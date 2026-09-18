package com.example.servletsample.samples.list;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * ページング結果 (1 ページ分のデータ + ページ送りに必要な情報)。
 *
 * <p>一覧のページングでは、次の 2 つが分かれば画面を作れます。</p>
 * <ul>
 *   <li>そのページに表示する行 ({@code SELECT ... LIMIT ? OFFSET ?} の結果)</li>
 *   <li>条件に一致する全件数 ({@code SELECT COUNT(*)} の結果)</li>
 * </ul>
 *
 * <p>「10 / 87 件」「◀ 1 2 3 ▶」といった表示に必要な計算はこのクラスにまとめてあります。
 * JSP からは {@code ${productPage.totalPages}} のように参照します。</p>
 *
 * @param <T> 一覧に並べるデータの型
 */
public final class Page<T> {

    /** ページ番号のリンクを何個まで並べるか。 */
    private static final int WINDOW = 5;

    private final List<T> items;
    private final int totalCount;
    private final int number;
    private final int size;

    private Page(List<T> items, int totalCount, int number, int size) {
        this.items = Collections.unmodifiableList(new ArrayList<>(items));
        this.totalCount = Math.max(0, totalCount);
        this.size = Math.max(1, size);
        this.number = Math.max(1, number);
    }

    /**
     * ページを組み立てる。
     *
     * @param items      そのページに表示する行
     * @param totalCount 条件に一致する全件数
     * @param number     現在のページ番号 (1 始まり)
     * @param size       1 ページの件数
     */
    public static <T> Page<T> of(List<T> items, int totalCount, int number, int size) {
        return new Page<>(items, totalCount, number, size);
    }

    /** そのページに表示する行。 */
    public List<T> getItems() {
        return items;
    }

    /** 条件に一致する全件数。 */
    public int getTotalCount() {
        return totalCount;
    }

    /** 現在のページ番号 (1 始まり)。 */
    public int getNumber() {
        return number;
    }

    /** 1 ページの件数。 */
    public int getSize() {
        return size;
    }

    /** 総ページ数 (0 件でも 1 ページとして扱う)。 */
    public int getTotalPages() {
        return totalCount == 0 ? 1 : (totalCount + size - 1) / size;
    }

    /** 表示する行が 1 件も無いか。 */
    public boolean isEmpty() {
        return items.isEmpty();
    }

    public boolean isFirst() {
        return number <= 1;
    }

    public boolean isLast() {
        return number >= getTotalPages();
    }

    /** 前のページ番号 (先頭ページなら 1)。 */
    public int getPreviousNumber() {
        return Math.max(1, number - 1);
    }

    /** 次のページ番号 (最終ページならそのまま)。 */
    public int getNextNumber() {
        return Math.min(getTotalPages(), number + 1);
    }

    /** 「87 件中 <b>21</b> - 40 件」の 21。0 件なら 0。 */
    public int getFirstItemNumber() {
        return totalCount == 0 ? 0 : (number - 1) * size + 1;
    }

    /** 「87 件中 21 - <b>40</b> 件」の 40。 */
    public int getLastItemNumber() {
        return Math.min(totalCount, number * size);
    }

    /**
     * 画面に並べるページ番号。
     *
     * <p>総ページ数が多いときに 1 〜 100 まで全部並べても押せないので、
     * 現在のページの前後だけを返します (例: 7 ページ目なら 5 6 7 8 9)。</p>
     */
    public List<Integer> getNumbers() {
        int totalPages = getTotalPages();
        int start = Math.max(1, number - WINDOW / 2);
        int end = Math.min(totalPages, start + WINDOW - 1);
        start = Math.max(1, end - WINDOW + 1);

        List<Integer> numbers = new ArrayList<>();
        for (int i = start; i <= end; i++) {
            numbers.add(i);
        }
        return numbers;
    }

    /** 先頭ページへのリンクを出すべきか (ページ番号の並びに 1 が入っていない)。 */
    public boolean isFirstPageHidden() {
        return !getNumbers().contains(1);
    }

    /** 最終ページへのリンクを出すべきか。 */
    public boolean isLastPageHidden() {
        return !getNumbers().contains(getTotalPages());
    }
}
