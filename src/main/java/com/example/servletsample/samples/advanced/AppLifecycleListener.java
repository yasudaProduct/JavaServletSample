package com.example.servletsample.samples.advanced;

import java.time.LocalDateTime;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

/**
 * 【サンプル】アプリの起動と停止を捕まえるリスナー。
 *
 * <p>{@link ServletContextListener} は、アプリ全体で <b>2 回だけ</b>呼ばれます。</p>
 *
 * <ul>
 *   <li>{@code contextInitialized} … アプリが起動したとき
 *       (最初のリクエストが来る<b>前</b>)</li>
 *   <li>{@code contextDestroyed} … アプリが止まるとき
 *       (最後のリクエストが終わった<b>あと</b>)</li>
 * </ul>
 *
 * <p>「起動時に 1 回だけやっておきたいこと」の置き場です。
 * 設定ファイルの読み込み、キャッシュの用意、接続プールやスレッドプールの作成が典型で、
 * 停止時にはその後始末をします。このサイトでも
 * {@code common/CatalogInitializer} がサンプル一覧を読み込み、
 * {@code common/DatabaseInitializer} が組み込みデータベースを用意しています。</p>
 *
 * <h2>Servlet の init() との違い</h2>
 * <p>Servlet の {@code init()} も起動時の処理ですが、呼ばれるのは
 * <b>その Servlet が初めて使われたとき</b>です (既定の設定の場合)。
 * 「アプリ全体で、誰かが来る前に」であればリスナーの出番です。</p>
 *
 * <h2>止めるときの後始末を忘れない</h2>
 * <p>{@code contextDestroyed} を書かずに自前のスレッドや接続を作ると、
 * アプリを入れ替えてもそれらが残り、古いクラスローダごとメモリに居座ります
 * (Tomcat のログに出る「appears to have started a thread ... but has failed to stop it」がこれです)。
 * 作ったものはここで必ず閉じます。</p>
 */
@WebListener
public class AppLifecycleListener implements ServletContextListener {

    /** 画面の記録に出す名前。 */
    static final String NAME = "AppLifecycleListener";

    @Override
    public void contextInitialized(ServletContextEvent event) {
        ServletContext context = event.getServletContext();

        // 起動時刻を控える。ここから先の記録はすべて「今回の起動」の分になる
        ListenerEventLog.markStarted(LocalDateTime.now());
        ListenerEventLog.add(ListenerEvent.Kind.APPLICATION, NAME, "contextInitialized",
                "アプリが起動しました (" + context.getServerInfo()
                        + " / Servlet " + context.getEffectiveMajorVersion()
                        + "." + context.getEffectiveMinorVersion() + ")");

        // サーバのログにも残す (docker compose logs -f tomcat で見られます)
        context.log("リスナーのサンプル: アプリが起動しました");
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        // ここで記録しても画面には出ません。アプリが止まるところなので、
        // この記録を読みに来るリクエストがもう来ないためです。
        // 停止時の出来事を残す場所は、画面ではなくログです。
        ListenerEventLog.add(ListenerEvent.Kind.APPLICATION, NAME, "contextDestroyed",
                "アプリが停止します");
        event.getServletContext().log("リスナーのサンプル: アプリが停止します");
    }
}
