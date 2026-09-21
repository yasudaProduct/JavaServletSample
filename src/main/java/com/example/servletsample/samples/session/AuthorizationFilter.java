package com.example.servletsample.samples.session;

import java.io.IOException;
import java.util.Optional;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.Json;

/**
 * 【サンプル】権限が足りない人を弾くフィルタ (認可)。
 *
 * <p>{@link AuthenticationFilter} の<b>あと</b>に動きます。
 * そちらで「誰か」は確定しているので、こちらは「許してよいか」だけを見ます。</p>
 *
 * <pre>{@code
 * ① AuthenticationFilter : ログインしているか   → していなければ 401 / ログイン画面へ
 * ② AuthorizationFilter  : 管理者か             → 違えば 403
 * ③ Servlet              : 本来の処理
 * }</pre>
 *
 * <p>この順番は {@code web.xml} の {@code <filter-mapping>} を書いた順で決まります。
 * 逆にすると「ログインしていない人に 403 を返す」ことになり、
 * <b>ログインすれば通るのか、ログインしても通らないのか</b>が伝わりません。</p>
 *
 * <h2>権限の判定をどこに置くか</h2>
 * <table border="1">
 *   <caption>3 つの層で重ねる</caption>
 *   <tr><th>層</th><th>やること</th><th>やらないこと</th></tr>
 *   <tr><td>画面 (JSP)</td><td>見せないボタンを隠す</td>
 *       <td><b>これだけで守ったつもりにならない</b>。URL を直打ちされたら素通りです</td></tr>
 *   <tr><td>フィルタ</td><td>URL 単位でまとめて弾く</td>
 *       <td>「自分のデータかどうか」のような細かい判定</td></tr>
 *   <tr><td>業務の処理</td><td>「その注文は自分のものか」を確かめる</td><td>-</td></tr>
 * </table>
 *
 * <p>とくに 3 番目を忘れがちです。URL は通ってよくても、
 * {@code ?orderId=1234} を書き換えて<b>他人のデータを開けてしまう</b>形になっていないか、
 * 必ず確かめてください (アクセス制御の不備)。</p>
 */
public class AuthorizationFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        Optional<LoginUser> user = LoginServlet.currentUser(httpRequest);

        // 認証フィルタを通っているので、ここへ来た時点でログイン済みのはず。
        // それでも確かめるのは、設定の順番を間違えたときに素通りさせないためです
        if (user.isPresent() && user.get().isAdmin()) {
            chain.doFilter(request, response);
            return;
        }

        String loginId = user.map(LoginUser::getLoginId).orElse("(未ログイン)");
        httpRequest.getServletContext().log("権限が足りません: user=" + loginId
                + " path=" + httpRequest.getRequestURI());

        if (AuthenticationFilter.wantsJson(httpRequest)) {
            httpResponse.setStatus(HttpServletResponse.SC_FORBIDDEN);
            Json.write(httpResponse, Json.object()
                    .put("ok", false)
                    .put("code", "FORBIDDEN")
                    .put("message", "この操作を行う権限がありません。"));
            return;
        }

        // 403 は「あなたが誰かは分かっているが、許可できない」。
        // ログインし直しても結果は変わらないので、ログイン画面へは送りません
        httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN,
                "管理者だけが開ける画面です");
    }
}
