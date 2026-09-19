package com.example.servletsample.samples.ajax;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.example.servletsample.samples.list.Page;
import com.example.servletsample.samples.list.Product;
import com.example.servletsample.samples.list.ProductDao;
import com.example.servletsample.samples.list.ProductSearch;

/**
 * インクリメンタルサーチの API ({@link AjaxSearchApiServlet}) のテスト。
 *
 * <p>Servlet API に触れない部分 (キーワードの検査・件数の切り詰め・JSON の組み立て) だけを
 * 取り出してあるので、Tomcat を起動せずにそのまま実行できます。
 * 検索そのものは組み込みデータベース (H2) 上の {@link ProductDao} に任せています。</p>
 */
class AjaxSearchApiServletTest {

    private final ProductDao dao = new ProductDao();

    @Test
    @DisplayName("前後の空白を落とす（全角スペースだけの入力も空とみなす）")
    void normalizesKeyword() {
        assertEquals("ペン", AjaxSearchApiServlet.normalize("  ペン "));
        assertEquals("", AjaxSearchApiServlet.normalize(null), "未送信は空文字として扱う");
        assertEquals("", AjaxSearchApiServlet.normalize("　"), "全角スペースも落とす (strip)");
    }

    @Test
    @DisplayName("空のキーワードでは検索しない")
    void doesNotSearchForEmptyKeyword() {
        assertFalse(AjaxSearchApiServlet.isSearchable(""));
        assertFalse(AjaxSearchApiServlet.isSearchable(AjaxSearchApiServlet.normalize("   ")));
        assertTrue(AjaxSearchApiServlet.isSearchable("ペ"));
    }

    @Test
    @DisplayName("整えたキーワードで実際に検索する（全角スペース混じりでも取りこぼさない）")
    void searchesWithNormalizedKeyword() {
        // ProductSearch の trim() は全角スペースを落とさないので、
        // 素のリクエストのままだと「ペン」と答えながら 0 件になってしまう
        HttpServletRequest raw = request(Map.of("q", "　ペン", "category", "文房具"));

        assertEquals("　ペン", ProductSearch.from(raw).getKeyword(), "差し替える前は全角スペースが残る");

        ProductSearch fixed = ProductSearch.from(
                AjaxSearchApiServlet.withKeyword(raw, AjaxSearchApiServlet.normalize("　ペン")));
        assertEquals("ペン", fixed.getKeyword());
        assertEquals("文房具", fixed.getCategory(), "q 以外のパラメータはそのまま読める");

        assertEquals(dao.search(search(Map.of("q", "ペン"))).getTotalCount(),
                dao.search(ProductSearch.from(
                        AjaxSearchApiServlet.withKeyword(request(Map.of("q", "　ペン")), "ペン")))
                        .getTotalCount(),
                "前後の全角スペースがあっても、無いときと同じ件数になる");
    }

    @Test
    @DisplayName("検索しなかったときも、検索したときと同じ形の JSON を返す")
    void returnsSameShapeWhenSkipped() {
        String json = AjaxSearchApiServlet.skipped("", 0).toString();

        assertTrue(json.contains("\"searched\":false"), json);
        assertTrue(json.contains("\"items\":[]"), json);
        assertTrue(json.contains("\"total\":0"), json);
        assertTrue(json.contains("\"limit\":" + AjaxSearchApiServlet.SUGGEST_LIMIT), json);
    }

    @Test
    @DisplayName("候補は上限の件数までに切り詰める")
    void limitsSuggestions() {
        List<Product> fifty = dao.search(search(Map.of("q", "P-00", "size", "50"))).getItems();
        assertEquals(50, fifty.size(), "切り詰める前は 50 件");

        List<Product> limited = AjaxSearchApiServlet.limit(fifty, AjaxSearchApiServlet.SUGGEST_LIMIT);
        assertEquals(AjaxSearchApiServlet.SUGGEST_LIMIT, limited.size());
        assertEquals(fifty.get(0), limited.get(0), "先頭から順に残る");

        List<Product> few = dao.search(search(Map.of("q", "P-0001"))).getItems();
        assertSame(few, AjaxSearchApiServlet.limit(few, AjaxSearchApiServlet.SUGGEST_LIMIT),
                "上限以下なら作り直さない");
    }

    @Test
    @DisplayName("上限で切り詰めても、総件数はそのまま返す")
    void keepsTotalCountEvenWhenTruncated() {
        Page<Product> page = dao.search(search(Map.of("q", "P-00", "size", "50")));
        List<Product> shown = AjaxSearchApiServlet.limit(page.getItems(), AjaxSearchApiServlet.SUGGEST_LIMIT);

        String json = AjaxSearchApiServlet.toJson("P-00", page, shown, 0, 1).toString();

        assertTrue(json.contains("\"total\":60"), "「60 件見つかりました」と書けること: " + json);
        assertTrue(json.contains("\"truncated\":true"), json);
        assertEquals(AjaxSearchApiServlet.SUGGEST_LIMIT, countOf(json, "\"code\":"), "候補は 10 件だけ");
    }

    @Test
    @DisplayName("0 件のときは items が空になる")
    void returnsEmptyItems() {
        Page<Product> page = dao.search(search(Map.of("q", "存在しない商品名")));
        String json = AjaxSearchApiServlet.toJson("存在しない商品名", page, page.getItems(), 0, 1).toString();

        assertTrue(json.contains("\"total\":0"), json);
        assertTrue(json.contains("\"items\":[]"), json);
        assertTrue(json.contains("\"truncated\":false"), json);
    }

    @Test
    @DisplayName("商品の値が JSON に入る")
    void writesProductFields() {
        Page<Product> page = dao.search(search(Map.of("q", "P-0001")));
        String json = AjaxSearchApiServlet.toJson("P-0001", page, page.getItems(), 0, 1).toString();

        assertTrue(json.contains("\"code\":\"P-0001\""), json);
        assertTrue(json.contains("\"name\":\"ボールペン (黒・0.5mm)\""), json);
        assertTrue(json.contains("\"price\":130"), "数値は引用符なしで入る: " + json);
        assertTrue(json.contains("\"inStock\":true"), json);
    }

    @Test
    @DisplayName("わざと遅くする待ち時間は、キーワードが短いほど長い")
    void slowResponseFavorsLongerKeyword() {
        long one = AjaxSearchApiServlet.delayMillisFor("ペ");
        long two = AjaxSearchApiServlet.delayMillisFor("ペン");
        long three = AjaxSearchApiServlet.delayMillisFor("ボール");

        // 「ペ」の応答が「ペン」より後に返る → 古い結果で上書きする競合を確実に再現できる
        assertTrue(one > two, one + " > " + two);
        assertTrue(two > three, two + " > " + three);
        assertTrue(AjaxSearchApiServlet.delayMillisFor("とても長いキーワード") > 0, "下限より小さくはならない");
    }

    /** パラメータだけを返す最小限の {@link HttpServletRequest} から検索条件を作る (テスト用)。 */
    private static ProductSearch search(Map<String, String> parameters) {
        return ProductSearch.from(request(parameters));
    }

    /** パラメータだけを返す最小限の {@link HttpServletRequest} (テスト用)。 */
    private static HttpServletRequest request(Map<String, String> parameters) {
        Map<String, String> values = new HashMap<>(parameters);
        return (HttpServletRequest) Proxy.newProxyInstance(
                AjaxSearchApiServletTest.class.getClassLoader(),
                new Class<?>[]{HttpServletRequest.class},
                (proxy, method, args) -> "getParameter".equals(method.getName())
                        ? values.get((String) args[0])
                        : null);
    }

    /** 文字列の中に needle が何回出てくるか。 */
    private static int countOf(String text, String needle) {
        int count = 0;
        for (int i = text.indexOf(needle); i >= 0; i = text.indexOf(needle, i + needle.length())) {
            count++;
        }
        return count;
    }
}
