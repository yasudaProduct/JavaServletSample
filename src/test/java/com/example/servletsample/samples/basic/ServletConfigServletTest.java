package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 設定値の読み方を確かめるテスト。
 *
 * <p>設定値は「人が手で書いた文字列」なので、空欄・全角数字・桁あふれ・
 * 大きすぎる値が来ます。読んだ側で確かめる約束が守られているかを見ています。</p>
 */
class ServletConfigServletTest {

    @Test
    @DisplayName("普通の数値はそのまま使う")
    void usesConfiguredValue() {
        assertEquals(10, ServletConfigServlet.pageSizeOf("10"));
        assertEquals(1, ServletConfigServlet.pageSizeOf("1"));
        assertEquals(ServletConfigServlet.MAX_PAGE_SIZE,
                ServletConfigServlet.pageSizeOf(String.valueOf(ServletConfigServlet.MAX_PAGE_SIZE)));
    }

    @Test
    @DisplayName("上限を超える値は丸める")
    void clampsTooLargeValue() {
        assertEquals(ServletConfigServlet.MAX_PAGE_SIZE, ServletConfigServlet.pageSizeOf("500"));
        assertEquals(ServletConfigServlet.MAX_PAGE_SIZE,
                ServletConfigServlet.pageSizeOf("2147483647"));
    }

    @Test
    @DisplayName("読めない値は既定値に倒す")
    void fallsBackToDefault() {
        assertEquals(ServletConfigServlet.DEFAULT_PAGE_SIZE, ServletConfigServlet.pageSizeOf(null),
                "設定が書かれていない");
        assertEquals(ServletConfigServlet.DEFAULT_PAGE_SIZE, ServletConfigServlet.pageSizeOf(""));
        assertEquals(ServletConfigServlet.DEFAULT_PAGE_SIZE, ServletConfigServlet.pageSizeOf("  "));
        assertEquals(ServletConfigServlet.DEFAULT_PAGE_SIZE, ServletConfigServlet.pageSizeOf("twenty"));
        assertEquals(ServletConfigServlet.DEFAULT_PAGE_SIZE, ServletConfigServlet.pageSizeOf("２０"),
                "全角数字");
        assertEquals(ServletConfigServlet.DEFAULT_PAGE_SIZE,
                ServletConfigServlet.pageSizeOf("9999999999999"), "int に収まらない");
    }

    @Test
    @DisplayName("0 や負の値も既定値に倒す")
    void rejectsZeroAndNegativeValues() {
        assertEquals(ServletConfigServlet.DEFAULT_PAGE_SIZE, ServletConfigServlet.pageSizeOf("0"));
        assertEquals(ServletConfigServlet.DEFAULT_PAGE_SIZE, ServletConfigServlet.pageSizeOf("-5"));
    }
}
