package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * スコープのサンプルのうち、Servlet コンテナが無くても確かめられる部分のテスト。
 *
 * <p>application スコープは<b>全利用者で共有される</b>ため、
 * 「何でも入れられてしまわないか」を一番きちんと固めておきたいところです。</p>
 */
class ScopeServletTest {

    @Test
    @DisplayName("正しい入力なら、エラーメッセージは返らない")
    void acceptsValidInput() {
        assertNull(ScopeServlet.validate(ScopeServlet.SCOPE_REQUEST, "memo", "あとで消す"));
        assertNull(ScopeServlet.validate(ScopeServlet.SCOPE_SESSION, "cart_01", "りんご"));
        assertNull(ScopeServlet.validate(ScopeServlet.SCOPE_APPLICATION, "notice-1", "お知らせ"));
    }

    @Test
    @DisplayName("画面のラジオボタンに無いスコープは受け付けない")
    void rejectsUnknownScope() {
        // 画面を経由しなくてもリクエストは送れるので、受け取った値は必ず検査する
        assertNotNull(ScopeServlet.validate(null, "memo", "値"));
        assertNotNull(ScopeServlet.validate("", "memo", "値"));
        assertNotNull(ScopeServlet.validate("page", "memo", "値"));
        assertNotNull(ScopeServlet.validate("REQUEST", "memo", "値"));
    }

    @Test
    @DisplayName("探索順デモの hidden も、画面が出す 3 つのスコープだけを受け付ける")
    void acceptsOnlyKnownScopes() {
        // hidden の値も利用者が書き換えて送れるので、検査せずに画面へ出さない
        assertTrue(ScopeServlet.isKnownScope(ScopeServlet.SCOPE_REQUEST));
        assertTrue(ScopeServlet.isKnownScope(ScopeServlet.SCOPE_SESSION));
        assertTrue(ScopeServlet.isKnownScope(ScopeServlet.SCOPE_APPLICATION));

        assertFalse(ScopeServlet.isKnownScope(null));
        assertFalse(ScopeServlet.isKnownScope(""));
        assertFalse(ScopeServlet.isKnownScope("page"));
        assertFalse(ScopeServlet.isKnownScope("<img src=x onerror=alert(1)>"));
    }

    @Test
    @DisplayName("名前と値は必須")
    void rejectsEmptyNameAndValue() {
        assertNotNull(ScopeServlet.validate(ScopeServlet.SCOPE_REQUEST, "", "値"));
        assertNotNull(ScopeServlet.validate(ScopeServlet.SCOPE_REQUEST, "memo", ""));
    }

    @Test
    @DisplayName("名前は半角英数字・ハイフン・アンダースコアだけを許す")
    void rejectsNameWithUnexpectedCharacters() {
        // 属性名は接頭辞と連結してキーにし、EL の書き方として画面にも出すため、
        // 空白・記号・日本語が混ざらないようにしておく
        assertNotNull(ScopeServlet.validate(ScopeServlet.SCOPE_REQUEST, "名前", "値"));
        assertNotNull(ScopeServlet.validate(ScopeServlet.SCOPE_REQUEST, "my memo", "値"));
        assertNotNull(ScopeServlet.validate(ScopeServlet.SCOPE_REQUEST, "a.b", "値"));
        assertNotNull(ScopeServlet.validate(ScopeServlet.SCOPE_REQUEST, "<script>", "値"));
    }

    @Test
    @DisplayName("名前は 20 文字まで、値は 50 文字まで")
    void rejectsTooLongInput() {
        String name = "a".repeat(ScopeServlet.NAME_MAX_LENGTH);
        String value = "あ".repeat(ScopeServlet.VALUE_MAX_LENGTH);

        assertNull(ScopeServlet.validate(ScopeServlet.SCOPE_APPLICATION, name, value),
                "上限ちょうどは通るはずです");
        assertNotNull(ScopeServlet.validate(ScopeServlet.SCOPE_APPLICATION, name + "a", value));
        assertNotNull(ScopeServlet.validate(ScopeServlet.SCOPE_APPLICATION, name, value + "あ"));
    }

    @Test
    @DisplayName("未入力 (null) は空文字として扱い、前後の空白は取り除く")
    void trimsInput() {
        assertEquals("", ScopeServlet.trim(null));
        assertEquals("", ScopeServlet.trim("   "));
        assertEquals("memo", ScopeServlet.trim("  memo  "));
    }

    @Test
    @DisplayName("セッション ID は先頭だけを見せ、残りは伏せる")
    void masksSessionId() {
        String masked = ScopeServlet.maskSessionId("0123456789ABCDEF0123456789ABCDEF");

        assertTrue(masked.startsWith("01234567"), "先頭 8 文字が見えていません: " + masked);
        assertTrue(masked.indexOf("89ABCDEF0123") < 0, "続きが見えてしまっています: " + masked);

        // 取り違えても落ちないようにしておく
        assertEquals("", ScopeServlet.maskSessionId(null));
        assertEquals("", ScopeServlet.maskSessionId(""));
        assertEquals("short", ScopeServlet.maskSessionId("short"));
    }

    @Test
    @DisplayName("セッションの時刻 (エポックミリ秒) を読める形にする")
    void formatsEpochMillis() {
        // 実行環境のタイムゾーンで変わるので、形が崩れていないことだけを見る
        String text = ScopeServlet.formatEpoch(1_700_000_000_000L);

        assertTrue(text.matches("\\d{4}/\\d{2}/\\d{2} \\d{2}:\\d{2}:\\d{2}"),
                "yyyy/MM/dd HH:mm:ss になっていません: " + text);
    }
}
