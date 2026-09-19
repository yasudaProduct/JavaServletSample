package com.example.servletsample.samples.list;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

/**
 * 一覧画面の検索条件 (キーワード・カテゴリ・並び順・ページ)。
 *
 * <p>画面から来る値は何が入っているか分からないため、
 * このクラスで受け取るときに<b>必ず検査して正規化</b>します。
 * ページ番号に {@code abc} が来ても、並び順に知らない列名が来ても落ちません。</p>
 *
 * <p>特に並び順は注意が必要です。{@code ORDER BY} は {@code ?} で置き換えられないため、
 * 受け取った文字列をそのまま SQL に埋めると SQL インジェクションの入口になります。
 * ここでは {@link #SORT_COLUMNS} に載っている名前だけを通しています (ホワイトリスト方式)。</p>
 */
public final class ProductSearch {

    /** 並び替えに使ってよい「画面のキー → テーブルの列名」の対応表。 */
    private static final Map<String, String> SORT_COLUMNS = new LinkedHashMap<>();

    static {
        SORT_COLUMNS.put("code", "code");
        SORT_COLUMNS.put("name", "name");
        SORT_COLUMNS.put("category", "category");
        SORT_COLUMNS.put("price", "price");
        SORT_COLUMNS.put("stock", "stock");
        SORT_COLUMNS.put("updated", "updated_at");
    }

    /** 1 ページの件数として選べる値。 */
    private static final List<Integer> PAGE_SIZES = Arrays.asList(10, 20, 50);

    private static final String DEFAULT_SORT = "code";
    private static final int DEFAULT_PAGE_SIZE = 10;

    private final String keyword;
    private final String category;
    private final boolean inStockOnly;
    private final String sort;
    private final boolean ascending;
    private final int page;
    private final int pageSize;

    private ProductSearch(String keyword, String category, boolean inStockOnly,
                          String sort, boolean ascending, int page, int pageSize) {
        this.keyword = keyword;
        this.category = category;
        this.inStockOnly = inStockOnly;
        this.sort = sort;
        this.ascending = ascending;
        this.page = page;
        this.pageSize = pageSize;
    }

    /** リクエストパラメータから検索条件を組み立てる (不正な値は既定値に丸める)。 */
    public static ProductSearch from(HttpServletRequest request) {
        String keyword = trim(request.getParameter("q"));
        String category = trim(request.getParameter("category"));
        boolean inStockOnly = request.getParameter("stock") != null;

        String sort = request.getParameter("sort");
        if (sort == null || !SORT_COLUMNS.containsKey(sort)) {
            sort = DEFAULT_SORT;
        }
        boolean ascending = !"desc".equals(request.getParameter("order"));

        int pageSize = toInt(request.getParameter("size"), DEFAULT_PAGE_SIZE);
        if (!PAGE_SIZES.contains(pageSize)) {
            pageSize = DEFAULT_PAGE_SIZE;
        }
        int page = Math.max(1, toInt(request.getParameter("page"), 1));

        return new ProductSearch(keyword, category, inStockOnly, sort, ascending, page, pageSize);
    }

    /** ページ番号だけを差し替えた条件を作る。 */
    public ProductSearch withPage(int newPage) {
        return new ProductSearch(keyword, category, inStockOnly, sort, ascending,
                Math.max(1, newPage), pageSize);
    }

    /** 検索キーワード (未入力なら空文字)。 */
    public String getKeyword() {
        return keyword;
    }

    /** 絞り込むカテゴリ (未選択なら空文字)。 */
    public String getCategory() {
        return category;
    }

    /** 在庫のあるものだけに絞るか。 */
    public boolean isInStockOnly() {
        return inStockOnly;
    }

    /** 並び替えのキー (画面側の名前)。 */
    public String getSort() {
        return sort;
    }

    /** 昇順か。 */
    public boolean isAscending() {
        return ascending;
    }

    /** 現在のページ番号 (1 始まり)。 */
    public int getPage() {
        return page;
    }

    /** 1 ページの件数。 */
    public int getPageSize() {
        return pageSize;
    }

    /** 1 ページの件数として選べる値。 */
    public List<Integer> getPageSizes() {
        return PAGE_SIZES;
    }

    /** 検索条件が 1 つでも指定されているか (「条件をクリア」ボタンの表示判定に使う)。 */
    public boolean isFiltered() {
        return !keyword.isEmpty() || !category.isEmpty() || inStockOnly;
    }

    /** その列で並び替え中か (見出しに ▲▼ を出すために使う)。 */
    public boolean isSortedBy(String key) {
        return sort.equals(key);
    }

    /** {@code ORDER BY} に埋めてよい列名。ホワイトリストを通しているので安全。 */
    String getSortColumn() {
        return SORT_COLUMNS.get(sort);
    }

    /** {@code ORDER BY} の方向。 */
    String getDirection() {
        return ascending ? "ASC" : "DESC";
    }

    /** {@code LIMIT ? OFFSET ?} の OFFSET。 */
    int getOffset() {
        return (page - 1) * pageSize;
    }

    /**
     * 指定したページへのクエリ文字列を作る。
     * <p>JSP から {@code ${search.queryForPage(n)}} のように呼びます。</p>
     */
    public String queryForPage(int newPage) {
        return toQuery(newPage, sort, ascending);
    }

    /**
     * 指定した列で並び替えるクエリ文字列を作る。
     * <p>同じ列をもう一度押したときは昇順 / 降順が入れ替わります。
     * 並び順を変えたらページは 1 に戻します。</p>
     */
    public String queryForSort(String key) {
        if (!SORT_COLUMNS.containsKey(key)) {
            key = DEFAULT_SORT;
        }
        boolean nextAscending = sort.equals(key) ? !ascending : true;
        return toQuery(1, key, nextAscending);
    }

    private String toQuery(int targetPage, String targetSort, boolean targetAscending) {
        StringBuilder query = new StringBuilder();
        append(query, "q", keyword);
        append(query, "category", category);
        if (inStockOnly) {
            append(query, "stock", "on");
        }
        append(query, "sort", targetSort);
        append(query, "order", targetAscending ? "asc" : "desc");
        append(query, "size", String.valueOf(pageSize));
        append(query, "page", String.valueOf(targetPage));
        return query.toString();
    }

    private static void append(StringBuilder query, String name, String value) {
        if (value == null || value.isEmpty()) {
            return;
        }
        if (query.length() > 0) {
            query.append('&');
        }
        query.append(name).append('=').append(encode(value));
    }

    private static String encode(String value) {
        try {
            return URLEncoder.encode(value, StandardCharsets.UTF_8.name());
        } catch (UnsupportedEncodingException e) {
            throw new IllegalStateException("UTF-8 が使えない環境です", e);
        }
    }

    private static String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private static int toInt(String value, int defaultValue) {
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException | NullPointerException e) {
            return defaultValue;
        }
    }

    @Override
    public String toString() {
        return "ProductSearch{" + toQuery(page, sort, ascending) + "}";
    }
}
