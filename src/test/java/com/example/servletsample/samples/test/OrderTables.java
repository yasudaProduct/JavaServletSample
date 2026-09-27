package com.example.servletsample.samples.test;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import com.example.servletsample.common.Database;

/**
 * 【サンプル】DB を使うテストのための補助 (データの準備・確認・後片付け)。
 *
 * <p>{@link OrderServletDbTest} から使います。
 * テスト対象のクラス ({@link JdbcOrderRepository}) を通さず、<b>自分で SQL を書いて</b>
 * テーブルを直接読み書きしているのがポイントです。
 * テスト対象の読み込み処理を使って確認すると、書き込みと読み込みが同じように間違っていたとき
 * (列を取り違えている、など) に気付けません。</p>
 *
 * <p><b>現場で使うときは</b>、接続の取り方 ({@link Database#getConnection()}) を
 * そのシステムのテスト用 DB への接続に置き換えます。</p>
 */
final class OrderTables {

    private OrderTables() {
    }

    /** 注文テーブルから読み出した 1 行。テストで比べやすいよう、列をそのまま持たせる。 */
    record OrderRow(String orderNumber, String customerName, String itemCode, int quantity,
                    String memberRank, int subtotal, int bulkDiscount, int memberDiscount,
                    int shippingFee, int tax, LocalDateTime acceptedAt) {

        /** 請求金額 (値引き後の小計 + 送料 + 消費税)。 */
        int total() {
            return subtotal - bulkDiscount - memberDiscount + shippingFee + tax;
        }
    }

    /** 両方のテーブルを空にする。テストの前に呼び、前のテストの残りを消す。 */
    static void clear() throws SQLException {
        try (Connection connection = Database.getConnection();
             Statement statement = connection.createStatement()) {
            statement.executeUpdate("DELETE FROM order_entries");
            statement.executeUpdate("DELETE FROM order_items");
        }
    }

    /** 商品を 1 件入れる。テストに必要な商品だけを、必要な在庫で用意する。 */
    static void insertItem(String code, String name, int unitPrice, int stock) throws SQLException {
        String sql = "INSERT INTO order_items (code, name, unit_price, stock, sort_order) VALUES (?, ?, ?, ?, ?)";
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, code);
            statement.setString(2, name);
            statement.setInt(3, unitPrice);
            statement.setInt(4, stock);
            statement.setInt(5, 0);
            statement.executeUpdate();
        }
    }

    /** 商品の今の在庫数。 */
    static int stockOf(String code) throws SQLException {
        String sql = "SELECT stock FROM order_items WHERE code = ?";
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, code);
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) {
                    throw new AssertionError("商品がありません: " + code);
                }
                return rs.getInt("stock");
            }
        }
    }

    /** 登録された注文を、登録した順に全部読み出す。 */
    static List<OrderRow> findOrders() throws SQLException {
        String sql = """
                SELECT order_number, customer_name, item_code, quantity, member_rank,
                       subtotal, bulk_discount, member_discount, shipping_fee, tax, accepted_at
                  FROM order_entries
                 ORDER BY id
                """;
        List<OrderRow> rows = new ArrayList<>();
        try (Connection connection = Database.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                rows.add(new OrderRow(
                        rs.getString("order_number"),
                        rs.getString("customer_name"),
                        rs.getString("item_code"),
                        rs.getInt("quantity"),
                        rs.getString("member_rank"),
                        rs.getInt("subtotal"),
                        rs.getInt("bulk_discount"),
                        rs.getInt("member_discount"),
                        rs.getInt("shipping_fee"),
                        rs.getInt("tax"),
                        rs.getTimestamp("accepted_at").toLocalDateTime()));
            }
        }
        return rows;
    }
}
