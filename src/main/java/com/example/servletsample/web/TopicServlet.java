package com.example.servletsample.web;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.catalog.Topic;
import com.example.servletsample.common.BaseServlet;

/**
 * 座学メモの一覧と本文。
 *
 * <p>URL パターンを 2 つ登録しているのがポイントです。</p>
 * <ul>
 *   <li>{@code /topics} &nbsp;… 完全一致。一覧ページ</li>
 *   <li>{@code /topics/*} … 前方一致。{@code getPathInfo()} に {@code /request-lifecycle} が入る</li>
 * </ul>
 *
 * <p>前方一致だけでも {@code /topics} は拾えますが、
 * 「一覧」と「本文」という別の役割であることを URL パターンからも読めるようにしています。
 * どちらが選ばれるかは「基本 &gt; URL と Servlet の対応づけ」のサンプルで確かめられます。</p>
 */
@WebServlet(name = "topic", urlPatterns = {"/topics", "/topics/*"})
public class TopicServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();          // 例: "/request-lifecycle"

        // /topics そのもの (完全一致なら null、前方一致なら "/") は一覧ページ
        if (pathInfo == null || pathInfo.length() <= 1) {
            render(request, response, "topics");
            return;
        }
        // 末尾のスラッシュは無視する
        if (pathInfo.endsWith("/")) {
            pathInfo = pathInfo.substring(0, pathInfo.length() - 1);
        }

        String path = request.getServletPath() + pathInfo;   // 例: "/topics/request-lifecycle"
        Topic topic = topics().byPath(path);
        if (topic == null || !topic.isVisitable()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "座学メモが見つかりません: " + path);
            return;
        }

        request.setAttribute("topic", topic);
        forward(request, response, topic.getViewPath());
    }
}
