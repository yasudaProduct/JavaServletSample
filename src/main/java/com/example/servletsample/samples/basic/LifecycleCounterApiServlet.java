package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.concurrent.atomic.AtomicInteger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;

/**
 * 【サンプル】ライフサイクルのデモで使う、アクセス回数を数える JSON API。
 *
 * <p>この Servlet の本題は「<b>インスタンス変数は全リクエストで共有される</b>」ことを
 * 目に見える形にすることです。そのために、同じことを数える 2 つのカウンタを
 * わざと並べて持っています。</p>
 *
 * <ul>
 *   <li>{@link #atomicCount} … {@link AtomicInteger}。増やす操作が 1 つにまとまっているので安全</li>
 *   <li>{@link #unsafeCount} … ただの {@code int}。「読む → 書き戻す」の間に割り込まれる</li>
 * </ul>
 *
 * <p>画面から 50 件を同時に投げると、{@code atomic} は送った数どおりに増えるのに、
 * {@code unsafe} のほうは数が足りなくなります (失われた更新)。
 * 実際のコードでは {@code unsafeCount++} と 1 行で書いていても中身は同じ 3 手順なので、
 * ここでは隙間を人間に見える大きさにするために、間に短い待ちを挟んでいます。</p>
 *
 * <p>URL は {@code /samples/basic/servlet-lifecycle/api} で、サンプル本体の URL の下に
 * ぶら下げています (完全一致なので、前方一致の {@code /samples/*} より優先されます)。</p>
 *
 * <ul>
 *   <li>{@code GET} … 数えずに、いまの値を返すだけ</li>
 *   <li>{@code POST action=hit} … 2 つのカウンタを 1 増やして値を返す</li>
 *   <li>{@code POST action=reset} … 2 つのカウンタを 0 に戻す</li>
 * </ul>
 *
 * <p>{@code loadOnStartup = 1} を付けてあるので、この Servlet はアプリの起動時に
 * インスタンスが作られ、{@code init()} まで終わっています。
 * 指定していない {@link LifecycleServlet} との違いを画面で見比べられます。</p>
 */
@WebServlet(name = "servletLifecycleCounterApi",
        urlPatterns = {"/samples/basic/servlet-lifecycle/api"},
        loadOnStartup = 1)
public class LifecycleCounterApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /**
     * init の結果を {@code ServletContext} (アプリ全体で 1 つのスコープ) に控えるときのキー。
     *
     * <p>画面側の {@link LifecycleServlet} がここから読み取って表示します。
     * Servlet どうしが直接相手のフィールドを覗きに行くのではなく、
     * アプリのスコープを経由して受け渡すのが素直な書き方です。</p>
     */
    static final String INIT_AT_KEY = "servlet-lifecycle.api.initAt";

    /** init を処理したスレッド名を控えるキー。 */
    static final String INIT_THREAD_KEY = "servlet-lifecycle.api.initThread";

    /** インスタンスの識別子を控えるキー。 */
    static final String INSTANCE_KEY = "servlet-lifecycle.api.instance";

    /**
     * スレッドセーフでない側が「読んでから書き戻すまで」に空ける時間 (ミリ秒)。
     *
     * <p>本来この隙間はナノ秒単位で、目で見えるほどの差にはなかなかなりません。
     * 学習用に競合を確実に体験してもらうため、わざと広げています。</p>
     */
    private static final long UNSAFE_WINDOW_MILLIS = 5L;

    /**
     * 安全なカウンタ。
     *
     * <p>{@code final} なのはフィールド自体を差し替えないという意味で、
     * 中身の数値はスレッドセーフに増やせます。</p>
     */
    private final AtomicInteger atomicCount = new AtomicInteger();

    /**
     * わざとスレッドセーフにしていないカウンタ。
     *
     * <p>{@code volatile} も付けていません。値がずれるだけでなく、
     * 他のスレッドが書いた最新の値が見えないことすらあります。</p>
     */
    private int unsafeCount;

    /**
     * 起動時に 1 回だけ呼ばれる。
     *
     * <p>コンストラクタではなく init に書くのは、{@code ServletConfig} や
     * {@code ServletContext} が使えるようになるのが init の直前だからです。</p>
     */
    @Override
    public void init() throws ServletException {
        getServletContext().setAttribute(INIT_AT_KEY,
                LocalDateTime.now().format(LifecycleServlet.TIME_FORMAT));
        getServletContext().setAttribute(INIT_THREAD_KEY, Thread.currentThread().getName());
        getServletContext().setAttribute(INSTANCE_KEY, instanceId());
        log("LifecycleCounterApiServlet#init : " + instanceId()
                + " (loadOnStartup = 1 なので、アプリの起動時に呼ばれます)");
    }

    /** いまの値を読むだけ。状態を変えないので GET。 */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // GET の応答は、ブラウザや中継サーバにキャッシュされることがあります。
        // このデモは「送った回数」と「数えられた回数」を突き合わせるのが目的なので、
        // 古い値が返ってくると話が成立しません。毎回サーバに聞きに行かせます
        noStore(response);
        Json.write(response, snapshot());
    }

    /** カウンタを増やす / 戻す。状態を変えるので POST。 */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        noStore(response);
        if ("reset".equals(request.getParameter("action"))) {
            reset();
        } else {
            hit();
        }
        Json.write(response, snapshot());
    }

    /** この API の応答をキャッシュさせない。 */
    private static void noStore(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store");
    }

    /**
     * 2 つのカウンタを 1 ずつ増やす。
     *
     * <p>このメソッドは<b>同時に何本ものスレッドから呼ばれます</b>。
     * ローカル変数 {@code current} はスレッドごとに別物ですが、
     * フィールド {@link #unsafeCount} は全員で 1 つを共有しています。</p>
     */
    void hit() {
        // 安全な側 : 「読んで、足して、書き戻す」が 1 つの操作になっている
        atomicCount.incrementAndGet();

        // 危険な側 : 3 つの操作に分かれている
        int current = unsafeCount;          // ① 読む
        pauseToWidenTheGap();               // ② この隙間に、別のスレッドも同じ値を読む
        unsafeCount = current + 1;          // ③ 書き戻す → ②で読んだ側の結果を上書きしてしまう
    }

    /** 両方のカウンタを 0 に戻す。 */
    void reset() {
        atomicCount.set(0);
        unsafeCount = 0;
    }

    /** 安全な側の現在値 (テスト用)。 */
    int atomicValue() {
        return atomicCount.get();
    }

    /** 危険な側の現在値 (テスト用)。 */
    int unsafeValue() {
        return unsafeCount;
    }

    /**
     * 画面に返す JSON を組み立てる。
     *
     * <p>{@code thread} は<b>いま動いているスレッドの名前</b>なので、リクエストごとに変わります。
     * {@code instance} は<b>この Servlet インスタンスの識別子</b>なので、どのリクエストでも同じです。
     * 「スレッドはたくさん、インスタンスは 1 つ」がこの 2 つの値に表れます。</p>
     */
    Json.JsonObject snapshot() {
        return Json.object()
                .put("atomic", atomicCount.get())
                .put("unsafe", unsafeCount)
                .put("thread", Thread.currentThread().getName())
                .put("instance", instanceId());
    }

    /**
     * インスタンスの識別子。
     *
     * <p>{@code System.identityHashCode} は「そのオブジェクトが同じものかどうか」の目印です。
     * 同じインスタンスである限り値は変わらないので、
     * 「毎回 new されているわけではない」ことの確認に使えます。</p>
     */
    private String instanceId() {
        return getClass().getSimpleName() + "@"
                + Integer.toHexString(System.identityHashCode(this));
    }

    /** 競合を体験しやすくするための待ち。デモ専用で、実務のコードには書きません。 */
    private void pauseToWidenTheGap() {
        try {
            Thread.sleep(UNSAFE_WINDOW_MILLIS);
        } catch (InterruptedException e) {
            // 割り込まれたことを握りつぶさず、呼び出し元へ伝わるように印を戻しておく
            Thread.currentThread().interrupt();
        }
    }

    /**
     * アプリの停止・再配備の直前に 1 回だけ呼ばれる。
     *
     * <p>ここで消えるということは、フィールドに貯めた値は再配備で失われるということです
     * (このカウンタもリセットされます)。残したい値はデータベースなどに置きます。</p>
     */
    @Override
    public void destroy() {
        log("LifecycleCounterApiServlet#destroy : atomic=" + atomicCount.get()
                + " / unsafe=" + unsafeCount + " の状態で破棄されます");
    }
}
