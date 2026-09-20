package com.example.servletsample.samples.session;

import java.io.IOException;
import java.util.Optional;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;

/**
 * 【サンプル】フィルタで守られた JSON API。
 *
 * <p>未ログインのときに<b>ここへ到達しません</b>。
 * {@link AuthenticationFilter} が 401 と JSON を返して折り返します。</p>
 *
 * <p>画面側 (fetch) は、次のように「401 なら再ログインを促す」形にしておきます。</p>
 *
 * <pre>{@code
 * const res = await fetch(apiUrl, { headers: { Accept: 'application/json' } });
 * if (res.status === 401) {
 *     // セッションが切れている。ログイン画面へ送る
 *     location.href = (await res.json()).loginUrl;
 *     return;
 * }
 * }</pre>
 *
 * <p>これをやっていないと、セッションが切れた瞬間に
 * 「ボタンを押しても何も起きない」画面になります。
 * <b>長く開きっぱなしにされる画面ほど、この分岐が効きます。</b></p>
 */
@WebServlet(name = "authApi", urlPatterns = {AuthApiServlet.PATH})
public class AuthApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** この API の URL。 */
    static final String PATH = "/samples/session/auth-filter/api";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        // フィルタを通っているので、ここでは必ずログイン済み
        Optional<LoginUser> user = LoginServlet.currentUser(request);

        Json.write(response, Json.object()
                .put("ok", true)
                .put("loginId", user.map(LoginUser::getLoginId).orElse(""))
                .put("name", user.map(LoginUser::getName).orElse(""))
                .put("role", user.map(u -> u.getRole().getLabel()).orElse(""))
                .put("message", "フィルタを通り抜けて API まで届きました。"));
    }
}
