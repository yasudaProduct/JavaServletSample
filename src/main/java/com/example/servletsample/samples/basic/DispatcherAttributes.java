package com.example.servletsample.samples.basic;

import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * 【サンプル】forward / include されたときに、コンテナが置いていく目印。
 *
 * <p>サーバの中で処理を渡すと、渡された側からは「自分が直接呼ばれたのか、
 * 誰かから渡されたのか」が分かりにくくなります。そこでコンテナは、
 * <b>決まった名前のリクエスト属性</b>に元の情報を入れてくれます。</p>
 *
 * <table border="1">
 *   <caption>置かれる目印</caption>
 *   <tr><th>&nbsp;</th><th>属性</th><th>入っているもの</th></tr>
 *   <tr><td>forward</td><td>{@code javax.servlet.forward.request_uri} など</td>
 *       <td><b>元の</b> URL (ブラウザが最初に叩いた方)</td></tr>
 *   <tr><td>include</td><td>{@code javax.servlet.include.request_uri} など</td>
 *       <td><b>差し込まれている側</b>の URL (いま動いている方)</td></tr>
 * </table>
 *
 * <p>向きが逆なのがややこしいところです。</p>
 *
 * <ul>
 *   <li>forward では {@code getRequestURI()} が<b>転送先</b>を指し、元の URL は属性に入る</li>
 *   <li>include では {@code getRequestURI()} が<b>元のまま</b>で、差し込まれた側の URL が属性に入る</li>
 * </ul>
 *
 * <p>どちらも「ブラウザから見た URL は変わっていない」ことに変わりはありません。
 * そのためリンクを作るときは、{@code getRequestURI()} ではなく
 * コンテキストパスから組み立てます (「コンテキストパスと相対パス」を参照)。</p>
 */
public final class DispatcherAttributes {

    private DispatcherAttributes() {
    }

    /** include されたときに置かれる属性 (Servlet 4.0 / javax 名前空間)。 */
    public static final List<String> INCLUDE_KEYS = Collections.unmodifiableList(Arrays.asList(
            "javax.servlet.include.request_uri",
            "javax.servlet.include.context_path",
            "javax.servlet.include.servlet_path",
            "javax.servlet.include.path_info",
            "javax.servlet.include.query_string"));

    /** forward されたときに置かれる属性。 */
    public static final List<String> FORWARD_KEYS = Collections.unmodifiableList(Arrays.asList(
            "javax.servlet.forward.request_uri",
            "javax.servlet.forward.context_path",
            "javax.servlet.forward.servlet_path",
            "javax.servlet.forward.path_info",
            "javax.servlet.forward.query_string"));

    /** 呼ばれ方。 */
    public enum Kind {

        /** ブラウザから直接。 */
        DIRECT("直接呼ばれた"),

        /** 誰かから forward された。 */
        FORWARDED("forward された"),

        /** 誰かに include された。 */
        INCLUDED("include された");

        private final String label;

        Kind(String label) {
            this.label = label;
        }

        /** 画面に出す名前。 */
        public String getLabel() {
            return label;
        }
    }

    /**
     * どう呼ばれたかを、置かれている目印から判断する。
     *
     * <p>include の目印が先です。forward された先でさらに include されることがあり、
     * そのとき「いま動いているのは include された側」だからです。</p>
     *
     * @param lookup リクエスト属性を引く関数 ({@code request::getAttribute} を渡します)
     */
    public static Kind kindOf(Function<String, Object> lookup) {
        if (lookup.apply(INCLUDE_KEYS.get(0)) != null) {
            return Kind.INCLUDED;
        }
        if (lookup.apply(FORWARD_KEYS.get(0)) != null) {
            return Kind.FORWARDED;
        }
        return Kind.DIRECT;
    }

    /**
     * 属性をまとめて読み、順番を保った Map にする。
     *
     * <p>置かれていない属性は {@code null} なので、画面で見えるように文字にしています。</p>
     */
    public static Map<String, String> collect(List<String> keys, Function<String, Object> lookup) {
        Map<String, String> values = new LinkedHashMap<>();
        for (String key : keys) {
            Object value = lookup.apply(key);
            values.put(key, value == null ? "null" : String.valueOf(value));
        }
        return values;
    }

    /** 属性がひとつでも置かれているか。 */
    public static boolean anyPresent(List<String> keys, Function<String, Object> lookup) {
        for (String key : keys) {
            if (lookup.apply(key) != null) {
                return true;
            }
        }
        return false;
    }
}
