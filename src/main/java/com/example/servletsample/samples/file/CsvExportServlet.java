package com.example.servletsample.samples.file;

import java.io.IOException;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】CSV ファイルをダウンロードさせる。
 *
 * <p>やることは 3 つだけです。</p>
 * <ol>
 *   <li>{@code Content-Type} と文字コードを決める</li>
 *   <li>{@code Content-Disposition} で「ダウンロードさせる」「ファイル名はこれ」と伝える</li>
 *   <li>本文を書く</li>
 * </ol>
 *
 * <h2>JSP を通さない</h2>
 * <p>ファイルを返すときは JSP へ {@code forward} しません。
 * JSP は HTML を組み立てるためのもので、
 * <b>タグの外にある改行がそのままファイルに混ざります</b>。
 * Servlet から直接書き出します。</p>
 *
 * <h2>文字コードと BOM</h2>
 * <p>「Excel で開いたら文字化けした」の原因はほぼこれです。</p>
 *
 * <table border="1">
 *   <caption>文字コードの選び方</caption>
 *   <tr><th>渡す相手</th><th>選ぶもの</th><th>理由</th></tr>
 *   <tr><td>Excel で開く人</td><td><b>UTF-8 + BOM</b></td>
 *       <td>BOM が無いと、Excel は環境の既定 (日本語 Windows なら Shift_JIS) として読みます</td></tr>
 *   <tr><td>プログラム</td><td>UTF-8 (BOM なし)</td>
 *       <td>BOM は 1 列目の値に紛れ込んで事故のもとになります</td></tr>
 *   <tr><td>古いシステム</td><td>Windows-31J</td>
 *       <td>いわゆる Shift_JIS。<b>変換できない文字は化けます</b></td></tr>
 * </table>
 *
 * <p>BOM は「このファイルは UTF-8 です」という 3 バイトの目印です。
 * {@code Content-Type} の {@code charset} だけでは Excel には伝わりません
 * (ダウンロードしたあとはただのファイルで、HTTP ヘッダは残らないためです)。</p>
 *
 * <h2>日本語のファイル名</h2>
 * <p>{@code Content-Disposition} ヘッダには、そのままでは ASCII しか書けません。
 * 日本語のファイル名は {@code filename*} (RFC 5987 / RFC 6266) で渡します。</p>
 *
 * <pre>{@code
 * Content-Disposition: attachment; filename="sales.csv"; filename*=UTF-8''%E5%A3%B2%E4%B8%8A.csv
 *                                  ~~~~~~~~~~~~~~~~~~~  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *                                  読めない環境向けの控え   本命 (UTF-8 で URL エンコード)
 * }</pre>
 *
 * <p>両方書いておくと、{@code filename*} を理解するブラウザはそちらを、
 * 理解しないものは {@code filename} を使います。</p>
 */
@WebServlet(name = "csvExport", urlPatterns = {"/samples/file/csv-download/export"})
public class CsvExportServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** この URL。 */
    static final String PATH = "/samples/file/csv-download/export";

    /** 日本語のファイル名 (filename* で渡す)。 */
    static final String FILE_NAME = "売上明細.csv";

    /** 日本語を読めない環境向けの控え。 */
    static final String FALLBACK_FILE_NAME = "sales.csv";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        CsvOptions options = CsvOptions.from(request);
        String text = options.build();

        // ------------------------------------------------ ① Content-Type
        // text/csv と書いておくと、ブラウザが表計算ソフトに関連付けてくれます。
        // 「とにかくダウンロードさせたい」なら application/octet-stream でも構いません
        response.setContentType("text/csv");
        response.setCharacterEncoding(options.getEncoding().getCharset().name());

        // ------------------------------------------------ ② Content-Disposition
        response.setHeader("Content-Disposition", contentDisposition(
                options.isTabDelimited() ? tsvName(FILE_NAME) : FILE_NAME,
                options.isTabDelimited() ? tsvName(FALLBACK_FILE_NAME) : FALLBACK_FILE_NAME));

        // 個人情報を含むことが多いので、中継サーバに残させない
        response.setHeader("Cache-Control", "no-store");

        // ------------------------------------------------ ③ 本文
        //
        // Writer ではなく OutputStream を使っています。
        // BOM は「3 バイトのデータ」であって文字ではないので、
        // バイトのまま書けるこちらのほうが扱いを間違えません
        byte[] bom = options.getEncoding().isBom()
                ? new byte[] {(byte) 0xEF, (byte) 0xBB, (byte) 0xBF}
                : new byte[0];
        byte[] body = text.getBytes(options.getEncoding().getCharset());

        // 長さを伝えておくと、ブラウザが進捗を出せます
        response.setContentLength(bom.length + body.length);

        try (OutputStream out = response.getOutputStream()) {
            out.write(bom);
            out.write(body);
        }
    }

    /**
     * {@code Content-Disposition} ヘッダの値を組み立てる。
     *
     * @param fileName         本命のファイル名 (日本語可)
     * @param fallbackFileName 日本語を読めない環境向けの控え (ASCII のみ)
     */
    static String contentDisposition(String fileName, String fallbackFileName) {
        // URLEncoder はスペースを + にするが、RFC 5987 では %20 でなければならない
        String encoded = URLEncoder.encode(fileName, StandardCharsets.UTF_8).replace("+", "%20");
        return "attachment; filename=\"" + fallbackFileName + "\"; filename*=UTF-8''" + encoded;
    }

    /** 拡張子を .tsv に差し替える。 */
    private static String tsvName(String fileName) {
        return fileName.replace(".csv", ".tsv");
    }
}
