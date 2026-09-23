package com.example.servletsample.samples.test;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/** 受け付けた注文 1 件。 */
public final class OrderEntry implements Serializable {

    private static final long serialVersionUID = 1L;

    private static final DateTimeFormatter DISPLAY = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");

    private final String orderNumber;
    private final String customerName;
    private final String itemCode;
    private final String itemName;
    private final int quantity;
    private final MemberRank memberRank;
    private final OrderAmount amount;
    private final LocalDateTime acceptedAt;

    public OrderEntry(String orderNumber, String customerName, String itemCode, String itemName,
                      int quantity, MemberRank memberRank, OrderAmount amount, LocalDateTime acceptedAt) {
        this.orderNumber = orderNumber;
        this.customerName = customerName;
        this.itemCode = itemCode;
        this.itemName = itemName;
        this.quantity = quantity;
        this.memberRank = memberRank;
        this.amount = amount;
        this.acceptedAt = acceptedAt;
    }

    /** 受注番号 (例: {@code ORD-20250401-001})。 */
    public String getOrderNumber() {
        return orderNumber;
    }

    public String getCustomerName() {
        return customerName;
    }

    public String getItemCode() {
        return itemCode;
    }

    public String getItemName() {
        return itemName;
    }

    public int getQuantity() {
        return quantity;
    }

    public MemberRank getMemberRank() {
        return memberRank;
    }

    /** 金額の内訳。 */
    public OrderAmount getAmount() {
        return amount;
    }

    /** 受付日時。 */
    public LocalDateTime getAcceptedAt() {
        return acceptedAt;
    }

    /** 画面表示用の受付日時。 */
    public String getAcceptedAtText() {
        return acceptedAt == null ? "" : DISPLAY.format(acceptedAt);
    }

    @Override
    public String toString() {
        return orderNumber + " " + customerName + " " + itemCode + " × " + quantity
                + " = " + (amount == null ? "-" : amount.getTotal() + "円");
    }
}
