package com.example.servletsample.samples.file;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.example.servletsample.common.Database;

/**
 * CSV から取り込んだ社員の保存・取得 (DAO)。
 *
 * <h2>全件を 1 つのトランザクションで登録する</h2>
 * <p>取り込みの途中で失敗したとき、「3 件目までは入って、4 件目から入っていない」状態が
 * いちばん困ります。利用者は CSV を直して取り込み直しますが、
 * どこまで入ったのか分からないからです。</p>
 * <p>そこで自動コミットを切り、全件を書き終えてから {@code commit()} します。
 * 途中で失敗したら {@code rollback()} で全部取り消すので、
 * <b>「全部入った」か「1 件も入っていない」のどちらか</b>になります。</p>
 *
 * <h2>登録済みの社員は上書きする</h2>
 * <p>H2 の {@code MERGE INTO ... KEY (...)} は「あれば更新、無ければ追加」を 1 文で行います
 * (Oracle / SQL Server なら {@code MERGE}、PostgreSQL なら {@code INSERT ... ON CONFLICT}、
 * MySQL なら {@code INSERT ... ON DUPLICATE KEY UPDATE})。</p>
 */
public class ImportedEmployeeDao {

    private static final Logger LOG = LogManager.getLogger(ImportedEmployeeDao.class);

    /**
     * テーブル定義。
     *
     * <p>氏名だけ、入力チェックの上限 (40 文字) の 2 倍の幅にしています。
     * 入力チェックは「人が数えた文字数」で数えますが、H2 は UTF-16 の単位で数えるため、
     * 絵文字や「𠮟」のような文字は 1 文字が 2 つに数えられます。
     * 幅を揃えてしまうと、<b>入力チェックを通った値が DB で弾かれてシステムエラーになります</b>。
     * DB ごとに数え方が違うので (MySQL の utf8mb4 や PostgreSQL は人が数えたとおり)、
     * 使う DB で確かめてから決めます。</p>
     */
    private static final String CREATE_TABLE = """
            CREATE TABLE IF NOT EXISTS csv_import_employees (
                employee_code   VARCHAR(6)   PRIMARY KEY,
                name            VARCHAR(80)  NOT NULL,
                kana            VARCHAR(40)  NOT NULL,
                email           VARCHAR(100) NOT NULL,
                department_code VARCHAR(3)   NOT NULL,
                employment_type VARCHAR(10)  NOT NULL,
                hire_date       DATE         NOT NULL,
                updated_at      TIMESTAMP    NOT NULL
            )
            """;

    private static final String MERGE = """
            MERGE INTO csv_import_employees
                (employee_code, name, kana, email, department_code, employment_type, hire_date, updated_at)
            KEY (employee_code)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """;

    private static final String SELECT_ALL = """
            SELECT employee_code, name, kana, email, department_code, employment_type, hire_date, updated_at
              FROM csv_import_employees
             ORDER BY employee_code
            """;

    private static boolean tableReady;

    public ImportedEmployeeDao() {
        prepareTable();
    }

    /** テーブルを作り、空なら最初の社員を入れておく。 */
    public static synchronized void prepareTable() {
        if (tableReady) {
            return;
        }
        try (Connection connection = Database.getConnection();
             Statement statement = connection.createStatement()) {
            statement.execute(CREATE_TABLE);
            try (ResultSet rs = statement.executeQuery("SELECT COUNT(*) FROM csv_import_employees")) {
                if (rs.next() && rs.getInt(1) == 0) {
                    insertSeed(connection);
                }
            }
            tableReady = true;
        } catch (SQLException e) {
            throw new IllegalStateException("csv_import_employees テーブルを作成できませんでした", e);
        }
    }

    /** 社員コード順に全件を取得する。 */
    public List<ImportedEmployee> findAll() {
        List<ImportedEmployee> employees = new ArrayList<>();
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(SELECT_ALL);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                employees.add(new ImportedEmployee(
                        rs.getString("employee_code"),
                        rs.getString("name"),
                        rs.getString("kana"),
                        rs.getString("email"),
                        rs.getString("department_code"),
                        rs.getString("employment_type"),
                        rs.getObject("hire_date", LocalDate.class),
                        rs.getObject("updated_at", LocalDateTime.class)));
            }
            return employees;
        } catch (SQLException e) {
            throw new IllegalStateException("社員の一覧を取得できませんでした", e);
        }
    }

    /**
     * 登録済みの社員コードを全部返す。
     *
     * <p>取り込む前に「何件が追加で、何件が上書きか」を数えるために使います。
     * このサンプルは件数が少ないので全件を読んでいますが、
     * 多いなら {@code WHERE employee_code IN (...)} で取り込む分だけに絞ります。</p>
     */
    public Set<String> findAllCodes() {
        Set<String> codes = new HashSet<>();
        try (Connection connection = Database.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement("SELECT employee_code FROM csv_import_employees");
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                codes.add(rs.getString(1));
            }
            return codes;
        } catch (SQLException e) {
            throw new IllegalStateException("登録済みの社員コードを取得できませんでした", e);
        }
    }

    /**
     * 全件を 1 つのトランザクションで登録する (登録済みの社員コードは上書き)。
     *
     * <p>失敗したら全部取り消し、原因の例外を<b>添えて</b>投げ直します。
     * ここではログに出しません。受け止めてログに出すのは呼び出し元
     * ({@link CsvImportServlet}) の 1 か所だけにします
     * (各層でログに出すと、同じ障害が何件も起きたように見えるためです)。</p>
     *
     * @param employees  登録する社員
     * @param breakHalfway デモ用。true にすると、半分まで書いたところで障害を起こす
     * @throws IllegalStateException 登録に失敗したとき (ロールバック済み)
     */
    public void saveAll(List<ImportedEmployee> employees, boolean breakHalfway) {
        int written = 0;
        try (Connection connection = Database.getConnection()) {
            // ここから commit() までが 1 つのまとまり
            connection.setAutoCommit(false);
            LOG.debug("登録を始めます (トランザクション開始) count={}", employees.size());

            try (PreparedStatement statement = connection.prepareStatement(MERGE)) {
                for (ImportedEmployee employee : employees) {
                    if (breakHalfway && written == Math.max(1, employees.size() / 2)) {
                        // 【デモ用】実際のアプリにこの分岐を残してはいけません。
                        // 本物なら、DB サーバの停止や接続断でここに来ます
                        throw new SQLException("【デモ】登録の途中で DB との接続が切れたことにしています", "08S01");
                    }
                    bind(statement, employee);
                    statement.executeUpdate();
                    written++;
                }
                connection.commit();
                LOG.debug("コミットしました count={}", written);
            } catch (SQLException e) {
                rollback(connection, e);
                throw e;
            }
        } catch (SQLException e) {
            // 原因 (e) を第 2 引数に渡すと、ログに「Caused by:」として連なって出ます。
            // 渡し忘れると、なぜ失敗したのかが永久に分からなくなります
            throw new IllegalStateException("社員の登録に失敗したため、ロールバックしました ("
                    + employees.size() + " 件中 " + written + " 件を書いたところで失敗)", e);
        }
    }

    /** 社員を最初の 3 人だけに戻す (デモ用)。 */
    public void reset() {
        try (Connection connection = Database.getConnection()) {
            connection.setAutoCommit(false);
            try (Statement statement = connection.createStatement()) {
                statement.executeUpdate("DELETE FROM csv_import_employees");
                insertSeed(connection);
                connection.commit();
            } catch (SQLException e) {
                rollback(connection, e);
                throw e;
            }
        } catch (SQLException e) {
            throw new IllegalStateException("社員を初期状態に戻せませんでした", e);
        }
    }

    /** ロールバックする。ロールバック自体が失敗したら、元の例外に添えておく。 */
    private static void rollback(Connection connection, SQLException cause) {
        try {
            connection.rollback();
        } catch (SQLException e) {
            cause.addSuppressed(e);
        }
    }

    private static void bind(PreparedStatement statement, ImportedEmployee employee) throws SQLException {
        statement.setString(1, employee.getCode());
        statement.setString(2, employee.getName());
        statement.setString(3, employee.getKana());
        statement.setString(4, employee.getEmail());
        statement.setString(5, employee.getDepartmentCode());
        statement.setString(6, employee.getEmploymentType());
        statement.setObject(7, employee.getHireDate());
        statement.setObject(8, employee.getUpdatedAt());
    }

    /** 最初から登録されている 3 人。取り込みの「上書き」を試せるように置いています。 */
    private static void insertSeed(Connection connection) throws SQLException {
        LocalDateTime now = LocalDateTime.now();
        List<ImportedEmployee> seed = List.of(
                new ImportedEmployee("E00001", "伊藤 誠", "イトウ マコト", "makoto.ito@example.com",
                        "D01", "正社員", LocalDate.of(2015, 4, 1), now),
                new ImportedEmployee("E00002", "中村 真由美", "ナカムラ マユミ", "mayumi.nakamura@example.com",
                        "D02", "正社員", LocalDate.of(2018, 10, 1), now),
                new ImportedEmployee("E00003", "佐藤 花子", "サトウ ハナコ", "hanako.sato@example.com",
                        "D02", "契約社員", LocalDate.of(2021, 4, 1), now));
        try (PreparedStatement statement = connection.prepareStatement(MERGE)) {
            for (ImportedEmployee employee : seed) {
                bind(statement, employee);
                statement.executeUpdate();
            }
        }
    }
}
