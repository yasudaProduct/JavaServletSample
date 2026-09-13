package com.example.servletsample.web;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.catalog.Category;
import com.example.servletsample.common.BaseServlet;

/**
 * カテゴリ別のサンプル一覧。
 *
 * <p>{@code /categories/basic} のように、URL の末尾がカテゴリ ID になります。
 * {@code /categories/*} でマッピングしているので、
 * {@code request.getPathInfo()} に {@code /basic} が入ります。</p>
 */
@WebServlet(name = "category", urlPatterns = {"/categories/*"})
public class CategoryServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();          // 例: "/basic"
        if (pathInfo == null || pathInfo.length() <= 1) {
            // カテゴリ未指定ならトップへ
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        String categoryId = pathInfo.substring(1);
        Category category = Category.findById(categoryId).orElse(null);
        if (category == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "カテゴリが見つかりません: " + categoryId);
            return;
        }

        request.setAttribute("category", category);
        request.setAttribute("samples", catalog().byCategory(category));
        render(request, response, "category");
    }
}
