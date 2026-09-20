package com.example.servletsample.samples.session;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】ログインとログアウト。
 *
 * <p>HTTP は 1 回のやり取りごとに関係が切れる (ステートレスな) 約束事なので、
 * サーバは「さっきの人」を自力では覚えていません。
 * そこで<b>セッション</b>に「この人はログイン済み」という印を置き、
 * 次のリクエストでその印を確かめます。これがログインの仕組みのすべてです。</p>
 *
 * <pre>{@code
 * ① POST /samples/session/login   ID とパスワードを送る
 * ② 照合する                       マスタのハッシュと突き合わせる
 * ③ セッション ID を振り直す         ← セッション固定攻撃への対策 (下記)
 * ④ セッションに LoginUser を置く
 * ⑤ リダイレクト                    PRG。再読み込みで再ログインされないように
 * }</pre>
 *
 * <h2>ログインに成功したらセッション ID を振り直す</h2>
 * <p>攻撃者があらかじめ用意したセッション ID を利用者に使わせ、
 * その利用者がログインしたあとに<b>同じ ID で入り込む</b>攻撃があります
 * (セッション固定攻撃)。</p>
 *
 * <pre>{@code
 * ［対策しない場合］
 *   攻撃者 : 自分が知っている JSESSIONID=ABC を利用者に使わせる
 *   利用者 : そのままログイン           → ABC が「ログイン済み」になる
 *   攻撃者 : JSESSIONID=ABC でアクセス  → 利用者になりすませてしまう
 *
 * ［対策する場合］
 *   利用者 : ログイン成功 → ID を ABC から XYZ へ振り直す
 *   攻撃者 : ABC でアクセス            → もう誰でもない
 * }</pre>
 *
 * <p>やり方は 2 つあります。</p>
 * <table border="1">
 *   <caption>セッション ID を振り直す 2 つの方法</caption>
 *   <tr><th></th><th>{@code request.changeSessionId()}</th><th>{@code invalidate()} して作り直す</th></tr>
 *   <tr><td>入れてあった値</td><td><b>残る</b></td><td>消える (自分で移し替える)</td></tr>
 *   <tr><td>使えるバージョン</td><td>Servlet 3.1 以降</td><td>いつでも</td></tr>
 *   <tr><td>向いている場面</td><td>ログイン前のカートなどを引き継ぎたい</td>
 *       <td>ログイン前の値をすべて捨てたい</td></tr>
 * </table>
 *
 * <p>このサンプルは {@code changeSessionId()} を使い、
 * 振り直しの前後の ID を画面に出しています。</p>
 */
@WebServlet(name = "login", urlPatterns = {"/samples/session/login"})
public class LoginServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/session/login.jsp";

    /** このサンプルの URL。 */
    static final String PATH = "/samples/session/login";

    /**
     * ログイン後に戻ってよい URL の接頭辞。
     *
     * <p>「元いた画面へ戻す」ために URL を受け取りますが、
     * <b>受け取った値をそのままリダイレクト先にしてはいけません</b>。
     * {@code ?next=https://example.com/} のような値を渡されると、
     * 自サイトのログイン画面を踏み台に外部サイトへ飛ばせてしまいます
     * (オープンリダイレクト。フィッシングの入口になります)。
     * 通してよい形を決めて、外れたら既定の画面へ倒します。</p>
     */
    static final String ALLOWED_NEXT_PREFIX = "/samples/session/";

    /** ログイン時刻を入れておくセッション属性名 (画面に出すだけ)。 */
    static final String LOGGED_IN_AT = "loginSample.loggedInAt";

    /** 振り直す前のセッション ID (画面に出すだけ)。 */
    static final String SESSION_ID_BEFORE = "loginSample.sessionIdBefore";

    private static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /** 画面を表示する。 */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Flash.consume(request);
        request.setAttribute("accounts", UserAccounts.demoRows());
        request.setAttribute("next", safeNext(request.getParameter("next")));
        forward(request, response, VIEW);
    }

    /** ログインを受け付ける。 */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String loginId = Validators.strip(request.getParameter("loginId"));
        String password = request.getParameter("password");
        String next = safeNext(request.getParameter("next"));

        // ------------------------------------------------ ① 未入力チェック
        if (Validators.isBlank(loginId) || Validators.isBlank(password)) {
            failed(request, response, loginId, next, "ログイン ID とパスワードを入力してください。");
            return;
        }

        // ------------------------------------------------ ② 照合
        Optional<UserAccount> account = UserAccounts.authenticate(loginId, password);
        if (account.isEmpty()) {
            // どちらが違うかは伝えない。「その ID は実在する」と教えないため
            getServletContext().log("ログインに失敗しました: loginId=" + loginId);
            failed(request, response, loginId, next,
                    "ログイン ID またはパスワードが正しくありません。");
            return;
        }

        // ------------------------------------------------ ③ セッション ID を振り直す
        HttpSession session = request.getSession();
        String before = session.getId();
        request.changeSessionId();

        // ------------------------------------------------ ④ ログイン済みの印を置く
        session.setAttribute(LoginUser.SESSION_KEY, account.get().toLoginUser());
        session.setAttribute(SESSION_ID_BEFORE, before);
        session.setAttribute(LOGGED_IN_AT, LocalDateTime.now().format(TIME_FORMAT));

        // ------------------------------------------------ ⑤ PRG でリダイレクト
        Flash.set(request, "success", "ログインしました",
                account.get().getName() + " さんとしてログインしています。");
        response.sendRedirect(request.getContextPath() + (next.isEmpty() ? PATH : next));
    }

    /**
     * ログインできなかったときの画面を返す。
     *
     * <p>入力し直してもらうだけなので<b>リダイレクトはしません</b> (forward)。
     * パスワードは画面に戻しません。</p>
     */
    private void failed(HttpServletRequest request, HttpServletResponse response,
                        String loginId, String next, String message)
            throws ServletException, IOException {

        // 401 は「認証が必要 / 認証に失敗した」を表すステータス。
        // sendError ではなく setStatus なので、エラーページには差し替わらず
        // この画面がそのまま返ります (入力し直してもらいたいため)
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        request.setAttribute("loginError", message);
        request.setAttribute("inputLoginId", loginId);
        request.setAttribute("next", next);
        request.setAttribute("accounts", UserAccounts.demoRows());
        forward(request, response, VIEW);
    }

    /**
     * リダイレクト先として受け取ってよい値かどうかを確かめる。
     *
     * @return 通してよい場合はその値。それ以外は空文字
     */
    static String safeNext(String raw) {
        if (raw == null) {
            return "";
        }
        String value = raw.strip();
        if (!value.startsWith(ALLOWED_NEXT_PREFIX)) {
            return "";                       // 別サイトへの誘導、相対パス、空
        }
        if (value.startsWith("//") || value.contains(":") || value.contains("\\")) {
            return "";                       // "//example.com" は別サイトを指す
        }
        return value;
    }

    /** セッションからログイン中の利用者を取り出す。ログインしていなければ空。 */
    public static Optional<LoginUser> currentUser(HttpServletRequest request) {
        // getSession(false) : 無ければ作らない。
        // ここで作ってしまうと、ログインしていない人の分までセッションが積み上がります
        HttpSession session = request.getSession(false);
        if (session == null) {
            return Optional.empty();
        }
        Object user = session.getAttribute(LoginUser.SESSION_KEY);
        return user instanceof LoginUser ? Optional.of((LoginUser) user) : Optional.empty();
    }
}
