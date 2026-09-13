package com.example.servletsample.web;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.catalog.Sample;
import com.example.servletsample.common.BaseServlet;

/**
 * サンプルページの既定の受け口。
 *
 * <p>{@code /samples/*} に来たリクエストをカタログから探し、対応する JSP へ転送します。
 * これにより「JSP を 1 枚置いてカタログに登録するだけ」でサンプルが増やせます。</p>
 *
 * <p>Servlet の処理が必要なサンプルは
 * {@code @WebServlet("/samples/basic/hello-world")} のように<b>完全一致</b>でマッピングしてください。
 * Servlet 仕様では完全一致のマッピングが前方一致 ({@code /samples/*}) より優先されるため、
 * そちらが呼ばれます。</p>
 */
@WebServlet(name = "sampleDispatcher", urlPatterns = {"/samples/*"})
public class SampleDispatcherServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();          // 例: "/design/bootstrap-basics"
        if (pathInfo == null || pathInfo.length() <= 1) {
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }
        // 末尾のスラッシュは無視する
        if (pathInfo.endsWith("/")) {
            pathInfo = pathInfo.substring(0, pathInfo.length() - 1);
        }

        String path = request.getServletPath() + pathInfo;   // 例: "/samples/design/bootstrap-basics"
        Sample sample = catalog().byPath(path);
        if (sample == null || !sample.isVisitable()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "サンプルが見つかりません: " + path);
            return;
        }

        request.setAttribute("sample", sample);
        forward(request, response, sample.getViewPath());
    }
}
