package com.example.servletsample.samples.ajax;

import java.io.IOException;
import java.io.Serializable;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;

/**
 * 【サンプル】進捗のポーリングで使う JSON API。
 *
 * <p>画面 ({@link AjaxPollingServlet} が表示する JSP) が
 * 1 秒おきに叩く先です。1 つの URL で 2 つの役目を持たせています。</p>
 *
 * <table border="1">
 *   <caption>この API の使い分け</caption>
 *   <tr><th>メソッド</th><th>パラメータ</th><th>やること</th></tr>
 *   <tr><td>{@code GET}</td><td>―</td><td>いまの進捗を返す (状態を変えない)</td></tr>
 *   <tr><td>{@code POST}</td><td>{@code action=start}</td><td>集計を開始する</td></tr>
 *   <tr><td>{@code POST}</td><td>{@code action=cancel}</td><td>集計を中止する</td></tr>
 * </table>
 *
 * <p>進捗を読むだけの問い合わせが GET、状態を変える開始と中止が POST です。
 * ここを分けておかないと、ブラウザや中継サーバが「GET は何度呼んでも同じ」と見なして
 * 勝手に再実行・キャッシュしたときに、集計が勝手に開始されることになります。</p>
 *
 * <h2>サーバ側でスレッドもタイマーも作っていません</h2>
 * <p>このサンプルの「時間のかかる集計」は擬似的なものです。
 * セッションに<b>開始時刻だけ</b>を覚えておき、問い合わせが来るたびに
 * 「いま - 開始時刻」を {@value #TOTAL_MILLIS} ミリ秒で割って進捗を計算しています。</p>
 *
 * <pre>{@code
 * 進捗 (%) = (いまの時刻 - 開始時刻) * 100 / 8000
 * }</pre>
 *
 * <p>学習用に軽くしているという理由だけではありません。Servlet の中から
 * {@code new Thread(...)} を起こす作りは、実務では避けるべきものです。</p>
 * <ul>
 *   <li>アプリを再配備 (デプロイ) すると、走っているスレッドの後始末ができない</li>
 *   <li>サーバを 2 台に増やすと、どちらのメモリにある進捗なのか分からなくなる</li>
 *   <li>何本まで同時に走ってよいかを誰も制御していない</li>
 * </ul>
 * <p>本当に重い処理を動かすなら、実行中の状態をデータベースの「ジョブ」の行として持ち、
 * 実行は専用の仕組み (バッチ基盤、ジョブキュー、{@code ManagedExecutorService} など) に任せます。
 * その形にしておけば、この API は<b>ジョブの行を読んで返すだけ</b>になり、
 * 画面側のコードはこのサンプルのままで通用します。</p>
 *
 * <h2>進捗はサーバ側 (セッション) が持つ</h2>
 * <p>開始時刻を画面の JavaScript の変数に持たせると、画面を再読み込みした瞬間に消えます。
 * ここではセッションに入れているので、画面を開き直しても続きから進捗を見られます
 * ({@link AjaxPollingServlet} が開き直したときの状態を JSP へ渡しています)。</p>
 *
 * <p>ただしセッションは「そのブラウザだけのもの」で、
 * サーバを再起動すると消え、別の端末からは見えません。
 * 「あとから別の画面で結果を見たい」「担当者がやり直したい」といった要件が出てきたら、
 * 置き場所をデータベースに移すことになります。</p>
 */
@WebServlet(name = "ajaxPollingApi", urlPatterns = {"/samples/ajax/ajax-polling/api"})
public class AjaxPollingApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** この API の URL (画面へ渡して、JavaScript の fetch 先にする)。 */
    static final String PATH = "/samples/ajax/ajax-polling/api";

    /** 擬似的な集計処理にかかることにしている時間 (ミリ秒)。 */
    static final long TOTAL_MILLIS = 8000L;

    /** 同じ長さを秒で表したもの (画面に「8 秒」と出すため)。 */
    static final int TOTAL_SECONDS = (int) (TOTAL_MILLIS / 1000L);

    /**
     * セッションに進捗を入れるときのキー。
     *
     * <p>セッションはアプリ全体で 1 つの入れ物です。{@code "job"} のような
     * ありふれた名前を使うと、別の画面が入れた値と取り違えます。
     * サンプル名を前に付けて、ぶつからないようにしています。</p>
     */
    static final String JOB_KEY = "ajaxPolling.job";

    /** セッションに「この API を何回叩かれたか」を入れるときのキー。 */
    static final String POLL_COUNT_KEY = "ajaxPolling.pollCount";

    /**
     * 画面に出す時刻の書式。
     *
     * <p>{@link DateTimeFormatter} は変更できないオブジェクトなので、
     * 複数のスレッドから同時に使っても安全です ({@code SimpleDateFormat} はこの逆で、
     * {@code static} のフィールドに置くと同時アクセスで壊れます)。</p>
     */
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm:ss");

    /**
     * いまの進捗を返す (GET)。
     *
     * <p>読むだけなので GET です。1 秒おきに呼ばれることを前提に、
     * <b>軽い処理しか書かない</b>のがポーリング用 API の鉄則です。
     * ここで DB を何本も引いたり重い集計をしたりすると、
     * 画面を開いている人数 × 1 秒あたり 1 回の負荷がそのままサーバにかかります。</p>
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        // 進捗は毎回サーバに聞きに行ってほしいので、キャッシュを止めます。
        // これが無いと、ブラウザや中継サーバが前回の応答を使い回し、
        // 「進捗が 37% のまま動かない」という分かりにくい不具合になります
        response.setHeader("Cache-Control", "no-store");

        Json.JsonObject payload;

        // 1 秒おきの問い合わせと、開始・中止の操作は重なることがあります。
        // セッションの中身を読みながら書き換える部分は、まとめて 1 つずつ通します
        synchronized (session) {
            long pollCount = countPoll(session);
            payload = statusPayload(findJob(session), System.currentTimeMillis(), pollCount);
        }

        // 書き出すのはロックの外で。応答を書く処理は相手のネットワークしだいで待たされるため、
        // その間ロックを握り続けると、同じセッションの他のリクエストまで止まります
        Json.write(response, payload);
    }

    /**
     * 集計の開始・中止を受け付ける (POST)。
     *
     * <p>状態を変えるので POST です。どちらの操作でも、
     * 返すのは GET と同じ形の進捗 JSON にしています。
     * こうしておくと画面側は「返ってきた JSON で画面を描き直す」1 本の処理で済みます。</p>
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 画面は application/x-www-form-urlencoded で送ってくるので、
        // 普通のフォームと同じ getParameter で受け取れます
        // (JSON を本文に入れて送った場合、getParameter では取れません)
        String action = request.getParameter("action");

        HttpSession session = request.getSession();
        response.setHeader("Cache-Control", "no-store");

        int status = HttpServletResponse.SC_OK;
        Json.JsonObject payload;

        synchronized (session) {
            long now = System.currentTimeMillis();

            if ("start".equals(action)) {
                Job running = runningJob(session, now);
                if (running != null) {
                    // すでに実行中。画面側でもボタンを disabled にしていますが、
                    // それは「押しにくくする」だけの話です。
                    // URL を直接叩かれても二重に始まらないよう、断るのはサーバの仕事です
                    status = HttpServletResponse.SC_CONFLICT;   // 409
                    payload = statusPayload(running, now, pollCount(session), false,
                            "すでに集計を実行中です。完了するか、中止してから開始してください。");
                } else {
                    // 新しい集計を始める = セッションに開始時刻を置くだけ。
                    // スレッドもタイマーも作りません
                    Job job = new Job(now, LocalDateTime.now().format(TIME_FORMAT));
                    session.setAttribute(JOB_KEY, job);
                    session.setAttribute(POLL_COUNT_KEY, 0L);   // 問い合わせ回数を数え直す
                    payload = statusPayload(job, now, 0L);
                }

            } else if ("cancel".equals(action)) {
                // 中止は「覚えていた開始時刻を捨てる」だけ。
                // 画面がタイマーを止めるのとは別に、サーバ側の状態も消しておきます。
                // 消さずに画面のタイマーだけ止めると、開き直したときに
                // 「中止したはずの集計」がまた進んでいるように見えます
                session.removeAttribute(JOB_KEY);
                payload = statusPayload(null, now, pollCount(session));

            } else {
                // 想定外の値。画面の不具合か、直接叩かれたかのどちらかなので 400 を返します
                status = HttpServletResponse.SC_BAD_REQUEST;    // 400
                payload = statusPayload(findJob(session), now, pollCount(session), false,
                        "action には start か cancel を指定してください。");
            }
        }

        response.setStatus(status);
        Json.write(response, payload);
    }

    // ------------------------------------------------------------------
    // ここから下は Servlet コンテナが要らない、ただの計算。
    // テスト (AjaxPollingApiServletTest) はこちらを直接呼んで確かめています
    // ------------------------------------------------------------------

    /**
     * 画面へ返す進捗 JSON を組み立てる (正常時)。
     *
     * @param job        実行中・完了済みの集計 (無ければ null)
     * @param nowMillis  いまの時刻。引数で受け取るのは、テストで時間を止められるようにするため
     * @param pollCount  この API がセッション内で呼ばれた回数
     */
    static Json.JsonObject statusPayload(Job job, long nowMillis, long pollCount) {
        return statusPayload(job, nowMillis, pollCount, true, null);
    }

    /**
     * 画面へ返す進捗 JSON を組み立てる。
     *
     * <p>返す形は、集計が無いときも実行中のときも完了後も<b>同じ</b>にしています。
     * 「状態によって項目が増えたり消えたりする JSON」は、
     * 受け取る側が {@code if} だらけになるので避けます。</p>
     *
     * <pre>{@code
     * {"ok":true,"problem":null,"state":"running","running":true,"done":false,
     *  "percent":37,"elapsedSeconds":3,"totalSeconds":8,
     *  "message":"明細データを読み込んでいます...","startedAt":"12:34:56",
     *  "resultCount":null,"serverPollCount":4}
     * }</pre>
     *
     * <p>{@code running} と {@code done} を別々に持たせているのは、
     * 画面が知りたいことが 2 つあるからです
     * (「進捗バーを動かし続けるか」と「結果を出してよいか」)。
     * 状態の名前も {@code state} として文字列で返しておくと、ログに出したときに読めます。</p>
     *
     * @param ok      要求を受け付けられたか (二重開始を断ったときなどは false)
     * @param problem 受け付けられなかった理由 (無ければ null)
     */
    static Json.JsonObject statusPayload(Job job, long nowMillis, long pollCount,
                                         boolean ok, String problem) {

        if (job == null) {
            // まだ開始していない / 中止した状態
            return Json.object()
                    .put("ok", ok)
                    .put("problem", problem)
                    .put("state", "idle")
                    .put("running", false)
                    .put("done", false)
                    .put("percent", 0)
                    .put("elapsedSeconds", 0)
                    .put("totalSeconds", TOTAL_SECONDS)
                    .put("message", "集計は動いていません。")
                    .put("startedAt", null)
                    .put("resultCount", null)
                    .put("serverPollCount", pollCount);
        }

        long elapsed = nowMillis - job.getStartedAtMillis();
        int percent = percentOf(elapsed);
        boolean done = percent >= 100;

        return Json.object()
                .put("ok", ok)
                .put("problem", problem)
                .put("state", done ? "done" : "running")
                // running は「まだ動いているか」。完了したら false になるので、
                // 画面は running が false になった時点で問い合わせを止められます
                .put("running", !done)
                .put("done", done)
                .put("percent", percent)
                .put("elapsedSeconds", elapsedSecondsOf(elapsed))
                .put("totalSeconds", TOTAL_SECONDS)
                .put("message", messageOf(percent))
                .put("startedAt", job.getStartedAtText())
                // 結果は完了してから。未完了のときに 0 を返すと、
                // 画面側が「0 件で終わった」と誤って表示してしまいます
                .put("resultCount", done ? resultCountOf(job.getStartedAtMillis()) : null)
                .put("serverPollCount", pollCount);
    }

    /**
     * 経過時間から進捗 (0〜100) を求める。
     *
     * <p>{@code elapsedMillis * 100} を先に計算しているのは、
     * 整数の割り算で小数が切り捨てられるのを避けるためです
     * ({@code elapsed / TOTAL} だと、終わるまでずっと 0 になります)。</p>
     *
     * <p>0 未満と 100 超えを先に潰しておくのも大事です。
     * サーバの時刻が調整されて {@code elapsedMillis} が負になることもあり、
     * そのまま計算すると進捗バーの幅が負の値になります。</p>
     */
    static int percentOf(long elapsedMillis) {
        if (elapsedMillis <= 0L) {
            return 0;
        }
        if (elapsedMillis >= TOTAL_MILLIS) {
            return 100;
        }
        return (int) (elapsedMillis * 100L / TOTAL_MILLIS);
    }

    /**
     * 経過時間を秒に直す。
     *
     * <p>進捗 (%) は 100 で頭打ちにしていますが、秒数は頭打ちにしていません。
     * 画面を閉じて 1 分後に開き直したときに「経過 62 秒」と出るのは、
     * 実際にそれだけ時間が経っているからです
     * (集計そのものは 8 秒で終わっていた、という見え方になります)。</p>
     */
    static int elapsedSecondsOf(long elapsedMillis) {
        if (elapsedMillis <= 0L) {
            return 0;
        }
        return (int) Math.min(elapsedMillis / 1000L, Integer.MAX_VALUE);
    }

    /**
     * 進捗に応じて、いま何をしているかの文を返す。
     *
     * <p>パーセントだけの画面は「本当に動いているのか」が伝わりません。
     * 実際の処理でも「対象を数えている」「明細を読んでいる」といった段階は分かるはずなので、
     * 短くても今やっていることを返すと、待っている人の不安が減ります。</p>
     */
    static String messageOf(int percent) {
        if (percent >= 100) {
            return "集計が完了しました。";
        }
        if (percent >= 75) {
            return "レポートを組み立てています...";
        }
        if (percent >= 50) {
            return "カテゴリごとに合計しています...";
        }
        if (percent >= 25) {
            return "明細データを読み込んでいます...";
        }
        return "対象データを数えています...";
    }

    /**
     * 完了したときに返す「集計できた件数」を求める。
     *
     * <p>デモ用の値ですが、<b>開始時刻から決まる値</b>にしてあります。
     * {@code Math.random()} で毎回作ると、100% になったあとに
     * もう一度問い合わせたときに件数が変わってしまい、
     * 「結果が確定していない画面」になってしまうためです。</p>
     *
     * <p>実際のジョブでも同じで、結果は処理が終わった時点で 1 回だけ確定させ、
     * 以後の問い合わせにはその値を返します。</p>
     */
    static int resultCountOf(long startedAtMillis) {
        return 1200 + (int) Math.floorMod(startedAtMillis / 1000L, 800L);
    }

    /**
     * セッションから集計の状態を取り出す。
     *
     * <p>{@code getAttribute} が返すのは {@code Object} です。
     * {@code instanceof} で確かめてから使うのは、
     * アプリを入れ替えたあとに<b>古いクラスのまま復元されたセッション</b>が
     * 残っていることがあるためです (いきなりキャストすると例外になります)。</p>
     *
     * @param session セッション (まだ無ければ null でよい)
     */
    static Job findJob(HttpSession session) {
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute(JOB_KEY);
        return value instanceof Job ? (Job) value : null;
    }

    /**
     * 「まだ実行中の」集計だけを取り出す (完了済みなら null)。
     *
     * <p>二重開始を断る判定に使います。完了済みの集計が残っているときは、
     * 新しく開始してかまいません。</p>
     */
    static Job runningJob(HttpSession session, long nowMillis) {
        Job job = findJob(session);
        if (job == null) {
            return null;
        }
        return percentOf(nowMillis - job.getStartedAtMillis()) < 100 ? job : null;
    }

    /** これまでにこのセッションから問い合わせが来た回数。 */
    static long pollCount(HttpSession session) {
        if (session == null) {
            return 0L;
        }
        Object value = session.getAttribute(POLL_COUNT_KEY);
        return value instanceof Long ? (Long) value : 0L;
    }

    /** 問い合わせ回数を 1 つ増やして、増やしたあとの値を返す。 */
    private static long countPoll(HttpSession session) {
        long next = pollCount(session) + 1L;
        session.setAttribute(POLL_COUNT_KEY, next);
        return next;
    }

    /**
     * 実行中の集計。セッションに入れておく値。
     *
     * <p>持っているのは<b>開始時刻だけ</b>です。進捗そのものは持ちません。
     * 「いま何 % か」は問い合わせが来たときに計算すればよく、
     * 覚えておくとかえって食い違いの原因になります。</p>
     *
     * <p>{@link Serializable} を付けているのは、セッションに入れる値の作法です。
     * コンテナは再起動をまたぐためにセッションをファイルへ書き出したり、
     * 複数台のサーバ間で複製したりすることがあり、
     * そのときに {@code Serializable} でないオブジェクトは捨てられるか、例外になります。</p>
     *
     * <p>値を書き換えられない形 (フィールドはすべて {@code final}) にしてあるのも理由があります。
     * 1 秒おきの問い合わせは別々のスレッドで動くので、
     * 途中まで書き換えた状態を他のスレッドが読む事故が起きません。
     * 状態を変えるときは、新しい {@code Job} に差し替えるか、捨てるかのどちらかです。</p>
     */
    static final class Job implements Serializable {

        private static final long serialVersionUID = 1L;

        /** 開始した時刻 (計算用のミリ秒)。 */
        private final long startedAtMillis;

        /** 開始した時刻 (画面に出す文字列)。 */
        private final String startedAtText;

        Job(long startedAtMillis, String startedAtText) {
            this.startedAtMillis = startedAtMillis;
            this.startedAtText = startedAtText;
        }

        long getStartedAtMillis() {
            return startedAtMillis;
        }

        String getStartedAtText() {
            return startedAtText;
        }
    }
}
