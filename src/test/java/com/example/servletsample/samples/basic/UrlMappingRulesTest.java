package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Arrays;
import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.example.servletsample.samples.basic.UrlMappingRules.Kind;
import com.example.servletsample.samples.basic.UrlMappingRules.Match;
import com.example.servletsample.samples.basic.UrlMappingRules.Rule;

/**
 * URL マッピングの判定が、Servlet 仕様どおりの順番になっているかを確かめるテスト。
 *
 * <p>画面に「この URL ならこれが呼ばれる」と出す以上、ここが間違っていると
 * 解説そのものが嘘になるので、優先順位の組み合わせを一通り押さえています。</p>
 */
class UrlMappingRulesTest {

    /** テスト用のマッピング一式 (4 つの形をすべて含む)。 */
    private static final List<Rule> RULES = Arrays.asList(
            new Rule("", "home", "コンテキストルート"),
            new Rule("/about", "about", "完全一致"),
            new Rule("/samples/basic/url-mapping", "urlMapping", "完全一致"),
            new Rule("/samples/basic/url-mapping/demo/exact", "urlMappingDemo", "完全一致"),
            new Rule("/samples/basic/url-mapping/demo/*", "urlMappingDemo", "前方一致"),
            new Rule("/samples/*", "sampleDispatcher", "前方一致"),
            new Rule("*.mapping", "urlMappingDemo", "拡張子一致"),
            new Rule("/", "default", "既定"));

    private static Match resolve(String path) {
        return UrlMappingRules.resolve(path, RULES);
    }

    @Test
    @DisplayName("完全一致は前方一致より優先される")
    void exactWinsOverPrefix() {
        Match match = resolve("/samples/basic/url-mapping");

        assertEquals(Kind.EXACT, match.getKind());
        assertEquals("urlMapping", match.getRule().getServletName());
        // 完全一致で呼ばれた Servlet の getPathInfo() は null (空文字ではない)
        assertNull(match.getPathInfo());
        assertEquals("/samples/basic/url-mapping", match.getServletPath());
    }

    @Test
    @DisplayName("前方一致は長いパターンが優先される")
    void longestPrefixWins() {
        Match match = resolve("/samples/basic/url-mapping/demo/a/b");

        assertEquals(Kind.PREFIX, match.getKind());
        assertEquals("/samples/basic/url-mapping/demo/*", match.getRule().getPattern());
        assertEquals("/samples/basic/url-mapping/demo", match.getServletPath());
        assertEquals("/a/b", match.getPathInfo());
    }

    @Test
    @DisplayName("完全一致のパターンの下は前方一致が受ける")
    void fallsBackToPrefixBelowExactPattern() {
        Match match = resolve("/samples/basic/url-mapping/demo/exact/more");

        assertEquals(Kind.PREFIX, match.getKind());
        assertEquals("/samples/basic/url-mapping/demo/*", match.getRule().getPattern());
        assertEquals("/exact/more", match.getPathInfo());
    }

    @Test
    @DisplayName("/foo/* はその階層自身にも一致し、そのときの pathInfo は null")
    void prefixPatternMatchesItsOwnPath() {
        Match match = resolve("/samples/basic/url-mapping/demo");

        assertEquals(Kind.PREFIX, match.getKind());
        assertEquals("/samples/basic/url-mapping/demo/*", match.getRule().getPattern());
        assertNull(match.getPathInfo());
    }

    @Test
    @DisplayName("前方一致は拡張子一致より優先される")
    void prefixWinsOverExtension() {
        Match match = resolve("/samples/basic/url-mapping/demo/report.mapping");

        assertEquals(Kind.PREFIX, match.getKind());
        assertEquals("/samples/basic/url-mapping/demo/*", match.getRule().getPattern());
    }

    @Test
    @DisplayName("前方一致に当たらなければ拡張子一致が選ばれる")
    void extensionMatchesOutsidePrefixPatterns() {
        Match match = resolve("/report.mapping");

        assertEquals(Kind.EXTENSION, match.getKind());
        assertEquals("*.mapping", match.getRule().getPattern());
        // 拡張子一致では URL 全体が servletPath になる
        assertEquals("/report.mapping", match.getServletPath());
        assertNull(match.getPathInfo());
    }

    @Test
    @DisplayName("拡張子を見るのは最後の階層だけ")
    void extensionLooksOnlyAtLastSegment() {
        // 途中の階層が .mapping でも、最後が index.html なので *.mapping には当たらない
        Match match = resolve("/report.mapping/index.html");

        assertEquals(Kind.DEFAULT, match.getKind());
        assertEquals("default", match.getRule().getServletName());
    }

    @Test
    @DisplayName("どれにも当たらなければ既定の Servlet が受ける")
    void fallsBackToDefaultServlet() {
        Match match = resolve("/assets/css/app.css");

        assertEquals(Kind.DEFAULT, match.getKind());
        assertEquals("/", match.getRule().getPattern());
    }

    @Test
    @DisplayName("空文字のパターンはコンテキストルートだけを受ける")
    void emptyPatternMatchesContextRootOnly() {
        assertEquals("home", resolve("/").getRule().getServletName());
        assertEquals(Kind.EXACT, resolve("/").getKind());

        // "" は "/other" には当たらない
        assertEquals("default", resolve("/other").getRule().getServletName());
    }

    @Test
    @DisplayName("既定の Servlet も無ければ該当なし (404)")
    void reportsNoMatchWhenNothingIsRegistered() {
        Match match = UrlMappingRules.resolve("/nowhere",
                Arrays.asList(new Rule("/about", "about", "完全一致")));

        assertEquals(Kind.NONE, match.getKind());
        assertFalse(match.isMatched());
        assertNull(match.getRule());
    }

    @Test
    @DisplayName("URL を丸ごと貼り付けても判定できる")
    void normalizesPastedUrls() {
        assertEquals("/samples/basic/scope",
                UrlMappingRules.normalize("http://localhost:8080/samples/basic/scope?x=1#top"));
        assertEquals("/samples/basic/scope",
                UrlMappingRules.normalize("  samples/basic/scope  "));
        assertEquals("/", UrlMappingRules.normalize(""));
        assertEquals("/", UrlMappingRules.normalize(null));
        assertEquals("/", UrlMappingRules.normalize("http://localhost:8080"));
    }

    @Test
    @DisplayName("探した順は長いパターンから短いパターンへ並ぶ")
    void searchOrderGoesFromLongestToShortest() {
        List<String> order = UrlMappingRules.searchOrder("/a/b/c.do");

        assertTrue(order.get(0).startsWith("/a/b/c.do "), "最初は完全一致: " + order.get(0));
        assertTrue(order.indexOf("/a/b/*  (前方一致)") < order.indexOf("/a/*  (前方一致)"),
                "長い前方一致が先に来ていません: " + order);
        assertTrue(order.contains("*.do  (拡張子一致)"), "拡張子一致が入っていません: " + order);
        assertEquals("/  (既定)", order.get(order.size() - 1), "最後は既定: " + order);
    }

    @Test
    @DisplayName("このサイトに登録しているパターンでも判定できる")
    void resolvesWithSiteRules() {
        List<Rule> site = UrlMappingRules.siteRules();

        assertEquals("urlMapping",
                UrlMappingRules.resolve("/samples/basic/url-mapping", site).getRule().getServletName());
        // 専用の Servlet を持たないサンプルは前方一致の受け口へ
        assertEquals("sampleDispatcher",
                UrlMappingRules.resolve("/samples/design/bootstrap-basics", site).getRule().getServletName());
        assertEquals("category",
                UrlMappingRules.resolve("/categories/basic", site).getRule().getServletName());
    }
}
