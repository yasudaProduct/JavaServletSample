package com.example.servletsample.samples.ajax;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpSession;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * 進捗のポーリングで使う JSON API ({@link AjaxPollingApiServlet}) のテスト。
 *
 * <p>Servlet コンテナは起動しません。進捗の計算と JSON の組み立ては
 * 「いまの時刻」を引数で受け取る形にしてあるので、
 * <b>時間を止めた状態で</b>確かめられます
 * ({@code Thread.sleep} で待つテストは、遅いだけでなく、まれに落ちます)。</p>
 */
class AjaxPollingApiServletTest {

    /** 開始時刻。値そのものに意味はないので、読みやすい固定値にしています。 */
    private static final long START = 1_700_000_000_000L;

    // ------------------------------------------------------------------
    // 進捗の計算
    // ------------------------------------------------------------------

    @ParameterizedTest
    @CsvSource({
            "0,       0",
            "40,      0",     // 1% に満たない間は 0 のまま
            "2000,   25",
            "3000,   37",     // 37.5% は切り捨てて 37
            "4000,   50",
            "7999,   99"
    })
    @DisplayName("経過時間に応じて 0 から 99 まで進む")
    void percentGrowsWithElapsedTime(long elapsedMillis, int expected) {
        assertEquals(expected, AjaxPollingApiServlet.percentOf(elapsedMillis));
    }

    @ParameterizedTest
    @ValueSource(longs = {8000L, 8001L, 60_000L, 86_400_000L})
    @DisplayName("かかる時間を過ぎたら 100 で頭打ちになる")
    void percentStopsAtHundred(long elapsedMillis) {
        assertEquals(100, AjaxPollingApiServlet.percentOf(elapsedMillis));
    }

    @ParameterizedTest
    @ValueSource(longs = {-1L, -5000L, -86_400_000L})
    @DisplayName("経過時間が負でも 0 になる（時計がずれても進捗バーが壊れない）")
    void negativeElapsedTimeIsZero(long elapsedMillis) {
        assertEquals(0, AjaxPollingApiServlet.percentOf(elapsedMillis));
    }

    @ParameterizedTest
    @CsvSource({
            "-1000,  0",
            "0,      0",
            "999,    0",
            "1000,   1",
            "3500,   3",
            "62000, 62"     // 経過秒数は頭打ちにしない（開き直したときに実際の値を出すため）
    })
    @DisplayName("経過秒数は切り捨てで、上限を設けない")
    void elapsedSecondsAreTruncated(long elapsedMillis, int expected) {
        assertEquals(expected, AjaxPollingApiServlet.elapsedSecondsOf(elapsedMillis));
    }

    // ------------------------------------------------------------------
    // 進捗に添えるメッセージ
    // ------------------------------------------------------------------

    @ParameterizedTest
    @ValueSource(ints = {0, 1, 24})
    @DisplayName("始まったばかりのときは準備中のメッセージを返す")
    void messageForTheBeginning(int percent) {
        assertEquals("対象データを数えています...", AjaxPollingApiServlet.messageOf(percent));
    }

    @ParameterizedTest
    @CsvSource({
            "25,  明細データを読み込んでいます...",
            "49,  明細データを読み込んでいます...",
            "50,  カテゴリごとに合計しています...",
            "74,  カテゴリごとに合計しています...",
            "75,  レポートを組み立てています...",
            "99,  レポートを組み立てています...",
            "100, 集計が完了しました。"
    })
    @DisplayName("進捗の段階ごとにメッセージが変わる")
    void messageChangesByStage(int percent, String expected) {
        assertEquals(expected, AjaxPollingApiServlet.messageOf(percent));
    }

    // ------------------------------------------------------------------
    // 完了したときの結果
    // ------------------------------------------------------------------

    @Test
    @DisplayName("結果の件数は開始時刻から決まる（何度問い合わせても変わらない）")
    void resultCountIsStable() {
        int first = AjaxPollingApiServlet.resultCountOf(START);
        int second = AjaxPollingApiServlet.resultCountOf(START);

        // 問い合わせのたびに変わると、完了後に件数が揺れる画面になってしまう
        assertEquals(first, second);
    }

    @ParameterizedTest
    @ValueSource(longs = {0L, START, START + 1234L, START + 999_999L, -START})
    @DisplayName("結果の件数はいつでも 1200 〜 1999 件に収まる")
    void resultCountStaysInRange(long startedAtMillis) {
        int count = AjaxPollingApiServlet.resultCountOf(startedAtMillis);

        // Math.floorMod を使っているので、開始時刻が負でも負の件数にならない
        assertTrue(count >= 1200 && count <= 1999, "範囲外です: " + count);
    }

    // ------------------------------------------------------------------
    // 返す JSON
    // ------------------------------------------------------------------

    @Test
    @DisplayName("集計が無いときは idle を返し、結果は null のままにする")
    void payloadWithoutJob() {
        String json = AjaxPollingApiServlet.statusPayload(null, START, 0L).toString();

        assertTrue(json.contains("\"state\":\"idle\""), json);
        assertTrue(json.contains("\"running\":false"), json);
        assertTrue(json.contains("\"done\":false"), json);
        assertTrue(json.contains("\"percent\":0"), json);
        assertTrue(json.contains("\"startedAt\":null"), json);
        assertTrue(json.contains("\"resultCount\":null"), json);
    }

    @Test
    @DisplayName("実行中は running が true で、結果はまだ入っていない")
    void payloadWhileRunning() {
        String json = AjaxPollingApiServlet
                .statusPayload(job(), START + 3000L, 4L).toString();

        assertTrue(json.contains("\"state\":\"running\""), json);
        assertTrue(json.contains("\"running\":true"), json);
        assertTrue(json.contains("\"done\":false"), json);
        assertTrue(json.contains("\"percent\":37"), json);
        assertTrue(json.contains("\"elapsedSeconds\":3"), json);
        assertTrue(json.contains("\"serverPollCount\":4"), json);

        // 未完了のときに 0 を入れると、画面が「0 件で完了」と表示してしまう
        assertTrue(json.contains("\"resultCount\":null"), json);
    }

    @Test
    @DisplayName("完了すると running が false になり、件数が入る")
    void payloadWhenDone() {
        String json = AjaxPollingApiServlet
                .statusPayload(job(), START + 8000L, 9L).toString();

        assertTrue(json.contains("\"state\":\"done\""), json);
        // 画面はこれが false になった時点で問い合わせを止める
        assertTrue(json.contains("\"running\":false"), json);
        assertTrue(json.contains("\"done\":true"), json);
        assertTrue(json.contains("\"percent\":100"), json);
        assertTrue(json.contains("\"message\":\"集計が完了しました。\""), json);
        assertTrue(json.contains("\"resultCount\":" + AjaxPollingApiServlet.resultCountOf(START)), json);
    }

    @Test
    @DisplayName("画面が使う項目が、どの状態でも同じだけ入っている")
    void payloadHasTheSameShapeInEveryState() {
        String[] names = {"ok", "problem", "state", "running", "done", "percent",
                "elapsedSeconds", "totalSeconds", "message", "startedAt",
                "resultCount", "serverPollCount"};

        String idle = AjaxPollingApiServlet.statusPayload(null, START, 0L).toString();
        String running = AjaxPollingApiServlet.statusPayload(job(), START + 1000L, 1L).toString();
        String done = AjaxPollingApiServlet.statusPayload(job(), START + 9000L, 9L).toString();

        for (String name : names) {
            // 状態によって項目が消える JSON は、受け取る側が if だらけになる
            assertTrue(idle.contains("\"" + name + "\":"), name + " がありません: " + idle);
            assertTrue(running.contains("\"" + name + "\":"), name + " がありません: " + running);
            assertTrue(done.contains("\"" + name + "\":"), name + " がありません: " + done);
        }
    }

    @Test
    @DisplayName("数値の項目は文字列ではなく数値として書き出される")
    void numbersAreWrittenAsNumbers() {
        String json = AjaxPollingApiServlet.statusPayload(job(), START + 2000L, 3L).toString();

        // "percent":"25" のように引用符が付くと、画面側で幅の計算に使えなくなる
        assertFalse(json.contains("\"percent\":\""), json);
        assertFalse(json.contains("\"elapsedSeconds\":\""), json);
        assertFalse(json.contains("\"serverPollCount\":\""), json);
    }

    @Test
    @DisplayName("断ったときは ok が false になり、理由が入る")
    void payloadCanCarryTheReasonForRefusal() {
        String json = AjaxPollingApiServlet
                .statusPayload(job(), START + 1000L, 2L, false, "すでに実行中です。").toString();

        assertTrue(json.contains("\"ok\":false"), json);
        assertTrue(json.contains("\"problem\":\"すでに実行中です。\""), json);

        // 断られても進捗そのものは返す（画面は走っている集計を表示し続けられる）
        assertTrue(json.contains("\"running\":true"), json);
    }

    @Test
    @DisplayName("受け付けたときは problem が null になる")
    void acceptedPayloadHasNoProblem() {
        String json = AjaxPollingApiServlet.statusPayload(job(), START, 1L).toString();

        assertTrue(json.contains("\"ok\":true"), json);
        assertTrue(json.contains("\"problem\":null"), json);
    }

    // ------------------------------------------------------------------
    // セッションから状態を取り出すところ
    // ------------------------------------------------------------------

    @Test
    @DisplayName("セッションがまだ無ければ、集計も回数も無いものとして扱う")
    void handlesMissingSession() {
        // 画面を表示する Servlet は getSession(false) を使うので、null が渡ってくる
        assertNull(AjaxPollingApiServlet.findJob(null));
        assertEquals(0L, AjaxPollingApiServlet.pollCount(null));
    }

    @Test
    @DisplayName("セッションに入れた集計を取り出せる")
    void findsJobInSession() {
        FakeSession session = new FakeSession();
        session.values.put(AjaxPollingApiServlet.JOB_KEY, job());

        AjaxPollingApiServlet.Job found = AjaxPollingApiServlet.findJob(session.session);

        assertNotNull(found);
        assertEquals(START, found.getStartedAtMillis());
        assertEquals("12:34:56", found.getStartedAtText());
    }

    @Test
    @DisplayName("別の型の値が入っていても例外にしない（古いセッションが残っている場合）")
    void ignoresUnexpectedValue() {
        FakeSession session = new FakeSession();
        session.values.put(AjaxPollingApiServlet.JOB_KEY, "これは Job ではない");

        // いきなりキャストすると ClassCastException になる場面
        assertNull(AjaxPollingApiServlet.findJob(session.session));
    }

    @Test
    @DisplayName("実行中の集計だけが二重開始を断る対象になる")
    void onlyRunningJobBlocksTheNextStart() {
        FakeSession session = new FakeSession();
        session.values.put(AjaxPollingApiServlet.JOB_KEY, job());

        // 途中なので、新しく開始させてはいけない
        assertNotNull(AjaxPollingApiServlet.runningJob(session.session, START + 3000L));

        // 完了済みなら、次の集計を開始してよい
        assertNull(AjaxPollingApiServlet.runningJob(session.session, START + 8000L));
    }

    @Test
    @DisplayName("問い合わせ回数は、入っていなければ 0 から数える")
    void pollCountStartsAtZero() {
        FakeSession session = new FakeSession();
        assertEquals(0L, AjaxPollingApiServlet.pollCount(session.session));

        session.values.put(AjaxPollingApiServlet.POLL_COUNT_KEY, 12L);
        assertEquals(12L, AjaxPollingApiServlet.pollCount(session.session));
    }

    // ------------------------------------------------------------------
    // テスト用の部品
    // ------------------------------------------------------------------

    /** 開始時刻を {@link #START} に固定した集計。 */
    private static AjaxPollingApiServlet.Job job() {
        return new AjaxPollingApiServlet.Job(START, "12:34:56");
    }

    /**
     * テスト用の最小限の {@link HttpSession}。
     *
     * <p>モックのライブラリを足さずに済ませるため、動的プロキシで
     * 属性の出し入れだけを実装しています。</p>
     */
    private static final class FakeSession {

        private final Map<String, Object> values = new HashMap<>();
        private final HttpSession session;

        FakeSession() {
            this.session = proxy(HttpSession.class, (target, method, args) -> {
                switch (method.getName()) {
                    case "setAttribute":
                        values.put((String) args[0], args[1]);
                        return null;
                    case "getAttribute":
                        return values.get((String) args[0]);
                    case "removeAttribute":
                        values.remove((String) args[0]);
                        return null;
                    default:
                        return null;
                }
            });
        }

        @SuppressWarnings("unchecked")
        private static <T> T proxy(Class<T> type, InvocationHandler handler) {
            return (T) Proxy.newProxyInstance(AjaxPollingApiServletTest.class.getClassLoader(),
                    new Class<?>[]{type}, handler);
        }
    }
}
