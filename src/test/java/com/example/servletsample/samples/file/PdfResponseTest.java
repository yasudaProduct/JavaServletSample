package com.example.servletsample.samples.file;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** PDF を返すときのヘッダ ({@link PdfResponse}) と ID の変換のテスト。 */
class PdfResponseTest {

    @Test
    @DisplayName("表示するときは inline、ダウンロードのときは attachment になる")
    void switchesInlineAndAttachment() {
        assertEquals("inline; filename=\"manual.pdf\"; filename*=UTF-8''manual.pdf",
                PdfResponse.contentDisposition(false, "manual.pdf"));
        assertEquals("attachment; filename=\"manual.pdf\"; filename*=UTF-8''manual.pdf",
                PdfResponse.contentDisposition(true, "manual.pdf"));
    }

    @Test
    @DisplayName("日本語のファイル名は ASCII 用と UTF-8 用を並べて出す")
    void encodesJapaneseFileName() {
        String header = PdfResponse.contentDisposition(false, "見積書.pdf");

        assertTrue(header.contains("filename=\"___.pdf\""), header);
        assertTrue(header.contains("filename*=UTF-8''%E8%A6%8B%E7%A9%8D%E6%9B%B8.pdf"), header);
    }

    @Test
    @DisplayName("空白は %20、* は %2A にする (URLEncoder のままではヘッダに書けない)")
    void encodesSpaceAndAsterisk() {
        String header = PdfResponse.contentDisposition(false, "a b*.pdf");
        assertTrue(header.endsWith("filename*=UTF-8''a%20b%2A.pdf"), header);
    }

    @Test
    @DisplayName("ヘッダを壊す引用符はファイル名から追い出す")
    void escapesQuotes() {
        String header = PdfResponse.contentDisposition(false, "a\"b.pdf");
        assertTrue(header.contains("filename=\"a_b.pdf\""), header);
    }

    @Test
    @DisplayName("数字以外の ID は -1 になる")
    void parsesId() {
        assertEquals(3L, PdfFromDbServlet.parseId("3"));
        assertEquals(-1L, PdfFromDbServlet.parseId("abc"));
        assertEquals(-1L, PdfFromDbServlet.parseId(""));
        assertEquals(-1L, PdfFromDbServlet.parseId(null));
    }
}
