package com.example.servletsample.samples.basic;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;

/**
 * 【サンプル】Cookie の基本。
 *
 * <p>Cookie は「サーバがブラウザに預ける小さなメモ」です。
 * 預けておくと、同じサイトへのリクエストのたびにブラウザが自動で送り返してくれます。
 * HTTP はリクエストごとに独立していて前回を覚えていないため、
 * <b>「誰からの続きか」を伝える唯一の手段</b>として使われてきました。</p>
 *
 * <p>セッション (「スコープ」「ログインとログアウト」のサンプル) も、
 * 土台はこの Cookie です。サーバは値の置き場所 (セッション) を用意し、
 * その<b>引換券だけ</b>を {@code JSESSIONID} という Cookie でブラウザに渡しています。</p>
 *
 * <h2>発行と削除</h2>
 * <pre>{@code
 * // 発行 : Set-Cookie ヘッダが付く
 * Cookie cookie = new Cookie("sample_memo", "hello");
 * cookie.setMaxAge(3600);            // 秒。-1 ならブラウザを閉じるまで
 * cookie.setPath("/");               // 送り返してほしい範囲
 * cookie.setHttpOnly(true);          // JavaScript から読ませない
 * response.addCookie(cookie);
 *
 * // 削除 : 同じ名前・同じパスで、有効期限 0 のものを上書きする
 * Cookie deleted = new Cookie("sample_memo", "");
 * deleted.setMaxAge(0);
 * deleted.setPath("/");
 * response.addCookie(deleted);
 * }</pre>
 *
 * <p>更新も削除も「同じ名前・同じパスで上書きする」だけです。
 * <b>パスが違うと別の Cookie として扱われる</b>ため、消えずに残ります。</p>
 */
@WebServlet(name = "cookie", urlPatterns = {"/samples/basic/cookie"})
public class CookieServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String SAMPLE_PATH = "/samples/basic/cookie";

    private static final String VIEW = "/WEB-INF/views/samples/basic/cookie.jsp";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // リダイレクト後のメッセージを受け取る (PRG パターン)
        Flash.consume(request);

        // getCookies() は 1 つも無いと null を返します。View 側で毎回気にせずに済むよう、
        // ここでリストに直しておきます
        request.setAttribute("cookies", Cookies.view(request.getCookies()));

        // セッションを作ると JSESSIONID が発行されます (この画面では必ず作られています)
        request.setAttribute("sessionId", request.getSession().getId());

        request.setAttribute("pathAll", pathAll(request.getContextPath()));
        request.setAttribute("pathSample", pathSample(request.getContextPath()));

        forward(request, response, VIEW);
    }

    /** 発行と削除。値を変えるので POST で受け、終わったらリダイレクトします。 */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        String contextPath = request.getContextPath();

        if ("delete".equals(action)) {
            String name = request.getParameter("name");
            if (name != null && name.startsWith(Cookies.PREFIX)) {
                deleteEverywhere(response, contextPath, name);
                Flash.set(request, "success", "削除しました",
                        name + " に有効期限 0 の Cookie を上書きしました。");
            }

        } else if ("deleteAll".equals(action)) {
            int count = 0;
            for (Cookies.View view : Cookies.view(request.getCookies())) {
                if (view.isSample()) {
                    deleteEverywhere(response, contextPath, view.getName());
                    count++;
                }
            }
            Flash.set(request, "success", "まとめて削除しました",
                    "このサンプルで作った Cookie " + count + " 件に有効期限 0 を送りました。");

        } else {
            String name = Cookies.demoName(request.getParameter("name"));
            int maxAge = Cookies.parseMaxAge(request.getParameter("maxAge"));
            boolean httpOnly = request.getParameter("httpOnly") != null;
            boolean secure = request.getParameter("secure") != null;
            boolean wholeSite = !"sample".equals(request.getParameter("path"));
            String path = wholeSite ? pathAll(contextPath) : pathSample(contextPath);

            // 値は URL エンコードしてから入れる。日本語も ; も、これで安全に運べます
            Cookie cookie = new Cookie(name, Cookies.encodeValue(request.getParameter("value")));
            cookie.setMaxAge(maxAge);
            cookie.setPath(path);
            cookie.setHttpOnly(httpOnly);
            // Secure を付けると、ブラウザは HTTPS のときしか保存も送信もしません。
            // http で開いていると「発行したのに一覧に出てこない」ことになります
            cookie.setSecure(secure);
            response.addCookie(cookie);

            Flash.set(request, "success", "発行しました",
                    name + " を Path=" + path + " / " + Cookies.describeMaxAge(maxAge)
                            + " で預けました。"
                            + (secure ? " (Secure 付きなので http では保存されません)" : ""));
        }

        // POST のあとはリダイレクト。再読み込みで同じ発行が繰り返されるのを防ぎます
        response.sendRedirect(request.getContextPath() + SAMPLE_PATH);
    }

    /**
     * 同じ名前の Cookie を、このサンプルが使う 2 つのパスの両方から消す。
     *
     * <p>ブラウザが送り返してくるのは<b>名前と値だけ</b>で、
     * どのパスで預けたものかは分かりません。そのため、
     * 心当たりのあるパスすべてに「有効期限 0」を送る必要があります。</p>
     */
    private static void deleteEverywhere(HttpServletResponse response, String contextPath,
            String name) {
        for (String path : new String[] {pathAll(contextPath), pathSample(contextPath)}) {
            Cookie deleted = new Cookie(name, "");
            deleted.setMaxAge(0);
            deleted.setPath(path);
            response.addCookie(deleted);
        }
    }

    /** サイト全体に送り返してもらうときのパス。 */
    static String pathAll(String contextPath) {
        return contextPath.isEmpty() ? "/" : contextPath + "/";
    }

    /** このサンプルの画面だけに送り返してもらうときのパス。 */
    static String pathSample(String contextPath) {
        return contextPath + SAMPLE_PATH;
    }
}
