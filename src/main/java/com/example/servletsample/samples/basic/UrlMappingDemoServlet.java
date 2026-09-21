package com.example.servletsample.samples.basic;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;

/**
 * 【サンプル】URL マッピングのデモ用。呼ばれたときの情報を JSON で返します。
 *
 * <p><b>1 つの Servlet に 3 つのパターンを登録しています。</b>
 * {@code urlPatterns} は配列なので、形の違うパターンをいくつでも並べられます。</p>
 *
 * <table border="1">
 *   <caption>この Servlet に登録したパターン</caption>
 *   <tr><th>パターン</th><th>形</th><th>当たる URL の例</th></tr>
 *   <tr><td>{@code /samples/basic/url-mapping/demo/exact}</td><td>完全一致</td>
 *       <td>{@code /samples/basic/url-mapping/demo/exact} だけ</td></tr>
 *   <tr><td>{@code /samples/basic/url-mapping/demo/*}</td><td>前方一致</td>
 *       <td>{@code /samples/basic/url-mapping/demo/a/b} など、その下すべて</td></tr>
 *   <tr><td>{@code *.mapping}</td><td>拡張子一致</td>
 *       <td>{@code /report.mapping} など</td></tr>
 * </table>
 *
 * <p>返す JSON には {@code getServletPath()} と {@code getPathInfo()} を入れています。
 * <b>この 2 つを見れば、どのパターンで呼ばれたかが分かります。</b></p>
 *
 * <ul>
 *   <li>完全一致 … {@code servletPath} が URL 全体で、{@code pathInfo} は {@code null}</li>
 *   <li>前方一致 … {@code servletPath} が {@code /*} を除いた部分、{@code pathInfo} が余り</li>
 *   <li>拡張子一致 … {@code servletPath} が URL 全体で、{@code pathInfo} は {@code null}</li>
 * </ul>
 *
 * <p>なお、{@code *.mapping} のような拡張子一致は<b>アプリ全体</b>に効きます。
 * サンプルの中だけで使いたいものを拡張子で登録すると、思わぬ URL を横取りしてしまうので、
 * 実務では前方一致か完全一致を選んでください
 * (ここでは「拡張子一致とはどう効くか」を見せるためにあえて登録しています)。</p>
 */
@WebServlet(name = "urlMappingDemo", urlPatterns = {
        "/samples/basic/url-mapping/demo/exact",
        "/samples/basic/url-mapping/demo/*",
        "*.mapping"})
public class UrlMappingDemoServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // コンテナが実際に決めた値。画面ではこれと UrlMappingRules の判定を見比べます
        String servletPath = request.getServletPath();
        String pathInfo = request.getPathInfo();

        UrlMappingRules.Match predicted =
                UrlMappingRules.resolve(servletPath + (pathInfo == null ? "" : pathInfo),
                        UrlMappingRules.siteRules());

        Json.write(response, Json.object()
                // コンテナが渡してきた値
                .put("requestURI", request.getRequestURI())
                .put("contextPath", request.getContextPath())
                .put("servletPath", servletPath)
                .put("pathInfo", pathInfo)
                .put("queryString", request.getQueryString())
                .put("method", request.getMethod())
                // web.xml / @WebServlet で付けた名前。どの Servlet が答えたかの証拠
                .put("servletName", getServletName())
                .put("servletClass", getClass().getSimpleName())
                // こちらは UrlMappingRules による予想
                .put("predictedPattern", predicted.getRule() == null
                        ? null : predicted.getRule().getPattern())
                .put("predictedKind", predicted.getKind().getLabel()));
    }
}
