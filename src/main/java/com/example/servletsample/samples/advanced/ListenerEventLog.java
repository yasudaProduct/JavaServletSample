package com.example.servletsample.samples.advanced;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Deque;
import java.util.List;

/**
 * リスナーが捕まえた出来事を、直近の数件だけ預かっておく置き場。
 *
 * <p>リスナーは画面とは別のタイミングで呼ばれます
 * (アプリの起動時、セッションが切れたとき、など)。
 * そのため「呼ばれたこと」を画面に出すには、いったんどこかに書き留めておいて、
 * あとから画面が取りに来るしかありません。その置き場がこのクラスです。</p>
 *
 * <h2>アプリ全体で 1 つの入れ物を共有するということ</h2>
 * <p>{@code static} のフィールドはアプリ全体で 1 つなので、
 * <b>複数のリクエスト (スレッド) が同時に読み書きします</b>。
 * 出入り口のメソッドをすべて {@code synchronized} にしているのはそのためです。</p>
 *
 * <p>もう 1 つ大事なのが<b>上限</b>です。記録を消さずに貯め続けると、
 * アクセスがあるだけメモリを食い続け、いつかアプリが落ちます。
 * ここでは新しいものから {@value #MAX_EVENTS} 件だけを残し、古いものは捨てています。</p>
 *
 * <p>実際のアプリでこの役目を担うのはログです。画面に出しているのはサンプル都合で、
 * 「リスナーがいつ呼ばれたか」を目で見えるようにするためのものです。</p>
 */
public final class ListenerEventLog {

    /** 預かっておく件数の上限。 */
    static final int MAX_EVENTS = 40;

    /** 新しいものが先頭。古いものは末尾からあふれて消える。 */
    private static final Deque<ListenerEvent> EVENTS = new ArrayDeque<>();

    /** 通し番号。記録するたびに 1 つ増える。 */
    private static int sequence;

    /** アプリが起動した時刻 ({@link SampleContextListener} が設定する)。 */
    private static LocalDateTime startedAt;

    /** これまでに作られたセッションの数。 */
    private static int createdSessions;

    /** いま生きているセッションの数。 */
    private static int activeSessions;

    private ListenerEventLog() {
    }

    /** 出来事を 1 件書き留める。 */
    static synchronized ListenerEvent add(ListenerEvent.Kind kind, String source, String method,
            String message) {
        ListenerEvent event = new ListenerEvent(++sequence, LocalDateTime.now(), kind, source, method, message);
        EVENTS.addFirst(event);
        while (EVENTS.size() > MAX_EVENTS) {
            EVENTS.removeLast();   // 上限を超えたら、いちばん古いものから捨てる
        }
        return event;
    }

    /** 記録を新しい順に返す。 */
    public static synchronized List<ListenerEvent> recent() {
        return Collections.unmodifiableList(new ArrayList<>(EVENTS));
    }

    /** 記録だけを捨てる (画面の「記録を消す」ボタン用)。稼働時間やセッション数は残す。 */
    public static synchronized void clearEvents() {
        EVENTS.clear();
    }

    /** アプリの起動を記録する。 */
    static synchronized void markStarted(LocalDateTime at) {
        startedAt = at;
        EVENTS.clear();
        sequence = 0;
        createdSessions = 0;
        activeSessions = 0;
    }

    /** アプリが起動した時刻。まだ起動処理を通っていなければ {@code null}。 */
    public static synchronized LocalDateTime getStartedAt() {
        return startedAt;
    }

    /** 起動してからの経過時間 (秒)。起動時刻が分からなければ {@code -1}。 */
    public static synchronized long getUptimeSeconds() {
        return startedAt == null ? -1L : Duration.between(startedAt, LocalDateTime.now()).toSeconds();
    }

    /** セッションが 1 つ作られた。 */
    static synchronized void sessionCreated() {
        createdSessions++;
        activeSessions++;
    }

    /** セッションが 1 つ無くなった。 */
    static synchronized void sessionDestroyed() {
        activeSessions = Math.max(0, activeSessions - 1);
    }

    /** アプリが起動してから作られたセッションの数。 */
    public static synchronized int getCreatedSessions() {
        return createdSessions;
    }

    /**
     * いま生きているセッションの数。
     *
     * <p>ブラウザを閉じてもセッションはすぐには消えません。
     * 最後のアクセスから {@code web.xml} の {@code <session-timeout>} の時間が過ぎると、
     * コンテナがセッションを捨て、そのときに {@code sessionDestroyed} が呼ばれます。</p>
     */
    public static synchronized int getActiveSessions() {
        return activeSessions;
    }
}
