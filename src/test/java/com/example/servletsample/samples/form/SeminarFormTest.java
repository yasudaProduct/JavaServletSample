package com.example.servletsample.samples.form;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Constructor;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import com.example.servletsample.common.ValidationErrors;

/**
 * セミナー申込フォーム ({@link SeminarForm}) の入力チェックのテスト。
 *
 * <p>とくに確かめたいのは<b>「選択肢に無い値が送られてきたとき」</b>です。
 * プルダウンから選ばせていても、利用者は好きな値を送れます。
 * 「画面で選ばせたから安全」が成り立たないことを、テストでも押さえておきます。</p>
 */
class SeminarFormTest {

    /** 有効な参加日 (マスタの先頭)。 */
    private static final String VALID_DATE = SeminarForm.availableDates().get(0);

    /**
     * テスト用にフォームを組み立てる。
     *
     * <p>{@code SeminarForm} のコンストラクタは private です。
     * 本来は {@code HttpServletRequest} から作りますが、
     * コンテナを起動せずに検証だけを試したいので、ここだけリフレクションで作っています。</p>
     */
    private static SeminarForm form(String name, String company, String email,
                                    String attendDate, String headcount, String note) {
        try {
            Constructor<SeminarForm> constructor = SeminarForm.class.getDeclaredConstructor(
                    String.class, String.class, String.class,
                    String.class, String.class, String.class);
            constructor.setAccessible(true);
            return constructor.newInstance(name, company, email, attendDate, headcount, note);
        } catch (ReflectiveOperationException e) {
            throw new IllegalStateException(e);
        }
    }

    /** 全項目が正しいフォーム。 */
    private static SeminarForm valid() {
        return form("山田太郎", "株式会社サンプル", "taro@example.com", VALID_DATE, "2", "よろしくお願いします");
    }

    @Test
    @DisplayName("正しく入力されていればエラーにならない")
    void acceptsValidInput() {
        assertFalse(valid().validate().hasErrors());
    }

    @Test
    @DisplayName("任意項目は未入力でもよい")
    void optionalFieldsMayBeBlank() {
        assertFalse(form("山田太郎", "", "taro@example.com", VALID_DATE, "1", "").validate().hasErrors());
    }

    @Nested
    @DisplayName("氏名")
    class Name {

        @ParameterizedTest
        @NullAndEmptySource
        @ValueSource(strings = {"   ", "　"})
        @DisplayName("必須。全角スペースだけでも未入力とみなす")
        void required(String name) {
            ValidationErrors errors = form(name, "", "taro@example.com", VALID_DATE, "1", "").validate();
            assertTrue(errors.has("name"));
        }

        @Test
        @DisplayName("上限を超えるとエラー")
        void tooLong() {
            String name = "あ".repeat(SeminarForm.NAME_MAX_LENGTH + 1);
            assertTrue(form(name, "", "taro@example.com", VALID_DATE, "1", "").validate().has("name"));
        }

        @Test
        @DisplayName("ちょうど上限なら通る")
        void exactlyMaxLength() {
            String name = "あ".repeat(SeminarForm.NAME_MAX_LENGTH);
            assertFalse(form(name, "", "taro@example.com", VALID_DATE, "1", "").validate().has("name"));
        }
    }

    @Nested
    @DisplayName("メールアドレス")
    class Email {

        @ParameterizedTest
        @ValueSource(strings = {"taro", "taro@", "@example.com", "taro example@a.com", "taro@example"})
        @DisplayName("形式がおかしいとエラー")
        void invalidFormat(String email) {
            assertTrue(form("山田", "", email, VALID_DATE, "1", "").validate().has("email"));
        }

        @ParameterizedTest
        @ValueSource(strings = {"taro@example.com", "taro.yamada+tag@example.co.jp"})
        @DisplayName("よくある形式は通る")
        void validFormat(String email) {
            assertFalse(form("山田", "", email, VALID_DATE, "1", "").validate().has("email"));
        }
    }

    @Nested
    @DisplayName("参加日")
    class AttendDate {

        @ParameterizedTest
        @NullAndEmptySource
        @DisplayName("必須")
        void required(String date) {
            assertTrue(form("山田", "", "a@b.com", date, "1", "").validate().has("attendDate"));
        }

        @ParameterizedTest
        @ValueSource(strings = {"2026/10/15", "2026-10-32", "2026-02-30", "きょう"})
        @DisplayName("日付として読めないとエラー")
        void invalidDate(String date) {
            assertTrue(form("山田", "", "a@b.com", date, "1", "").validate().has("attendDate"));
        }

        @Test
        @DisplayName("日付として正しくても、選択肢に無ければエラー")
        void notInAvailableDates() {
            // プルダウンに無い値を送ってきた = 画面を通していない。
            // 「選択肢から選ばせたから安全」は成り立たない
            ValidationErrors errors = form("山田", "", "a@b.com", "2030-01-01", "1", "").validate();

            assertTrue(errors.has("attendDate"));
            assertEquals("選べない参加日です。", errors.get("attendDate"));
        }
    }

    @Nested
    @DisplayName("人数")
    class Headcount {

        @ParameterizedTest
        @NullAndEmptySource
        @DisplayName("必須")
        void required(String headcount) {
            assertTrue(form("山田", "", "a@b.com", VALID_DATE, headcount, "").validate().has("headcount"));
        }

        @ParameterizedTest
        @ValueSource(strings = {"ふたり", "２", "1.5", "1名", "99999999999999999999"})
        @DisplayName("半角数字でなければエラー (全角数字も通さない)")
        void mustBeHalfWidthDigits(String headcount) {
            assertTrue(form("山田", "", "a@b.com", VALID_DATE, headcount, "").validate().has("headcount"));
        }

        @ParameterizedTest
        @ValueSource(strings = {"0", "-1", "11", "100"})
        @DisplayName("範囲外はエラー")
        void outOfRange(String headcount) {
            assertTrue(form("山田", "", "a@b.com", VALID_DATE, headcount, "").validate().has("headcount"));
        }

        @ParameterizedTest
        @ValueSource(strings = {"1", "5", "10"})
        @DisplayName("範囲内なら通る")
        void inRange(String headcount) {
            assertFalse(form("山田", "", "a@b.com", VALID_DATE, headcount, "").validate().has("headcount"));
        }
    }

    @Nested
    @DisplayName("確認画面に出す値")
    class Display {

        @Test
        @DisplayName("参加日は画面向けの形に整える")
        void formatsAttendDate() {
            assertEquals("2026/10/15",
                    form("山田", "", "a@b.com", "2026-10-15", "1", "").getAttendDateText());
        }

        @Test
        @DisplayName("読めない日付は、入力されたまま返す (画面で気付けるように)")
        void keepsUnparseableDateAsIs() {
            assertEquals("きょう",
                    form("山田", "", "a@b.com", "きょう", "1", "").getAttendDateText());
        }

        @Test
        @DisplayName("人数は数値で取り出せる")
        void headcountAsNumber() {
            assertEquals(3, form("山田", "", "a@b.com", VALID_DATE, "3", "").getHeadcountValue());
            assertEquals(0, form("山田", "", "a@b.com", VALID_DATE, "あ", "").getHeadcountValue());
        }
    }

    @Nested
    @DisplayName("値の持ち回り方")
    class Carry {

        @Test
        @DisplayName("session と書かれたときだけセッション方式")
        void onlySessionMeansSession() {
            assertTrue(ConfirmFormServlet.isSessionCarry("session"));
            assertFalse(ConfirmFormServlet.isSessionCarry("hidden"));
            assertFalse(ConfirmFormServlet.isSessionCarry(""));
            assertFalse(ConfirmFormServlet.isSessionCarry(null));
        }
    }
}
