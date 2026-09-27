package com.example.servletsample.samples.test;

import java.io.IOException;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.samples.test.EstimateCalculator.Estimate;

/**
 * 【サンプル】{@link LegacyEstimateServlet} を直した後の Servlet。
 *
 * <p>やっていることは元と同じで、画面に渡す値の名前も同じです。変えたのは形だけです。</p>
 * <ul>
 *   <li>計算を {@link EstimateCalculator} に切り出した (Servlet を動かさずにテストできる)</li>
 *   <li>時計を外から受け取るようにした (テストで見積番号を固定できる)</li>
 * </ul>
 *
 * <p>入力の受け取り方 ({@link Integer#parseInt}) は、あえて元のままです。
 * カンマ付きの金額や空欄で例外 (画面では 500 エラー) になるのは褒められた動きではありませんが、
 * 直すなら<b>整理とは別の変更として</b>行います (入力チェックを足すと画面の動きが変わるため)。</p>
 */
@WebServlet(name = "estimate", urlPatterns = {"/samples/test/characterization-test/refactored"})
public class EstimateServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    static final String VIEW = "/WEB-INF/views/samples/test/characterization-test.jsp";

    private static final DateTimeFormatter ESTIMATE_NO = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final transient Clock clock;

    /** Tomcat が使うコンストラクタ (システム時計)。 */
    public EstimateServlet() {
        this(Clock.systemDefaultZone());
    }

    /** テストから止めた時計を渡すためのコンストラクタ。 */
    EstimateServlet(Clock clock) {
        this.clock = clock;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/samples/test/characterization-test");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Estimate estimate = EstimateCalculator.calculate(
                request.getParameter("pref"),
                Integer.parseInt(request.getParameter("price")),
                Integer.parseInt(request.getParameter("qty")),
                Integer.parseInt(request.getParameter("weight")),
                "1".equals(request.getParameter("member")));

        request.setAttribute("amount", estimate.getAmount());
        request.setAttribute("ship", estimate.getShip());
        request.setAttribute("discount", estimate.getDiscount());
        request.setAttribute("tax", estimate.getTax());
        request.setAttribute("total", estimate.getTotal());
        request.setAttribute("estimateNo", "EST-" + LocalDateTime.now(clock).format(ESTIMATE_NO));
        forward(request, response, VIEW);
    }
}
