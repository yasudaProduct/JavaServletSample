package com.example.servletsample.samples.basic;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】Servlet から直接出力する（getWriter とバッファ）。
 *
 * <p>Servlet は JSP を経由しなくても、自分で HTML を書き出せます。
 * にもかかわらず、このサイトを含めてほとんどの画面が JSP へ forward しているのは、
 * <b>HTML を Java の文字列として書くと読めなくなる</b>からです。</p>
 *
 * <pre>{@code
 * // Servlet の中で HTML を組み立てる (見づらく、エスケープも忘れやすい)
 * out.write("<table>");
 * for (Product product : products) {
 *     out.write("<tr><td>" + product.getName() + "</td></tr>");   // ← XSS
 * }
 * out.write("</table>");
 * }</pre>
 *
 * <p>とはいえ、直接書き出す場面もあります。JSON を返す API、CSV や PDF のダウンロード、
 * 画像の出力などです。そのときに知っておくことをまとめたのがこのサンプルです。</p>
 *
 * <ul>
 *   <li>文字で書くなら {@code getWriter()}、バイトで書くなら {@code getOutputStream()}。
 *       <b>同じレスポンスで両方は使えません</b></li>
 *   <li>{@code setContentType} は<b>書き始める前</b>に。あとから変えても効きません</li>
 *   <li>書いた内容はいったんバッファにたまる。<b>送り始めたら、もう取り消せません</b></li>
 * </ul>
 */
@WebServlet(name = "responseOutput", urlPatterns = {"/samples/basic/response-output"})
public class ResponseOutputServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/basic/response-output.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // この時点ではまだ何も書いていないので、必ず false です
        request.setAttribute("committedBeforeForward", response.isCommitted());

        // Servlet の既定のバッファの大きさ (Tomcat では 8192 バイト)。
        // このあと forward した JSP は、web.xml の <jsp-config> で 64kb に広げています
        request.setAttribute("bufferSize", response.getBufferSize());
        request.setAttribute("demoPath", request.getContextPath() + "/samples/basic/response-output/demo");

        forward(request, response, VIEW);
    }
}
