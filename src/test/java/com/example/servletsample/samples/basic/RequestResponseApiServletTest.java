package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * レスポンスを組み立てるときの、画面から来た値の扱いを確かめるテスト。
 *
 * <p>ステータスコードもヘッダの値も、<b>画面から来たものをそのまま使わない</b>
 * という約束で書いています。そこが崩れていないかを見ています。</p>
 */
class RequestResponseApiServletTest {

    @Test
    @DisplayName("許可したステータスコードだけを返す")
    void allowsOnlyListedStatuses() {
        assertEquals(404, RequestResponseApiServlet.parseStatus("404"));
        assertEquals(503, RequestResponseApiServlet.parseStatus(" 503 "));

        // 許可していないコードは 200 に落とす
        assertEquals(200, RequestResponseApiServlet.parseStatus("418"));
        assertEquals(200, RequestResponseApiServlet.parseStatus("999"));
        assertEquals(200, RequestResponseApiServlet.parseStatus("-1"));
    }

    @Test
    @DisplayName("数値でない値や未指定は 200")
    void fallsBackToOkForUnreadableValues() {
        assertEquals(200, RequestResponseApiServlet.parseStatus(null));
        assertEquals(200, RequestResponseApiServlet.parseStatus(""));
        assertEquals(200, RequestResponseApiServlet.parseStatus("404; DROP"));
        assertEquals(200, RequestResponseApiServlet.parseStatus("４０４"), "全角数字");
    }

    @Test
    @DisplayName("Content-Type は決められた 3 種類から選ぶ")
    void mapsContentTypes() {
        assertTrue(RequestResponseApiServlet.contentTypeOf("json").startsWith("application/json"));
        assertTrue(RequestResponseApiServlet.contentTypeOf("text").startsWith("text/plain"));
        assertTrue(RequestResponseApiServlet.contentTypeOf("html").startsWith("text/html"));

        // 知らない値は JSON にする (画面から来た文字列をそのまま Content-Type にしない)
        assertTrue(RequestResponseApiServlet.contentTypeOf("text/html><script>")
                .startsWith("application/json"));
        assertTrue(RequestResponseApiServlet.contentTypeOf(null).startsWith("application/json"));
    }

    @Test
    @DisplayName("ヘッダに載せる値から改行を落とす")
    void removesNewlinesFromHeaderValue() {
        String injected = "ok\r\nSet-Cookie: admin=true";
        String cleaned = RequestResponseApiServlet.sanitizeHeaderValue(injected);

        assertFalse(cleaned.contains("\r"), "CR が残っています: " + cleaned);
        assertFalse(cleaned.contains("\n"), "LF が残っています: " + cleaned);
        assertEquals("okSet-Cookie: admin=true", cleaned);
    }

    @Test
    @DisplayName("制御文字も落とし、前後の空白を整える")
    void removesControlCharacters() {
        assertEquals("abc", RequestResponseApiServlet.sanitizeHeaderValue("  a\u0000b\tc  "));
        assertEquals("", RequestResponseApiServlet.sanitizeHeaderValue(null));
        assertEquals("", RequestResponseApiServlet.sanitizeHeaderValue("\r\n"));
    }

    @Test
    @DisplayName("長すぎるヘッダの値は切り詰める")
    void limitsHeaderValueLength() {
        String longValue = "あ".repeat(200);

        assertEquals(RequestResponseApiServlet.NOTE_MAX_LENGTH,
                RequestResponseApiServlet.sanitizeHeaderValue(longValue).length());
    }

    @Test
    @DisplayName("日本語はヘッダの値としてそのまま残る")
    void keepsJapaneseCharacters() {
        assertEquals("こんにちは", RequestResponseApiServlet.sanitizeHeaderValue("こんにちは"));
    }
}
