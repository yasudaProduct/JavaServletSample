package com.example.servletsample.shared;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 共通ライブラリの表記そろえ ({@link CodeFormatter}) のテスト。
 *
 * <p>このテストが<b>共通ライブラリ側にある</b>ことに意味があります。
 * 共通ライブラリは JDK 以外に依存していないので、Tomcat もデータベースも
 * アプリ本体も無しで回せます。これが「共通に置いてよいもの」の目印です。</p>
 *
 * <p>逆に、テストを回すために Tomcat を起動しないといけない処理は、
 * 共通ライブラリに置くべきものではありません。</p>
 */
class CodeFormatterTest {

    @Test
    @DisplayName("前後の空白を落とす")
    void trims() {
        assertEquals("E1001", CodeFormatter.normalize("  E1001  "));
    }

    @Test
    @DisplayName("全角スペースも落とす")
    void trimsFullWidthSpace() {
        assertEquals("E1001", CodeFormatter.normalize("　E1001　"));
    }

    @Test
    @DisplayName("全角の英数字を半角にする")
    void convertsFullWidthToHalfWidth() {
        assertEquals("E1001", CodeFormatter.normalize("Ｅ１００１"));
    }

    @Test
    @DisplayName("英字は大文字に揃える")
    void upperCases() {
        assertEquals("E1001", CodeFormatter.normalize("e1001"));
    }

    @Test
    @DisplayName("null は空文字として扱う")
    void nullBecomesEmpty() {
        assertEquals("", CodeFormatter.normalize(null));
    }

    @Test
    @DisplayName("日本語はそのまま残す (全角英数字だけを変換する)")
    void keepsJapanese() {
        assertEquals("商品コード", CodeFormatter.normalize("商品コード"));
    }

    @Test
    @DisplayName("hasValue は空白だけを未入力とみなす")
    void hasValue() {
        assertFalse(CodeFormatter.hasValue(null));
        assertFalse(CodeFormatter.hasValue(""));
        assertFalse(CodeFormatter.hasValue("   "));
        assertFalse(CodeFormatter.hasValue("　"));
        assertTrue(CodeFormatter.hasValue("E1001"));
    }
}
