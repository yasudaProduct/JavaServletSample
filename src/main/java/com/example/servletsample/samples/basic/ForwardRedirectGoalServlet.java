package com.example.servletsample.samples.basic;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】forward と redirect の違い : redirect 版の遷移先。
 *
 * <p>{@link ForwardRedirectServlet} が {@code sendRedirect} を返したあと、
 * <b>ブラウザが改めて GET してくる</b>のがこの Servlet です。
 * POST のときとは別のリクエストなので、
 * {@code request.setAttribute} で入れた値は入っていません。</p>
 *
 * <p>そのことを画面で確かめられるように、
 * ここでは<b>あえて受付番号を入れ直さず</b>に JSP へ渡しています。
 * 受付番号はクエリ文字列 ({@code ?receipt=...}) から受け取ります。</p>
 *
 * <p>URL を完全一致 ({@code /samples/basic/forward-redirect/goal}) で割り当てているため、
 * 前方一致の {@code /samples/*} ({@code SampleDispatcherServlet}) より
 * 優先してこの Servlet が呼ばれます。</p>
 */
@WebServlet(name = "forwardRedirectGoal", urlPatterns = {ForwardRedirectServlet.GOAL_PATH})
public class ForwardRedirectGoalServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 「redirect を受けてブラウザが取りに来た」ことを画面に伝えるための目印。
        // forward 版ではこの Servlet を通らず、POST を処理した Servlet が
        // 直接 JSP へ処理を渡すため、この値は "forward" になっています。
        request.setAttribute("arrivedBy", "redirect");

        // 表示そのものは forward 版とまったく同じ JSP が行います。
        // (この forward によって、JSP からは javax.servlet.forward.request_uri が
        //  このページの URL として見えるようになります)
        forward(request, response, ForwardRedirectServlet.GOAL_VIEW);
    }
}
