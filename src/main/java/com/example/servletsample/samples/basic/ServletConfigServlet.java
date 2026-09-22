package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebInitParam;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】設定値の渡し方（init-param と context-param）。
 *
 * <p>1 ページに出す件数、外部サービスの URL、上限値。
 * こうした「あとで変えたくなる値」をソースに直接書くと、
 * 変えるたびにビルドと再配備が要ります。Servlet には、
 * これを外に出す仕組みが 2 段階で用意されています。</p>
 *
 * <table border="1">
 *   <caption>2 つの置き場所</caption>
 *   <tr><th>&nbsp;</th><th>{@code <context-param>}</th><th>{@code <init-param>}</th></tr>
 *   <tr><td>届く範囲</td><td>アプリ全体</td><td>書いた Servlet (またはフィルタ) 1 つだけ</td></tr>
 *   <tr><td>読む相手</td><td>{@code ServletContext}</td><td>{@code ServletConfig}</td></tr>
 *   <tr><td>Java から</td><td>{@code getServletContext().getInitParameter(名前)}</td>
 *       <td>{@code getInitParameter(名前)}</td></tr>
 *   <tr><td>JSP から</td><td>{@code ${initParam.名前}}</td><td>(直接は読めない)</td></tr>
 * </table>
 *
 * <p>この Servlet は {@code @WebServlet(initParams = ...)} で自分用の設定を持っています。
 * 同じ値を {@code web.xml} に書くこともでき、その場合は {@code web.xml} が優先されます。</p>
 *
 * <h2>読むのは init() で 1 回だけ</h2>
 * <p>設定値はアプリが動いている間は変わりません。リクエストのたびに読み直す必要はなく、
 * <b>{@code init()} で読んで、そこで検証しておく</b>のが定石です。
 * 設定が壊れていることに気付くのが「起動時」になるか「利用者が操作したとき」になるかの違いです。</p>
 */
@WebServlet(
        name = "servletConfig",
        urlPatterns = {"/samples/basic/servlet-config"},
        initParams = {
                @WebInitParam(name = "pageSize", value = "20",
                        description = "1 ページに出す件数"),
                @WebInitParam(name = "greeting", value = "設定ファイルからこんにちは",
                        description = "画面に出す文言")
        })
public class ServletConfigServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** {@code pageSize} が読めなかったときに使う値。 */
    static final int DEFAULT_PAGE_SIZE = 20;

    /** {@code pageSize} に許す上限 (大きすぎる値を設定されても守るため)。 */
    static final int MAX_PAGE_SIZE = 100;

    private static final String VIEW = "/WEB-INF/views/samples/basic/servlet-config.jsp";

    private static final DateTimeFormatter TIMESTAMP =
            DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");

    /** init() で読んで確かめた値。以降のリクエストではこれを使います。 */
    private int pageSize;
    private String greeting;
    private String initializedAt;

    /**
     * 設定を読む。呼ばれるのは<b>この Servlet につき 1 回だけ</b>です。
     *
     * <p>引数なしの {@code init()} は、{@code ServletConfig} を保管したあとに
     * コンテナが呼んでくれます。{@code init(ServletConfig)} を上書きするときは
     * {@code super.init(config)} を忘れると {@code getInitParameter} が動かなくなります。</p>
     */
    @Override
    public void init() throws ServletException {
        pageSize = pageSizeOf(getInitParameter("pageSize"));
        greeting = getInitParameter("greeting");
        initializedAt = LocalDateTime.now().format(TIMESTAMP);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        ServletConfig config = getServletConfig();
        ServletContext context = getServletContext();

        // この Servlet だけの設定
        request.setAttribute("servletName", config.getServletName());
        request.setAttribute("initParams", toMap(Collections.list(config.getInitParameterNames()),
                config::getInitParameter));
        request.setAttribute("pageSize", pageSize);
        request.setAttribute("greeting", greeting);
        request.setAttribute("initializedAt", initializedAt);

        // アプリ全体の設定
        request.setAttribute("contextParams",
                toMap(Collections.list(context.getInitParameterNames()),
                        context::getInitParameter));

        // ServletContext から取れる、設定以外のもの
        Map<String, String> contextFacts = new LinkedHashMap<>();
        contextFacts.put("getContextPath()",
                context.getContextPath().isEmpty() ? "\"\" (空文字)" : context.getContextPath());
        contextFacts.put("getServerInfo()", context.getServerInfo());
        contextFacts.put("getMajorVersion() / getMinorVersion()",
                context.getMajorVersion() + "." + context.getMinorVersion() + " (Servlet の版)");
        contextFacts.put("getVirtualServerName()", String.valueOf(context.getVirtualServerName()));
        request.setAttribute("contextFacts", contextFacts);

        request.setAttribute("demoPathA", request.getContextPath() + "/samples/basic/servlet-config/a");
        request.setAttribute("demoPathB", request.getContextPath() + "/samples/basic/servlet-config/b");

        forward(request, response, VIEW);
    }

    /**
     * {@code pageSize} を読んで確かめる。
     *
     * <p>設定値は「誰かが手で書いた文字列」です。数値のつもりでも、
     * 空欄・全角数字・桁あふれ・大きすぎる値が来ます。
     * <b>読めない値は既定値に倒し、上限も自分で決めておきます</b>。</p>
     */
    static int pageSizeOf(String value) {
        return Validators.toInt(value)
                .stream()
                .filter(size -> size > 0)
                .map(size -> Math.min(size, MAX_PAGE_SIZE))
                .findFirst()
                .orElse(DEFAULT_PAGE_SIZE);
    }

    /** 名前の一覧と「名前から値を引く関数」から、順番を保った Map を作る。 */
    private static Map<String, String> toMap(Iterable<String> names,
            java.util.function.Function<String, String> lookup) {
        Map<String, String> map = new LinkedHashMap<>();
        for (String name : names) {
            map.put(name, lookup.apply(name));
        }
        return map;
    }
}
