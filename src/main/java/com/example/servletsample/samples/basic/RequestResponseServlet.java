package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.util.Collections;
import java.util.Enumeration;
import java.util.LinkedHashMap;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】リクエストとレスポンスの中身を見る。
 *
 * <p>Servlet がやっていることは、つきつめると
 * <b>「HTTP のリクエストを読んで、HTTP のレスポンスを組み立てる」</b>だけです。
 * {@code HttpServletRequest} と {@code HttpServletResponse} は、
 * その HTTP を Java から触れるようにしたものです。</p>
 *
 * <pre>
 * GET /samples/basic/request-response?x=1 HTTP/1.1     ← リクエスト行
 * Host: localhost:8080                                 ← ヘッダ
 * User-Agent: Mozilla/5.0 ...                             (何行でも続く)
 * Accept-Language: ja,en-US;q=0.9
 *                                                      ← 空行
 * (本文。GET では普通ありません)
 * </pre>
 *
 * <pre>
 * HTTP/1.1 200 OK                                      ← ステータス行
 * Content-Type: text/html;charset=UTF-8                ← ヘッダ
 * Content-Length: 12345
 *                                                      ← 空行
 * &lt;!DOCTYPE html&gt;...                                   ← 本文
 * </pre>
 *
 * <p>この Servlet は、届いたリクエスト行とヘッダを画面に並べます。
 * レスポンス側 (ステータスコードとヘッダ) を組み立てて返すのは
 * {@link RequestResponseApiServlet} です。</p>
 */
@WebServlet(name = "requestResponse", urlPatterns = {"/samples/basic/request-response"})
public class RequestResponseServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/basic/request-response.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("requestLine", requestLine(request));
        request.setAttribute("facts", facts(request));
        request.setAttribute("headers", headers(request));
        forward(request, response, VIEW);
    }

    /** リクエストの 1 行目を組み立て直す (ブラウザが送ってきたのはこの形です)。 */
    static String requestLine(HttpServletRequest request) {
        String query = request.getQueryString();
        return request.getMethod() + " " + request.getRequestURI()
                + (query == null ? "" : "?" + query)
                + " " + request.getProtocol();
    }

    /**
     * リクエストから取れる代表的な値。
     *
     * <p>「どのメソッドが何を返すか」は覚えるより、並べて見比べた方が早いので、
     * メソッド名をそのまま見出しにしています。</p>
     */
    private static Map<String, String> facts(HttpServletRequest request) {
        Map<String, String> facts = new LinkedHashMap<>();
        facts.put("getMethod()", request.getMethod());
        facts.put("getRequestURL()", String.valueOf(request.getRequestURL()));
        facts.put("getRequestURI()", request.getRequestURI());
        facts.put("getContextPath()", quoteIfEmpty(request.getContextPath()));
        facts.put("getServletPath()", quoteIfEmpty(request.getServletPath()));
        facts.put("getPathInfo()", request.getPathInfo() == null ? "null" : request.getPathInfo());
        facts.put("getQueryString()",
                request.getQueryString() == null ? "null" : request.getQueryString());
        facts.put("getProtocol()", request.getProtocol());
        facts.put("getScheme()", request.getScheme());
        facts.put("isSecure()", String.valueOf(request.isSecure()));
        facts.put("getServerName()", request.getServerName());
        facts.put("getServerPort()", String.valueOf(request.getServerPort()));
        facts.put("getRemoteAddr()", request.getRemoteAddr());
        facts.put("getLocale()", String.valueOf(request.getLocale()));
        facts.put("getContentType()",
                request.getContentType() == null ? "null" : request.getContentType());
        facts.put("getContentLengthLong()", String.valueOf(request.getContentLengthLong()));
        return facts;
    }

    /**
     * リクエストヘッダを名前順ではなく<b>届いた順</b>に集める。
     *
     * <p>同じ名前のヘッダは何度でも現れてよい決まりなので、
     * {@code getHeader} (最初の 1 つ) ではなく {@code getHeaders} で全部取り、
     * カンマでつないでいます。</p>
     */
    private static Map<String, String> headers(HttpServletRequest request) {
        Map<String, String> headers = new LinkedHashMap<>();
        Enumeration<String> names = request.getHeaderNames();
        if (names == null) {
            return headers;
        }
        for (String name : Collections.list(names)) {
            headers.put(name, String.join(", ", Collections.list(request.getHeaders(name))));
        }
        return headers;
    }

    /** 空文字だと画面で消えてしまうので、見えるようにする。 */
    private static String quoteIfEmpty(String value) {
        return value == null || value.isEmpty() ? "\"\" (空文字)" : value;
    }
}
