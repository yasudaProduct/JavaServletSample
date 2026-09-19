package com.example.servletsample.samples.design;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】モーダルのサンプル ④ で、完了モーダルを閉じたあとに移動してくる画面。
 *
 * <p>登録した受付の一覧を出すだけの画面です。
 * 「完了を知らせてから次の画面へ送る」という流れの<b>行き先</b>にあたります。</p>
 *
 * <p>URL を完全一致 ({@code /samples/design/modal-dialog/entries}) で割り当てているため、
 * 前方一致の {@code /samples/*} より優先してこの Servlet が呼ばれます。</p>
 */
@WebServlet(name = "modalDialogEntries", urlPatterns = {ModalDialogServlet.ENTRIES_PATH})
public class ModalDialogEntriesServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/design/modal-dialog-entries.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("entries", ModalDialogServlet.entriesOf(request));
        forward(request, response, VIEW);
    }
}
