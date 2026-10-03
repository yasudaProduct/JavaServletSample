package com.example.servletsample.samples.file;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * CSV の文字列を行と値に分ける、最小限の読み取り部品 (RFC 4180)。
 *
 * <p>書き出し側の {@link Csv} と対になるものです。
 * 「カンマで {@code split} すればよい」と思いがちですが、それでは次の値が読めません。</p>
 *
 * <pre>{@code
 * "Brown, Emily"        … 値の中にカンマ。split(",") だと 2 つに割れる
 * "幅 24"" モニタ"       … 値の中の " は "" と 2 つ重ねて書かれている
 * "1 行目
 * 2 行目"               … 値の中に改行。行で割ると 2 行に割れる
 * }</pre>
 *
 * <p>そこで 1 文字ずつ読み、「いま {@code "} の中にいるか」を覚えながら区切ります。
 * {@code "} の中ではカンマも改行もただの文字です。</p>
 *
 * <h2>行番号の数え方</h2>
 * <p>見出しを 1 行目として、<b>レコード (CSV の 1 行) の順番</b>で数えます。
 * Excel で開いたときの行番号と同じです。
 * 値の中に改行があると、テキストエディタで見たときの行番号とはずれます。</p>
 *
 * <p>実務では Apache Commons CSV や OpenCSV を使ってください。
 * ここでは「何をしているか」が見えるよう、自前で書いています。</p>
 */
public final class CsvReader {

    private static final char DELIMITER = ',';
    private static final char QUOTE = '"';

    private CsvReader() {
    }

    /**
     * CSV を読む。
     *
     * @param text 文字コードを解決したあとの文字列 (BOM は取り除いておく)
     * @return 行の一覧 (空行も 1 行として含む)
     * @throws CsvFormatException {@code "} の閉じ方が壊れていて、どこで値が終わるか決められないとき
     */
    public static List<Row> read(String text) throws CsvFormatException {
        List<Row> rows = new ArrayList<>();
        List<String> values = new ArrayList<>();
        StringBuilder value = new StringBuilder();

        // いま " で囲まれた値の中にいるか
        boolean quoted = false;
        // " を閉じた直後か (このあとに来てよいのは区切りか改行だけ)
        boolean afterQuote = false;

        int i = 0;
        while (i < text.length()) {
            char c = text.charAt(i);

            if (quoted) {
                if (c == QUOTE) {
                    if (i + 1 < text.length() && text.charAt(i + 1) == QUOTE) {
                        value.append(QUOTE);   // "" は " 1 文字
                        i += 2;
                        continue;
                    }
                    quoted = false;            // 囲みの終わり
                    afterQuote = true;
                } else {
                    value.append(c);           // 囲みの中では、カンマも改行もただの文字
                }
                i++;
                continue;
            }

            if (c == DELIMITER) {
                values.add(value.toString());
                value.setLength(0);
                afterQuote = false;
                i++;
                continue;
            }

            if (c == '\r' || c == '\n') {
                values.add(value.toString());
                rows.add(new Row(rows.size() + 1, values));
                values = new ArrayList<>();
                value.setLength(0);
                afterQuote = false;
                // CRLF / LF / CR のどれで改行されていても 1 回の改行として扱う
                i += (c == '\r' && i + 1 < text.length() && text.charAt(i + 1) == '\n') ? 2 : 1;
                continue;
            }

            if (afterQuote) {
                // "abc"def のような形。どこまでが値なのか決められない
                throw new CsvFormatException(rows.size() + 1,
                        "\" で囲んだ値のすぐあとに文字があります。"
                        + "値の中の \" は \"\" のように 2 つ重ねて書いてください。");
            }

            if (c == QUOTE && value.length() == 0) {
                quoted = true;                 // 値の先頭の " だけを囲みの始まりとみなす
            } else {
                value.append(c);               // 値の途中の " は、ただの文字として読む
            }
            i++;
        }

        if (quoted) {
            // 閉じていない " があると、そこからファイルの最後までが 1 つの値になってしまう
            throw new CsvFormatException(rows.size() + 1,
                    "\" で始まった値が閉じられていません (\" が 1 つ足りません)。");
        }

        // 最後の行 (末尾に改行が無いとき)
        if (!values.isEmpty() || value.length() > 0 || afterQuote) {
            values.add(value.toString());
            rows.add(new Row(rows.size() + 1, values));
        }
        return rows;
    }

    /** 読み取った 1 行。 */
    public static final class Row {

        private final int lineNumber;
        private final List<String> values;

        Row(int lineNumber, List<String> values) {
            this.lineNumber = lineNumber;
            this.values = Collections.unmodifiableList(new ArrayList<>(values));
        }

        /** 行番号 (見出しを 1 行目として数える)。 */
        public int getLineNumber() {
            return lineNumber;
        }

        /** 値の一覧 (左の列から順に)。 */
        public List<String> getValues() {
            return values;
        }

        /**
         * 中身の無い行か。
         *
         * <p>Excel で保存した CSV には、最後に {@code ,,,,,,} だけの行が付いてくることがあります
         * (一度でも書式を付けたセルが「使われた範囲」に数えられるため)。
         * これをエラーにすると利用者には理由が分からないので、読み飛ばす判断に使います。</p>
         */
        public boolean isBlank() {
            return values.stream().allMatch(v -> v.strip().isEmpty());
        }
    }

    /** {@code "} の閉じ方が壊れていて、CSV として読めないとき。 */
    public static final class CsvFormatException extends Exception {

        private static final long serialVersionUID = 1L;

        private final int lineNumber;

        CsvFormatException(int lineNumber, String message) {
            super(message);
            this.lineNumber = lineNumber;
        }

        /** 壊れていた行の番号 (見出しを 1 行目として数える)。 */
        public int getLineNumber() {
            return lineNumber;
        }
    }
}
