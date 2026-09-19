package com.example.servletsample.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** JSON の組み立て ({@link Json}) のテスト。 */
class JsonTest {

    @Test
    @DisplayName("オブジェクトと配列を組み立てられる")
    void buildsObjectAndArray() {
        String json = Json.object()
                .put("ok", true)
                .put("count", 2)
                .put("items", Json.array().add("A").add("B"))
                .toString();

        assertEquals("{\"ok\":true,\"count\":2,\"items\":[\"A\",\"B\"]}", json);
    }

    @Test
    @DisplayName("空のオブジェクト・配列も正しい JSON になる")
    void buildsEmpty() {
        assertEquals("{}", Json.object().toString());
        assertEquals("[]", Json.array().toString());
        assertTrue(Json.array().isEmpty());
        assertFalse(Json.array().add(1).isEmpty());
    }

    @Test
    @DisplayName("null と数値はそのまま、文字列は引用符が付く")
    void writesTypes() {
        assertEquals("{\"a\":null,\"b\":1,\"c\":1.5,\"d\":\"1\"}",
                Json.object().put("a", null).put("b", 1).put("c", 1.5).put("d", "1").toString());
    }

    @Test
    @DisplayName("何度 toString しても同じ結果になる")
    void toStringIsRepeatable() {
        Json.JsonObject object = Json.object().put("a", 1);
        assertEquals(object.toString(), object.toString());
    }

    @Test
    @DisplayName("引用符・バックスラッシュ・改行をエスケープする")
    void escapesSpecialCharacters() {
        assertEquals("\"a\\\"b\"", Json.quote("a\"b"));
        assertEquals("\"a\\\\b\"", Json.quote("a\\b"));
        assertEquals("\"a\\nb\"", Json.quote("a\nb"));
        assertEquals("\"a\\tb\"", Json.quote("a\tb"));
    }

    @Test
    @DisplayName("制御文字は \\u 形式にする")
    void escapesControlCharacters() {
        assertEquals("\"\\u0001\"", Json.quote("\u0001"));
    }

    @Test
    @DisplayName("< をエスケープして </script> で閉じられないようにする")
    void escapesLessThan() {
        assertEquals("\"\\u003C/script>\"", Json.quote("</script>"));
    }

    @Test
    @DisplayName("日本語はそのまま (UTF-8 で返すため)")
    void keepsJapaneseAsIs() {
        assertEquals("\"商品 A\"", Json.quote("商品 A"));
    }
}
