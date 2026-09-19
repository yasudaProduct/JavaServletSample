package com.example.servletsample.samples.ajax;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * 非同期通信の基本で使う JSON API ({@link AjaxBasicsApiServlet}) のテスト。
 *
 * <p>Servlet コンテナは起動しません。Servlet も「ただの Java のクラス」なので、
 * {@code new} してメソッドを直接呼べば、検証と JSON の組み立てだけを取り出して確かめられます。</p>
 *
 * <p>とくに {@code delay} の検証は<b>外から来た文字列をそのまま信用しない</b>ための処理なので、
 * 「数字でない」「負の数」「大きすぎる」といった素直でない入力を並べて確かめています。</p>
 */
class AjaxBasicsApiServletTest {

    /** {@code payload} に渡すサーバ情報 (テストでは固定値でよい)。 */
    private static final String SERVER_INFO = "Test Server/1.0";

    // ------------------------------------------------------------------
    // delay の検証
    // ------------------------------------------------------------------

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"   "})
    @DisplayName("delay が未指定・空・空白だけなら待たない (0)")
    void blankDelayMeansNoWait(String raw) {
        assertEquals(0L, AjaxBasicsApiServlet.parseDelayMillis(raw));
    }

    @ParameterizedTest
    @CsvSource({
            "0,     0",
            "1,     1",
            "1500,  1500",
            "2000,  2000"
    })
    @DisplayName("0 から上限までの値はそのまま使われる")
    void delayInRangeIsUsedAsIs(String raw, long expected) {
        assertEquals(expected, AjaxBasicsApiServlet.parseDelayMillis(raw));
    }

    @ParameterizedTest
    @ValueSource(strings = {"2001", "60000", "600000", "9223372036854775807"})
    @DisplayName("上限を超える値は上限に丸められる (スレッドを長時間占有させないため)")
    void tooLargeDelayIsClamped(String raw) {
        assertEquals(AjaxBasicsApiServlet.MAX_DELAY_MILLIS, AjaxBasicsApiServlet.parseDelayMillis(raw));
    }

    @ParameterizedTest
    @ValueSource(strings = {"-1", "-1500", "-9999999"})
    @DisplayName("負の値は 0 として扱う (Thread.sleep に渡すと例外になる)")
    void negativeDelayBecomesZero(String raw) {
        assertEquals(0L, AjaxBasicsApiServlet.parseDelayMillis(raw));
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "abc",                      // 数字でない
            "1500ms",                   // 単位つき
            "1,500",                    // 桁区切り
            "1.5",                      // 小数
            "99999999999999999999999"   // long に収まらない
    })
    @DisplayName("数値として読めない値は、例外を外に出さずに 0 として扱う")
    void unparsableDelayBecomesZero(String raw) {
        assertEquals(0L, AjaxBasicsApiServlet.parseDelayMillis(raw));
    }

    @Test
    @DisplayName("前後に空白があっても数値として読める")
    void surroundingSpacesAreIgnored() {
        assertEquals(800L, AjaxBasicsApiServlet.parseDelayMillis("  800  "));
    }

    // ------------------------------------------------------------------
    // 返す JSON
    // ------------------------------------------------------------------

    @Test
    @DisplayName("正常時の JSON に、画面が使う項目がすべて入っている")
    void payloadContainsEveryFieldTheScreenUses() {
        String json = new AjaxBasicsApiServlet().payload(1500L, 3L, SERVER_INFO).toString();

        assertTrue(json.contains("\"ok\":true"), json);
        assertTrue(json.contains("\"serverTime\":\""), json);
        assertTrue(json.contains("\"serverInfo\":\"Test Server/1.0\""), json);
        assertTrue(json.contains("\"javaVersion\":\""), json);
        assertTrue(json.contains("\"sampleCount\":"), json);
        assertTrue(json.contains("\"delayMillis\":1500"), json);
        assertTrue(json.contains("\"requestCount\":3"), json);
        assertTrue(json.contains("\"thread\":\""), json);
    }

    @Test
    @DisplayName("数値の項目は文字列ではなく数値として書き出される")
    void numbersAreWrittenAsNumbers() {
        String json = new AjaxBasicsApiServlet().payload(0L, 1L, SERVER_INFO).toString();

        // "delayMillis":"0" のように引用符が付くと、画面側で計算に使えなくなる
        assertFalse(json.contains("\"delayMillis\":\""), json);
        assertFalse(json.contains("\"requestCount\":\""), json);
        assertFalse(json.contains("\"sampleCount\":\""), json);
    }

    @Test
    @DisplayName("サーバ情報に引用符が含まれていても、壊れない JSON になる")
    void quotesInValuesAreEscaped() {
        String json = new AjaxBasicsApiServlet()
                .payload(0L, 1L, "Weird \"Server\"").toString();

        // エスケープせずに埋め込むと、ここで JSON の文字列が閉じてしまう
        assertTrue(json.contains("\"serverInfo\":\"Weird \\\"Server\\\"\""), json);
    }

    @Test
    @DisplayName("失敗時の JSON は ok が false で、ステータスと説明が入っている")
    void errorPayloadTellsWhatHappened() {
        String json = new AjaxBasicsApiServlet().errorPayload(0L, 7L).toString();

        assertTrue(json.contains("\"ok\":false"), json);
        assertTrue(json.contains("\"status\":500"), json);
        assertTrue(json.contains("\"message\":\""), json);
        assertTrue(json.contains("\"requestCount\":7"), json);
    }

    @Test
    @DisplayName("公開中のサンプル件数は 1 件以上が返る")
    void sampleCountIsTakenFromTheCatalog() {
        String json = new AjaxBasicsApiServlet().payload(0L, 1L, SERVER_INFO).toString();

        assertFalse(json.contains("\"sampleCount\":0"),
                "カタログから件数を取れていない可能性があります: " + json);
    }
}
