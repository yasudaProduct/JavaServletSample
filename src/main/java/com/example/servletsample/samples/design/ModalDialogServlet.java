package com.example.servletsample.samples.design;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.atomic.AtomicInteger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;

/**
 * 【サンプル】モーダル (ダイアログ) の出し方 3 パターン。
 *
 * <p>Bootstrap のモーダルは HTML と JavaScript だけで開けますが、
 * 「サーバで処理した結果を知らせるモーダル」となると、
 * サーバ側とどう連携するかを決める必要があります。</p>
 *
 * <table border="1">
 *   <caption>3 つのパターン</caption>
 *   <tr><th>パターン</th><th>開くきっかけ</th><th>サーバ側</th></tr>
 *   <tr>
 *     <td>① ボタンを押したら開く</td>
 *     <td>{@code data-toggle="modal"}</td>
 *     <td>処理なし (画面の中だけで完結)</td>
 *   </tr>
 *   <tr>
 *     <td>② 処理後の完了モーダル</td>
 *     <td>同じ画面へ forward し、結果があれば JS で開く</td>
 *     <td>{@code request.setAttribute} → forward</td>
 *   </tr>
 *   <tr>
 *     <td>③ 画面遷移後のモーダル</td>
 *     <td>リダイレクト先で、預けたメッセージがあれば JS で開く</td>
 *     <td>{@link Flash} に入れて {@code sendRedirect}</td>
 *   </tr>
 * </table>
 *
 * <p>実務では ③ を使う場面が多いです。②は URL が POST のままなので、
 * 完了画面でブラウザを再読み込みすると「再送信しますか？」が出てしまいます。</p>
 */
@WebServlet(name = "modalDialog", urlPatterns = {"/samples/design/modal-dialog"})
public class ModalDialogServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/design/modal-dialog.jsp";

    private static final DateTimeFormatter RECEIPT_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    /** 受付番号を作るための連番 (サンプルなのでメモリ上で採番しています)。 */
    private static final AtomicInteger SEQUENCE = new AtomicInteger();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ③ リダイレクト元が預けたメッセージを取り出す (あれば画面表示直後にモーダルが開く)
        Flash.consume(request);
        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        String name = trimmed(request.getParameter("name"), "名無しさん");
        String receiptNumber = nextReceiptNumber();

        if ("redirect".equals(action)) {
            // ③ 画面遷移後にモーダルを出す (PRG パターン)
            //    メッセージはセッション経由で渡し、リダイレクト先で 1 回だけ表示する
            Flash.set(request, "success", "登録が完了しました",
                    name + " さんの受付番号は " + receiptNumber + " です。");
            response.sendRedirect(request.getContextPath() + "/samples/design/modal-dialog");
            return;
        }

        // ② 同じ画面へ forward して、その場で完了モーダルを開く
        //    リダイレクトしていないので、URL は POST したときのまま
        request.setAttribute("resultTitle", "送信しました");
        request.setAttribute("resultText",
                name + " さんの受付番号は " + receiptNumber + " です。(forward で表示しています)");
        forward(request, response, VIEW);
    }

    /** 受付番号を作る。例: {@code A-20260918-0003} */
    private static String nextReceiptNumber() {
        return String.format("A-%s-%04d",
                LocalDate.now().format(RECEIPT_DATE), SEQUENCE.incrementAndGet());
    }

    private static String trimmed(String value, String defaultValue) {
        if (value == null || value.trim().isEmpty()) {
            return defaultValue;
        }
        String trimmed = value.trim();
        return trimmed.length() > 20 ? trimmed.substring(0, 20) : trimmed;
    }
}
