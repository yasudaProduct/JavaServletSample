package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】forward と include の違いを、同じ部品を呼び分けて確かめる。
 *
 * <p>どちらも {@code RequestDispatcher} から呼びますが、起きることが違います。</p>
 *
 * <table border="1">
 *   <caption>forward と include</caption>
 *   <tr><th>&nbsp;</th><th>{@code forward}</th><th>{@code include}</th></tr>
 *   <tr><td>処理</td><td>渡したら<b>戻ってこない</b></td><td>差し込んだあと<b>戻ってくる</b></td></tr>
 *   <tr><td>それまでに書いた本文</td><td><b>捨てられる</b></td><td>残る</td></tr>
 *   <tr><td>呼ばれた側のヘッダ・ステータス</td><td>効く</td><td><b>無視される</b></td></tr>
 *   <tr><td>{@code getRequestURI()}</td><td>転送先になる</td><td>元のまま</td></tr>
 *   <tr><td>使いどころ</td><td>画面を丸ごと任せる (Servlet → JSP)</td>
 *       <td>画面の一部を差し込む (ヘッダー・メニュー)</td></tr>
 * </table>
 *
 * <h2>書いたあとでは forward できない</h2>
 * <p>forward は「それまでに書いた本文を捨てて、転送先にやり直させる」ものです。
 * すでに送信済み ({@code isCommitted()} が {@code true}) だと捨てられないので、
 * {@code IllegalStateException} になります
 * (「Servlet から直接出力する」のサンプルを参照)。</p>
 */
@WebServlet(name = "dispatcherIncludeDemo", urlPatterns = {"/samples/basic/dispatcher-include/demo"})
public class DispatcherIncludeDemoServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** 呼び出す部品。コンテキストパスは付けません (サーバの中の話なので)。 */
    static final String PART = "/samples/basic/dispatcher-include/part";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String mode = modeOf(request.getParameter("mode"));

        response.setContentType("text/plain; charset=UTF-8");

        // 部品に渡したい値は、リクエストスコープに入れておきます
        request.setAttribute("messageFromCaller", "呼び出し元から部品への伝言 (mode=" + mode + ")");

        PrintWriter out = response.getWriter();
        out.write("① 呼び出し元が最初に書いた行\n");

        RequestDispatcher dispatcher = request.getRequestDispatcher(PART);

        if ("forward".equals(mode)) {
            // forward : ここまでに書いた ① は捨てられ、部品の出力だけが残ります
            dispatcher.forward(request, response);

            // forward のあとにレスポンスへ書き込んではいけません。
            // 何が起きるかを見せるため、あえて書いて例外を捕まえています
            try {
                out.write("③ forward のあとに書いた行\n");
                out.flush();
                if (out.checkError()) {
                    throw new IllegalStateException("forward 後の書き込みは届きません");
                }
            } catch (IllegalStateException e) {
                // ここで書けたとしても、利用者には届きません (捨てられます)
                log("forward のあとの書き込み: " + e.getMessage());
            }
            return;
        }

        if ("forward-after-commit".equals(mode)) {
            // バッファ (既定 8KB) を超えるまで書いてから forward してみます
            out.write(ResponseOutputDemoServlet.filler(20000));
            out.write("\n");
            try {
                dispatcher.forward(request, response);
            } catch (IllegalStateException e) {
                out.write("\n② forward できませんでした : " + e + "\n");
                out.write("   すでに送り始めているので、①〜を捨ててやり直すことができません。\n");
            }
            return;
        }

        // include : 部品の出力がこの位置に差し込まれ、処理が戻ってきます
        dispatcher.include(request, response);
        out.write("③ 部品から戻ってきて、呼び出し元が続きを書いた行\n");
    }

    /** 呼び分けを、決めた 3 つに絞る。 */
    static String modeOf(String mode) {
        if ("forward".equals(mode) || "forward-after-commit".equals(mode)) {
            return mode;
        }
        return "include";
    }
}
