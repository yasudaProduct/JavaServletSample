package com.example.servletsample.samples.list;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Proxy;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 検索・ページング ({@link ProductDao}) のテスト。
 *
 * <p>組み込みデータベース (H2) をメモリ上で動かすため、
 * Tomcat を起動しなくてもそのまま実行できます。</p>
 */
class ProductDaoTest {

    private final ProductDao dao = new ProductDao();

    @Test
    @DisplayName("サンプルデータが登録されている")
    void hasSeedData() {
        assertEquals(60, dao.countAll());
        assertFalse(dao.findCategories().isEmpty());
    }

    @Test
    @DisplayName("1 ページの件数だけ取り出し、全件数も分かる")
    void returnsOnePage() {
        Page<Product> page = dao.search(search(Map.of()));

        assertEquals(10, page.getItems().size(), "既定は 10 件ずつ");
        assertEquals(60, page.getTotalCount(), "全件数は 60 件");
        assertEquals(6, page.getTotalPages());
        assertEquals(1, page.getNumber());
    }

    @Test
    @DisplayName("2 ページ目は 11 件目から取り出される")
    void returnsSecondPage() {
        List<Product> first = dao.search(search(Map.of())).getItems();
        Page<Product> second = dao.search(search(Map.of("page", "2")));

        assertEquals(10, second.getItems().size());
        assertEquals("P-0011", second.getItems().get(0).getCode());
        assertFalse(first.contains(second.getItems().get(0)), "1 ページ目と重複していない");
    }

    @Test
    @DisplayName("最終ページは端数だけになる")
    void returnsLastPage() {
        Page<Product> page = dao.search(search(Map.of("size", "50", "page", "2")));

        assertEquals(10, page.getItems().size(), "60 件を 50 件ずつなら 2 ページ目は 10 件");
        assertEquals(2, page.getTotalPages());
        assertTrue(page.isLast());
    }

    @Test
    @DisplayName("キーワードで商品名・コード・カテゴリを横断して検索できる")
    void searchesByKeyword() {
        Page<Product> byName = dao.search(search(Map.of("q", "ボトル")));
        assertFalse(byName.getItems().isEmpty());
        assertTrue(byName.getItems().stream().allMatch(p -> p.getName().contains("ボトル")));

        Page<Product> byCategory = dao.search(search(Map.of("q", "文房具")));
        assertEquals(10, byCategory.getTotalCount());

        Page<Product> byCode = dao.search(search(Map.of("q", "P-0001")));
        assertEquals(1, byCode.getTotalCount());
    }

    @Test
    @DisplayName("一致しないキーワードなら 0 件になる")
    void returnsEmptyResult() {
        Page<Product> page = dao.search(search(Map.of("q", "存在しない商品名")));

        assertTrue(page.isEmpty());
        assertEquals(0, page.getTotalCount());
        assertEquals(1, page.getTotalPages(), "0 件でもページ数は 1");
    }

    @Test
    @DisplayName("LIKE のワイルドカードは文字として扱われる")
    void escapesLikeWildcards() {
        // エスケープしていないと "%" が「何にでも一致」になり全件返ってしまう
        assertEquals(0, dao.search(search(Map.of("q", "%"))).getTotalCount());
        assertEquals(0, dao.search(search(Map.of("q", "_"))).getTotalCount());
        assertEquals("!%", ProductDao.escapeLike("%"));
        assertEquals("a!_b", ProductDao.escapeLike("a_b"));
    }

    @Test
    @DisplayName("カテゴリと在庫の有無で絞り込める")
    void filtersByCategoryAndStock() {
        Page<Product> byCategory = dao.search(search(Map.of("category", "デジタル家電")));
        assertEquals(10, byCategory.getTotalCount());
        assertTrue(byCategory.getItems().stream().allMatch(p -> "デジタル家電".equals(p.getCategory())));

        Page<Product> inStock = dao.search(search(Map.of("stock", "on", "size", "50")));
        assertTrue(inStock.getTotalCount() < 60, "在庫切れの商品が除かれている");
        assertTrue(inStock.getItems().stream().allMatch(Product::isInStock));
    }

    @Test
    @DisplayName("条件を組み合わせると AND で絞り込まれる")
    void combinesConditions() {
        Page<Product> page = dao.search(search(Map.of("q", "ペン", "category", "文房具")));

        assertFalse(page.isEmpty());
        assertTrue(page.getItems().stream()
                .allMatch(p -> "文房具".equals(p.getCategory()) && p.getName().contains("ペン")));
    }

    @Test
    @DisplayName("指定した列で昇順・降順に並べ替えられる")
    void sortsByColumn() {
        List<Product> ascending = dao.search(search(Map.of("sort", "price", "order", "asc"))).getItems();
        List<Product> descending = dao.search(search(Map.of("sort", "price", "order", "desc"))).getItems();

        assertTrue(isSorted(ascending, Comparator.comparingInt(Product::getPrice)));
        assertTrue(isSorted(descending, Comparator.comparingInt(Product::getPrice).reversed()));
        assertEquals(130, ascending.get(0).getPrice(), "いちばん安いのはボールペン");
        assertEquals(68000, descending.get(0).getPrice(), "いちばん高いのは昇降デスク");
    }

    @Test
    @DisplayName("並び替えに知らない列名を指定されても既定の並びに戻す")
    void ignoresUnknownSortColumn() {
        // ORDER BY に文字列をそのまま埋めると SQL インジェクションになるため、
        // ホワイトリストに無い値は既定 (code) に丸められる
        ProductSearch injected = search(Map.of("sort", "price; DROP TABLE products"));

        assertEquals("code", injected.getSort());
        assertEquals("P-0001", dao.search(injected).getItems().get(0).getCode());
        assertEquals(60, dao.countAll(), "テーブルは消えていない");
    }

    @Test
    @DisplayName("実行する SQL を説明用に組み立てられる")
    void describesSql() {
        String sql = dao.describeSql(search(Map.of("q", "ペン", "category", "文房具", "page", "2")));

        assertTrue(sql.contains("LIKE ?"), sql);
        assertTrue(sql.contains("category = ?"), sql);
        assertTrue(sql.contains("LIMIT 10 OFFSET 10"), sql);
        assertFalse(sql.contains("ペン"), "入力値は ? のままで SQL に埋め込まれない");
    }

    private static <T> boolean isSorted(List<T> items, Comparator<T> comparator) {
        for (int i = 1; i < items.size(); i++) {
            if (comparator.compare(items.get(i - 1), items.get(i)) > 0) {
                return false;
            }
        }
        return true;
    }

    /** パラメータだけを返す最小限の HttpServletRequest を作る (テスト用)。 */
    private static ProductSearch search(Map<String, String> parameters) {
        Map<String, String> values = new HashMap<>(parameters);
        HttpServletRequest request = (HttpServletRequest) Proxy.newProxyInstance(
                ProductDaoTest.class.getClassLoader(),
                new Class<?>[]{HttpServletRequest.class},
                (proxy, method, args) -> "getParameter".equals(method.getName())
                        ? values.get((String) args[0])
                        : null);
        return ProductSearch.from(request);
    }
}
