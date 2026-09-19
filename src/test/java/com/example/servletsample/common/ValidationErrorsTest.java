package com.example.servletsample.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Arrays;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** 入力チェック結果 ({@link ValidationErrors}) のテスト。 */
class ValidationErrorsTest {

    @Test
    @DisplayName("エラーが無ければ hasErrors は false")
    void emptyByDefault() {
        ValidationErrors errors = new ValidationErrors();
        assertFalse(errors.hasErrors());
        assertEquals(0, errors.getCount());
        assertEquals("", errors.get("name"), "無い項目は空文字");
        assertFalse(errors.has("name"));
    }

    @Test
    @DisplayName("項目ごとのエラーを持てる")
    void holdsFieldErrors() {
        ValidationErrors errors = new ValidationErrors();
        errors.add("name", "氏名を入力してください。");

        assertTrue(errors.hasErrors());
        assertTrue(errors.has("name"));
        assertEquals("氏名を入力してください。", errors.get("name"));
        assertEquals(1, errors.getCount());
    }

    @Test
    @DisplayName("同じ項目は最初の 1 件だけ残る")
    void keepsFirstMessagePerField() {
        ValidationErrors errors = new ValidationErrors();
        errors.add("name", "1 件目").add("name", "2 件目");

        assertEquals("1 件目", errors.get("name"));
        assertEquals(1, errors.getCount());
    }

    @Test
    @DisplayName("条件付きで追加できる")
    void addsConditionally() {
        ValidationErrors errors = new ValidationErrors();
        errors.addIf(true, "age", "数字で入力してください。");
        errors.addIf(false, "mail", "出ないメッセージ");

        assertTrue(errors.has("age"));
        assertFalse(errors.has("mail"));
    }

    @Test
    @DisplayName("項目に紐づかないメッセージも持てる")
    void holdsGlobalErrors() {
        ValidationErrors errors = new ValidationErrors();
        errors.addGlobal("入力内容を確認してください。");
        errors.add("name", "氏名を入力してください。");

        assertEquals(Arrays.asList("入力内容を確認してください。"), errors.getGlobals());
        assertEquals(2, errors.getCount());
        assertEquals(Arrays.asList("入力内容を確認してください。", "氏名を入力してください。"),
                errors.getMessages(), "全体のメッセージが先に並ぶ");
    }

    @Test
    @DisplayName("取り出した一覧は書き換えられない")
    void returnsUnmodifiableViews() {
        ValidationErrors errors = new ValidationErrors();
        errors.add("name", "x");
        try {
            errors.getFields().put("other", "y");
            throw new AssertionError("変更できてしまいました");
        } catch (UnsupportedOperationException expected) {
            assertTrue(true);
        }
    }
}
