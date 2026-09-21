package com.example.servletsample.samples.advanced;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 記録に書いてよいものだけを書いているか確かめるテスト。
 *
 * <p>このリスナーはアプリ全体に掛かるため、ログイン情報や CSRF トークンの出し入れも通ります。
 * セッション ID と値の中身が記録に残らないことは、動きの確認ではなく<b>約束ごと</b>です。</p>
 */
class SessionLifecycleListenerTest {

    @Test
    @DisplayName("セッション ID は先頭だけしか残さない")
    void masksSessionId() {
        String id = "4FE1B0C2D3A4E5F60718293A4B5C6D7E";

        String masked = SessionLifecycleListener.mask(id);

        assertEquals("4FE1B0…", masked);
        assertFalse(id.startsWith(masked), "ID がそのまま残っています: " + masked);
    }

    @Test
    @DisplayName("短い ID や null は伏せ字だけにする")
    void masksShortId() {
        assertEquals("******", SessionLifecycleListener.mask(null));
        assertEquals("******", SessionLifecycleListener.mask("abc"));
        assertEquals("******", SessionLifecycleListener.mask("123456"));
    }

    @Test
    @DisplayName("値は型だけを記録し、中身は残さない")
    void recordsTypeOnly() {
        assertEquals(" (String)", SessionLifecycleListener.typeOf("p@ssw0rd"));
        assertEquals(" (Integer)", SessionLifecycleListener.typeOf(1));
        assertEquals("", SessionLifecycleListener.typeOf(null));
    }
}
