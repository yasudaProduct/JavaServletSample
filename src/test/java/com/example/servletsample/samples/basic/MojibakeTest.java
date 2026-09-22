package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.example.servletsample.samples.basic.Mojibake.Conversion;

/**
 * 文字化けの再現が、説明どおりの結果になるかを確かめるテスト。
 *
 * <p>画面に「この組み合わせならこう化ける」と出す以上、
 * 化け方そのものが説明と合っていないと解説が嘘になります。</p>
 */
class MojibakeTest {

    @Test
    @DisplayName("同じ文字コードで書いて読めば元に戻る")
    void sameCharsetKeepsText() {
        assertEquals("文字化け", Mojibake.simulate("文字化け", "UTF-8", "UTF-8"));
        assertEquals("文字化け", Mojibake.simulate("文字化け", "windows-31j", "windows-31j"));
    }

    @Test
    @DisplayName("UTF-8 を Shift_JIS 系で読むと化ける")
    void utf8ReadAsShiftJisBreaks() {
        String broken = Mojibake.simulate("文字化け", "UTF-8", "windows-31j");

        assertNotEquals("文字化け", broken, "化けていません");
        // 日本語 1 文字が UTF-8 では 3 バイトなので、Shift_JIS 系では 1.5 文字ぶんに見える
        assertTrue(broken.length() > "文字化け".length(), "文字数が増えていません: " + broken);
    }

    @Test
    @DisplayName("ISO-8859-1 は 1 バイトを 1 文字として読むので、読み直せば元に戻る")
    void latin1IsByteTransparent() {
        String broken = Mojibake.simulate("文字化け", "UTF-8", "ISO-8859-1");

        assertNotEquals("文字化け", broken);
        // バイト列がそのまま保たれるため、書き直して読み直すと復元できる
        assertEquals("文字化け", Mojibake.simulate(broken, "ISO-8859-1", "UTF-8"));
    }

    @Test
    @DisplayName("書き手に表現手段が無ければ ? に潰れて戻せない")
    void unsupportedCharactersBecomeQuestionMarks() {
        String written = Mojibake.simulate("文字化け", "ISO-8859-1", "ISO-8859-1");

        assertEquals("????", written, "? に潰れていません: " + written);
        assertEquals("3F 3F 3F 3F", Mojibake.toHex("文字化け", "ISO-8859-1"),
                "バイト列の時点で ? (0x3F) になっているはずです");
    }

    @Test
    @DisplayName("読み手が解釈できないバイトは U+FFFD になる")
    void undecodableBytesBecomeReplacementCharacter() {
        String broken = Mojibake.simulate("文字化け", "windows-31j", "UTF-8");

        assertTrue(broken.indexOf(Mojibake.REPLACEMENT) >= 0,
                "読めなかった印 (U+FFFD) が出ていません: " + broken);
    }

    @Test
    @DisplayName("バイト列を 16 進で並べられる")
    void printsBytesAsHex() {
        assertEquals("41 42", Mojibake.toHex("AB", "UTF-8"));
        assertEquals("E3 81 82", Mojibake.toHex("あ", "UTF-8"));
        assertEquals("82 A0", Mojibake.toHex("あ", "windows-31j"));
        assertEquals("", Mojibake.toHex("", "UTF-8"));
        assertEquals("", Mojibake.toHex(null, "UTF-8"));
    }

    @Test
    @DisplayName("化け方の一覧には正しい組み合わせが 1 つだけ入る")
    void patternsContainExactlyOneCorrectRow() {
        List<Conversion> conversions = Mojibake.patterns("文字化け");

        long correct = conversions.stream().filter(conversion -> !conversion.isBroken()).count();
        assertEquals(1, correct, "元に戻る組み合わせは UTF-8 → UTF-8 の 1 つだけのはずです");
        assertEquals("UTF-8", conversions.get(0).getWrittenAs());
        assertEquals("UTF-8", conversions.get(0).getReadAs());
        assertEquals("文字化け", conversions.get(0).getText());
    }

    @Test
    @DisplayName("生のクエリ文字列から、正しい文字コードで読み直せる")
    void recoversParameterFromRawQueryString() {
        String encoded = Mojibake.encodeForQuery("売上一覧", "windows-31j");

        // Shift_JIS で組み立てられているので、UTF-8 の %E5... にはならない
        assertTrue(encoded.startsWith("%94%84"), "Shift_JIS で組み立てられていません: " + encoded);
        assertEquals("売上一覧",
                Mojibake.recoverParameter("q=" + encoded, "q", "windows-31j"));
    }

    @Test
    @DisplayName("クエリ文字列に無いパラメータは null")
    void returnsNullForMissingParameter() {
        assertNull(Mojibake.recoverParameter("a=1&b=2", "q", "UTF-8"));
        assertNull(Mojibake.recoverParameter(null, "q", "UTF-8"));
        assertNull(Mojibake.recoverParameter("q", "q", "UTF-8"), "= が無い項目は値なしとして扱う");
    }

    @Test
    @DisplayName("似た名前のパラメータを取り違えない")
    void picksTheExactParameterName() {
        assertEquals("2", Mojibake.recoverParameter("qq=1&q=2", "q", "UTF-8"));
    }

    @Test
    @DisplayName("知らない文字コード名を渡してもデモが止まらない")
    void fallsBackToUtf8ForUnknownCharset() {
        assertEquals("文字化け", Mojibake.simulate("文字化け", "NO_SUCH_CHARSET", "UTF-8"));
        assertEquals(false, Mojibake.isSupported("NO_SUCH_CHARSET"));
        assertEquals(false, Mojibake.isSupported("日本語"), "文字コード名として不正な文字列");
    }
}
