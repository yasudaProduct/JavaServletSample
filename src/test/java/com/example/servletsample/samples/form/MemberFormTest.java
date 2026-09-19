package com.example.servletsample.samples.form;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import com.example.servletsample.common.ValidationErrors;

/**
 * 会員登録フォームの入力チェック ({@link MemberForm#validate()}) のテスト。
 *
 * <p>入力チェックはバグが目に見えにくい場所です
 * (「1 文字多くても通ってしまう」のは画面を見ても気づけません)。
 * そのため<b>境界値</b>、つまり「ちょうど通る値」と「1 つだけ外れた値」を
 * 並べて確かめています。</p>
 *
 * <p>{@link MemberForm} は Servlet API に依存していないので、
 * Tomcat を起動せずにそのまま呼べます。
 * {@link MemberForm#from(HttpServletRequest)} のテストだけは
 * {@code HttpServletRequest} が要るため、動的プロキシで最小限のものを作っています
 * (見本: {@code common/FlashTest.java})。</p>
 */
class MemberFormTest {

    // ------------------------------------------------------------------
    // 組み立ての補助 : 調べたい項目以外は「正しい値」で埋める
    // ------------------------------------------------------------------

    /** すべて正しい入力。 */
    private static MemberForm validForm() {
        return MemberForm.of("山田太郎", "taro@example.com", "30", "123-4567",
                "pass1234", "pass1234", true);
    }

    private static ValidationErrors withName(String name) {
        return MemberForm.of(name, "taro@example.com", "30", "123-4567",
                "pass1234", "pass1234", true).validate();
    }

    private static ValidationErrors withEmail(String email) {
        return MemberForm.of("山田太郎", email, "30", "123-4567",
                "pass1234", "pass1234", true).validate();
    }

    private static ValidationErrors withAge(String age) {
        return MemberForm.of("山田太郎", "taro@example.com", age, "123-4567",
                "pass1234", "pass1234", true).validate();
    }

    private static ValidationErrors withZipCode(String zipCode) {
        return MemberForm.of("山田太郎", "taro@example.com", "30", zipCode,
                "pass1234", "pass1234", true).validate();
    }

    private static ValidationErrors withPasswords(String password, String passwordConfirm) {
        return MemberForm.of("山田太郎", "taro@example.com", "30", "123-4567",
                password, passwordConfirm, true).validate();
    }

    /** 同じ文字を n 個並べた文字列。 */
    private static String repeat(String unit, int count) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < count; i++) {
            builder.append(unit);
        }
        return builder.toString();
    }

    // ------------------------------------------------------------------

    @Test
    @DisplayName("すべて正しければエラーは 0 件")
    void acceptsValidInput() {
        ValidationErrors errors = validForm().validate();
        assertFalse(errors.hasErrors(), "エラー: " + errors.getMessages());
        assertEquals(0, errors.getCount());
    }

    @Test
    @DisplayName("任意項目 (年齢・郵便番号) は空でも通る")
    void allowsEmptyOptionalFields() {
        ValidationErrors errors = MemberForm.of("山田太郎", "taro@example.com", "", "",
                "pass1234", "pass1234", true).validate();
        assertFalse(errors.hasErrors(), "エラー: " + errors.getMessages());
    }

    @Test
    @DisplayName("空のフォームでは必須項目だけがエラーになる (氏名・メール・パスワード・同意)")
    void reportsOnlyRequiredErrorsForEmptyForm() {
        ValidationErrors errors = MemberForm.empty().validate();

        assertTrue(errors.has("name"));
        assertTrue(errors.has("email"));
        assertTrue(errors.has("password"));
        assertTrue(errors.has("agree"));
        assertFalse(errors.has("age"), "年齢は任意なのでエラーにしない");
        assertFalse(errors.has("zipCode"), "郵便番号は任意なのでエラーにしない");
        assertFalse(errors.has("passwordConfirm"),
                "パスワード側が未入力のときに「一致しません」まで出すと直し方が分からなくなる");
        assertEquals(4, errors.getCount());
    }

    // ------------------------------------------------------------------
    @Nested
    @DisplayName("氏名 : 必須 / 50 文字以内")
    class Name {

        @Test
        @DisplayName("0 文字はエラー")
        void rejectsEmpty() {
            ValidationErrors errors = withName("");
            assertTrue(errors.has("name"));
            assertEquals("氏名を入力してください。", errors.get("name"));
        }

        @Test
        @DisplayName("空白だけの入力もエラー")
        void rejectsWhitespaceOnly() {
            assertTrue(withName("      ").has("name"),
                    "前後の空白を落としてから判定しないと「入力あり」になってしまいます");
        }

        @Test
        @DisplayName("全角スペースだけの入力もエラー (trim では落とせない)")
        void rejectsFullWidthSpaceOnly() {
            // String.trim() が削るのは U+0020 以下だけなので、全角スペース (U+3000) は残ります。
            // strip() は Unicode の空白判定を使うので落とせます。
            assertEquals("\u3000", "\u3000".trim(), "前提: trim では全角スペースが残る");
            assertEquals("", "\u3000".strip(), "前提: strip なら落ちる");
            assertTrue(withName("\u3000\u3000").has("name"));
        }

        @Test
        @DisplayName("前後の空白は取り除かれるので、中身があれば通る")
        void trimsSurroundingSpaces() {
            MemberForm form = MemberForm.of("  山田太郎  ", "taro@example.com", "30", "",
                    "pass1234", "pass1234", true);
            assertFalse(form.validate().hasErrors());
            assertEquals("山田太郎", form.getName(), "空白を落とした値が画面に戻る");
        }

        @Test
        @DisplayName("50 文字ちょうどは通る")
        void acceptsExactly50() {
            assertFalse(withName(repeat("あ", 50)).has("name"));
        }

        @Test
        @DisplayName("51 文字はエラー")
        void rejects51() {
            ValidationErrors errors = withName(repeat("あ", 51));
            assertTrue(errors.has("name"));
            assertTrue(errors.get("name").contains("51 文字"),
                    "何文字打ったのかが分かるメッセージにする: " + errors.get("name"));
        }

        @Test
        @DisplayName("サロゲートペアの文字は 1 文字として数える")
        void countsSurrogatePairAsOneCharacter() {
            // 「𠮟」は UTF-16 では 2 単位。String.length() で数えると 25 文字で溢れてしまう
            String name = repeat("𠮟", 50);
            assertEquals(100, name.length(), "前提: UTF-16 では 100 単位");
            assertFalse(withName(name).has("name"), "codePointCount で数えていれば 50 文字ちょうど");
            assertTrue(withName(name + "𠮟").has("name"), "51 文字目からはエラー");
        }
    }

    // ------------------------------------------------------------------
    @Nested
    @DisplayName("メールアドレス : 必須 / 形式")
    class Email {

        @Test
        @DisplayName("未入力はエラー")
        void rejectsEmpty() {
            assertEquals("メールアドレスを入力してください。", withEmail("").get("email"));
        }

        @Test
        @DisplayName("ふつうのアドレスは通る")
        void acceptsTypicalAddresses() {
            assertFalse(withEmail("taro@example.com").has("email"));
            assertFalse(withEmail("taro.yamada+news@mail.example.co.jp").has("email"));
        }

        @Test
        @DisplayName("@ が無い / ドメインにドットが無い / 空白が入るとエラー")
        void rejectsBrokenAddresses() {
            assertTrue(withEmail("taro.example.com").has("email"), "@ が無い");
            assertTrue(withEmail("taro@example").has("email"), "ドメインにドットが無い");
            assertTrue(withEmail("taro @example.com").has("email"), "空白が入っている");
            assertTrue(withEmail("@example.com").has("email"), "@ の前が無い");
            assertTrue(withEmail("taro@").has("email"), "@ の後ろが無い");
        }

        @Test
        @DisplayName("形式が正しくても「実在する」わけではない (そこまでは見ない)")
        void acceptsAddressThatMayNotExist() {
            // 届くかどうかは確認メールでしか分かりません。
            // 正規表現を厳しくしても実在チェックにはならないので、ここは緩くしています。
            assertFalse(withEmail("dare-mo-inai@example.com").has("email"));
        }
    }

    // ------------------------------------------------------------------
    @Nested
    @DisplayName("年齢 : 任意 / 数字 / 0 〜 120")
    class Age {

        @Test
        @DisplayName("未入力は通る (任意項目)")
        void allowsEmpty() {
            assertFalse(withAge("").has("age"));
        }

        @Test
        @DisplayName("-1 は範囲外でエラー")
        void rejectsMinus1() {
            ValidationErrors errors = withAge("-1");
            assertTrue(errors.has("age"));
            assertEquals("年齢は 0 から 120 の範囲で入力してください。", errors.get("age"),
                    "符号付きの数字は「形式」ではなく「範囲」で弾くほうが直し方が分かる");
        }

        @Test
        @DisplayName("0 は通る (下限ちょうど)")
        void acceptsZero() {
            assertFalse(withAge("0").has("age"));
        }

        @Test
        @DisplayName("120 は通る (上限ちょうど)")
        void accepts120() {
            assertFalse(withAge("120").has("age"));
        }

        @Test
        @DisplayName("121 は範囲外でエラー")
        void rejects121() {
            assertTrue(withAge("121").has("age"));
        }

        @Test
        @DisplayName("数字でなければエラー")
        void rejectsNonNumeric() {
            assertEquals("年齢は半角数字で入力してください。(例: 30)", withAge("三十").get("age"));
            assertTrue(withAge("30歳").has("age"));
            assertTrue(withAge("1.5").has("age"));
        }

        @Test
        @DisplayName("全角数字はエラー (Integer.parseInt は通してしまう)")
        void rejectsFullWidthDigits() {
            // Integer.parseInt("２０") は 20 を返します。
            // 形を先に見ていないと、画面の表示と保存した値がずれます。
            assertEquals(20, Integer.parseInt("２０"), "前提: parseInt は全角数字を受け付ける");
            assertTrue(withAge("２０").has("age"));
        }

        @Test
        @DisplayName("int に収まらない桁数でも落ちない")
        void survivesOverflow() {
            ValidationErrors errors = withAge("99999999999999999999");
            assertTrue(errors.has("age"), "NumberFormatException を投げずにエラーとして扱う");
        }

        @Test
        @DisplayName("チェックを通った値は数値としても取り出せる")
        void exposesNumericValue() {
            MemberForm form = MemberForm.of("山田太郎", "taro@example.com", "007", "",
                    "pass1234", "pass1234", true);
            assertFalse(form.validate().hasErrors());
            assertEquals(7, form.getAgeValue(), "数値としては 7");
            assertEquals("007", form.getAge(), "画面に戻すのは打たれたままの文字列");
        }
    }

    // ------------------------------------------------------------------
    @Nested
    @DisplayName("郵便番号 : 任意 / 7 桁 (ハイフンあり・なし)")
    class ZipCode {

        @Test
        @DisplayName("未入力は通る (任意項目)")
        void allowsEmpty() {
            assertFalse(withZipCode("").has("zipCode"));
        }

        @Test
        @DisplayName("ハイフン無しの 7 桁は通る")
        void accepts7Digits() {
            assertFalse(withZipCode("1234567").has("zipCode"));
        }

        @Test
        @DisplayName("ハイフンありの 3-4 桁は通る")
        void acceptsHyphenated() {
            assertFalse(withZipCode("123-4567").has("zipCode"));
        }

        @Test
        @DisplayName("6 桁・8 桁はエラー")
        void rejectsWrongLength() {
            assertTrue(withZipCode("123456").has("zipCode"));
            assertTrue(withZipCode("12345678").has("zipCode"));
        }

        @Test
        @DisplayName("ハイフンの位置が違うとエラー")
        void rejectsWrongHyphenPosition() {
            assertTrue(withZipCode("1234-567").has("zipCode"));
            assertTrue(withZipCode("-1234567").has("zipCode"));
        }

        @Test
        @DisplayName("ハイフンを取り除いた 7 桁を取り出せる")
        void normalizesToDigits() {
            MemberForm form = MemberForm.of("山田太郎", "taro@example.com", "30", "123-4567",
                    "pass1234", "pass1234", true);
            assertEquals("1234567", form.getZipCodeDigits());
            assertEquals("123-4567", form.getZipCode(), "画面に戻すのは打たれたまま");
        }
    }

    // ------------------------------------------------------------------
    @Nested
    @DisplayName("パスワード : 必須 / 8 文字以上 / 英字と数字")
    class Password {

        @Test
        @DisplayName("未入力はエラー")
        void rejectsEmpty() {
            assertEquals("パスワードを入力してください。", withPasswords("", "").get("password"));
        }

        @Test
        @DisplayName("7 文字はエラー、8 文字ちょうどは通る")
        void checksLengthBoundary() {
            assertTrue(withPasswords("pass123", "pass123").has("password"), "7 文字");
            assertFalse(withPasswords("pass1234", "pass1234").has("password"), "8 文字ちょうど");
        }

        @Test
        @DisplayName("英字だけ / 数字だけはエラー")
        void requiresLetterAndDigit() {
            assertEquals("パスワードには英字と数字を両方含めてください。",
                    withPasswords("password", "password").get("password"));
            assertTrue(withPasswords("12345678", "12345678").has("password"));
        }

        @Test
        @DisplayName("記号が混ざっていても、英字と数字があれば通る")
        void allowsSymbols() {
            assertFalse(withPasswords("p@ss-123", "p@ss-123").has("password"));
        }

        @Test
        @DisplayName("1 項目につきメッセージは 1 つ (短くて種類も足りない場合は長さだけ言う)")
        void reportsOneMessagePerField() {
            ValidationErrors errors = withPasswords("abc", "abc");
            assertEquals("パスワードは 8 文字以上で入力してください。", errors.get("password"));
        }

        @Test
        @DisplayName("パスワードの空白は落とさない (空白も文字として数える)")
        void doesNotTrimPassword() {
            // 「 pass123」(先頭に空白) は 8 文字。空白を削ると 7 文字とみなされて弾かれる
            assertFalse(withPasswords(" pass123", " pass123").has("password"),
                    "パスワードの空白まで削ると、登録できたはずの値が通らなくなります");
            assertTrue(withPasswords(" pass123", "pass123").has("passwordConfirm"),
                    "空白の有無で一致しなくなることも確かめる");
        }
    }

    // ------------------------------------------------------------------
    @Nested
    @DisplayName("パスワード (確認) : 相関チェック")
    class PasswordConfirm {

        @Test
        @DisplayName("一致していれば通る")
        void acceptsMatching() {
            assertFalse(withPasswords("pass1234", "pass1234").has("passwordConfirm"));
        }

        @Test
        @DisplayName("違っていればエラー")
        void rejectsMismatch() {
            ValidationErrors errors = withPasswords("pass1234", "pass12345");
            assertEquals("パスワードが一致しません。もう一度入力してください。",
                    errors.get("passwordConfirm"));
            assertFalse(errors.has("password"), "エラーを付けるのは確認欄の側だけ");
        }

        @Test
        @DisplayName("大文字・小文字が違えばエラー")
        void isCaseSensitive() {
            assertTrue(withPasswords("pass1234", "PASS1234").has("passwordConfirm"));
        }

        @Test
        @DisplayName("確認欄だけ未入力ならエラー")
        void rejectsEmptyConfirm() {
            assertEquals("確認のため、パスワードをもう一度入力してください。",
                    withPasswords("pass1234", "").get("passwordConfirm"));
        }

        @Test
        @DisplayName("パスワード側がエラーのときは、一致の判定はしない")
        void skipsWhenPasswordItselfIsInvalid() {
            // 「8 文字以上にしてください」と「一致しません」が並ぶと、どちらを直せばよいか迷います
            ValidationErrors errors = withPasswords("abc", "xyz");
            assertTrue(errors.has("password"));
            assertFalse(errors.has("passwordConfirm"), "相関チェックは各項目が妥当になってから");
        }
    }

    // ------------------------------------------------------------------
    @Nested
    @DisplayName("利用規約への同意 : 必須")
    class Agreement {

        @Test
        @DisplayName("チェックが無ければエラー")
        void requiresAgreement() {
            ValidationErrors errors = MemberForm.of("山田太郎", "taro@example.com", "30", "",
                    "pass1234", "pass1234", false).validate();
            assertEquals("利用規約に同意していただく必要があります。", errors.get("agree"));
        }

        @Test
        @DisplayName("チェックがあれば通る")
        void acceptsAgreement() {
            assertFalse(validForm().validate().has("agree"));
        }
    }

    // ------------------------------------------------------------------
    @Nested
    @DisplayName("リクエストからの受け取り")
    class FromRequest {

        @Test
        @DisplayName("パラメータをそのまま受け取る (文字列は空白を落とし、パスワードはそのまま)")
        void readsParameters() {
            Map<String, String> parameters = new HashMap<>();
            parameters.put("name", "  山田太郎  ");
            parameters.put("email", " taro@example.com ");
            parameters.put("age", " 30 ");
            parameters.put("zipCode", " 123-4567 ");
            parameters.put("password", " pass1234 ");
            parameters.put("passwordConfirm", " pass1234 ");
            parameters.put("agree", "on");

            MemberForm form = MemberForm.from(fakeRequest(parameters));

            assertEquals("山田太郎", form.getName());
            assertEquals("taro@example.com", form.getEmail());
            assertEquals("30", form.getAge());
            assertEquals("123-4567", form.getZipCode());
            assertTrue(form.isAgreed());
            assertFalse(form.validate().hasErrors(),
                    "パスワードの空白は残るが、確認欄と同じなので一致する");
        }

        @Test
        @DisplayName("チェックボックスは、チェックしないとパラメータ自体が届かない")
        void treatsMissingCheckboxAsUnchecked() {
            Map<String, String> parameters = new HashMap<>();
            parameters.put("name", "山田太郎");
            parameters.put("email", "taro@example.com");
            parameters.put("password", "pass1234");
            parameters.put("passwordConfirm", "pass1234");
            // "agree" は入れない (= チェックしなかった状態)

            MemberForm form = MemberForm.from(fakeRequest(parameters));

            assertFalse(form.isAgreed());
            assertTrue(form.validate().has("agree"));
        }

        @Test
        @DisplayName("パラメータが 1 つも無くても落ちない (curl で空の POST をされた場合)")
        void survivesEmptyPost() {
            MemberForm form = MemberForm.from(fakeRequest(new HashMap<>()));

            ValidationErrors errors = form.validate();
            assertTrue(errors.hasErrors(), "必須項目のエラーとして返る (例外にはしない)");
            assertEquals("", form.getName(), "null ではなく空文字にしておくと JSP 側が楽");
        }

        @Test
        @DisplayName("パスワードは toString に出さない (ログに残さないため)")
        void hidesPasswordFromToString() {
            String text = validForm().toString();
            assertFalse(text.contains("pass1234"), "ログに出る文字列にパスワードを含めない: " + text);
        }

        /**
         * テスト用の最小限の {@link HttpServletRequest}。
         *
         * <p>モックライブラリを足さずに済ませるため、動的プロキシで
         * {@code getParameter} だけを実装しています (見本: {@code common/FlashTest.java})。</p>
         */
        private HttpServletRequest fakeRequest(Map<String, String> parameters) {
            InvocationHandler handler = (target, method, args) -> {
                if ("getParameter".equals(method.getName())) {
                    // 送られていないパラメータは null が返る、という本物の挙動に合わせる
                    return parameters.get((String) args[0]);
                }
                return null;
            };
            return (HttpServletRequest) Proxy.newProxyInstance(
                    MemberFormTest.class.getClassLoader(),
                    new Class<?>[]{HttpServletRequest.class}, handler);
        }
    }
}
