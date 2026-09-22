package com.example.servletsample.samples.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * 【サンプル】計算ロジックの単体テスト ({@link OrderPricing})。
 *
 * <h2>このテストで見せたいこと</h2>
 * <ol>
 *   <li><b>AAA (Arrange / Act / Assert)</b> … 準備して、呼んで、確かめる。1 つのテストに 1 つの観点。</li>
 *   <li><b>境界値</b> … ルールが切り替わる「ちょうど」の前後を必ず両方試す。
 *       9 個と 10 個、4,999 円と 5,000 円。不具合はここに集まります。</li>
 *   <li><b>期待値は手計算で直接書く</b> … 実装と同じ式をテストに書くと、
 *       式が間違っていても一緒に間違えるのでテストが通ってしまいます。</li>
 *   <li><b>異常系</b> … 例外が出ることも仕様なので {@code assertThrows} で確かめる。</li>
 * </ol>
 *
 * <p>Tomcat も DB も要りません。{@code mvn test} で数ミリ秒で終わります。</p>
 */
class OrderPricingTest {

    // ======================================================================
    // 基本
    // ======================================================================

    @Nested
    @DisplayName("基本の計算")
    class Basic {

        @Test
        @DisplayName("単価 × 数量に送料と消費税が乗る")
        void calculatesSimpleOrder() {
            // Arrange : 何を計算させたいのかを、まず読める形で置く
            int unitPrice = 1200;
            int quantity = 3;

            // Act : 試したいメソッドは 1 つだけ呼ぶ
            OrderAmount amount = OrderPricing.calculate(unitPrice, quantity, MemberRank.REGULAR);

            // Assert : 内訳ごとに確かめる (どこがずれたのか失敗メッセージで分かる)
            assertEquals(3600, amount.getSubtotal(), "小計");
            assertEquals(0, amount.getBulkDiscount(), "まとめ買い割引");
            assertEquals(0, amount.getMemberDiscount(), "会員割引");
            assertEquals(600, amount.getShippingFee(), "送料");
            assertEquals(420, amount.getTax(), "消費税");
            assertEquals(4620, amount.getTotal(), "請求金額");
        }

        @Test
        @DisplayName("内訳をまとめて 1 行で比較する (値オブジェクトの equals)")
        void comparesWholeAmount() {
            // 内訳が全部そろっているかを 1 行で確かめられます。
            // 失敗すると OrderAmount#toString の内容が表示されるので、どこが違うかも分かります。
            assertEquals(new OrderAmount(3600, 0, 0, 600, 420),
                    OrderPricing.calculate(1200, 3, MemberRank.REGULAR));
        }

        @Test
        @DisplayName("会員ランクが未指定 (null) なら一般扱いにする")
        void treatsNullRankAsRegular() {
            assertEquals(OrderPricing.calculate(1200, 3, MemberRank.REGULAR),
                    OrderPricing.calculate(1200, 3, null));
        }
    }

    // ======================================================================
    // 境界値
    // ======================================================================

    @Nested
    @DisplayName("まとめ買い割引の境界 (10 個)")
    class BulkDiscountBoundary {

        @Test
        @DisplayName("9 個なら割引なし")
        void noDiscountAtNine() {
            OrderAmount amount = OrderPricing.calculate(1000, 9, MemberRank.REGULAR);

            assertEquals(9000, amount.getSubtotal());
            assertEquals(0, amount.getBulkDiscount(), "9 個では割引が効かない");
            assertEquals(9900, amount.getTotal());
        }

        @Test
        @DisplayName("ちょうど 10 個から 5% 引き")
        void discountFromTen() {
            OrderAmount amount = OrderPricing.calculate(1000, 10, MemberRank.REGULAR);

            assertEquals(10_000, amount.getSubtotal());
            assertEquals(500, amount.getBulkDiscount(), "10 個ちょうどで割引が効く");
            assertEquals(9500, amount.getDiscountedSubtotal());
            assertEquals(10_450, amount.getTotal());
        }
    }

    @Nested
    @DisplayName("送料無料の境界 (5,000 円)")
    class FreeShippingBoundary {

        @ParameterizedTest(name = "割引後 {0} 円 → 送料 {1} 円")
        @CsvSource({
                "4999, 600",    // 1 円足りない
                "5000,   0",    // ちょうど → 無料
                "5001,   0",
        })
        @DisplayName("割引後の商品代金が 5,000 円以上なら送料が無料になる")
        void freeShippingFromThreshold(int unitPrice, int expectedShippingFee) {
            // 単価だけ変えて 1 個買う = 割引後の商品代金をそのまま動かせる
            OrderAmount amount = OrderPricing.calculate(unitPrice, 1, MemberRank.REGULAR);

            assertEquals(expectedShippingFee, amount.getShippingFee());
        }

        @Test
        @DisplayName("送料の判定は「割引後」の金額で行う")
        void judgesAfterDiscount() {
            // 5,200 円の商品を一般会員が 1 個 → 割引なしなので送料無料
            OrderAmount regular = OrderPricing.calculate(5200, 1, MemberRank.REGULAR);
            assertTrue(regular.isFreeShipping());
            assertEquals(5720, regular.getTotal());

            // 同じ商品をゴールド会員が買うと 10% 引き = 4,680 円になり、無料ラインを割る
            OrderAmount gold = OrderPricing.calculate(5200, 1, MemberRank.GOLD);
            assertEquals(520, gold.getMemberDiscount());
            assertEquals(4680, gold.getDiscountedSubtotal());
            assertEquals(600, gold.getShippingFee(), "割引の結果、無料ラインを下回る");

            // その結果、ゴールド会員のほうが請求金額が高くなる。
            // 「バグに見えるが仕様どおり」という状態をテストに書き残しておくと、
            // 後から見た人が勝手に直して別の不具合を作るのを防げます。
            assertEquals(5808, gold.getTotal());
            assertTrue(gold.getTotal() > regular.getTotal(),
                    "割引したのに高くなる。仕様を決めた人に確認すべき点として残している");
        }
    }

    // ======================================================================
    // 端数
    // ======================================================================

    @Nested
    @DisplayName("円未満の端数")
    class Rounding {

        @Test
        @DisplayName("割引の端数は切り捨てる (166.5 円 → 166 円)")
        void floorsDiscount() {
            OrderAmount amount = OrderPricing.calculate(333, 10, MemberRank.REGULAR);

            assertEquals(3330, amount.getSubtotal());
            assertEquals(166, amount.getBulkDiscount(), "3330 × 5% = 166.5 → 166");
            assertEquals(376, amount.getTax(), "(3164 + 600) × 10% = 376.4 → 376");
            assertEquals(4140, amount.getTotal());
        }

        @Test
        @DisplayName("消費税の端数も切り捨てる (33.3 円 → 33 円)")
        void floorsMemberDiscountAndTax() {
            OrderAmount amount = OrderPricing.calculate(333, 1, MemberRank.GOLD);

            assertEquals(33, amount.getMemberDiscount(), "333 × 10% = 33.3 → 33");
            assertEquals(300, amount.getDiscountedSubtotal());
            assertEquals(90, amount.getTax());
            assertEquals(990, amount.getTotal());
        }
    }

    // ======================================================================
    // 組み合わせ (表で一気に確かめる)
    // ======================================================================

    @ParameterizedTest(name = "{0} 円 × {1} 個 ({2}) → 合計 {3} 円")
    @CsvSource({
            // 単価,   数量, ランク,   期待する請求金額
            "  1200,    3, REGULAR,  4620",
            "  1000,    9, REGULAR,  9900",
            "  1000,   10, REGULAR, 10450",
            "  1000,   10, GOLD,     9405",
            "   333,    1, GOLD,      990",
            "   100,   99, REGULAR, 10345",
    })
    @DisplayName("代表的な組み合わせの請求金額")
    void totals(int unitPrice, int quantity, MemberRank rank, int expectedTotal) {
        assertEquals(expectedTotal, OrderPricing.calculate(unitPrice, quantity, rank).getTotal());
    }

    // ======================================================================
    // 異常系
    // ======================================================================

    @Nested
    @DisplayName("扱えない値を渡したとき")
    class InvalidArguments {

        @ParameterizedTest(name = "数量 {0}")
        @ValueSource(ints = {0, -1, 100})
        @DisplayName("数量が 1 〜 99 の外なら例外にする")
        void rejectsQuantityOutOfRange(int quantity) {
            IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
                    () -> OrderPricing.calculate(1000, quantity, MemberRank.REGULAR));

            // メッセージまで確かめておくと、別の原因の例外を掴んで
            // 「テストは通っているのに直っていない」状態を防げます。
            assertTrue(e.getMessage().contains("数量"), "実際のメッセージ: " + e.getMessage());
        }

        @ParameterizedTest(name = "単価 {0}")
        @ValueSource(ints = {-1, 1_000_001})
        @DisplayName("単価が 0 〜 1,000,000 の外なら例外にする")
        void rejectsUnitPriceOutOfRange(int unitPrice) {
            assertThrows(IllegalArgumentException.class,
                    () -> OrderPricing.calculate(unitPrice, 1, MemberRank.REGULAR));
        }

        @Test
        @DisplayName("上限ちょうど (99 個 / 1,000,000 円) は通す")
        void acceptsUpperBounds() {
            // 「例外になる」テストを書いたら、「ならない」側も必ず書きます。
            // 片方だけだと、全部例外にする実装でもテストが通ってしまいます。
            assertEquals(9900, OrderPricing.calculate(100, 99, MemberRank.REGULAR).getSubtotal());
            assertEquals(1_000_000, OrderPricing.calculate(1_000_000, 1, MemberRank.REGULAR).getSubtotal());
        }

        @Test
        @DisplayName("単価 0 円 (ノベルティ) は例外にしない")
        void acceptsZeroUnitPrice() {
            OrderAmount amount = OrderPricing.calculate(0, 1, MemberRank.REGULAR);

            assertEquals(0, amount.getSubtotal());
            assertEquals(600, amount.getShippingFee(), "0 円でも送料はかかる");
            assertEquals(660, amount.getTotal());
        }
    }
}
