package com.example.servletsample.samples.advanced;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * セッションに入れる値の入力チェック ({@link ListenerServlet#validate}) のテスト。
 */
class ListenerServletTest {

    @Test
    @DisplayName("半角英数字の名前と値なら受け付ける")
    void acceptsValidInput() {
        assertNull(ListenerServlet.validate("color", "blue"));
        assertNull(ListenerServlet.validate("a", "あ"));
    }

    @Test
    @DisplayName("名前が未入力・全角・長すぎるときは断る")
    void rejectsInvalidName() {
        assertNotNull(ListenerServlet.validate("", "blue"));
        assertNotNull(ListenerServlet.validate("　", "blue"));   // 全角スペースだけ
        assertNotNull(ListenerServlet.validate("いろ", "blue"));
        assertNotNull(ListenerServlet.validate("color!", "blue"));
        assertNotNull(ListenerServlet.validate("a".repeat(ListenerServlet.MAX_NAME_LENGTH + 1), "blue"));
    }

    @Test
    @DisplayName("値が未入力・長すぎるときは断る")
    void rejectsInvalidValue() {
        assertNotNull(ListenerServlet.validate("color", ""));
        assertNotNull(ListenerServlet.validate("color",
                "a".repeat(ListenerServlet.MAX_VALUE_LENGTH + 1)));
    }

    @Test
    @DisplayName("上限ちょうどは受け付ける")
    void acceptsBoundary() {
        assertNull(ListenerServlet.validate(
                "a".repeat(ListenerServlet.MAX_NAME_LENGTH),
                "b".repeat(ListenerServlet.MAX_VALUE_LENGTH)));
    }

    @Test
    @DisplayName("メッセージは画面にそのまま出せる文言になっている")
    void messageIsReadable() {
        String message = ListenerServlet.validate("", "blue");
        assertNotNull(message);
        assertTrue(message.endsWith("。"), "メッセージが文になっていません: " + message);
    }
}
