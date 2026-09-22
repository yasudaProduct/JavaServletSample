package com.example.servletsample.common;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.catalog.SampleCatalog;
import com.example.servletsample.catalog.TopicCatalog;

/**
 * このサンプル集の Servlet が共通で使う土台。
 *
 * <p>「JSP は {@code /WEB-INF/views/} の下に置き、Servlet 経由でしか表示しない」
 * という構成にしているため、転送処理をここにまとめています。</p>
 */
public abstract class BaseServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** JSP の置き場所。 */
    protected static final String VIEW_PREFIX = "/WEB-INF/views/";

    /** JSP の拡張子。 */
    protected static final String VIEW_SUFFIX = ".jsp";

    /**
     * ビュー名を指定して JSP へ転送する。
     * <p>{@code render(req, res, "home")} → {@code /WEB-INF/views/home.jsp}</p>
     */
    protected void render(HttpServletRequest request, HttpServletResponse response, String viewName)
            throws ServletException, IOException {
        forward(request, response, VIEW_PREFIX + viewName + VIEW_SUFFIX);
    }

    /** JSP のパスを直接指定して転送する。 */
    protected void forward(HttpServletRequest request, HttpServletResponse response, String viewPath)
            throws ServletException, IOException {
        request.getRequestDispatcher(viewPath).forward(request, response);
    }

    /** サンプルカタログ。 */
    protected SampleCatalog catalog() {
        return SampleCatalog.getInstance();
    }

    /** 座学メモのカタログ。 */
    protected TopicCatalog topics() {
        return TopicCatalog.getInstance();
    }
}
