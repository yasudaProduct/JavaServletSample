package com.example.servletsample.samples.advanced;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * エラー処理のサンプル ({@link ErrorHandlingServlet}) のテスト。
 *
 * <p>Servlet コンテナは起動しません。判定の部分だけを取り出して確かめています。</p>
 *
 * <p>このサンプルの要点は「どのエラーを例外にして、どれを例外にしないか」です。
 * テストもその区別どおりに分けてあります。</p>
 */
class ErrorHandlingServletTest {

    // ------------------------------------------------------------------
    // 入力の誤り : 例外にしない
    // ------------------------------------------------------------------

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"   ", "　"})
    @DisplayName("未入力・空白だけなら null (例外にはしない)")
    void blankQuantityIsNull(String raw) {
        assertNull(ErrorHandlingServlet.toQuantity(raw));
    }

    @ParameterizedTest
    @ValueSource(strings = {"abc", "3個", "3.5", "99999999999999999999"})
    @DisplayName("数値として読めない入力は null (例外を外へ出さない)")
    void invalidQuantityIsNull(String raw) {
        assertNull(ErrorHandlingServlet.toQuantity(raw));
    }

    @ParameterizedTest
    @ValueSource(strings = {"１２", "３"})
    @DisplayName("全角数字は通さない (Integer.parseInt を直に呼ぶと通ってしまう)")
    void fullWidthDigitsAreRejected(String raw) {
        assertNull(ErrorHandlingServlet.toQuantity(raw));
    }

    @ParameterizedTest
    @ValueSource(strings = {"3", " 3 ", "0", "-1"})
    @DisplayName("数値として読める入力はそのまま数値になる (良し悪しの判断はしない)")
    void validQuantityIsParsed(String raw) {
        Integer parsed = ErrorHandlingServlet.toQuantity(raw);
        assertEquals(Integer.valueOf(raw.strip()), parsed);
    }

    // ------------------------------------------------------------------
    // 業務上の都合 : 業務例外を投げる
    // ------------------------------------------------------------------

    @ParameterizedTest
    @ValueSource(ints = {1, 5, ErrorHandlingServlet.STOCK})
    @DisplayName("在庫の範囲内なら出庫できる")
    void shipsWithinStock(int quantity) {
        assertDoesNotThrow(() -> ErrorHandlingServlet.ship(quantity));
    }

    @Test
    @DisplayName("在庫を超えたら業務例外になる (エラーコード付き)")
    void shippingOverStockThrowsApplicationException() {
        ApplicationException thrown = assertThrows(ApplicationException.class,
                () -> ErrorHandlingServlet.ship(ErrorHandlingServlet.STOCK + 1));

        assertEquals("E-1001", thrown.getCode());
        // 画面にそのまま出すメッセージなので、利用者に分かる言葉になっていること
        assertTrue(thrown.getMessage().contains("在庫が足りません"), thrown.getMessage());
    }

    @Test
    @DisplayName("業務例外は原因つきでも作れる (元の例外を失わない)")
    void keepsCause() {
        Exception cause = new IllegalStateException("元の例外");
        ApplicationException thrown = new ApplicationException("E-9001", "失敗しました", cause);

        assertEquals(cause, thrown.getCause());
        assertEquals("E-9001", thrown.getCode());
    }
}
