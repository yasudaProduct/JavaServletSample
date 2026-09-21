package com.example.servletsample.samples.advanced;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * リスナーの記録 ({@link ListenerEventLog}) のテスト。
 *
 * <p>確かめたいのは次の 3 点です。</p>
 * <ul>
 *   <li>新しいものが先頭に並ぶ</li>
 *   <li>アプリ全体で共有する入れ物が、上限を超えて膨らまない</li>
 *   <li>セッションの数え方 (作られた数は増えるだけ、生きている数は増減する)</li>
 * </ul>
 */
class ListenerEventLogTest {

    @BeforeEach
    void reset() {
        // static な置き場を使っているため、テストごとに起動直後の状態へ戻す
        ListenerEventLog.markStarted(LocalDateTime.now());
    }

    @Test
    @DisplayName("記録は新しいものが先頭に並ぶ")
    void newestComesFirst() {
        ListenerEventLog.add(ListenerEvent.Kind.APPLICATION, "AppLifecycleListener",
                "contextInitialized", "起動しました");
        ListenerEventLog.add(ListenerEvent.Kind.SESSION, "SessionLifecycleListener",
                "sessionCreated", "セッションができました");

        List<ListenerEvent> events = ListenerEventLog.recent();
        assertEquals(2, events.size());
        assertEquals("sessionCreated", events.get(0).getMethod());
        assertEquals("contextInitialized", events.get(1).getMethod());

        // 通し番号は 1 から順に振られる
        assertEquals(2, events.get(0).getSeq());
        assertEquals(1, events.get(1).getSeq());
    }

    @Test
    @DisplayName("上限を超えた分は古いものから捨てられる")
    void keepsOnlyRecentEvents() {
        int over = ListenerEventLog.MAX_EVENTS + 10;
        for (int i = 1; i <= over; i++) {
            ListenerEventLog.add(ListenerEvent.Kind.ATTRIBUTE, "SessionLifecycleListener",
                    "attributeAdded", "demo." + i + " が入りました");
        }

        List<ListenerEvent> events = ListenerEventLog.recent();
        assertEquals(ListenerEventLog.MAX_EVENTS, events.size());

        // 残っているのは新しい方
        assertEquals(over, events.get(0).getSeq());
        assertEquals(over - ListenerEventLog.MAX_EVENTS + 1, events.get(events.size() - 1).getSeq());
    }

    @Test
    @DisplayName("記録を消しても、起動時刻とセッション数は残る")
    void clearEventsKeepsCounters() {
        ListenerEventLog.sessionCreated();
        ListenerEventLog.add(ListenerEvent.Kind.SESSION, "SessionLifecycleListener",
                "sessionCreated", "セッションができました");

        ListenerEventLog.clearEvents();

        assertTrue(ListenerEventLog.recent().isEmpty());
        assertEquals(1, ListenerEventLog.getCreatedSessions());
        assertEquals(1, ListenerEventLog.getActiveSessions());
        assertNotNull(ListenerEventLog.getStartedAt());
        assertTrue(ListenerEventLog.getUptimeSeconds() >= 0);
    }

    @Test
    @DisplayName("生きているセッションの数は増減し、作られた数は増えるだけ")
    void countsSessions() {
        ListenerEventLog.sessionCreated();
        ListenerEventLog.sessionCreated();
        ListenerEventLog.sessionDestroyed();

        assertEquals(2, ListenerEventLog.getCreatedSessions());
        assertEquals(1, ListenerEventLog.getActiveSessions());

        // タイムアウトの取りこぼしなどで多く呼ばれても、負の数にはしない
        ListenerEventLog.sessionDestroyed();
        ListenerEventLog.sessionDestroyed();
        assertEquals(0, ListenerEventLog.getActiveSessions());
        assertEquals(2, ListenerEventLog.getCreatedSessions());
    }

    @Test
    @DisplayName("記録には時刻とクラス名が入る")
    void recordsTimeAndSource() {
        ListenerEvent event = ListenerEventLog.add(ListenerEvent.Kind.APPLICATION,
                "AppLifecycleListener", "contextInitialized", "起動しました");

        assertEquals(ListenerEvent.Kind.APPLICATION, event.getKind());
        assertEquals("アプリ", event.getKind().getLabel());
        assertEquals("AppLifecycleListener", event.getSource());
        assertNotNull(event.getAt());

        // 12:34:56.789 の形
        assertTrue(event.getTime().matches("\\d{2}:\\d{2}:\\d{2}\\.\\d{3}"),
                "時刻の書式が違います: " + event.getTime());
    }
}
