package com.example.servletsample.samples.advanced;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;

/**
 * 【サンプル】フィルタの通過記録を JSON で返す API。
 *
 * <p>この URL も {@code /samples/advanced/filter/*} に含まれるので、
 * 画面と同じ 3 つのフィルタを通ります。</p>
 *
 * <h2>2 回に分けて呼ぶ理由</h2>
 * <p>フィルタの<b>後処理</b>は、Servlet が応答を書き終えたあとに動きます。
 * つまり「自分の通過記録の全体」を、自分の応答に含めることはできません。
 * そこで画面側は次の 2 回に分けて呼んでいます。</p>
 *
 * <ol>
 *   <li>{@code GET /samples/advanced/filter/api} …
 *       ふつうにリクエストを 1 本流す。応答ヘッダ {@code X-Request-Id} にリクエスト ID が入る</li>
 *   <li>{@code GET /samples/advanced/filter/api?trace=R-000003} …
 *       ①の記録を取り出す。まだ保管し終えていなければ {@code pending} を返すので、
 *       画面側は少し待って呼び直す</li>
 * </ol>
 *
 * <h2>受け付けるパラメータ</h2>
 * <table border="1">
 *   <caption>クエリパラメータ</caption>
 *   <tr><th>名前</th><th>意味</th></tr>
 *   <tr><td>{@code trace}</td><td>取り出したい記録のリクエスト ID</td></tr>
 *   <tr><td>{@code blocked}</td>
 *       <td>{@code 1} なら {@link AccessCheckFilter} が 403 で止める (この Servlet は動かない)</td></tr>
 * </table>
 */
@WebServlet(name = "filterSampleApi", urlPatterns = {"/samples/advanced/filter/api"})
public class FilterApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** この API の URL (コンテキストルートからのパス)。 */
    static final String PATH = "/samples/advanced/filter/api";

    /** 画面の記録に出す名前。 */
    static final String NAME = "FilterApiServlet";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        FilterTrace current = FilterTrace.of(request);
        String wanted = request.getParameter("trace");

        if (wanted == null || wanted.isBlank()) {
            // ① ふつうのリクエスト。記録に残るのはこの呼び出し
            if (current != null) {
                current.run(NAME, "JSON を書き出した");
            }
            Json.write(response, Json.object()
                    .put("ok", true)
                    .put("requestId", current == null ? null : current.getId())
                    .put("message", "フィルタを通ってここまで来ました。"));
            return;
        }

        // ② 記録の取り出し
        if (current != null) {
            current.run(NAME, "記録 " + wanted + " を取り出した");
        }
        FilterTrace found = FilterTraceStore.find(wanted.strip());
        if (found == null || !found.isFinished()) {
            // いちばん外側のフィルタの後処理が終わるまで、ほんのわずかに間があります。
            // 「まだ」と正直に返し、画面側に呼び直してもらいます
            Json.write(response, Json.object()
                    .put("ok", false)
                    .put("pending", true)
                    .put("message", "記録はまだ保管されていません。"));
            return;
        }

        Json.write(response, toJson(found));
    }

    /** 記録を JSON に組み立てる。 */
    static Json.JsonObject toJson(FilterTrace trace) {
        Json.JsonArray steps = Json.array();
        for (FilterTrace.Step step : trace.getSteps()) {
            steps.add(Json.object()
                    .put("seq", step.getSeq())
                    .put("phase", step.getPhase().getLabel())
                    .put("mark", step.getPhase().getMark())
                    .put("name", step.getName())
                    .put("message", step.getMessage())
                    .put("depth", step.getDepth()));
        }
        return Json.object()
                .put("ok", true)
                .put("id", trace.getId())
                .put("method", trace.getMethod())
                .put("uri", trace.getUri())
                .put("elapsedMillis", trace.getElapsedMillis())
                .put("steps", steps);
    }
}
