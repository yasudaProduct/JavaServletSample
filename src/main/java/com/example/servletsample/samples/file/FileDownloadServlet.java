package com.example.servletsample.samples.file;

import java.io.IOException;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】データベースに保存したファイルのダウンロード。
 *
 * <p>ダウンロードは「レスポンスに HTML ではなくファイルの中身を書く」だけです。
 * ブラウザに保存ダイアログを出させるため、次のヘッダを付けます。</p>
 * <ul>
 *   <li>{@code Content-Type} … ファイルの種類</li>
 *   <li>{@code Content-Length} … バイト数 (進捗バーが出せる)</li>
 *   <li>{@code Content-Disposition: attachment; filename=...} … 保存させる / ファイル名を伝える</li>
 * </ul>
 *
 * <p>日本語のファイル名は、そのままではヘッダに書けません。
 * 古いブラウザ向けの {@code filename="..."} と、
 * RFC 6266 の {@code filename*=UTF-8''...} を両方並べるのが定石です。</p>
 */
@WebServlet(name = "fileDownload", urlPatterns = {"/samples/file/file-upload/download"})
public class FileDownloadServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private final StoredFileDao dao = new StoredFileDao();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        long id = FileUploadServlet.parseId(request.getParameter("id"));
        StoredFile file = id < 0 ? null : dao.findById(id);
        if (file == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "ファイルが見つかりません");
            return;
        }

        response.setContentType(file.getContentType());
        response.setContentLengthLong(file.getSize());
        response.setHeader("Content-Disposition", contentDisposition(file.getFileName()));
        // ブラウザに中身を見て種類を推測させない (アップロードされた HTML が実行されるのを防ぐ)
        response.setHeader("X-Content-Type-Options", "nosniff");

        try (OutputStream out = response.getOutputStream()) {
            if (!dao.copyContentTo(id, out)) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "ファイルが見つかりません");
            }
        }
    }

    /**
     * {@code Content-Disposition} ヘッダの値を組み立てる。
     *
     * <p>例: {@code attachment; filename="_____.png"; filename*=UTF-8''%E5%86%99%E7%9C%9F.png}</p>
     */
    static String contentDisposition(String fileName) {
        return "attachment; filename=\"" + asciiFallback(fileName) + "\""
                + "; filename*=UTF-8''" + encode(fileName);
    }

    /** ASCII 以外と記号を {@code _} に置き換えた、古いブラウザ向けのファイル名。 */
    private static String asciiFallback(String fileName) {
        StringBuilder builder = new StringBuilder(fileName.length());
        for (int i = 0; i < fileName.length(); i++) {
            char c = fileName.charAt(i);
            builder.append(c < 0x20 || c > 0x7e || c == '"' || c == '\\' ? '_' : c);
        }
        return builder.toString();
    }

    /** RFC 6266 の {@code filename*} 用にパーセントエンコードする。 */
    private static String encode(String fileName) {
        try {
            // URLEncoder は半角スペースを + にするが、ヘッダでは %20 でなければならない
            return URLEncoder.encode(fileName, StandardCharsets.UTF_8.name()).replace("+", "%20");
        } catch (UnsupportedEncodingException e) {
            throw new IllegalStateException("UTF-8 が使えない環境です", e);
        }
    }
}
