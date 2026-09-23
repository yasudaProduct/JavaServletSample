package com.example.servletsample.samples.test;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Proxy;

import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServletResponseWrapper;

/**
 * 【サンプル】テスト用の偽の {@link HttpServletResponse}。
 *
 * <p>作り方は {@link FakeHttpServletRequest} と同じで、
 * {@link HttpServletResponseWrapper} に空っぽの土台を渡し、必要なものだけ上書きしています。</p>
 *
 * <p>レスポンスの偽物は<b>「何をされたか」を覚えておく</b>のが仕事です。
 * どこへリダイレクトしたか、ステータスは何番か、本文に何を書いたか。
 * テストはそれを取り出して確かめます。</p>
 */
class FakeHttpServletResponse extends HttpServletResponseWrapper {

    private final StringWriter body = new StringWriter();
    private final PrintWriter writer = new PrintWriter(body);

    private String redirectedTo;
    private int status = HttpServletResponse.SC_OK;
    private String contentType;

    FakeHttpServletResponse() {
        super(emptyResponse());
    }

    /** {@code sendRedirect} で渡された URL (呼ばれていなければ null)。 */
    String getRedirectedTo() {
        return redirectedTo;
    }

    /** 最後に設定されたステータスコード (リダイレクトなら 302)。 */
    @Override
    public int getStatus() {
        return status;
    }

    @Override
    public String getContentType() {
        return contentType;
    }

    /** レスポンスに書かれた本文。 */
    String getBody() {
        writer.flush();
        return body.toString();
    }

    @Override
    public void sendRedirect(String location) {
        this.redirectedTo = location;
        this.status = HttpServletResponse.SC_FOUND;   // 302
    }

    @Override
    public void setStatus(int status) {
        this.status = status;
    }

    @Override
    public void sendError(int status, String message) {
        this.status = status;
    }

    @Override
    public void sendError(int status) {
        this.status = status;
    }

    @Override
    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    @Override
    public PrintWriter getWriter() {
        return writer;
    }

    private static HttpServletResponse emptyResponse() {
        return (HttpServletResponse) Proxy.newProxyInstance(
                FakeHttpServletResponse.class.getClassLoader(),
                new Class<?>[]{HttpServletResponse.class},
                (proxy, method, args) -> {
                    Class<?> returnType = method.getReturnType();
                    if (returnType == boolean.class) {
                        return false;
                    }
                    if (returnType == int.class) {
                        return 0;
                    }
                    if (returnType == long.class) {
                        return 0L;
                    }
                    return null;
                });
    }
}
