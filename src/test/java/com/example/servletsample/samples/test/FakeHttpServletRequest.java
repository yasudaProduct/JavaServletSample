package com.example.servletsample.samples.test;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import javax.servlet.http.HttpSession;

/**
 * 【サンプル】テスト用の偽の {@link HttpServletRequest}。
 *
 * <p>Servlet をテストするには {@code HttpServletRequest} が要りますが、これはインターフェースで、
 * 本物は Tomcat が作ります。<b>Tomcat を起動せずに済ませる</b>ために、
 * テストの中で最低限の偽物を用意します。</p>
 *
 * <h2>作り方</h2>
 * <p>{@code HttpServletRequest} には 60 以上のメソッドがあり、全部書くのは現実的ではありません。
 * そこで 2 つの道具を使っています。</p>
 * <ol>
 *   <li>{@link HttpServletRequestWrapper} … すべてのメソッドを「中の request に丸投げ」する形で
 *       実装済みのクラス。必要なものだけ上書きすれば済みます。</li>
 *   <li>{@link Proxy} … その「中の request」を、何を呼ばれても既定値を返すだけの
 *       空っぽの実装として作ります (下の {@link #emptyRequest()})。</li>
 * </ol>
 *
 * <p><b>実務では</b> Mockito の {@code mock(HttpServletRequest.class)} や、
 * Spring の {@code MockHttpServletRequest} を使うのが一般的です。
 * このサンプル集はライブラリを増やさない方針なので標準の API だけで作っていますが、
 * 「やっていることは同じ」だと分かると、モックライブラリも怖くなくなります。</p>
 */
class FakeHttpServletRequest extends HttpServletRequestWrapper {

    private final Map<String, String> parameters = new HashMap<>();
    private final Map<String, Object> attributes = new HashMap<>();
    private final Map<String, Object> sessionAttributes = new HashMap<>();

    private String method = "GET";

    /** forward された先のパス。行き先が正しいかを確かめるために記録する。 */
    private String forwardedPath;

    FakeHttpServletRequest() {
        super(emptyRequest());
    }

    // ------------------------------------------------------------------
    // テストから状況を組み立てるためのメソッド
    // ------------------------------------------------------------------

    /** パラメータを 1 件足す (画面の入力欄 1 つ分)。 */
    FakeHttpServletRequest withParameter(String name, String value) {
        parameters.put(name, value);
        return this;
    }

    /** HTTP メソッドを指定する。 */
    FakeHttpServletRequest withMethod(String method) {
        this.method = method;
        return this;
    }

    /** forward された先の JSP パス (されていなければ null)。 */
    String getForwardedPath() {
        return forwardedPath;
    }

    // ------------------------------------------------------------------
    // ここから下が「本物の代わり」に動く部分
    // ------------------------------------------------------------------

    @Override
    public String getParameter(String name) {
        return parameters.get(name);
    }

    @Override
    public String getMethod() {
        return method;
    }

    /** コンテキストパス。リダイレクト先 URL の組み立てで使われる。 */
    @Override
    public String getContextPath() {
        return "";
    }

    @Override
    public void setAttribute(String name, Object value) {
        attributes.put(name, value);
    }

    @Override
    public Object getAttribute(String name) {
        return attributes.get(name);
    }

    @Override
    public void removeAttribute(String name) {
        attributes.remove(name);
    }

    @Override
    public HttpSession getSession() {
        return getSession(true);
    }

    @Override
    public HttpSession getSession(boolean create) {
        return fakeSession(sessionAttributes);
    }

    /**
     * forward の行き先を記録するだけのディスパッチャを返す。
     *
     * <p>本物は JSP を実行しますが、テストでは
     * 「どの JSP に渡したか」が分かれば十分です。</p>
     */
    @Override
    public RequestDispatcher getRequestDispatcher(String path) {
        return new RequestDispatcher() {
            @Override
            public void forward(ServletRequest request, ServletResponse response) {
                forwardedPath = path;
            }

            @Override
            public void include(ServletRequest request, ServletResponse response) {
                forwardedPath = path;
            }
        };
    }

    // ------------------------------------------------------------------
    // 道具
    // ------------------------------------------------------------------

    /**
     * 何を呼ばれても既定値 (null / 0 / false) を返すだけの {@link HttpServletRequest}。
     *
     * <p>{@link HttpServletRequestWrapper} は null を渡せないので、土台として必要になります。
     * ここに実装を足すのではなく、<b>上のクラス側で上書きする</b>のがポイントです
     * (テストに必要な分だけ本物らしく振る舞わせる)。</p>
     */
    private static HttpServletRequest emptyRequest() {
        return (HttpServletRequest) Proxy.newProxyInstance(
                FakeHttpServletRequest.class.getClassLoader(),
                new Class<?>[]{HttpServletRequest.class},
                defaultAnswer());
    }

    /** 属性を覚えるだけの偽のセッション。 */
    private static HttpSession fakeSession(Map<String, Object> attributes) {
        InvocationHandler handler = (proxy, method, args) -> {
            switch (method.getName()) {
                case "setAttribute":
                    attributes.put((String) args[0], args[1]);
                    return null;
                case "getAttribute":
                    return attributes.get(args[0]);
                case "removeAttribute":
                    attributes.remove(args[0]);
                    return null;
                case "getId":
                    return "FAKE-SESSION";
                default:
                    return defaultValueOf(method.getReturnType());
            }
        };
        return (HttpSession) Proxy.newProxyInstance(
                FakeHttpServletRequest.class.getClassLoader(),
                new Class<?>[]{HttpSession.class}, handler);
    }

    private static InvocationHandler defaultAnswer() {
        return (proxy, method, args) -> defaultValueOf(method.getReturnType());
    }

    /** 戻り値の型に合わせた既定値。プリミティブに null を返すと NullPointerException になる。 */
    private static Object defaultValueOf(Class<?> returnType) {
        if (!returnType.isPrimitive()) {
            return null;
        }
        if (returnType == boolean.class) {
            return false;
        }
        if (returnType == void.class) {
            return null;
        }
        if (returnType == long.class) {
            return 0L;
        }
        if (returnType == double.class) {
            return 0d;
        }
        if (returnType == float.class) {
            return 0f;
        }
        if (returnType == char.class) {
            return (char) 0;
        }
        if (returnType == short.class) {
            return (short) 0;
        }
        if (returnType == byte.class) {
            return (byte) 0;
        }
        return 0;
    }
}
