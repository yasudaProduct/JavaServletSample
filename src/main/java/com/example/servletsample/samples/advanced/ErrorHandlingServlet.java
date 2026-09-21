package com.example.servletsample.samples.advanced;

import java.io.IOException;
import java.sql.SQLException;
import java.util.OptionalInt;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】エラー処理とエラーページ。
 *
 * <p>Web アプリで起きる「うまくいかないこと」は、次の 3 つに分けて考えると迷いません。</p>
 *
 * <table border="1">
 *   <caption>エラーの種類と扱い方</caption>
 *   <tr><th>種類</th><th>例</th><th>扱い方</th></tr>
 *   <tr><td>入力の誤り</td><td>未入力、数字でない</td>
 *       <td><b>例外にしない</b>。その場でメッセージを出して直してもらう</td></tr>
 *   <tr><td>業務上の都合</td><td>在庫不足、締め切り超過</td>
 *       <td>業務例外 ({@link ApplicationException}) を投げ、受け止めて画面に出す</td></tr>
 *   <tr><td>システムの異常</td><td>DB に繋がらない、NullPointerException</td>
 *       <td><b>その場では受け止めない</b>。エラーページへ任せる</td></tr>
 * </table>
 *
 * <p>いちばん間違えやすいのが 3 つめです。
 * {@code catch (Exception e) { }} で握りつぶすと、画面は一見動いたように見えるのに
 * データは中途半端なまま進み、あとから原因も追えなくなります。
 * <b>直せない例外は受け止めない</b>のが原則です。</p>
 *
 * <h2>エラーページは web.xml で決める</h2>
 * <p>受け止めなかった例外と {@code sendError} は、コンテナが {@code web.xml} の
 * {@code <error-page>} を見て、対応する JSP へ転送します。</p>
 *
 * <pre>{@code
 * <error-page>                                  ステータスコードで割り当てる
 *   <error-code>404</error-code>
 *   <location>/WEB-INF/views/error/404.jsp</location>
 * </error-page>
 * <error-page>                                  例外の型で割り当てる
 *   <exception-type>java.lang.Throwable</exception-type>
 *   <location>/WEB-INF/views/error/500.jsp</location>
 * </error-page>
 * }</pre>
 *
 * <h2>この Servlet が受け持つ URL</h2>
 * <table border="1">
 *   <caption>リクエストと動き</caption>
 *   <tr><th>リクエスト</th><th>動き</th></tr>
 *   <tr><td>{@code GET /samples/advanced/error-handling}</td><td>画面を表示する</td></tr>
 *   <tr><td>{@code GET ...?raise=runtime}</td><td>実行時例外を投げる → 500 のエラーページ</td></tr>
 *   <tr><td>{@code GET ...?raise=npe}</td><td>NullPointerException を起こす → 500 のエラーページ</td></tr>
 *   <tr><td>{@code GET ...?raise=cause}</td><td>原因つきの例外を投げる → 500 のエラーページ</td></tr>
 *   <tr><td>{@code GET ...?raise=business}</td><td>業務例外を投げる → 業務エラー用のエラーページ</td></tr>
 *   <tr><td>{@code GET ...?raise=status-400}</td><td>{@code sendError(400)}</td></tr>
 *   <tr><td>{@code GET ...?raise=status-403}</td><td>{@code sendError(403)}</td></tr>
 *   <tr><td>{@code GET ...?raise=jsp}</td><td>JSP の中で例外を起こす画面へ転送する</td></tr>
 *   <tr><td>{@code POST /samples/advanced/error-handling}</td><td>出庫フォームを処理する</td></tr>
 * </table>
 *
 * <p>{@code raise} は<b>デモのためだけ</b>のパラメータです。
 * 実際のアプリに「わざと失敗する入口」を残してはいけません。</p>
 */
@WebServlet(name = "errorHandling", urlPatterns = {"/samples/advanced/error-handling"})
public class ErrorHandlingServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/advanced/error-handling.jsp";

    /** JSP の中で例外を起こすデモ用の画面。 */
    private static final String JSP_ERROR_VIEW = "/WEB-INF/views/samples/advanced/error-handling-jsp.jsp";

    /** このサンプルの URL (リダイレクト先に使う)。 */
    static final String PATH = "/samples/advanced/error-handling";

    /** 出庫できる在庫数 (デモ用の固定値)。 */
    static final int STOCK = 10;

    /**
     * 画面を表示する。{@code raise} が付いていたら、その種類のエラーをわざと起こす。
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String raise = request.getParameter("raise");
        if (raise != null && !raise.isBlank()) {
            raise(raise.strip(), request, response);
            return;
        }

        // リダイレクトで預けた完了メッセージがあれば取り出す (PRG パターン)
        Flash.consume(request);

        request.setAttribute("stock", STOCK);
        forward(request, response, VIEW);
    }

    /**
     * 出庫フォームを処理する。
     *
     * <p>ここが「想定内のエラーは例外にしない」の実例です。
     * 数量の書き間違いも在庫不足も<b>起こりうると分かっている</b>ことなので、
     * エラーページへ飛ばさず、同じ画面にメッセージを出して直してもらいます。</p>
     *
     * <p>業務例外の投げ方・受け止め方を見せるため、在庫不足だけは
     * {@link ApplicationException} を投げ、この Servlet で受け止める形にしています
     * (在庫の判定が別のクラスにあることを想定した書き方です)。</p>
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String raw = request.getParameter("quantity");
        request.setAttribute("stock", STOCK);
        request.setAttribute("inputQuantity", raw == null ? "" : raw);

        // ① 入力の誤り : 例外にせず、その場でメッセージを出す
        Integer quantity = toQuantity(raw);
        if (quantity == null) {
            request.setAttribute("formError", "数量は半角数字で入力してください。");
            forward(request, response, VIEW);
            return;
        }
        if (quantity < 1) {
            request.setAttribute("formError", "数量は 1 以上で入力してください。");
            forward(request, response, VIEW);
            return;
        }

        // ② 業務上の都合 : 業務例外を投げ、画面を返せる場所で受け止める
        try {
            ship(quantity);
        } catch (ApplicationException e) {
            // 画面に出すのは「利用者が次に何をすればよいか」が分かるメッセージだけ。
            // 原因を追うための情報はログに出す (ここでは Tomcat のログへ)
            getServletContext().log("業務エラー: " + e.getCode() + " " + e.getMessage());
            request.setAttribute("formErrorCode", e.getCode());
            request.setAttribute("formError", e.getMessage());
            forward(request, response, VIEW);
            return;
        }

        // ③ 成功 : POST → リダイレクト → GET (PRG) にして、再読み込みで二重に処理されないようにする
        Flash.set(request, "success", "出庫しました",
                quantity + " 個を出庫しました。(このサンプルでは保存はしていません)");
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /**
     * 在庫から払い出す (デモ用)。
     *
     * <p>在庫が足りなければ業務例外を投げます。
     * 「呼び出し元が画面を持っているかどうか」をこの層は知らなくてよい、というのが
     * 例外で知らせる利点です。</p>
     *
     * @throws ApplicationException 在庫が足りない場合
     */
    static void ship(int quantity) {
        if (quantity > STOCK) {
            throw new ApplicationException("E-1001",
                    "在庫が足りません。(在庫 " + STOCK + " 個に対して " + quantity + " 個の出庫要求)");
        }
    }

    /**
     * 入力された数量を数値に直す。数値として読めなければ {@code null}。
     *
     * <p><b>利用者の書き間違いは例外で扱わない</b>ので、読めないことを
     * {@code null} という戻り値で表しています。</p>
     *
     * <p>変換そのものは {@link Validators#toInt(String)} に任せています。
     * {@code Integer.parseInt} を直に呼ぶと、<b>「１２」のような全角数字も通ってしまう</b>
     * (Java が全角数字も数字として扱うため) ので、
     * 半角数字だけを通す共通の部品を使うのが安全です。</p>
     */
    static Integer toQuantity(String raw) {
        OptionalInt parsed = Validators.toInt(raw);
        return parsed.isPresent() ? parsed.getAsInt() : null;
    }

    /**
     * 顧客名を探す (デモ用)。見つからなければ {@code null} を返す。
     *
     * <p>「無ければ null」を返すメソッドは、呼び出し側が確かめ忘れると
     * そのまま {@link NullPointerException} になります。
     * 実際には {@link java.util.Optional} を返す、または見つからないこと自体を
     * 業務例外にする、といった形で<b>確かめ忘れを起こせなくする</b>のが確実です。</p>
     */
    private static String findCustomerName(String customerId) {
        return null;
    }

    /**
     * {@code raise} パラメータの指示どおりにエラーを起こす (デモ専用)。
     *
     * <p>ここで投げた例外はどこでも受け止めません。コンテナまで抜けていき、
     * {@code web.xml} の {@code <error-page>} が選んだ JSP が表示されます。</p>
     */
    private void raise(String kind, HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        switch (kind) {
            case "runtime":
                // 素の実行時例外。<exception-type>java.lang.Throwable</exception-type> に当たる
                throw new IllegalStateException(
                        "帳票テンプレートが見つかりません (このサンプルがわざと投げた例外です)");

            case "npe": {
                // 「うっかり」で起きる例外の代表格。
                // 「無ければ null を返す」メソッドの戻り値を、確かめずにそのまま使っている
                String customerName = findCustomerName("C-9999");
                request.setAttribute("nameLength", customerName.length());
                return;
            }

            case "cause":
                // 原因つきの例外。下位で起きた例外を包んで投げ直す典型的な形
                throw new IllegalStateException("注文データを読み込めませんでした",
                        new SQLException("connection refused: orders-db:5432"));

            case "business":
                // 業務例外。web.xml で専用のエラーページに割り当てている
                throw new ApplicationException("E-2001",
                        "受付時間を過ぎています。翌営業日の 9:00 以降にお試しください。");

            case "status-400":
                // 例外ではなく HTTP のステータスで返す。<error-code>400</error-code> に当たる
                response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                        "パラメータの形式が正しくありません");
                return;

            case "status-403":
                response.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "この操作を行う権限がありません");
                return;

            case "jsp":
                // JSP の中で起きた例外を <%@ page errorPage="..." %> で受け止める例
                forward(request, response, JSP_ERROR_VIEW);
                return;

            default:
                // 知らない指示は「おかしなリクエスト」として 400 で返す
                response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                        "raise に指定できない値です: " + kind);
        }
    }
}
