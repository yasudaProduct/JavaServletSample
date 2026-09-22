package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.HashMap;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.example.servletsample.samples.basic.DispatcherAttributes.Kind;

/**
 * forward / include されたときの目印の読み方を確かめるテスト。
 *
 * <p>リクエスト属性を引く関数を渡す形にしてあるので、
 * Servlet コンテナが無くても確かめられます。</p>
 */
class DispatcherAttributesTest {

    /** リクエスト属性の代わり。 */
    private final Map<String, Object> attributes = new HashMap<>();

    @Test
    @DisplayName("目印が無ければ、直接呼ばれたと判断する")
    void detectsDirectCall() {
        assertEquals(Kind.DIRECT, DispatcherAttributes.kindOf(attributes::get));
    }

    @Test
    @DisplayName("forward の目印があれば forward")
    void detectsForward() {
        attributes.put("javax.servlet.forward.request_uri", "/samples/basic/dispatcher-include");

        assertEquals(Kind.FORWARDED, DispatcherAttributes.kindOf(attributes::get));
    }

    @Test
    @DisplayName("include の目印があれば include")
    void detectsInclude() {
        attributes.put("javax.servlet.include.request_uri", "/samples/basic/dispatcher-include/part");

        assertEquals(Kind.INCLUDED, DispatcherAttributes.kindOf(attributes::get));
    }

    @Test
    @DisplayName("forward された先でさらに include されたら、include として扱う")
    void includeWinsOverForward() {
        // 画面を forward で作り、その中で部品を include した状態
        attributes.put("javax.servlet.forward.request_uri", "/samples/basic/dispatcher-include");
        attributes.put("javax.servlet.include.request_uri", "/samples/basic/dispatcher-include/part");

        assertEquals(Kind.INCLUDED, DispatcherAttributes.kindOf(attributes::get),
                "いま動いているのは include された側です");
    }

    @Test
    @DisplayName("置かれていない属性は null として並べる")
    void collectsMissingAttributesAsNull() {
        attributes.put("javax.servlet.include.request_uri", "/part");

        Map<String, String> values =
                DispatcherAttributes.collect(DispatcherAttributes.INCLUDE_KEYS, attributes::get);

        assertEquals(DispatcherAttributes.INCLUDE_KEYS.size(), values.size());
        assertEquals("/part", values.get("javax.servlet.include.request_uri"));
        assertEquals("null", values.get("javax.servlet.include.query_string"),
                "クエリ文字列が無いときは null と表示する");
    }

    @Test
    @DisplayName("目印が 1 つでもあるかを調べられる")
    void checksAnyPresent() {
        assertFalse(DispatcherAttributes.anyPresent(
                DispatcherAttributes.FORWARD_KEYS, attributes::get));

        attributes.put("javax.servlet.forward.servlet_path", "/samples/basic/dispatcher-include");
        assertTrue(DispatcherAttributes.anyPresent(
                DispatcherAttributes.FORWARD_KEYS, attributes::get));
    }

    @Test
    @DisplayName("呼び分けは決められた 3 つに絞る")
    void allowsOnlyKnownModes() {
        assertEquals("include", DispatcherIncludeDemoServlet.modeOf(null));
        assertEquals("include", DispatcherIncludeDemoServlet.modeOf("redirect"));
        assertEquals("forward", DispatcherIncludeDemoServlet.modeOf("forward"));
        assertEquals("forward-after-commit",
                DispatcherIncludeDemoServlet.modeOf("forward-after-commit"));
    }
}
