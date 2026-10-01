package com.example.servletsample.samples.file;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * データベースに保存した PDF 1 件分の情報。
 *
 * <p>中身 (BLOB) はこのクラスには持ちません。一覧を出すたびに全部の PDF を読み込むと
 * メモリを大量に使うためです。中身は表示するときだけ
 * {@link PdfDocumentDao#copyContentTo} で読み出して、そのままレスポンスへ流します。</p>
 */
public final class PdfDocument {

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm");

    private final long id;
    private final String title;
    private final String fileName;
    private final long size;
    private final LocalDateTime createdAt;

    PdfDocument(long id, String title, String fileName, long size, LocalDateTime createdAt) {
        this.id = id;
        this.title = title;
        this.fileName = fileName;
        this.size = size;
        this.createdAt = createdAt;
    }

    /** 採番された ID (表示の URL で使う)。 */
    public long getId() {
        return id;
    }

    /** 画面に出す名前。例: {@code 御見積書（Q-2026-0012）} */
    public String getTitle() {
        return title;
    }

    /** 保存するときのファイル名。例: {@code 見積書_Q-2026-0012.pdf} */
    public String getFileName() {
        return fileName;
    }

    /** バイト数。 */
    public long getSize() {
        return size;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    /** 画面に出す日時 (JSTL の fmt:formatDate は LocalDateTime を扱えないため Java 側で整形する)。 */
    public String getCreatedAtText() {
        return createdAt == null ? "" : createdAt.format(FORMATTER);
    }

    /** 画面に出すサイズ。例: {@code 39.7 KB} */
    public String getSizeText() {
        return StoredFile.formatSize(size);
    }

    @Override
    public String toString() {
        return "PdfDocument{id=" + id + ", fileName='" + fileName + "'}";
    }
}
