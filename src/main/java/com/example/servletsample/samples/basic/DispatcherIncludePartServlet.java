package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.util.Map;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】呼ばれ方を報告するだけの「部品」。
 *
 * <p>ブラウザから直接開いても、{@link DispatcherIncludeDemoServlet} から
 * forward / include されても、同じこの Servlet が動きます。
 * <b>自分がどう呼ばれたかを書き出す</b>ので、3 通りを見比べられます。</p>
 *
 * <p>include されたときは、ステータスコードやヘッダを変えても<b>無視されます</b>。
 * 差し込まれている側なので、レスポンス全体の話は呼び出し元が決めるからです。</p>
 */
@WebServlet(name = "dispatcherIncludePart", urlPatterns = {"/samples/basic/dispatcher-include/part"})
public class DispatcherIncludePartServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        DispatcherAttributes.Kind kind = DispatcherAttributes.kindOf(request::getAttribute);

        StringBuilder report = new StringBuilder();
        report.append("--- ここから部品 (DispatcherIncludePartServlet) ---\n");
        report.append("呼ばれ方              : ").append(kind.getLabel()).append('\n');
        report.append("getRequestURI()       : ").append(request.getRequestURI()).append('\n');
        report.append("getServletPath()      : ").append(request.getServletPath()).append('\n');

        // 呼び出し元が request スコープに入れた値は、そのまま読めます。
        // 部品に値を渡すときの、いちばん基本的なやり方です
        report.append("呼び出し元からの値     : ")
                .append(String.valueOf(request.getAttribute("messageFromCaller"))).append('\n');

        if (kind == DispatcherAttributes.Kind.INCLUDED) {
            append(report, "include の目印", DispatcherAttributes.collect(
                    DispatcherAttributes.INCLUDE_KEYS, request::getAttribute));
        } else if (kind == DispatcherAttributes.Kind.FORWARDED) {
            append(report, "forward の目印", DispatcherAttributes.collect(
                    DispatcherAttributes.FORWARD_KEYS, request::getAttribute));
        } else {
            report.append("目印                  : ありません（直接呼ばれたので）\n");
        }

        report.append("--- ここまで部品 ---\n");

        // include されているときは、この setContentType も無視されます
        response.setContentType("text/plain; charset=UTF-8");
        response.getWriter().write(report.toString());
    }

    private static void append(StringBuilder report, String title, Map<String, String> values) {
        report.append(title).append("\n");
        for (Map.Entry<String, String> entry : values.entrySet()) {
            report.append("  ").append(entry.getKey()).append(" = ")
                    .append(entry.getValue()).append('\n');
        }
    }
}
