package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@code <jsp:useBean>} で使う {@link OrderBean} のテスト。
 *
 * <p>ここで確かめたいのは「<b>画面から変な値が来ても落ちないこと</b>」です。
 * {@code <jsp:setProperty>} の自動変換に任せると、数字でない値が来たときに
 * 例外になって 500 エラーの画面になってしまうため、
 * このクラスは文字列で受け取って自分で変換しています。</p>
 */
class OrderBeanTest {

    @Test
    @DisplayName("作った直後は「未選択・0 個・通常便」")
    void defaults() {
        OrderBean order = new OrderBean();

        assertEquals("", order.getProductCode());
        assertEquals("（未選択）", order.getProductLabel());
        assertEquals(0, order.getQuantityValue());
        assertFalse(order.isExpress());
    }

    @Test
    @DisplayName("商品コードから名前を引ける (知らないコードは未選択)")
    void productLabel() {
        OrderBean order = new OrderBean();

        order.setProductCode("P-01");
        assertEquals("ボールペン（黒）", order.getProductLabel());

        order.setProductCode("P-99");
        assertEquals("（未選択）", order.getProductLabel());
    }

    @Test
    @DisplayName("前後の空白は落とす / null は空文字にする")
    void stripsInput() {
        OrderBean order = new OrderBean();

        order.setProductCode(" P-02 ");
        assertEquals("P-02", order.getProductCode());

        order.setQuantity(null);
        assertEquals("", order.getQuantity());
    }

    @Test
    @DisplayName("数量が数字でなくても落ちない (0 として扱う)")
    void quantityIsParsedSafely() {
        OrderBean order = new OrderBean();

        order.setQuantity("3");
        assertEquals(3, order.getQuantityValue());

        order.setQuantity("abc");
        assertEquals(0, order.getQuantityValue(), "int のプロパティなら例外になる値");

        order.setQuantity("");
        assertEquals(0, order.getQuantityValue());

        order.setQuantity("-5");
        assertEquals(0, order.getQuantityValue(), "下限は 0");

        order.setQuantity("150");
        assertEquals(99, order.getQuantityValue(), "上限は 99");
    }

    @Test
    @DisplayName("要約はサーバ側で決めた値だけで組み立てる")
    void summary() {
        OrderBean order = new OrderBean();
        order.setProductCode("P-02");
        order.setQuantity("2");
        order.setExpress(true);
        order.setChannel("Web 画面");

        assertEquals("ノート A5 を 2 個（お急ぎ便） / 受付: Web 画面", order.getSummary());
    }

    @Test
    @DisplayName("要約には画面から来た文字列がそのまま入らない")
    void summaryDoesNotEchoInput() {
        OrderBean order = new OrderBean();
        // 一覧に無いコードなので「（未選択）」に置き換わる。
        // <jsp:getProperty> はエスケープしないため、ここが素通しだと穴になる
        order.setProductCode("<script>alert(1)</script>");
        order.setQuantity("<script>");

        assertFalse(order.getSummary().contains("<"), "要約: " + order.getSummary());
    }

    @Test
    @DisplayName("選択肢は 3 件 (JSP からは ${order.products} で読む)")
    void products() {
        OrderBean order = new OrderBean();

        assertEquals(3, order.getProducts().size());
        assertTrue(order.getProducts().containsKey("P-01"));
    }
}
