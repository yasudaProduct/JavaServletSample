package com.example.servletsample.samples.advanced;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 非同期サンプルの API ({@link AsyncApiServlet}) が受け取る値のテスト。
 *
 * <p>外から来る値は「数字とは限らない」「とんでもない大きさかもしれない」前提で扱います。
 * 待ち時間をそのまま信じると、1 本のリクエストでスレッドを何分も占有されてしまいます。</p>
 */
class AsyncApiServletTest {

    @Test
    @DisplayName("mode=async のときだけ非同期にする")
    void detectsAsyncMode() {
        assertTrue(AsyncApiServlet.isAsync("async"));
        assertTrue(AsyncApiServlet.isAsync(" ASYNC "));
        assertFalse(AsyncApiServlet.isAsync("sync"));
        assertFalse(AsyncApiServlet.isAsync(""));
        assertFalse(AsyncApiServlet.isAsync(null));
    }

    @Test
    @DisplayName("待ち時間は既定値と上限に丸める")
    void clampsWorkMillis() {
        assertEquals(AsyncApiServlet.DEFAULT_WORK_MILLIS, AsyncApiServlet.workMillis(null));
        assertEquals(AsyncApiServlet.DEFAULT_WORK_MILLIS, AsyncApiServlet.workMillis(""));
        assertEquals(AsyncApiServlet.DEFAULT_WORK_MILLIS, AsyncApiServlet.workMillis("すぐに"));

        assertEquals(1500, AsyncApiServlet.workMillis("1500"));
        assertEquals(0, AsyncApiServlet.workMillis("-1"));
        assertEquals(AsyncApiServlet.MAX_WORK_MILLIS, AsyncApiServlet.workMillis("600000"));

        // 桁あふれもそのまま通さない (Validators.toInt が空を返すので既定値になる)
        assertEquals(AsyncApiServlet.DEFAULT_WORK_MILLIS, AsyncApiServlet.workMillis("99999999999"));
    }

    @Test
    @DisplayName("制限時間は指定が無ければ 0 (無制限)")
    void clampsTimeoutMillis() {
        assertEquals(0L, AsyncApiServlet.timeoutMillis(null));
        assertEquals(0L, AsyncApiServlet.timeoutMillis("0"));
        assertEquals(1500L, AsyncApiServlet.timeoutMillis("1500"));
        assertEquals(AsyncApiServlet.MAX_TIMEOUT_MILLIS, AsyncApiServlet.timeoutMillis("120000"));
    }

    @Test
    @DisplayName("見出しは長すぎるものを切り詰める")
    void trimsLabel() {
        assertEquals("", AsyncApiServlet.label(null));
        assertEquals("非同期 1 本", AsyncApiServlet.label(" 非同期 1 本 "));
        assertEquals(AsyncApiServlet.MAX_LABEL_LENGTH,
                AsyncApiServlet.label("あ".repeat(50)).length());
    }

    @Test
    @DisplayName("応答の JSON には、どのスレッドが何をしたかが入る")
    void buildsResultJson() {
        String json = AsyncApiServlet.result("async", "非同期 1 本", 2000,
                "http-nio-8080-exec-5", "async-worker-1", 3L, 2004L, "終わりました").toString();

        assertTrue(json.contains("\"mode\":\"async\""), json);
        assertTrue(json.contains("\"servletThread\":\"http-nio-8080-exec-5\""), json);
        assertTrue(json.contains("\"workerThread\":\"async-worker-1\""), json);
        assertTrue(json.contains("\"waitedMillis\":3"), json);
        assertTrue(json.contains("\"totalMillis\":2004"), json);
        assertTrue(json.contains("\"timedOut\":false"), json);
        assertTrue(json.contains("\"ok\":true"), json);
    }
}
