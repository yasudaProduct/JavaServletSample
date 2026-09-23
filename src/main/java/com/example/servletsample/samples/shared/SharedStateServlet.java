package com.example.servletsample.samples.shared;

import java.io.IOException;
import java.io.Serializable;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.shared.SequenceCounter;
import com.example.servletsample.shared.SharedLibrary;

/**
 * 【サンプル】JAR を共通化しても共通化できないもの（状態）。
 *
 * <p>共通ライブラリに入れても意味がないものがあります。<b>状態</b>です。
 * サーバーが 2 台あれば JVM も 2 つあり、{@code static} はそれぞれ別に存在します。
 * 同じ JAR を配っても、同じ版を使っても、1 つにはなりません。</p>
 *
 * <h2>1 台で「2 台の事故」を再現する</h2>
 * <p>2 台用意しなくても見せられるようにしてあります。
 * 共通 JAR を<b>別のクラスローダでもう一度読み込み</b>、
 * それを「サーバー B」として扱います（{@link SimulatedServer}）。
 * クラスの同一性はクラスローダとの組で決まるので、
 * {@code static} フィールドも別に確保されます。</p>
 *
 * <p>画面では、同じ操作を「サーバー A」「サーバー B」から行い、</p>
 * <ul>
 *   <li>{@code static} の採番 … 両方が 1, 2, 3 …（<b>番号が重複する</b>）</li>
 *   <li>DB の採番 … 通しで 1, 2, 3 …（<b>重複しない</b>）</li>
 * </ul>
 * <p>が並ぶので、置き場所の違いがそのまま結果の違いになります。</p>
 */
@WebServlet(name = "sharedState", urlPatterns = {"/samples/shared/shared-state"})
public class SharedStateServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** 発行履歴をセッションに置くときのキー。 */
    private static final String HISTORY_KEY = "servletSample.sharedState.history";

    private final SharedSequenceDao sequenceDao = new SharedSequenceDao();

    /**
     * 「もう 1 台のサーバー」。起動時に 1 つ作り、停止時に閉じる。
     *
     * <p>{@code volatile} にしているのは、{@link #init()} で書いた値を
     * 別のリクエストスレッドから確実に読めるようにするためです。</p>
     */
    private volatile SimulatedServer serverB;

    /** 模擬サーバーを作れなかった場合の理由（画面に出す）。 */
    private volatile String simulationError;

    @Override
    public void init() {
        URL sharedJar = SimulatedServer.sharedJarLocation();
        if (sharedJar == null) {
            simulationError = "共通 JAR の場所を取得できなかったため、サーバー B を用意できませんでした。";
            return;
        }
        try {
            serverB = SimulatedServer.of("サーバー B", sharedJar);
        } catch (IOException | ReflectiveOperationException | RuntimeException e) {
            simulationError = "サーバー B を用意できませんでした: " + e.getMessage();
            getServletContext().log("模擬サーバーの用意に失敗しました", e);
        }
    }

    /**
     * アプリの停止時にクラスローダを閉じる。
     *
     * <p>閉じ忘れると、アプリを入れ替えても古いクラスローダが JAR を掴んだまま
     * メモリに居座ります。Tomcat が警告を出す「クラスローダリーク」がこれです。</p>
     */
    @Override
    public void destroy() {
        SimulatedServer current = serverB;
        serverB = null;
        if (current == null) {
            return;
        }
        try {
            current.close();
        } catch (IOException e) {
            // 停止処理なので、失敗してもアプリの終了は続行する
            getServletContext().log("模擬サーバーのクラスローダを閉じられませんでした", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("sharedVersion", SharedLibrary.VERSION);
        request.setAttribute("simulationError", simulationError);

        List<Issue> history = history(request.getSession());
        request.setAttribute("history", history);
        // EL にラムダは書けないので、判定はここで済ませておく
        request.setAttribute("hasDuplicate", history.stream().anyMatch(Issue::isDuplicated));

        // いまの値（発行はしない）
        request.setAttribute("staticA", SequenceCounter.current());
        SimulatedServer b = serverB;
        request.setAttribute("staticB", b == null ? 0 : b.current());
        request.setAttribute("dbValue", sequenceDao.current());

        // 「別のクラスとして読まれている」ことの確認
        request.setAttribute("loaderA", SharedLibrary.originOf(SequenceCounter.class).getClassLoader());
        request.setAttribute("loaderB", b == null ? null : b.getClassLoaderName());
        request.setAttribute("sameClass", b != null && b.isSameClassAsApp());

        render(request, response, "samples/shared/shared-state");
    }

    /**
     * 採番する。
     *
     * <p>更新のあとはリダイレクトしています（PRG パターン）。
     * そのまま画面を出すと、再読み込みでもう一度採番されてしまいます。</p>
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        HttpSession session = request.getSession();

        if ("reset".equals(action)) {
            SequenceCounter.reset();
            SimulatedServer b = serverB;
            if (b != null) {
                b.reset();
            }
            sequenceDao.reset();
            session.removeAttribute(HISTORY_KEY);
        } else if ("issue-a".equals(action)) {
            issue(session, "サーバー A", SequenceCounter.next());
        } else if ("issue-b".equals(action)) {
            SimulatedServer b = serverB;
            if (b != null) {
                issue(session, b.getName(), b.next());
            }
        }

        response.sendRedirect(request.getContextPath() + "/samples/shared/shared-state");
    }

    /**
     * 1 回分の採番を記録する。
     *
     * <p>{@code static} 側と DB 側を同時に発行して 1 行にまとめます。
     * 同じ行に並ぶので、片方だけが重複することが目で見えます。</p>
     */
    private void issue(HttpSession session, String serverName, int staticValue) {
        int dbValue = sequenceDao.next();
        List<Issue> history = history(session);
        boolean duplicated = history.stream().anyMatch(issue -> issue.getStaticValue() == staticValue);
        history.add(new Issue(history.size() + 1, serverName, staticValue, dbValue, duplicated));
        session.setAttribute(HISTORY_KEY, history);
    }

    @SuppressWarnings("unchecked")
    private List<Issue> history(HttpSession session) {
        Object stored = session.getAttribute(HISTORY_KEY);
        if (stored instanceof List) {
            return (List<Issue>) stored;
        }
        return new ArrayList<>();
    }

    /**
     * 発行 1 回分の記録。
     *
     * <p>{@link Serializable} にしているのは、セッションに入れるからです。
     * 2 台構成でセッションクラスタリングを使う場合や、Tomcat の再起動を
     * またいでセッションを残す設定では、<b>入っているものがすべて
     * 直列化できないと落ちます</b>。複数サーバー構成では特に効いてきます。</p>
     */
    public static final class Issue implements Serializable {

        private static final long serialVersionUID = 1L;

        private final int seq;
        private final String server;
        private final int staticValue;
        private final int dbValue;
        private final boolean duplicated;

        Issue(int seq, String server, int staticValue, int dbValue, boolean duplicated) {
            this.seq = seq;
            this.server = server;
            this.staticValue = staticValue;
            this.dbValue = dbValue;
            this.duplicated = duplicated;
        }

        /** 何回目の操作か。 */
        public int getSeq() {
            return seq;
        }

        /** どちらのサーバーで採番したか。 */
        public String getServer() {
            return server;
        }

        /** 共通 JAR の static が返した番号。 */
        public int getStaticValue() {
            return staticValue;
        }

        /** DB の採番テーブルが返した番号。 */
        public int getDbValue() {
            return dbValue;
        }

        /** その static の番号が、過去に発行済みだったか。 */
        public boolean isDuplicated() {
            return duplicated;
        }
    }
}
