package com.example.servletsample.samples.advanced;

import java.io.IOException;
import java.util.OptionalInt;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.atomic.AtomicBoolean;

import javax.servlet.AsyncContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】時間のかかる処理を、同期と非同期の両方で動かす API。
 *
 * <p>やっていることはどちらも「指定されたミリ秒だけ待って JSON を返す」だけです。
 * 違うのは<b>誰が待つか</b>です。</p>
 *
 * <pre>{@code
 * 同期   : http-nio-8080-exec-5 が待って、そのまま応答を書く
 *          → 待っている間、このスレッドは他のリクエストを処理できない
 *
 * 非同期 : http-nio-8080-exec-5 は startAsync して、すぐ doGet を抜ける (スレッドは返却される)
 *          async-worker-1 が待って、終わってから応答を書き、complete() で閉じる
 * }</pre>
 *
 * <h2>受け付けるパラメータ</h2>
 * <table border="1">
 *   <caption>クエリパラメータ</caption>
 *   <tr><th>名前</th><th>意味</th></tr>
 *   <tr><td>{@code mode}</td><td>{@code async} なら非同期。それ以外は同期</td></tr>
 *   <tr><td>{@code millis}</td>
 *       <td>待つ時間 (既定 {@value #DEFAULT_WORK_MILLIS} / 上限 {@value #MAX_WORK_MILLIS})</td></tr>
 *   <tr><td>{@code timeout}</td>
 *       <td>非同期の制限時間。{@code 0} なら無制限 (上限 {@value #MAX_TIMEOUT_MILLIS})</td></tr>
 *   <tr><td>{@code label}</td><td>画面で結果を並べるための見出し (任意)</td></tr>
 * </table>
 *
 * <h2>非同期にするための約束ごと</h2>
 * <ul>
 *   <li>{@code @WebServlet} に <b>{@code asyncSupported = true}</b> を付ける
 *       (付け忘れると {@code startAsync()} で {@link IllegalStateException})</li>
 *   <li>この URL に掛かるフィルタがあれば、そちらにも
 *       {@code asyncSupported} / {@code <async-supported>true</async-supported>} が要る</li>
 *   <li>{@code startAsync()} のあと、元のスレッドで {@code response} を触らない</li>
 *   <li>最後に必ず {@code complete()} (または {@code dispatch()}) を呼ぶ</li>
 * </ul>
 */
@WebServlet(name = "asyncSampleApi", urlPatterns = {"/samples/advanced/async/api"}, asyncSupported = true)
public class AsyncApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** この API の URL (コンテキストルートからのパス)。 */
    static final String PATH = "/samples/advanced/async/api";

    /** 待つ時間の既定値 (ミリ秒)。 */
    static final int DEFAULT_WORK_MILLIS = 2000;

    /** 待つ時間の上限 (ミリ秒)。デモなので長く占有させない。 */
    static final int MAX_WORK_MILLIS = 8000;

    /** 制限時間の上限 (ミリ秒)。 */
    static final int MAX_TIMEOUT_MILLIS = 30_000;

    /** 見出しの長さの上限。 */
    static final int MAX_LABEL_LENGTH = 20;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store");

        String label = label(request.getParameter("label"));
        int millis = workMillis(request.getParameter("millis"));

        if (!isAsync(request.getParameter("mode"))) {
            runOnThisThread(response, label, millis);
            return;
        }
        startAsync(request, response, label, millis, timeoutMillis(request.getParameter("timeout")));
    }

    // ------------------------------------------------------------------
    // 同期 : いつもの Servlet
    // ------------------------------------------------------------------

    /** リクエストを受け取ったスレッドが、そのまま待って応答する。 */
    private void runOnThisThread(HttpServletResponse response, String label, int millis)
            throws IOException {

        long start = System.nanoTime();
        String thread = Thread.currentThread().getName();

        sleepQuietly(millis);

        Json.write(response, result("sync", label, millis, thread, thread, 0L, elapsedMillis(start),
                "リクエストを受け取ったスレッドが、そのまま " + millis + " ミリ秒待ちました。"
                        + "待っている間、このスレッドは他のリクエストを処理できません。"));
    }

    // ------------------------------------------------------------------
    // 非同期 : 待つのは別のスレッド
    // ------------------------------------------------------------------

    /** 応答を後回しにして、仕事をスレッドプールへ渡す。 */
    private void startAsync(HttpServletRequest request, HttpServletResponse response,
            String label, int millis, long timeout) {

        String servletThread = Thread.currentThread().getName();
        long start = System.nanoTime();

        // ここから応答は「後回し」になります。
        // このメソッドを抜けてもレスポンスは閉じません (complete() まで開いたまま)
        AsyncContext asyncContext = request.startAsync();

        // 0 は「制限時間なし」。指定しなければコンテナの既定値 (Tomcat は 30 秒) が使われます
        asyncContext.setTimeout(timeout);

        // 応答を書いてよいのは、仕事と時間切れのうち先に着いた方だけ
        AtomicBoolean responded = new AtomicBoolean();
        asyncContext.addListener(new AsyncJobListener(
                responded, getServletContext(), label, millis, servletThread, timeout));

        try {
            AsyncWorkerPool.submit(() -> work(asyncContext, responded, label, millis, servletThread, start));
        } catch (RejectedExecutionException e) {
            // 待ち行列があふれた。投げっぱなしにすると応答が返らないので、ここで返す
            rejected(asyncContext, responded, label);
        }
    }

    /** スレッドプールの中で動く仕事。 */
    private void work(AsyncContext asyncContext, AtomicBoolean responded,
            String label, int millis, String servletThread, long startNanos) {

        // 受け付けてから、この仕事が始まるまでにかかった時間 (＝順番待ちの時間)
        long waited = elapsedMillis(startNanos);

        sleepQuietly(millis);

        if (!responded.compareAndSet(false, true)) {
            // すでに時間切れとして応答済み。ここで response を触ると IllegalStateException になります。
            // 「利用者はもう待っていないが、仕事は動き続けている」状態です
            getServletContext().log("非同期の仕事が、時間切れのあとに終わりました: " + label);
            return;
        }

        try {
            HttpServletResponse response = (HttpServletResponse) asyncContext.getResponse();
            Json.write(response, result("async", label, millis, servletThread,
                    Thread.currentThread().getName(), waited, elapsedMillis(startNanos),
                    "受け付けた " + servletThread + " はすぐ解放され、"
                            + Thread.currentThread().getName() + " が " + millis + " ミリ秒待ちました。"));
        } catch (IOException | IllegalStateException e) {
            // 利用者がタブを閉じた、通信が切れた、など。応答は書けないのでログだけ残す
            getServletContext().log("非同期の応答を書けませんでした: " + label, e);
        } finally {
            // complete() を呼ばないと、レスポンスは時間切れまで開いたままになります
            asyncContext.complete();
        }
    }

    /** 待ち行列があふれたときの応答 (503)。 */
    private void rejected(AsyncContext asyncContext, AtomicBoolean responded, String label) {
        if (!responded.compareAndSet(false, true)) {
            return;
        }
        try {
            HttpServletResponse response = (HttpServletResponse) asyncContext.getResponse();
            response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
            Json.write(response, Json.object()
                    .put("ok", false)
                    .put("mode", "async")
                    .put("label", label)
                    .put("message", "順番待ちがいっぱいです (スレッド " + AsyncWorkerPool.POOL_SIZE
                            + " 本 / 待ち行列 " + AsyncWorkerPool.QUEUE_CAPACITY + " 件)。"
                            + "少し待ってからもう一度試してください。"));
        } catch (IOException | IllegalStateException e) {
            getServletContext().log("混雑の応答を書けませんでした: " + label, e);
        } finally {
            asyncContext.complete();
        }
    }

    // ------------------------------------------------------------------
    // 部品
    // ------------------------------------------------------------------

    /** 応答の JSON を組み立てる。 */
    static Json.JsonObject result(String mode, String label, int requestedMillis,
            String servletThread, String workerThread, long waitedMillis, long totalMillis,
            String message) {

        return Json.object()
                .put("ok", true)
                .put("timedOut", false)
                .put("mode", mode)
                .put("label", label)
                .put("requestedMillis", requestedMillis)
                .put("servletThread", servletThread)
                .put("workerThread", workerThread)
                .put("waitedMillis", waitedMillis)
                .put("totalMillis", totalMillis)
                .put("queued", AsyncWorkerPool.queuedCount())
                .put("message", message);
    }

    /** {@code mode=async} かどうか。 */
    static boolean isAsync(String mode) {
        return "async".equalsIgnoreCase(Validators.strip(mode));
    }

    /** 待つ時間を決める (範囲外は上限・下限に丸める)。 */
    static int workMillis(String raw) {
        OptionalInt value = Validators.toInt(raw);
        if (value.isEmpty()) {
            return DEFAULT_WORK_MILLIS;
        }
        return Math.max(0, Math.min(MAX_WORK_MILLIS, value.getAsInt()));
    }

    /** 制限時間を決める ({@code 0} なら無制限)。 */
    static long timeoutMillis(String raw) {
        OptionalInt value = Validators.toInt(raw);
        if (value.isEmpty()) {
            return 0L;
        }
        return Math.max(0, Math.min(MAX_TIMEOUT_MILLIS, value.getAsInt()));
    }

    /** 画面で結果を並べるための見出し (長すぎるものは切り詰める)。 */
    static String label(String raw) {
        String stripped = Validators.strip(raw);
        if (stripped.isEmpty()) {
            return "";
        }
        return stripped.length() <= MAX_LABEL_LENGTH ? stripped : stripped.substring(0, MAX_LABEL_LENGTH);
    }

    /** 指定のミリ秒だけ待つ (重い処理の代わり)。 */
    private static void sleepQuietly(int millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            // 割り込まれたことを消さずに呼び出し元へ伝え直す
            Thread.currentThread().interrupt();
        }
    }

    /** 開始からの経過をミリ秒で返す。 */
    private static long elapsedMillis(long startNanos) {
        return (System.nanoTime() - startNanos) / 1_000_000L;
    }
}
