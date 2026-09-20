package com.example.servletsample.samples.session;

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
 * 利用者マスタ ({@link UserAccounts}) と、ログイン後に戻る URL の検査のテスト。
 */
class UserAccountsTest {

    // ------------------------------------------------------------------
    // 照合
    // ------------------------------------------------------------------

    @ParameterizedTest
    @CsvSource({
            "taro,   password1",
            "hanako, password2",
            "admin,  admin1234"
    })
    @DisplayName("正しい組み合わせなら認証できる")
    void authenticatesWithCorrectPassword(String loginId, String password) {
        assertTrue(UserAccounts.authenticate(loginId, password).isPresent());
    }

    @ParameterizedTest
    @CsvSource({
            "taro,    password2",
            "taro,    PASSWORD1",
            "admin,   password1",
            "unknown, password1"
    })
    @DisplayName("ID かパスワードが違えば認証できない")
    void rejectsWrongCombination(String loginId, String password) {
        assertFalse(UserAccounts.authenticate(loginId, password).isPresent());
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {"   "})
    @DisplayName("ID が未入力でも例外にならず、認証は失敗する")
    void blankLoginIdFails(String loginId) {
        assertFalse(UserAccounts.authenticate(loginId, "password1").isPresent());
    }

    @Test
    @DisplayName("パスワードが null でも落ちない")
    void nullPasswordFails() {
        assertFalse(UserAccounts.authenticate("taro", null).isPresent());
    }

    @Test
    @DisplayName("前後の空白は落として探す")
    void trimsLoginId() {
        assertTrue(UserAccounts.find("  taro  ").isPresent());
    }

    // ------------------------------------------------------------------
    // 役割
    // ------------------------------------------------------------------

    @Test
    @DisplayName("役割はマスタのとおりに引き継がれる")
    void keepsRole() {
        assertEquals(Role.MEMBER, UserAccounts.authenticate("taro", "password1")
                .orElseThrow().getRole());
        assertEquals(Role.ADMIN, UserAccounts.authenticate("admin", "admin1234")
                .orElseThrow().getRole());
    }

    @Test
    @DisplayName("セッションに入れる形には、パスワードのハッシュが含まれない")
    void loginUserHasNoPassword() {
        LoginUser user = UserAccounts.authenticate("taro", "password1").orElseThrow().toLoginUser();

        assertEquals("taro", user.getLoginId());
        assertEquals("山田 太郎", user.getName());
        assertFalse(user.isAdmin());
        // LoginUser には getPasswordHash に相当するメソッドが無い、というのが設計の意図。
        // toString にも出ていないことだけ確かめておく
        assertFalse(user.toString().contains("pbkdf2"), user.toString());
    }

    // ------------------------------------------------------------------
    // ログイン後に戻る URL (オープンリダイレクト対策)
    // ------------------------------------------------------------------

    @ParameterizedTest
    @ValueSource(strings = {
            "/samples/session/auth-filter/member",
            "/samples/session/auth-filter/admin",
            "/samples/session/csrf"
    })
    @DisplayName("自サイトの想定内の URL は通す")
    void allowsInternalPaths(String next) {
        assertEquals(next, LoginServlet.safeNext(next));
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "https://evil.example/",
            "//evil.example/",
            "http://evil.example/samples/session/login",
            "/samples/basic/hello-world",
            "javascript:alert(1)",
            "/samples/session/../../etc/passwd\\",
            "evil.example"
    })
    @DisplayName("外部サイトや想定外の URL は通さない (オープンリダイレクト対策)")
    void rejectsExternalOrUnexpectedPaths(String next) {
        assertEquals("", LoginServlet.safeNext(next));
    }

    @ParameterizedTest
    @NullAndEmptySource
    @DisplayName("未指定なら空 (既定の画面へ戻す)")
    void blankNextIsEmpty(String next) {
        assertEquals("", LoginServlet.safeNext(next));
    }
}
