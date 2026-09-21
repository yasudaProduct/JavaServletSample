package com.example.servletsample.samples.advanced;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * アクセスログのフィルタ ({@link AccessLogFilter}) の初期化パラメータの読み取りテスト。
 *
 * <p>{@code web.xml} に書いた値は文字列として渡ってきます。
 * 設定ファイルの書き間違いでアプリが起動しなくなることのないよう、
 * 読めない値は既定値に倒す作りにしています。</p>
 */
class AccessLogFilterTest {

    private static final long DEFAULT = AccessLogFilter.DEFAULT_SLOW_MILLIS;

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"   "})
    @DisplayName("init-param を書かなければ既定値が使われる")
    void missingParameterFallsBackToDefault(String raw) {
        assertEquals(DEFAULT, AccessLogFilter.parseMillis(raw, DEFAULT));
    }

    @ParameterizedTest
    @CsvSource({
            "1,     1",
            "500,   500",
            " 800 , 800",
            "60000, 60000"
    })
    @DisplayName("正の数はそのまま使われる")
    void positiveValueIsUsedAsIs(String raw, long expected) {
        assertEquals(expected, AccessLogFilter.parseMillis(raw, DEFAULT));
    }

    @ParameterizedTest
    @ValueSource(strings = {"abc", "1,000", "1.5", "0", "-1", "99999999999999999999"})
    @DisplayName("読めない値・0 以下は既定値に倒す (設定ミスで起動できなくならないように)")
    void invalidValueFallsBackToDefault(String raw) {
        assertEquals(DEFAULT, AccessLogFilter.parseMillis(raw, DEFAULT));
    }
}
