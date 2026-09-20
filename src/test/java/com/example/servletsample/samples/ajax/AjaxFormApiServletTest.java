package com.example.servletsample.samples.ajax;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.samples.ajax.AjaxFormApiServlet.DuplicateGuard;
import com.example.servletsample.samples.ajax.AjaxFormApiServlet.InquiryForm;

/**
 * Ajax で送られてきたフォームを受け取る API ({@link AjaxFormApiServlet}) のテスト。
 *
 * <p>Servlet コンテナは起動しません。入力チェックも JSON の組み立ても
 * {@code HttpServletRequest} を使わない形に分けてあるので、{@code new} して直接呼べます。</p>
 *
 * <p>とくに念入りに確かめているのは<b>セレクトボックスの値</b>です。
 * この API は URL さえ分かれば画面を通さずに叩けるので、
 * 「画面に並べた選択肢しか送られてこない」という前提は成り立ちません。</p>
 */
class AjaxFormApiServletTest {

    /** 検証を通る入力 (これを 1 項目ずつ崩して試す)。 */
    private static InquiryForm validForm() {
        return InquiryForm.of("山田 太郎", "taro@example.com", "question", "使い方を教えてください。");
    }

    /** 指定した文字を繰り返した文字列。 */
    private static String repeat(String unit, int times) {
        return unit.repeat(times);
    }

    // ======================================================================
    // 入力チェック
    // ======================================================================

    @Nested
    @DisplayName("入力チェック")
    class Validation {

        @Test
        @DisplayName("すべて正しければエラーは 0 件")
        void validFormHasNoErrors() {
            ValidationErrors errors = validForm().validate();

            assertFalse(errors.hasErrors(), errors.toString());
            assertEquals(0, errors.getCount());
        }

        @ParameterizedTest
        @NullAndEmptySource
        @ValueSource(strings = {"   ", "　"})
        @DisplayName("お名前が未入力・空白だけならエラー (全角スペースも空白として落とす)")
        void blankNameIsRejected(String name) {
            ValidationErrors errors =
                    InquiryForm.of(name, "taro@example.com", "question", "本文").validate();

            assertTrue(errors.has("name"), errors.toString());
            assertEquals("お名前を入力してください。", errors.get("name"));
        }

        @Test
        @DisplayName("お名前が上限ちょうどなら通る")
        void nameAtTheLimitIsAccepted() {
            String name = repeat("あ", InquiryForm.NAME_MAX_LENGTH);
            ValidationErrors errors =
                    InquiryForm.of(name, "taro@example.com", "question", "本文").validate();

            assertFalse(errors.has("name"), errors.toString());
        }

        @Test
        @DisplayName("お名前が上限を 1 文字超えるとエラー")
        void tooLongNameIsRejected() {
            String name = repeat("あ", InquiryForm.NAME_MAX_LENGTH + 1);
            ValidationErrors errors =
                    InquiryForm.of(name, "taro@example.com", "question", "本文").validate();

            assertTrue(errors.has("name"), errors.toString());
        }

        @ParameterizedTest
        @NullAndEmptySource
        @ValueSource(strings = {"  "})
        @DisplayName("メールアドレスが未入力ならエラー")
        void blankMailIsRejected(String mail) {
            ValidationErrors errors = InquiryForm.of("山田", mail, "question", "本文").validate();

            assertEquals("メールアドレスを入力してください。", errors.get("mail"));
        }

        @ParameterizedTest
        @ValueSource(strings = {
                "taro.example.com",   // @ が無い
                "taro@example",       // ドットが無い
                "@example.com",       // @ の前が無い
                "taro@",              // @ の後ろが無い
                "taro example@x.com"  // 空白が混ざっている
        })
        @DisplayName("メールアドレスの形が崩れていればエラー")
        void malformedMailIsRejected(String mail) {
            ValidationErrors errors = InquiryForm.of("山田", mail, "question", "本文").validate();

            assertEquals("メールアドレスの形式が正しくありません。", errors.get("mail"));
        }

        @Test
        @DisplayName("前後に空白が付いたメールアドレスは、空白を落としてから見る")
        void surroundingSpacesAreStripped() {
            ValidationErrors errors =
                    InquiryForm.of("  山田  ", "  taro@example.com  ", "question", " 本文 ").validate();

            assertFalse(errors.hasErrors(), errors.toString());
        }

        @ParameterizedTest
        @NullAndEmptySource
        @DisplayName("種別が未選択ならエラー")
        void blankTypeIsRejected(String type) {
            ValidationErrors errors =
                    InquiryForm.of("山田", "taro@example.com", type, "本文").validate();

            assertEquals("お問い合わせの種別を選んでください。", errors.get("type"));
        }

        @ParameterizedTest
        @ValueSource(strings = {"question", "request", "trouble", "other"})
        @DisplayName("画面に並べた選択肢はすべて受け付ける")
        void everyOptionOnTheScreenIsAccepted(String type) {
            ValidationErrors errors =
                    InquiryForm.of("山田", "taro@example.com", type, "本文").validate();

            assertFalse(errors.has("type"), errors.toString());
        }

        @ParameterizedTest
        @ValueSource(strings = {
                "secret-admin",   // 画面に無い値を直接 POST された場合
                "QUESTION",       // 大文字小文字が違う
                "question2",      // 似ているが別の値
                "'; DROP TABLE"   // そのまま使うと危ない文字列
        })
        @DisplayName("選択肢に無い種別はエラー (画面を通さず POST されても弾く)")
        void unknownTypeIsRejected(String type) {
            ValidationErrors errors =
                    InquiryForm.of("山田", "taro@example.com", type, "本文").validate();

            assertTrue(errors.has("type"), errors.toString());
        }

        @ParameterizedTest
        @NullAndEmptySource
        @ValueSource(strings = {"   "})
        @DisplayName("お問い合わせ内容が未入力ならエラー")
        void blankBodyIsRejected(String body) {
            ValidationErrors errors =
                    InquiryForm.of("山田", "taro@example.com", "question", body).validate();

            assertEquals("お問い合わせ内容を入力してください。", errors.get("body"));
        }

        @Test
        @DisplayName("お問い合わせ内容が上限を超えるとエラー")
        void tooLongBodyIsRejected() {
            String body = repeat("あ", InquiryForm.BODY_MAX_LENGTH + 1);
            ValidationErrors errors =
                    InquiryForm.of("山田", "taro@example.com", "question", body).validate();

            assertTrue(errors.has("body"), errors.toString());
        }

        @Test
        @DisplayName("改行は CRLF でも 1 文字として数える (見えている行数どおりに数える)")
        void crlfCountsAsOneCharacter() {
            // 「あ」を 100 行。CRLF のまま数えると 298 文字で上限超え、
            // LF に揃えれば 199 文字で収まる
            String body = repeat("あ\r\n", 99) + "あ";
            assertEquals(298, body.length(), "テストの前提 (変換前の長さ)");

            ValidationErrors errors =
                    InquiryForm.of("山田", "taro@example.com", "question", body).validate();

            assertFalse(errors.has("body"), errors.toString());
        }

        @Test
        @DisplayName("複数の項目が同時に誤っていれば、その数だけエラーが返る")
        void everyBrokenFieldIsReported() {
            ValidationErrors errors = InquiryForm.of("", "", "", "").validate();

            assertEquals(4, errors.getCount(), errors.toString());
            assertTrue(errors.has("name"));
            assertTrue(errors.has("mail"));
            assertTrue(errors.has("type"));
            assertTrue(errors.has("body"));
        }

        @Test
        @DisplayName("1 つの項目に付くメッセージは 1 件だけ")
        void oneMessagePerField() {
            // 未入力なので「入力してください」だけが付く (長さのチェックには進まない)
            ValidationErrors errors =
                    InquiryForm.of("", "taro@example.com", "question", "本文").validate();

            assertEquals(1, errors.getCount(), errors.toString());
        }

        @Test
        @DisplayName("種別の値から表示名を引ける (知らない値なら空文字)")
        void labelOfKnownType() {
            assertEquals("ご質問", InquiryForm.labelOf("question"));
            assertEquals("", InquiryForm.labelOf("secret-admin"));
        }
    }

    // ======================================================================
    // 返す JSON
    // ======================================================================

    @Nested
    @DisplayName("返す JSON")
    class Payload {

        @Test
        @DisplayName("入力エラーの JSON は、項目名をキーにしたオブジェクトになっている")
        void errorPayloadUsesFieldNamesAsKeys() {
            ValidationErrors errors = InquiryForm.of("", "bad-mail", "question", "本文").validate();

            String json = new AjaxFormApiServlet().errorPayload(errors).toString();

            assertTrue(json.contains("\"ok\":false"), json);
            assertTrue(json.contains("\"status\":400"), json);
            assertTrue(json.contains("\"errorCount\":2"), json);
            assertTrue(json.contains("\"errors\":{"), json);
            assertTrue(json.contains("\"name\":\"お名前を入力してください。\""), json);
            assertTrue(json.contains("\"mail\":\"メールアドレスの形式が正しくありません。\""), json);
        }

        @Test
        @DisplayName("エラーの JSON のキーの順番は、画面の項目の並び順と同じ")
        void errorKeysKeepTheScreenOrder() {
            ValidationErrors errors = InquiryForm.of("", "", "", "").validate();

            String json = new AjaxFormApiServlet().errorPayload(errors).toString();

            // 画面側が「最初のエラー項目へフォーカスを移す」書き方をできるようにするため、
            // 入れた順 (= 画面の項目順) が保たれていることを確かめる
            assertTrue(json.indexOf("\"name\"") < json.indexOf("\"mail\""), json);
            assertTrue(json.indexOf("\"mail\"") < json.indexOf("\"type\""), json);
            assertTrue(json.indexOf("\"type\"") < json.indexOf("\"body\""), json);
        }

        @Test
        @DisplayName("エラーが無ければ errors は空のオブジェクトになる (形は変えない)")
        void errorsKeyAlwaysExists() {
            String json = new AjaxFormApiServlet().errorPayload(new ValidationErrors()).toString();

            // 受け取る側に「このときは errors が無い」という分岐を増やさないため、
            // 中身が空でもキーごと消さない
            assertTrue(json.contains("\"errors\":{}"), json);
        }

        @Test
        @DisplayName("受付完了の JSON に、画面が使う項目がすべて入っている")
        void successPayloadContainsEveryFieldTheScreenUses() {
            DuplicateGuard.Result accepted = new DuplicateGuard.Result("A-0001", false);

            String json = new AjaxFormApiServlet().successPayload(validForm(), accepted).toString();

            assertTrue(json.contains("\"ok\":true"), json);
            assertTrue(json.contains("\"receipt\":\"A-0001\""), json);
            assertTrue(json.contains("\"message\":\""), json);
            assertTrue(json.contains("\"duplicate\":false"), json);
            assertTrue(json.contains("\"acceptedAt\":\""), json);
            assertTrue(json.contains("\"name\":\"山田 太郎\""), json);
            assertTrue(json.contains("\"typeLabel\":\"ご質問\""), json);
            assertTrue(json.contains("\"bodyLength\":12"), json);
        }

        @Test
        @DisplayName("二重送信として受けた場合は duplicate が true になり、メッセージも変わる")
        void duplicateIsToldToTheScreen() {
            DuplicateGuard.Result accepted = new DuplicateGuard.Result("A-0001", true);

            String json = new AjaxFormApiServlet().successPayload(validForm(), accepted).toString();

            assertTrue(json.contains("\"duplicate\":true"), json);
            assertTrue(json.contains("受付番号は変わりません"), json);
        }

        @Test
        @DisplayName("値に引用符が混ざっていても、壊れない JSON になる")
        void quotesInValuesAreEscaped() {
            InquiryForm form = InquiryForm.of("山田 \"太郎\"", "taro@example.com", "question", "本文");
            DuplicateGuard.Result accepted = new DuplicateGuard.Result("A-0002", false);

            String json = new AjaxFormApiServlet().successPayload(form, accepted).toString();

            // エスケープせずに埋め込むと、ここで JSON の文字列が閉じてしまう
            assertTrue(json.contains("\"name\":\"山田 \\\"太郎\\\"\""), json);
        }

        @Test
        @DisplayName("文字数は数値として書き出される (文字列にすると画面で計算できない)")
        void numbersAreWrittenAsNumbers() {
            DuplicateGuard.Result accepted = new DuplicateGuard.Result("A-0001", false);

            String json = new AjaxFormApiServlet().successPayload(validForm(), accepted).toString();

            assertFalse(json.contains("\"bodyLength\":\""), json);
        }
    }

    // ======================================================================
    // 受付番号と二重送信の防止
    // ======================================================================

    @Nested
    @DisplayName("二重送信の防止")
    class Duplicate {

        /** 呼ばれるたびに番号が 1 つ増える採番役 (本体の AtomicLong と同じ働き)。 */
        private Supplier<String> sequence() {
            AtomicLong counter = new AtomicLong();
            return () -> AjaxFormApiServlet.formatReceipt(counter.incrementAndGet());
        }

        @Test
        @DisplayName("受付番号は A-0001 の形になる")
        void receiptIsZeroPadded() {
            assertEquals("A-0001", AjaxFormApiServlet.formatReceipt(1L));
            assertEquals("A-0042", AjaxFormApiServlet.formatReceipt(42L));
            // 桁があふれても切り捨てずに伸びる
            assertEquals("A-12345", AjaxFormApiServlet.formatReceipt(12345L));
        }

        @Test
        @DisplayName("期間内に同じ内容が来たら、採番し直さず同じ受付番号を返す")
        void sameContentInWindowKeepsTheReceipt() {
            DuplicateGuard guard = new DuplicateGuard(10_000L);
            Supplier<String> issuer = sequence();

            DuplicateGuard.Result first = guard.accept("key", 1_000L, issuer);
            DuplicateGuard.Result second = guard.accept("key", 3_000L, issuer);

            assertEquals("A-0001", first.getReceipt());
            assertFalse(first.isDuplicate());
            assertEquals("A-0001", second.getReceipt(), "同じ受付番号を返す");
            assertTrue(second.isDuplicate());
        }

        @Test
        @DisplayName("期間を過ぎていれば、同じ内容でも新しく受け付ける")
        void sameContentAfterWindowIsAcceptedAgain() {
            DuplicateGuard guard = new DuplicateGuard(10_000L);
            Supplier<String> issuer = sequence();

            guard.accept("key", 1_000L, issuer);
            // ちょうど 10 秒後は「期間内ではない」扱い (11_000 - 1_000 = 10_000)
            DuplicateGuard.Result later = guard.accept("key", 11_000L, issuer);

            assertEquals("A-0002", later.getReceipt());
            assertFalse(later.isDuplicate());
        }

        @Test
        @DisplayName("内容が違えば、同じ時刻でも別々に受け付ける")
        void differentContentGetsDifferentReceipts() {
            DuplicateGuard guard = new DuplicateGuard(10_000L);
            Supplier<String> issuer = sequence();

            DuplicateGuard.Result first = guard.accept("key-1", 1_000L, issuer);
            DuplicateGuard.Result second = guard.accept("key-2", 1_000L, issuer);

            assertNotEquals(first.getReceipt(), second.getReceipt());
            assertFalse(second.isDuplicate());
            assertEquals(2, guard.size());
        }

        @Test
        @DisplayName("別々の内容が短い間に大量に来ても、覚えている件数は頭打ちになる")
        void memoryIsBounded() {
            DuplicateGuard guard = new DuplicateGuard(10_000L);
            Supplier<String> issuer = sequence();

            // 時刻を動かさないので、どの記録もまだ期限内。
            // 「掃除しても 1 件も減らない」状況をわざと作る
            for (int i = 0; i < 5_000; i++) {
                guard.accept("key-" + i, 1_000L, issuer);
            }

            // ここで際限なく増えると、公開した画面ではメモリを食いつぶす的になる
            assertTrue(guard.size() <= 1_000, "覚えている件数: " + guard.size());
        }

        @Test
        @DisplayName("鍵にはセッション ID が混ざる (別の利用者の受付番号を渡さない)")
        void fingerprintSeparatesUsers() {
            InquiryForm form = validForm();

            String mine = AjaxFormApiServlet.fingerprint("SESSION-A", form);
            String others = AjaxFormApiServlet.fingerprint("SESSION-B", form);

            assertNotEquals(mine, others);
        }

        @Test
        @DisplayName("同じ人が同じ内容を送れば、同じ鍵になる")
        void sameInputMakesSameFingerprint() {
            String first = AjaxFormApiServlet.fingerprint("SESSION-A", validForm());
            String second = AjaxFormApiServlet.fingerprint("SESSION-A", validForm());

            assertEquals(first, second);
        }

        @Test
        @DisplayName("項目の区切りがあるので、文字の切れ目が違えば別の鍵になる")
        void fieldBoundariesAreKept() {
            String first = AjaxFormApiServlet.fingerprint("S",
                    InquiryForm.of("ab", "c@example.com", "question", "本文"));
            String second = AjaxFormApiServlet.fingerprint("S",
                    InquiryForm.of("a", "bc@example.com", "question", "本文"));

            // 区切り無しで連結すると、この 2 つが同じ鍵になってしまう
            assertNotEquals(first, second);
        }
    }
}
