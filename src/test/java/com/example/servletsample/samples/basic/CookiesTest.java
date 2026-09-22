package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import javax.servlet.http.Cookie;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.example.servletsample.samples.basic.Cookies.View;

/**
 * Cookie の名前・値の扱いを確かめるテスト。
 *
 * <p>名前に使えない文字を渡すと {@code new Cookie(...)} は例外を投げ、
 * 値に区切り文字が入ると受け取り側で壊れます。画面から来た文字列を
 * そのまま使わない約束が守られているかを見ています。</p>
 */
class CookiesTest {

    @Test
    @DisplayName("名前には必ず sample_ が付く")
    void prefixesDemoNames() {
        assertEquals("sample_memo", Cookies.demoName("memo"));
        assertEquals("sample_memo", Cookies.demoName(null), "未入力なら既定の名前");
        assertEquals("sample_memo", Cookies.demoName(""), "空なら既定の名前");
    }

    @Test
    @DisplayName("名前に使えない文字は落とす")
    void removesIllegalCharactersFromName() {
        // 空白・記号・日本語は Cookie の名前に使えない
        assertEquals("sample_ab", Cookies.demoName("a b"));
        assertEquals("sample_memo", Cookies.demoName("メモmemo"));
        assertEquals("sample_a-b_c", Cookies.demoName("a-b_c"));

        // JSESSIONID を上書きしようとしても、別名になる
        assertEquals("sample_JSESSIONID", Cookies.demoName("JSESSIONID"));
        assertFalse(Cookies.demoName("JSESSIONID").equals(Cookies.SESSION_COOKIE));
    }

    @Test
    @DisplayName("名前の長さを制限する")
    void limitsNameLength() {
        String longName = "a".repeat(100);

        assertEquals(Cookies.PREFIX.length() + Cookies.NAME_MAX_LENGTH,
                Cookies.demoName(longName).length());
    }

    @Test
    @DisplayName("値は URL エンコードして預け、読むときに戻す")
    void encodesAndDecodesValues() {
        String value = "こんにちは; 世界";
        String encoded = Cookies.encodeValue(value);

        // Cookie の値に使えない文字が残っていないこと
        assertFalse(encoded.contains(";"), "区切り文字が残っています: " + encoded);
        assertFalse(encoded.contains(" "), "空白が残っています: " + encoded);
        assertEquals(value, Cookies.decodeValue(encoded));
    }

    @Test
    @DisplayName("値の長さを制限する")
    void limitsValueLength() {
        String decoded = Cookies.decodeValue(Cookies.encodeValue("あ".repeat(300)));

        assertEquals(Cookies.VALUE_MAX_LENGTH, decoded.length());
    }

    @Test
    @DisplayName("URL エンコードされていない値でも、読むときに落ちない")
    void decodesForeignValuesSafely() {
        assertEquals("plain-value", Cookies.decodeValue("plain-value"));
        assertEquals("", Cookies.decodeValue(null));
        // % のあとが 16 進でない値 (他のサイトが作った Cookie など)
        assertEquals("100%", Cookies.decodeValue("100%"));
    }

    @Test
    @DisplayName("有効期限は選べる値だけを受け付ける")
    void allowsOnlyListedMaxAges() {
        assertEquals(3600, Cookies.parseMaxAge("3600"));
        assertEquals(0, Cookies.parseMaxAge("0"));
        assertEquals(-1, Cookies.parseMaxAge("-1"));

        // 許可していない値・読めない値はブラウザを閉じるまでに倒す
        assertEquals(-1, Cookies.parseMaxAge("99999999"));
        assertEquals(-1, Cookies.parseMaxAge("abc"));
        assertEquals(-1, Cookies.parseMaxAge(null));
    }

    @Test
    @DisplayName("Cookie が 1 つも無ければ空の一覧になる")
    void viewHandlesNullArray() {
        // getCookies() は 1 つも無いと null を返す
        assertTrue(Cookies.view(null).isEmpty());
    }

    @Test
    @DisplayName("セッションの Cookie とサンプルの Cookie を見分けられる")
    void marksSessionAndSampleCookies() {
        List<View> views = Cookies.view(new Cookie[] {
                new Cookie(Cookies.SESSION_COOKIE, "ABC123"),
                new Cookie("sample_memo", Cookies.encodeValue("こんにちは")),
                new Cookie("other", "x")});

        assertTrue(views.get(0).isSessionCookie());
        assertFalse(views.get(0).isSample());

        assertTrue(views.get(1).isSample());
        assertEquals("こんにちは", views.get(1).getValue(), "画面にはデコードした値を出す");

        assertFalse(views.get(2).isSample());
        assertFalse(views.get(2).isSessionCookie());
    }

    @Test
    @DisplayName("削除に使う Path はコンテキストパスから組み立てる")
    void buildsPathsFromContextPath() {
        assertEquals("/", CookieServlet.pathAll(""));
        assertEquals("/app/", CookieServlet.pathAll("/app"));
        assertEquals("/samples/basic/cookie", CookieServlet.pathSample(""));
        assertEquals("/app/samples/basic/cookie", CookieServlet.pathSample("/app"));
    }
}
