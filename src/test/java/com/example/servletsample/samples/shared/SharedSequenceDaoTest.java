package com.example.servletsample.samples.shared;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@link SharedSequenceDao} のテスト。
 *
 * <p>DB に寄せた採番は、どこから呼ばれても 1 つの連番になります。
 * {@link SimulatedServerTest} で確かめた「static は台ごとに別」と
 * 対になる性質です。</p>
 */
class SharedSequenceDaoTest {

    private final SharedSequenceDao dao = new SharedSequenceDao();

    @BeforeEach
    void reset() {
        dao.reset();
    }

    @Test
    @DisplayName("1 から順に発行する")
    void issuesInOrder() {
        assertEquals(1, dao.next());
        assertEquals(2, dao.next());
        assertEquals(3, dao.next());
    }

    @Test
    @DisplayName("別のインスタンスから呼んでも連番が続く（数えている場所が 1 つ）")
    void sharedAcrossInstances() {
        assertEquals(1, dao.next());

        // 「別のサーバーのアプリ」に相当。DAO のインスタンスは別でも DB は 1 つ
        SharedSequenceDao another = new SharedSequenceDao();
        assertEquals(2, another.next());
        assertEquals(3, dao.next());
    }

    @Test
    @DisplayName("current は発行せずに現在値を返す")
    void currentDoesNotIssue() {
        dao.next();
        assertEquals(1, dao.current());
        assertEquals(1, dao.current());
    }

    @Test
    @DisplayName("同時に呼んでも番号が重複しない")
    void doesNotDuplicateUnderConcurrency() throws Exception {
        int threads = 8;
        int perThread = 10;
        java.util.Set<Integer> issued = java.util.Collections.synchronizedSet(new java.util.HashSet<>());
        java.util.concurrent.ExecutorService pool =
                java.util.concurrent.Executors.newFixedThreadPool(threads);
        try {
            java.util.List<java.util.concurrent.Future<?>> futures = new java.util.ArrayList<>();
            for (int i = 0; i < threads; i++) {
                futures.add(pool.submit(() -> {
                    for (int n = 0; n < perThread; n++) {
                        issued.add(dao.next());
                    }
                }));
            }
            for (java.util.concurrent.Future<?> future : futures) {
                future.get();
            }
        } finally {
            pool.shutdown();
        }
        assertEquals(threads * perThread, issued.size(), "重複した番号が発行されています");
        assertTrue(issued.contains(1));
        assertTrue(issued.contains(threads * perThread));
    }
}
