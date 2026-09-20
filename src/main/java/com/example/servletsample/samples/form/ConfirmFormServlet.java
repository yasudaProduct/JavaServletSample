package com.example.servletsample.samples.form;

import java.io.IOException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.concurrent.atomic.AtomicInteger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.ValidationErrors;

/**
 * 【サンプル】入力 → 確認 → 完了 の 3 画面。
 *
 * <p>業務システムでいちばんよく出てくる流れです。
 * 画面は 3 つですが、<b>URL は 1 つ</b>で、どの段階を表示するかを
 * リクエストごとに決めています。</p>
 *
 * <pre>{@code
 * ［入力］ --POST action=confirm--> ［確認］ --POST action=submit--> ［完了］
 *    ↑                                 │
 *    └-------POST action=back----------┘
 * }</pre>
 *
 * <h2>確認画面へ進むのも POST</h2>
 * <p>GET にすると、入力値が URL に出ます。
 * ブラウザの履歴・アクセスログ・{@code Referer} に残り、
 * 肩越しにも見えます。<b>入力値を運ぶのは常に POST</b>です。</p>
 *
 * <h2>値の持ち回り方 : 2 つのやり方</h2>
 * <table border="1">
 *   <caption>hidden とセッション</caption>
 *   <tr><th></th><th>隠し項目 (hidden)</th><th>セッション</th></tr>
 *   <tr><td>置き場所</td><td>画面 (HTML の中)</td><td>サーバのメモリ</td></tr>
 *   <tr><td>複数タブ</td><td><b>問題なし</b> (タブごとに独立)</td>
 *       <td><b>混ざる</b> (あとから開いたタブの値で上書きされる)</td></tr>
 *   <tr><td>改ざん</td><td><b>される前提で考える</b></td><td>されない</td></tr>
 *   <tr><td>大きなデータ</td><td>向かない (画面が重くなる)</td><td>向く</td></tr>
 *   <tr><td>消し忘れ</td><td>起きない</td><td><b>起きる</b> (明示的に消す)</td></tr>
 *   <tr><td>戻るボタン</td><td>素直に動く</td><td>ずれることがある</td></tr>
 * </table>
 *
 * <p>どちらにしても<b>確定するときに必ず検証をやり直します</b>。
 * 隠し項目は書き換えられますし、セッションの値も
 * 「確認画面を出したときは正しかった」だけで、
 * その間にマスタが変わっているかもしれません。</p>
 *
 * <h2>二重送信を防ぐ</h2>
 * <p>確認画面で「登録」を二度押しされると、同じ申し込みが 2 件できます。
 * 確認画面を出すときに<b>1 回きりのトークン</b>を埋めておき、
 * 受け取ったら<b>すぐ捨てます</b>。2 回目はトークンが無いので弾けます。</p>
 *
 * <p>CSRF 対策のトークンとは目的が違うので、別に用意します
 * (CSRF のトークンはセッション中ずっと同じ値を使い回します)。</p>
 */
@WebServlet(name = "confirmForm", urlPatterns = {"/samples/form/confirm-form"})
public class ConfirmFormServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/form/confirm-form.jsp";

    /** このサンプルの URL。 */
    static final String PATH = "/samples/form/confirm-form";

    /** セッション方式のときに、入力値を預けておく属性名。 */
    static final String FORM_KEY = "confirmFormSample.form";

    /** 二重送信を防ぐための、1 回きりのトークンを置く属性名。 */
    static final String TOKEN_KEY = "confirmFormSample.token";

    /** 受付番号の連番 (複数のスレッドから同時に採番されるので Atomic)。 */
    private static final AtomicInteger SEQUENCE = new AtomicInteger();

    private static final SecureRandom RANDOM = new SecureRandom();

    /** 入力画面。 */
    static final String STEP_INPUT = "input";

    /** 確認画面。 */
    static final String STEP_CONFIRM = "confirm";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Flash.consume(request);
        render(request, response, STEP_INPUT, SeminarForm.empty(), new ValidationErrors(),
                carryOf(request));
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        String carry = carryOf(request);

        if ("back".equals(action)) {
            // 確認画面から入力画面へ戻る。値は保持したまま、検証はしない
            render(request, response, STEP_INPUT, restore(request, carry),
                    new ValidationErrors(), carry);
            return;
        }

        if ("submit".equals(action)) {
            confirmAndRegister(request, response, carry);
            return;
        }

        // 既定は「確認画面へ進む」
        goToConfirm(request, response, carry);
    }

    /** 入力画面 → 確認画面。 */
    private void goToConfirm(HttpServletRequest request, HttpServletResponse response, String carry)
            throws ServletException, IOException {

        SeminarForm form = SeminarForm.from(request);
        ValidationErrors errors = form.validate();

        if (errors.hasErrors()) {
            // 入力画面に戻す。入力値は保持し、項目ごとにメッセージを出す
            render(request, response, STEP_INPUT, form, errors, carry);
            return;
        }

        if (isSessionCarry(carry)) {
            // セッション方式 : ここで預ける
            request.getSession().setAttribute(FORM_KEY, form);
        }

        // 二重送信を防ぐトークンを発行する (確認画面の隠し項目に入る)
        request.getSession().setAttribute(TOKEN_KEY, newToken());

        render(request, response, STEP_CONFIRM, form, errors, carry);
    }

    /** 確認画面 → 登録 → 完了。 */
    private void confirmAndRegister(HttpServletRequest request, HttpServletResponse response,
                                    String carry) throws ServletException, IOException {

        // ------------------------------------------------ ① 二重送信の確認
        if (!consumeToken(request)) {
            ValidationErrors errors = new ValidationErrors();
            errors.addGlobal("この内容はすでに送信済みです。もう一度最初から入力してください。");
            clear(request);
            render(request, response, STEP_INPUT, SeminarForm.empty(), errors, carry);
            return;
        }

        SeminarForm form = restore(request, carry);

        // ------------------------------------------------ ② 検証をやり直す
        //
        // 「確認画面を通ったから正しいはず」は成り立ちません。
        // 隠し項目は書き換えられますし、セッションの値も
        // その間にマスタが変わっているかもしれません
        ValidationErrors errors = form.validate();
        if (errors.hasErrors()) {
            errors.addGlobal("入力内容を確認してください。"
                    + "（確認画面から送られた値が、受け付けられる内容ではありませんでした）");
            render(request, response, STEP_INPUT, form, errors, carry);
            return;
        }

        // ------------------------------------------------ ③ 登録 (このサンプルでは保存しません)
        String receiptNo = String.format("SM-%04d", SEQUENCE.incrementAndGet());
        getServletContext().log("セミナー申込を受け付けました: " + receiptNo + " " + form);

        // ------------------------------------------------ ④ 後始末
        clear(request);

        // ------------------------------------------------ ⑤ PRG
        Flash.set(request, "success", "申し込みを受け付けました",
                "受付番号は " + receiptNo + " です。確認のメールをお送りしました。");
        response.sendRedirect(request.getContextPath() + PATH + "?carry=" + carry);
    }

    /**
     * 値を取り出す。
     *
     * <p>hidden 方式ならリクエストパラメータから、
     * セッション方式ならセッションから取り出します。</p>
     *
     * <p>セッション方式で値が見つからない場合 (セッションが切れた、
     * ブックマークから直接開いた) は空のフォームを返します。
     * <b>null を返して呼び出し元で毎回確かめる形にしない</b>のは、
     * 確かめ忘れがそのまま NullPointerException になるからです。</p>
     */
    private SeminarForm restore(HttpServletRequest request, String carry) {
        if (!isSessionCarry(carry)) {
            return SeminarForm.from(request);
        }
        HttpSession session = request.getSession(false);
        Object saved = session == null ? null : session.getAttribute(FORM_KEY);
        return saved instanceof SeminarForm ? (SeminarForm) saved : SeminarForm.empty();
    }

    /** 画面を表示する。 */
    private void render(HttpServletRequest request, HttpServletResponse response,
                        String step, SeminarForm form, ValidationErrors errors, String carry)
            throws ServletException, IOException {

        request.setAttribute("step", step);
        request.setAttribute("form", form);
        request.setAttribute("errors", errors);
        request.setAttribute("carry", carry);
        request.setAttribute("sessionCarry", isSessionCarry(carry));
        request.setAttribute("availableDates", SeminarForm.availableDates());

        if (STEP_CONFIRM.equals(step)) {
            HttpSession session = request.getSession(false);
            Object token = session == null ? null : session.getAttribute(TOKEN_KEY);
            request.setAttribute("oneTimeToken", token == null ? "" : token);
        }

        forward(request, response, VIEW);
    }

    /** 預けた値とトークンを片づける。 */
    private void clear(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            // セッションは消し忘れるとメモリに残り続けます。
            // 「使い終わったら消す」を処理の中に書いておきます
            session.removeAttribute(FORM_KEY);
            session.removeAttribute(TOKEN_KEY);
        }
    }

    /**
     * 二重送信を防ぐトークンを確かめ、<b>使ったら捨てる</b>。
     *
     * <p>捨てるのが要点です。2 回目の送信では、
     * セッションにトークンが無いので一致しません。</p>
     */
    private boolean consumeToken(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return false;
        }
        synchronized (session) {
            Object expected = session.getAttribute(TOKEN_KEY);
            String actual = request.getParameter("token");
            if (!(expected instanceof String) || actual == null || !expected.equals(actual)) {
                return false;
            }
            session.removeAttribute(TOKEN_KEY);
            return true;
        }
    }

    /** 1 回きりのトークンを作る。 */
    private static String newToken() {
        byte[] bytes = new byte[16];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /** 値の持ち回り方 ({@code hidden} または {@code session})。 */
    static String carryOf(HttpServletRequest request) {
        return "session".equals(request.getParameter("carry")) ? "session" : "hidden";
    }

    /** セッション方式かどうか。 */
    static boolean isSessionCarry(String carry) {
        return "session".equals(carry);
    }
}
