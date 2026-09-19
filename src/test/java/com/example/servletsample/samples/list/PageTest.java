package com.example.servletsample.samples.list;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** ページ送りの計算 ({@link Page}) のテスト。 */
class PageTest {

    private static final List<String> TEN = Collections.nCopies(10, "行");

    @Test
    @DisplayName("87 件を 10 件ずつなら 9 ページになる")
    void calculatesTotalPages() {
        Page<String> page = Page.of(TEN, 87, 1, 10);
        assertEquals(9, page.getTotalPages());
        assertTrue(page.isFirst());
        assertFalse(page.isLast());
    }

    @Test
    @DisplayName("「87 件中 21 - 30 件」の番号を計算できる")
    void calculatesItemNumbers() {
        Page<String> page = Page.of(TEN, 87, 3, 10);
        assertEquals(21, page.getFirstItemNumber());
        assertEquals(30, page.getLastItemNumber());
    }

    @Test
    @DisplayName("最終ページでは端数の件数になる")
    void lastPageShowsRemainder() {
        Page<String> page = Page.of(Arrays.asList("A", "B", "C", "D", "E", "F", "G"), 87, 9, 10);
        assertEquals(81, page.getFirstItemNumber());
        assertEquals(87, page.getLastItemNumber());
        assertTrue(page.isLast());
        assertEquals(9, page.getNextNumber(), "最終ページの「次へ」は自分のページ番号のまま");
    }

    @Test
    @DisplayName("0 件でも 1 ページとして扱う")
    void emptyPage() {
        Page<String> page = Page.of(Collections.emptyList(), 0, 1, 10);
        assertTrue(page.isEmpty());
        assertEquals(1, page.getTotalPages());
        assertEquals(0, page.getFirstItemNumber());
        assertEquals(0, page.getLastItemNumber());
        assertTrue(page.isFirst());
        assertTrue(page.isLast());
    }

    @Test
    @DisplayName("ページ番号のリンクは現在のページの前後だけを並べる")
    void showsWindowOfPageNumbers() {
        assertEquals(Arrays.asList(1, 2, 3, 4, 5), Page.of(TEN, 200, 1, 10).getNumbers());
        assertEquals(Arrays.asList(5, 6, 7, 8, 9), Page.of(TEN, 200, 7, 10).getNumbers());
        assertEquals(Arrays.asList(16, 17, 18, 19, 20), Page.of(TEN, 200, 20, 10).getNumbers());
    }

    @Test
    @DisplayName("先頭・末尾がリンクに出ていないかを判定できる")
    void tellsWhetherEdgePagesAreHidden() {
        Page<String> first = Page.of(TEN, 200, 1, 10);
        assertFalse(first.isFirstPageHidden());
        assertTrue(first.isLastPageHidden());

        Page<String> middle = Page.of(TEN, 200, 10, 10);
        assertTrue(middle.isFirstPageHidden());
        assertTrue(middle.isLastPageHidden());
    }

    @Test
    @DisplayName("ページ数より大きいページ番号でも計算が壊れない")
    void toleratesOutOfRangePage() {
        Page<String> page = Page.of(Collections.emptyList(), 15, 99, 10);
        assertEquals(2, page.getTotalPages());
        assertTrue(page.isLast());
        assertTrue(page.isEmpty());
    }
}
