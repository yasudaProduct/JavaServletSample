package com.example.servletsample.samples.form;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.samples.form.RealtimeValidationServlet.ContactForm;

/**
 * 問い合わせフォームの入力チェック ({@link ContactForm#validate()}) のテスト。
 *
 * <p>このサンプルは画面側 (JavaScript) でも同じチェックをしていますが、
 * <b>守っているのはこちら側</b>なので、テストもこちらに書きます。
 * 確かめるのは<b>境界値</b>、つまり「ちょうど通る値」と「1 つだけ外れた値」です。</p>
 *
 * <p>{@link ContactForm} は Servlet API に依存していないため、
 * Tomcat を起動せずにそのまま呼べます。</p>
 */
class RealtimeValidationServletTest {

    // ------------------------------------------------------------------
    // 組み立ての補助 : 調べたい項目以外は「正しい値」で埋める
    // ------------------------------------------------------------------

    private static ValidationErrors withName(String name) {
        return ContactForm.of(name, "taro@example.com", "090-1234-5678", "相談したいことがあります。")
                .validate();
    }

    private static ValidationErrors withEmail(String email) {
        return ContactForm.of("山田太郎", email, "090-1234-5678", "相談したいことがあります。")
                .validate();
    }

    private static ValidationErrors withTel(String tel) {
        return ContactForm.of("山田太郎", "taro@example.com", tel, "相談したいことがあります。")
                .validate();
    }

    private static ValidationErrors withMessage(String message) {
        return ContactForm.of("山田太郎", "taro@example.com", "090-1234-5678", message)
                .validate();
    }

    /** 同じ文字を n 個つないだ文字列。 */
    private static String repeat(String unit, int count) {
        return unit.repeat(count);
    }

    @Test
    @DisplayName("すべて正しければエラーは 0 件")
    void acceptsValidForm() {
        ValidationErrors errors = ContactForm
                .of("山田太郎", "taro@example.com", "09012345678", "資料を送ってください。")
                .validate();
        assertFalse(errors.hasErrors());
        assertEquals(0, errors.getCount());
    }

    @Nested
    @DisplayName("お名前")
    class Name {

        @Test
        @DisplayName("未入力はエラー")
        void rejectsEmpty() {
            assertTrue(withName("").has("name"));
        }

        @Test
        @DisplayName("全角スペースだけの入力もエラー (strip で落とすため)")
        void rejectsWideSpaceOnly() {
            assertTrue(withName("　　").has("name"));
        }

        @Test
        @DisplayName("30 文字ちょうどは通る")
        void acceptsExactlyMax() {
            assertFalse(withName(repeat("あ", ContactForm.NAME_MAX_LENGTH)).has("name"));
        }

        @Test
        @DisplayName("31 文字はエラー")
        void rejectsOverMax() {
            assertTrue(withName(repeat("あ", ContactForm.NAME_MAX_LENGTH + 1)).has("name"));
        }

        @Test
        @DisplayName("サロゲートペアは 1 文字として数える")
        void countsSurrogatePairAsOne() {
            // "𠮟" は char 2 つ分。length() で数えると 15 文字で上限を超えてしまう
            assertFalse(withName(repeat("𠮟", ContactForm.NAME_MAX_LENGTH)).has("name"));
        }
    }

    @Nested
    @DisplayName("メールアドレス")
    class Email {

        @Test
        @DisplayName("未入力はエラー")
        void rejectsEmpty() {
            assertTrue(withEmail("").has("email"));
        }

        @Test
        @DisplayName("@ が無いとエラー")
        void rejectsWithoutAtMark() {
            assertTrue(withEmail("taro.example.com").has("email"));
        }

        @Test
        @DisplayName("ドメインにドットが無いとエラー")
        void rejectsWithoutDot() {
            assertTrue(withEmail("taro@example").has("email"));
        }

        @Test
        @DisplayName("+ 付きのエイリアスは通る")
        void acceptsPlusAlias() {
            assertFalse(withEmail("taro+news@example.co.jp").has("email"));
        }
    }

    @Nested
    @DisplayName("電話番号 (任意項目)")
    class Tel {

        @Test
        @DisplayName("未入力はエラーにしない")
        void allowsEmpty() {
            assertFalse(withTel("").has("tel"));
        }

        @Test
        @DisplayName("ハイフン無しの 11 桁は通る")
        void acceptsDigitsOnly() {
            assertFalse(withTel("09012345678").has("tel"));
        }

        @Test
        @DisplayName("ハイフン有りは通る")
        void acceptsHyphenated() {
            assertFalse(withTel("03-1234-5678").has("tel"));
        }

        @Test
        @DisplayName("全角数字はエラー")
        void rejectsWideDigits() {
            assertTrue(withTel("０９０１２３４５６７８").has("tel"));
        }

        @Test
        @DisplayName("0 で始まらないとエラー")
        void rejectsNotStartingWithZero() {
            assertTrue(withTel("9012345678").has("tel"));
        }
    }

    @Nested
    @DisplayName("お問い合わせ内容")
    class Message {

        @Test
        @DisplayName("未入力はエラー")
        void rejectsEmpty() {
            assertTrue(withMessage("").has("message"));
        }

        @Test
        @DisplayName("200 文字ちょうどは通る")
        void acceptsExactlyMax() {
            assertFalse(withMessage(repeat("あ", ContactForm.MESSAGE_MAX_LENGTH)).has("message"));
        }

        @Test
        @DisplayName("201 文字はエラー")
        void rejectsOverMax() {
            assertTrue(withMessage(repeat("あ", ContactForm.MESSAGE_MAX_LENGTH + 1)).has("message"));
        }

        @Test
        @DisplayName("CRLF の改行は 1 文字として数える (画面の文字数カウンタと揃えるため)")
        void countsCrlfAsOneCharacter() {
            // textarea の中身は送信されるときに改行が CRLF になる。
            // そのまま数えると画面のカウンタより多くなり、
            // 「画面では残り 0 文字なのにサーバではエラー」という食い違いが起きる
            ContactForm form = ContactForm.of("山田太郎", "taro@example.com", "", "あ\r\nい\r\nう");
            assertEquals(5, form.getMessageLength());
        }

        @Test
        @DisplayName("改行を含めて 200 文字ちょうどなら通る")
        void acceptsExactlyMaxWithNewlines() {
            // 「あ + 改行」を 99 行 (198 文字) + 末尾の 2 文字 = 200 文字。
            // 末尾を文字で終わらせているのは、strip() で改行が落ちないようにするため
            String text = repeat("あ\r\n", 99) + "ああ";
            assertEquals(ContactForm.MESSAGE_MAX_LENGTH,
                    ContactForm.of("山田太郎", "taro@example.com", "", text).getMessageLength());
            assertFalse(withMessage(text).has("message"));
        }
    }
}
