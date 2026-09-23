package com.example.servletsample.samples.test;

import java.io.IOException;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】「テストダブル」ページの画面。
 *
 * <p>同じ {@link OrderService} を 2 通りの組み立て方で動かし、結果を並べて見せます。</p>
 * <table border="1">
 *   <caption>2 つの組み立て</caption>
 *   <tr><th></th><th>本番の組み立て</th><th>テストの組み立て</th></tr>
 *   <tr><th>データ置き場</th><td>{@link JdbcOrderRepository} (H2)</td>
 *       <td>{@link InMemoryOrderRepository} (メモリ)</td></tr>
 *   <tr><th>時計</th><td>システム時刻</td><td>2025-04-01 09:00:00 で固定</td></tr>
 * </table>
 *
 * <p>受注番号の日付が変わらないこと、何度実行しても同じ結果になることが、
 * テストで {@code assertEquals} を書けるということです。</p>
 *
 * <p>テスト用のリポジトリはセッションに持たせています
 * (他の人の操作の影響を受けずに、自分の分だけ在庫が減るようにするため)。</p>
 */
@WebServlet(name = "testDoubleDemo", urlPatterns = {"/samples/test/test-double"})
public class TestDoubleDemoServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/test/test-double.jsp";

    private static final String SESSION_KEY = "servletSample.testDouble.repository";

    /** テスト側で使う、止まった時計。 */
    private static final Clock FIXED_CLOCK =
            Clock.fixed(Instant.parse("2025-04-01T00:00:00Z"), ZoneId.of("Asia/Tokyo"));

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        show(request, response, null, null);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        OrderService realService = new OrderService(new JdbcOrderRepository(), Clock.systemDefaultZone());
        OrderService fakeService = new OrderService(fakeRepository(request), FIXED_CLOCK);

        if ("reset".equals(request.getParameter("action"))) {
            realService.reset();
            fakeService.reset();
            show(request, response, null, null);
            return;
        }

        OrderRequest orderRequest = new OrderRequest(
                Validators.strip(request.getParameter("customerName")),
                Validators.strip(request.getParameter("itemCode")),
                Validators.toInt(Validators.strip(request.getParameter("quantity"))).orElse(0),
                MemberRank.of(request.getParameter("memberRank")));

        // まったく同じ処理を、組み立ての違う 2 つのサービスに流す
        OrderResult realResult = realService.place(orderRequest);
        OrderResult fakeResult = fakeService.place(orderRequest);

        request.setAttribute("customerName", orderRequest.getCustomerName());
        request.setAttribute("itemCode", orderRequest.getItemCode());
        request.setAttribute("quantity", String.valueOf(orderRequest.getQuantity()));
        request.setAttribute("memberRank", orderRequest.getMemberRank().name());
        show(request, response, realResult, fakeResult);
    }

    /** 画面に必要な値をそろえる。 */
    private void show(HttpServletRequest request, HttpServletResponse response,
                      OrderResult realResult, OrderResult fakeResult)
            throws ServletException, IOException {

        OrderRepository real = new JdbcOrderRepository();
        OrderRepository fake = fakeRepository(request);

        request.setAttribute("realItems", real.findItems());
        request.setAttribute("fakeItems", fake.findItems());
        request.setAttribute("realOrders", real.findRecentOrders(3));
        request.setAttribute("fakeOrders", fake.findRecentOrders(3));
        request.setAttribute("realResult", realResult);
        request.setAttribute("fakeResult", fakeResult);
        request.setAttribute("saveCount", ((InMemoryOrderRepository) fake).getSaveCount());
        request.setAttribute("decreaseStockCount", ((InMemoryOrderRepository) fake).getDecreaseStockCount());
        request.setAttribute("ranks", MemberRank.values());
        forward(request, response, VIEW);
    }

    /** セッションに持っているテスト用リポジトリ (無ければ作る)。 */
    private static InMemoryOrderRepository fakeRepository(HttpServletRequest request) {
        HttpSession session = request.getSession();
        Object stored = session.getAttribute(SESSION_KEY);
        if (stored instanceof InMemoryOrderRepository) {
            return (InMemoryOrderRepository) stored;
        }
        InMemoryOrderRepository repository = new InMemoryOrderRepository();
        session.setAttribute(SESSION_KEY, repository);
        return repository;
    }
}
