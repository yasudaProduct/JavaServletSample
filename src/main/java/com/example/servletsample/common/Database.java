package com.example.servletsample.common;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * サンプルで使う組み込みデータベース (H2) への入口。
 *
 * <p>「DB を使う画面」のサンプルを動かすために、アプリの中で H2 を<b>メモリ上</b>で
 * 動かしています。別途 DB サーバを立てる必要はありませんが、
 * <b>アプリを再起動するとデータは消えます</b>。</p>
 *
 * <p>接続 URL の {@code DB_CLOSE_DELAY=-1} は「最後の接続を閉じても DB を消さない」
 * という指定です。これが無いと {@code close()} のたびにテーブルごと消えてしまいます。</p>
 *
 * <p><b>実務では</b>コネクションを毎回作らず、コネクションプール
 * ({@code META-INF/context.xml} に書く JNDI の {@code DataSource} など) から借りるのが普通です。
 * ここでは「JDBC の素の流れ」が見えるように {@link DriverManager} を直接使っています。</p>
 */
public final class Database {

    /** 組み込み H2 (メモリ) への接続 URL。 */
    private static final String URL = "jdbc:h2:mem:servlet-sample;DB_CLOSE_DELAY=-1";

    private static final String USER = "sa";
    private static final String PASSWORD = "";

    static {
        // JDBC 4 以降はクラスパス上のドライバが DriverManager に自動登録されるが、
        // Tomcat では WEB-INF/lib のドライバがその対象にならず、
        // 接続時に「No suitable driver found」で失敗する。
        // (Tomcat の JreMemoryLeakPreventionListener が、アプリを配備する前に
        //  DriverManager を初期化してしまい、自動検出はその 1 回で終わってしまうため)
        // そこで、使う前にドライバのクラスを自分で読み込んで登録させる。
        try {
            Class.forName("org.h2.Driver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    private Database() {
    }

    /**
     * 接続を取得する。
     *
     * <p>使い終わったら必ず閉じてください。try-with-resources を使うと閉じ忘れを防げます。</p>
     *
     * <pre>{@code
     * try (Connection connection = Database.getConnection();
     *      PreparedStatement statement = connection.prepareStatement(sql)) {
     *     ...
     * }
     * }</pre>
     */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    /**
     * データベースを終了する (アプリの停止時に呼ぶ)。
     *
     * <p>メモリ上の DB は JVM が生きている限り残り続けるため、
     * アプリを入れ替えたときに前のデータが残らないよう明示的に落としています。</p>
     */
    public static void shutdown() {
        try (Connection connection = getConnection();
             Statement statement = connection.createStatement()) {
            statement.execute("SHUTDOWN");
        } catch (SQLException e) {
            throw new IllegalStateException("データベースの停止に失敗しました", e);
        }
    }
}
