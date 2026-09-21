package com.example.servletsample.samples.advanced;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicBoolean;

import javax.servlet.AsyncContext;
import javax.servlet.AsyncEvent;
import javax.servlet.AsyncListener;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.Json;

/**
 * 【サンプル】非同期処理の「終わり方」を見張るリスナー。
 *
 * <p>{@code AsyncContext} を使うと、応答を返すのは<b>あとから別のスレッド</b>になります。
 * そのぶん「返せなかったとき」の面倒も自分で見る必要があります。
 * {@link AsyncListener} を登録しておくと、コンテナが次の節目で呼んでくれます。</p>
 *
 * <table border="1">
 *   <caption>呼ばれるタイミング</caption>
 *   <tr><th>メソッド</th><th>呼ばれるとき</th></tr>
 *   <tr><td>{@code onComplete}</td><td>{@code complete()} まで終わったとき</td></tr>
 *   <tr><td>{@code onTimeout}</td>
 *       <td>{@code setTimeout(...)} の時間までに終わらなかったとき</td></tr>
 *   <tr><td>{@code onError}</td><td>処理中に例外が出たとき</td></tr>
 *   <tr><td>{@code onStartAsync}</td>
 *       <td>{@code dispatch()} のあと、もう一度 {@code startAsync()} されたとき</td></tr>
 * </table>
 *
 * <h2>onTimeout で何もしないとどうなるか</h2>
 * <p>コンテナが代わりにエラー (500) で打ち切ります。
 * 利用者から見れば「重い処理を頼んだらエラーになった」としか分かりません。
 * ここで {@code complete()} まで自分で面倒を見て、
 * 「時間切れです」と分かる応答を返しておきます。</p>
 *
 * <h2>二重に応答しないための旗</h2>
 * <p>時間切れのすぐあとに、遅れてきた仕事が応答を書こうとすることがあります。
 * 応答を書いてよいのは<b>先に着いた方だけ</b>なので、
 * {@link AtomicBoolean#compareAndSet(boolean, boolean)} で
 * 「自分が最初だったか」を確かめてから書いています。</p>
 */
public class AsyncJobListener implements AsyncListener {

    /** 応答を書いたかどうか。仕事をするスレッドと共有する。 */
    private final AtomicBoolean responded;

    private final ServletContext context;
    private final String label;
    private final int requestedMillis;
    private final String servletThread;
    private final long timeoutMillis;

    AsyncJobListener(AtomicBoolean responded, ServletContext context, String label,
            int requestedMillis, String servletThread, long timeoutMillis) {
        this.responded = responded;
        this.context = context;
        this.label = label;
        this.requestedMillis = requestedMillis;
        this.servletThread = servletThread;
        this.timeoutMillis = timeoutMillis;
    }

    @Override
    public void onTimeout(AsyncEvent event) throws IOException {
        if (!responded.compareAndSet(false, true)) {
            return;   // ひと足違いで仕事の方が終わっていた
        }
        AsyncContext asyncContext = event.getAsyncContext();
        HttpServletResponse response = (HttpServletResponse) asyncContext.getResponse();
        try {
            // 503 Service Unavailable : いまは応えられない、という意味のステータス
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            Json.write(response, Json.object()
                    .put("ok", false)
                    .put("timedOut", true)
                    .put("mode", "async")
                    .put("label", label)
                    .put("requestedMillis", requestedMillis)
                    .put("servletThread", servletThread)
                    // 仕事はまだ終わっていないので「仕事をしたスレッド」は無い
                    .put("workerThread", null)
                    .put("timeoutMillis", timeoutMillis)
                    .put("message", timeoutMillis + " ミリ秒待っても終わらなかったので、"
                            + Thread.currentThread().getName()
                            + " が onTimeout を呼び、時間切れとして応答しました。"
                            + "仕事そのものはスレッドプールの中でまだ動いています。"));
        } finally {
            // complete() を呼ばないと、コンテナが 500 で打ち切ります
            asyncContext.complete();
        }
    }

    @Override
    public void onError(AsyncEvent event) throws IOException {
        context.log("非同期処理で例外が起きました", event.getThrowable());
        if (!responded.compareAndSet(false, true)) {
            return;
        }
        AsyncContext asyncContext = event.getAsyncContext();
        HttpServletResponse response = (HttpServletResponse) asyncContext.getResponse();
        try {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Json.write(response, Json.object()
                    .put("ok", false)
                    .put("mode", "async")
                    .put("label", label)
                    .put("message", "非同期処理で例外が起きました。"));
        } finally {
            asyncContext.complete();
        }
    }

    @Override
    public void onComplete(AsyncEvent event) {
        // 応答を返し終えたところ。後始末があればここで行います
        // (ここで response を触ることはできません。もう送信済みです)
    }

    @Override
    public void onStartAsync(AsyncEvent event) {
        // dispatch() してから、もう一度 startAsync() されたときに呼ばれます。
        // リスナーは引き継がれないので、必要ならここで登録し直します
    }
}
