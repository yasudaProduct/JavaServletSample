package com.example.servletsample.samples.shared;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.net.URL;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.example.servletsample.shared.SequenceCounter;

/**
 * {@link SimulatedServer} のテスト。
 *
 * <p>ここで確かめているのは、このサンプルがいちばん言いたいこと
 * <b>「クラスローダが違えば static も別」</b>そのものです。
 * 画面で見せている現象を、テストでも押さえておきます。</p>
 *
 * <p>2 台のサーバーを用意しなくてもテストできるのが、この方法の利点です。</p>
 */
class SimulatedServerTest {

    @Test
    @DisplayName("共通ライブラリの置き場所を取得できる")
    void findsSharedLocation() {
        assertNotNull(SimulatedServer.sharedJarLocation(),
                "共通ライブラリの CodeSource が取れません");
    }

    @Test
    @DisplayName("読み直したクラスは、アプリ側のものとは別のクラスになる")
    void loadsDistinctClass() throws Exception {
        URL location = SimulatedServer.sharedJarLocation();
        try (SimulatedServer server = SimulatedServer.of("サーバー B", location)) {
            assertFalse(server.isSameClassAsApp(),
                    "クラスローダを分けたのに同じ Class オブジェクトが返っています");
        }
    }

    @Test
    @DisplayName("2 台を模擬すると、それぞれが 1 から採番する（= 番号が重複する）")
    void countersAreIndependent() throws Exception {
        URL location = SimulatedServer.sharedJarLocation();
        try (SimulatedServer a = SimulatedServer.of("サーバー A", location);
             SimulatedServer b = SimulatedServer.of("サーバー B", location)) {

            assertEquals(1, a.next());
            assertEquals(2, a.next());
            assertEquals(3, a.next());

            // ここが事故の正体。同じ共通ライブラリなのに 1 に戻る
            assertEquals(1, b.next());

            assertEquals(3, a.current());
            assertEquals(1, b.current());
        }
    }

    @Test
    @DisplayName("模擬サーバーの採番は、アプリ側の static に影響しない")
    void doesNotTouchAppCounter() throws Exception {
        SequenceCounter.reset();
        URL location = SimulatedServer.sharedJarLocation();
        try (SimulatedServer server = SimulatedServer.of("サーバー B", location)) {
            server.next();
            server.next();
            assertEquals(0, SequenceCounter.current(), "アプリ側のカウンタまで動いています");
        }
    }

    @Test
    @DisplayName("模擬サーバーごとにクラスローダが違う")
    void hasOwnClassLoader() throws Exception {
        URL location = SimulatedServer.sharedJarLocation();
        try (SimulatedServer a = SimulatedServer.of("サーバー A", location);
             SimulatedServer b = SimulatedServer.of("サーバー B", location)) {
            assertNotEquals(a.getClassLoaderName(), b.getClassLoaderName());
        }
    }

    @Test
    @DisplayName("reset で 0 に戻る")
    void resets() throws Exception {
        URL location = SimulatedServer.sharedJarLocation();
        try (SimulatedServer server = SimulatedServer.of("サーバー B", location)) {
            server.next();
            server.reset();
            assertEquals(0, server.current());
        }
    }
}
