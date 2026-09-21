package com.example.servletsample.samples.advanced;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】時間のかかる処理を非同期で動かす。
 *
 * <p>この Servlet は画面を出すだけです。非同期で動くのは
 * {@link AsyncApiServlet} の方で、画面はそこへ {@code fetch} で問い合わせます。</p>
 *
 * <p>画面を組み立てたスレッドの名前も渡しています。
 * ブラウザの表示と API の応答を見比べると、
 * <b>どのスレッドが何をしたか</b>が分かります。</p>
 */
@WebServlet(name = "asyncSample", urlPatterns = {"/samples/advanced/async"})
public class AsyncServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/advanced/async.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("apiPath", request.getContextPath() + AsyncApiServlet.PATH);
        request.setAttribute("pageThread", Thread.currentThread().getName());
        request.setAttribute("poolSize", AsyncWorkerPool.POOL_SIZE);
        request.setAttribute("queueCapacity", AsyncWorkerPool.QUEUE_CAPACITY);
        request.setAttribute("defaultMillis", AsyncApiServlet.DEFAULT_WORK_MILLIS);
        request.setAttribute("maxMillis", AsyncApiServlet.MAX_WORK_MILLIS);

        forward(request, response, VIEW);
    }
}
