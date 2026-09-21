package com.example.servletsample.samples.advanced;

import java.io.IOException;
import java.util.List;
import java.util.OptionalInt;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】データベースのトランザクション（commit と rollback）。
 *
 * <p>口座間の振替を題材にしています。
 * 「1 つの処理」に見えても、中身は<b>3 つの更新</b>です。</p>
 *
 * <pre>{@code
 * ① 送金元から引く
 * ② 送金先に足す
 * ③ 履歴を残す
 * }</pre>
 *
 * <p>①だけ成功して②で落ちたら、<b>お金が消えます</b>。
 * 「全部やるか、1 つもやらないか」にするのがトランザクションです。</p>
 *
 * <h2>この画面でできること</h2>
 * <ul>
 *   <li>トランザクションを<b>使う / 使わない</b>を切り替えて振替する</li>
 *   <li>出金のあとで<b>わざと失敗させる</b></li>
 *   <li>残高の合計を見る (振替では変わらないはずの値)</li>
 * </ul>
 *
 * <p>「トランザクションを使わない」＋「わざと失敗させる」を選ぶと、
 * 出金だけが確定して<b>合計が減ったまま戻りません</b>。これが体験してほしいところです。</p>
 */
@WebServlet(name = "transaction", urlPatterns = {"/samples/advanced/transaction"})
public class TransactionServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/advanced/transaction.jsp";

    /** このサンプルの URL。 */
    static final String PATH = "/samples/advanced/transaction";

    /** 振替できる金額の上限 (デモ用)。 */
    static final int MAX_AMOUNT = 100_000;

    /** 直前の実行結果を 1 回だけ持ち回るためのセッション属性名。 */
    static final String OUTCOME_KEY = "transactionSample.outcome";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Flash.consume(request);

        // リダイレクトをまたいで結果を渡す (Flash と同じ考え方。1 回見せたら消す)
        Object outcome = request.getSession().getAttribute(OUTCOME_KEY);
        if (outcome != null) {
            request.getSession().removeAttribute(OUTCOME_KEY);
            request.setAttribute("outcome", outcome);
        }

        render(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        TransferDao dao = new TransferDao();

        if ("reset".equals(request.getParameter("action"))) {
            dao.reset();
            Flash.set(request, "info", "元に戻しました", "残高と履歴を初期状態に戻しました。");
            response.sendRedirect(request.getContextPath() + PATH);
            return;
        }

        // ---------------- 入力チェック (例外にせず画面に戻す)
        OptionalInt fromId = Validators.toInt(request.getParameter("fromId"));
        OptionalInt toId = Validators.toInt(request.getParameter("toId"));
        OptionalInt amount = Validators.toInt(request.getParameter("amount"));

        String error = validate(fromId, toId, amount);
        if (error != null) {
            request.setAttribute("formError", error);
            render(request, response);
            return;
        }

        boolean useTransaction = request.getParameter("useTransaction") != null;
        boolean failMidway = request.getParameter("failMidway") != null;

        TransferOutcome outcome = dao.transfer(
                fromId.getAsInt(), toId.getAsInt(), amount.getAsInt(), useTransaction, failMidway);

        // PRG。再読み込みでもう一度振替されないようにする
        request.getSession().setAttribute(OUTCOME_KEY, outcome);
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /** 画面を組み立てる。 */
    private void render(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        TransferDao dao = new TransferDao();
        List<Account> accounts = dao.findAccounts();

        request.setAttribute("accounts", accounts);
        request.setAttribute("totalBalance", dao.totalBalance());
        request.setAttribute("history", dao.recentTransfers(5));
        request.setAttribute("initialTotal", 90_000);
        forward(request, response, VIEW);
    }

    /**
     * 振替の入力を確かめる。
     *
     * @return 問題があればメッセージ。無ければ {@code null}
     */
    static String validate(OptionalInt fromId, OptionalInt toId, OptionalInt amount) {
        if (fromId.isEmpty() || toId.isEmpty()) {
            return "送金元と送金先を選んでください。";
        }
        if (fromId.getAsInt() == toId.getAsInt()) {
            return "送金元と送金先には別の口座を選んでください。";
        }
        if (amount.isEmpty()) {
            return "金額は半角数字で入力してください。";
        }
        if (amount.getAsInt() < 1 || amount.getAsInt() > MAX_AMOUNT) {
            return "金額は 1 〜 " + MAX_AMOUNT + " の範囲で入力してください。";
        }
        return null;
    }
}
