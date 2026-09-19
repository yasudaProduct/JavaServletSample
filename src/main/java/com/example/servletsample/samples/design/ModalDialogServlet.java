package com.example.servletsample.samples.design;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;

/**
 * 【サンプル】モーダル (ダイアログ) の出し方 4 パターン。
 *
 * <p>Bootstrap のモーダルは HTML と JavaScript だけで開けますが、
 * 「サーバで処理した結果を知らせるモーダル」となると、
 * サーバ側とどう連携するかを決める必要があります。</p>
 *
 * <table border="1">
 *   <caption>4 つのパターン</caption>
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
 *   <tr>
 *     <td>④ 確認 → 登録 → 完了モーダル → 画面遷移</td>
 *     <td>③ と同じ。閉じたときに次の画面へ移動する</td>
 *     <td>{@link Flash} に移動先 (nextUrl) も入れる</td>
 *   </tr>
 * </table>
 *
 * <p>実務では ③ と ④ を使う場面が多いです。②は URL が POST のままなので、
 * 完了画面でブラウザを再読み込みすると「再送信しますか？」が出てしまいます。</p>
 */
@WebServlet(name = "modalDialog", urlPatterns = {"/samples/design/modal-dialog"})
public class ModalDialogServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/design/modal-dialog.jsp";

    /** ④ の完了後に移動する画面。 */
    static final String ENTRIES_PATH = "/samples/design/modal-dialog/entries";

    /** 受付一覧をセッションに置くときのキー。 */
    private static final String ENTRIES_KEY = "modalDialog.entries";

    /** セッションに残す受付の件数。 */
    private static final int MAX_ENTRIES = 20;

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

        if ("move".equals(action)) {
            // ④ 確認 → 登録 → 完了モーダル → 画面遷移
            //    ③ と同じ PRG だが、「知らせたあとに移動させる画面」も一緒に預ける。
            //    モーダルを閉じた時点で、画面側がこの URL へ移動する。
            addEntry(request, new ReceptionEntry(receiptNumber, name, LocalDateTime.now()));
            Flash.set(request, "success", "登録が完了しました",
                    name + " さんを受付番号 " + receiptNumber + " で登録しました。"
                            + "このまま受付一覧へ移動します。",
                    request.getContextPath() + ENTRIES_PATH);
            response.sendRedirect(request.getContextPath() + "/samples/design/modal-dialog");
            return;
        }

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

    /**
     * この人が登録した受付の一覧を取り出す (新しい順)。
     *
     * <p>DB ではなくセッションに持たせているので、見えるのは登録した本人だけです。</p>
     */
    static List<ReceptionEntry> entriesOf(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return Collections.emptyList();
        }
        @SuppressWarnings("unchecked")
        List<ReceptionEntry> entries = (List<ReceptionEntry>) session.getAttribute(ENTRIES_KEY);
        return entries == null ? Collections.emptyList() : Collections.unmodifiableList(entries);
    }

    /** 受付を 1 件追加する (古いものから捨てて、溜まりすぎないようにする)。 */
    private static void addEntry(HttpServletRequest request, ReceptionEntry entry) {
        HttpSession session = request.getSession();
        @SuppressWarnings("unchecked")
        List<ReceptionEntry> stored = (List<ReceptionEntry>) session.getAttribute(ENTRIES_KEY);
        List<ReceptionEntry> entries = stored == null ? new ArrayList<>() : new ArrayList<>(stored);

        entries.add(0, entry);
        while (entries.size() > MAX_ENTRIES) {
            entries.remove(entries.size() - 1);
        }
        session.setAttribute(ENTRIES_KEY, entries);
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
