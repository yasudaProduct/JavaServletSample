package com.example.servletsample.samples.advanced;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicLong;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * 【サンプル】1 番目のフィルタ : リクエスト ID を採番する。
 *
 * <p>フィルタは Servlet の<b>手前と奥</b>に置ける共通処理です。
 * {@code chain.doFilter(...)} を境に、前が「行き」、後ろが「帰り」になります。</p>
 *
 * <pre>{@code
 * public void doFilter(req, res, chain) {
 *     ... 行きの処理 ...
 *     chain.doFilter(req, res);    // ← 次のフィルタ、最後は Servlet へ
 *     ... 帰りの処理 ...
 * }
 * }</pre>
 *
 * <p>チェーンは入れ子 (マトリョーシカ) になります。
 * 1 番目の行き → 2 番目の行き → Servlet → 2 番目の帰り → 1 番目の帰り、の順です。</p>
 *
 * <h2>このフィルタがやること</h2>
 * <ol>
 *   <li>リクエストごとに通し番号 ({@code R-000001}) を振る</li>
 *   <li>レスポンスヘッダ {@code X-Request-Id} に入れて、ブラウザ側からも分かるようにする</li>
 *   <li>通過の記録 ({@link FilterTrace}) を作り、リクエストスコープに置く</li>
 *   <li>帰りに記録を {@link FilterTraceStore} へ預ける</li>
 * </ol>
 *
 * <p>実際のアプリでも、この「リクエスト ID」は非常に役に立ちます。
 * ログの各行に同じ ID を書いておくと、大量のログの中から
 * 「あの利用者のあの操作」だけを抜き出せます
 * (SLF4J なら MDC に入れ、ログの書式に {@code %X{requestId}} を足します)。</p>
 *
 * <h2>レスポンスヘッダは chain の前に設定する</h2>
 * <p>ヘッダは本文より先に送られるため、<b>本文が送信され始めたあとでは設定できません</b>。
 * 行きの処理 ({@code chain.doFilter} の前) で設定しておくのが安全です。</p>
 *
 * <h2>順番の決め方</h2>
 * <p>このサンプルでは 3 つのフィルタを {@code web.xml} に登録しています。
 * 適用される順番は {@code <filter-mapping>} を<b>書いた順</b>です。
 * {@code @WebFilter} アノテーションでも登録できますが、
 * <b>複数あるときの順番を指定できません</b>
 * (順番が意味を持つなら {@code web.xml} に書きます)。</p>
 */
public class RequestIdFilter implements Filter {

    /** 画面の記録に出す名前。 */
    static final String NAME = "RequestIdFilter";

    /** レスポンスヘッダ名。独自のヘッダは X- で始めるのが慣例でした (今は必須ではありません)。 */
    static final String HEADER = "X-Request-Id";

    /**
     * 採番用のカウンタ。
     *
     * <p>フィルタのインスタンスはアプリ全体で 1 つ、そこへ複数のスレッドが同時に入ってきます。
     * 素の {@code long} で {@code count++} と書くと番号が重複するため、
     * {@link AtomicLong} を使います。</p>
     */
    private final AtomicLong sequence = new AtomicLong();

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String requestId = String.format("R-%06d", sequence.incrementAndGet());

        // ------------------------------------------------ 行きの処理
        FilterTrace trace = new FilterTrace(requestId, httpRequest.getMethod(), fullUri(httpRequest));
        request.setAttribute(FilterTrace.ATTRIBUTE_NAME, trace);

        // ヘッダは本文より先に送られる。chain を呼んだあとでは間に合わないことがある
        httpResponse.setHeader(HEADER, requestId);

        trace.enter(NAME, "リクエスト ID を採番し、レスポンスヘッダ " + HEADER + " に入れた");
        long startNanos = System.nanoTime();

        try {
            // ------------------------------------------------ 次へ渡す
            chain.doFilter(request, response);

        } finally {
            // ------------------------------------------------ 帰りの処理
            //
            // finally に書くのが要点です。奥で例外が起きても、ここは必ず通ります。
            // try の外に書くと、エラーのときだけ記録もログも残らないという
            // 「いちばん知りたいときに何も残っていない」状態になります。
            long elapsedMillis = (System.nanoTime() - startNanos) / 1_000_000L;
            trace.exit(NAME, "記録を保管した (?trace=" + requestId + " で取り出せる)");
            trace.finish(elapsedMillis);
            FilterTraceStore.save(trace);
        }
    }

    /** クエリ文字列まで含めた URL。 */
    private static String fullUri(HttpServletRequest request) {
        String query = request.getQueryString();
        return query == null ? request.getRequestURI() : request.getRequestURI() + "?" + query;
    }
}
