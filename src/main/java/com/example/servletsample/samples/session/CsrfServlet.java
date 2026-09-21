package com.example.servletsample.samples.session;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.Json;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】CSRF 対策（ワンタイムトークン）。
 *
 * <p>「メールアドレスの変更」を題材に、トークンを付けた場合と付けない場合で
 * 受け付けられ方がどう変わるかを確かめます。</p>
 *
 * <h2>受け取り側の形</h2>
 * <pre>{@code
 * protected void doPost(...) {
 *     if (!CsrfToken.verify(request)) {
 *         // 「たまたま失敗した」ではなく「攻撃かもしれない」。
 *         // 入力し直しを促さず、処理を中止してログに残す
 *         response.setStatus(403);
 *         ...
 *         return;
 *     }
 *     ... 本来の処理 ...
 * }
 * }</pre>
 *
 * <h2>本来はフィルタに置く</h2>
 * <p>このサンプルでは分かりやすさのため Servlet の中で確かめていますが、
 * <b>実務では更新系のリクエストすべてに掛かるフィルタ</b>に置きます。
 * 画面ごとに書くと、ログインの確認と同じで必ず書き漏れます。</p>
 *
 * <pre>{@code
 * if (!"GET".equals(method) && !"HEAD".equals(method) && !CsrfToken.verify(request)) {
 *     response.sendError(403);
 *     return;                       // chain.doFilter を呼ばない
 * }
 * }</pre>
 *
 * <p>このサイトでは、他のサンプルの POST まで弾いてしまわないよう、
 * フィルタにはしていません。</p>
 */
@WebServlet(name = "csrf", urlPatterns = {"/samples/session/csrf", "/samples/session/csrf/api"})
public class CsrfServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/session/csrf.jsp";

    /** このサンプルの URL。 */
    static final String PATH = "/samples/session/csrf";

    /** Ajax から呼ぶ URL。 */
    static final String API_PATH = "/samples/session/csrf/api";

    /** 変更した値を覚えておくセッション属性名 (デモ用)。 */
    static final String CURRENT_EMAIL = "csrfSample.email";

    /** 初期値。 */
    static final String DEFAULT_EMAIL = "taro@example.com";

    private static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("HH:mm:ss");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (API_PATH.equals(request.getServletPath())) {
            // API は GET を受け付けない (状態を変える処理なので)
            response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                    "この URL は POST でのみ受け付けます");
            return;
        }

        Flash.consume(request);
        prepare(request);
        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        boolean fromApi = API_PATH.equals(request.getServletPath());

        // ------------------------------------------------ ① まずトークンを確かめる
        //
        // 入力チェックより先です。トークンが合わない時点で、
        // 中身を見る必要はありません
        if (!CsrfToken.verify(request)) {
            // 「たまたま失敗した」ではなく「攻撃かもしれない」ので、必ずログに残す
            getServletContext().log("CSRF トークンが一致しませんでした: "
                    + request.getServletPath()
                    + " referer=" + String.valueOf(request.getHeader("Referer")));

            if (fromApi) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                Json.write(response, Json.object()
                        .put("ok", false)
                        .put("code", "CSRF_TOKEN_MISMATCH")
                        .put("message", "トークンが一致しないため、処理を中止しました。"));
                return;
            }

            // setStatus なのでエラーページには差し替わらず、この画面がそのまま返ります。
            // 「何が起きたか」を見せたいサンプルなのでこうしていますが、
            // 実務では sendError(403) でエラーページへ送って構いません
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            request.setAttribute("csrfError",
                    "トークンが一致しないため、処理を中止しました。(HTTP 403)");
            prepare(request);
            forward(request, response, VIEW);
            return;
        }

        // ------------------------------------------------ ② 本来の処理
        String email = Validators.strip(request.getParameter("email"));
        if (Validators.isBlank(email)) {
            email = DEFAULT_EMAIL;
        }
        request.getSession().setAttribute(CURRENT_EMAIL, email);

        if (fromApi) {
            Json.write(response, Json.object()
                    .put("ok", true)
                    .put("email", email)
                    .put("changedAt", LocalDateTime.now().format(TIME_FORMAT))
                    .put("message", "トークンが一致したので、変更を受け付けました。"));
            return;
        }

        // ------------------------------------------------ ③ PRG
        Flash.set(request, "success", "変更しました",
                "メールアドレスを " + email + " に変更しました。");
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /** 画面に渡す値をそろえる。 */
    private void prepare(HttpServletRequest request) {
        // トークンはセッションに 1 つ。無ければここで作られる
        request.setAttribute("csrfToken", CsrfToken.issue(request.getSession()));
        request.setAttribute("csrfParameterName", CsrfToken.PARAMETER_NAME);
        request.setAttribute("csrfHeaderName", CsrfToken.HEADER_NAME);
        request.setAttribute("apiPath", request.getContextPath() + API_PATH);

        Object email = request.getSession().getAttribute(CURRENT_EMAIL);
        request.setAttribute("currentEmail", email == null ? DEFAULT_EMAIL : email);
    }
}
