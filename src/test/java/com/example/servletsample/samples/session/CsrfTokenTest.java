package com.example.servletsample.samples.session;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.NullAndEmptySource;

/**
 * CSRF トークンの照合 ({@link CsrfToken#tokensMatch(String, String)}) のテスト。
 *
 * <p>いちばん確かめたいのは<b>「空なら不一致」</b>です。
 * 「トークンが無ければチェックしない」と書いてしまうと、
 * 罠のページから送られた（当然トークンが無い）リクエストが素通りします。
 * 対策を入れたつもりで何も守れていない、という事故が起きるところです。</p>
 */
class CsrfTokenTest {

    private static final String TOKEN = "xY9kfQ2mZ8pL3vN6bR1tW4cH7sJ0dG5a";

    @Test
    @DisplayName("同じ値なら一致する")
    void matchesSameToken() {
        assertTrue(CsrfToken.tokensMatch(TOKEN, TOKEN));
        // 別のインスタンスでも一致する (== ではなく中身で比べている)
        assertTrue(CsrfToken.tokensMatch(TOKEN, new String(TOKEN.toCharArray())));
    }

    @ParameterizedTest
    @CsvSource({
            "xY9kfQ2mZ8pL3vN6bR1tW4cH7sJ0dG5a, xY9kfQ2mZ8pL3vN6bR1tW4cH7sJ0dG5b",
            "xY9kfQ2mZ8pL3vN6bR1tW4cH7sJ0dG5a, XY9kfQ2mZ8pL3vN6bR1tW4cH7sJ0dG5a",
            "xY9kfQ2mZ8pL3vN6bR1tW4cH7sJ0dG5a, xY9kfQ2mZ8pL3vN6bR1tW4cH7sJ0dG5",
            "xY9kfQ2mZ8pL3vN6bR1tW4cH7sJ0dG5a, xY9kfQ2mZ8pL3vN6bR1tW4cH7sJ0dG5aa"
    })
    @DisplayName("1 文字でも違えば一致しない (長さ違いも含む)")
    void rejectsDifferentToken(String expected, String actual) {
        assertFalse(CsrfToken.tokensMatch(expected, actual));
    }

    @Test
    @DisplayName("先頭だけ合っていても一致しない")
    void rejectsPrefix() {
        assertFalse(CsrfToken.tokensMatch(TOKEN, TOKEN.substring(0, 8)));
    }

    @ParameterizedTest
    @NullAndEmptySource
    @DisplayName("送られてきた値が空なら一致しない (ここを素通しにすると対策の意味がない)")
    void rejectsBlankActual(String actual) {
        assertFalse(CsrfToken.tokensMatch(TOKEN, actual));
    }

    @ParameterizedTest
    @NullAndEmptySource
    @DisplayName("セッション側の値が空でも一致しない (セッション切れで素通しにしない)")
    void rejectsBlankExpected(String expected) {
        assertFalse(CsrfToken.tokensMatch(expected, TOKEN));
    }

    @Test
    @DisplayName("両方とも空でも一致しない")
    void rejectsBothBlank() {
        assertFalse(CsrfToken.tokensMatch("", ""));
        assertFalse(CsrfToken.tokensMatch(null, null));
    }
}
