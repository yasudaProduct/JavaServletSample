package com.example.servletsample.samples.test;

import java.io.Serializable;
import java.util.Objects;

/**
 * 注文 1 件の金額の内訳。
 *
 * <p>{@link OrderPricing#calculate} の結果です。合計だけでなく内訳を持たせているのは、
 * 画面に明細を出すためだけでなく<b>テストのため</b>でもあります。
 * 合計しか返さないと、金額がずれたときに
 * 「割引が違うのか、送料が違うのか、税が違うのか」がテストの失敗メッセージから分かりません。</p>
 *
 * <p>値を持つだけで、状態が変わらないクラス (値オブジェクト) にしてあります。
 * {@code equals} を実装してあるので、テストでは内訳をまとめて 1 行で比較できます。</p>
 *
 * <pre>{@code
 * assertEquals(new OrderAmount(3600, 0, 0, 600, 420), OrderPricing.calculate(1200, 3, MemberRank.REGULAR));
 * }</pre>
 */
public final class OrderAmount implements Serializable {

    private static final long serialVersionUID = 1L;

    private final int subtotal;
    private final int bulkDiscount;
    private final int memberDiscount;
    private final int shippingFee;
    private final int tax;

    public OrderAmount(int subtotal, int bulkDiscount, int memberDiscount, int shippingFee, int tax) {
        this.subtotal = subtotal;
        this.bulkDiscount = bulkDiscount;
        this.memberDiscount = memberDiscount;
        this.shippingFee = shippingFee;
        this.tax = tax;
    }

    /** 小計 (単価 × 数量、税抜)。 */
    public int getSubtotal() {
        return subtotal;
    }

    /** まとめ買い割引の額。 */
    public int getBulkDiscount() {
        return bulkDiscount;
    }

    /** 会員割引の額。 */
    public int getMemberDiscount() {
        return memberDiscount;
    }

    /** 割引をすべて引いたあとの商品代金 (税抜)。 */
    public int getDiscountedSubtotal() {
        return subtotal - bulkDiscount - memberDiscount;
    }

    /** 送料 (税抜)。 */
    public int getShippingFee() {
        return shippingFee;
    }

    /** 消費税。 */
    public int getTax() {
        return tax;
    }

    /** 請求金額 (税込)。 */
    public int getTotal() {
        return getDiscountedSubtotal() + shippingFee + tax;
    }

    /** 送料が無料になっているか。 */
    public boolean isFreeShipping() {
        return shippingFee == 0;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof OrderAmount)) {
            return false;
        }
        OrderAmount that = (OrderAmount) other;
        return subtotal == that.subtotal
                && bulkDiscount == that.bulkDiscount
                && memberDiscount == that.memberDiscount
                && shippingFee == that.shippingFee
                && tax == that.tax;
    }

    @Override
    public int hashCode() {
        return Objects.hash(subtotal, bulkDiscount, memberDiscount, shippingFee, tax);
    }

    /**
     * テストが失敗したときに、どこがずれたのか読み取れる形にしておく。
     *
     * <p>{@code OrderAmount@1b6d3586} と表示されても何も分かりません。
     * 値オブジェクトの {@code toString} は<b>テストの失敗メッセージ</b>だと思って書きます。</p>
     */
    @Override
    public String toString() {
        return "OrderAmount{小計=" + subtotal
                + ", まとめ買い割引=" + bulkDiscount
                + ", 会員割引=" + memberDiscount
                + ", 送料=" + shippingFee
                + ", 消費税=" + tax
                + ", 合計=" + getTotal() + "}";
    }
}
