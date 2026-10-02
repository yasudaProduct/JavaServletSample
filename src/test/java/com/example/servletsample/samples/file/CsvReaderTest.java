package com.example.servletsample.samples.file;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * CSV の読み取り ({@link CsvReader}) のテスト。
 *
 * <p>{@code split(",")} では読めない値 (カンマ・改行・{@code "} を含む値) を
 * 正しく読めることを確かめます。書き出し側の {@link Csv} で作った CSV を
 * 読み戻して、元の値に戻ることも確かめています。</p>
 */
class CsvReaderTest {

    @Nested
    @DisplayName("値の区切り方")
    class Values {

        @Test
        @DisplayName("カンマで区切り、改行で行を分ける")
        void splitsByCommaAndNewline() throws Exception {
            List<CsvReader.Row> rows = CsvReader.read("a,b,c\n1,2,3\n");

            assertEquals(2, rows.size());
            assertEquals(List.of("a", "b", "c"), rows.get(0).getValues());
            assertEquals(List.of("1", "2", "3"), rows.get(1).getValues());
        }

        @Test
        @DisplayName("\" で囲まれた値の中のカンマは区切りにしない")
        void keepsCommaInQuotedValue() throws Exception {
            List<CsvReader.Row> rows = CsvReader.read("E10003,\"Brown, Emily\",D02\n");

            assertEquals(List.of("E10003", "Brown, Emily", "D02"), rows.get(0).getValues());
        }

        @Test
        @DisplayName("\"\" は \" 1 文字として読む")
        void readsEscapedQuote() throws Exception {
            List<CsvReader.Row> rows = CsvReader.read("\"幅 24\"\" モニタ\",x\n");

            assertEquals(List.of("幅 24\" モニタ", "x"), rows.get(0).getValues());
        }

        @Test
        @DisplayName("囲まれていない値の途中にある \" は、ただの文字として読む")
        void keepsQuoteInUnquotedValue() throws Exception {
            List<CsvReader.Row> rows = CsvReader.read("幅 24\" モニタ,x\n");

            assertEquals(List.of("幅 24\" モニタ", "x"), rows.get(0).getValues());
        }

        @Test
        @DisplayName("空の値も 1 つの値として数える (行末のカンマを含む)")
        void keepsEmptyValues() throws Exception {
            List<CsvReader.Row> rows = CsvReader.read("a,,c,\n\"\",x\n");

            assertEquals(List.of("a", "", "c", ""), rows.get(0).getValues());
            assertEquals(List.of("", "x"), rows.get(1).getValues());
        }

        @Test
        @DisplayName("Csv で書き出したものを読み戻すと、元の値に戻る")
        void roundTripsWithCsvWriter() throws Exception {
            String[] values = {"E10003", "Brown, Emily", "幅 24\" モニタ", "1 行目\n2 行目", " 前後に空白 ", ""};
            String text = new Csv(',', "\r\n", true, false).row((Object[]) values).text();

            List<CsvReader.Row> rows = CsvReader.read(text);

            assertEquals(1, rows.size());
            assertEquals(List.of(values), rows.get(0).getValues());
        }
    }

    @Nested
    @DisplayName("行の分け方と行番号")
    class Rows {

        @Test
        @DisplayName("CRLF / LF / CR のどれでも 1 回の改行として扱う")
        void acceptsAnyNewline() throws Exception {
            List<CsvReader.Row> rows = CsvReader.read("a\r\nb\nc\rd");

            assertEquals(4, rows.size());
            assertEquals("d", rows.get(3).getValues().get(0));
        }

        @Test
        @DisplayName("末尾に改行があっても無くても、行の数は変わらない")
        void ignoresTrailingNewline() throws Exception {
            assertEquals(2, CsvReader.read("a\nb").size());
            assertEquals(2, CsvReader.read("a\nb\n").size());
            assertEquals(2, CsvReader.read("a\r\nb\r\n").size());
        }

        @Test
        @DisplayName("値の中の改行では行を分けない。行番号は Excel と同じくレコードの順番")
        void countsRecordsNotPhysicalLines() throws Exception {
            List<CsvReader.Row> rows = CsvReader.read("見出し\n\"1 行目\n2 行目\"\n次の行\n");

            assertEquals(3, rows.size());
            assertEquals("1 行目\n2 行目", rows.get(1).getValues().get(0));
            assertEquals(2, rows.get(1).getLineNumber());
            // テキストエディタでは 4 行目だが、レコードとしては 3 行目
            assertEquals(3, rows.get(2).getLineNumber());
        }

        @Test
        @DisplayName("空の文字列は 0 行")
        void emptyTextHasNoRows() throws Exception {
            assertTrue(CsvReader.read("").isEmpty());
        }

        @Test
        @DisplayName("値が空白だけの行・カンマだけの行は「空の行」")
        void detectsBlankRows() throws Exception {
            List<CsvReader.Row> rows = CsvReader.read("a,b\n,\n\n , 　\nx,\n");

            assertFalse(rows.get(0).isBlank());
            assertTrue(rows.get(1).isBlank(), "カンマだけ");
            assertTrue(rows.get(2).isBlank(), "改行だけ");
            assertTrue(rows.get(3).isBlank(), "空白だけ (全角スペースを含む)");
            assertFalse(rows.get(4).isBlank());
        }
    }

    @Nested
    @DisplayName("壊れた CSV")
    class Broken {

        @Test
        @DisplayName("閉じていない \" があると、その行番号つきで知らせる")
        void rejectsUnclosedQuote() {
            CsvReader.CsvFormatException e = assertThrows(CsvReader.CsvFormatException.class,
                    () -> CsvReader.read("見出し\nok\n\"閉じていない,x\n次の行\n"));

            assertEquals(3, e.getLineNumber());
            assertTrue(e.getMessage().contains("閉じられていません"), e.getMessage());
        }

        @Test
        @DisplayName("\" で閉じたあとに文字が続くと、その行番号つきで知らせる")
        void rejectsTextAfterClosingQuote() {
            CsvReader.CsvFormatException e = assertThrows(CsvReader.CsvFormatException.class,
                    () -> CsvReader.read("見出し\n\"幅 24\" モニタ,x\n"));

            assertEquals(2, e.getLineNumber());
        }
    }
}
