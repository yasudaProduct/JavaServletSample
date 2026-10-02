package com.example.servletsample.samples.file;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * CSV 取り込み 1 回ぶんの結果 (画面に出すもの)。
 *
 * <p>結果は 4 通りです。利用者に伝えることがそれぞれ違うので、種類として分けています。</p>
 *
 * <table border="1">
 *   <caption>結果の種類</caption>
 *   <tr><th>種類</th><th>起きたこと</th><th>利用者にしてほしいこと</th><th>ログ</th></tr>
 *   <tr><td>{@code SUCCESS}</td><td>全件を登録した</td><td>なし</td><td>INFO</td></tr>
 *   <tr><td>{@code INVALID}</td><td>入力エラーがあり、1 件も登録していない</td>
 *       <td>一覧を見て CSV を直す</td><td>WARN (件数) / DEBUG (位置)</td></tr>
 *   <tr><td>{@code REJECTED}</td><td>ファイルとして受け付けられない</td>
 *       <td>ファイルや文字コードを選び直す</td><td>WARN</td></tr>
 *   <tr><td>{@code FAILED}</td><td>システムの異常で登録できなかった</td>
 *       <td>時間をおく / 問い合わせ番号を添えて連絡する</td><td>ERROR (スタックトレース付き)</td></tr>
 * </table>
 *
 * <p>リダイレクトをまたいでセッションに置くので {@link Serializable} にしています。</p>
 */
public final class CsvImportResult implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 結果の種類。 */
    public enum Status {
        SUCCESS, INVALID, REJECTED, FAILED
    }

    private final Status status;
    private final String importId;
    private final String fileName;
    private final String message;
    private final int rowCount;
    private final int insertedCount;
    private final int updatedCount;
    private final List<CsvImportError> errors;
    private final int errorCount;

    private CsvImportResult(Status status, String importId, String fileName, String message,
                            int rowCount, int insertedCount, int updatedCount,
                            List<CsvImportError> errors, int errorCount) {
        this.status = status;
        this.importId = importId;
        this.fileName = fileName == null ? "" : fileName;
        this.message = message;
        this.rowCount = rowCount;
        this.insertedCount = insertedCount;
        this.updatedCount = updatedCount;
        this.errors = Collections.unmodifiableList(new ArrayList<>(errors));
        this.errorCount = errorCount;
    }

    /** 全件を登録できた。 */
    static CsvImportResult success(String importId, String fileName, int rowCount,
                                   int insertedCount, int updatedCount) {
        return new CsvImportResult(Status.SUCCESS, importId, fileName,
                rowCount + " 行を取り込みました。", rowCount, insertedCount, updatedCount,
                List.of(), 0);
    }

    /**
     * 入力エラーがあったので、1 件も登録しなかった。
     *
     * @param errors     画面に出すエラー (上限まで)
     * @param errorCount エラーの総数 (上限で切る前の数)
     */
    static CsvImportResult invalid(String importId, String fileName, int rowCount,
                                   List<CsvImportError> errors, int errorCount) {
        return new CsvImportResult(Status.INVALID, importId, fileName,
                "入力エラーが " + errorCount + " 件あったため、取り込みませんでした (1 件も登録していません)。"
                + "下の一覧を見て CSV を直し、もう一度取り込んでください。",
                rowCount, 0, 0, errors, errorCount);
    }

    /** ファイルとして受け付けられなかった。 */
    static CsvImportResult rejected(String importId, String fileName, String message) {
        return new CsvImportResult(Status.REJECTED, importId, fileName, message, 0, 0, 0, List.of(), 0);
    }

    /** システムの異常で登録できなかった。 */
    static CsvImportResult failed(String importId, String fileName) {
        return new CsvImportResult(Status.FAILED, importId, fileName,
                "システムエラーのため取り込めませんでした。登録は行っていません (途中までの分も取り消しました)。"
                + "時間をおいてもう一度お試しください。続くようでしたら、問い合わせ番号を添えてご連絡ください。",
                0, 0, 0, List.of(), 0);
    }

    public Status getStatus() {
        return status;
    }

    /** 全件を登録できたか。 */
    public boolean isSuccess() {
        return status == Status.SUCCESS;
    }

    /** 入力エラーで差し戻したか。 */
    public boolean isInvalid() {
        return status == Status.INVALID;
    }

    /** ファイルとして受け付けなかったか。 */
    public boolean isRejected() {
        return status == Status.REJECTED;
    }

    /** システムの異常で失敗したか。 */
    public boolean isFailed() {
        return status == Status.FAILED;
    }

    /** 取り込み ID (= 問い合わせ番号)。ログの各行にも同じ値が出ています。 */
    public String getImportId() {
        return importId;
    }

    /** 送られてきたファイル名。 */
    public String getFileName() {
        return fileName;
    }

    /** 利用者に向けたメッセージ。 */
    public String getMessage() {
        return message;
    }

    /** データ行の数 (見出しと空行を除く)。 */
    public int getRowCount() {
        return rowCount;
    }

    /** 追加した件数。 */
    public int getInsertedCount() {
        return insertedCount;
    }

    /** 上書きした件数 (社員コードが登録済みだった行)。 */
    public int getUpdatedCount() {
        return updatedCount;
    }

    /** 画面に出すエラー (上限まで)。 */
    public List<CsvImportError> getErrors() {
        return errors;
    }

    /** エラーの総数。 */
    public int getErrorCount() {
        return errorCount;
    }

    /** 上限で切ったために画面に出していないエラーの数。 */
    public int getHiddenErrorCount() {
        return errorCount - errors.size();
    }
}
