package com.example.servletsample.samples.file;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;

/**
 * 【サンプル】ファイルのアップロード・削除 (中身はデータベースに保存)。
 *
 * <p>ファイル送信のポイントは 3 つです。</p>
 * <ol>
 *   <li>フォームに {@code enctype="multipart/form-data"} と {@code method="post"} を付ける</li>
 *   <li>Servlet に {@link MultipartConfig @MultipartConfig} を付ける
 *       (これが無いと {@code getPart()} が例外になります)</li>
 *   <li>{@code request.getPart("名前")} で受け取り、{@code getInputStream()} で中身を読む</li>
 * </ol>
 *
 * <p>登録・削除のあとはリダイレクトしています (PRG パターン)。
 * そのまま画面を表示すると、ブラウザの再読み込みで同じファイルがもう一度登録されてしまうためです。</p>
 */
@WebServlet(name = "fileUpload", urlPatterns = {"/samples/file/file-upload"})
@MultipartConfig(
        // これを超えた分はメモリではなく一時ファイルに書き出される
        fileSizeThreshold = 512 * 1024,
        // ファイル 1 つの上限 (Tomcat が判断する。超えると getPart() が例外を投げる)
        maxFileSize = 5L * 1024 * 1024,
        // リクエスト全体の上限
        maxRequestSize = 6L * 1024 * 1024)
public class FileUploadServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/file/file-upload.jsp";

    /** アプリ側で許可する 1 ファイルの上限 (2 MB)。 */
    static final long MAX_FILE_SIZE = 2L * 1024 * 1024;

    /** 保存できる件数の上限 (公開中のデモなので、際限なく溜まらないようにする)。 */
    static final int MAX_FILES = 20;

    /** 保存できる合計サイズの上限 (16 MB)。 */
    static final long MAX_TOTAL_SIZE = 16L * 1024 * 1024;

    private final StoredFileDao dao = new StoredFileDao();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // リダイレクト元から渡されたメッセージを取り出す (あれば完了モーダルが開く)
        Flash.consume(request);

        List<StoredFile> files = dao.findAll();
        request.setAttribute("files", files);
        request.setAttribute("totalSizeText", StoredFile.formatSize(dao.totalSize()));
        request.setAttribute("maxFileSize", MAX_FILE_SIZE);
        request.setAttribute("maxFileSizeText", StoredFile.formatSize(MAX_FILE_SIZE));
        request.setAttribute("maxFiles", MAX_FILES);
        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            if ("delete".equals(request.getParameter("action"))) {
                delete(request);
            } else {
                upload(request);
            }
        } catch (IllegalStateException e) {
            // Tomcat 側の上限 (maxFileSize / maxRequestSize) を超えたときはここに来る
            Flash.set(request, "danger", "アップロードできませんでした",
                    "ファイルが大きすぎます。" + StoredFile.formatSize(MAX_FILE_SIZE) + " 以下にしてください。");
        }

        // PRG パターン : 処理のあとは必ずリダイレクトして、再読み込みでの二重送信を防ぐ
        response.sendRedirect(request.getContextPath() + "/samples/file/file-upload");
    }

    /** 送られてきたファイルをデータベースへ保存する。 */
    private void upload(HttpServletRequest request) throws ServletException, IOException {
        Part part = request.getPart("file");
        String fileName = sanitizeFileName(part == null ? null : part.getSubmittedFileName());

        if (part == null || fileName.isEmpty() || part.getSize() == 0) {
            Flash.set(request, "warning", "ファイルが選ばれていません",
                    "アップロードするファイルを選んでから実行してください。");
            return;
        }
        if (part.getSize() > MAX_FILE_SIZE) {
            Flash.set(request, "danger", "アップロードできませんでした",
                    "ファイルサイズが上限 (" + StoredFile.formatSize(MAX_FILE_SIZE) + ") を超えています。");
            return;
        }
        if (dao.findAll().size() >= MAX_FILES) {
            Flash.set(request, "warning", "これ以上保存できません",
                    "保存できるのは " + MAX_FILES + " 件までです。不要なファイルを削除してください。");
            return;
        }
        if (dao.totalSize() + part.getSize() > MAX_TOTAL_SIZE) {
            Flash.set(request, "warning", "これ以上保存できません",
                    "合計サイズが上限 (" + StoredFile.formatSize(MAX_TOTAL_SIZE) + ") を超えます。");
            return;
        }

        String contentType = part.getContentType();
        if (contentType == null || contentType.isEmpty()) {
            contentType = "application/octet-stream";
        }

        try (InputStream in = part.getInputStream()) {
            dao.save(fileName, contentType, part.getSize(), in);
        }
        Flash.set(request, "success", "アップロードしました",
                fileName + " (" + StoredFile.formatSize(part.getSize()) + ") を保存しました。");
    }

    /** 選択されたファイルを削除する。 */
    private void delete(HttpServletRequest request) {
        long id = parseId(request.getParameter("id"));
        StoredFile file = id < 0 ? null : dao.findById(id);

        if (file == null) {
            Flash.set(request, "warning", "削除できませんでした",
                    "対象のファイルが見つかりませんでした (すでに削除された可能性があります)。");
            return;
        }
        dao.delete(id);
        Flash.set(request, "success", "削除しました", file.getFileName() + " を削除しました。");
    }

    /**
     * ファイル名を安全な形に整える。
     *
     * <p>ブラウザによってはフルパス ({@code C:\Users\...\photo.png}) が送られてくるため、
     * 最後の区切り以降だけを使います。{@code ../} のような文字列を弾く意味もあります。</p>
     */
    static String sanitizeFileName(String submitted) {
        if (submitted == null) {
            return "";
        }
        String name = submitted.trim();
        int slash = Math.max(name.lastIndexOf('/'), name.lastIndexOf('\\'));
        if (slash >= 0) {
            name = name.substring(slash + 1);
        }
        // 制御文字を除く
        name = name.replaceAll("[\\p{Cntrl}]", "");
        if (name.length() > 255) {
            name = name.substring(0, 255);
        }
        return name.trim();
    }

    /** 数字以外が来ても落ちないように変換する。変換できなければ -1。 */
    static long parseId(String value) {
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException | NullPointerException e) {
            return -1L;
        }
    }
}
