package com.example.servletsample.samples.session;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * パスワードのハッシュ化 ({@link PasswordHash}) のテスト。
 *
 * <p>確かめたいのは次の 3 点です。</p>
 * <ul>
 *   <li>同じパスワードでも毎回違う値になる (ソルトが効いている)</li>
 *   <li>正しいパスワードだけが通る</li>
 *   <li>保存値が壊れていても例外を外へ出さない (ログイン画面で落ちない)</li>
 * </ul>
 */
class PasswordHashTest {

    private static final String RAW = "password1";

    @Test
    @DisplayName("同じパスワードでも、作るたびに違う値になる (ソルト)")
    void producesDifferentHashForSamePassword() {
        String first = PasswordHash.hash(RAW);
        String second = PasswordHash.hash(RAW);

        assertNotEquals(first, second, "ソルトが効いていません");
        // それでも、どちらも元のパスワードで照合できる
        assertTrue(PasswordHash.matches(RAW, first));
        assertTrue(PasswordHash.matches(RAW, second));
    }

    @Test
    @DisplayName("保存値にパスワードそのものは含まれない")
    void storedValueDoesNotContainRawPassword() {
        String stored = PasswordHash.hash(RAW);
        assertFalse(stored.contains(RAW), "保存値に平文が混ざっています: " + stored);
    }

    @Test
    @DisplayName("保存値には方式と反復回数が入っている (あとから設定を変えられるように)")
    void storedValueCarriesSchemeAndIterations() {
        String[] parts = PasswordHash.hash(RAW).split("\\$");

        assertEquals(4, parts.length, "方式 / 反復回数 / ソルト / ハッシュ の 4 つ");
        assertEquals("pbkdf2", parts[0]);
        assertTrue(Integer.parseInt(parts[1]) >= 10_000, "反復回数が少なすぎます");
    }

    @ParameterizedTest
    @ValueSource(strings = {"password2", "Password1", "password1 ", "", "passwor"})
    @DisplayName("違うパスワードでは通らない (大文字小文字・前後の空白も区別する)")
    void rejectsWrongPassword(String wrong) {
        String stored = PasswordHash.hash(RAW);
        assertFalse(PasswordHash.matches(wrong, stored));
    }

    @Test
    @DisplayName("正しいパスワードなら通る")
    void acceptsCorrectPassword() {
        assertTrue(PasswordHash.matches(RAW, PasswordHash.hash(RAW)));
    }

    @ParameterizedTest
    @NullSource
    @ValueSource(strings = {"", "pbkdf2", "pbkdf2$1$2", "sha256$1000$c2FsdA==$aGFzaA==",
            "pbkdf2$abc$c2FsdA==$aGFzaA==", "pbkdf2$1000$***$***"})
    @DisplayName("保存値が壊れていても例外にせず、認証は失敗にする")
    void brokenStoredValueFailsWithoutException(String stored) {
        assertFalse(PasswordHash.matches(RAW, stored));
    }

    @Test
    @DisplayName("パスワードが null でも落ちない")
    void nullPasswordFails() {
        assertFalse(PasswordHash.matches(null, PasswordHash.hash(RAW)));
    }

    @Test
    @DisplayName("概要にはハッシュの全体は出さない")
    void describeHidesFullDigest() {
        String stored = PasswordHash.hash(RAW);
        String summary = PasswordHash.describe(stored);

        assertTrue(summary.startsWith("pbkdf2"), summary);
        assertFalse(summary.contains(stored.split("\\$")[3]), "ハッシュが丸ごと出ています");
    }
}
