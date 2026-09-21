package com.example.servletsample.samples.basic;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】文字コードと文字化け。
 *
 * <p>文字化けが起きる場所は、大きく 3 つに分けられます。</p>
 *
 * <ol>
 *   <li><b>リクエストを読むとき</b> … ブラウザが送ってきたバイト列を、何の文字コードとして読むか</li>
 *   <li><b>レスポンスを書くとき</b> … 文字列を何の文字コードでバイト列にし、何と名乗るか</li>
 *   <li><b>ファイルを読み書きするとき</b> … ソース・properties・CSV・DB との受け渡し</li>
 * </ol>
 *
 * <p>このサンプルは 1 と 2 を扱います。3 のうち CSV については
 * 「ファイル &gt; CSV ダウンロード」が BOM まで含めて扱っています。</p>
 *
 * <h2>このアプリでの設定</h2>
 * <p>{@code web.xml} に次の 2 行を書いてあるので、Servlet 側で
 * {@code request.setCharacterEncoding("UTF-8")} を書く必要がありません
 * (Servlet 4.0 で入った書き方です)。</p>
 *
 * <pre>{@code
 * <request-character-encoding>UTF-8</request-character-encoding>
 * <response-character-encoding>UTF-8</response-character-encoding>
 * }</pre>
 *
 * <p>Servlet 3.1 以前は、フィルタで全リクエストに
 * {@code setCharacterEncoding} を掛けるのが定番でした。
 * <b>どちらにしても {@code getParameter} より前に指定する</b>必要があります。
 * 一度読み始めてからでは手遅れです。</p>
 */
@WebServlet(name = "characterEncoding", urlPatterns = {"/samples/basic/character-encoding"})
public class CharacterEncodingServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** 化け方の一覧に使う既定の文字列。 */
    static final String DEFAULT_TEXT = "文字化け";

    /** 「Shift_JIS のリンク」デモで送る文字列。 */
    static final String LEGACY_TEXT = "売上一覧";

    /** 古いシステムを想定した文字コード。 */
    static final String LEGACY_CHARSET = "windows-31j";

    private static final String SAMPLE_PATH = "/samples/basic/character-encoding";

    private static final String VIEW = "/WEB-INF/views/samples/basic/character-encoding.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        show(request, response);
    }

    /** GET と POST で受け取り方が変わるかを見せたいので、POST も同じ画面を返します。 */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        show(request, response);
    }

    private void show(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ------------------------------------------------------------------
        // ① いまの設定。request 側はコンテナが web.xml を見て決めています
        // ------------------------------------------------------------------
        request.setAttribute("requestEncoding", request.getCharacterEncoding());
        request.setAttribute("responseEncoding", response.getCharacterEncoding());
        request.setAttribute("contextRequestEncoding",
                getServletContext().getRequestCharacterEncoding());
        request.setAttribute("contextResponseEncoding",
                getServletContext().getResponseCharacterEncoding());
        request.setAttribute("fileEncoding", System.getProperty("file.encoding"));
        request.setAttribute("requestMethod", request.getMethod());
        request.setAttribute("queryString", request.getQueryString());

        // ------------------------------------------------------------------
        // ② 送られてきた日本語。GET でも POST でも同じように受け取れているかを見る
        // ------------------------------------------------------------------
        String sent = request.getParameter("sent");
        if (sent != null) {
            request.setAttribute("sent", sent);
            request.setAttribute("sentLength", sent.length());
            request.setAttribute("sentHex", Mojibake.toHex(sent, "UTF-8"));
        }

        // ------------------------------------------------------------------
        // ③ 化け方の一覧。実際のリクエストは壊さず、Java の中で再現します
        // ------------------------------------------------------------------
        String text = request.getParameter("text");
        if (text == null || text.isEmpty()) {
            text = DEFAULT_TEXT;
        }
        request.setAttribute("text", text);
        request.setAttribute("textHex", Mojibake.toHex(text, "UTF-8"));
        request.setAttribute("conversions", Mojibake.patterns(text));

        // ------------------------------------------------------------------
        // ④ 古いシステムから Shift_JIS で組み立てられたリンクが来たら、という想定
        // ------------------------------------------------------------------
        request.setAttribute("legacyLink", legacyLink(request.getContextPath()));
        String legacy = request.getParameter("q");
        if (legacy != null) {
            // コンテナが読んだ値 (Tomcat 8 以降はクエリ文字列も既定で UTF-8 として読む)
            request.setAttribute("legacyAsRead", legacy);
            request.setAttribute("legacyAsReadHex", Mojibake.toHex(legacy, "UTF-8"));
            // 生のクエリ文字列まで戻って、正しい文字コードで読み直したもの
            request.setAttribute("legacyRecovered",
                    Mojibake.recoverParameter(request.getQueryString(), "q", LEGACY_CHARSET));
        }

        forward(request, response, VIEW);
    }

    /**
     * 「Shift_JIS で組み立てられたリンク」を作る。
     *
     * <p>{@code %E5%A3%B2...} (UTF-8) ではなく {@code %94%84...} (Shift_JIS) になります。</p>
     */
    static String legacyLink(String contextPath) {
        return contextPath + SAMPLE_PATH + "?q="
                + Mojibake.encodeForQuery(LEGACY_TEXT, LEGACY_CHARSET);
    }
}
