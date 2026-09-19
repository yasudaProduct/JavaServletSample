package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertSame;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * EL と JSTL の基本サンプルのテスト。
 *
 * <p>この画面は「利用者が URL を書き換えても落ちない」ことが前提になっています
 * （画面の説明文でもそう書いています）。受け取った値を丸める部分と、
 * エスケープ比較用の文字列をホワイトリストで選ぶ部分を確かめます。</p>
 */
class JspBasicsServletTest {

    @Nested
    @DisplayName("在庫数の受け取り")
    class ParseStock {

        @Test
        @DisplayName("数字ならそのまま受け取れる")
        void acceptsNumber() {
            assertEquals(7, JspBasicsServlet.parseStock("7"));
        }

        @Test
        @DisplayName("前後に空白があっても受け取れる")
        void trimsSpaces() {
            assertEquals(7, JspBasicsServlet.parseStock("  7  "),
                    "trim していないと NumberFormatException になります");
        }

        @Test
        @DisplayName("パラメータが無ければ既定値で続ける")
        void fallsBackWhenNotSent() {
            assertEquals(JspBasicsServlet.DEFAULT_STOCK, JspBasicsServlet.parseStock(null));
        }

        @Test
        @DisplayName("空文字なら既定値で続ける")
        void fallsBackWhenEmpty() {
            assertEquals(JspBasicsServlet.DEFAULT_STOCK, JspBasicsServlet.parseStock("   "));
        }

        @Test
        @DisplayName("数字でなければ既定値で続ける（画面をエラーにしない）")
        void fallsBackWhenNotANumber() {
            assertEquals(JspBasicsServlet.DEFAULT_STOCK, JspBasicsServlet.parseStock("abc"));
        }

        @Test
        @DisplayName("桁があふれる値でも既定値で続ける")
        void fallsBackWhenOverflow() {
            assertEquals(JspBasicsServlet.DEFAULT_STOCK,
                    JspBasicsServlet.parseStock("99999999999999999999"),
                    "int に収まらない値は NumberFormatException になります");
        }

        @Test
        @DisplayName("負の値は 0 に丸める")
        void clampsNegative() {
            assertEquals(0, JspBasicsServlet.parseStock("-1"));
        }

        @Test
        @DisplayName("大きすぎる値は上限に丸める")
        void clampsTooLarge() {
            assertEquals(JspBasicsServlet.MAX_STOCK, JspBasicsServlet.parseStock("100000"));
        }

        @Test
        @DisplayName("0 はそのまま 0（品切れの表示を確かめるため）")
        void keepsZero() {
            assertEquals(0, JspBasicsServlet.parseStock("0"));
        }
    }

    @Nested
    @DisplayName("ニックネームの受け取り")
    class ResolveNickname {

        @Test
        @DisplayName("パラメータが無ければ既定値を使う")
        void fallsBackWhenNotSent() {
            assertEquals(JspBasicsServlet.DEFAULT_NICKNAME, JspBasicsServlet.resolveNickname(null));
        }

        @Test
        @DisplayName("空文字で送られたら空文字のまま扱う")
        void keepsEmpty() {
            assertEquals("", JspBasicsServlet.resolveNickname(""),
                    "既定値に戻してしまうと empty 演算子の動きを画面で確かめられません");
        }

        @Test
        @DisplayName("空白だけで送られたら空文字として扱う")
        void treatsBlankAsEmpty() {
            assertEquals("", JspBasicsServlet.resolveNickname("   "));
        }

        @Test
        @DisplayName("前後の空白は落とす")
        void trimsSpaces() {
            assertEquals("たろちゃん", JspBasicsServlet.resolveNickname("  たろちゃん  "));
        }

        @Test
        @DisplayName("長すぎる入力は上限で切る")
        void cutsTooLongInput() {
            String longInput = "あ".repeat(100);
            assertEquals(JspBasicsServlet.NICKNAME_MAX_LENGTH,
                    JspBasicsServlet.resolveNickname(longInput).length());
        }
    }

    @Nested
    @DisplayName("エスケープ比較用の文字列の選択")
    class Preset {

        @Test
        @DisplayName("知っているキーはそのまま使う")
        void acceptsKnownKey() {
            assertEquals("color", JspBasicsServlet.presetKey("color"));
        }

        @Test
        @DisplayName("知らないキーは既定値に丸める")
        void rejectsUnknownKey() {
            assertEquals(JspBasicsServlet.DEFAULT_TEXT_KEY,
                    JspBasicsServlet.presetKey("<script>alert(1)</script>"),
                    "画面から来た文字列をそのまま HTML として出さないための入口です");
        }

        @Test
        @DisplayName("パラメータが無ければ既定値に丸める")
        void rejectsNullKey() {
            assertEquals(JspBasicsServlet.DEFAULT_TEXT_KEY, JspBasicsServlet.presetKey(null));
        }

        @Test
        @DisplayName("キーに対応する文字列が取れる")
        void returnsTextForKey() {
            assertNotNull(JspBasicsServlet.presetText("color"));
            assertEquals(JspBasicsServlet.presetText(JspBasicsServlet.DEFAULT_TEXT_KEY),
                    JspBasicsServlet.presetText("知らないキー"));
        }

        @Test
        @DisplayName("表示する文字列はサーバ側が持っているものだけ")
        void textIsNeverTakenFromTheRequest() {
            String dangerous = "<script>alert(1)</script>";
            assertSame(JspBasicsServlet.presetText(JspBasicsServlet.DEFAULT_TEXT_KEY),
                    JspBasicsServlet.presetText(dangerous),
                    "受け取った文字列がそのまま返ってくると、エスケープなしの比較が XSS の穴になります");
        }
    }
}
