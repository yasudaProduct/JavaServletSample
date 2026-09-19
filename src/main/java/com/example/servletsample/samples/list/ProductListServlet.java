package com.example.servletsample.samples.list;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】検索条件つきの一覧画面 (ページング・並び替えあり)。
 *
 * <p>やっていることは単純で、</p>
 * <ol>
 *   <li>URL のパラメータ ({@code ?q=...&page=2&sort=price}) を {@link ProductSearch} で受け取る</li>
 *   <li>{@link ProductDao#search} で「そのページの行」と「全件数」を取る</li>
 *   <li>{@link Page} にまとめて JSP へ渡す</li>
 * </ol>
 *
 * <p>検索条件を <b>GET</b> (URL のパラメータ) で受け取っているのがポイントです。
 * こうすると「2 ページ目の検索結果」をそのままブックマークしたり、
 * 人に URL を送ったりできます。ページ送りのリンクも普通の {@code <a>} で書けます。</p>
 */
@WebServlet(name = "productList", urlPatterns = {"/samples/list/search-list"})
public class ProductListServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/list/search-list.jsp";

    private final ProductDao dao = new ProductDao();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        ProductSearch search = ProductSearch.from(request);
        Page<Product> productPage = dao.search(search);

        // 「5 ページ目を見ていて、条件を絞ったら 2 ページしか無くなった」ときの手当て
        if (search.getPage() > productPage.getTotalPages()) {
            search = search.withPage(productPage.getTotalPages());
            productPage = dao.search(search);
        }

        request.setAttribute("search", search);
        request.setAttribute("productPage", productPage);
        request.setAttribute("categories", dao.findCategories());
        request.setAttribute("allCount", dao.countAll());
        request.setAttribute("executedSql", dao.describeSql(search));
        forward(request, response, VIEW);
    }
}
