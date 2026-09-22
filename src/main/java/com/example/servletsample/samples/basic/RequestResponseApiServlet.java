package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.OptionalInt;
import java.util.Set;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】レスポンスを組み立てて返す側。画面の fetch から呼ばれます。
 *
 * <h2>受け付けるパラメータ</h2>
 * <table border="1">
 *   <caption>クエリパラメータ</caption>
 *   <tr><th>名前</th><th>値</th><th>意味</th></tr>
 *   <tr><td>{@code status}</td><td>200 / 404 / 500 など</td><td>返すステータスコード</td></tr>
 *   <tr><td>{@code mode}</td><td>{@code setStatus} / {@code sendError}</td>
 *       <td>エラーの返し方。{@code sendError} はコンテナのエラーページに差し替わる</td></tr>
 *   <tr><td>{@code type}</td><td>{@code json} / {@code text} / {@code html}</td>
 *       <td>{@code Content-Type}。同じ中身でもブラウザでの見え方が変わる</td></tr>
 *   <tr><td>{@code note}</td><td>任意の文字列</td>
 *       <td>{@code X-Sample-Note} ヘッダに載せる (ヘッダに入れる前の掃除が要ります)</td></tr>
 * </table>
 *
 * <h2>setStatus と sendError</h2>
 * <p>どちらもステータスコードを返しますが、そのあとが違います。</p>
 * <ul>
 *   <li>{@code setStatus} … コードを決めるだけ。<b>本文は自分で書きます</b>。
 *       API のようにエラーも JSON で返したいときはこちら</li>
 *   <li>{@code sendError} … コンテナに任せます。{@code web.xml} の
 *       {@code <error-page>} に飛び、<b>本文は差し替えられます</b>。
 *       画面遷移のある普通のページはこちら</li>
 * </ul>
 * <p>Ajax で {@code sendError} を使うと、JSON を期待している画面に
 * エラーページの HTML が返ります。「非同期通信の基本」で扱っている落とし穴です。</p>
 */
@WebServlet(name = "requestResponseApi", urlPatterns = {"/samples/basic/request-response/api"})
public class RequestResponseApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /**
     * 画面から選べるステータスコード。
     *
     * <p><b>受け取った数値をそのまま返してはいけません。</b>
     * 画面から来た値で何でも返せるようにすると、思わぬ応答を作らされます。
     * デモであっても、使ってよいものを並べて許可制にします。</p>
     */
    public static final Set<Integer> ALLOWED_STATUSES = Collections.unmodifiableSet(
            new LinkedHashSet<>(Arrays.asList(
                    200, 201, 204, 302, 304, 400, 401, 403, 404, 405, 409, 500, 503)));

    /** {@code X-Sample-Note} に載せる文字数の上限。 */
    static final int NOTE_MAX_LENGTH = 60;

    /** リダイレクトのデモで返す行き先。 */
    private static final String REDIRECT_TO = "/samples/basic/request-response";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = parseStatus(request.getParameter("status"));
        String mode = "sendError".equals(request.getParameter("mode")) ? "sendError" : "setStatus";
        String type = contentTypeOf(request.getParameter("type"));

        // ------------------------------------------------------------------
        // 独自ヘッダ。名前は X- で始めるのが慣例 (正式な仕様には無い、という印)
        // ------------------------------------------------------------------
        response.setHeader("X-Sample-Mode", mode);
        String note = sanitizeHeaderValue(request.getParameter("note"));
        if (!note.isEmpty()) {
            response.setHeader("X-Sample-Note", note);
        }
        // 毎回サーバに聞き直してほしいことを伝える (ブラウザにためさせない)
        response.setHeader("Cache-Control", "no-store");

        // ------------------------------------------------------------------
        // リダイレクト。Location ヘッダが無い 302 は、ブラウザから見ると行き先不明
        // ------------------------------------------------------------------
        if (status == HttpServletResponse.SC_FOUND) {
            response.sendRedirect(request.getContextPath() + REDIRECT_TO);
            return;
        }

        // ------------------------------------------------------------------
        // エラーをコンテナに任せる。web.xml の <error-page> に差し替えられるので、
        // ここで本文を書いても出てきません
        // ------------------------------------------------------------------
        if ("sendError".equals(mode) && status >= 400) {
            response.sendError(status, "デモのために " + status + " を返しました");
            return;
        }

        response.setStatus(status);

        // 204 (No Content) と 304 (Not Modified) は本文を持てない決まりです。
        // 書いてもコンテナが捨てるので、はじめから書きません
        if (status == HttpServletResponse.SC_NO_CONTENT
                || status == HttpServletResponse.SC_NOT_MODIFIED) {
            return;
        }

        if (type.startsWith("application/json")) {
            Json.write(response, Json.object()
                    .put("status", status)
                    .put("mode", mode)
                    .put("message", "setStatus で " + status + " を返しました。本文は自分で書いています"));
            return;
        }

        // Content-Type は getWriter() より前に決めること。あとから変えても効きません
        response.setContentType(type);
        if (type.startsWith("text/html")) {
            response.getWriter().write("<p>Content-Type が <b>text/html</b> なので、"
                    + "ブラウザはタグとして解釈します。</p>");
        } else {
            response.getWriter().write("Content-Type が text/plain なので、"
                    + "<p>タグも文字として</p> そのまま見えます。");
        }
    }

    /**
     * 画面から来たステータスコードを、使ってよいものだけに絞る。
     *
     * @return 許可されたコード。読めない値や許可していない値は 200
     */
    static int parseStatus(String value) {
        OptionalInt status = Validators.toInt(value);
        if (status.isPresent() && ALLOWED_STATUSES.contains(status.getAsInt())) {
            return status.getAsInt();
        }
        return HttpServletResponse.SC_OK;
    }

    /** 画面から来た種類を {@code Content-Type} に直す。知らない値は JSON。 */
    static String contentTypeOf(String type) {
        if ("text".equals(type)) {
            return "text/plain; charset=UTF-8";
        }
        if ("html".equals(type)) {
            return "text/html; charset=UTF-8";
        }
        return "application/json; charset=UTF-8";
    }

    /**
     * ヘッダに載せる値から、載せてはいけない文字を落とす。
     *
     * <p>HTTP のヘッダは<b>改行で区切られています</b>。値に改行を混ぜられると、
     * そこから先が別のヘッダや本文として解釈されてしまいます
     * (HTTP ヘッダインジェクション)。画面から来た値をヘッダに入れるときは、
     * かならず改行と制御文字を落としてください。</p>
     */
    static String sanitizeHeaderValue(String value) {
        if (value == null) {
            return "";
        }
        StringBuilder cleaned = new StringBuilder(value.length());
        for (int i = 0; i < value.length() && cleaned.length() < NOTE_MAX_LENGTH; i++) {
            char c = value.charAt(i);
            // 改行 (CR / LF) を含む制御文字は落とす
            if (c >= 0x20 && c != 0x7F) {
                cleaned.append(c);
            }
        }
        return cleaned.toString().trim();
    }
}
