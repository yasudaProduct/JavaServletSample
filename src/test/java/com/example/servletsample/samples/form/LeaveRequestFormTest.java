package com.example.servletsample.samples.form;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import com.example.servletsample.common.ValidationErrors;

/**
 * 休暇申請フォームの入力チェック ({@link LeaveRequestForm#validate(LocalDate)}) のテスト。
 *
 * <p>入力チェックの間違いは画面を見ても気づけないので、<b>境界値</b>
 * (ちょうど通る値と、1 つだけ外れた値) を並べて確かめています。</p>
 *
 * <p>「今日」は {@link #TODAY} に固定しています。
 * {@code validate} が基準日を引数で受け取る作りになっているおかげで、
 * <b>いつテストを実行しても同じ結果</b>になります。</p>
 */
class LeaveRequestFormTest {

    /** テストの中での「今日」。 */
    private static final LocalDate TODAY = LocalDate.of(2026, 4, 1);

    // ------------------------------------------------------------------
    // 組み立ての補助 : 調べたい項目以外は「正しい値」で埋める
    // ------------------------------------------------------------------

    private static LeaveRequestForm form(String employeeCode, String nameKana, String leaveType,
                                         String startDate, String endDate, String[] backupCodes,
                                         String reason) {
        return LeaveRequestForm.of(employeeCode, nameKana, leaveType, startDate, endDate,
                backupCodes, reason);
    }

    /** すべて正しい入力。 */
    private static LeaveRequestForm validForm() {
        return form("E1001", "ヤマダ タロウ", "10", "2026-04-10", "2026-04-12",
                new String[]{"E1002"}, "私用のため");
    }

    private static ValidationErrors withEmployeeCode(String employeeCode) {
        return form(employeeCode, "ヤマダ タロウ", "10", "2026-04-10", "2026-04-12",
                new String[]{"E1002"}, "私用のため").validate(TODAY);
    }

    private static ValidationErrors withNameKana(String nameKana) {
        return form("E1001", nameKana, "10", "2026-04-10", "2026-04-12",
                new String[]{"E1002"}, "私用のため").validate(TODAY);
    }

    private static ValidationErrors withLeaveType(String leaveType) {
        return form("E1001", "ヤマダ タロウ", leaveType, "2026-04-10", "2026-04-12",
                new String[]{"E1002"}, "私用のため").validate(TODAY);
    }

    private static ValidationErrors withDates(String startDate, String endDate) {
        return form("E1001", "ヤマダ タロウ", "10", startDate, endDate,
                new String[]{"E1002"}, "私用のため").validate(TODAY);
    }

    private static ValidationErrors withBackups(String... backupCodes) {
        return form("E1001", "ヤマダ タロウ", "10", "2026-04-10", "2026-04-12",
                backupCodes, "私用のため").validate(TODAY);
    }

    private static ValidationErrors withReason(String reason) {
        return form("E1001", "ヤマダ タロウ", "10", "2026-04-10", "2026-04-12",
                new String[]{"E1002"}, reason).validate(TODAY);
    }

    private static String repeat(String text, int count) {
        return text.repeat(count);
    }

    @Test
    @DisplayName("すべて正しければエラーは 0 件")
    void validFormHasNoErrors() {
        ValidationErrors errors = validForm().validate(TODAY);
        assertFalse(errors.hasErrors(), "エラーが出ています: " + errors);
    }

    @Nested
    @DisplayName("社員コード (必須 → 文字種 → 桁数 → 突き合わせ)")
    class EmployeeCode {

        @Test
        @DisplayName("未入力・空白だけはエラー")
        void required() {
            assertTrue(withEmployeeCode("").has("employeeCode"));
            assertTrue(withEmployeeCode("　").has("employeeCode"), "全角スペースだけも未入力");
            assertTrue(withEmployeeCode(null).has("employeeCode"));
        }

        @Test
        @DisplayName("半角英数字でなければエラー")
        void characterType() {
            assertTrue(withEmployeeCode("Ｅ１００１").has("employeeCode"), "全角");
            assertTrue(withEmployeeCode("E-101").has("employeeCode"), "記号");
        }

        @Test
        @DisplayName("5 桁ちょうどだけを受け付ける")
        void length() {
            assertTrue(withEmployeeCode("E100").has("employeeCode"), "4 桁");
            assertTrue(withEmployeeCode("E10011").has("employeeCode"), "6 桁");
            assertFalse(withEmployeeCode("E1001").has("employeeCode"), "5 桁");
        }

        @Test
        @DisplayName("形は正しくてもマスタに無ければエラー")
        void master() {
            assertTrue(withEmployeeCode("E9999").has("employeeCode"));
            assertFalse(withEmployeeCode("E2001").has("employeeCode"));
        }

        @Test
        @DisplayName("メッセージは 1 項目 1 件だけ")
        void onlyOneMessagePerField() {
            // 未入力は「必須」だけで、桁数のメッセージは出さない
            ValidationErrors errors = withEmployeeCode("");
            assertEquals("社員コードを入力してください。", errors.get("employeeCode"));
        }
    }

    @Nested
    @DisplayName("フリガナ (必須 → 文字種 → 桁数)")
    class NameKana {

        @Test
        @DisplayName("未入力はエラー")
        void required() {
            assertTrue(withNameKana("").has("nameKana"));
        }

        @Test
        @DisplayName("全角カタカナ以外はエラー")
        void characterType() {
            assertTrue(withNameKana("やまだ").has("nameKana"), "ひらがな");
            assertTrue(withNameKana("山田").has("nameKana"), "漢字");
            assertTrue(withNameKana("ﾔﾏﾀﾞ").has("nameKana"), "半角カタカナ");
            assertFalse(withNameKana("ヤマダ タロウ").has("nameKana"));
            assertFalse(withNameKana("サン・テグジュペリ").has("nameKana"), "中点も許す");
        }

        @Test
        @DisplayName("30 文字ちょうどは通り、31 文字はエラー")
        void length() {
            assertFalse(withNameKana(repeat("ア", 30)).has("nameKana"));
            assertTrue(withNameKana(repeat("ア", 31)).has("nameKana"));
        }
    }

    @Nested
    @DisplayName("休暇の種類 (選択必須 → ホワイトリスト)")
    class Type {

        @Test
        @DisplayName("選ばなければエラー")
        void required() {
            assertTrue(withLeaveType("").has("leaveType"));
        }

        @Test
        @DisplayName("一覧に無いコードはエラー")
        void whitelist() {
            assertTrue(withLeaveType("99").has("leaveType"));
            assertTrue(withLeaveType("ANNUAL").has("leaveType"), "enum の名前も受け付けない");
        }

        @Test
        @DisplayName("一覧にあるコードは通る")
        void accepted() {
            for (LeaveType type : LeaveType.all()) {
                assertFalse(withLeaveType(type.getCode()).has("leaveType"), type.getLabel());
            }
        }
    }

    @Nested
    @DisplayName("開始日・終了日 (形式 → 範囲 → 相関)")
    class Dates {

        @Test
        @DisplayName("未入力はエラー")
        void required() {
            assertTrue(withDates("", "2026-04-12").has("startDate"));
            assertTrue(withDates("2026-04-10", "").has("endDate"));
        }

        @Test
        @DisplayName("実在しない日付・形式違いはエラー")
        void format() {
            assertTrue(withDates("2026-02-30", "2026-04-12").has("startDate"), "2 月 30 日");
            assertTrue(withDates("2026/04/10", "2026-04-12").has("startDate"), "区切りが違う");
            assertTrue(withDates("2026-4-10", "2026-04-12").has("startDate"), "0 詰めが無い");
            assertTrue(withDates("2026-04-10", "2026-02-30").has("endDate"));
        }

        @Test
        @DisplayName("開始日は今日ちょうどなら通り、昨日ならエラー")
        void notInThePast() {
            assertFalse(withDates("2026-04-01", "2026-04-01").has("startDate"), "今日");
            assertTrue(withDates("2026-03-31", "2026-04-01").has("startDate"), "昨日");
        }

        @Test
        @DisplayName("6 か月後ちょうどは通り、その翌日はエラー")
        void notTooFarAhead() {
            assertFalse(withDates("2026-10-01", "2026-10-01").has("startDate"));
            assertTrue(withDates("2026-10-02", "2026-10-02").has("startDate"));
        }

        @Test
        @DisplayName("終了日が開始日より前ならエラー (同じ日は通る)")
        void order() {
            assertTrue(withDates("2026-04-10", "2026-04-09").has("endDate"));
            assertFalse(withDates("2026-04-10", "2026-04-10").has("endDate"));
        }

        @Test
        @DisplayName("30 日ちょうどは通り、31 日はエラー")
        void periodLimit() {
            // 4/10 から数えて 30 日目は 5/9、31 日目は 5/10
            assertFalse(withDates("2026-04-10", "2026-05-09").has("endDate"));
            assertTrue(withDates("2026-04-10", "2026-05-10").has("endDate"));
        }

        @Test
        @DisplayName("開始日が読めないときは前後関係を判定しない")
        void skipsCorrelationWhenUnparsable() {
            ValidationErrors errors = withDates("2026-02-30", "2026-04-12");
            assertTrue(errors.has("startDate"));
            assertFalse(errors.has("endDate"), "終了日まで赤くしない");
        }

        @Test
        @DisplayName("日数は両端を含めて数える")
        void days() {
            assertEquals(3, form("E1001", "ヤマダ", "10", "2026-04-10", "2026-04-12",
                    new String[]{"E1002"}, "私用のため").getDays());
            assertEquals(1, form("E1001", "ヤマダ", "10", "2026-04-10", "2026-04-10",
                    new String[]{"E1002"}, "私用のため").getDays());
            assertEquals(0, form("E1001", "ヤマダ", "10", "2026-04-10", "2026-02-30",
                    new String[]{"E1002"}, "私用のため").getDays(), "読めない日付なら 0");
        }
    }

    @Nested
    @DisplayName("引継ぎ先 (個数 → 突き合わせ → 相関)")
    class Backups {

        @Test
        @DisplayName("1 つも選ばなければエラー")
        void atLeastOne() {
            assertTrue(withBackups().has("backupCodes"));
            // getParameterValues は「選ばれていない」とき null を返す
            assertTrue(form("E1001", "ヤマダ", "10", "2026-04-10", "2026-04-12", null, "私用のため")
                    .validate(TODAY).has("backupCodes"));
        }

        @Test
        @DisplayName("3 名ちょうどは通り、4 名はエラー")
        void atMostThree() {
            assertFalse(withBackups("E1002", "E1003", "E2001").has("backupCodes"));
            assertTrue(withBackups("E1002", "E1003", "E2001", "E2002").has("backupCodes"));
        }

        @Test
        @DisplayName("同じ人を何度送っても 1 名として数える")
        void duplicatesAreCountedOnce() {
            assertFalse(withBackups("E1002", "E1002", "E1002").has("backupCodes"));
        }

        @Test
        @DisplayName("マスタに無いコードはエラー")
        void master() {
            assertTrue(withBackups("E9999").has("backupCodes"));
        }

        @Test
        @DisplayName("申請者本人は選べない")
        void notSelf() {
            assertTrue(withBackups("E1001").has("backupCodes"));
            assertTrue(withBackups("E1002", "E1001").has("backupCodes"));
        }

        @Test
        @DisplayName("選ばれているかを JSP から判定できる")
        void hasBackup() {
            LeaveRequestForm form = validForm();
            assertTrue(form.hasBackup("E1002"));
            assertFalse(form.hasBackup("E1003"));
        }
    }

    @Nested
    @DisplayName("理由 (必須 → 桁数)")
    class Reason {

        @Test
        @DisplayName("未入力はエラー")
        void required() {
            assertTrue(withReason("").has("reason"));
            assertTrue(withReason("   ").has("reason"));
        }

        @Test
        @DisplayName("200 文字ちょうどは通り、201 文字はエラー")
        void length() {
            assertFalse(withReason(repeat("あ", 200)).has("reason"));
            assertTrue(withReason(repeat("あ", 201)).has("reason"));
        }

        @Test
        @DisplayName("途中の改行は 1 文字として数える (CRLF を \\n に揃えている)")
        void newlinesCountAsOne() {
            // "あ" 100 個 + 改行 + "あ" 99 個 = 200 文字。
            // \r\n のまま数えると 201 文字になり、通るはずの入力がエラーになってしまう
            String text = repeat("あ", 100) + "\r\n" + repeat("あ", 99);
            assertFalse(withReason(text).has("reason"));
            assertEquals(200, form("E1001", "ヤマダ", "10", "2026-04-10", "2026-04-12",
                    new String[]{"E1002"}, text).getReasonLength());
            assertEquals(201, text.length(), "揃える前は 1 文字多い");
        }

        @Test
        @DisplayName("末尾の改行は前後の空白として落とす")
        void trailingNewlineIsStripped() {
            String text = repeat("あ", 200) + "\r\n";
            assertFalse(withReason(text).has("reason"));
            assertEquals(200, form("E1001", "ヤマダ", "10", "2026-04-10", "2026-04-12",
                    new String[]{"E1002"}, text).getReasonLength());
        }
    }

    @Nested
    @DisplayName("リクエストからの組み立て")
    class From {

        @Test
        @DisplayName("getParameter / getParameterValues から受け取れる")
        void readsParameters() {
            Map<String, String> parameters = new HashMap<>();
            parameters.put("employeeCode", " E1001 ");
            parameters.put("nameKana", "ヤマダ タロウ");
            parameters.put("leaveType", "10");
            parameters.put("startDate", "2026-04-10");
            parameters.put("endDate", "2026-04-12");
            parameters.put("reason", "私用のため");

            Map<String, String[]> multiParameters = new HashMap<>();
            multiParameters.put("backupCodes", new String[]{"E1002", "E1003"});

            LeaveRequestForm form = LeaveRequestForm.from(request(parameters, multiParameters));

            assertEquals("E1001", form.getEmployeeCode(), "前後の空白は落とす");
            assertEquals("10", form.getLeaveType());
            assertEquals(2, form.getBackupCodes().size());
            assertFalse(form.validate(TODAY).hasErrors());
        }

        @Test
        @DisplayName("チェックボックスが 1 つも選ばれていなくても落ちない")
        void noCheckbox() {
            LeaveRequestForm form = LeaveRequestForm.from(
                    request(new HashMap<>(), new HashMap<>()));
            assertTrue(form.getBackupCodes().isEmpty());
            assertTrue(form.validate(TODAY).has("backupCodes"));
        }

        /**
         * テスト用の最小限の {@code HttpServletRequest} (動的プロキシ)。
         *
         * <p>本物と同じように、送られていないパラメータには {@code null} を返します。</p>
         */
        private HttpServletRequest request(Map<String, String> parameters,
                                           Map<String, String[]> multiParameters) {
            InvocationHandler handler = (target, method, args) -> {
                if ("getParameter".equals(method.getName())) {
                    return parameters.get((String) args[0]);
                }
                if ("getParameterValues".equals(method.getName())) {
                    return multiParameters.get((String) args[0]);
                }
                return null;
            };
            return (HttpServletRequest) Proxy.newProxyInstance(
                    LeaveRequestFormTest.class.getClassLoader(),
                    new Class<?>[]{HttpServletRequest.class}, handler);
        }
    }
}
