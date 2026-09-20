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
import javax.servlet.http.HttpServletRequestWrapper;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.samples.list.Product;
import com.example.servletsample.samples.list.ProductDao;
import com.example.servletsample.samples.list.ProductSearch;

/**
 * 【サンプル】モーダル (ダイアログ) の出し方 6 パターン。
 *
 * <p>Bootstrap のモーダルは HTML と JavaScript だけで開けますが、
 * 「サーバで処理した結果を知らせるモーダル」や
 * 「モーダルで選んだ値を元の画面へ返すモーダル」となると、
 * サーバ側・元の画面とどう連携するかを決める必要があります。</p>
 *
 * <table border="1">
 *   <caption>6 つのパターン</caption>
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
 *   <tr>
 *     <td>⑤ モーダルの入力を元の画面のフォームへ渡す</td>
 *     <td>{@code data-toggle="modal"}</td>
 *     <td>処理なし (値の受け渡しは画面の中だけ)</td>
 *   </tr>
 *   <tr>
 *     <td>⑥ モーダルで検索して選んだ行を元の画面へ渡す</td>
 *     <td>{@code data-toggle="modal"}</td>
 *     <td>候補をあらかじめ request に載せておく ({@link #CANDIDATE_COUNT} 件)</td>
 *   </tr>
 * </table>
 *
 * <p>実務では ③ と ④ (処理結果の通知)、⑤ と ⑥ (入力を助けるダイアログ) を
 * 使う場面が多いです。②は URL が POST のままなので、
 * 完了画面でブラウザを再読み込みすると「再送信しますか？」が出てしまいます。</p>
 *
 * <p>⑤ と ⑥ はサーバへ行かずに画面の中だけで値を受け渡します。
 * この Servlet がしているのは、⑥ の検索ダイアログに並べる候補を用意することだけです。</p>
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

    /**
     * ⑥ の商品検索ダイアログに並べる候補の件数。
     *
     * <p>{@link ProductSearch} が 1 ページの件数として認める値 (10 / 20 / 50) の 1 つにしています。
     * 認めていない値を指定すると既定の 10 件に丸められてしまうためです。</p>
     */
    private static final int CANDIDATE_COUNT = 20;

    private static final DateTimeFormatter RECEIPT_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    /** 受付番号を作るための連番 (サンプルなのでメモリ上で採番しています)。 */
    private static final AtomicInteger SEQUENCE = new AtomicInteger();

    /** ⑥ の候補を取り出すための DAO (一覧サンプルと同じ products テーブルを読むだけです)。 */
    private final ProductDao productDao = new ProductDao();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ③ リダイレクト元が預けたメッセージを取り出す (あれば画面表示直後にモーダルが開く)
        Flash.consume(request);
        forwardToView(request, response);
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
        forwardToView(request, response);
    }

    /**
     * JSP へ転送する。
     *
     * <p>⑥ の候補は GET で開いたときだけでなく、② の forward で戻ってきたときにも必要です。
     * 載せ忘れると「POST したあとだけ検索ダイアログが空になる」という分かりにくい不具合になるので、
     * JSP へ進む手前の 1 か所にまとめています。</p>
     */
    private void forwardToView(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("candidates", findCandidates(request));
        forward(request, response, VIEW);
    }

    /**
     * ⑥ の商品検索ダイアログに並べる候補を取り出す。
     *
     * <p>候補は画面に書き出してしまい、絞り込みは JavaScript だけで行います
     * (通信しないので速い)。この作りが成り立つのは、候補が数十件で収まる場合です。
     * 何百件・何千件になるなら、キーワードを入力するたびにサーバへ問い合わせる
     * Ajax 検索 (<code>/samples/ajax/ajax-search</code>) に切り替えます。</p>
     */
    private List<Product> findCandidates(HttpServletRequest request) {
        // ProductSearch は「リクエストパラメータから作る」決まりになっているため、
        // この画面のリクエストをそのまま渡すと ?q=... や ?page=2 が候補にも効いてしまう。
        // 決め打ちの条件を返すラッパーをかぶせて、いつも同じ候補が並ぶようにする。
        ProductSearch search = ProductSearch.from(new CandidateRequest(request));
        return productDao.search(search).getItems();
    }

    /**
     * {@link ProductSearch} へ「決め打ちの検索条件」を渡すためのラッパー。
     *
     * <p>{@link HttpServletRequestWrapper} は、元のリクエストの働きはそのままに、
     * 一部のメソッドだけを差し替えたいときに使う Servlet API の部品です。
     * {@code ProductSearch.from} が見るのは {@code getParameter} だけなので、
     * ここで返す値がそのまま検索条件になります
     * ({@link ProductDao} は他のサンプルと共用しているので、
     * このサンプルの都合で DAO 側にメソッドを足さずに済ませています)。</p>
     */
    private static final class CandidateRequest extends HttpServletRequestWrapper {

        CandidateRequest(HttpServletRequest request) {
            super(request);
        }

        @Override
        public String getParameter(String name) {
            switch (name) {
                case "size":
                    // 1 ページの件数 = 候補の件数。既定のままだと 10 件しか取れない
                    return String.valueOf(CANDIDATE_COUNT);
                case "sort":
                    // 商品名順にすると、いろいろなカテゴリの商品が候補に混ざって分かりやすい
                    return "name";
                default:
                    // キーワードやページ番号は画面から引き継がない (常に先頭の候補を出す)
                    return null;
            }
        }
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
