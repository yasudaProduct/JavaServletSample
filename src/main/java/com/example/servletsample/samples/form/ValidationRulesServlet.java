package com.example.servletsample.samples.form;

import java.io.IOException;
import java.time.LocalDate;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】入力チェックの種類 (必須 / 文字種 / 桁数 / 形式 / 範囲 / 相関 / 選択 / 突き合わせ)。
 *
 * <p>「入力チェック」と一口に言っても、確かめている内容にはいくつかの種類があります。
 * この画面は<b>種類ごとの書き方を 1 つのフォームに詰め込んだ</b>ものです。
 * 実装は {@link LeaveRequestForm} にあり、判定そのものは
 * {@link Validators} の部品を組み合わせて作っています。</p>
 *
 * <p>基本の流れ (受け取る → 確かめる → エラーなら forward、成功ならリダイレクト) は
 * {@link InputValidationServlet} のサンプルと同じです。
 * そちらを先に見ておくと、この画面は「種類の一覧」として読めます。</p>
 *
 * <h2>Servlet がすることは 3 つだけ</h2>
 * <ol>
 *   <li>画面から値を受け取る ({@link LeaveRequestForm#from(HttpServletRequest)})</li>
 *   <li>確かめる ({@link LeaveRequestForm#validate(LocalDate)})</li>
 *   <li>結果によって forward するかリダイレクトするかを決める</li>
 * </ol>
 *
 * <p>判定そのものは 1 行も書いていません。
 * <b>チェックの中身をフォームのクラスへ寄せておくと、Tomcat を起動せずにテストできます</b>
 * ({@code src/test/java/.../LeaveRequestFormTest.java})。</p>
 *
 * <h2>「今日」を渡しているのはなぜか</h2>
 * <p>{@code validate(LocalDate.now())} のように、基準日を<b>外から渡しています</b>。
 * チェックの中で {@code now()} を呼ぶと、実行した日によってテスト結果が変わってしまいます。
 * 時刻に依存する判定は、基準になる日時を引数で受け取る形にしておくと素直にテストできます。</p>
 */
@WebServlet(name = "validationRules", urlPatterns = {"/samples/form/validation-rules"})
public class ValidationRulesServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/form/validation-rules.jsp";

    private static final String PATH = "/samples/form/validation-rules";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 申請直後のリダイレクトで預けられたメッセージを取り出す (あれば完了モーダルが開く)
        Flash.consume(request);

        // JSP が ${form.employeeCode} / ${errors.has('...')} を常に書けるよう、空のものを入れておく
        request.setAttribute("form", LeaveRequestForm.empty());
        request.setAttribute("errors", new ValidationErrors());
        putChoices(request);

        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ① 受け取る (この時点では良し悪しを判断しない)
        LeaveRequestForm form = LeaveRequestForm.from(request);

        // ② 確かめる。「今日」は呼び出し側で決めて渡す
        ValidationErrors errors = form.validate(LocalDate.now());

        if (errors.hasErrors()) {
            // ③ エラーあり : 入力値とエラーを持たせて同じ画面へ戻す (forward)
            request.setAttribute("form", form);
            request.setAttribute("errors", errors);
            putChoices(request);
            forward(request, response, VIEW);
            return;
        }

        // ④ エラーなし : 本来はここで申請を登録する (このサンプルでは保存しません)。
        //    完了メッセージはセッションに預けてからリダイレクトする (PRG パターン)
        Flash.set(request, "success", "申請を受け付けました",
                form.getLeaveTypeLabel() + " を " + form.getStartDate() + " 〜 " + form.getEndDate()
                        + " (" + form.getDays() + " 日間) で受け付けました。"
                        + "引継ぎ先: " + form.getBackupNames() + "。"
                        + "このサンプルでは保存はしていません。");
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /**
     * 選択肢とチェックの上限値を画面へ渡す。
     *
     * <p>桁数や日数を JSP に直接書かず、<b>Java 側の定数を渡して表示しています</b>。
     * 画面に「30 文字以内」と書いたのに実装は 20 文字だった、という食い違いは
     * よく起きます。出どころを 1 つにしておけば、直したときに片方だけ残りません。</p>
     */
    private void putChoices(HttpServletRequest request) {
        request.setAttribute("leaveTypes", LeaveType.all());
        request.setAttribute("employees", EmployeeMaster.all());

        LocalDate today = LocalDate.now();
        request.setAttribute("today", Validators.formatDate(today));
        request.setAttribute("limitDate",
                Validators.formatDate(today.plusMonths(LeaveRequestForm.MAX_MONTHS_AHEAD)));

        request.setAttribute("codeLength", LeaveRequestForm.CODE_LENGTH);
        request.setAttribute("kanaMaxLength", LeaveRequestForm.KANA_MAX_LENGTH);
        request.setAttribute("reasonMaxLength", LeaveRequestForm.REASON_MAX_LENGTH);
        request.setAttribute("maxPeriodDays", LeaveRequestForm.MAX_PERIOD_DAYS);
        request.setAttribute("minBackups", LeaveRequestForm.MIN_BACKUPS);
        request.setAttribute("maxBackups", LeaveRequestForm.MAX_BACKUPS);
        request.setAttribute("maxMonthsAhead", LeaveRequestForm.MAX_MONTHS_AHEAD);
    }
}
