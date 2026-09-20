package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * カウンタ API ({@link LifecycleCounterApiServlet}) のテスト。
 *
 * <p>Servlet コンテナは起動しません。Servlet も「ただの Java のクラス」なので、
 * {@code new} して {@code hit()} を直接呼べば、複数スレッドから同時に叩いたときの
 * ふるまいだけを取り出して確かめられます
 * (画面では 50 本の {@code fetch} が担っている部分です)。</p>
 *
 * <p>「スレッドセーフでない側は必ずずれる」とは書けません。競合は<b>重なったときだけ</b>
 * 起きるからです。テストとして確実に言えるのは次の 2 つで、そこを検査しています。</p>
 * <ul>
 *   <li>{@code AtomicInteger} の側は<b>必ず</b>呼んだ回数と一致する</li>
 *   <li>素の {@code int} の側は<b>呼んだ回数を超えない</b> (増えすぎではなく取りこぼしが起きる)</li>
 * </ul>
 */
class LifecycleCounterApiServletTest {

    /** 同時に叩くスレッドの数。 */
    private static final int THREADS = 8;

    /** 1 スレッドあたりの呼び出し回数。 */
    private static final int HITS_PER_THREAD = 20;

    /** 呼び出しの合計。 */
    private static final int TOTAL = THREADS * HITS_PER_THREAD;

    @Test
    @DisplayName("1 回呼ぶと両方のカウンタが 1 ずつ増える")
    void singleHitIncrementsBothCounters() {
        LifecycleCounterApiServlet servlet = new LifecycleCounterApiServlet();

        servlet.hit();

        assertEquals(1, servlet.atomicValue());
        assertEquals(1, servlet.unsafeValue());
    }

    @Test
    @DisplayName("AtomicInteger のカウンタは同時に増やしても数が合う")
    void atomicCounterKeepsExactCount() throws InterruptedException {
        LifecycleCounterApiServlet servlet = new LifecycleCounterApiServlet();

        hitConcurrently(servlet);

        assertEquals(TOTAL, servlet.atomicValue(),
                "incrementAndGet は読み出しと書き戻しが 1 つの操作なので、取りこぼしてはいけません");
    }

    @Test
    @DisplayName("スレッドセーフでない int のカウンタは、呼んだ回数を超えない（取りこぼす側にずれる）")
    void unsafeCounterNeverExceedsTheNumberOfCalls() throws InterruptedException {
        LifecycleCounterApiServlet servlet = new LifecycleCounterApiServlet();

        hitConcurrently(servlet);

        int unsafe = servlet.unsafeValue();
        assertTrue(unsafe <= TOTAL,
                "「読む → 書き戻す」の競合で起きるのは失われた更新なので、呼んだ回数より増えることはありません: " + unsafe);
        assertTrue(unsafe > 0, "1 件も数えられていないのはおかしい: " + unsafe);
        assertTrue(unsafe <= servlet.atomicValue(),
                "安全な側より多くなることはありません: unsafe=" + unsafe + " / atomic=" + servlet.atomicValue());
    }

    @Test
    @DisplayName("画面へ返す JSON に atomic / unsafe / thread / instance が入っている")
    void snapshotContainsAllValues() {
        LifecycleCounterApiServlet servlet = new LifecycleCounterApiServlet();
        servlet.hit();

        String json = servlet.snapshot().toString();

        assertTrue(json.contains("\"atomic\":1"), json);
        assertTrue(json.contains("\"unsafe\":1"), json);
        assertTrue(json.contains("\"thread\":\""), json);
        assertTrue(json.contains("\"instance\":\"LifecycleCounterApiServlet@"), json);
    }

    @Test
    @DisplayName("リセットすると両方のカウンタが 0 に戻る")
    void resetClearsBothCounters() {
        LifecycleCounterApiServlet servlet = new LifecycleCounterApiServlet();
        servlet.hit();
        servlet.hit();

        servlet.reset();

        assertEquals(0, servlet.atomicValue());
        assertEquals(0, servlet.unsafeValue());
    }

    /**
     * 複数のスレッドから {@code hit()} を一斉に呼ぶ。
     *
     * <p>スレッドを作った順に走らせると重なりにくいので、
     * {@link CountDownLatch} で全員を待たせてから同時に走り出させています。</p>
     */
    private static void hitConcurrently(LifecycleCounterApiServlet servlet) throws InterruptedException {
        CountDownLatch startGate = new CountDownLatch(1);
        List<Thread> threads = new ArrayList<>();

        for (int i = 0; i < THREADS; i++) {
            Thread thread = new Thread(() -> {
                try {
                    startGate.await();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    return;
                }
                for (int n = 0; n < HITS_PER_THREAD; n++) {
                    servlet.hit();
                }
            }, "hit-" + i);
            thread.start();
            threads.add(thread);
        }

        startGate.countDown();
        for (Thread thread : threads) {
            thread.join();
        }
    }
}
