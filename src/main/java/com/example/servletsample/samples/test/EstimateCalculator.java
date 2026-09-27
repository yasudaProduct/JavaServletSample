package com.example.servletsample.samples.test;

import java.util.Objects;

/**
 * 【サンプル】{@link LegacyEstimateServlet} の計算部分を切り出したもの (直した後の姿)。
 *
 * <p>Servlet API にも時計にも触らない、ただの計算です。
 * 引数を渡せば結果が返るので、Servlet を動かさなくてもテストできます。</p>
 *
 * <h2>動きは 1 つも変えていない</h2>
 * <p>切り出すときに守ったのは、<b>元の Servlet と同じ入力には同じ結果を返す</b>ことだけです。
 * 境界の {@code <=} と {@code <} の不揃いも、沖縄の扱いも、数量 0 で送料が掛かることも、
 * 元のまま残しています。それを保証しているのが {@code EstimateGoldenMasterTest} で、
 * 同じ記録ファイルが直す前にも直した後にも通ることを確かめています。</p>
 *
 * <p>不揃いを直したくなっても、<b>この整理とは別の変更として</b>、
 * 業務の担当者に確認してから行います。
 * 「整理」と「動きの変更」を 1 つの変更に混ぜると、
 * 結果が変わったときにどちらが原因なのか分からなくなるからです。</p>
 */
public final class EstimateCalculator {

    /** 送料が「離島・遠隔地」の料金表になる地域。 */
    private static final String HOKKAIDO = "北海道";
    private static final String OKINAWA = "沖縄";

    /** 会員はこの金額「以上」で送料無料。 */
    static final int MEMBER_FREE_SHIPPING_FROM = 5_000;

    /** 一般はこの金額を「超えると」送料無料 (ちょうどは有料。会員と揃っていないが今の動きのまま)。 */
    static final int REGULAR_FREE_SHIPPING_OVER = 10_000;

    /** 沖縄は送料無料の対象外で、無料になるはずのときもこの送料が掛かる。 */
    static final int OKINAWA_MINIMUM_SHIPPING = 1_200;

    /** 会員割引の率 (%)。 */
    static final int MEMBER_DISCOUNT_PERCENT = 5;

    static final int TAX_PERCENT = 10;

    private EstimateCalculator() {
    }

    /**
     * 見積もりを計算する。
     *
     * @param pref   都道府県。{@code null} は元の Servlet と同じく {@link NullPointerException}
     * @param price  単価
     * @param qty    数量 (0 や負の数も、元の Servlet と同じくそのまま計算する)
     * @param weight 1 個あたりの重さ (g)
     * @param member 会員か
     */
    public static Estimate calculate(String pref, int price, int qty, int weight, boolean member) {
        Objects.requireNonNull(pref, "pref");

        int amount = price * qty;
        int ship = shippingFee(pref, weight * qty);
        if (isFreeShipping(amount, member)) {
            ship = 0;
        }
        if (OKINAWA.equals(pref) && ship == 0) {
            ship = OKINAWA_MINIMUM_SHIPPING;
        }

        int discount = member ? amount * MEMBER_DISCOUNT_PERCENT / 100 : 0;
        int tax = (amount - discount + ship) * TAX_PERCENT / 100;
        return new Estimate(amount, ship, discount, tax);
    }

    /** 重さと地域で決まる送料 (送料無料の判定前)。 */
    static int shippingFee(String pref, int totalWeight) {
        if (HOKKAIDO.equals(pref) || OKINAWA.equals(pref)) {
            // 要確認: 5,000g ちょうどは 2,500 円。本州側 (<= 5000) と境界が揃っていない
            if (totalWeight <= 2000) {
                return 1_200;
            }
            return totalWeight < 5000 ? 1_800 : 2_500;
        }
        // 都道府県が空や未知の値でも、ここ (本州の料金) になる
        if (totalWeight <= 2000) {
            return 800;
        }
        return totalWeight <= 5000 ? 1_100 : 1_600;
    }

    private static boolean isFreeShipping(int amount, boolean member) {
        return member ? amount >= MEMBER_FREE_SHIPPING_FROM : amount > REGULAR_FREE_SHIPPING_OVER;
    }

    /** 見積もりの結果。 */
    public static final class Estimate {

        private final int amount;
        private final int ship;
        private final int discount;
        private final int tax;

        Estimate(int amount, int ship, int discount, int tax) {
            this.amount = amount;
            this.ship = ship;
            this.discount = discount;
            this.tax = tax;
        }

        /** 商品代金 (単価 × 数量)。 */
        public int getAmount() {
            return amount;
        }

        /** 送料。 */
        public int getShip() {
            return ship;
        }

        /** 会員割引額。 */
        public int getDiscount() {
            return discount;
        }

        /** 消費税。 */
        public int getTax() {
            return tax;
        }

        /** 請求金額。 */
        public int getTotal() {
            return amount - discount + ship + tax;
        }
    }
}
