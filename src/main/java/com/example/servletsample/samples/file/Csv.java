package com.example.servletsample.samples.file;

import java.util.regex.Pattern;

/**
 * CSV を組み立てるための小さな部品。
 *
 * <p>CSV は「カンマで区切るだけ」に見えて、<b>値の中にカンマ・改行・ダブルクォートが
 * 入った瞬間に壊れます</b>。それを防ぐ決まりが RFC 4180 です。</p>
 *
 * <table border="1">
 *   <caption>エスケープの決まり (RFC 4180)</caption>
 *   <tr><th>値の中身</th><th>書き方</th></tr>
 *   <tr><td>区切り文字 ({@code ,}) を含む</td><td>全体を {@code "} で囲む</td></tr>
 *   <tr><td>改行を含む</td><td>全体を {@code "} で囲む (改行はそのまま入れてよい)</td></tr>
 *   <tr><td>{@code "} を含む</td><td>全体を {@code "} で囲み、中の {@code "} は {@code ""} に</td></tr>
 *   <tr><td>前後に空白がある</td><td>囲んでおくと安全 (読み込む側が落とすことがある)</td></tr>
 * </table>
 *
 * <pre>{@code
 * 値 : 山田, 太郎        → "山田, 太郎"
 * 値 : 幅 12" のモニタ    → "幅 12"" のモニタ"
 * 値 : 1 行目
 *      2 行目           → "1 行目
 *      2 行目"
 * }</pre>
 *
 * <h2>もう 1 つの落とし穴 : 数式として実行される</h2>
 * <p>{@code =} {@code +} {@code -} {@code @} で始まる値は、
 * Excel や Google スプレッドシートで開いたときに<b>数式として解釈されます</b>。
 * 利用者が入力した文字列をそのまま CSV に出していると、
 * <b>別の利用者がそのファイルを開いた瞬間に</b>仕込まれた式が動きます
 * (CSV インジェクション / 数式インジェクション)。</p>
 *
 * <pre>{@code
 * 備考欄に入力された値 : =1+1
 * → Excel で開くと セルに 2 と表示される (文字列として扱われない)
 * }</pre>
 *
 * <p>対策は、危ない文字で始まる値の前に {@code '} を付けて
 * 「これは文字列です」と伝えることです。
 * ただし <b>{@code -100} のような負の数まで文字列にしてしまわない</b>よう、
 * 数値として読める値は対象から外します。</p>
 *
 * <h2>このクラスの使い方</h2>
 * <pre>{@code
 * Csv csv = new Csv(',', "\r\n", true, true);
 * csv.row("商品コード", "商品名", "金額");
 * csv.row("A-001", "ケーブル, 2m", 1200);
 * String text = csv.text();
 * }</pre>
 *
 * <p>実務で複雑な CSV を扱うなら、Apache Commons CSV や OpenCSV といった
 * ライブラリを使ってください (読み込みはとくに面倒です)。
 * ここでは「何をしているか」が見えるよう、最小限のものを置いています。</p>
 */
public final class Csv {

    /**
     * BOM (Byte Order Mark)。
     *
     * <p>UTF-8 の CSV を Excel が<b>文字化けさせずに開いてくれるかどうか</b>は、
     * この 3 バイトが先頭にあるかで決まります。
     * Excel は BOM が無い UTF-8 ファイルを、環境の既定の文字コード
     * (日本語 Windows なら Shift_JIS) として読もうとするためです。</p>
     */
    public static final String BOM = "﻿";

    /** 数値として読める値 (この形なら数式ガードの対象にしない)。 */
    private static final Pattern NUMERIC = Pattern.compile("[-+]?\\d+(\\.\\d+)?");

    /** 数式として解釈されうる書き出し。 */
    private static final String FORMULA_STARTERS = "=+-@";

    private final char delimiter;
    private final String newline;
    private final boolean quote;
    private final boolean guardFormula;
    private final StringBuilder body = new StringBuilder();

    /**
     * @param delimiter    区切り文字 ({@code ','} または {@code '\t'})
     * @param newline      改行コード ({@code "\r\n"} または {@code "\n"})
     * @param quote        RFC 4180 のエスケープを行うか (false にすると壊れる様子が見られます)
     * @param guardFormula 数式として解釈されうる値に {@code '} を付けるか
     */
    public Csv(char delimiter, String newline, boolean quote, boolean guardFormula) {
        this.delimiter = delimiter;
        this.newline = newline;
        this.quote = quote;
        this.guardFormula = guardFormula;
    }

    /** 1 行書く。 */
    public Csv row(Object... values) {
        for (int i = 0; i < values.length; i++) {
            if (i > 0) {
                body.append(delimiter);
            }
            body.append(field(String.valueOf(values[i] == null ? "" : values[i]),
                    delimiter, quote, guardFormula));
        }
        body.append(newline);
        return this;
    }

    /** 組み立てた CSV。 */
    public String text() {
        return body.toString();
    }

    /** 行数 (ヘッダを含む)。 */
    public int lineCount() {
        if (body.length() == 0) {
            return 0;
        }
        int count = 0;
        int index = body.indexOf(newline);
        while (index >= 0) {
            count++;
            index = body.indexOf(newline, index + newline.length());
        }
        return count;
    }

    /**
     * 値 1 つ分を CSV に書ける形にする。
     *
     * @param raw          元の値
     * @param delimiter    区切り文字
     * @param quote        RFC 4180 のエスケープを行うか
     * @param guardFormula 数式ガードを行うか
     */
    public static String field(String raw, char delimiter, boolean quote, boolean guardFormula) {
        String value = raw == null ? "" : raw;

        if (guardFormula && needsFormulaGuard(value)) {
            // 「これは文字列です」と伝えるための ' を先頭に付ける。
            // 表計算ソフトはこの ' を表示せず、中身を文字列として扱います
            value = "'" + value;
        }

        if (!quote) {
            // エスケープしない = そのまま連結する。
            // 値にカンマや改行が入っていると、列がずれたり行が増えたりします
            return value;
        }

        boolean needsQuote = value.indexOf(delimiter) >= 0
                || value.indexOf('"') >= 0
                || value.indexOf('\n') >= 0
                || value.indexOf('\r') >= 0
                || value.startsWith(" ")
                || value.endsWith(" ");

        if (!needsQuote) {
            return value;
        }
        // 中の " は "" にしてから、全体を " で囲む
        return '"' + value.replace("\"", "\"\"") + '"';
    }

    /**
     * 数式として解釈されうる値かどうか。
     *
     * <p>{@code -100} のような<b>数値は対象外</b>にしています。
     * これをやらないと、金額の列がすべて {@code '-100} になって集計できなくなります。</p>
     */
    static boolean needsFormulaGuard(String value) {
        if (value == null || value.isEmpty()) {
            return false;
        }
        char first = value.charAt(0);
        // タブと復帰も、セルの先頭にあると式の開始とみなされることがある
        if (first == '\t' || first == '\r') {
            return true;
        }
        if (FORMULA_STARTERS.indexOf(first) < 0) {
            return false;
        }
        return !NUMERIC.matcher(value).matches();
    }
}
