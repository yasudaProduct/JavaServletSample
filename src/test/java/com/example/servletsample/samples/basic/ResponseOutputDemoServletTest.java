package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 書き出しデモの、画面から来た値の扱いを確かめるテスト。
 *
 * <p>本文の文字数は「バッファに収まるかどうか」を切り替えるためのものですが、
 * 画面から来た数値をそのまま使うと、いくらでも大きな応答を作らされます。</p>
 */
class ResponseOutputDemoServletTest {

    @Test
    @DisplayName("書き出し方は決められた 3 つに絞る")
    void allowsOnlyKnownModes() {
        assertEquals("writer", ResponseOutputDemoServlet.modeOf("writer"));
        assertEquals("stream", ResponseOutputDemoServlet.modeOf("stream"));
        assertEquals("both", ResponseOutputDemoServlet.modeOf("both"));

        assertEquals("writer", ResponseOutputDemoServlet.modeOf(null));
        assertEquals("writer", ResponseOutputDemoServlet.modeOf("file"));
    }

    @Test
    @DisplayName("本文の文字数は上限で止める")
    void clampsBodySize() {
        assertEquals(200, ResponseOutputDemoServlet.bodySizeOf("200"));
        assertEquals(0, ResponseOutputDemoServlet.bodySizeOf("0"));
        assertEquals(0, ResponseOutputDemoServlet.bodySizeOf("-100"), "負の値は 0 にする");
        assertEquals(ResponseOutputDemoServlet.MAX_SIZE,
                ResponseOutputDemoServlet.bodySizeOf("99999999"));
    }

    @Test
    @DisplayName("読めない値は既定の文字数")
    void fallsBackToDefaultSize() {
        assertEquals(ResponseOutputDemoServlet.DEFAULT_SIZE,
                ResponseOutputDemoServlet.bodySizeOf(null));
        assertEquals(ResponseOutputDemoServlet.DEFAULT_SIZE,
                ResponseOutputDemoServlet.bodySizeOf("たくさん"));
    }

    @Test
    @DisplayName("指定した文字数ちょうどの本文を作る")
    void fillerHasExactLength() {
        assertEquals(0, ResponseOutputDemoServlet.filler(0).length());
        assertEquals(1, ResponseOutputDemoServlet.filler(1).length());
        assertEquals(200, ResponseOutputDemoServlet.filler(200).length());
        assertEquals(20000, ResponseOutputDemoServlet.filler(20000).length());
    }

    @Test
    @DisplayName("本文には何文字目かの目印が入る")
    void fillerMarksPositions() {
        String body = ResponseOutputDemoServlet.filler(200);

        assertTrue(body.startsWith("000000:"), "先頭に目印がありません: " + body);
        assertTrue(body.contains("\n"), "改行が入っていません");
    }
}
