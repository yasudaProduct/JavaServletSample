package com.example.servletsample.samples.file;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】ファイルとして保存されている PDF を返す。
 *
 * <pre>{@code
 * GET /samples/file/pdf-view/file?name=manual.pdf             → 画面に表示 (inline)
 * GET /samples/file/pdf-view/file?name=manual.pdf&download=1  → ダウンロード (attachment)
 * }</pre>
 *
 * <p>PDF を {@code /assets} のような公開フォルダに置けば、Servlet を書かなくても
 * Tomcat がそのまま返してくれます。それでも Servlet を通すのは、
 * <b>返す前にアプリが口を挟める</b>からです。</p>
 * <ul>
 *   <li>ログインしている人・権限のある人にだけ見せる</li>
 *   <li>誰がいつ開いたかを記録する</li>
 *   <li>置き場所を WAR の外 (サーバのフォルダや共有ストレージ) にできる</li>
 * </ul>
 *
 * <p>ファイル名は画面から受け取るため、{@link PdfFolder#find} で
 * フォルダの外へ出られないことを確かめてから開いています。</p>
 */
@WebServlet(name = "pdfFromFile", urlPatterns = {"/samples/file/pdf-view/file"})
public class PdfFromFileServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private transient PdfFolder folder;

    @Override
    public void init() throws ServletException {
        folder = PdfFolder.of(getServletContext());
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ① 名前からファイルを探す (../ などでフォルダの外を指していたら見つからない扱い)
        Optional<Path> found = folder.find(request.getParameter("name"));
        if (found.isEmpty()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "PDF が見つかりません");
            return;
        }
        Path file = found.get();

        // ② ヘッダ : application/pdf と inline / attachment
        PdfResponse.setHeaders(response, file.getFileName().toString(), Files.size(file),
                PdfResponse.wantsDownload(request));

        // ③ 本文 : ファイルの中身をそのまま流す (Files.copy は少しずつ読んで書く)
        try (OutputStream out = response.getOutputStream()) {
            Files.copy(file, out);
        }
    }
}
