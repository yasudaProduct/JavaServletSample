package com.example.servletsample.web;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.catalog.Category;
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
    private static final int FEATURED_COUNT = 6;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("featuredSamples", pickup());
        render(request, response, "home");
    }

    /**
     * トップページに並べるサンプルを選ぶ。
     *
     * <p>先頭から順に取ると同じカテゴリばかりになってしまうので、
     * <b>カテゴリごとに 1 件ずつ</b>拾って、サンプル集の幅が見えるようにしています。
     * それでも足りなければ、残りを登録順に足します。</p>
     */
    private List<Sample> pickup() {
        List<Sample> picked = new ArrayList<>();
        for (Category category : catalog().getCategories()) {
            catalog().byCategory(category).stream()
                    .filter(Sample::isVisitable)
                    .findFirst()
                    .ifPresent(picked::add);
            if (picked.size() >= FEATURED_COUNT) {
                return picked;
            }
        }
        for (Sample sample : catalog().getVisitableSamples()) {
            if (picked.size() >= FEATURED_COUNT) {
                break;
            }
            if (!picked.contains(sample)) {
                picked.add(sample);
            }
        }
        return picked;
    }
}
