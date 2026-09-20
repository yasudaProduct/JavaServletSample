package com.example.servletsample.samples.session;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * CSRF 対策のワンタイムトークン (Synchronizer Token Pattern)。
 *
 * <h2>何を防ぐのか</h2>
 * <p>ブラウザは、あるサイト宛のリクエストに<b>そのサイトの Cookie を自動で付けます</b>。
 * これは、罠のページから送られたリクエストでも同じです。</p>
 *
 * <pre>{@code
 * ① 利用者は銀行サイトにログイン済み (JSESSIONID の Cookie を持っている)
 * ② 罠のページを開く
 *      <form action="https://bank.example/transfer" method="post">
 *        <input type="hidden" name="to" value="攻撃者">
 *        <input type="hidden" name="amount" value="1000000">
 *      </form>
 *      <script>document.forms[0].submit();</script>
 * ③ ブラウザは銀行サイトの Cookie を付けて POST してしまう
 * ④ サーバから見ると「ログイン済みの本人からの、正しい送金依頼」に見える
 * }</pre>
 *
 * <p>これが CSRF (クロスサイト・リクエスト・フォージェリ) です。
 * <b>利用者は何も入力していないのに、処理が実行されてしまいます。</b></p>
 *
 * <h2>どう防ぐのか</h2>
 * <p>「自分のサイトが出したフォームから送られてきた」ことを確かめます。
 * そのために、<b>推測できない値</b>をセッションに持ち、
 * 同じ値をフォームの隠し項目にも入れておいて、送信時に突き合わせます。</p>
 *
 * <pre>{@code
 * ［画面を出すとき］ セッション : token=xY9... / フォーム : <input type="hidden" name="_csrf" value="xY9...">
 * ［受け取るとき  ］ 送られてきた _csrf とセッションの token が一致するか
 * }</pre>
 *
 * <p>罠のページは<b>この値を知りようがありません</b>。
 * Cookie は自動で付いても、フォームの中身までは作れないからです
 * (別のサイトから他サイトの画面の中身を読むことは、ブラウザが禁じています)。</p>
 *
 * <h2>トークンの寿命</h2>
 * <table border="1">
 *   <caption>セッション単位と、リクエスト単位</caption>
 *   <tr><th></th><th>セッションに 1 つ (このサンプル)</th><th>画面ごとに作り直す</th></tr>
 *   <tr><td>安全性</td><td>十分</td><td>より高い (使い回しも防げる)</td></tr>
 *   <tr><td>複数タブ</td><td>問題なし</td><td><b>古いタブで送れなくなる</b></td></tr>
 *   <tr><td>戻るボタン</td><td>問題なし</td><td><b>エラーになりやすい</b></td></tr>
 * </table>
 *
 * <p>一般的な業務システムでは、前者 (セッション単位) で十分です。
 * 後者にすると、利用者から「戻ってもう一度送ったらエラーになる」という
 * 問い合わせが増えます。</p>
 *
 * <h2>やってはいけないこと</h2>
 * <ul>
 *   <li><b>GET で状態を変えない</b> … トークンを URL に付けると、
 *       履歴・ログ・Referer に残ります</li>
 *   <li><b>トークンを Cookie だけに置かない</b> … Cookie は自動で付くので、
 *       Cookie 同士を比べても意味がありません
 *       (二重送信 Cookie 方式にする場合は、必ず本文やヘッダの値と比べます)</li>
 *   <li><b>「Referer が自サイトか」だけで判断しない</b> …
 *       Referer は送られてこないことがあります</li>
 * </ul>
 *
 * <h2>SameSite Cookie との関係</h2>
 * <p>最近のブラウザは Cookie の {@code SameSite} 属性の既定値を {@code Lax} にしており、
 * <b>別サイトからの POST には Cookie を付けません</b>。
 * これだけでも多くの CSRF は防げます。ただし</p>
 * <ul>
 *   <li>古いブラウザには効かない</li>
 *   <li>同じサイトの中に投稿できる箇所があると回避されうる</li>
 *   <li>ブラウザ任せの対策であって、サーバ側の保証ではない</li>
 * </ul>
 * <p>という理由から、<b>トークンによる対策は今も必要</b>です。両方やります。</p>
 */
public final class CsrfToken {

    /** セッションに入れるときの属性名。 */
    static final String SESSION_KEY = "csrfSample.token";

    /** フォームの隠し項目の名前。 */
    public static final String PARAMETER_NAME = "_csrf";

    /** Ajax で送るときのヘッダ名。 */
    public static final String HEADER_NAME = "X-CSRF-Token";

    /** 推測できない値を作るための乱数生成器。 */
    private static final SecureRandom RANDOM = new SecureRandom();

    /** トークンの長さ (バイト)。 */
    private static final int TOKEN_BYTES = 32;

    private CsrfToken() {
    }

    /**
     * トークンを取り出す。まだ無ければ作ってセッションに入れる。
     *
     * <p>{@code synchronized} にしているのは、同じ利用者が複数のタブで
     * 同時に画面を開いたときに、2 つ作られて<b>片方が上書きされる</b>のを防ぐためです。
     * (1 つのセッションに対して直列化すればよいので、セッションを錠にしています)</p>
     */
    public static String issue(HttpSession session) {
        synchronized (session) {
            Object token = session.getAttribute(SESSION_KEY);
            if (token instanceof String && !((String) token).isEmpty()) {
                return (String) token;
            }
            String created = generate();
            session.setAttribute(SESSION_KEY, created);
            return created;
        }
    }

    /**
     * 送られてきたトークンが、セッションのものと一致するか。
     *
     * <p>フォームの隠し項目と、Ajax 用のヘッダの<b>どちらでも</b>受け付けます。</p>
     *
     * <p>セッションが無い (切れた) 場合は {@code false} です。
     * 「セッションが切れていたら素通し」にしてしまうと、対策の意味がありません。</p>
     */
    public static boolean verify(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return false;
        }
        Object expected = session.getAttribute(SESSION_KEY);
        if (!(expected instanceof String) || ((String) expected).isEmpty()) {
            return false;
        }
        String actual = request.getParameter(PARAMETER_NAME);
        if (actual == null || actual.isEmpty()) {
            actual = request.getHeader(HEADER_NAME);
        }
        return tokensMatch((String) expected, actual);
    }

    /**
     * 2 つのトークンが一致するか。
     *
     * <p>パスワードの照合と同じ理由で、<b>一定時間で</b>比べます。
     * {@code equals} で 1 文字ずつ早期に打ち切ると、
     * 応答時間の差から「何文字目まで合っているか」が漏れ、
     * 1 文字ずつ総当たりで当てられてしまうためです。</p>
     *
     * <p>どちらかが空なら、その時点で不一致です。
     * 「トークンが無ければチェックしない」と書いてしまうと、対策の意味がなくなります。</p>
     */
    static boolean tokensMatch(String expected, String actual) {
        if (expected == null || expected.isEmpty() || actual == null || actual.isEmpty()) {
            return false;
        }
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                actual.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * トークンを作り直す。
     *
     * <p>ログインの前後では作り直します。ログイン前に配ったトークンを
     * ログイン後もそのまま使うと、セッション固定攻撃と同じ理屈で
     * 攻撃者に既知の値を使わせられるためです。</p>
     */
    public static String regenerate(HttpSession session) {
        synchronized (session) {
            String created = generate();
            session.setAttribute(SESSION_KEY, created);
            return created;
        }
    }

    /** 推測できない値を作る。 */
    private static String generate() {
        byte[] bytes = new byte[TOKEN_BYTES];
        RANDOM.nextBytes(bytes);
        // URL やフォームに入れるので、記号の出ない形式にする
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
