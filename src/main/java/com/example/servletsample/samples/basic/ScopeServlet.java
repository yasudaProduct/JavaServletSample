package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;
import java.util.regex.Pattern;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;

/**
 * 【サンプル】スコープ (request / session / application)。
 *
 * <p>値を「どこに置くか」で、その値が<b>いつまで残るか</b>と<b>誰に見えるか</b>が決まります。
 * このサンプルでは同じ「名前と値」を 3 つのスコープに入れて、
 * 画面を開き直したり、セッションを破棄したりしながら違いを確かめます。</p>
 *
 * <table border="1">
 *   <caption>4 つのスコープ</caption>
 *   <tr><th>スコープ</th><th>入れ方</th><th>生きている間</th><th>見える範囲</th></tr>
 *   <tr>
 *     <td>page</td>
 *     <td>{@code pageContext.setAttribute} / JSP の {@code c:set}</td>
 *     <td>その JSP を 1 ページ組み立てている間だけ</td>
 *     <td>その JSP の中だけ (include した先には行かない)</td>
 *   </tr>
 *   <tr>
 *     <td>request</td>
 *     <td>{@code request.setAttribute}</td>
 *     <td>1 回のリクエストの間 (forward 先を含む)</td>
 *     <td>そのリクエストを処理している間だけ</td>
 *   </tr>
 *   <tr>
 *     <td>session</td>
 *     <td>{@code request.getSession().setAttribute}</td>
 *     <td>そのブラウザのセッションが続く間 (既定 30 分)</td>
 *     <td>同じブラウザからのリクエスト全部</td>
 *   </tr>
 *   <tr>
 *     <td>application</td>
 *     <td>{@code getServletContext().setAttribute}</td>
 *     <td>アプリが動いている間ずっと</td>
 *     <td><b>そのアプリを見ている全員</b></td>
 *   </tr>
 * </table>
 *
 * <p>application スコープはこのサイトを見ている人<b>全員で 1 つ</b>を共有します。
 * 公開しているデモなので、入れられる件数と文字数を制限し、
 * 書き換えは {@link ServletContext} で同期化しています
 * (複数のリクエストが同時に処理されるため)。</p>
 *
 * <p>「値を入れる」操作のうち request スコープだけはリダイレクトしていません。
 * リダイレクトすると別のリクエストになり、入れた値がその場で消えてしまって
 * 何も確かめられないためです (これ自体が request スコープの性質です)。</p>
 */
@WebServlet(name = "scope", urlPatterns = {ScopeServlet.SAMPLE_PATH})
public class ScopeServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** このサンプル画面の URL (コンテキストパスは含まない)。 */
    static final String SAMPLE_PATH = "/samples/basic/scope";

    private static final String VIEW = "/WEB-INF/views/samples/basic/scope.jsp";

    /**
     * このサンプルが入れた属性であることが分かるようにする接頭辞。
     *
     * <p>とくに application スコープはアプリ全体で 1 つしかありません。
     * 接頭辞を付けずに {@code "user"} のような名前で入れると、
     * 他の画面やフレームワークが使っている属性を壊してしまうおそれがあります。</p>
     */
    static final String ENTRY_PREFIX = "scopeSample.entry.";

    /**
     * 「スコープを省略したときの探索順」を試すための属性名。
     *
     * <p>こちらは EL で {@code ${scopeDemoValue}} と<b>スコープを省略して</b>書けるように、
     * 接頭辞 (ドット) を付けていません。EL の {@code .} はプロパティの参照になるため、
     * {@code scopeSample.entry.x} のようなドット入りの名前は
     * {@code ${requestScope['scopeSample.entry.x']}} と書かないと取り出せません。</p>
     */
    static final String DEMO_NAME = "scopeDemoValue";

    /** この画面を開いた回数を数えるカウンタのキー (session / application の両方で使う)。 */
    private static final String VIEW_COUNT_KEY = "scopeSample.viewCount";

    /** 属性名の上限。 */
    static final int NAME_MAX_LENGTH = 20;

    /** 値の上限。application スコープは全員に見えるので、長い文章を貼れないようにしています。 */
    static final int VALUE_MAX_LENGTH = 50;

    /** application スコープに置ける件数の上限。サーバのメモリに残り続けるため制限します。 */
    static final int APP_MAX_ENTRIES = 10;

    /** 属性名に使える文字。記号や空白を弾いて、画面にそのまま出せる形に限定します。 */
    private static final Pattern NAME_PATTERN = Pattern.compile("[A-Za-z0-9_-]{1," + NAME_MAX_LENGTH + "}");

    static final String SCOPE_REQUEST = "request";
    static final String SCOPE_SESSION = "session";
    static final String SCOPE_APPLICATION = "application";

    /** 知らないスコープが送られてきたときのメッセージ。 */
    static final String UNKNOWN_SCOPE_MESSAGE =
            "スコープは request / session / application のどれかを選んでください。";

    private static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");

    // ======================================================================
    // 表示
    // ======================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // リダイレクト元 (POST 側) が預けたメッセージがあれば取り出す
        consumeFlashAsNotice(request);
        showPage(request, response);
    }

    /**
     * 3 つのスコープの中身と、セッションの情報を集めて画面へ渡す。
     *
     * <p>ここで {@code setAttribute} している表示用の値 (requestEntries など) も
     * request スコープに入りますが、一覧には接頭辞が付いたものだけを並べているので
     * 画面の表には出てきません。</p>
     */
    private void showPage(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        ServletContext context = getServletContext();

        // ---- 各スコープの中身 (このサンプルが入れたものだけ) ----
        request.setAttribute("requestEntries", requestEntries(request));
        request.setAttribute("sessionEntries", sessionEntries(request));
        request.setAttribute("applicationEntries", applicationEntries(context));

        // ---- セッションの情報 ----
        // getSession() は「無ければ作る」。この画面はセッションの様子を見せるのが目的なので、
        // ここで作ってしまってよいと判断しています。
        // (表示するだけの画面では getSession(false) にして、無駄にセッションを作らない方が良い場面もあります)
        HttpSession session = request.getSession();
        long timeoutSeconds = session.getMaxInactiveInterval();
        long now = System.currentTimeMillis();

        request.setAttribute("sessionId", maskSessionId(session.getId()));
        request.setAttribute("sessionNew", session.isNew());
        request.setAttribute("sessionCreatedText", formatEpoch(session.getCreationTime()));
        request.setAttribute("sessionLastAccessedText", formatEpoch(session.getLastAccessedTime()));
        request.setAttribute("sessionTimeoutMinutes", timeoutSeconds / 60);
        // 時間切れは「最後にアクセスした時刻 + タイムアウト」で判定されます。
        // 「最後にアクセスした時刻」は今まさに処理しているこのリクエストなので、
        // 目安は now を起点に計算します。
        // (getLastAccessedTime() が返すのは 1 つ前のリクエストの時刻なので、
        //  そこから計算すると、しばらく放置したあとに開き直したときに実際より早い時刻が出ます)
        request.setAttribute("sessionExpiresText", formatEpoch(now + timeoutSeconds * 1000L));

        // ---- 「自分だけ」と「全員」の違いが分かるカウンタ ----
        request.setAttribute("sessionViewCount", countSessionView(session));
        request.setAttribute("applicationViewCount", countApplicationView(context));
        request.setAttribute("nowText", formatEpoch(now));

        // ---- 画面の入力値・制限値 ----
        request.setAttribute("appMaxEntries", APP_MAX_ENTRIES);
        request.setAttribute("nameMaxLength", NAME_MAX_LENGTH);
        request.setAttribute("valueMaxLength", VALUE_MAX_LENGTH);

        forward(request, response, VIEW);
    }

    // ======================================================================
    // 操作
    // ======================================================================

    /**
     * 画面からの操作を受け取る。
     *
     * <p>状態を変える処理なので POST で受け、終わったらリダイレクトして GET に戻します
     * (PRG パターン。再読み込みで同じ操作が繰り返されないようにするためです)。
     * ただし request スコープへの格納だけは、リダイレクトすると値が消えてしまうので
     * forward で同じリクエストのまま画面を出します。</p>
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        if ("invalidate".equals(action)) {
            invalidateSession(request);
            redirect(request, response);
            return;
        }
        if ("clear-application".equals(action)) {
            clearApplication(request);
            redirect(request, response);
            return;
        }
        if ("put-demo".equals(action)) {
            putDemoValue(request, response);
            return;
        }
        if ("clear-demo".equals(action)) {
            clearDemoValue(request);
            redirect(request, response);
            return;
        }

        putValue(request, response);
    }

    /** 入力された名前と値を、選ばれたスコープに入れる。 */
    private void putValue(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String scope = trim(request.getParameter("scope"));
        String name = trim(request.getParameter("name"));
        String value = trim(request.getParameter("value"));

        // 入力し直してもらう場合に備えて、入力値は画面に返す
        request.setAttribute("inputScope", scope);
        request.setAttribute("inputName", name);
        request.setAttribute("inputValue", value);

        String error = validate(scope, name, value);
        if (error != null) {
            setNotice(request, "danger", "入力を確認してください", error);
            showPage(request, response);
            return;
        }

        String key = ENTRY_PREFIX + name;

        if (SCOPE_REQUEST.equals(scope)) {
            // 【request スコープ】
            // ここでリダイレクトすると次は別のリクエストになり、入れた値は届きません。
            // 同じリクエストのまま JSP へ forward するので、この画面にだけ表示されます。
            request.setAttribute(key, value);
            setNotice(request, "info", "request スコープに入れました",
                    "この値が見えるのは今表示している画面だけです。"
                            + "「もう一度開く」を押すと消えていることを確かめてください。");
            showPage(request, response);
            return;
        }

        if (SCOPE_SESSION.equals(scope)) {
            // 【session スコープ】
            // 同じブラウザからのリクエストであれば、別の画面へ移動しても残ります。
            // 残るということは、消さない限りサーバのメモリを使い続けるということでもあります。
            request.getSession().setAttribute(key, value);
            Flash.set(request, "success", "session スコープに入れました",
                    "画面を開き直しても残ります。消えるのは、セッションを破棄したときか、"
                            + "操作しないまま時間切れになったときです。");
            redirect(request, response);
            return;
        }

        // 【application スコープ】
        // アプリ全体で 1 つしかない入れ物で、複数のリクエストが同時に触ります。
        // 「件数を数えて、空きがあれば入れる」は読んでから書くまでの間に割り込まれるので、
        // ServletContext そのものを鍵にして同期化します
        // (全スレッドから見える唯一のオブジェクトなので、鍵として使えます)。
        ServletContext context = getServletContext();
        boolean stored;
        synchronized (context) {
            boolean overwrite = context.getAttribute(key) != null;
            stored = overwrite || countEntries(context) < APP_MAX_ENTRIES;
            if (stored) {
                context.setAttribute(key, value);
            }
        }

        if (!stored) {
            setNotice(request, "danger", "これ以上は入れられません",
                    "application スコープに置けるのは " + APP_MAX_ENTRIES + " 件までにしています。"
                            + "不要になったら「application の値を全部消す」で消してください。");
            showPage(request, response);
            return;
        }

        Flash.set(request, "success", "application スコープに入れました",
                "この値はサーバを再起動するまで残り、このサイトを見ている人全員に表示されます。");
        redirect(request, response);
    }

    /**
     * 探索順を試すための値を入れる。
     *
     * <p>値は画面からではなくサーバ側で決めています。
     * 3 つのスコープに同じ名前で入れておき、EL でスコープを省略したときに
     * どれが選ばれるかを見るための仕掛けです。</p>
     */
    private void putDemoValue(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String scope = trim(request.getParameter("scope"));
        if (!isKnownScope(scope)) {
            // 画面のボタン以外からも POST できるので、hidden で送っている値もそのまま信用しません。
            // (検査しないと、送られてきた文字列がそのまま画面の表に出てしまいます)
            setNotice(request, "danger", "入力を確認してください", UNKNOWN_SCOPE_MESSAGE);
            showPage(request, response);
            return;
        }
        String value = scope + " スコープに入れた値";

        if (SCOPE_SESSION.equals(scope)) {
            request.getSession().setAttribute(DEMO_NAME, value);
            redirect(request, response);
            return;
        }
        if (SCOPE_APPLICATION.equals(scope)) {
            ServletContext context = getServletContext();
            // 固定のキーに固定の文字列を入れるだけなので件数は増えません
            synchronized (context) {
                context.setAttribute(DEMO_NAME, value);
            }
            redirect(request, response);
            return;
        }

        // request スコープは同じリクエストの中だけなので forward で表示する
        request.setAttribute(DEMO_NAME, value);
        showPage(request, response);
    }

    /** 探索順のデモで入れた値を、session と application から消す。 */
    private void clearDemoValue(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.removeAttribute(DEMO_NAME);
        }
        ServletContext context = getServletContext();
        synchronized (context) {
            context.removeAttribute(DEMO_NAME);
        }
        Flash.set(request, "info", "デモの値を消しました",
                "session と application から " + DEMO_NAME + " を削除しました。");
    }

    /**
     * セッションを破棄する (ログアウト処理と同じことをしています)。
     *
     * <p>{@code invalidate()} を呼ぶと、そのセッションに入っていた値はすべて捨てられ、
     * 同じセッションオブジェクトは以後使えなくなります
     * (触ると {@code IllegalStateException})。</p>
     *
     * <p>このあと {@link Flash} がメッセージを預けるために {@code getSession()} を呼ぶため、
     * すぐに<b>新しいセッションが作られ、ID も変わります</b>。
     * ログイン直後にセッションを作り直す (セッション固定攻撃への対策) のも同じ考え方です。</p>
     */
    private void invalidateSession(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        Flash.set(request, "warning", "セッションを破棄しました",
                "session スコープの値は消え、セッション ID も新しくなりました。"
                        + "application の値はサーバに残ったままです。");
    }

    /** application スコープに入れた値をまとめて消す。 */
    private void clearApplication(HttpServletRequest request) {
        ServletContext context = getServletContext();
        int removed;
        synchronized (context) {
            List<String> keys = entryKeys(context);
            for (String key : keys) {
                context.removeAttribute(key);
            }
            removed = keys.size();
        }
        Flash.set(request, "info", "application スコープの値を消しました",
                removed + " 件を削除しました。この操作はサイトを見ている全員に影響します。");
    }

    // ======================================================================
    // 入力チェック
    // ======================================================================

    /**
     * 入力された値を検査する。
     *
     * @return 問題があればメッセージ、問題なければ {@code null}
     */
    static String validate(String scope, String name, String value) {
        if (!isKnownScope(scope)) {
            // 画面のラジオボタン以外の値が送られてくることもある (URL や開発者ツールから送れる)
            return UNKNOWN_SCOPE_MESSAGE;
        }
        if (name.isEmpty()) {
            return "名前を入力してください。";
        }
        if (!NAME_PATTERN.matcher(name).matches()) {
            return "名前は半角英数字・ハイフン・アンダースコアで、"
                    + NAME_MAX_LENGTH + " 文字までにしてください。";
        }
        if (value.isEmpty()) {
            return "値を入力してください。";
        }
        if (value.length() > VALUE_MAX_LENGTH) {
            return "値は " + VALUE_MAX_LENGTH + " 文字までにしてください (いまは "
                    + value.length() + " 文字です)。";
        }
        return null;
    }

    /** 画面が扱う 3 つのスコープのどれかかどうか。 */
    static boolean isKnownScope(String scope) {
        return SCOPE_REQUEST.equals(scope) || SCOPE_SESSION.equals(scope)
                || SCOPE_APPLICATION.equals(scope);
    }

    /** null を空文字にし、前後の空白を取る。 */
    static String trim(String value) {
        return value == null ? "" : value.trim();
    }

    // ======================================================================
    // 各スコープの中身を読む
    // ======================================================================

    private static List<Entry> requestEntries(HttpServletRequest request) {
        List<Entry> entries = new ArrayList<>();
        Enumeration<String> names = request.getAttributeNames();
        while (names.hasMoreElements()) {
            String key = names.nextElement();
            if (key.startsWith(ENTRY_PREFIX)) {
                entries.add(new Entry("requestScope", key, request.getAttribute(key)));
            }
        }
        return sorted(entries);
    }

    private static List<Entry> sessionEntries(HttpServletRequest request) {
        List<Entry> entries = new ArrayList<>();
        // getSession(false) … 無いときに新しく作らせない書き方。
        // 「セッションがあるかどうか」を見たいだけの場面ではこちらを使います。
        HttpSession session = request.getSession(false);
        if (session == null) {
            return entries;
        }
        Enumeration<String> names = session.getAttributeNames();
        while (names.hasMoreElements()) {
            String key = names.nextElement();
            if (key.startsWith(ENTRY_PREFIX)) {
                entries.add(new Entry("sessionScope", key, session.getAttribute(key)));
            }
        }
        return sorted(entries);
    }

    /**
     * application スコープの中身を読む。
     *
     * <p>読むだけでも同期化しているのは、属性名を順に取り出している最中に
     * 別のリクエストが値を足したり消したりするおそれがあるためです。</p>
     */
    private static List<Entry> applicationEntries(ServletContext context) {
        List<Entry> entries = new ArrayList<>();
        synchronized (context) {
            for (String key : entryKeys(context)) {
                entries.add(new Entry("applicationScope", key, context.getAttribute(key)));
            }
        }
        return sorted(entries);
    }

    /** application スコープにある、このサンプルの属性名を集める。呼び出し側で同期化すること。 */
    private static List<String> entryKeys(ServletContext context) {
        List<String> keys = new ArrayList<>();
        Enumeration<String> names = context.getAttributeNames();
        while (names.hasMoreElements()) {
            String key = names.nextElement();
            if (key.startsWith(ENTRY_PREFIX)) {
                keys.add(key);
            }
        }
        return keys;
    }

    /** application スコープにあるこのサンプルの件数。呼び出し側で同期化すること。 */
    private static int countEntries(ServletContext context) {
        return entryKeys(context).size();
    }

    private static List<Entry> sorted(List<Entry> entries) {
        entries.sort(Comparator.comparing(Entry::getName));
        return entries;
    }

    // ======================================================================
    // カウンタ
    // ======================================================================

    /** この画面を開いた回数 (このブラウザの分だけ)。 */
    private static int countSessionView(HttpSession session) {
        Object stored = session.getAttribute(VIEW_COUNT_KEY);
        int count = (stored instanceof Integer ? (Integer) stored : 0) + 1;
        session.setAttribute(VIEW_COUNT_KEY, count);
        return count;
    }

    /**
     * この画面を開いた回数 (全員の合計)。
     *
     * <p>{@code Integer} を読んで +1 して書き戻すと、同時にアクセスされたときに
     * 数え落とします。application スコープには
     * {@link AtomicLong} のような<b>スレッドセーフな入れ物</b>を置いて、
     * その中身を更新します (入れ物を入れ替えないので {@code setAttribute} は最初の 1 回だけです)。</p>
     */
    private static long countApplicationView(ServletContext context) {
        AtomicLong counter;
        synchronized (context) {
            Object stored = context.getAttribute(VIEW_COUNT_KEY);
            if (stored instanceof AtomicLong) {
                counter = (AtomicLong) stored;
            } else {
                counter = new AtomicLong();
                context.setAttribute(VIEW_COUNT_KEY, counter);
            }
        }
        return counter.incrementAndGet();
    }

    // ======================================================================
    // 小さな部品
    // ======================================================================

    /**
     * セッション ID を伏せ字にする。
     *
     * <p>セッション ID は「その人になりすませる鍵」です。
     * 画面に丸ごと出すと、画面共有やスクリーンショットから漏れます。
     * 学習用に変化だけ分かればよいので、先頭だけを見せています。</p>
     */
    static String maskSessionId(String sessionId) {
        if (sessionId == null || sessionId.isEmpty()) {
            return "";
        }
        int visible = 8;
        if (sessionId.length() <= visible) {
            return sessionId;
        }
        return sessionId.substring(0, visible) + "…（以降は伏せています）";
    }

    /** セッションが持っている時刻 (1970 年からのミリ秒) を読める形にする。 */
    static String formatEpoch(long epochMillis) {
        return TIME_FORMAT.format(
                LocalDateTime.ofInstant(Instant.ofEpochMilli(epochMillis), ZoneId.systemDefault()));
    }

    /** 画面の上に出すお知らせを request スコープに入れる。 */
    private static void setNotice(HttpServletRequest request, String variant, String title, String text) {
        request.setAttribute("noticeVariant", variant);
        request.setAttribute("noticeTitle", title);
        request.setAttribute("noticeText", text);
    }

    /**
     * リダイレクト元が預けたメッセージを、forward のときと同じ形に揃える。
     *
     * <p>こうしておくと、JSP 側は「お知らせがあれば出す」と 1 か所書くだけで済みます。</p>
     */
    private static void consumeFlashAsNotice(HttpServletRequest request) {
        Flash.consume(request);
        Object message = request.getAttribute(Flash.ATTRIBUTE_NAME);
        if (message instanceof Flash.Message) {
            Flash.Message flash = (Flash.Message) message;
            setNotice(request, flash.getVariant(), flash.getTitle(), flash.getText());
        }
    }

    /** この画面へリダイレクトする (POST → GET に戻す)。 */
    private static void redirect(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        // パスは必ず getContextPath() から組み立てる (/app のような配備でも壊れないように)
        response.sendRedirect(request.getContextPath() + SAMPLE_PATH);
    }

    /**
     * 画面の表に出す 1 行分。
     *
     * <p>JSP から {@code ${entry.name}} のように参照するため、public な getter を持たせています。</p>
     */
    public static final class Entry {

        private final String scopeName;
        private final String key;
        private final String value;

        Entry(String scopeName, String key, Object value) {
            this.scopeName = scopeName;
            this.key = key;
            this.value = String.valueOf(value);
        }

        /** 接頭辞を除いた、画面で入力した名前。 */
        public String getName() {
            return key.substring(ENTRY_PREFIX.length());
        }

        /** 実際の属性名 (接頭辞つき)。 */
        public String getKey() {
            return key;
        }

        /** 値。 */
        public String getValue() {
            return value;
        }

        /**
         * この値を JSP から取り出すときの書き方。
         *
         * <p>属性名にドットが含まれるため、{@code ${requestScope.scopeSample.entry.x}} とは書けません
         * (EL がプロパティの参照だと解釈します)。角かっこで名前を丸ごと指定します。</p>
         */
        public String getEl() {
            return "${" + scopeName + "['" + key + "']}";
        }
    }
}
