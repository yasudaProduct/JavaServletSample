package com.example.servletsample.samples.file;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** DB に保存した PDF を取り出す {@link PdfDocumentDao} のテスト。 */
class PdfDocumentDaoTest {

    private final PdfDocumentDao dao = new PdfDocumentDao();

    @Test
    @DisplayName("起動時にサンプルの PDF が入っている")
    void hasSeedDocuments() {
        List<String> fileNames = dao.findAll().stream()
                .map(PdfDocument::getFileName)
                .collect(Collectors.toList());

        assertTrue(fileNames.contains("見積書_Q-2026-0012.pdf"), fileNames.toString());
        assertTrue(fileNames.contains("請求書_INV-2026-0345.pdf"), fileNames.toString());
        assertTrue(fileNames.contains("定例会議資料_2026年9月.pdf"), fileNames.toString());
    }

    @Test
    @DisplayName("prepareTable を何度呼んでも、サンプルが二重に入らない")
    void seedsOnlyOnce() {
        int before = dao.findAll().size();
        PdfDocumentDao.prepareTable();
        new PdfDocumentDao();
        assertEquals(before, dao.findAll().size());
    }

    @Test
    @DisplayName("1 件取得すると、一覧と同じ情報が返る")
    void findsById() {
        PdfDocument first = dao.findAll().get(0);
        PdfDocument found = dao.findById(first.getId());

        assertNotNull(found);
        assertEquals(first.getTitle(), found.getTitle());
        assertEquals(first.getFileName(), found.getFileName());
        assertEquals(first.getSize(), found.getSize());
        assertNotNull(found.getCreatedAt());
    }

    @Test
    @DisplayName("取り出した中身は PDF で、バイト数は file_size と一致する")
    void copiesPdfContent() throws IOException {
        for (PdfDocument document : dao.findAll()) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();

            assertTrue(dao.copyContentTo(document.getId(), out));
            byte[] bytes = out.toByteArray();
            assertEquals(document.getSize(), bytes.length, document.getFileName());
            assertEquals("%PDF-", new String(bytes, 0, 5, StandardCharsets.US_ASCII), document.getFileName());
        }
    }

    @Test
    @DisplayName("存在しない ID を指定しても落ちない")
    void toleratesUnknownId() throws IOException {
        assertNull(dao.findById(-1));
        assertFalse(dao.copyContentTo(-1, new ByteArrayOutputStream()));
    }
}
