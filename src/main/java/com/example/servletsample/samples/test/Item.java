package com.example.servletsample.samples.test;

import java.io.Serializable;

/** 商品マスタ 1 件 (コード・名称・単価・在庫数)。 */
public final class Item implements Serializable {

    private static final long serialVersionUID = 1L;

    private final String code;
    private final String name;
    private final int unitPrice;
    private final int stock;

    public Item(String code, String name, int unitPrice, int stock) {
        this.code = code;
        this.name = name;
        this.unitPrice = unitPrice;
        this.stock = stock;
    }

    public String getCode() {
        return code;
    }

    public String getName() {
        return name;
    }

    public int getUnitPrice() {
        return unitPrice;
    }

    /** 残りの在庫数。 */
    public int getStock() {
        return stock;
    }

    /** 在庫を減らした新しい値を返す (この値オブジェクト自体は書き換えない)。 */
    public Item decreaseStock(int quantity) {
        return new Item(code, name, unitPrice, stock - quantity);
    }

    @Override
    public String toString() {
        return code + " " + name + " (" + unitPrice + "円 / 在庫" + stock + ")";
    }
}
