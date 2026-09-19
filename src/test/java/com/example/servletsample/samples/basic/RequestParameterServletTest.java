package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import com.example.servletsample.samples.basic.RequestParameterServlet.NumberResult;
import com.example.servletsample.samples.basic.RequestParameterServlet.ParameterRow;

/**
 * リクエストパラメータの受け取り方サンプルのテスト。
 *
 * <p>「利用者は何でも送れる」という前提が守れているか
 * （落ちない・既定値で続けられる）を中心に確かめます。</p>
 */
class RequestParameterServletTest {

    @Nested
    @DisplayName("文字列から数値への変換")
    class ParseSize {

        @Test
        @DisplayName("数字ならそのまま受け取れる")
        void acceptsNumber() {
            NumberResult result = RequestParameterServlet.parseSize("25");
            assertTrue(result.isValid());
            assertEquals(25, result.getValue());
        }

        @Test
        @DisplayName("前後に空白があっても受け取れる")
        void trimsSpaces() {
            NumberResult result = RequestParameterServlet.parseSize("  25  ");
            assertTrue(result.isValid(), "trim していないと NumberFormatException になります");
            assertEquals(25, result.getValue());
        }

        @Test
        @DisplayName("パラメータが届いていなければ既定値で続ける")
        void fallsBackWhenNotSent() {
            NumberResult result = RequestParameterServlet.parseSize(null);
            assertFalse(result.isValid());
            assertEquals(RequestParameterServlet.DEFAULT_SIZE, result.getValue());
            assertEquals("null", result.getRawText(), "null と空文字は表示で見分けられるようにする");
        }

        @Test
        @DisplayName("空文字なら既定値で続ける")
        void fallsBackWhenEmpty() {
            NumberResult result = RequestParameterServlet.parseSize("");
            assertFalse(result.isValid());
            assertEquals(RequestParameterServlet.DEFAULT_SIZE, result.getValue());
            assertEquals("\"\"", result.getRawText());
        }

        @Test
        @DisplayName("数字以外・小数・桁あふれでも落ちない")
        void survivesUnparsableInput() {
            for (String raw : new String[]{"abc", "1.5", "1,000", "9999999999", "10 件", "<script>"}) {
                NumberResult result = RequestParameterServlet.parseSize(raw);
                assertFalse(result.isValid(), raw + " は数値として扱えないはずです");
                assertEquals(RequestParameterServlet.DEFAULT_SIZE, result.getValue(),
                        raw + " のときは既定値で続けます");
            }
        }

        @Test
        @DisplayName("全角数字は通ってしまう（だから範囲の検査が要る）")
        void acceptsFullWidthDigits() {
            // Integer.parseInt は内部で Character.digit を使うため、全角数字も数字として扱われます。
            // 「変換できた = 正しい値」ではない、という例です。
            NumberResult result = RequestParameterServlet.parseSize("１０");
            assertTrue(result.isValid());
            assertEquals(10, result.getValue());
        }

        @Test
        @DisplayName("範囲の外は範囲内に丸める")
        void clampsOutOfRange() {
            assertEquals(1, RequestParameterServlet.parseSize("0").getValue());
            assertEquals(1, RequestParameterServlet.parseSize("-5").getValue());
            assertEquals(RequestParameterServlet.MAX_SIZE,
                    RequestParameterServlet.parseSize("100000").getValue());
        }
    }

    @Nested
    @DisplayName("hidden 併用チェックボックスの判定")
    class CheckedByLastValue {

        @Test
        @DisplayName("チェックされていれば hidden の後ろに on が届く")
        void checked() {
            assertTrue(RequestParameterServlet.checkedByLastValue(new String[]{"off", "on"}));
        }

        @Test
        @DisplayName("チェックされていなければ hidden の off だけが届く")
        void unchecked() {
            assertFalse(RequestParameterServlet.checkedByLastValue(new String[]{"off"}));
        }

        @Test
        @DisplayName("hidden を置き忘れて何も届かなくても落ちない")
        void nothingSent() {
            assertFalse(RequestParameterServlet.checkedByLastValue(null));
            assertFalse(RequestParameterServlet.checkedByLastValue(new String[0]));
        }
    }

    @Nested
    @DisplayName("受け取った値の状態（届いていない / 空文字 / 値あり）")
    class Row {

        @Test
        @DisplayName("パラメータが届いていなければ null として扱う")
        void notSent() {
            ParameterRow row = ParameterRow.read(request(new HashMap<>()), "name", "氏名");

            assertFalse(row.isSent());
            assertEquals("届いていない", row.getState());
            assertEquals("null", row.getValueText());
            assertEquals("null", row.getValuesText(), "getParameterValues も null です");
            assertEquals(-1, row.getLength());
            assertEquals(0, row.getValueCount());
        }

        @Test
        @DisplayName("空のまま送信されたら空文字として扱う（null とは区別する）")
        void sentButEmpty() {
            Map<String, String[]> parameters = new HashMap<>();
            parameters.put("name", new String[]{""});
            ParameterRow row = ParameterRow.read(request(parameters), "name", "氏名");

            assertTrue(row.isSent(), "パラメータ自体は届いています");
            assertEquals("空文字", row.getState());
            assertEquals("\"\"", row.getValueText());
            assertEquals(0, row.getLength());
        }

        @Test
        @DisplayName("複数届いたら getParameter は先頭だけ、getParameterValues は全部")
        void multipleValues() {
            Map<String, String[]> parameters = new HashMap<>();
            parameters.put("interests", new String[]{"java", "db"});
            ParameterRow row = ParameterRow.read(request(parameters), "interests", "興味");

            assertEquals("java", row.getValue(), "getParameter は先頭の 1 つだけを返します");
            assertTrue(row.isMultiple());
            assertEquals(2, row.getValueCount());
            assertEquals("[\"java\", \"db\"]", row.getValuesText());
        }

        @Test
        @DisplayName("getParameterMap の 1 件からも同じ形にできる")
        void fromMapEntry() {
            ParameterRow row = ParameterRow.fromMap("interests", new String[]{"java", "db"});

            assertEquals("java", row.getValue());
            assertEquals(2, row.getValueCount());
        }
    }

    // ------------------------------------------------------------------
    // テスト用の最小限の HttpServletRequest
    // (モックライブラリを足さずに済ませるため、動的プロキシで必要なメソッドだけ実装する)
    // ------------------------------------------------------------------
    private static HttpServletRequest request(Map<String, String[]> parameters) {
        InvocationHandler handler = (target, method, args) -> {
            switch (method.getName()) {
                case "getParameter": {
                    String[] values = parameters.get((String) args[0]);
                    return (values == null || values.length == 0) ? null : values[0];
                }
                case "getParameterValues":
                    return parameters.get((String) args[0]);
                case "getParameterMap":
                    return parameters;
                default:
                    return null;
            }
        };
        return (HttpServletRequest) Proxy.newProxyInstance(
                RequestParameterServletTest.class.getClassLoader(),
                new Class<?>[]{HttpServletRequest.class}, handler);
    }
}
