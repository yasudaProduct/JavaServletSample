package com.example.servletsample.samples.test;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】「doPost から DB まで通してテストする」ページの画面。
 *
 * <p>注文サンプル ({@link OrderServlet}) が書き込むテーブルの、今の中身を表示します。
 * {@code OrderServletDbTest} が SQL で確かめているのは、この 2 つのテーブルです。</p>
 *
 * <p>注文そのものは「Servlet を単体テストする」ページのフォームから行います
 * (同じ DB を見ているので、注文するとこの画面の表が変わります)。</p>
 */
@WebServlet(name = "servletDbTestDemo", urlPatterns = {"/samples/test/servlet-db-test"})
public class ServletDbTestDemoServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/test/servlet-db-test.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        OrderRepository repository = new JdbcOrderRepository();
        request.setAttribute("items", repository.findItems());
        request.setAttribute("orders", repository.findRecentOrders(10));
        forward(request, response, VIEW);
    }
}
