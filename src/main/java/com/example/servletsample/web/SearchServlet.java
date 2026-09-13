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
 * サンプルのキーワード検索。
 *
 * <p>{@code /search?q=フォーム} のように GET パラメータを受け取ります。</p>
 */
@WebServlet(name = "search", urlPatterns = {"/search"})
public class SearchServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String keyword = request.getParameter("q");
        List<Sample> results = catalog().search(keyword);

        request.setAttribute("keyword", keyword == null ? "" : keyword.trim());
        request.setAttribute("results", results);
        render(request, response, "search");
    }
}
