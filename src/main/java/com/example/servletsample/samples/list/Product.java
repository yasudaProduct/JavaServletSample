package com.example.servletsample.samples.list;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * 一覧・検索サンプルで使う商品 1 件分。
 *
 * <p>データベースの {@code products} テーブル 1 行に対応します。</p>
 */
public final class Product {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy/MM/dd");

    private final long id;
    private final String code;
    private final String name;
    private final String category;
    private final int price;
    private final int stock;
    private final LocalDate updatedAt;

    Product(long id, String code, String name, String category, int price, int stock, LocalDate updatedAt) {
        this.id = id;
        this.code = code;
        this.name = name;
        this.category = category;
        this.price = price;
        this.stock = stock;
        this.updatedAt = updatedAt;
    }

    public long getId() {
        return id;
    }

    /** 商品コード。例: {@code P-0007} */
    public String getCode() {
        return code;
    }

    public String getName() {
        return name;
    }

    public String getCategory() {
        return category;
    }

    public int getPrice() {
        return price;
    }

    public int getStock() {
        return stock;
    }

    public LocalDate getUpdatedAt() {
        return updatedAt;
    }

    /** 在庫があるか。 */
    public boolean isInStock() {
        return stock > 0;
    }

    /** 画面に出す更新日 (JSTL の fmt:formatDate は LocalDate を扱えないため Java 側で整形する)。 */
    public String getUpdatedAtText() {
        return updatedAt == null ? "" : updatedAt.format(FORMATTER);
    }

    @Override
    public String toString() {
        return code + " " + name;
    }
}
