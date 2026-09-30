package com.example.servletsample.samples.file;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】PDF を画面に表示する (一覧の画面)。
 *
 * <p>この Servlet は「どんな PDF があるか」を集めて JSP へ渡すだけです。
 * PDF の中身を返すのは別の Servlet です。</p>
 * <ul>
 *   <li>{@link PdfFromFileServlet} … サーバのフォルダに置いた PDF</li>
 *   <li>{@link PdfFromDbServlet} … データベースの BLOB 列に入れた PDF</li>
 * </ul>
 *
 * <p>埋め込み・別タブ・ポップアップといった<b>見せ方の違いは、すべて画面 (JSP) 側</b>で決まります。
 * サーバから見れば、どれも「PDF の URL が 1 回開かれた」だけです。</p>
 */
@WebServlet(name = "pdfView", urlPatterns = {"/samples/file/pdf-view"})
public class PdfViewServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/file/pdf-view.jsp";

    private transient PdfFolder folder;

    private final PdfDocumentDao dao = new PdfDocumentDao();

    @Override
    public void init() throws ServletException {
        folder = PdfFolder.of(getServletContext());
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("folderLocation", PdfFolder.LOCATION);
        request.setAttribute("folderFiles", folder.list());
        request.setAttribute("documents", dao.findAll());
        forward(request, response, VIEW);
    }
}
