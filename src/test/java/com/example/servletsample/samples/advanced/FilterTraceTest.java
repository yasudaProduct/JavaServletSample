package com.example.servletsample.samples.advanced;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * フィルタの通過記録 ({@link FilterTrace} / {@link FilterTraceStore}) のテスト。
 *
 * <p>確かめたいのは次の 2 点です。</p>
 * <ul>
 *   <li>行きは上から、帰りは逆順に並ぶ (入れ子の深さが正しく上下する)</li>
 *   <li>共有の置き場が上限を超えて膨らまない</li>
 * </ul>
 */
class FilterTraceTest {

    @BeforeEach
    void clearStore() {
        // static な置き場を使っているため、テストごとに空にしておく
        FilterTraceStore.clear();
    }

    @Test
    @DisplayName("行きは深くなり、帰りは同じ深さに戻る")
    void nestsAndUnnests() {
        FilterTrace trace = new FilterTrace("R-000001", "GET", "/samples/advanced/filter");

        trace.enter("RequestIdFilter", "採番した");
        trace.enter("AccessLogFilter", "開始時刻を記録した");
        trace.run("FilterServlet", "JSP へ転送した");
        trace.exit("AccessLogFilter", "処理時間を記録した");
        trace.exit("RequestIdFilter", "記録を保管した");

        List<FilterTrace.Step> steps = trace.getSteps();
        assertEquals(5, steps.size());

        // 通し番号は 1 から順に振られる
        for (int i = 0; i < steps.size(); i++) {
            assertEquals(i + 1, steps.get(i).getSeq());
        }

        // 深さ : 0 → 1 → 2(本体) → 1 → 0
        assertEquals(List.of(0, 1, 2, 1, 0),
                steps.stream().map(FilterTrace.Step::getDepth).toList());

        // 帰りは行きの逆順
        assertEquals("AccessLogFilter", steps.get(3).getName());
        assertEquals("RequestIdFilter", steps.get(4).getName());

        assertEquals(FilterTrace.Phase.BEFORE, steps.get(0).getPhase());
        assertEquals(FilterTrace.Phase.RUN, steps.get(2).getPhase());
        assertEquals(FilterTrace.Phase.AFTER, steps.get(4).getPhase());
    }

    @Test
    @DisplayName("深さは 0 より小さくならない")
    void depthNeverGoesBelowZero() {
        FilterTrace trace = new FilterTrace("R-000002", "GET", "/");

        trace.exit("こわれた呼び出し", "enter より先に exit した");
        trace.enter("RequestIdFilter", "採番した");

        assertEquals(0, trace.getSteps().get(0).getDepth());
        assertEquals(0, trace.getSteps().get(1).getDepth());
    }

    @Test
    @DisplayName("保管した記録はリクエスト ID で取り出せる")
    void savesAndFinds() {
        FilterTrace trace = new FilterTrace("R-000003", "GET", "/samples/advanced/filter/api");
        assertFalse(trace.isFinished());

        trace.finish(12L);
        FilterTraceStore.save(trace);

        FilterTrace found = FilterTraceStore.find("R-000003");
        assertNotNull(found);
        assertTrue(found.isFinished());
        assertEquals(12L, found.getElapsedMillis());

        assertNull(FilterTraceStore.find("R-999999"), "知らない ID では見つからない");
        assertNull(FilterTraceStore.find(null), "null でも落ちない");
    }

    @Test
    @DisplayName("置き場は上限を超えて膨らまない (古いものから捨てる)")
    void keepsOnlyRecentTraces() {
        for (int i = 1; i <= 30; i++) {
            FilterTrace trace = new FilterTrace(String.format("R-%06d", i), "GET", "/");
            trace.finish(1L);
            FilterTraceStore.save(trace);
        }

        List<FilterTrace> recent = FilterTraceStore.recent();
        assertEquals(20, recent.size(), "上限 20 件を超えて溜まっている");

        // 新しい順に並び、古いものは捨てられている
        assertEquals("R-000030", recent.get(0).getId());
        assertNull(FilterTraceStore.find("R-000010"), "古い記録は捨てられているはず");
        assertNotNull(FilterTraceStore.find("R-000011"));
    }
}
