package com.example.servletsample.samples.basic;

import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import javax.servlet.http.Cookie;

/**
 * 【サンプル】Cookie を扱うときの決まりごとをまとめた道具。
 *
 * <p>Cookie は「サーバがブラウザに預ける小さなメモ」です。
 * 預けたあとは、<b>同じサイトへのリクエストのたびにブラウザが自動で送り返します</b>。
 * 送り返されるのは<b>名前と値だけ</b>で、有効期限やパスといった属性は付いてきません。</p>
 *
 * <pre>
 * サーバ → ブラウザ   Set-Cookie: sample_memo=hello; Max-Age=3600; Path=/; HttpOnly
 * ブラウザ → サーバ   Cookie: sample_memo=hello          ← 属性は戻ってこない
 * </pre>
 *
 * <p>値に使える文字は限られています ({@code ;} {@code ,} 空白などは使えません)。
 * 日本語を入れたいときも含め、<b>URL エンコードしてから入れる</b>のが定番です。</p>
 */
public final class Cookies {

    private Cookies() {
    }

    /**
     * このサンプルで作る Cookie の名前に必ず付ける頭。
     *
     * <p>画面から来た名前をそのまま使うと <code>JSESSIONID</code> を
     * 上書きされてしまいます。デモであっても、触ってよい範囲を分かる形で区切ります。</p>
     */
    public static final String PREFIX = "sample_";

    /** セッション ID を運んでいる Cookie の名前 (Tomcat の既定)。 */
    public static final String SESSION_COOKIE = "JSESSIONID";

    /** 画面から選べる有効期限 (秒)。 */
    public static final List<Integer> MAX_AGES =
            Collections.unmodifiableList(Arrays.asList(-1, 0, 60, 3600, 86400));

    /** 名前に使ってよい文字数の上限 ({@link #PREFIX} を除いた部分)。 */
    static final int NAME_MAX_LENGTH = 20;

    /** 値の文字数の上限 (Cookie 全体で 4KB 程度までという制限があるため)。 */
    static final int VALUE_MAX_LENGTH = 100;

    /** 画面に出す Cookie 1 件分。 */
    public static final class View {

        private final String name;
        private final String rawValue;
        private final String value;

        View(String name, String rawValue, String value) {
            this.name = name;
            this.rawValue = rawValue;
            this.value = value;
        }

        /** Cookie の名前。 */
        public String getName() {
            return name;
        }

        /** ブラウザから届いたままの値 (URL エンコードされたまま)。 */
        public String getRawValue() {
            return rawValue;
        }

        /** URL デコードした値。 */
        public String getValue() {
            return value;
        }

        /** このサンプルで作ったものか。 */
        public boolean isSample() {
            return name.startsWith(PREFIX);
        }

        /** セッション ID を運んでいる Cookie か。 */
        public boolean isSessionCookie() {
            return SESSION_COOKIE.equals(name);
        }
    }

    /**
     * 届いた Cookie を画面用に整える。
     *
     * <p>{@code request.getCookies()} は<b>1 つも無いとき {@code null} を返します</b>
     * (空の配列ではありません)。毎回 null を確かめるのを忘れないための入口でもあります。</p>
     */
    public static List<View> view(Cookie[] cookies) {
        List<View> views = new ArrayList<>();
        if (cookies == null) {
            return views;
        }
        for (Cookie cookie : cookies) {
            views.add(new View(cookie.getName(), cookie.getValue(), decodeValue(cookie.getValue())));
        }
        return views;
    }

    /**
     * 画面から来た名前を、このサンプルで使ってよい名前に直す。
     *
     * <p>Cookie の名前に使えるのは英数字と一部の記号だけです
     * (使えない文字を {@code new Cookie(...)} に渡すと例外になります)。
     * ここでは英数字・{@code -}・{@code _} だけを残し、頭に {@link #PREFIX} を付けます。</p>
     */
    public static String demoName(String input) {
        StringBuilder cleaned = new StringBuilder();
        if (input != null) {
            for (int i = 0; i < input.length() && cleaned.length() < NAME_MAX_LENGTH; i++) {
                char c = input.charAt(i);
                if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
                        || (c >= '0' && c <= '9') || c == '-' || c == '_') {
                    cleaned.append(c);
                }
            }
        }
        return PREFIX + (cleaned.length() == 0 ? "memo" : cleaned);
    }

    /**
     * 値を Cookie に入れられる形にする。
     *
     * <p>日本語も {@code ;} も、URL エンコードすれば安全に運べます。</p>
     */
    public static String encodeValue(String value) {
        String source = value == null ? "" : value;
        if (source.length() > VALUE_MAX_LENGTH) {
            source = source.substring(0, VALUE_MAX_LENGTH);
        }
        return URLEncoder.encode(source, StandardCharsets.UTF_8);
    }

    /** URL エンコードされた値を元に戻す。戻せない値はそのまま返す。 */
    public static String decodeValue(String value) {
        if (value == null) {
            return "";
        }
        try {
            return URLDecoder.decode(value, StandardCharsets.UTF_8);
        } catch (IllegalArgumentException e) {
            // 自分で作ったもの以外は、URL エンコードされているとは限らない
            return value;
        }
    }

    /** 画面から来た有効期限を、選べる値だけに絞る。分からない値はブラウザを閉じるまで。 */
    public static int parseMaxAge(String value) {
        if (value == null) {
            return -1;
        }
        try {
            int maxAge = Integer.parseInt(value.trim());
            return MAX_AGES.contains(maxAge) ? maxAge : -1;
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    /** 有効期限を日本語にする。 */
    public static String describeMaxAge(int maxAge) {
        switch (maxAge) {
            case -1:
                return "ブラウザを閉じるまで (Max-Age を送らない)";
            case 0:
                return "すぐに削除";
            case 60:
                return "60 秒";
            case 3600:
                return "1 時間";
            case 86400:
                return "1 日";
            default:
                return maxAge + " 秒";
        }
    }
}
