package com.example.servletsample.samples.test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * 【サンプル】サービス層の単体テスト ({@link OrderService})。
 *
 * <p>このサービスは本番では H2 を読み書きしますが、このテストでは
 * <b>DB を一切使いません</b>。{@link OrderRepository} をインターフェースにしてあり、
 * テストではメモリ上で動く {@link InMemoryOrderRepository} を渡しているからです。</p>
 *
 * <h2>見せたいこと</h2>
 * <ol>
 *   <li><b>テストダブルを差し替える</b> … 本物の代わりに偽物を渡す。DB も Tomcat も要らない。</li>
 *   <li><b>時計を止める</b> … {@code Clock.fixed} で時刻を固定すると、
 *       受注番号や受付日時を {@code assertEquals} で確かめられる。</li>
 *   <li><b>「やっていないこと」を確かめる</b> … 在庫不足のときに保存していないことを、
 *       スパイ (呼び出し回数の記録) で確認する。</li>
 *   <li><b>異常系は戻り値で受け取る</b> … 在庫不足は例外ではなく {@link OrderResult} の失敗。</li>
 * </ol>
 */
class OrderServiceTest {

    /**
     * 2025-04-01 09:00:00 (日本時間) で止めた時計。
     *
     * <p>時刻が動かないので、受注番号 {@code ORD-20250401-001} のような
     * 「日付を含む値」をテストで書けます。{@code LocalDateTime.now()} を
     * サービスの中で直接呼んでいたら、この検証はできません。</p>
     */
    private static final Clock FIXED_CLOCK =
            Clock.fixed(Instant.parse("2025-04-01T00:00:00Z"), ZoneId.of("Asia/Tokyo"));

    private InMemoryOrderRepository repository;
    private OrderService service;

    @BeforeEach
    void setUp() {
        // テストごとに作り直す。前のテストの在庫が残っていると、
        // 単体では通るのに全部流すと落ちる、という厄介な状態になります。
        repository = new InMemoryOrderRepository();
        service = new OrderService(repository, FIXED_CLOCK);
    }

    // ======================================================================
    // 正常系
    // ======================================================================

    @Nested
    @DisplayName("注文を受け付けられるとき")
    class Accepted {

        @Test
        @DisplayName("受注番号・金額・受付日時を返す")
        void returnsAcceptedOrder() {
            // Arrange : コピー用紙 (1,000 円) を 10 個 → まとめ買い割引が効く
            OrderRequest request = new OrderRequest("山田 太郎", "B-200", 10, MemberRank.REGULAR);

            // Act
            OrderResult result = service.place(request);

            // Assert
            assertTrue(result.isSuccess(), result.getMessage());

            OrderEntry order = result.getOrder();
            assertEquals("ORD-20250401-001", order.getOrderNumber(), "時計を止めてあるので固定値で書ける");
            assertEquals("山田 太郎", order.getCustomerName());
            assertEquals("B-200", order.getItemCode());
            assertEquals(10, order.getQuantity());
            assertEquals(LocalDateTime.of(2025, 4, 1, 9, 0, 0), order.getAcceptedAt());

            // 金額の計算そのものは OrderPricingTest の担当なので、ここでは
            // 「サービスが正しい単価と数量で計算させたか」が分かる代表値だけ見ます。
            assertEquals(10_450, order.getAmount().getTotal());
        }

        @Test
        @DisplayName("在庫が減る")
        void decreasesStock() {
            service.place(new OrderRequest("山田 太郎", "B-200", 10, MemberRank.REGULAR));

            assertEquals(30, stockOf("B-200"), "40 個から 10 個減る");
            assertEquals(1, repository.getDecreaseStockCount());
            assertEquals(1, repository.getSaveCount());
        }

        @Test
        @DisplayName("在庫ちょうどの数量も受け付ける")
        void acceptsExactStock() {
            // オフィスチェアの在庫は 3 個
            OrderResult result = service.place(new OrderRequest("鈴木 花子", "C-300", 3, MemberRank.REGULAR));

            assertTrue(result.isSuccess(), result.getMessage());
            assertEquals(0, stockOf("C-300"));
        }

        @Test
        @DisplayName("受注番号は注文のたびに増える")
        void numbersOrdersInSequence() {
            String first = service.place(new OrderRequest("山田", "A-100", 1, MemberRank.REGULAR))
                    .getOrder().getOrderNumber();
            String second = service.place(new OrderRequest("鈴木", "A-100", 1, MemberRank.REGULAR))
                    .getOrder().getOrderNumber();

            assertEquals("ORD-20250401-001", first);
            assertEquals("ORD-20250401-002", second);
        }

        @Test
        @DisplayName("日付が変われば受注番号の日付も変わる")
        void usesClockDate() {
            // 時計を差し替えるだけで「別の日の注文」を作れます。
            // 実機の日付を変えたり、テストを日をまたいで流したりする必要はありません。
            Clock newYear = Clock.fixed(Instant.parse("2027-01-01T00:30:00Z"), ZoneId.of("Asia/Tokyo"));
            OrderService newYearService = new OrderService(repository, newYear);

            OrderResult result = newYearService.place(
                    new OrderRequest("山田", "A-100", 1, MemberRank.REGULAR));

            assertEquals("ORD-20270101-001", result.getOrder().getOrderNumber());
        }
    }

    // ======================================================================
    // 異常系
    // ======================================================================

    @Nested
    @DisplayName("注文を受け付けられないとき")
    class Rejected {

        @Test
        @DisplayName("在庫が足りなければ理由を返し、何も書き換えない")
        void rejectsWhenStockIsShort() {
            // オフィスチェアの在庫は 3 個。4 個注文する。
            OrderResult result = service.place(new OrderRequest("山田 太郎", "C-300", 4, MemberRank.REGULAR));

            assertFalse(result.isSuccess());
            assertTrue(result.getMessage().contains("在庫が足りません"), result.getMessage());
            assertTrue(result.getMessage().contains("3"), "残り何個かを伝える: " + result.getMessage());
            assertNull(result.getOrder());

            // ここが「テストダブルをスパイとして使う」場面。
            // 戻り値を見るだけでは「保存だけされてしまった」不具合に気付けません。
            assertEquals(0, repository.getDecreaseStockCount(), "在庫を減らしてはいけない");
            assertEquals(0, repository.getSaveCount(), "注文を保存してはいけない");
            assertEquals(3, stockOf("C-300"), "在庫はそのまま");
        }

        @Test
        @DisplayName("在庫 0 の商品は注文できない")
        void rejectsSoldOutItem() {
            // 「在庫 0 のとき」を作るために、偽物のリポジトリへ直接値を仕込む (スタブ)。
            // 本物の DB でこの状態を作るには、更新 SQL を流す用意が必要になります。
            repository.setStock("B-200", 0);

            OrderResult result = service.place(new OrderRequest("山田", "B-200", 1, MemberRank.REGULAR));

            assertFalse(result.isSuccess());
            assertEquals(0, repository.getSaveCount());
        }

        @Test
        @DisplayName("知らない商品コードなら理由を返す")
        void rejectsUnknownItem() {
            OrderResult result = service.place(new OrderRequest("山田", "Z-999", 1, MemberRank.REGULAR));

            assertFalse(result.isSuccess());
            assertTrue(result.getMessage().contains("商品が見つかりません"), result.getMessage());
        }

        @Test
        @DisplayName("数量が範囲外でも例外にはせず、メッセージで返す")
        void rejectsInvalidQuantityWithoutException() {
            // OrderPricing.calculate は数量 0 で例外を投げますが、
            // 利用者の入力が原因の失敗を 500 エラーにしてはいけません。
            // サービス層が手前で受け止めていることを確かめます。
            for (int quantity : new int[]{0, -1, 100}) {
                OrderResult result = assertDoesNotThrow(
                        () -> service.place(new OrderRequest("山田", "A-100", quantity, MemberRank.REGULAR)),
                        "数量 " + quantity + " で例外が出ています");

                assertFalse(result.isSuccess(), "数量 " + quantity);
                assertTrue(result.getMessage().contains("数量"), result.getMessage());
            }
            assertEquals(0, repository.getSaveCount());
        }
    }

    /** テストを読みやすくするための小さな補助メソッド。 */
    private int stockOf(String itemCode) {
        return repository.findItem(itemCode).orElseThrow().getStock();
    }
}
