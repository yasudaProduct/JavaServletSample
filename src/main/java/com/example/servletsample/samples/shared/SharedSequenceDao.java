package com.example.servletsample.samples.shared;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import com.example.servletsample.common.Database;

/**
 * 【サンプル】採番を DB に寄せた場合の実装（採番テーブル）。
 *
 * <p>{@code SequenceCounter} の {@code static} と並べて比べるために用意しました。
 * こちらは<b>サーバーが何台あっても 1 つの連番</b>になります。
 * 理由は単純で、数えている場所が 1 箇所（DB）だからです。</p>
 *
 * <h2>1 文で更新して読む</h2>
 * <p>「読んでから +1 して書き戻す」と書くと、2 台が同時に来たときに
 * 同じ番号を掴みます（読んだ後、書く前に割り込まれる）。
 * そうならないよう、<b>更新と読み取りを 1 つのトランザクションにまとめます</b>。</p>
 *
 * <pre>
 *   UPDATE shared_sequence SET next_value = next_value + 1 WHERE name = ?
 *   SELECT next_value FROM shared_sequence WHERE name = ?
 * </pre>
 *
 * <p>{@code UPDATE} が行ロックを取るので、もう一方はこの 2 文が終わるまで待ちます。
 * DB のシーケンス（{@code CREATE SEQUENCE}）や {@code IDENTITY} 列が使えるなら、
 * そちらのほうが速くて簡単です。採番テーブルにするのは
 * 「年度ごとに 1 番から」のような業務上の都合があるときです。</p>
 */
public class SharedSequenceDao {

    private static final String CREATE_TABLE = """
            CREATE TABLE IF NOT EXISTS shared_sequence (
                name       VARCHAR(40) PRIMARY KEY,
                next_value INT         NOT NULL
            )
            """;

    /** このサンプルで使う採番の名前。業務では「受付番号」「伝票番号」などが入ります。 */
    private static final String SEQUENCE_NAME = "reception";

    private static boolean tableReady;

    /** テーブルを用意する（アプリ起動時に DatabaseInitializer から呼ばれる）。 */
    public static synchronized void prepareTable() {
        if (tableReady) {
            return;
        }
        try (Connection connection = Database.getConnection();
             Statement statement = connection.createStatement()) {
            statement.execute(CREATE_TABLE);
            seed(connection);
            tableReady = true;
        } catch (SQLException e) {
            throw new IllegalStateException("採番テーブルの準備に失敗しました", e);
        }
    }

    private static void seed(Connection connection) throws SQLException {
        String sql = "MERGE INTO shared_sequence (name, next_value) KEY(name) VALUES (?, 0)";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, SEQUENCE_NAME);
            statement.executeUpdate();
        }
    }

    /** 次の番号を発行する。2 台から同時に呼ばれても重複しない。 */
    public int next() {
        prepareTable();
        try (Connection connection = Database.getConnection()) {
            connection.setAutoCommit(false);
            try {
                increment(connection);
                int value = read(connection);
                connection.commit();
                return value;
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new IllegalStateException("採番に失敗しました", e);
        }
    }

    /** いまの値を見る（発行はしない）。 */
    public int current() {
        prepareTable();
        try (Connection connection = Database.getConnection()) {
            return read(connection);
        } catch (SQLException e) {
            throw new IllegalStateException("採番の読み取りに失敗しました", e);
        }
    }

    /** 0 に戻す（サンプルを繰り返し試せるようにするため）。 */
    public void reset() {
        prepareTable();
        String sql = "UPDATE shared_sequence SET next_value = 0 WHERE name = ?";
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, SEQUENCE_NAME);
            statement.executeUpdate();
        } catch (SQLException e) {
            throw new IllegalStateException("採番のリセットに失敗しました", e);
        }
    }

    private void increment(Connection connection) throws SQLException {
        String sql = "UPDATE shared_sequence SET next_value = next_value + 1 WHERE name = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, SEQUENCE_NAME);
            statement.executeUpdate();
        }
    }

    private int read(Connection connection) throws SQLException {
        String sql = "SELECT next_value FROM shared_sequence WHERE name = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, SEQUENCE_NAME);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next() ? rows.getInt("next_value") : 0;
            }
        }
    }
}
