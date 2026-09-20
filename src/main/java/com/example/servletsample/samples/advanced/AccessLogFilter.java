package com.example.servletsample.samples.advanced;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * 【サンプル】2 番目のフィルタ : 処理時間を測ってログに残す。
 *
 * <p>「すべての画面で同じことをする」処理はフィルタに置くと、
 * Servlet を 1 つも直さずに後から足せます。アクセスログはその代表例です。</p>
 *
 * <p>フィルタに向いている処理 / 向いていない処理は、だいたい次のように分かれます。</p>
 *
 * <table border="1">
 *   <caption>フィルタの使いどころ</caption>
 *   <tr><th>向いている</th><th>向いていない</th></tr>
 *   <tr><td>アクセスログ、処理時間の計測</td><td>画面ごとに内容が違う処理</td></tr>
 *   <tr><td>ログイン済みかどうかの確認</td><td>1 つの画面でしか使わない処理</td></tr>
 *   <tr><td>文字コードの設定</td><td>重い処理 (すべてのリクエストが遅くなる)</td></tr>
 *   <tr><td>共通のレスポンスヘッダ付与</td><td>画面の内容を書き換える処理 (追いにくくなる)</td></tr>
 * </table>
 *
 * <h2>init とライフサイクル</h2>
 * <p>フィルタも Servlet と同じで、アプリ全体で<b>インスタンスは 1 つ</b>です。</p>
 * <ol>
 *   <li>{@link #init(FilterConfig)} … アプリ起動時に 1 回だけ</li>
 *   <li>{@link #doFilter} … リクエストのたびに (複数のスレッドから同時に)</li>
 *   <li>{@link #destroy()} … アプリ停止時に 1 回だけ</li>
 * </ol>
 * <p>そのため、リクエストごとに変わる値をインスタンス変数に置いてはいけません
 * (別の利用者の値が混ざります)。設定値のように<b>起動時に決まって変わらない</b>ものだけ
 * {@code init} で読んで持ちます。</p>
 *
 * <h2>初期化パラメータ</h2>
 * <pre>{@code
 * <filter>
 *   <filter-name>accessLogFilter</filter-name>
 *   <filter-class>...AccessLogFilter</filter-class>
 *   <init-param>
 *     <param-name>slowMillis</param-name>
 *     <param-value>1000</param-value>
 *   </init-param>
 * </filter>
 * }</pre>
 */
public class AccessLogFilter implements Filter {

    /** 画面の記録に出す名前。 */
    static final String NAME = "AccessLogFilter";

    /** 「遅い」とみなす時間の既定値 (ミリ秒)。 */
    static final long DEFAULT_SLOW_MILLIS = 1000L;

    /**
     * これを超えたら警告としてログに出す時間 (ミリ秒)。
     *
     * <p>{@code init} で 1 回だけ決まり、その後は読むだけなので、
     * 複数のスレッドから同時に使っても問題ありません。</p>
     */
    private long slowMillis = DEFAULT_SLOW_MILLIS;

    /** ログ出力に使う。{@code init} で受け取っておく。 */
    private ServletContext context;

    @Override
    public void init(FilterConfig config) {
        this.context = config.getServletContext();
        this.slowMillis = parseMillis(config.getInitParameter("slowMillis"), DEFAULT_SLOW_MILLIS);
        context.log(NAME + " を初期化しました (slowMillis=" + slowMillis + ")");
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        FilterTrace trace = FilterTrace.of(request);

        if (trace != null) {
            trace.enter(NAME, "開始時刻を記録した");
        }
        long startNanos = System.nanoTime();

        try {
            chain.doFilter(request, response);

        } finally {
            long elapsedMillis = (System.nanoTime() - startNanos) / 1_000_000L;

            // ステータスコードは「帰り」でなければ分かりません。
            // 行きの時点では、まだ Servlet が何を返すか決まっていないからです
            int status = httpResponse.getStatus();

            if (trace != null) {
                trace.exit(NAME, "処理時間 " + elapsedMillis + " ms / ステータス " + status
                        + " を記録した");
            }

            // 1 リクエスト 1 行。あとで grep しやすいよう、区切りをそろえておく
            String line = String.format("%s %s %d %d ms",
                    httpRequest.getMethod(), fullUri(httpRequest), status, elapsedMillis);
            if (elapsedMillis >= slowMillis) {
                context.log("[SLOW] " + line);
            } else {
                context.log(line);
            }
        }
    }

    @Override
    public void destroy() {
        // 開いたもの (スレッドプール、コネクション) があればここで閉じます。
        // 閉じ忘れると、アプリを入れ替えても古いクラスが解放されずメモリに残ります
        if (context != null) {
            context.log(NAME + " を終了しました");
        }
    }

    /** 初期化パラメータを数値に直す。読めなければ既定値。 */
    static long parseMillis(String raw, long defaultValue) {
        if (raw == null || raw.isBlank()) {
            return defaultValue;
        }
        try {
            long value = Long.parseLong(raw.strip());
            return value > 0 ? value : defaultValue;
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    /** クエリ文字列まで含めた URL。 */
    private static String fullUri(HttpServletRequest request) {
        String query = request.getQueryString();
        return query == null ? request.getRequestURI() : request.getRequestURI() + "?" + query;
    }
}
