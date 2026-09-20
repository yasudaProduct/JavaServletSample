package com.example.servletsample.samples.file;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.charset.UnsupportedCharsetException;

import javax.servlet.http.HttpServletRequest;

/**
 * CSV を出すときの選択肢。
 *
 * <p>画面で選んだ内容を 1 つにまとめ、<b>プレビューとダウンロードで同じ設定を使う</b>ためのクラスです。
 * 画面側の Servlet とダウンロード側の Servlet で別々に解釈すると、
 * 「画面で見たものと落ちてきたファイルが違う」ことになります。</p>
 */
public final class CsvOptions {

    /** 文字コードの選択肢。 */
    public enum Encoding {

        /** UTF-8 + BOM。Excel で開くならこれが無難。 */
        UTF8_BOM("utf8-bom", "UTF-8（BOM あり）", StandardCharsets.UTF_8, true),

        /** UTF-8 のみ。プログラムで読むならこれ。 */
        UTF8("utf8", "UTF-8（BOM なし）", StandardCharsets.UTF_8, false),

        /** Shift_JIS (Windows-31J)。古いシステムとのやり取り用。 */
        SJIS("sjis", "Shift_JIS（Windows-31J）", windows31j(), false);

        private final String key;
        private final String label;
        private final Charset charset;
        private final boolean bom;

        Encoding(String key, String label, Charset charset, boolean bom) {
            this.key = key;
            this.label = label;
            this.charset = charset;
            this.bom = bom;
        }

        /** URL に載せる値。 */
        public String getKey() {
            return key;
        }

        /** 画面に出す名前。 */
        public String getLabel() {
            return label;
        }

        /** 実際の文字コード。 */
        public Charset getCharset() {
            return charset;
        }

        /** 先頭に BOM を付けるか。 */
        public boolean isBom() {
            return bom;
        }

        /** Shift_JIS に無い文字が化けうるか。 */
        public boolean isLossy() {
            return this == SJIS;
        }

        static Encoding of(String key) {
            for (Encoding encoding : values()) {
                if (encoding.key.equals(key)) {
                    return encoding;
                }
            }
            return UTF8_BOM;
        }

        /**
         * Windows-31J を取り出す。
         *
         * <p>いわゆる Shift_JIS には方言があり、Java の {@code Shift_JIS} では
         * 「①」「㈱」「～」といった Windows 独自の文字を出せません。
         * Windows で作られた CSV とやり取りするなら {@code Windows-31J} (CP932) を使います。</p>
         */
        private static Charset windows31j() {
            try {
                return Charset.forName("Windows-31J");
            } catch (UnsupportedCharsetException e) {
                return Charset.forName("Shift_JIS");
            }
        }
    }

    private final Encoding encoding;
    private final boolean tabDelimited;
    private final boolean crlf;
    private final boolean header;
    private final boolean quote;
    private final boolean guardFormula;

    private CsvOptions(Encoding encoding, boolean tabDelimited, boolean crlf,
                       boolean header, boolean quote, boolean guardFormula) {
        this.encoding = encoding;
        this.tabDelimited = tabDelimited;
        this.crlf = crlf;
        this.header = header;
        this.quote = quote;
        this.guardFormula = guardFormula;
    }

    /**
     * リクエストパラメータから組み立てる。
     *
     * <p>チェックボックスは<b>チェックを外すとパラメータ自体が送られてきません</b>。
     * 「初期表示では全部オン」にしたいので、
     * 一緒に送る隠し項目 ({@code submitted}) で「フォームから来たかどうか」を見分けています。
     * これを忘れると、画面を開いた瞬間にすべてオフになります。</p>
     */
    public static CsvOptions from(HttpServletRequest request) {
        boolean submitted = request.getParameter("submitted") != null;
        return new CsvOptions(
                Encoding.of(request.getParameter("encoding")),
                "tab".equals(request.getParameter("delimiter")),
                !submitted || request.getParameter("crlf") != null,
                !submitted || request.getParameter("header") != null,
                !submitted || request.getParameter("quote") != null,
                !submitted || request.getParameter("guardFormula") != null);
    }

    /** 文字コード。 */
    public Encoding getEncoding() {
        return encoding;
    }

    /** 区切り文字。 */
    public char getDelimiter() {
        return tabDelimited ? '\t' : ',';
    }

    /** タブ区切りか。 */
    public boolean isTabDelimited() {
        return tabDelimited;
    }

    /**
     * 改行コード。
     *
     * <p>RFC 4180 は {@code CRLF} と定めています。
     * Excel はどちらでも開けますが、<b>古いシステムに渡すなら CRLF</b> が無難です。</p>
     */
    public String getNewline() {
        return crlf ? "\r\n" : "\n";
    }

    /** CRLF か。 */
    public boolean isCrlf() {
        return crlf;
    }

    /** 見出し行を付けるか。 */
    public boolean isHeader() {
        return header;
    }

    /** RFC 4180 のエスケープを行うか。 */
    public boolean isQuote() {
        return quote;
    }

    /** 数式ガードを行うか。 */
    public boolean isGuardFormula() {
        return guardFormula;
    }

    /** 選んだ内容で CSV を組み立てる。 */
    public String build() {
        Csv csv = new Csv(getDelimiter(), getNewline(), quote, guardFormula);
        if (header) {
            csv.row(SalesRecord.headers().toArray());
        }
        for (SalesRecord record : SalesRecords.all()) {
            csv.row(record.values().toArray());
        }
        return csv.text();
    }

    /** ダウンロード用のリンクに付けるクエリ文字列。 */
    public String query() {
        StringBuilder query = new StringBuilder("submitted=1");
        query.append("&encoding=").append(encoding.getKey());
        query.append("&delimiter=").append(tabDelimited ? "tab" : "comma");
        if (crlf) {
            query.append("&crlf=1");
        }
        if (header) {
            query.append("&header=1");
        }
        if (quote) {
            query.append("&quote=1");
        }
        if (guardFormula) {
            query.append("&guardFormula=1");
        }
        return query.toString();
    }
}
