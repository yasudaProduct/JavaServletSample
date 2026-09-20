package com.example.servletsample.samples.session;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】フィルタで守られている画面。
 *
 * <p>注目してほしいのは、この Servlet が<b>ログインの確認を 1 行も書いていない</b>ことです。
 * ここへ処理が届いた時点で、フィルタが済ませてくれています。</p>
 *
 * <pre>{@code
 * // この 3 行のような確認が、どの画面にも要らなくなる
 * if (request.getSession().getAttribute("loginUser") == null) {
 *     response.sendRedirect(...);
 *     return;
 * }
 * }</pre>
 *
 * <p>とはいえ「誰がログインしているか」は使いたいので、
 * セッションから取り出すところだけは残ります
 * ({@code ${loginUser}} で JSP からも参照できます)。</p>
 *
 * <p>1 つの Servlet に 2 つの URL を割り当て、
 * {@link HttpServletRequest#getServletPath()} でどちらから来たかを見ています。
 * 中身がほぼ同じ画面を 2 つ作らないための書き方です。</p>
 */
@WebServlet(name = "protectedPage", urlPatterns = {
        ProtectedPageServlet.MEMBER_PATH,
        ProtectedPageServlet.ADMIN_PATH
})
public class ProtectedPageServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** ログインしていれば誰でも開ける画面。 */
    static final String MEMBER_PATH = "/samples/session/auth-filter/member";

    /** 管理者だけが開ける画面。 */
    static final String ADMIN_PATH = "/samples/session/auth-filter/admin";

    private static final String VIEW = "/WEB-INF/views/samples/session/auth-filter-protected.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        boolean adminOnly = ADMIN_PATH.equals(request.getServletPath());
        request.setAttribute("adminOnly", adminOnly);
        request.setAttribute("backPath", request.getContextPath() + AuthFilterServlet.PATH);
        forward(request, response, VIEW);
    }
}
