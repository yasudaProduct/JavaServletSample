package com.example.servletsample.samples.basic;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * 【サンプル】文字化けを再現するための道具。
 *
 * <p>文字化けは「文字」が壊れて起きるのではありません。
 * 文字はいったん<b>バイト列</b>になって運ばれ、受け取った側がそれを文字に戻します。
 * このとき<b>書いたときと違う文字コードで読む</b>と化けます。</p>
 *
 * <pre>
 *   "文字化け"  --[UTF-8 で書く]--&gt;  E6 96 87 E5 AD 97 ...  --[Shift_JIS で読む]--&gt;  "譁・ｭ怜喧"
 * </pre>
 *
 * <p>実際のリクエストを壊さなくても、この「書いて読み直す」を Java の中で
 * そのまま再現すれば、化け方を安全に見せられます。</p>
 */
public final class Mojibake {

    private Mojibake() {
    }

    /** デモで選べる文字コード。 */
    public static final List<String> CHARSET_NAMES = Collections.unmodifiableList(Arrays.asList(
            "UTF-8", "Shift_JIS", "windows-31j", "EUC-JP", "ISO-8859-1", "US-ASCII"));

    /** 化けたかどうかの判断に使う、読めなかった文字の代わりの記号。 */
    public static final char REPLACEMENT = '�';

    /** 変換 1 回分の結果。 */
    public static final class Conversion {

        private final String writtenAs;
        private final String readAs;
        private final String text;
        private final String hex;
        private final String note;
        private final boolean broken;

        Conversion(String writtenAs, String readAs, String text, String hex, String note,
                boolean broken) {
            this.writtenAs = writtenAs;
            this.readAs = readAs;
            this.text = text;
            this.hex = hex;
            this.note = note;
            this.broken = broken;
        }

        /** 書き出すときに使った文字コード。 */
        public String getWrittenAs() {
            return writtenAs;
        }

        /** 読み直すときに使った文字コード。 */
        public String getReadAs() {
            return readAs;
        }

        /** 読み直した結果の文字列。 */
        public String getText() {
            return text;
        }

        /** 書き出したバイト列 (16 進)。 */
        public String getHex() {
            return hex;
        }

        /** 画面に添える一言。 */
        public String getNote() {
            return note;
        }

        /** 元に戻らなかったか (画面で色を変えるため)。 */
        public boolean isBroken() {
            return broken;
        }
    }

    /**
     * 「この文字コードで書いて、別の文字コードで読む」を再現する。
     *
     * @param text      元の文字列
     * @param writtenAs 書き出すときの文字コード名
     * @param readAs    読み直すときの文字コード名
     */
    public static String simulate(String text, String writtenAs, String readAs) {
        if (text == null) {
            return "";
        }
        byte[] bytes = text.getBytes(charset(writtenAs));
        return new String(bytes, charset(readAs));
    }

    /**
     * 文字列を指定の文字コードでバイト列にし、16 進で並べる。
     *
     * <p>文字化けを追うときは、まずここを見ます。
     * 「E3 81 82」なら UTF-8 の「あ」、「82 A0」なら Shift_JIS の「あ」です。</p>
     */
    public static String toHex(String text, String charsetName) {
        if (text == null || text.isEmpty()) {
            return "";
        }
        byte[] bytes = text.getBytes(charset(charsetName));
        StringBuilder hex = new StringBuilder(bytes.length * 3);
        for (int i = 0; i < bytes.length; i++) {
            if (i > 0) {
                hex.append(' ');
            }
            hex.append(String.format("%02X", bytes[i]));
        }
        return hex.toString();
    }

    /**
     * 化け方を一覧にする。
     *
     * <p>元の文字列を UTF-8 / Shift_JIS で書き出し、いくつかの文字コードで読み直します。</p>
     */
    public static List<Conversion> patterns(String text) {
        List<Conversion> conversions = new ArrayList<>();
        conversions.add(conversion(text, "UTF-8", "UTF-8",
                "正しい組み合わせ。書いたときと同じ文字コードで読めば元に戻ります"));
        conversions.add(conversion(text, "UTF-8", "windows-31j",
                "UTF-8 を Shift_JIS 系で読んだ形。日本語の Web でいちばんよく見る化け方です"));
        conversions.add(conversion(text, "UTF-8", "ISO-8859-1",
                "1 バイトずつ別の文字として読まれた形。ラテン文字が並びます"));
        conversions.add(conversion(text, "windows-31j", "UTF-8",
                "Shift_JIS を UTF-8 で読んだ形。UTF-8 として成り立たないバイトは "
                        + REPLACEMENT + " (U+FFFD) になります"));
        conversions.add(conversion(text, "UTF-8", "US-ASCII",
                "読み手に日本語を表す手段が無い形。1 バイトずつ " + REPLACEMENT + " に潰れます"));
        conversions.add(conversion(text, "ISO-8859-1", "UTF-8",
                "書き手に日本語を表す手段が無い形。バイト列の時点で ? になっており、もう戻せません"));
        return conversions;
    }

    private static Conversion conversion(String text, String writtenAs, String readAs, String note) {
        String result = simulate(text, writtenAs, readAs);
        return new Conversion(writtenAs, readAs, result, toHex(text, writtenAs), note,
                !result.equals(text));
    }

    /**
     * クエリ文字列から、指定した文字コードでパラメータを読み直す。
     *
     * <p>コンテナは決められた文字コード (Tomcat 8 以降は既定で UTF-8) で
     * クエリ文字列を読みます。古いシステムから Shift_JIS で組み立てられた URL が
     * 飛んでくると、{@code request.getParameter} の時点で化けてしまいます。</p>
     *
     * <p>そのときは、生のクエリ文字列 ({@code request.getQueryString()}) を
     * 自分で分解して読み直すと復元できます。<b>すでに化けた文字列から戻すのではなく、
     * 生のバイト列まで戻ってやり直す</b>のが要点です。</p>
     *
     * @param rawQuery    {@code request.getQueryString()} の値 (例: {@code q=%95%B6%8E%9A})
     * @param name        取り出したいパラメータ名
     * @param charsetName 組み立てに使われた文字コード
     * @return 読み直した値。見つからなければ {@code null}
     */
    public static String recoverParameter(String rawQuery, String name, String charsetName) {
        if (rawQuery == null || name == null) {
            return null;
        }
        for (String pair : rawQuery.split("&")) {
            int equal = pair.indexOf('=');
            if (equal < 0) {
                continue;
            }
            String key = pair.substring(0, equal);
            if (!name.equals(key)) {
                continue;
            }
            try {
                return URLDecoder.decode(pair.substring(equal + 1), charsetName);
            } catch (UnsupportedEncodingException | IllegalArgumentException e) {
                // 壊れた % の並びが混ざっていることもある。デモなので握りつぶさず空で返す
                return "";
            }
        }
        return null;
    }

    /**
     * 指定した文字コードで URL のクエリ文字列用にエスケープする。
     *
     * <p>「Shift_JIS で組み立てられたリンク」をデモで作るために使います。</p>
     */
    public static String encodeForQuery(String value, String charsetName) {
        return URLEncoder.encode(value == null ? "" : value, charset(charsetName));
    }

    /** 文字コード名が使えるか。 */
    public static boolean isSupported(String charsetName) {
        try {
            return Charset.isSupported(charsetName);
        } catch (IllegalArgumentException e) {
            // 文字コード名として使えない文字が混ざっていると
            // IllegalCharsetNameException (IllegalArgumentException の一種) になる
            return false;
        }
    }

    /** 文字コード名を Charset に直す。知らない名前は UTF-8 として扱う (デモを止めないため)。 */
    static Charset charset(String charsetName) {
        return isSupported(charsetName) ? Charset.forName(charsetName) : Charset.forName("UTF-8");
    }
}
