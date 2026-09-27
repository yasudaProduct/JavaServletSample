package com.example.servletsample.samples.test;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * 【サンプル】仕様化テストの題材にする「古い作り」の見積もり Servlet。
 *
 * <p><b>わざと、テストしにくく書いてあります。</b>現場でよく見かける形を再現したもので、
 * お手本ではありません。直した後の姿は {@link EstimateServlet} / {@link EstimateCalculator} です。</p>
 *
 * <ul>
 *   <li>入力の受け取り・送料の計算・画面の切り替えが、すべて {@code doPost} の中にある</li>
 *   <li>計算だけを呼び出す入口が無い (テストするには Servlet ごと動かすしかない)</li>
 *   <li>見積番号に現在時刻が入る (実行するたびに結果が変わる)</li>
 *   <li>仕様書が無く、境界の {@code <=} と {@code <} が正しいのかどうか誰にも分からない</li>
 * </ul>
 *
 * <p>このクラスは<b>書き換えずに</b>、{@code LegacyEstimateCharacterizationTest} と
 * {@code EstimateGoldenMasterTest} で今の動きを記録しています。</p>
 */
@WebServlet(name = "legacyEstimate", urlPatterns = {"/samples/test/characterization-test/legacy"})
public class LegacyEstimateServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        res.sendRedirect(req.getContextPath() + "/samples/test/characterization-test");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String pref = req.getParameter("pref");
        int price = Integer.parseInt(req.getParameter("price"));
        int qty = Integer.parseInt(req.getParameter("qty"));
        int weight = Integer.parseInt(req.getParameter("weight"));
        String member = req.getParameter("member");

        int amount = price * qty;
        int totalWeight = weight * qty;

        // 送料
        int ship = 0;
        if (pref.equals("北海道") || pref.equals("沖縄")) {
            if (totalWeight <= 2000) {
                ship = 1200;
            } else if (totalWeight < 5000) {
                ship = 1800;
            } else {
                ship = 2500;
            }
        } else {
            if (totalWeight <= 2000) {
                ship = 800;
            } else if (totalWeight <= 5000) {
                ship = 1100;
            } else {
                ship = 1600;
            }
        }

        // 送料無料
        if (member != null && member.equals("1")) {
            if (amount >= 5000) {
                ship = 0;
            }
        } else {
            if (amount > 10000) {
                ship = 0;
            }
        }
        // 2019/04 改定 沖縄は送料無料の対象外
        if (pref.equals("沖縄") && ship == 0) {
            ship = 1200;
        }

        // 会員割引 5%
        int discount = 0;
        if (member != null && member.equals("1")) {
            discount = amount * 5 / 100;
        }

        int tax = (amount - discount + ship) * 10 / 100;
        int total = amount - discount + ship + tax;

        String estimateNo = "EST-" + new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());

        req.setAttribute("amount", amount);
        req.setAttribute("ship", ship);
        req.setAttribute("discount", discount);
        req.setAttribute("tax", tax);
        req.setAttribute("total", total);
        req.setAttribute("estimateNo", estimateNo);
        req.getRequestDispatcher("/WEB-INF/views/samples/test/characterization-test.jsp").forward(req, res);
    }
}
