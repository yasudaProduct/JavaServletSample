package com.example.servletsample.samples.ajax;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.concurrent.atomic.AtomicLong;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;

/**
 * 【サンプル】非同期通信の基本で使う JSON API。
 *
 * <p>画面 ({@link AjaxBasicsServlet} が表示する JSP) の {@code fetch} が叩く先です。
 * HTML ではなく<b>データだけ</b>を返すのが、画面を返す Servlet との違いです。</p>
 *
 * <p>URL はサンプル本体の下にぶら下げて {@code /samples/ajax/ajax-basics/api} にしています。
 * 完全一致のマッピングなので、前方一致の {@code /samples/*}
 * ({@code SampleDispatcherServlet}) よりこちらが優先されます。</p>
 *
 * <h2>受け付けるパラメータ</h2>
 * <table border="1">
 *   <caption>クエリパラメータ</caption>
 *   <tr><th>名前</th><th>値</th><th>意味</th></tr>
 *   <tr><td>{@code delay}</td><td>0 〜 2000 (ミリ秒)</td>
 *       <td>返すまでわざと待つ。ローディング表示を見せるため</td></tr>
 *   <tr><td>{@code fail}</td><td>{@code server}</td>
 *       <td>わざと HTTP 500 を返す。エラー時の画面の出方を見せるため</td></tr>
 * </table>
 *
 * <p>どちらも<b>デモのためだけ</b>のパラメータです。実際の API に
 * 「わざと失敗する入口」を残してはいけません。</p>
 *
 * <h2>状態を変えないので GET</h2>
 * <p>この API は値を読むだけなので GET にしています。
 * 登録・更新・削除を非同期で行うなら POST です
 * (GET はブラウザや中継サーバが勝手に再実行・キャッシュすることがあるため、
 * 「何度呼んでも結果が変わらない」処理に限ります)。</p>
 *
 * <h2>JSON の作り方について</h2>
 * <p>ここでは {@link Json} (このリポジトリの学習用の最小実装) で文字列を組み立てています。
 * <b>実務では Jackson や Gson といったライブラリを使ってください。</b>
 * オブジェクトをそのまま JSON にでき、日付の書式や null の扱いもまとめて決められます。</p>
 */
@WebServlet(name = "ajaxBasicsApi", urlPatterns = {"/samples/ajax/ajax-basics/api"})
public class AjaxBasicsApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** この API の URL (画面へ渡して、JavaScript の fetch 先にする)。 */
    static final String PATH = "/samples/ajax/ajax-basics/api";

    /**
     * {@code delay} で待てる上限 (ミリ秒)。
     *
     * <p>上限を決めるのは親切心ではなく<b>防御</b>です。
     * 待っている間、そのリクエストは Tomcat のスレッドを 1 本占有し続けます。
     * {@code ?delay=600000} のような値をそのまま受け入れると、
     * 何度か叩かれるだけでスレッドが尽きて、アプリ全体が応答しなくなります。</p>
     */
    static final long MAX_DELAY_MILLIS = 2000L;

    /**
     * この API が呼ばれた回数。
     *
     * <p>「画面は 1 回しか読み込んでいないのに、API は何度も呼ばれている」ことを
     * 画面で見せるための数です。</p>
     *
     * <p>Servlet のインスタンスはアプリ全体で 1 つ、そこへ複数のスレッドが同時に入ってくるので、
     * 素の {@code long} で {@code count++} と書くと数がずれます
     * (「読む → 足す → 書き戻す」の途中で別のスレッドに割り込まれるためです)。
     * {@link AtomicLong} は増やす操作が 1 つにまとまっているので安全です。</p>
     */
    private final AtomicLong callCount = new AtomicLong();

    /**
     * サーバの情報を JSON で返す。
     *
     * <p>処理の順番は「① パラメータを検証する → ② 指示どおり待つ / 失敗する → ③ JSON を書く」です。</p>
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ① パラメータを受け取って検証する。
        //    画面が組み立てて送ってくる値であっても、実際には利用者が URL を書き換えて
        //    何でも送れます。「画面が正しい値しか送らないはず」を前提にしてはいけません
        long delayMillis = parseDelayMillis(request.getParameter("delay"));

        // ② わざと待つ (ローディング表示を見てもらうためのデモ用の処理)
        sleepQuietly(delayMillis);

        long requestCount = callCount.incrementAndGet();

        // GET の応答はブラウザや中継サーバにキャッシュされることがあります。
        // 毎回サーバに聞きに行ってほしい API では、明示的に止めておきます
        response.setHeader("Cache-Control", "no-store");

        // ③ わざと失敗させる
        if ("server".equals(request.getParameter("fail"))) {
            // ステータスは 500。ただし本文は JSON のまま返します。
            // 画面側の fetch は 500 でも例外にならないので、
            // 「res.ok を見て、本文からエラーの内容を読む」形を体験してもらうためです
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Json.write(response, errorPayload(delayMillis, requestCount));
            return;
        }

        // Json.write が Content-Type: application/json と UTF-8 を設定して書き出します。
        // これを忘れると、ブラウザ側の res.json() で読めなかったり文字化けしたりします
        Json.write(response, payload(delayMillis, requestCount, serverInfo()));
    }

    /**
     * 正常時に返す JSON を組み立てる。
     *
     * <p>{@code getServletContext()} のようにコンテナが要るものは引数で受け取る形にしてあります。
     * こうしておくと <b>Tomcat を起動せずにテストが書けます</b>
     * ({@code src/test/java/.../AjaxBasicsApiServletTest.java})。</p>
     *
     * @param delayMillis  実際に待った時間 (ミリ秒)
     * @param requestCount この API が呼ばれた通算回数
     * @param serverInfo   サーバの名前とバージョン
     */
    Json.JsonObject payload(long delayMillis, long requestCount, String serverInfo) {
        return Json.object()
                .put("ok", true)
                .put("serverTime", LocalDateTime.now().format(AjaxBasicsServlet.TIME_FORMAT))
                .put("serverInfo", serverInfo)
                .put("javaVersion", System.getProperty("java.version"))
                // 公開中のサンプル件数。サーバ側にしか無いデータを返す例です
                .put("sampleCount", catalog().getTotalCount())
                .put("delayMillis", delayMillis)
                .put("requestCount", requestCount)
                // 応答したスレッド名。リクエストごとに変わります
                .put("thread", Thread.currentThread().getName());
    }

    /**
     * 失敗時に返す JSON を組み立てる。
     *
     * <p>エラーのときも<b>形の決まった JSON</b>を返しておくと、画面側が扱いやすくなります
     * (何が起きたかを画面に出せます)。</p>
     *
     * <p>入れてよいのは「利用者に見せてよい説明」だけです。
     * 例外のスタックトレースや SQL をそのまま返すと、
     * 攻撃者にサーバの中身を教えることになります。詳しい情報はログに出します。</p>
     */
    Json.JsonObject errorPayload(long delayMillis, long requestCount) {
        return Json.object()
                .put("ok", false)
                .put("status", HttpServletResponse.SC_INTERNAL_SERVER_ERROR)
                .put("message", "サーバ側で問題が発生しました。"
                        + "(このサンプルは fail=server を受け取ったので、わざと 500 を返しています)")
                .put("serverTime", LocalDateTime.now().format(AjaxBasicsServlet.TIME_FORMAT))
                .put("delayMillis", delayMillis)
                .put("requestCount", requestCount);
    }

    /**
     * {@code delay} パラメータを検証して、待ってよい時間に直す。
     *
     * <p>外から来た文字列を数値として使うときの手順は、いつもこの形になります。</p>
     * <ol>
     *   <li>未入力 (null や空文字) を先に片づける</li>
     *   <li>数値に直せなければ、例外を外へ出さずに既定値に倒す
     *       ({@code Long.parseLong} は数字以外でも桁があふれても例外になります)</li>
     *   <li>範囲を決めて、外れていたら丸める</li>
     * </ol>
     *
     * <p>ここでは不正な値でもエラーにせず 0 として扱っています。
     * 「待つ時間」という飾りの値だからで、<b>業務上の意味を持つ値なら
     * 黙って直さずエラーにする</b>ほうが安全です (400 を返す、など)。</p>
     *
     * @param raw リクエストパラメータの生の値 (null 可)
     * @return 0 以上 {@link #MAX_DELAY_MILLIS} 以下の待ち時間 (ミリ秒)
     */
    static long parseDelayMillis(String raw) {
        if (raw == null || raw.isBlank()) {
            return 0L;
        }
        long value;
        try {
            value = Long.parseLong(raw.strip());
        } catch (NumberFormatException e) {
            // 数字でない ("abc") / 桁が大きすぎる ("999999999999999999999") のどちらもここに来る
            return 0L;
        }
        if (value <= 0L) {
            return 0L;
        }
        return Math.min(value, MAX_DELAY_MILLIS);
    }

    /**
     * 指定された時間だけ待つ。
     *
     * <p>デモ専用の処理です。実際のアプリで応答をわざと遅らせることはありません。</p>
     *
     * <p>{@link InterruptedException} を握りつぶさず、割り込まれた印を戻しているのは、
     * 「このスレッドはもう止まってよい」という合図を呼び出し元へ伝えるためです。</p>
     */
    private static void sleepQuietly(long millis) {
        if (millis <= 0L) {
            return;
        }
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    /** サーバの名前とバージョン (例: {@code Apache Tomcat/9.0.x})。 */
    private String serverInfo() {
        return getServletContext().getServerInfo();
    }
}
