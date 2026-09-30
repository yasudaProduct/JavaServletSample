package com.example.servletsample.samples.file;

import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】データベースに保存されている PDF を返す。
 *
 * <pre>{@code
 * GET /samples/file/pdf-view/db?id=1             → 画面に表示 (inline)
 * GET /samples/file/pdf-view/db?id=1&download=1  → ダウンロード (attachment)
 * }</pre>
 *
 * <p>画面側の「埋め込み」「別タブ」「ポップアップ」は、どれもこの URL を開いているだけです。
 * 見せ方を変えても、サーバ側の処理は 1 つで済みます。</p>
 *
 * <h2>実務で足すもの : 見てよい人かどうかの確認</h2>
 * <p>{@code ?id=1} を {@code ?id=2} に書き換えれば、他人の請求書を開けてしまいます。
 * 実務では「ログインしている人がこの帳票を見てよいか」を、
 * 中身を返す前に必ず確かめてください (このサンプルは誰でも見られる前提で省いています)。</p>
 * <pre>{@code
 * PdfDocument document = dao.findById(id);
 * if (document == null || !permissions.canView(loginUser, document)) {   // canView は自分で用意する
 *     response.sendError(404);   // 403 にすると「その ID は存在する」ことが分かってしまう
 *     return;
 * }
 * }</pre>
 */
@WebServlet(name = "pdfFromDb", urlPatterns = {"/samples/file/pdf-view/db"})
public class PdfFromDbServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private final PdfDocumentDao dao = new PdfDocumentDao();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ① ID から探す (中身はまだ読まない)
        long id = parseId(request.getParameter("id"));
        PdfDocument document = id < 0 ? null : dao.findById(id);
        if (document == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "PDF が見つかりません");
            return;
        }

        // ② ヘッダ : application/pdf と inline / attachment
        PdfResponse.setHeaders(response, document.getFileName(), document.getSize(),
                PdfResponse.wantsDownload(request));

        // 見積書・請求書のような帳票は個人情報を含むので、
        // 途中の中継サーバやブラウザのキャッシュに残させない
        response.setHeader("Cache-Control", "no-store");

        // ③ 本文 : BLOB を読みながらそのままレスポンスへ流す
        try (OutputStream out = response.getOutputStream()) {
            dao.copyContentTo(id, out);
        }
    }

    /** 数字以外が来ても落ちないように変換する。変換できなければ -1。 */
    static long parseId(String value) {
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException e) {
            return -1L;
        }
    }
}
