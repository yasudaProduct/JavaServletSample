package com.example.servletsample.samples.session;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】フィルタで未ログインを弾く (説明ページ)。
 *
 * <p>この画面自体は<b>誰でも開けます</b>。保護されているのは、この下の 3 つの URL です。</p>
 *
 * <table border="1">
 *   <caption>保護している URL</caption>
 *   <tr><th>URL</th><th>掛けているフィルタ</th><th>入れる人</th></tr>
 *   <tr><td>{@code /samples/session/auth-filter/member}</td>
 *       <td>認証</td><td>ログインしていれば誰でも</td></tr>
 *   <tr><td>{@code /samples/session/auth-filter/admin}</td>
 *       <td>認証 → 認可</td><td>管理者だけ</td></tr>
 *   <tr><td>{@code /samples/session/auth-filter/api}</td>
 *       <td>認証</td><td>ログインしていれば誰でも (未ログインなら 401 の JSON)</td></tr>
 * </table>
 */
@WebServlet(name = "authFilter", urlPatterns = {"/samples/session/auth-filter"})
public class AuthFilterServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/session/auth-filter.jsp";

    /** このサンプルの URL。 */
    static final String PATH = "/samples/session/auth-filter";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("memberPath", request.getContextPath() + ProtectedPageServlet.MEMBER_PATH);
        request.setAttribute("adminPath", request.getContextPath() + ProtectedPageServlet.ADMIN_PATH);
        request.setAttribute("apiPath", request.getContextPath() + AuthApiServlet.PATH);
        request.setAttribute("loginPath", request.getContextPath() + LoginServlet.PATH);
        forward(request, response, VIEW);
    }
}
