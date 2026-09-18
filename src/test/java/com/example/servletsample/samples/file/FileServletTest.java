package com.example.servletsample.samples.file;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** アップロード / ダウンロードで使う値の組み立てのテスト。 */
class FileServletTest {

    @Test
    @DisplayName("送られてきたファイル名からディレクトリ部分を落とす")
    void sanitizesFileName() {
        assertEquals("photo.png", FileUploadServlet.sanitizeFileName("C:\\Users\\taro\\photo.png"));
        assertEquals("photo.png", FileUploadServlet.sanitizeFileName("/tmp/photo.png"));
        assertEquals("passwd", FileUploadServlet.sanitizeFileName("../../etc/passwd"));
        assertEquals("報告書.xlsx", FileUploadServlet.sanitizeFileName("  報告書.xlsx  "));
        assertEquals("", FileUploadServlet.sanitizeFileName(null));
        assertEquals("", FileUploadServlet.sanitizeFileName(""));
    }

    @Test
    @DisplayName("ファイル名が長すぎても 255 文字までに収める")
    void limitsFileNameLength() {
        String name = FileUploadServlet.sanitizeFileName("a".repeat(300) + ".txt");
        assertEquals(255, name.length());
    }

    @Test
    @DisplayName("数字以外の ID は -1 になる")
    void parsesId() {
        assertEquals(12L, FileUploadServlet.parseId("12"));
        assertEquals(-1L, FileUploadServlet.parseId("abc"));
        assertEquals(-1L, FileUploadServlet.parseId(null));
    }

    @Test
    @DisplayName("日本語のファイル名は ASCII 用と UTF-8 用を並べて出す")
    void buildsContentDisposition() {
        String header = FileDownloadServlet.contentDisposition("報告書 v2.xlsx");

        assertTrue(header.startsWith("attachment; "), header);
        // ASCII に無い文字は _ に、UTF-8 側はパーセントエンコードされる
        assertTrue(header.contains("filename=\"___ v2.xlsx\""), header);
        assertTrue(header.contains("filename*=UTF-8''%E5%A0%B1%E5%91%8A%E6%9B%B8%20v2.xlsx"), header);
    }

    @Test
    @DisplayName("ヘッダを壊す引用符はファイル名から追い出す")
    void escapesQuotesInHeader() {
        String header = FileDownloadServlet.contentDisposition("a\"b.txt");
        assertTrue(header.contains("filename=\"a_b.txt\""), header);
    }
}
