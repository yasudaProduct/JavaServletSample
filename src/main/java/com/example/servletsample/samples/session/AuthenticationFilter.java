package com.example.servletsample.samples.session;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.Json;

/**
 * 【サンプル】ログインしていない人を弾くフィルタ (認証)。
 *
 * <p>「セッションにログイン済みの印があるか」を確かめるだけの処理ですが、
 * <b>画面ごとに書くと必ず書き漏れます</b>。
 * 1 か所でも漏れると、そこから中に入れてしまいます。
 * だからフィルタにまとめ、<b>URL で一括して掛ける</b>のが定石です。</p>
 *
 * <pre>{@code
 * if (ログインしていない) {
 *     ... ログイン画面へ送る ...
 *     return;                       // ← chain.doFilter を呼ばない
 * }
 * chain.doFilter(request, response);
 * }</pre>
 *
 * <h2>認証 (このクラス) と認可 ({@link AuthorizationFilter}) は別もの</h2>
 * <table border="1">
 *   <caption>401 と 403 の違い</caption>
 *   <tr><th></th><th>認証 (Authentication)</th><th>認可 (Authorization)</th></tr>
 *   <tr><td>問い</td><td>あなたは誰ですか</td><td>あなたにそれを許してよいですか</td></tr>
 *   <tr><td>通らないとき</td><td><b>401</b> Unauthorized</td><td><b>403</b> Forbidden</td></tr>
 *   <tr><td>利用者の対処</td><td>ログインすれば通る</td><td>ログインし直しても通らない</td></tr>
 * </table>
 *
 * <p>名前に反して 401 は「認証されていない」という意味です。
 * ログイン済みで権限が足りないときは 403 を返します。</p>
 *
 * <h2>画面と API で返し方を変える</h2>
 * <p><b>Ajax の呼び先でリダイレクトを返してはいけません。</b>
 * {@code fetch} はリダイレクトを自動で追いかけるので、
 * 画面側は<b>ログイン画面の HTML を JSON として受け取ろうとして</b>壊れます。
 * 「なぜか JSON が壊れる」の原因がセッション切れだった、というのはよくある話です。</p>
 *
 * <pre>{@code
 * ［画面］ 未ログイン → 302 でログイン画面へ (戻り先を ?next= で覚えておく)
 * ［API ］ 未ログイン → 401 + {"ok":false,...}  画面側が「再ログインしてください」を出せる
 * }</pre>
 *
 * <h2>掛ける範囲を絞る</h2>
 * <p>{@code web.xml} では、保護したい URL だけを列挙しています。
 * このサンプルの説明ページ自体 ({@code /samples/session/auth-filter}) は
 * ログインしていなくても開けるようにしたいためです。</p>
 *
 * <p>なお {@code <url-pattern>/samples/session/auth-filter/*</url-pattern>} と書くと、
 * <b>末尾の {@code /*} が無い {@code /samples/session/auth-filter} 自身にも掛かります</b>
 * (前方一致のマッピングは、その前置き部分そのものにも一致します)。
 * 「説明ページだけは外したい」ときに引っかかりやすい点です。</p>
 */
public class AuthenticationFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // ログイン済みならそのまま通す
        if (LoginServlet.currentUser(httpRequest).isPresent()) {
            chain.doFilter(request, response);
            return;
        }

        // ------------------------------------------------ API の場合
        if (wantsJson(httpRequest)) {
            httpResponse.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            httpResponse.setHeader("Cache-Control", "no-store");
            Json.write(httpResponse, Json.object()
                    .put("ok", false)
                    .put("code", "UNAUTHENTICATED")
                    .put("message", "セッションが切れています。ログインし直してください。")
                    // 画面側が「どこへ送ればよいか」を判断できるように添えておく
                    .put("loginUrl", httpRequest.getContextPath() + LoginServlet.PATH));
            return;
        }

        // ------------------------------------------------ 画面の場合
        // 元いた画面を覚えておき、ログイン後に戻す。
        // 覚えるのは「コンテキストルートからのパス」だけにして、
        // 受け取る側 (LoginServlet.safeNext) でも改めて形を確かめます
        String next = httpRequest.getRequestURI()
                .substring(httpRequest.getContextPath().length());
        httpResponse.sendRedirect(httpRequest.getContextPath() + LoginServlet.PATH
                + "?next=" + URLEncoder.encode(next, StandardCharsets.UTF_8));
    }

    /**
     * JSON を期待している呼び出しかどうか。
     *
     * <p>完全に見分ける方法はないので、次の 2 つで判断しています。</p>
     * <ul>
     *   <li>{@code Accept} ヘッダに {@code application/json} が入っている</li>
     *   <li>{@code X-Requested-With: XMLHttpRequest} が付いている (古くからの慣習)</li>
     * </ul>
     *
     * <p>迷ったら「API 用の URL は {@code /api/} で始める」と決めてしまい、
     * <b>パスで分ける</b>のがいちばん確実です。</p>
     */
    static boolean wantsJson(HttpServletRequest request) {
        String accept = request.getHeader("Accept");
        if (accept != null && accept.contains("application/json")) {
            return true;
        }
        return "XMLHttpRequest".equals(request.getHeader("X-Requested-With"));
    }
}
