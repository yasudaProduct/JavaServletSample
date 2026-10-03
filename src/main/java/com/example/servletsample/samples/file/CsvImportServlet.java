package com.example.servletsample.samples.file;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import org.apache.logging.log4j.CloseableThreadContext;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;

/**
 * 【サンプル】CSV 取り込み (入力チェックとエラー時のログ)。
 *
 * <p>この Servlet の仕事は、<b>ファイルを受け取って {@link CsvImporter} に渡し、結果を画面に出す</b>ことです。
 * チェックの中身は {@link CsvImporter} と {@link EmployeeCsvRow} にあります。</p>
 *
 * <h2>エラーは 3 種類に分けて扱う</h2>
 * <table border="1">
 *   <caption>エラーの種類と扱い方</caption>
 *   <tr><th>種類</th><th>例</th><th>扱い方</th><th>ログ</th></tr>
 *   <tr><td>入力の誤り</td><td>必須が空、日付の形が違う</td>
 *       <td>例外にしない。行番号つきで画面に並べる</td><td>WARN (件数のみ)</td></tr>
 *   <tr><td>ファイルの問題</td><td>文字コード違い、見出しが違う</td>
 *       <td>例外にしない。どうすればよいかを画面に出す</td><td>WARN (理由)</td></tr>
 *   <tr><td>システムの異常</td><td>DB に書けない</td>
 *       <td><b>ここで受け止め</b>、問い合わせ番号を出す</td><td>ERROR (スタックトレース付き)</td></tr>
 * </table>
 *
 * <h2>取り込み ID をすべてのログ行に付ける</h2>
 * <p>{@link CloseableThreadContext#put} で、このスレッドの「文脈」に取り込み ID を入れています。
 * 以後、このスレッドで出したログには ({@code DAO} の中で出したものも含めて)
 * 書式の {@code %X{importId}} の位置に同じ ID が付きます。</p>
 *
 * <p>try-with-resources で囲んでいるのは、<b>抜けるときに必ず消すため</b>です。
 * Tomcat はスレッドを使い回すので、消し忘れると<b>次に来た別の人のリクエストに
 * 前の人の ID が付いたまま</b>になります。</p>
 */
@WebServlet(name = "csvImport", urlPatterns = {"/samples/file/csv-import"})
@MultipartConfig(
        // これを超えた分はメモリではなく一時ファイルに書き出される
        fileSizeThreshold = 256 * 1024,
        // ファイル 1 つの上限 (Tomcat が判断する。超えると getPart() が例外を投げる)
        maxFileSize = 1024 * 1024,
        // リクエスト全体の上限
        maxRequestSize = 2 * 1024 * 1024)
public class CsvImportServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final Logger LOG = LogManager.getLogger(CsvImportServlet.class);

    /** この URL。 */
    static final String PATH = "/samples/file/csv-import";

    private static final String VIEW = "/WEB-INF/views/samples/file/csv-import.jsp";

    /** 結果をリダイレクト先へ渡すときのセッションのキー。 */
    private static final String RESULT_KEY = "servletSample.csvImportResult";

    private final ImportedEmployeeDao dao = new ImportedEmployeeDao();

    private final CsvImporter importer = new CsvImporter(dao);

    @Override
    public void init() throws ServletException {
        // 画面にログを出すための仕掛け (実際のアプリには要らない)
        ImportLogAppender.install();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 直前の取り込み結果 (PRG パターンでセッションに預けたもの) を 1 回だけ取り出す
        CsvImportResult result = takeResult(request);
        if (result != null) {
            request.setAttribute("result", result);
            request.setAttribute("logLines", ImportLogAppender.linesOf(result.getImportId()));
        }
        Flash.consume(request);

        request.setAttribute("sampleFiles", CsvImportTemplateServlet.SampleFile.values());
        request.setAttribute("columns", EmployeeCsvRow.Column.values());
        request.setAttribute("departments", EmployeeCsvRow.DEPARTMENTS);
        request.setAttribute("employmentTypes", EmployeeCsvRow.EMPLOYMENT_TYPES);
        request.setAttribute("employees", dao.findAll());
        request.setAttribute("maxEmployees", CsvImporter.MAX_EMPLOYEES);
        request.setAttribute("maxRows", CsvImporter.MAX_ROWS);
        request.setAttribute("maxFileSizeKb", CsvImporter.MAX_FILE_SIZE / 1024);
        forward(request, response, VIEW);
    }

    @Override
    @SuppressWarnings("try")   // context は「抜けるときに閉じる」ためだけに持つ (中では使わない)
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if ("reset".equals(request.getParameter("action"))) {
            dao.reset();
            Flash.set(request, "success", "初期状態に戻しました", "社員を最初の 3 人だけにしました。");
            response.sendRedirect(request.getContextPath() + PATH);
            return;
        }

        String importId = CsvImporter.newImportId();
        CsvImportResult result;
        // ここから閉じるまでの間に出たログには、すべて [importId] が付く
        try (CloseableThreadContext.Instance context =
                     CloseableThreadContext.put(CsvImporter.IMPORT_ID_KEY, importId)) {
            result = receive(request, importId);
        }

        // PRG パターン : 結果をセッションに預けてリダイレクトする (再読み込みで二重に取り込ませない)
        request.getSession().setAttribute(RESULT_KEY, result);
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /** ファイルを受け取って取り込む。 */
    private CsvImportResult receive(HttpServletRequest request, String importId)
            throws ServletException, IOException {

        Part part;
        try {
            part = request.getPart("file");
        } catch (IllegalStateException e) {
            // Tomcat 側の上限 (@MultipartConfig) を超えた。
            // 起こりうると分かっている失敗なので、スタックトレースは出さない
            LOG.warn("リクエストが大きすぎるため受け取りませんでした");
            return CsvImportResult.rejected(importId, "",
                    "ファイルが大きすぎます。" + (CsvImporter.MAX_FILE_SIZE / 1024) + " KB 以下にしてください。");
        }

        // ファイル名は利用者が付けた文字列。ディレクトリ部分と制御文字 (改行など) を落とす。
        // 改行を残したままログに出すと、偽のログ行を差し込まれる (ログインジェクション)
        String fileName = FileUploadServlet.sanitizeFileName(part == null ? null : part.getSubmittedFileName());
        byte[] content = read(part);
        Charset charset = "sjis".equals(request.getParameter("encoding"))
                ? CsvImporter.WINDOWS_31J : StandardCharsets.UTF_8;
        boolean breakHalfway = request.getParameter("breakHalfway") != null;

        try {
            return importer.importCsv(importId, fileName, content, charset, breakHalfway);
        } catch (RuntimeException e) {
            // システムの異常。受け止めるのはここ 1 か所だけにして、ERROR で残す。
            // 例外は最後の引数にそのまま渡す ({} の数より 1 つ多い引数は例外として扱われる)。
            // e.getMessage() だけを文字列にすると、発生場所と原因 (Caused by) が消えてしまう
            LOG.error("取り込みに失敗しました file={} size={}B", fileName, content.length, e);
            return CsvImportResult.failed(importId, fileName);
        }
    }

    /**
     * ファイルの中身を読む。上限を 1 バイトだけ超えたところで読むのをやめる。
     *
     * <p>上限ちょうどで止めると「ちょうど上限の大きさ」と「もっと大きい」の区別が付かないので、
     * 1 バイト多く読み、超えていたら {@link CsvImporter} が差し戻します。</p>
     */
    private static byte[] read(Part part) throws IOException {
        if (part == null) {
            return new byte[0];
        }
        try (InputStream in = part.getInputStream()) {
            return in.readNBytes(CsvImporter.MAX_FILE_SIZE + 1);
        }
    }

    /** セッションから結果を取り出して消す (無ければ null)。 */
    private static CsvImportResult takeResult(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }
        Object result = session.getAttribute(RESULT_KEY);
        session.removeAttribute(RESULT_KEY);
        return result instanceof CsvImportResult ? (CsvImportResult) result : null;
    }
}
