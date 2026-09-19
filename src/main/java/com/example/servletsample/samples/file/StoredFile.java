package com.example.servletsample.samples.file;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * データベースに保存したファイル 1 件分の情報。
 *
 * <p>一覧に出すのは「ファイル名・種類・サイズ・日時」だけで、
 * 中身 (BLOB) はこのクラスには持ちません。
 * 一覧を表示するたびに全ファイルの中身を読み込むとメモリを大量に使うためです。
 * 中身はダウンロードのときだけ {@link StoredFileDao#copyContentTo} で読み出します。</p>
 */
public final class StoredFile {

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");

    private final long id;
    private final String fileName;
    private final String contentType;
    private final long size;
    private final LocalDateTime uploadedAt;

    StoredFile(long id, String fileName, String contentType, long size, LocalDateTime uploadedAt) {
        this.id = id;
        this.fileName = fileName;
        this.contentType = contentType;
        this.size = size;
        this.uploadedAt = uploadedAt;
    }

    /** 採番された ID (ダウンロード・削除で使う)。 */
    public long getId() {
        return id;
    }

    /** アップロードされたときのファイル名。 */
    public String getFileName() {
        return fileName;
    }

    /** MIME タイプ。例: {@code image/png} */
    public String getContentType() {
        return contentType;
    }

    /** バイト数。 */
    public long getSize() {
        return size;
    }

    public LocalDateTime getUploadedAt() {
        return uploadedAt;
    }

    /** 画面に出す日時 (JSTL の fmt:formatDate は LocalDateTime を扱えないため Java 側で整形する)。 */
    public String getUploadedAtText() {
        return uploadedAt == null ? "" : uploadedAt.format(FORMATTER);
    }

    /** 画面に出すサイズ。例: {@code 12.3 KB} */
    public String getSizeText() {
        return formatSize(size);
    }

    /** バイト数を読みやすい単位に直す。 */
    public static String formatSize(long bytes) {
        if (bytes < 1024) {
            return bytes + " B";
        }
        if (bytes < 1024 * 1024) {
            return String.format("%.1f KB", bytes / 1024d);
        }
        return String.format("%.1f MB", bytes / (1024d * 1024d));
    }

    @Override
    public String toString() {
        return "StoredFile{id=" + id + ", fileName='" + fileName + "'}";
    }
}
