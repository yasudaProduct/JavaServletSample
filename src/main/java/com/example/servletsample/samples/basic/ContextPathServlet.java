package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】コンテキストパスと相対パス。
 *
 * <p>「自分の環境では動いたのに、配備したら CSS と画像だけ出ない」。
 * その多くは、リンクの書き方がコンテキストパスを考えていないことが原因です。</p>
 *
 * <p>コンテキストパスとは、アプリがサーバのどこに置かれているかを表す部分です。</p>
 *
 * <pre>
 *   http://localhost:8080/samples/basic/context-path        ← ROOT に配備 (コンテキストパスは空文字)
 *   http://localhost:8080/app/samples/basic/context-path    ← /app に配備 (コンテキストパスは /app)
 *                        ^^^^
 * </pre>
 *
 * <p>やっかいなのは、<b>ROOT に配備していると間違いに気付けない</b>ことです。
 * コンテキストパスが空文字なので、{@code /assets/...} と書いてもたまたま動きます。
 * このサイトも ROOT 配備なので、画面では「{@code /app} に置いたらどうなるか」を
 * 並べて表示しています。</p>
 *
 * <p>この Servlet は末尾スラッシュ付きの URL でも受けられるように、
 * 2 つのパターンを登録しています。相対パスの基準が変わることを見せるためです。</p>
 */
@WebServlet(name = "contextPath", urlPatterns = {
        "/samples/basic/context-path",
        "/samples/basic/context-path/"})
public class ContextPathServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** 実際に置いてあるファイル (コンテキストパスを除いた位置)。 */
    static final String TARGET = "/assets/favicon.svg";

    /** 「もし /app に配備したら」を見せるための、仮のコンテキストパス。 */
    static final String OTHER_CONTEXT = "/app";

    private static final String VIEW = "/WEB-INF/views/samples/basic/context-path.jsp";

    /** 書き方 1 通り分。 */
    public static final class Link {

        private final String href;
        private final String description;
        private final String resolvedNow;
        private final String resolvedOther;
        private final boolean brokenNow;
        private final boolean brokenOther;

        Link(String href, String description, String resolvedNow, String resolvedOther,
                boolean brokenNow, boolean brokenOther) {
            this.href = href;
            this.description = description;
            this.resolvedNow = resolvedNow;
            this.resolvedOther = resolvedOther;
            this.brokenNow = brokenNow;
            this.brokenOther = brokenOther;
        }

        /** HTML に書く文字列。 */
        public String getHref() {
            return href;
        }

        /** 書き方の名前。 */
        public String getDescription() {
            return description;
        }

        /** いまの配備で、ブラウザが実際に取りに行く先。 */
        public String getResolvedNow() {
            return resolvedNow;
        }

        /** {@code /app} に配備したときに取りに行く先。 */
        public String getResolvedOther() {
            return resolvedOther;
        }

        /** いまの配備で 404 になるか。 */
        public boolean isBrokenNow() {
            return brokenNow;
        }

        /** {@code /app} に配備したときに 404 になるか。 */
        public boolean isBrokenOther() {
            return brokenOther;
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String contextPath = request.getContextPath();
        // forward すると getRequestURI() は転送先の JSP を指すので、ここで控えておきます
        String currentPath = request.getRequestURI();

        request.setAttribute("contextPath", contextPath);
        request.setAttribute("currentPath", currentPath);
        request.setAttribute("requestUrl", String.valueOf(request.getRequestURL()));
        request.setAttribute("endsWithSlash", currentPath.endsWith("/"));
        request.setAttribute("links", links(contextPath, currentPath));
        request.setAttribute("targetPath", contextPath + TARGET);

        forward(request, response, VIEW);
    }

    /**
     * 3 通りの書き方が、それぞれどこを指すかを組み立てる。
     *
     * <p>いまの配備 (コンテキストパスは空文字) と、{@code /app} に配備した場合を並べます。</p>
     */
    static List<Link> links(String contextPath, String currentPath) {
        // /app に配備したときの、この画面の URL
        String otherPath = OTHER_CONTEXT + currentPath.substring(contextPath.length());

        List<Link> links = new ArrayList<>();

        // ① サーバのルートから。書く文字列は配備先が変わっても同じなので、/app では壊れる
        links.add(link(TARGET, TARGET, "サーバのルートから書く",
                contextPath, currentPath, otherPath));

        // ② 相対。いまの URL のディレクトリが基準になるので、どちらでも壊れる
        String relative = TARGET.substring(1);
        links.add(link(relative, relative, "相対で書く",
                contextPath, currentPath, otherPath));

        // ③ コンテキストパスから組み立てる。配備先が変われば、書き出される文字列も変わる
        links.add(link(contextPath + TARGET, OTHER_CONTEXT + TARGET,
                "コンテキストパスから組み立てる", contextPath, currentPath, otherPath));

        return links;
    }

    /**
     * 書き方 1 通り分を組み立てる。
     *
     * @param hrefNow     いまの配備で HTML に書き出される文字列
     * @param hrefOther   {@code /app} に配備したときに書き出される文字列
     */
    private static Link link(String hrefNow, String hrefOther, String description,
            String contextPath, String currentPath, String otherPath) {

        String resolvedNow = resolve(currentPath, hrefNow);
        String resolvedOther = resolve(otherPath, hrefOther);

        return new Link(hrefNow, description, resolvedNow, resolvedOther,
                !resolvedNow.equals(contextPath + TARGET),
                !resolvedOther.equals(OTHER_CONTEXT + TARGET));
    }

    /**
     * ブラウザがリンクを解決する手順を、そのまま Java で書いたもの。
     *
     * <ul>
     *   <li>{@code /} で始まる … サーバのルートから見た位置。いまの URL は関係ない</li>
     *   <li>それ以外 … <b>いまの URL のディレクトリ</b>から見た位置</li>
     * </ul>
     *
     * <p>「いまの URL」はブラウザのアドレスバーの値です。
     * forward しても<b>アドレスバーは変わらない</b>ので、
     * 転送先の JSP がどこに置かれていても関係ありません。</p>
     *
     * @param currentPath ブラウザから見たいまの URL のパス (例: {@code /samples/basic/context-path})
     * @param href        HTML に書いたリンク
     */
    static String resolve(String currentPath, String href) {
        if (href == null || href.isEmpty()) {
            return currentPath;
        }
        String combined;
        if (href.startsWith("/")) {
            combined = href;
        } else {
            // いまの URL の「最後の / まで」がディレクトリ。
            // /samples/basic/context-path  → /samples/basic/
            // /samples/basic/context-path/ → /samples/basic/context-path/
            int lastSlash = currentPath.lastIndexOf('/');
            String directory = lastSlash < 0 ? "/" : currentPath.substring(0, lastSlash + 1);
            combined = directory + href;
        }
        return normalize(combined);
    }

    /** {@code .} と {@code ..} を畳む。 */
    private static String normalize(String path) {
        Deque<String> segments = new ArrayDeque<>();
        for (String segment : path.split("/", -1)) {
            if (segment.isEmpty() || ".".equals(segment)) {
                continue;
            }
            if ("..".equals(segment)) {
                segments.pollLast();
                continue;
            }
            segments.addLast(segment);
        }
        StringBuilder normalized = new StringBuilder();
        for (String segment : segments) {
            normalized.append('/').append(segment);
        }
        if (path.endsWith("/") && normalized.length() > 0) {
            normalized.append('/');
        }
        return normalized.length() == 0 ? "/" : normalized.toString();
    }
}
