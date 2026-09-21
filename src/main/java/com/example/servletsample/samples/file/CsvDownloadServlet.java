package com.example.servletsample.samples.file;

import java.io.IOException;
import java.nio.charset.CharsetEncoder;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】CSV ダウンロード (説明ページ)。
 *
 * <p>選んだ設定で組み立てた CSV を<b>画面でそのまま見せて</b>から、
 * 同じ設定でダウンロードできるようにしています。
 * ダウンロードしたファイルをいちいちエディタで開かなくても、
 * エスケープの有無で何が変わるかを確かめられます。</p>
 *
 * <p>実際にファイルを書き出すのは {@link CsvExportServlet} です。</p>
 */
@WebServlet(name = "csvDownload", urlPatterns = {"/samples/file/csv-download"})
public class CsvDownloadServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/file/csv-download.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        CsvOptions options = CsvOptions.from(request);
        String text = options.build();

        request.setAttribute("options", options);
        request.setAttribute("encodings", CsvOptions.Encoding.values());
        request.setAttribute("csvText", text);
        request.setAttribute("records", SalesRecords.all());
        request.setAttribute("downloadUrl",
                request.getContextPath() + CsvExportServlet.PATH + "?" + options.query());

        // Shift_JIS を選んだときに、変換できない文字があるかを先に調べて知らせる
        request.setAttribute("lossyCharacters", lossyCharacters(options, text));

        // 実際に何バイトになるか (BOM の 3 バイトを含む)。
        // 同じ内容でも、文字コードによって大きさが変わることが分かります
        int bomLength = options.getEncoding().isBom() ? 3 : 0;
        request.setAttribute("byteLength",
                bomLength + text.getBytes(options.getEncoding().getCharset()).length);

        forward(request, response, VIEW);
    }

    /**
     * 選んだ文字コードで表せない文字を集める。
     *
     * <p>Shift_JIS には無い文字 (絵文字、一部の漢字、「～」など) は
     * <b>黙って {@code ?} に置き換わります</b>。
     * 例外にならないので、出したあとで気付くことになりがちです。
     * 出す前に確かめておくと、画面で知らせることができます。</p>
     */
    static String lossyCharacters(CsvOptions options, String text) {
        if (!options.getEncoding().isLossy()) {
            return "";
        }
        CharsetEncoder encoder = options.getEncoding().getCharset().newEncoder();
        StringBuilder lost = new StringBuilder();
        text.codePoints().forEach(codePoint -> {
            String character = new String(Character.toChars(codePoint));
            if (!encoder.canEncode(character) && lost.indexOf(character) < 0) {
                lost.append(character);
            }
        });
        return lost.toString();
    }
}
