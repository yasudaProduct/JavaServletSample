package com.example.servletsample.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import java.util.Optional;
import java.util.OptionalInt;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * 入力チェックの部品 ({@link Validators}) のテスト。
 *
 * <p>ここで確かめているのは「判定そのもの」です。
 * 全角スペース・全角数字・半角カタカナ・存在しない日付といった、
 * <b>うっかり通してしまいがちな値</b>を並べてあります。</p>
 */
class ValidatorsTest {

    @Nested
    @DisplayName("isBlank (必須チェック)")
    class IsBlank {

        @Test
        @DisplayName("null と空文字は未入力")
        void nullAndEmpty() {
            assertTrue(Validators.isBlank(null));
            assertTrue(Validators.isBlank(""));
        }

        @Test
        @DisplayName("半角スペースだけは未入力")
        void halfWidthSpace() {
            assertTrue(Validators.isBlank("   "));
        }

        @Test
        @DisplayName("全角スペースだけも未入力 (trim では落とせない)")
        void fullWidthSpace() {
            assertTrue(Validators.isBlank("　　"));
            // trim() だと全角スペースが残るため「入力あり」になってしまう
            assertFalse("　　".trim().isEmpty());
        }

        @Test
        @DisplayName("文字が 1 つでもあれば入力あり")
        void present() {
            assertFalse(Validators.isBlank(" あ "));
            assertTrue(Validators.isPresent(" あ "));
        }
    }

    @Nested
    @DisplayName("文字種チェック")
    class CharacterTypes {

        @Test
        @DisplayName("半角英数字だけを通す")
        void halfWidthAlphanumeric() {
            assertTrue(Validators.isHalfWidthAlphanumeric("E1001"));
            assertTrue(Validators.isHalfWidthAlphanumeric("abc123"));

            assertFalse(Validators.isHalfWidthAlphanumeric("Ｅ１００１"), "全角は通さない");
            assertFalse(Validators.isHalfWidthAlphanumeric("E-100"), "記号は通さない");
            assertFalse(Validators.isHalfWidthAlphanumeric("E 100"), "空白は通さない");
            assertFalse(Validators.isHalfWidthAlphanumeric(""), "空文字は通さない");
            assertFalse(Validators.isHalfWidthAlphanumeric(null));
        }

        @Test
        @DisplayName("半角数字だけを通す (全角数字は弾く)")
        void halfWidthDigits() {
            assertTrue(Validators.isHalfWidthDigits("20"));
            assertFalse(Validators.isHalfWidthDigits("２０"));
        }

        @Test
        @DisplayName("全角カタカナだけを通す")
        void fullWidthKatakana() {
            assertTrue(Validators.isFullWidthKatakana("ヤマダ"));
            assertTrue(Validators.isFullWidthKatakana("ヤマダ タロウ"), "半角スペースは許す");
            assertTrue(Validators.isFullWidthKatakana("ヤマダ　タロウ"), "全角スペースは許す");
            assertTrue(Validators.isFullWidthKatakana("サン・テグジュペリ"), "中点は許す");
            assertTrue(Validators.isFullWidthKatakana("ソーダ"), "長音は許す");

            assertFalse(Validators.isFullWidthKatakana("やまだ"), "ひらがなは通さない");
            assertFalse(Validators.isFullWidthKatakana("山田"), "漢字は通さない");
            assertFalse(Validators.isFullWidthKatakana("ﾔﾏﾀﾞ"), "半角カタカナは通さない");
            assertFalse(Validators.isFullWidthKatakana("ヤマダ1"), "数字が混ざれば通さない");
        }
    }

    @Nested
    @DisplayName("桁数チェック")
    class Length {

        @Test
        @DisplayName("人が数えた文字数で数える (サロゲートペアは 1 文字)")
        void countsCodePoints() {
            assertEquals(3, Validators.length("あいう"));
            // 𠮟 は UTF-16 では 2 単位。String.length() だと 2 になる
            assertEquals(1, Validators.length("𠮟"));
            assertEquals(2, "𠮟".length());
            assertEquals(0, Validators.length(null));
        }

        @Test
        @DisplayName("上限ちょうどは通り、1 文字超えると通らない")
        void atMost() {
            assertTrue(Validators.isLengthAtMost("あいうえお", 5));
            assertFalse(Validators.isLengthAtMost("あいうえおか", 5));
        }

        @Test
        @DisplayName("固定長はちょうどのときだけ通る")
        void exactly() {
            assertTrue(Validators.isLengthExactly("E1001", 5));
            assertFalse(Validators.isLengthExactly("E100", 5));
            assertFalse(Validators.isLengthExactly("E10011", 5));
        }
    }

    @Nested
    @DisplayName("toInt (数値への変換)")
    class ToInt {

        @Test
        @DisplayName("半角数字は変換できる")
        void halfWidth() {
            assertEquals(OptionalInt.of(20), Validators.toInt("20"));
            assertEquals(OptionalInt.of(-5), Validators.toInt("-5"));
            assertEquals(OptionalInt.of(7), Validators.toInt(" 7 "), "前後の空白は落とす");
        }

        @Test
        @DisplayName("全角数字は変換しない (parseInt は通してしまう)")
        void fullWidthIsRejected() {
            assertEquals(OptionalInt.empty(), Validators.toInt("２０"));
            // 比較用 : parseInt は全角数字を 20 として受け付けてしまう
            assertEquals(20, Integer.parseInt("２０"));
        }

        @Test
        @DisplayName("数字でないもの・桁あふれは空を返す")
        void invalid() {
            assertEquals(OptionalInt.empty(), Validators.toInt("abc"));
            assertEquals(OptionalInt.empty(), Validators.toInt("1e3"));
            assertEquals(OptionalInt.empty(), Validators.toInt(""));
            assertEquals(OptionalInt.empty(), Validators.toInt(null));
            assertEquals(OptionalInt.empty(), Validators.toInt("99999999999999999999"));
        }
    }

    @Nested
    @DisplayName("toDate (日付への変換)")
    class ToDate {

        @Test
        @DisplayName("uuuu-MM-dd の実在する日付は変換できる")
        void valid() {
            assertEquals(Optional.of(LocalDate.of(2026, 4, 1)), Validators.toDate("2026-04-01"));
            assertEquals(Optional.of(LocalDate.of(2024, 2, 29)), Validators.toDate("2024-02-29"),
                    "うるう年の 2 月 29 日は存在する");
        }

        @Test
        @DisplayName("存在しない日付は空を返す (丸めない)")
        void notExisting() {
            assertEquals(Optional.empty(), Validators.toDate("2026-02-30"));
            assertEquals(Optional.empty(), Validators.toDate("2026-13-01"));
            assertEquals(Optional.empty(), Validators.toDate("2025-02-29"), "うるう年ではない");
        }

        @Test
        @DisplayName("形式が違うものは空を返す")
        void wrongFormat() {
            assertEquals(Optional.empty(), Validators.toDate("2026/04/01"));
            assertEquals(Optional.empty(), Validators.toDate("2026-4-1"));
            assertEquals(Optional.empty(), Validators.toDate("20260401"));
            assertEquals(Optional.empty(), Validators.toDate(""));
            assertEquals(Optional.empty(), Validators.toDate(null));
        }

        @Test
        @DisplayName("日付を文字列に戻せる")
        void format() {
            assertEquals("2026-04-01", Validators.formatDate(LocalDate.of(2026, 4, 1)));
            assertEquals("", Validators.formatDate(null));
        }
    }

    @Nested
    @DisplayName("文字列の整え方")
    class Normalize {

        @Test
        @DisplayName("strip は null を空文字にする")
        void strip() {
            assertEquals("", Validators.strip(null));
            assertEquals("あ", Validators.strip(" あ "));
            assertEquals("あ", Validators.strip("　あ　"), "全角スペースも落とす");
        }

        @Test
        @DisplayName("改行コードを \\n に揃える")
        void newlines() {
            assertEquals("a\nb", Validators.normalizeNewlines("a\r\nb"));
            assertEquals("a\nb", Validators.normalizeNewlines("a\rb"));
            assertEquals("", Validators.normalizeNewlines(null));
            // \r\n のままだと 1 文字多く数えてしまう
            assertEquals(3, Validators.length(Validators.normalizeNewlines("a\r\nb")));
        }
    }
}
