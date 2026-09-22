package com.example.servletsample.samples.test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.OptionalInt;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】「単体テストの基本」ページの画面。
 *
 * <p>{@link OrderPricing} を画面から呼んで、テストが押さえている境界値を
 * 自分の手で確かめられるようにしたものです。</p>
 *
 * <p>この Servlet 自体には見どころはありません。
 * 見てほしいのは {@link OrderPricing} と、そのテストである {@code OrderPricingTest} です。</p>
 */
@WebServlet(name = "pricingDemo", urlPatterns = {"/samples/test/unit-test-basics"})
public class PricingDemoServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/test/unit-test-basics.jsp";

    /**
     * 画面に並べる境界値の一覧。
     *
     * <p>{@code OrderPricingTest} が確かめているのと同じ条件です
     * (ルールが切り替わる「ちょうど」の前後)。</p>
     */
    private static final int[][] BOUNDARY_CASES = {
            // 単価,  数量
            {1000, 9},
            {1000, 10},
            {4999, 1},
            {5000, 1},
            {5200, 1},
            {333, 10},
    };

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String unitPriceText = Validators.strip(request.getParameter("unitPrice"));
        String quantityText = Validators.strip(request.getParameter("quantity"));
        String rankText = Validators.strip(request.getParameter("memberRank"));

        // 初期表示は代表的な値を入れておく
        if (unitPriceText.isEmpty() && quantityText.isEmpty()) {
            unitPriceText = "1200";
            quantityText = "3";
        }

        MemberRank rank = MemberRank.of(rankText);

        OptionalInt unitPrice = Validators.toInt(unitPriceText);
        OptionalInt quantity = Validators.toInt(quantityText);

        if (!unitPrice.isPresent() || !quantity.isPresent()) {
            request.setAttribute("error", "単価と数量は半角数字で入力してください。");
        } else {
            try {
                request.setAttribute("amount",
                        OrderPricing.calculate(unitPrice.getAsInt(), quantity.getAsInt(), rank));
            } catch (IllegalArgumentException e) {
                // 例外が出ることも仕様です (OrderPricingTest の assertThrows と同じ状況)。
                // 画面では 500 エラーにせず、何が起きたかを見せます。
                request.setAttribute("error",
                        "IllegalArgumentException : " + e.getMessage());
            }
        }

        request.setAttribute("unitPrice", unitPriceText);
        request.setAttribute("quantity", quantityText);
        request.setAttribute("memberRank", rank.name());
        request.setAttribute("ranks", Arrays.asList(MemberRank.values()));
        request.setAttribute("cases", boundaryCases(rank));
        forward(request, response, VIEW);
    }

    /** 境界値の一覧を計算する。 */
    private static List<Row> boundaryCases(MemberRank rank) {
        List<Row> rows = new ArrayList<>();
        for (int[] each : BOUNDARY_CASES) {
            rows.add(new Row(each[0], each[1], rank, OrderPricing.calculate(each[0], each[1], rank)));
        }
        return rows;
    }

    /** 画面の表 1 行分。 */
    public static final class Row {

        private final int unitPrice;
        private final int quantity;
        private final MemberRank memberRank;
        private final OrderAmount amount;

        Row(int unitPrice, int quantity, MemberRank memberRank, OrderAmount amount) {
            this.unitPrice = unitPrice;
            this.quantity = quantity;
            this.memberRank = memberRank;
            this.amount = amount;
        }

        public int getUnitPrice() {
            return unitPrice;
        }

        public int getQuantity() {
            return quantity;
        }

        public MemberRank getMemberRank() {
            return memberRank;
        }

        public OrderAmount getAmount() {
            return amount;
        }
    }
}
