package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.atomic.AtomicInteger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】forward と redirect の違い。
 *
 * <p>まったく同じ「注文を受け付ける」処理を、遷移のしかただけ変えて 2 通り用意しています。
 * どちらも POST で受け取り、受付番号をリクエストスコープに入れるところまでは同じです。</p>
 *
 * <table border="1">
 *   <caption>2 つの遷移のしかた</caption>
 *   <tr><th>&nbsp;</th><th>forward</th><th>redirect</th></tr>
 *   <tr>
 *     <td>やっていること</td>
 *     <td>サーバの中で次の資源へ処理を渡す</td>
 *     <td>ブラウザに「この URL をもう一度取りに行って」と返す</td>
 *   </tr>
 *   <tr>
 *     <td>ブラウザとの通信</td>
 *     <td>1 往復 (ブラウザは転送に気付かない)</td>
 *     <td>2 往復 (302 応答 → 改めてリクエスト)</td>
 *   </tr>
 *   <tr>
 *     <td>アドレスバーの URL</td>
 *     <td>POST した URL のまま</td>
 *     <td>遷移先の URL に変わる</td>
 *   </tr>
 *   <tr>
 *     <td>リクエストスコープ</td>
 *     <td>引き継がれる</td>
 *     <td>別のリクエストになるので消える</td>
 *   </tr>
 * </table>
 *
 * <p>登録・更新・削除のあとは redirect (PRG パターン) にします。
 * forward のままだと、完了画面で再読み込みしたときに POST がもう一度飛び、
 * 二重登録になってしまうためです。</p>
 */
@WebServlet(name = "forwardRedirect", urlPatterns = {ForwardRedirectServlet.SAMPLE_PATH})
public class ForwardRedirectServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** このサンプル画面の URL (コンテキストパスは含まない)。 */
    static final String SAMPLE_PATH = "/samples/basic/forward-redirect";

    /** 遷移先の URL。redirect 版の行き先で、{@link ForwardRedirectGoalServlet} が受けます。 */
    static final String GOAL_PATH = "/samples/basic/forward-redirect/goal";

    /** サンプル本体の JSP。 */
    private static final String VIEW = "/WEB-INF/views/samples/basic/forward-redirect.jsp";

    /**
     * 遷移先の JSP。
     *
     * <p>forward 版はこの JSP へ直接処理を渡します
     * ({@code /WEB-INF/} の下にあるので、ブラウザから直接は開けません)。
     * redirect 版は {@link ForwardRedirectGoalServlet} を経由して同じ JSP に届きます。</p>
     */
    static final String GOAL_VIEW = "/WEB-INF/views/samples/basic/forward-redirect-goal.jsp";

    private static final DateTimeFormatter RECEIPT_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    /** 受付番号を作るための連番 (サンプルなのでメモリ上で採番しています)。 */
    private static final AtomicInteger SEQUENCE = new AtomicInteger();

    /** 名前が未入力だったときに使う値。 */
    static final String DEFAULT_NAME = "名無しさん";

    /** 画面から受け取る名前の上限 (長すぎる値をそのまま URL に載せないため)。 */
    private static final int NAME_MAX_LENGTH = 20;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // サンプル画面そのものも「Servlet → JSP へ forward」で表示しています。
        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String mode = request.getParameter("mode");
        String name = orderName(request.getParameter("name"));
        String receiptNumber = nextReceiptNumber();

        // ------------------------------------------------------------------
        // ここまでは forward 版も redirect 版もまったく同じ。
        // 「受け付けた結果をリクエストスコープに入れる」ところまでを済ませておきます。
        // この値が forward では遷移先まで届き、redirect では消えます。
        // ------------------------------------------------------------------
        request.setAttribute("receiptNumber", receiptNumber);
        request.setAttribute("orderName", name);

        if ("redirect".equals(mode)) {
            // 【redirect 版】
            // ブラウザに 302 と Location ヘッダを返し、改めて GET してもらいます。
            // この時点で setAttribute した値は、このリクエストと一緒に捨てられます。
            // 引き継ぎたい値は URL のクエリ文字列か、セッション (common/Flash.java) に載せます。
            //
            // パスは必ず getContextPath() から組み立てること。
            // "/samples/..." とだけ書くと、コンテキストパス付き (/app/...) で
            // 配備したときにサーバのルート直下を指してしまい 404 になります。
            response.sendRedirect(buildGoalUrl(request.getContextPath(), receiptNumber, name));

            // sendRedirect のあとは必ず return する。
            // 続けてレスポンスに書き込むと IllegalStateException になります。
            return;
        }

        // 【forward 版】
        // サーバの中で遷移先の JSP に処理を渡します。ブラウザから見ると
        // POST した 1 回のリクエストがまだ続いているので、
        // アドレスバーは POST 先 (/samples/basic/forward-redirect) のまま変わりません。
        request.setAttribute("arrivedBy", "forward");
        forward(request, response, GOAL_VIEW);
    }

    /**
     * redirect 先の URL を組み立てる。
     *
     * <p>redirect ではリクエストスコープが引き継がれないため、
     * 遷移先に渡したい値はクエリ文字列に載せます
     * (見せたくない値やサイズの大きい値は、代わりにセッションを使ってください)。</p>
     *
     * @param contextPath {@code request.getContextPath()} の値 (ルート配備なら空文字)
     * @return 例: {@code /app/samples/basic/forward-redirect/goal?receipt=R-20260919-0001&name=%E5%B1%B1%E7%94%B0}
     */
    static String buildGoalUrl(String contextPath, String receiptNumber, String name) {
        return contextPath + GOAL_PATH
                + "?receipt=" + encode(receiptNumber)
                + "&name=" + encode(name);
    }

    /**
     * クエリ文字列に載せる値をエスケープする。
     *
     * <p>日本語や {@code &} {@code =} をそのまま URL に書くと壊れるため、
     * かならず {@link URLEncoder} を通します。</p>
     */
    private static String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    /**
     * 画面から受け取った名前を整える。
     *
     * <p>未入力なら既定の名前にし、長すぎる入力は切り詰めます。</p>
     */
    static String orderName(String value) {
        if (value == null || value.trim().isEmpty()) {
            return DEFAULT_NAME;
        }
        String trimmed = value.trim();
        return trimmed.length() > NAME_MAX_LENGTH ? trimmed.substring(0, NAME_MAX_LENGTH) : trimmed;
    }

    /** 受付番号を作る。例: {@code R-20260919-0003} */
    private static String nextReceiptNumber() {
        return String.format("R-%s-%04d",
                LocalDate.now().format(RECEIPT_DATE), SEQUENCE.incrementAndGet());
    }
}
