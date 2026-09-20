package com.example.servletsample.samples.advanced;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import java.util.OptionalInt;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * 振替とトランザクション ({@link TransferDao}) のテスト。
 *
 * <p>このサンプルでいちばん見せたいのは
 * <b>「トランザクションを使わずに途中で失敗すると、出金だけが残る」</b>ことです。
 * テストでもそこを押さえています
 * (壊れることを確かめるテストは、直したつもりで直っていない事故を防ぎます)。</p>
 */
class TransferDaoTest {

    /** 初期残高の合計。振替では変わらないはずの値。 */
    private static final int INITIAL_TOTAL = 90_000;

    private final TransferDao dao = new TransferDao();

    @BeforeEach
    void reset() {
        dao.reset();
    }

    private long idOf(String code) {
        return dao.findAccounts().stream()
                .filter(account -> account.getCode().equals(code))
                .findFirst()
                .orElseThrow()
                .getId();
    }

    private int balanceOf(String code) {
        return dao.findAccounts().stream()
                .filter(account -> account.getCode().equals(code))
                .findFirst()
                .orElseThrow()
                .getBalance();
    }

    @Test
    @DisplayName("初期状態の合計は 90,000 円")
    void hasSeedData() {
        assertEquals(3, dao.findAccounts().size());
        assertEquals(INITIAL_TOTAL, dao.totalBalance());
    }

    @Nested
    @DisplayName("成功したとき")
    class Success {

        @Test
        @DisplayName("出金・入金・履歴がまとめて確定する")
        void commitsAllThree() {
            TransferOutcome outcome = dao.transfer(idOf("A-001"), idOf("A-002"), 10_000, true, false);

            assertTrue(outcome.isCommitted());
            assertFalse(outcome.isRolledBack());
            assertEquals(40_000, balanceOf("A-001"));
            assertEquals(40_000, balanceOf("A-002"));
            assertEquals(1, dao.recentTransfers(10).size());
            assertEquals(INITIAL_TOTAL, dao.totalBalance(), "合計は変わらない");
        }
    }

    @Nested
    @DisplayName("トランザクションを使って失敗したとき")
    class WithTransaction {

        @Test
        @DisplayName("途中で失敗すると、出金ごと取り消される")
        void rollsBackEverything() {
            TransferOutcome outcome = dao.transfer(idOf("A-001"), idOf("A-002"), 10_000, true, true);

            assertTrue(outcome.isRolledBack());
            assertTrue(outcome.isFailed());
            assertEquals(50_000, balanceOf("A-001"), "出金が取り消されているはず");
            assertEquals(30_000, balanceOf("A-002"));
            assertEquals(INITIAL_TOTAL, dao.totalBalance());
            assertTrue(dao.recentTransfers(10).isEmpty(), "履歴も残らない");
        }

        @Test
        @DisplayName("残高が足りなければ業務エラーとして取り消される")
        void rollsBackWhenBalanceIsNotEnough() {
            TransferOutcome outcome = dao.transfer(idOf("A-003"), idOf("A-001"), 99_999, true, false);

            assertTrue(outcome.isRolledBack());
            assertEquals("ApplicationException", outcome.getErrorType());
            assertEquals(10_000, balanceOf("A-003"), "残高は減っていないはず");
            assertEquals(INITIAL_TOTAL, dao.totalBalance());
        }

        @Test
        @DisplayName("通った手順が記録される")
        void recordsSteps() {
            TransferOutcome outcome = dao.transfer(idOf("A-001"), idOf("A-002"), 1_000, true, false);

            List<String> steps = outcome.getSteps();
            assertTrue(steps.get(0).contains("setAutoCommit(false)"), steps.toString());
            assertTrue(steps.get(steps.size() - 1).contains("commit()"), steps.toString());
        }
    }

    @Nested
    @DisplayName("トランザクションを使わずに失敗したとき")
    class WithoutTransaction {

        @Test
        @DisplayName("出金だけが確定して、合計が合わなくなる")
        void leavesPartialUpdate() {
            TransferOutcome outcome = dao.transfer(idOf("A-001"), idOf("A-002"), 10_000, false, true);

            assertTrue(outcome.isFailed());
            assertFalse(outcome.isRolledBack(), "取り消せないはず");
            assertTrue(outcome.isAutoCommit());

            assertEquals(40_000, balanceOf("A-001"), "出金だけが確定して残る");
            assertEquals(30_000, balanceOf("A-002"), "入金は行われていない");
            assertEquals(INITIAL_TOTAL - 10_000, dao.totalBalance(),
                    "合計が 10,000 円減ってしまう ―― これが「途中まで実行された」状態");
        }
    }

    @Nested
    @DisplayName("入力チェック")
    class Validation {

        @Test
        @DisplayName("同じ口座どうしは振替できない")
        void rejectsSameAccount() {
            assertEquals("送金元と送金先には別の口座を選んでください。",
                    TransactionServlet.validate(OptionalInt.of(1), OptionalInt.of(1), OptionalInt.of(100)));
        }

        @Test
        @DisplayName("口座が選ばれていなければエラー")
        void rejectsMissingAccount() {
            assertEquals("送金元と送金先を選んでください。",
                    TransactionServlet.validate(OptionalInt.empty(), OptionalInt.of(2), OptionalInt.of(100)));
        }

        @Test
        @DisplayName("金額が数値でなければエラー")
        void rejectsNonNumericAmount() {
            assertEquals("金額は半角数字で入力してください。",
                    TransactionServlet.validate(OptionalInt.of(1), OptionalInt.of(2), OptionalInt.empty()));
        }

        @Test
        @DisplayName("金額が範囲外ならエラー")
        void rejectsOutOfRangeAmount() {
            assertFalse(TransactionServlet.validate(
                    OptionalInt.of(1), OptionalInt.of(2), OptionalInt.of(0)) == null);
            assertFalse(TransactionServlet.validate(
                    OptionalInt.of(1), OptionalInt.of(2), OptionalInt.of(TransactionServlet.MAX_AMOUNT + 1)) == null);
        }

        @Test
        @DisplayName("正しければ null")
        void acceptsValidInput() {
            assertEquals(null, TransactionServlet.validate(
                    OptionalInt.of(1), OptionalInt.of(2), OptionalInt.of(10_000)));
        }
    }
}
