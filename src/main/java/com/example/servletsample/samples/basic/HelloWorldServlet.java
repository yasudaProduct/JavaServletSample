package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】Servlet から JSP へ値を渡す、もっとも基本的な形。
 *
 * <p>処理の流れ</p>
 * <ol>
 *   <li>ブラウザが {@code /samples/basic/hello-world} をリクエストする</li>
 *   <li>この Servlet の {@code doGet} が呼ばれる</li>
 *   <li>表示したい値を {@code request.setAttribute} で入れる (リクエストスコープ)</li>
 *   <li>JSP へ {@code forward} し、JSP が {@code ${...}} で値を取り出して HTML を作る</li>
 * </ol>
 */
@WebServlet(name = "helloWorld", urlPatterns = {"/samples/basic/hello-world"})
public class HelloWorldServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 画面から ?name=... で名前を受け取る (未指定なら「世界」)
        String name = request.getParameter("name");
        if (name == null || name.trim().isEmpty()) {
            name = "世界";
        }

        // リクエストスコープに値を入れる → JSP では ${message} で参照できる
        request.setAttribute("message", "こんにちは、" + name + "！");
        request.setAttribute("now", LocalDateTime.now().format(FORMATTER));
        request.setAttribute("inputName", name);

        // /WEB-INF/views/samples/basic/hello-world.jsp へ転送する
        forward(request, response, "/WEB-INF/views/samples/basic/hello-world.jsp");
    }
}
