package com.example.servletsample.samples.file;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** ファイルを DB に保存する {@link StoredFileDao} のテスト。 */
class StoredFileDaoTest {

    private final StoredFileDao dao = new StoredFileDao();

    @Test
    @DisplayName("保存したファイルを一覧・1 件取得できる")
    void savesAndFinds() {
        long id = save("メモ.txt", "text/plain", "テストの中身");
        try {
            StoredFile file = dao.findById(id);
            assertNotNull(file);
            assertEquals("メモ.txt", file.getFileName());
            assertEquals("text/plain", file.getContentType());
            assertTrue(file.getSize() > 0);
            assertNotNull(file.getUploadedAt());

            assertTrue(dao.findAll().stream().anyMatch(f -> f.getId() == id), "一覧に出てくる");
        } finally {
            dao.delete(id);
        }
    }

    @Test
    @DisplayName("保存した中身をそのまま取り出せる")
    void readsBackTheContent() throws IOException {
        String content = "1 行目\n2 行目\n";
        long id = save("データ.csv", "text/csv", content);
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            assertTrue(dao.copyContentTo(id, out));
            assertEquals(content, out.toString(StandardCharsets.UTF_8.name()));
        } finally {
            dao.delete(id);
        }
    }

    @Test
    @DisplayName("削除すると取得できなくなる")
    void deletes() {
        long id = save("消す.txt", "text/plain", "x");

        assertTrue(dao.delete(id));
        assertNull(dao.findById(id));
        assertFalse(dao.delete(id), "2 回目の削除は false");
    }

    @Test
    @DisplayName("存在しない ID を指定しても落ちない")
    void toleratesUnknownId() throws IOException {
        assertNull(dao.findById(-1));
        assertFalse(dao.copyContentTo(-1, new ByteArrayOutputStream()));
        assertFalse(dao.delete(-1));
    }

    @Test
    @DisplayName("合計サイズが増減する")
    void tracksTotalSize() {
        long before = dao.totalSize();
        long id = save("サイズ.bin", "application/octet-stream", "0123456789");
        try {
            assertEquals(before + 10, dao.totalSize());
        } finally {
            dao.delete(id);
        }
        assertEquals(before, dao.totalSize());
    }

    @Test
    @DisplayName("バイト数を読みやすい単位に変換する")
    void formatsSize() {
        assertEquals("512 B", StoredFile.formatSize(512));
        assertEquals("1.0 KB", StoredFile.formatSize(1024));
        assertEquals("1.5 MB", StoredFile.formatSize(1024 * 1024 * 3 / 2));
    }

    private long save(String name, String contentType, String content) {
        byte[] bytes = content.getBytes(StandardCharsets.UTF_8);
        return dao.save(name, contentType, bytes.length, new ByteArrayInputStream(bytes));
    }
}
