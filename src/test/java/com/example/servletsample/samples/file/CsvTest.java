package com.example.servletsample.samples.file;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * CSV の組み立て ({@link Csv}) のテスト。
 *
 * <p>CSV は「カンマで区切るだけ」に見えて、値の中にカンマ・改行・ダブルクォートが
 * 入った瞬間に壊れます。壊れ方を先にテストで押さえておくと、
 * 本番データで初めて気付く、ということがなくなります。</p>
 */
class CsvTest {

    @Nested
    @DisplayName("エスケープ (RFC 4180)")
    class Escape {

        @ParameterizedTest
        @ValueSource(strings = {"A-001", "山田太郎", "1200", "", "ハイフン-入り"})
        @DisplayName("囲む必要が無い値は、そのまま出す")
        void plainValueIsNotQuoted(String raw) {
            assertEquals(raw, Csv.field(raw, ',', true, false));
        }

        @Test
        @DisplayName("区切り文字を含む値は囲む")
        void quotesValueWithDelimiter() {
            assertEquals("\"ケーブル, 2m\"", Csv.field("ケーブル, 2m", ',', true, false));
        }

        @Test
        @DisplayName("ダブルクォートは 2 つにして、全体を囲む")
        void doublesQuoteCharacter() {
            assertEquals("\"幅 24\"\" モニタ\"", Csv.field("幅 24\" モニタ", ',', true, false));
        }

        @Test
        @DisplayName("改行を含む値は囲む (改行はそのまま残す)")
        void quotesValueWithNewline() {
            assertEquals("\"至急\n要確認\"", Csv.field("至急\n要確認", ',', true, false));
        }

        @Test
        @DisplayName("前後に空白がある値は囲む (読み込む側で落とされないように)")
        void quotesValueWithSurroundingSpaces() {
            assertEquals("\"  ゼータ  \"", Csv.field("  ゼータ  ", ',', true, false));
        }

        @Test
        @DisplayName("タブ区切りのときは、タブを含む値を囲む (カンマは囲まない)")
        void quotesByActualDelimiter() {
            assertEquals("\"a\tb\"", Csv.field("a\tb", '\t', true, false));
            assertEquals("a,b", Csv.field("a,b", '\t', true, false));
        }

        @Test
        @DisplayName("エスケープを切ると、そのまま連結される (壊れる)")
        void withoutQuotingValueIsRawAndBreaks() {
            assertEquals("ケーブル, 2m", Csv.field("ケーブル, 2m", ',', false, false));
            assertEquals("至急\n要確認", Csv.field("至急\n要確認", ',', false, false));
        }
    }

    @Nested
    @DisplayName("数式ガード (CSV インジェクション対策)")
    class FormulaGuard {

        @ParameterizedTest
        @ValueSource(strings = {"=1+1", "=cmd|'/c calc'!A0", "+A1", "-A1+B1", "@SUM(A1)", "\tx", "\rx"})
        @DisplayName("数式として解釈されうる値は守る")
        void guardsFormulaLikeValues(String raw) {
            assertTrue(Csv.needsFormulaGuard(raw), raw);
            assertTrue(Csv.field(raw, ',', true, true).contains("'" + raw.charAt(0)),
                    Csv.field(raw, ',', true, true));
        }

        @ParameterizedTest
        @ValueSource(strings = {"-500", "-3600", "+100", "-1.5", "0", "1200"})
        @DisplayName("数値として読める値は守らない (金額の列が集計できなくなるため)")
        void doesNotGuardNumbers(String raw) {
            assertFalse(Csv.needsFormulaGuard(raw), raw);
            assertEquals(raw, Csv.field(raw, ',', true, true));
        }

        @ParameterizedTest
        @ValueSource(strings = {"山田太郎", "A-001", "返品", ""})
        @DisplayName("ふつうの値は守らない")
        void doesNotGuardPlainValues(String raw) {
            assertFalse(Csv.needsFormulaGuard(raw));
        }

        @Test
        @DisplayName("ガードを切ると、数式のまま出る")
        void withoutGuardFormulaStaysAsIs() {
            assertEquals("=1+1", Csv.field("=1+1", ',', true, false));
        }

        @Test
        @DisplayName("ガードとエスケープは両方かかる")
        void guardAndQuoteAreBothApplied() {
            // 先頭に ' が付いたうえで、カンマを含むので囲まれる
            assertEquals("\"'=1,2\"", Csv.field("=1,2", ',', true, true));
        }
    }

    @Nested
    @DisplayName("行の組み立て")
    class Rows {

        @Test
        @DisplayName("区切り文字と改行コードは指定どおりになる")
        void usesConfiguredDelimiterAndNewline() {
            Csv csv = new Csv(',', "\r\n", true, false);
            csv.row("a", "b");
            csv.row("c", "d");

            assertEquals("a,b\r\nc,d\r\n", csv.text());
            assertEquals(2, csv.lineCount());
        }

        @Test
        @DisplayName("LF とタブ区切りも選べる")
        void supportsTabAndLf() {
            Csv csv = new Csv('\t', "\n", true, false);
            csv.row("a", "b");

            assertEquals("a\tb\n", csv.text());
        }

        @Test
        @DisplayName("null は空文字として書く")
        void writesNullAsEmpty() {
            Csv csv = new Csv(',', "\n", true, false);
            csv.row("a", null, "c");

            assertEquals("a,,c\n", csv.text());
        }

        @Test
        @DisplayName("数値もそのまま書ける")
        void writesNumbers() {
            Csv csv = new Csv(',', "\n", true, true);
            csv.row("A-001", 3, -500);

            assertEquals("A-001,3,-500\n", csv.text());
        }

        @Test
        @DisplayName("1 行も書いていなければ 0 行")
        void emptyCsvHasNoLines() {
            assertEquals(0, new Csv(',', "\n", true, false).lineCount());
        }
    }

    @Nested
    @DisplayName("ダウンロードのヘッダ")
    class Header {

        @Test
        @DisplayName("日本語のファイル名は filename* で渡す")
        void encodesJapaneseFileName() {
            String value = CsvExportServlet.contentDisposition("売上明細.csv", "sales.csv");

            assertTrue(value.startsWith("attachment; "), value);
            assertTrue(value.contains("filename=\"sales.csv\""), value);
            assertTrue(value.contains("filename*=UTF-8''"), value);
            // 日本語はそのまま入れない (ヘッダは ASCII しか書けない)
            assertFalse(value.contains("売上明細"), value);
        }

        @Test
        @DisplayName("空白は + ではなく %20 にする (RFC 5987)")
        void encodesSpaceAsPercent20() {
            String value = CsvExportServlet.contentDisposition("sales report.csv", "sales.csv");

            assertTrue(value.contains("%20"), value);
            assertFalse(value.contains("+"), value);
        }
    }

    @Nested
    @DisplayName("デモ用データ")
    class DemoData {

        @Test
        @DisplayName("見出しと値の列数がそろっている")
        void headerAndValuesHaveSameSize() {
            int columns = SalesRecord.headers().size();
            for (SalesRecord record : SalesRecords.all()) {
                assertEquals(columns, record.values().size(), record.getOrderNo());
            }
        }

        @ParameterizedTest
        @CsvSource({
                "',',  true",
                "'\"', true",
                "'\n', true"
        })
        @DisplayName("エスケープが要る値が、ちゃんと混ざっている")
        void containsTrickyValues(String tricky, boolean expected) {
            boolean found = SalesRecords.all().stream()
                    .flatMap(record -> record.values().stream())
                    .map(String::valueOf)
                    .anyMatch(value -> value.contains(tricky));

            assertEquals(expected, found, "厄介な値が入っていません: " + tricky);
        }

        @Test
        @DisplayName("数式に見える値と負の数の両方が入っている")
        void containsFormulaAndNegativeNumber() {
            boolean hasFormula = SalesRecords.all().stream()
                    .anyMatch(record -> record.getNote().startsWith("="));
            boolean hasNegative = SalesRecords.all().stream()
                    .anyMatch(record -> record.getAmount() < 0);

            assertTrue(hasFormula, "数式に見える値が入っていません");
            assertTrue(hasNegative, "負の数が入っていません");
        }
    }
}
