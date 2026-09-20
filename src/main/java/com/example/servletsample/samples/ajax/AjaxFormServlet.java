package com.example.servletsample.samples.ajax;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.samples.ajax.AjaxFormApiServlet.InquiryForm;

/**
 * 【サンプル】Ajax でフォームを送信する。
 *
 * <p>この Servlet が受け持つのは<b>最初の 1 回の画面表示だけ</b>です。
 * 送信ボタンを押したあとのやり取りは、画面の JavaScript と
 * {@link AjaxFormApiServlet} ({@code /samples/ajax/ajax-form/api}) の間で行われます。</p>
 *
 * <pre>{@code
 * ［画面を開く］ ブラウザ ──GET /samples/ajax/ajax-form──→ この Servlet ──forward──→ JSP
 *                        ←──────── HTML 1 枚 ────────
 *
 * ［送信する］   JavaScript ──POST .../ajax-form/api──→ AjaxFormApiServlet
 *                          ←──────── JSON ────────
 *                ※ 画面は切り替わらない。入力した値もスクロール位置もそのまま残る
 * }</pre>
 *
 * <h2>画面へ渡しているもの</h2>
 * <p>渡しているのは<b>すべて「サーバ側の決めごと」</b>です。
 * セレクトボックスの選択肢も、文字数の上限も、Java の定数 1 か所から出しています。
 * 画面に直接「30 文字以内」と書いてしまうと、サーバ側を 40 に変えたときに
 * 画面の案内だけが 30 のまま取り残されます。</p>
 *
 * <table border="1">
 *   <caption>リクエストスコープに入れる値</caption>
 *   <tr><th>名前</th><th>中身</th><th>画面での使い道</th></tr>
 *   <tr><td>{@code apiPath}</td><td>API の URL</td><td>{@code fetch} の送り先</td></tr>
 *   <tr><td>{@code types}</td><td>種別の一覧 (値 → 表示名)</td><td>セレクトボックスの選択肢</td></tr>
 *   <tr><td>{@code nameMaxLength}</td><td>お名前の上限</td><td>案内文と {@code maxlength}</td></tr>
 *   <tr><td>{@code bodyMaxLength}</td><td>本文の上限</td><td>案内文と残り文字数の表示</td></tr>
 *   <tr><td>{@code duplicateWindowSeconds}</td><td>二重送信とみなす時間 (秒)</td><td>説明文</td></tr>
 * </table>
 *
 * <p>この Servlet に {@code doPost} はありません。送信先は API 側だからです。</p>
 */
@WebServlet(name = "ajaxForm", urlPatterns = {"/samples/ajax/ajax-form"})
public class AjaxFormServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/ajax/ajax-form.jsp";

    /**
     * 画面を表示する。
     *
     * <p>状態を何も変えないので GET です。</p>
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // fetch の送り先。画面に直接書かず、API 側の定数から渡して食い違いを防ぐ
        request.setAttribute("apiPath", AjaxFormApiServlet.PATH);

        // セレクトボックスの選択肢。サーバ側が受け付けてよい値の一覧そのもの
        request.setAttribute("types", InquiryForm.TYPES);

        // 入力の上限。画面の案内文・maxlength 属性・残り文字数の表示で使う
        request.setAttribute("nameMaxLength", InquiryForm.NAME_MAX_LENGTH);
        request.setAttribute("bodyMaxLength", InquiryForm.BODY_MAX_LENGTH);

        // 二重送信とみなす時間。説明文に「10 秒以内なら」と書くために秒へ直して渡す
        request.setAttribute("duplicateWindowSeconds",
                AjaxFormApiServlet.DUPLICATE_WINDOW_MILLIS / 1000L);

        forward(request, response, VIEW);
    }
}
