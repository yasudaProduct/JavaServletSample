package com.example.servletsample.samples.advanced;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

/**
 * 【サンプル】非同期処理の仕事を回すためのスレッドプール。
 *
 * <p>{@code AsyncContext} は「リクエストの応答を後回しにできる」だけで、
 * <b>仕事を代わりにやってくれるスレッドは付いてきません</b>。
 * 待っている間の仕事はアプリ側で用意したスレッドに任せます。それがこのクラスです。</p>
 *
 * <h2>スレッドプールはリスナーが作って、リスナーが閉じる</h2>
 * <p>作るのはアプリの起動時 ({@code contextInitialized})、閉じるのは停止時
 * ({@code contextDestroyed}) です。閉じ忘れると、アプリを入れ替えてもスレッドが残り続け、
 * 古いクラスローダごとメモリに居座ります (Tomcat が
 * 「appears to have started a thread ... but has failed to stop it」と警告するのがこれです)。
 * リスナーそのものの説明は「リスナーで起動・終了・セッションを捕まえる」のサンプルにあります。</p>
 *
 * <h2>スレッドは {@value #POOL_SIZE} 本、待ち行列は {@value #QUEUE_CAPACITY} 件まで</h2>
 * <p>デモで「詰まる様子」を見せたいので、わざと小さくしています。
 * 大事なのは<b>上限があること</b>です。{@code Executors.newCachedThreadPool()} のように
 * 際限なくスレッドを作る設定にすると、混雑したときにスレッドが増え続けてサーバごと倒れます。
 * 待ち行列があふれたときは {@link RejectedExecutionException} が飛ぶので、
 * 呼び出し側で「いま混み合っています」と返します
 * (黙って捨てる {@code DiscardPolicy} にすると、返事が返らないリクエストができてしまいます)。</p>
 */
@WebListener
public class AsyncWorkerPool implements ServletContextListener {

    /** 同時に動かすスレッドの数。 */
    static final int POOL_SIZE = 2;

    /** 順番待ちに並べる件数の上限。 */
    static final int QUEUE_CAPACITY = 20;

    /** アプリ全体で 1 つ。起動時に作り、停止時に閉じる。 */
    private static volatile ThreadPoolExecutor pool;

    @Override
    public void contextInitialized(ServletContextEvent event) {
        AtomicInteger counter = new AtomicInteger();
        pool = new ThreadPoolExecutor(
                POOL_SIZE, POOL_SIZE,
                0L, TimeUnit.MILLISECONDS,
                new ArrayBlockingQueue<>(QUEUE_CAPACITY),
                runnable -> {
                    // 名前を付けておくと、スレッドダンプや画面で見分けられる
                    Thread thread = new Thread(runnable, "async-worker-" + counter.incrementAndGet());
                    thread.setDaemon(true);
                    return thread;
                },
                new ThreadPoolExecutor.AbortPolicy());
        event.getServletContext().log("非同期サンプルのスレッドプールを作りました (" + POOL_SIZE + " 本)");
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        ServletContext context = event.getServletContext();
        ThreadPoolExecutor current = pool;
        pool = null;
        if (current == null) {
            return;
        }
        current.shutdown();   // 新しい仕事は受け付けず、動いている分は終わらせる
        try {
            if (!current.awaitTermination(5, TimeUnit.SECONDS)) {
                current.shutdownNow();   // 待っても終わらなければ割り込む
                context.log("非同期サンプルのスレッドプールを強制的に止めました");
            }
        } catch (InterruptedException e) {
            current.shutdownNow();
            Thread.currentThread().interrupt();   // 割り込まれたことを呼び出し元に伝え直す
        }
        context.log("非同期サンプルのスレッドプールを閉じました");
    }

    /**
     * 仕事を投げる。
     *
     * @throws RejectedExecutionException 待ち行列があふれているとき、
     *                                    またはアプリが停止処理に入っているとき
     */
    static void submit(Runnable work) {
        ThreadPoolExecutor current = pool;
        if (current == null) {
            throw new RejectedExecutionException("スレッドプールが動いていません");
        }
        current.execute(work);
    }

    /** いま順番待ちしている件数。 */
    static int queuedCount() {
        ThreadPoolExecutor current = pool;
        return current == null ? 0 : current.getQueue().size();
    }
}
