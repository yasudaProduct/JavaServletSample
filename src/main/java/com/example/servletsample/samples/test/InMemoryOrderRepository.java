package com.example.servletsample.samples.test;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * 【サンプル】メモリ上で動く {@link OrderRepository}。テストダブル (フェイク) の実例。
 *
 * <p><b>テストダブル</b>とは、テストのときに本物の代わりに使う部品のことです。
 * 役割で名前が分かれています。</p>
 * <table border="1">
 *   <caption>テストダブルの種類</caption>
 *   <tr><th>スタブ (stub)</th><td>決まった値を返すだけのもの。「在庫 0 を返す」など</td></tr>
 *   <tr><th>フェイク (fake)</th><td>簡略版だが本当に動くもの。このクラスがこれ</td></tr>
 *   <tr><th>スパイ (spy)</th><td>呼ばれた回数や引数を記録して、あとで確かめられるもの</td></tr>
 *   <tr><th>モック (mock)</th><td>「こう呼ばれるはず」を先に宣言し、違えば失敗するもの</td></tr>
 * </table>
 *
 * <p>このクラスはフェイクであると同時に、呼び出し回数を数えているのでスパイでもあります
 * ({@link #getSaveCount()} / {@link #getDecreaseStockCount()})。
 * 「在庫不足のときに保存していないこと」のような
 * <b>“やっていないこと” の確認</b>は、記録が無いと書けません。</p>
 *
 * <p><b>置き場所について</b> : テスト専用の部品なので、本来は {@code src/test/java} に置きます。
 * このサンプルでは画面のデモからも動かしたいので {@code src/main/java} に置いています。
 * デモではセッションに入れて持ち回るため {@link Serializable} にしていますが、
 * テストで使うだけなら不要です。</p>
 */
public class InMemoryOrderRepository implements OrderRepository, Serializable {

    private static final long serialVersionUID = 1L;

    /** 商品コード → 商品。登録順を保ちたいので LinkedHashMap。 */
    private final Map<String, Item> items = new LinkedHashMap<>();

    private final List<OrderEntry> orders = new ArrayList<>();

    private int saveCount;
    private int decreaseStockCount;

    public InMemoryOrderRepository() {
        reset();
    }

    @Override
    public List<Item> findItems() {
        return new ArrayList<>(items.values());
    }

    @Override
    public Optional<Item> findItem(String code) {
        return Optional.ofNullable(code).map(items::get);
    }

    @Override
    public void decreaseStock(String itemCode, int quantity) {
        decreaseStockCount++;
        Item item = items.get(itemCode);
        if (item == null) {
            throw new IllegalStateException("商品がありません: " + itemCode);
        }
        items.put(itemCode, item.decreaseStock(quantity));
    }

    @Override
    public int countOrders() {
        return orders.size();
    }

    @Override
    public void save(OrderEntry order) {
        saveCount++;
        orders.add(order);
    }

    @Override
    public List<OrderEntry> findRecentOrders(int limit) {
        List<OrderEntry> copy = new ArrayList<>(orders);
        Collections.reverse(copy);
        return copy.subList(0, Math.min(limit, copy.size()));
    }

    @Override
    public void reset() {
        items.clear();
        for (Item item : OrderSampleData.initialItems()) {
            items.put(item.getCode(), item);
        }
        orders.clear();
        saveCount = 0;
        decreaseStockCount = 0;
    }

    // ------------------------------------------------------------------
    // ここから下はスパイとしての機能 (本物の実装には無い、テスト用の覗き窓)
    // ------------------------------------------------------------------

    /** {@link #save} が呼ばれた回数。 */
    public int getSaveCount() {
        return saveCount;
    }

    /** {@link #decreaseStock} が呼ばれた回数。 */
    public int getDecreaseStockCount() {
        return decreaseStockCount;
    }

    /** 在庫をテスト用に上書きする (「在庫 0 のとき」を作るため)。 */
    public void setStock(String itemCode, int stock) {
        Item item = items.get(itemCode);
        if (item == null) {
            throw new IllegalArgumentException("商品がありません: " + itemCode);
        }
        items.put(itemCode, new Item(item.getCode(), item.getName(), item.getUnitPrice(), stock));
    }
}
