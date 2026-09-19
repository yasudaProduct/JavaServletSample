package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.atomic.AtomicInteger;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】Servlet のライフサイクルとスレッド。
 *
 * <p>Servlet はリクエストのたびに {@code new} されるわけではありません。
 * ひとつの Servlet につきインスタンスは<b>アプリ全体で 1 つ</b>だけ作られ、
 * そこへ<b>リクエストごとに別のスレッド</b>が同時に入ってきます。
 * この「1 インスタンス × 複数スレッド」が、Servlet を書くうえでの大前提です。</p>
 *
 * <p>呼ばれる順番は次のとおりです。</p>
 * <ol>
 *   <li>{@code init()} … インスタンスが作られた直後に 1 回だけ</li>
 *   <li>{@code service()} → {@code doGet()} / {@code doPost()} … リクエストのたびに、別々のスレッドで</li>
 *   <li>{@code destroy()} … アプリの停止・再配備の直前に 1 回だけ</li>
 * </ol>
 *
 * <p>この Servlet は {@code loadOnStartup} を指定していないので、init が呼ばれるのは
 * <b>最初にこの画面を開いた人のリクエスト</b>のときです。
 * 一方、カウンタ API ({@link LifecycleCounterApiServlet}) には {@code loadOnStartup = 1} を
 * 付けてあるので、アプリの起動時にはもう init が終わっています。
 * 画面ではその 2 つを並べて、init の時刻とスレッド名を見比べられるようにしています。</p>
 *
 * <p>フィールドに持たせているのは「init で決めて以降は変えない値」と、
 * スレッドセーフな {@link AtomicInteger} だけにしています。
 * リクエストごとに変わる値 (パラメータ、ユーザー名、処理結果など) は、
 * かならずローカル変数かリクエストスコープに置きます。</p>
 */
@WebServlet(name = "servletLifecycle", urlPatterns = {"/samples/basic/servlet-lifecycle"})
public class LifecycleServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/basic/servlet-lifecycle.jsp";

    /**
     * 時刻の書式。
     *
     * <p>{@link DateTimeFormatter} は不変 (immutable) でスレッドセーフなので、
     * {@code static final} で共有して構いません。
     * 昔からある {@code SimpleDateFormat} は<b>スレッドセーフではない</b>ため、
     * 同じ書き方をすると日付がおかしくなる、という有名な事故があります。</p>
     */
    static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss.SSS");

    /** init が呼ばれた時刻。init で一度だけ代入し、以降は読むだけなので共有しても安全。 */
    private String initAtText = "";

    /** init を処理したスレッドの名前。 */
    private String initThreadName = "";

    /**
     * この画面を返した回数。
     *
     * <p>全リクエストで共有されるフィールドなので、ただの {@code int} にすると
     * 数がずれます ({@code count++} は「読む・足す・書く」の 3 手順です)。
     * 数えるだけなら {@link AtomicInteger} を使うのが一番簡単です。</p>
     */
    private final AtomicInteger displayCount = new AtomicInteger();

    @Override
    public void init() throws ServletException {
        // loadOnStartup を指定していないので、ここが動くのは最初のアクセスのとき
        initAtText = LocalDateTime.now().format(TIME_FORMAT);
        initThreadName = Thread.currentThread().getName();
        log("LifecycleServlet#init : " + instanceId() + " を作りました");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // --- この Servlet インスタンス自身の情報 (何度リロードしても変わらない) ---
        request.setAttribute("initAt", initAtText);
        request.setAttribute("initThread", initThreadName);
        request.setAttribute("instanceId", instanceId());

        // --- いまのリクエストの情報 (リロードのたびに変わる) ---
        //     スレッド名はローカル変数で受けています。フィールドに入れてしまうと、
        //     隣のリクエストのスレッド名を表示する画面になります。
        String threadName = Thread.currentThread().getName();
        request.setAttribute("currentThread", threadName);
        request.setAttribute("displayCount", displayCount.incrementAndGet());

        // --- 相方の Servlet (カウンタ API) の情報 ---
        //     API 側が init のときに ServletContext (アプリ全体のスコープ) へ
        //     控えておいた値を読み出しています。
        ServletContext context = getServletContext();
        request.setAttribute("apiInitAt", textOf(context.getAttribute(LifecycleCounterApiServlet.INIT_AT_KEY)));
        request.setAttribute("apiInitThread", textOf(context.getAttribute(LifecycleCounterApiServlet.INIT_THREAD_KEY)));
        request.setAttribute("apiInstanceId", textOf(context.getAttribute(LifecycleCounterApiServlet.INSTANCE_KEY)));

        forward(request, response, VIEW);
    }

    /** ServletContext から読んだ値を画面に出せる形にする (未設定なら説明文を返す)。 */
    private static String textOf(Object value) {
        return value == null ? "(まだ init されていません)" : String.valueOf(value);
    }

    /**
     * インスタンスの識別子。
     *
     * <p>{@code System.identityHashCode} の値です。同じインスタンスである限り変わらないので、
     * 「リクエストのたびに作り直されてはいない」ことの確認に使えます。</p>
     */
    private String instanceId() {
        return getClass().getSimpleName() + "@"
                + Integer.toHexString(System.identityHashCode(this));
    }

    /**
     * アプリの停止・再配備の直前に 1 回だけ呼ばれる。
     *
     * <p>ただし、プロセスを強制終了した場合や電源が落ちた場合は呼ばれません。
     * 「ここで必ず保存する」という作りにしないでください。</p>
     */
    @Override
    public void destroy() {
        log("LifecycleServlet#destroy : " + displayCount.get() + " 回表示した状態で破棄されます");
    }
}
