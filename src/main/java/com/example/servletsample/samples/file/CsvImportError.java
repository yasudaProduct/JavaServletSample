package com.example.servletsample.samples.file;

import java.io.Serializable;

/**
 * CSV 取り込みの入力エラー 1 件 (どの行の、どの列が、なぜだめか)。
 *
 * <p>画面とログで<b>出すものを分けられる</b>よう、項目を細かく持っています。</p>
 *
 * <table border="1">
 *   <caption>どこに何を出すか</caption>
 *   <tr><th>項目</th><th>画面</th><th>ログ</th></tr>
 *   <tr><td>行番号・列の名前</td><td>出す</td><td>出す</td></tr>
 *   <tr><td>種類 (必須 / 文字種 / 形式 …)</td><td>出す</td><td>出す</td></tr>
 *   <tr><td>入力値</td><td>出す</td><td><b>出さない</b></td></tr>
 *   <tr><td>メッセージ</td><td>出す</td><td>出さない (種類で足りる)</td></tr>
 * </table>
 *
 * <p>入力値を画面に出すのは、取り込んだ本人が<b>自分のデータを直すため</b>です。
 * ログに出さないのは、氏名やメールアドレスは個人情報で、
 * ログは調査のためにコピーされ、長く保管されるからです。
 * 行番号と列の名前があれば、元のファイルを見れば値は分かります。</p>
 */
public final class CsvImportError implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 画面に出す入力値の長さの上限 (これを超えたら … で省略する)。 */
    static final int MAX_VALUE_LENGTH = 40;

    private final int lineNumber;
    private final String column;
    private final String kind;
    private final String value;
    private final String message;

    /**
     * @param lineNumber 行番号 (見出しを 1 行目として数える)
     * @param column     列の名前。行全体のエラー (列の数が違うなど) なら空文字
     * @param kind       エラーの種類 (必須 / 文字種 / 桁数 / 形式 / 範囲 / マスタ / 選択肢 / 重複 / 列数)
     * @param value      入力値 (画面にだけ出す)
     * @param message    利用者に向けたメッセージ
     */
    public CsvImportError(int lineNumber, String column, String kind, String value, String message) {
        this.lineNumber = lineNumber;
        this.column = column == null ? "" : column;
        this.kind = kind;
        this.value = shorten(value);
        this.message = message;
    }

    /** 行番号 (見出しを 1 行目として数える)。 */
    public int getLineNumber() {
        return lineNumber;
    }

    /** 列の名前 (行全体のエラーなら空文字)。 */
    public String getColumn() {
        return column;
    }

    /** エラーの種類。 */
    public String getKind() {
        return kind;
    }

    /** 入力値 (長いものは省略済み)。 */
    public String getValue() {
        return value;
    }

    /** 利用者に向けたメッセージ。 */
    public String getMessage() {
        return message;
    }

    /**
     * ログに書くための短い表し方。<b>入力値は含めません</b>。
     *
     * <pre>{@code フリガナ:文字種}</pre>
     */
    public String toLogText() {
        return (column.isEmpty() ? "行" : column) + ":" + kind;
    }

    /** 長い値は画面が崩れないよう省略する (コードポイントで数えて絵文字を割らない)。 */
    private static String shorten(String raw) {
        String text = raw == null ? "" : raw;
        if (text.codePointCount(0, text.length()) <= MAX_VALUE_LENGTH) {
            return text;
        }
        return text.substring(0, text.offsetByCodePoints(0, MAX_VALUE_LENGTH)) + "…";
    }

    @Override
    public String toString() {
        return lineNumber + " 行目 " + toLogText();
    }
}
