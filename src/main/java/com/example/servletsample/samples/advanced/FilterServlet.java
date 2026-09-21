package com.example.servletsample.samples.advanced;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】フィルタ (Filter) で共通処理をはさむ。
 *
 * <p>この Servlet 自体は、ごく普通に画面を出すだけです。
 * <b>フィルタのことを何も知りません</b>。それがフィルタの利点で、
 * ログ出力も権限チェックも、Servlet を 1 行も直さずに後から足したり外したりできます。</p>
 *
 * <pre>{@code
 * ブラウザ
 *   ↓
 * ① RequestIdFilter   行き : リクエスト ID を採番する
 *   ↓
 * ② AccessLogFilter   行き : 開始時刻を控える
 *   ↓
 * ③ AccessCheckFilter 行き : 通してよいか判断する (駄目ならここで折り返す)
 *   ↓
 * ■ FilterServlet     画面を組み立てて JSP へ転送する
 *   ↑
 * ③ AccessCheckFilter 帰り
 *   ↑
 * ② AccessLogFilter   帰り : 処理時間とステータスをログに出す
 *   ↑
 * ① RequestIdFilter   帰り : 記録を保管する
 *   ↓
 * ブラウザ
 * }</pre>
 *
 * <p>フィルタの登録は {@code web.xml} で行っています
 * ({@code <filter>} と {@code <filter-mapping>})。
 * 順番は {@code <filter-mapping>} を書いた順に決まります。</p>
 *
 * <h2>画面に出している記録について</h2>
 * <p>画面を組み立てているのは <b>③ の内側</b>なので、
 * その時点で分かるのは「行き」の分だけです。
 * 「帰り」まで含めた 1 往復を見せるために、
 * フィルタは記録を {@link FilterTraceStore} へ預け、
 * 画面はあとから {@link FilterApiServlet} に取りに行く形にしています。</p>
 */
@WebServlet(name = "filterSample", urlPatterns = {"/samples/advanced/filter"})
public class FilterServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/advanced/filter.jsp";

    /** 画面の記録に出す名前。 */
    static final String NAME = "FilterServlet";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // フィルタが作った記録に、Servlet 本体の通過も書き足す。
        // (フィルタが登録されていなければ null。無くても動くようにしておく)
        FilterTrace trace = FilterTrace.of(request);
        if (trace != null) {
            trace.run(NAME, "画面を組み立てて JSP へ転送した");
        }

        request.setAttribute("apiPath", request.getContextPath() + FilterApiServlet.PATH);
        forward(request, response, VIEW);
    }
}
