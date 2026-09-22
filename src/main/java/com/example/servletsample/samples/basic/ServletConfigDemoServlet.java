package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.util.Collections;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;

/**
 * 【サンプル】同じクラスを、違う設定で 2 つ登録するデモ。
 *
 * <p>このクラスには {@code @WebServlet} を付けていません。
 * 代わりに {@code web.xml} で<b>同じクラスを 2 回</b>登録し、
 * それぞれ別の {@code <init-param>} を渡しています。</p>
 *
 * <pre>{@code
 * <servlet>
 *   <servlet-name>servletConfigDemoA</servlet-name>
 *   <servlet-class>...ServletConfigDemoServlet</servlet-class>
 *   <init-param><param-name>label</param-name><param-value>A 号機</param-value></init-param>
 * </servlet>
 * <servlet>
 *   <servlet-name>servletConfigDemoB</servlet-name>
 *   <servlet-class>...ServletConfigDemoServlet</servlet-class>   ← 同じクラス
 *   <init-param><param-name>label</param-name><param-value>B 号機</param-value></init-param>
 * </servlet>
 * }</pre>
 *
 * <p>登録した数だけ<b>インスタンスが作られ、それぞれに {@code init()} が呼ばれます</b>。
 * 同じコードを設定違いで使い回せる、というのが {@code <init-param>} の値打ちです
 * (アノテーションではこの書き方はできません)。</p>
 */
public class ServletConfigDemoServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** init() で読んだ値。インスタンスごとに別の値が入ります。 */
    private String label;
    private int pageSize;

    @Override
    public void init() throws ServletException {
        label = getInitParameter("label");
        pageSize = ServletConfigServlet.pageSizeOf(getInitParameter("pageSize"));
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        Json.JsonObject params = Json.object();
        for (String name : Collections.list(getServletConfig().getInitParameterNames())) {
            params.put(name, getInitParameter(name));
        }

        Json.write(response, Json.object()
                // web.xml の <servlet-name>。どちらの登録が答えたかが分かります
                .put("servletName", getServletName())
                .put("servletClass", getClass().getSimpleName())
                // init() で読んで確かめたあとの値
                .put("label", label)
                .put("pageSize", pageSize)
                // web.xml に書かれたままの値
                .put("initParams", params)
                // インスタンスが別であることの証拠
                .put("instance", "@" + Integer.toHexString(System.identityHashCode(this))));
    }
}
