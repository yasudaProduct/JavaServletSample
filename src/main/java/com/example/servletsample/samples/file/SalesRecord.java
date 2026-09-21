package com.example.servletsample.samples.file;

import java.time.LocalDate;
import java.util.List;

/**
 * CSV 出力のサンプルで使う売上明細 1 件。
 *
 * <p>デモ用のデータには<b>わざと厄介な値を混ぜてあります</b>。
 * 素直なデータだけで試すと、エスケープが要ることに気付けないためです。</p>
 *
 * <table border="1">
 *   <caption>混ぜてある厄介な値</caption>
 *   <tr><th>種類</th><th>例</th><th>エスケープしないとどうなるか</th></tr>
 *   <tr><td>区切り文字を含む</td><td>{@code ケーブル, 2m}</td><td>列がずれる</td></tr>
 *   <tr><td>ダブルクォートを含む</td><td>{@code 幅 12" モニタ}</td><td>囲みが壊れる</td></tr>
 *   <tr><td>改行を含む</td><td>{@code 至急\n要確認}</td><td>行が増える</td></tr>
 *   <tr><td>数式に見える</td><td>{@code =1+1}</td><td>Excel で式として実行される</td></tr>
 *   <tr><td>前後に空白</td><td>{@code "  余白あり  "}</td><td>読み込む側で落とされる</td></tr>
 *   <tr><td>負の数</td><td>{@code -500}</td><td>数式ガードで文字列にしてしまうと集計できない</td></tr>
 * </table>
 */
public final class SalesRecord {

    private final String orderNo;
    private final LocalDate orderDate;
    private final String customer;
    private final String productName;
    private final int quantity;
    private final int amount;
    private final String note;

    SalesRecord(String orderNo, LocalDate orderDate, String customer,
                String productName, int quantity, int amount, String note) {
        this.orderNo = orderNo;
        this.orderDate = orderDate;
        this.customer = customer;
        this.productName = productName;
        this.quantity = quantity;
        this.amount = amount;
        this.note = note;
    }

    /** 受注番号。 */
    public String getOrderNo() {
        return orderNo;
    }

    /** 受注日。 */
    public LocalDate getOrderDate() {
        return orderDate;
    }

    /** 取引先。 */
    public String getCustomer() {
        return customer;
    }

    /** 商品名。 */
    public String getProductName() {
        return productName;
    }

    /** 数量。 */
    public int getQuantity() {
        return quantity;
    }

    /** 金額。 */
    public int getAmount() {
        return amount;
    }

    /** 備考。 */
    public String getNote() {
        return note;
    }

    /** CSV の見出し行。 */
    public static List<String> headers() {
        return List.of("受注番号", "受注日", "取引先", "商品名", "数量", "金額", "備考");
    }

    /**
     * CSV の 1 行分の値。
     *
     * <p>日付を {@code toString()} ({@code 2026-04-01}) にしているのは、
     * <b>環境によって意味が変わらない形</b>だからです。
     * {@code 2026/04/01} や {@code 04/01/2026} は、
     * 読む人や国によって解釈が変わります (ISO 8601)。</p>
     */
    public List<Object> values() {
        return List.of(orderNo, orderDate.toString(), customer, productName, quantity, amount, note);
    }
}
