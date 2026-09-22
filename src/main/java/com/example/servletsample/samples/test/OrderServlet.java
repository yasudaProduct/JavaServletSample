package com.example.servletsample.samples.test;

import java.io.IOException;
import java.time.Clock;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.ValidationErrors;

/**
 * 【サンプル】注文を受け付ける Servlet。単体テストの対象にできる形にしてある。
 *
 * <h2>Servlet に書くこと / 書かないこと</h2>
 * <p>この {@code doPost} がやっているのは、次の 4 つだけです。</p>
 * <ol>
 *   <li>リクエストから値を取り出す ({@link OrderForm#from})</li>
 *   <li>入力の形を確かめる ({@link OrderForm#validate})</li>
 *   <li>サービスに頼む ({@link OrderService#place})</li>
 *   <li>結果に応じて画面を決める (forward か redirect か)</li>
 * </ol>
 * <p>金額の計算も在庫の判定もここには書きません。
 * <b>Servlet に業務ロジックを書くほど、テストに Servlet API が必要になります。</b>
 * 逆に言えば、この 4 つに絞れていれば Servlet のテストは
 * 「行き先が正しいか」「画面に渡す値が正しいか」を見るだけで済みます。</p>
 *
 * <h2>テストできるようにする仕掛け</h2>
 * <p>コンストラクタが 2 つあります。</p>
 * <ul>
 *   <li>引数なし … Tomcat が使う。本番用の {@link JdbcOrderRepository} とシステム時計を組み立てる</li>
 *   <li>{@link OrderService} を受け取るもの … テストが使う (同じパッケージから呼べる可視性)</li>
 * </ul>
 * <p>{@code doPost} の中で {@code new OrderService(new JdbcOrderRepository(), ...)} と
 * 書いてしまうと、Servlet のテストに必ず DB が付いてきます。
 * <b>組み立てる場所を入口の 1 か所に寄せておく</b>のがコツです。</p>
 */
@WebServlet(name = "orderServlet", urlPatterns = {"/samples/test/servlet-test"})
public class OrderServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    static final String VIEW = "/WEB-INF/views/samples/test/servlet-test.jsp";

    static final String PATH = "/samples/test/servlet-test";

    private final transient OrderService service;

    /** Tomcat が使うコンストラクタ (本番の組み立て)。 */
    public OrderServlet() {
        this(new OrderService(new JdbcOrderRepository(), Clock.systemDefaultZone()));
    }

    /** テストから偽物のサービスを渡すためのコンストラクタ。 */
    OrderServlet(OrderService service) {
        this.service = service;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Flash.consume(request);
        showForm(request, response, OrderForm.empty(), new ValidationErrors());
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if ("reset".equals(request.getParameter("action"))) {
            service.reset();
            Flash.set(request, "info", "初期化しました", "商品の在庫と注文履歴を元に戻しました。");
            response.sendRedirect(request.getContextPath() + PATH);
            return;
        }

        // ① 受け取る
        OrderForm form = OrderForm.from(request);

        // ② 形を確かめる
        ValidationErrors errors = form.validate();
        if (errors.hasErrors()) {
            // 入力値を持ったまま同じ画面へ戻す (forward。リダイレクトでは入力が消える)
            showForm(request, response, form, errors);
            return;
        }

        // ③ サービスに頼む
        OrderResult result = service.place(form.toRequest());
        if (!result.isSuccess()) {
            // 在庫不足など、形は正しいが受け付けられなかった場合。
            // 画面全体へのメッセージとして出す
            errors.addGlobal(result.getMessage());
            showForm(request, response, form, errors);
            return;
        }

        // ④ 成功したらリダイレクト (PRG パターン。再読み込みで二重注文させない)
        OrderEntry order = result.getOrder();
        Flash.set(request, "success", "注文を受け付けました",
                "受注番号 " + order.getOrderNumber() + " / 請求金額 "
                        + String.format("%,d", order.getAmount().getTotal()) + " 円");
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /** 画面に必要な値をそろえて JSP へ転送する。 */
    private void showForm(HttpServletRequest request, HttpServletResponse response,
                          OrderForm form, ValidationErrors errors)
            throws ServletException, IOException {

        request.setAttribute("form", form);
        request.setAttribute("errors", errors);
        request.setAttribute("items", service.findItems());
        request.setAttribute("orders", service.findRecentOrders(5));
        forward(request, response, VIEW);
    }
}
