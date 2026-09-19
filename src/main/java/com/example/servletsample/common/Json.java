package com.example.servletsample.common;

import java.io.IOException;

import javax.servlet.http.HttpServletResponse;

/**
 * JSON を組み立ててレスポンスに書き出すための、ごく小さな道具。
 *
 * <pre>{@code
 * Json.write(response, Json.object()
 *         .put("ok", true)
 *         .put("count", 3)
 *         .put("items", Json.array().add(Json.object().put("name", "商品 A"))));
 * }</pre>
 *
 * <p><b>実務では Jackson や Gson といったライブラリを使ってください。</b>
 * ここでは「非同期通信で何が起きているか」に集中できるよう、
 * ライブラリを増やさずに済む最小限のものを用意しています
 * (オブジェクトをそのまま JSON にする、日付の書式を決める、といった機能はありません)。</p>
 */
public final class Json {

    private Json() {
    }

    /** {@code {...}} を組み立てる。 */
    public static JsonObject object() {
        return new JsonObject();
    }

    /** {@code [...]} を組み立てる。 */
    public static JsonArray array() {
        return new JsonArray();
    }

    /**
     * JSON をレスポンスへ書き出す。
     *
     * <p>{@code Content-Type} を {@code application/json} にしておかないと、
     * ブラウザ側の {@code response.json()} で受け取れないことがあります。</p>
     */
    public static void write(HttpServletResponse response, Object json) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(String.valueOf(json));
    }

    /**
     * 文字列を JSON の値の形にする (前後の {@code "} を含む)。
     *
     * <p>{@code "} と {@code \} と制御文字はエスケープが必須です。
     * あわせて {@code <} も {@code <} にしています。
     * HTML の {@code <script>} の中に JSON を埋め込んだときに、
     * 文字列の中の {@code </script>} でタグが閉じてしまう事故を防ぐためです
     * (JSON としては同じ意味なので、そのまま読み込めます)。</p>
     */
    static String quote(String value) {
        StringBuilder quoted = new StringBuilder(value.length() + 16).append('"');
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '"':
                    quoted.append("\\\"");
                    break;
                case '\\':
                    quoted.append("\\\\");
                    break;
                case '\b':
                    quoted.append("\\b");
                    break;
                case '\f':
                    quoted.append("\\f");
                    break;
                case '\n':
                    quoted.append("\\n");
                    break;
                case '\r':
                    quoted.append("\\r");
                    break;
                case '\t':
                    quoted.append("\\t");
                    break;
                case '<':
                    quoted.append("\\u003C");
                    break;
                default:
                    if (c < 0x20) {
                        quoted.append(String.format("\\u%04X", (int) c));
                    } else {
                        quoted.append(c);
                    }
            }
        }
        return quoted.append('"').toString();
    }

    /** 値を JSON の表記に直す。 */
    private static String valueOf(Object value) {
        if (value == null) {
            return "null";
        }
        if (value instanceof JsonObject || value instanceof JsonArray
                || value instanceof Number || value instanceof Boolean) {
            return value.toString();
        }
        return quote(String.valueOf(value));
    }

    /** JSON のオブジェクト。 */
    public static final class JsonObject {

        private final StringBuilder body = new StringBuilder();

        private JsonObject() {
        }

        /** 項目を足す。値は文字列・数値・真偽値・{@link JsonObject}・{@link JsonArray}・null。 */
        public JsonObject put(String name, Object value) {
            if (body.length() > 0) {
                body.append(',');
            }
            body.append(quote(name)).append(':').append(valueOf(value));
            return this;
        }

        @Override
        public String toString() {
            return "{" + body + "}";
        }
    }

    /** JSON の配列。 */
    public static final class JsonArray {

        private final StringBuilder body = new StringBuilder();

        private JsonArray() {
        }

        /** 要素を足す。 */
        public JsonArray add(Object value) {
            if (body.length() > 0) {
                body.append(',');
            }
            body.append(valueOf(value));
            return this;
        }

        /** 要素数。 */
        public boolean isEmpty() {
            return body.length() == 0;
        }

        @Override
        public String toString() {
            return "[" + body + "]";
        }
    }
}
