package com.example.servletsample.samples.form;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.ValidationErrors;

/**
 * 【サンプル】サーバ側での入力チェック (バリデーション)。
 *
 * <p>JavaScript を一切使わずに、<b>送られてきた値をサーバで確かめる</b>形のサンプルです。
 * ブラウザ側のチェックは「利用者に早く気づいてもらう」ためのもので、
 * 迂回できます (JavaScript を切る、{@code curl} で直接 POST する、開発者ツールで
 * {@code required} を外す)。<b>最後にデータを受け入れるかどうかを決めるのはサーバ側だけ</b>です。</p>
 *
 * <h2>画面の流れ</h2>
 * <ol>
 *   <li>GET … 空のフォームを表示する</li>
 *   <li>POST … {@link MemberForm#from(HttpServletRequest)} で受け取り、{@link MemberForm#validate()} で確かめる</li>
 *   <li>エラーがある … 同じ画面へ <b>forward</b> する。入力値とエラーを持ったまま戻すので、
 *       利用者は打ち直さずに直せる</li>
 *   <li>エラーが無い … {@link Flash} に完了メッセージを預けて <b>リダイレクト</b> する (PRG パターン)</li>
 * </ol>
 *
 * <p>エラー時に forward、成功時にリダイレクトと使い分けているのには理由があります。
 * エラー時はリクエストスコープの入力値をそのまま画面に渡したいので forward が向いています。
 * 一方で登録が成功したあとは、再読み込みで二重登録されないようにリダイレクトします。</p>
 */
@WebServlet(name = "inputValidation", urlPatterns = {"/samples/form/input-validation"})
public class InputValidationServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/form/input-validation.jsp";

    private static final String PATH = "/samples/form/input-validation";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 登録直後のリダイレクトで預けられたメッセージを取り出す (あれば完了モーダルが開く)
        Flash.consume(request);

        // JSP は form / errors が必ずある前提で書けるよう、空のものを入れておく。
        // ここで入れておかないと、初期表示で ${form.name} が空文字ではなく
        // 「値なし」になり、c:if を書き足す必要が出てくる。
        request.setAttribute("form", MemberForm.empty());
        request.setAttribute("errors", new ValidationErrors());
        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ① 受け取る (この時点では良し悪しを判断しない)
        MemberForm form = MemberForm.from(request);

        // ② 確かめる
        ValidationErrors errors = form.validate();

        if (errors.hasErrors()) {
            // ③ エラーあり : 入力値とエラーを持たせて同じ画面へ戻す。
            //    sendRedirect にすると request スコープが消えるため、ここは forward。
            request.setAttribute("form", form);
            request.setAttribute("errors", errors);
            forward(request, response, VIEW);
            return;
        }

        // ④ エラーなし : 本来はここで DB に登録する (このサンプルでは保存しません)。
        //    完了メッセージはセッションに預けてからリダイレクトする (PRG パターン)。
        //    パスワードはメッセージにも画面にも出さない。
        Flash.set(request, "success", "登録が完了しました",
                form.getName() + " さん (" + form.getEmail() + ") を登録しました。"
                        + "このサンプルでは保存はしていません。");
        response.sendRedirect(request.getContextPath() + PATH);
    }
}
