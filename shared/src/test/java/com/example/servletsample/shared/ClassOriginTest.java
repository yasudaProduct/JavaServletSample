package com.example.servletsample.shared;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@link ClassOrigin} のテスト。
 *
 * <p>読み込み元の URL は実行環境で変わるので、
 * <b>環境に依存しない部分だけ</b>を確かめています
 * (「WAR 同梱の JAR かどうか」は Tomcat に載せないと分からないため、
 * そちらは画面で確認する形にしてあります)。</p>
 */
class ClassOriginTest {

    @Test
    @DisplayName("クラス名を取得できる")
    void readsClassName() {
        ClassOrigin origin = ClassOrigin.of(CodeFormatter.class);
        assertEquals("com.example.servletsample.shared.CodeFormatter", origin.getClassName());
        assertEquals("CodeFormatter", origin.getSimpleName());
    }

    @Test
    @DisplayName("JDK のクラスは読み込み元が取れず、Tomcat / JDK 側と判定される")
    void jdkClassHasNoCodeSource() {
        ClassOrigin origin = ClassOrigin.of(String.class);
        // java.* はブートストラップクラスローダが読むため CodeSource を持たない
        assertEquals(ClassOrigin.Place.CONTAINER, origin.getPlace());
        assertEquals("(取得できません)", origin.getCodeSourceName());
        assertTrue(origin.getClassLoader().contains("ブートストラップ"));
    }

    @Test
    @DisplayName("自前のクラスは読み込み元とクラスローダが取れる")
    void ownClassHasCodeSource() {
        ClassOrigin origin = ClassOrigin.of(SequenceCounter.class);
        assertNotNull(origin.getCodeSource());
        assertNotNull(origin.getClassLoader());
        assertNotNull(origin.getPlace());
    }

    @Test
    @DisplayName("表示名は絶対パスをそのまま出さない")
    void shortensCodeSourceName() {
        ClassOrigin origin = ClassOrigin.of(SequenceCounter.class);
        String name = origin.getCodeSourceName();
        // サーバー上の絶対パスを画面に出さないよう、切り詰めている
        assertTrue(name.length() < origin.getCodeSource().length(),
                "表示名は元の URL より短くなるはず: " + name);
    }

    @Test
    @DisplayName("Place はラベルと説明を持つ")
    void placeHasLabels() {
        for (ClassOrigin.Place place : ClassOrigin.Place.values()) {
            assertNotNull(place.getLabel());
            assertNotNull(place.getDescription());
        }
    }
}
