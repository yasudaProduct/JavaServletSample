package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】URL と Servlet の対応づけ。
 *
 * <p>この Servlet 自身が「完全一致」の実例です。サンプルの URL
 * {@code /samples/basic/url-mapping} は前方一致の {@code /samples/*}
 * ({@code SampleDispatcherServlet}) にも当てはまりますが、
 * 完全一致が優先されるのでこちらが呼ばれます。</p>
 *
 * <p>画面では、入力された URL を {@link UrlMappingRules} で判定して
 * 「どの Servlet が呼ばれるか」「{@code getServletPath()} と {@code getPathInfo()} が
 * 何になるか」を表示します。</p>
 */
@WebServlet(name = "urlMapping", urlPatterns = {"/samples/basic/url-mapping"})
public class UrlMappingServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** 画面を開いた直後に判定しておく URL。 */
    static final String DEFAULT_PATH = "/samples/basic/url-mapping/demo/a/b";

    private static final String VIEW = "/WEB-INF/views/samples/basic/url-mapping.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String input = request.getParameter("path");
        String judged = (input == null || input.trim().isEmpty()) ? DEFAULT_PATH : input;

        List<UrlMappingRules.Rule> rules = UrlMappingRules.siteRules();

        request.setAttribute("inputPath", input == null ? DEFAULT_PATH : input);
        request.setAttribute("rules", rules);
        request.setAttribute("match", UrlMappingRules.resolve(judged, rules));
        request.setAttribute("searchOrder", UrlMappingRules.searchOrder(judged));

        // この画面自身がどう呼ばれたかも見せる (完全一致なので pathInfo は null)
        request.setAttribute("thisServletPath", request.getServletPath());
        request.setAttribute("thisPathInfo", request.getPathInfo());

        forward(request, response, VIEW);
    }
}
