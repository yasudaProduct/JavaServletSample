package com.example.servletsample.samples.test;

/**
 * サービス層への入力。
 *
 * <p>{@code HttpServletRequest} をそのままサービスに渡すと、
 * サービスのテストにまで Servlet API が付いてきてしまいます。
 * <b>画面の事情はここで断ち切って</b>、必要な値だけを持つ入れ物に詰め替えます。</p>
 */
public final class OrderRequest {

    private final String customerName;
    private final String itemCode;
    private final int quantity;
    private final MemberRank memberRank;

    public OrderRequest(String customerName, String itemCode, int quantity, MemberRank memberRank) {
        this.customerName = customerName;
        this.itemCode = itemCode;
        this.quantity = quantity;
        this.memberRank = (memberRank == null) ? MemberRank.REGULAR : memberRank;
    }

    public String getCustomerName() {
        return customerName;
    }

    public String getItemCode() {
        return itemCode;
    }

    public int getQuantity() {
        return quantity;
    }

    public MemberRank getMemberRank() {
        return memberRank;
    }

    @Override
    public String toString() {
        return "OrderRequest{" + customerName + ", " + itemCode + " × " + quantity + ", " + memberRank + "}";
    }
}
