package com.example.servletsample.samples.basic;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】include と forward（画面の一部を差し込む）。
 *
 * <p>{@code RequestDispatcher} には 2 つの渡し方があります。
 * このサイトの画面はすべて「Servlet が値を用意して JSP へ forward」ですが、
 * ヘッダーやメニューのように<b>画面の一部として差し込みたい</b>ものには
 * include を使います。</p>
 *
 * <p>この画面自身も、デモの中で部品の JSP を 2 回 include しています。
 * 同じ部品に違う値を渡して、2 か所に別の見た目で出しているところを見てください。</p>
 */
@WebServlet(name = "dispatcherInclude", urlPatterns = {"/samples/basic/dispatcher-include"})
public class DispatcherIncludeServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/basic/dispatcher-include.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 部品に渡す値。include 先からは ${...} でそのまま読めます
        request.setAttribute("noticeCount", 3);

        request.setAttribute("demoPath",
                request.getContextPath() + "/samples/basic/dispatcher-include/demo");
        request.setAttribute("partPath",
                request.getContextPath() + DispatcherIncludeDemoServlet.PART);

        // この画面自身が forward で表示されていることの目印
        request.setAttribute("forwardKeys", DispatcherAttributes.FORWARD_KEYS);
        request.setAttribute("includeKeys", DispatcherAttributes.INCLUDE_KEYS);

        forward(request, response, VIEW);
    }
}
