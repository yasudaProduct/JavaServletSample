package com.example.servletsample.samples.basic;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

/**
 * 【サンプル】URL から Servlet を選ぶときの決まりごと。
 *
 * <p>ブラウザから URL が届いたとき、コンテナ (Tomcat) は登録されている
 * {@code url-pattern} の中から 1 つを選びます。選び方は
 * <b>書いた順でも、登録した順でもありません</b>。次の順で探し、
 * 先に見つかったところで打ち切ります。</p>
 *
 * <ol>
 *   <li><b>完全一致</b> … {@code /samples/basic/url-mapping} のように、パターンと URL が同じ</li>
 *   <li><b>前方一致</b> … {@code /samples/*} の形。当てはまるものが複数あれば<b>いちばん長いもの</b></li>
 *   <li><b>拡張子一致</b> … {@code *.mapping} の形。前方一致で決まらなかったときだけ見られる</li>
 *   <li><b>既定</b> … {@code /} に割り当てられた Servlet (Tomcat では静的ファイルを返すもの)</li>
 * </ol>
 *
 * <p>このクラスはその手順をそのまま Java で書いたものです。画面に「この URL なら
 * どれが呼ばれるか」を出すために使っています。実際に選ぶのはコンテナなので、
 * デモではコンテナが返した {@code getServletPath()} と見比べられるようにしています。</p>
 *
 * <p>なお、パターンの文字列に使えるのは上の 4 つの形だけです。
 * パスの途中に {@code *} を挟む書き方や、正規表現は使えません。</p>
 */
public final class UrlMappingRules {

    private UrlMappingRules() {
    }

    /** 一致のしかた。 */
    public enum Kind {

        /** パターンと URL がぴったり同じ。いちばん強い。 */
        EXACT("完全一致", "パターンと URL が同じ", "success"),

        /** {@code /foo/*} の形。当てはまるもののうち、いちばん長いものが選ばれる。 */
        PREFIX("前方一致", "/foo/* の形。いちばん長いものが選ばれる", "primary"),

        /** {@code *.do} の形。前方一致で決まらなかったときだけ見られる。 */
        EXTENSION("拡張子一致", "*.do の形。前方一致で決まらなかったときだけ", "warning"),

        /** {@code /} に割り当てられた Servlet。どれにも当たらなかったものを受ける。 */
        DEFAULT("既定の Servlet", "/ に割り当てられたもの。静的ファイルはここが返す", "secondary"),

        /** 受け口が無い。404 になる。 */
        NONE("該当なし", "受け口が無いので 404 になる", "danger");

        private final String label;
        private final String description;
        private final String variant;

        Kind(String label, String description, String variant) {
            this.label = label;
            this.description = description;
            this.variant = variant;
        }

        /** 画面に出す名前。 */
        public String getLabel() {
            return label;
        }

        /** 画面に出す説明。 */
        public String getDescription() {
            return description;
        }

        /** Bootstrap のバッジ色。 */
        public String getVariant() {
            return variant;
        }
    }

    /** 登録されているマッピング 1 件 (パターンと、それを持つ Servlet)。 */
    public static final class Rule {

        private final String pattern;
        private final String servletName;
        private final String note;

        public Rule(String pattern, String servletName, String note) {
            this.pattern = Objects.requireNonNull(pattern, "pattern");
            this.servletName = servletName;
            this.note = note;
        }

        /** {@code url-pattern} の文字列。空文字はコンテキストルート専用の特別なパターン。 */
        public String getPattern() {
            return pattern;
        }

        /** 画面に出すときのパターン (空文字だと何も見えないので補う)。 */
        public String getPatternLabel() {
            return pattern.isEmpty() ? "\"\" (空文字)" : pattern;
        }

        /** この URL を受け持つ Servlet の名前。 */
        public String getServletName() {
            return servletName;
        }

        /** 一覧に添える一言。 */
        public String getNote() {
            return note;
        }

        /** 完全一致するか。空文字のパターンはコンテキストルート ({@code /}) だけに一致する。 */
        boolean matchesExactly(String path) {
            return pattern.isEmpty() ? "/".equals(path) : pattern.equals(path);
        }
    }

    /** 判定の結果。 */
    public static final class Match {

        private final Rule rule;
        private final Kind kind;
        private final String path;
        private final String servletPath;
        private final String pathInfo;

        Match(Rule rule, Kind kind, String path, String servletPath, String pathInfo) {
            this.rule = rule;
            this.kind = kind;
            this.path = path;
            this.servletPath = servletPath;
            this.pathInfo = pathInfo;
        }

        /** 選ばれたマッピング。該当なしなら {@code null}。 */
        public Rule getRule() {
            return rule;
        }

        /** 一致のしかた。 */
        public Kind getKind() {
            return kind;
        }

        /** 判定に使った URL (コンテキストパスより後ろ)。 */
        public String getPath() {
            return path;
        }

        /** {@code request.getServletPath()} に入るはずの値。 */
        public String getServletPath() {
            return servletPath;
        }

        /**
         * {@code request.getPathInfo()} に入るはずの値。
         * <p>余りが無ければ {@code null} です。空文字ではありません。</p>
         */
        public String getPathInfo() {
            return pathInfo;
        }

        /** 受け口が見つかったか。 */
        public boolean isMatched() {
            return kind != Kind.NONE;
        }

        /** 画面に出す {@code getServletPath()} (空文字のときに何も見えないのを防ぐ)。 */
        public String getServletPathLabel() {
            return servletPath.isEmpty() ? "\"\" (空文字)" : servletPath;
        }

        /** 画面に出す {@code getPathInfo()}。 */
        public String getPathInfoLabel() {
            return pathInfo == null ? "null" : pathInfo;
        }
    }

    /**
     * このサイトに実際に登録されているマッピング。
     *
     * <p>サンプル 1 件ごとの完全一致マッピング (30 件以上あります) は、
     * 代表として 2 件だけ載せています。</p>
     */
    public static List<Rule> siteRules() {
        return Collections.unmodifiableList(Arrays.asList(
                new Rule("", "home", "コンテキストルート専用。トップページ"),
                new Rule("/about", "about", "完全一致。このサイトについて"),
                new Rule("/search", "search", "完全一致。検索"),
                new Rule("/samples/basic/url-mapping", "urlMapping", "完全一致。いま開いているページ"),
                new Rule("/samples/basic/url-mapping/demo/exact", "urlMappingDemo", "完全一致。デモ用"),
                new Rule("/samples/basic/url-mapping/demo/*", "urlMappingDemo", "前方一致。デモ用"),
                new Rule("/samples/basic/hello-world", "helloWorld", "完全一致 (サンプルごとに 1 つ)"),
                new Rule("/categories/*", "category", "前方一致。/categories/basic など"),
                new Rule("/samples/*", "sampleDispatcher", "前方一致。専用の Servlet が無いサンプルの受け口"),
                new Rule("*.mapping", "urlMappingDemo", "拡張子一致。デモ用"),
                new Rule("*.jsp", "jsp", "拡張子一致。コンテナが最初から持っている JSP 用の Servlet"),
                new Rule("/", "default", "既定。コンテナが最初から持っている静的ファイル用の Servlet")));
    }

    /**
     * 入力された文字列を、判定に使える形に整える。
     *
     * <p>URL を丸ごと貼り付けられても動くように、スキームとホスト、
     * クエリ文字列 ({@code ?...})、フラグメント ({@code #...}) を落とします。
     * 判定に使うのは<b>コンテキストパスより後ろ</b>だけです。</p>
     */
    public static String normalize(String input) {
        if (input == null) {
            return "/";
        }
        String path = input.trim();

        // http://localhost:8080/foo → /foo
        int scheme = path.indexOf("://");
        if (scheme >= 0) {
            int slash = path.indexOf('/', scheme + 3);
            path = slash < 0 ? "" : path.substring(slash);
        }
        int query = path.indexOf('?');
        if (query >= 0) {
            path = path.substring(0, query);
        }
        int fragment = path.indexOf('#');
        if (fragment >= 0) {
            path = path.substring(0, fragment);
        }
        if (path.isEmpty()) {
            return "/";
        }
        return path.startsWith("/") ? path : "/" + path;
    }

    /**
     * URL を受け持つマッピングを探す。
     *
     * @param path  コンテキストパスより後ろの部分 (例: {@code /samples/basic/scope})
     * @param rules 登録されているマッピング
     */
    public static Match resolve(String path, List<Rule> rules) {
        String target = normalize(path);

        // ------------------------------------------------------------------
        // ① 完全一致。ここで見つかれば、他がどれだけ当てはまっても勝ち
        // ------------------------------------------------------------------
        for (Rule rule : rules) {
            if (rule.matchesExactly(target)) {
                return new Match(rule, Kind.EXACT, target, target, null);
            }
        }

        // ------------------------------------------------------------------
        // ② 前方一致。URL を後ろから 1 階層ずつ削りながら "/*" を付けて探すので、
        //    いちばん長いパターンが先に見つかります。
        //      /samples/basic/url-mapping/demo/a → /samples/basic/url-mapping/demo/a/*
        //                                        → /samples/basic/url-mapping/demo/*   ← ここで一致
        //                                        → /samples/basic/url-mapping/*
        //                                        → ...
        //    なお /foo/* は /foo/bar だけでなく /foo 自身にも一致します
        //    (そのときの getPathInfo() は null)。
        // ------------------------------------------------------------------
        String candidate = trimTrailingSlash(target);
        while (candidate.startsWith("/")) {
            Rule rule = findPattern(rules, candidate + "/*");
            if (rule != null) {
                String rest = target.substring(candidate.length());
                return new Match(rule, Kind.PREFIX, target, candidate, rest.isEmpty() ? null : rest);
            }
            candidate = candidate.substring(0, candidate.lastIndexOf('/'));
        }
        // "/*" はアプリ内のすべてに当たる。servletPath は空文字、pathInfo が URL 全体になる
        Rule everything = findPattern(rules, "/*");
        if (everything != null) {
            return new Match(everything, Kind.PREFIX, target, "", target);
        }

        // ------------------------------------------------------------------
        // ③ 拡張子一致。見るのは最後の階層だけです。
        //    /a.mapping/b は「最後が b」なので *.mapping には当たりません。
        // ------------------------------------------------------------------
        String lastSegment = target.substring(target.lastIndexOf('/') + 1);
        int dot = lastSegment.lastIndexOf('.');
        if (dot >= 0) {
            Rule rule = findPattern(rules, "*" + lastSegment.substring(dot));
            if (rule != null) {
                // 拡張子一致では URL 全体が getServletPath() になり、getPathInfo() は null
                return new Match(rule, Kind.EXTENSION, target, target, null);
            }
        }

        // ------------------------------------------------------------------
        // ④ 既定の Servlet。Tomcat では静的ファイル (CSS や画像) を返すものが
        //    最初から "/" に割り当たっています。ファイルが無ければ 404 を返します。
        // ------------------------------------------------------------------
        Rule fallback = findPattern(rules, "/");
        if (fallback != null) {
            return new Match(fallback, Kind.DEFAULT, target, target, null);
        }
        return new Match(null, Kind.NONE, target, target, null);
    }

    /** 判定に使った順でパターンを並べた説明 (画面の「探した順」に出す)。 */
    public static List<String> searchOrder(String path) {
        String target = normalize(path);
        List<String> order = new ArrayList<>();
        order.add(target + "  (完全一致)");

        String candidate = trimTrailingSlash(target);
        while (candidate.startsWith("/")) {
            order.add(candidate + "/*  (前方一致)");
            candidate = candidate.substring(0, candidate.lastIndexOf('/'));
        }
        order.add("/*  (前方一致)");

        String lastSegment = target.substring(target.lastIndexOf('/') + 1);
        int dot = lastSegment.lastIndexOf('.');
        if (dot >= 0) {
            order.add("*" + lastSegment.substring(dot) + "  (拡張子一致)");
        }
        order.add("/  (既定)");
        return order;
    }

    /** 末尾のスラッシュを落とす ({@code /} 自身は空文字にする)。 */
    private static String trimTrailingSlash(String path) {
        String trimmed = path;
        while (trimmed.endsWith("/")) {
            trimmed = trimmed.substring(0, trimmed.length() - 1);
        }
        return trimmed;
    }

    /** パターンの文字列が一致するものを探す。 */
    private static Rule findPattern(List<Rule> rules, String pattern) {
        for (Rule rule : rules) {
            if (rule.getPattern().equals(pattern)) {
                return rule;
            }
        }
        return null;
    }
}
