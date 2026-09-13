package com.example.servletsample.web;

import java.io.IOException;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.catalog.Sample;
import com.example.servletsample.common.BaseServlet;

/**
 * トップページ (サンプル集の目次)。
 *
 * <p>URL パターンの {@code ""} (空文字) は「コンテキストルートちょうど」を表します。
 * {@code "/"} と書くと既定サーブレットを置き換えてしまい、CSS などの静的ファイルが
 * 配信されなくなるので注意してください。</p>
 */
@WebServlet(name = "home", urlPatterns = {""})
public class HomeServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** トップページで大きく紹介するサンプルの件数。 */
    private static final int FEATURED_COUNT = 3;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        List<Sample> visitable = catalog().getVisitableSamples();
        List<Sample> featured = visitable.subList(0, Math.min(FEATURED_COUNT, visitable.size()));

        request.setAttribute("featuredSamples", featured);
        render(request, response, "home");
    }
}
