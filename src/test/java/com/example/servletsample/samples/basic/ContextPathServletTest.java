package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.example.servletsample.samples.basic.ContextPathServlet.Link;

/**
 * リンクの解決先が、ブラウザと同じ規則で求められているかを確かめるテスト。
 *
 * <p>この画面は「その書き方だと配備先でこうなる」と断言するので、
 * 解決の規則がずれていると解説が嘘になります。</p>
 */
class ContextPathServletTest {

    private static final String HERE = "/samples/basic/context-path";

    @Test
    @DisplayName("/ で始まるリンクは、いまの URL に関係なくサーバのルートから")
    void absolutePathIgnoresCurrentUrl() {
        assertEquals("/assets/favicon.svg",
                ContextPathServlet.resolve(HERE, "/assets/favicon.svg"));
        assertEquals("/assets/favicon.svg",
                ContextPathServlet.resolve("/app/samples/basic/context-path", "/assets/favicon.svg"));
    }

    @Test
    @DisplayName("相対リンクは、いまの URL のディレクトリから")
    void relativePathStartsFromCurrentDirectory() {
        assertEquals("/samples/basic/assets/favicon.svg",
                ContextPathServlet.resolve(HERE, "assets/favicon.svg"));
        assertEquals("/app/samples/basic/assets/favicon.svg",
                ContextPathServlet.resolve("/app" + HERE, "assets/favicon.svg"));
    }

    @Test
    @DisplayName("末尾のスラッシュがあると、その URL 自身がディレクトリになる")
    void trailingSlashChangesTheBase() {
        assertEquals("/samples/basic/context-path/assets/favicon.svg",
                ContextPathServlet.resolve(HERE + "/", "assets/favicon.svg"));
    }

    @Test
    @DisplayName(".. で上の階層へ戻れる")
    void resolvesParentSegments() {
        assertEquals("/samples/assets/favicon.svg",
                ContextPathServlet.resolve(HERE, "../assets/favicon.svg"));
        assertEquals("/assets/favicon.svg",
                ContextPathServlet.resolve(HERE, "../../assets/favicon.svg"));
        // ルートより上には行けない
        assertEquals("/assets/favicon.svg",
                ContextPathServlet.resolve(HERE, "../../../../assets/favicon.svg"));
    }

    @Test
    @DisplayName("./ は無視される")
    void ignoresCurrentDirectorySegments() {
        assertEquals("/samples/basic/assets/favicon.svg",
                ContextPathServlet.resolve(HERE, "./assets/favicon.svg"));
    }

    @Test
    @DisplayName("ROOT 配備では、相対で書いたものだけが壊れる")
    void onlyRelativeLinkBreaksOnRootDeployment() {
        List<Link> links = ContextPathServlet.links("", HERE);

        assertEquals(3, links.size());
        assertFalse(links.get(0).isBrokenNow(), "サーバのルートから書いたもの");
        assertTrue(links.get(1).isBrokenNow(), "相対で書いたもの");
        assertFalse(links.get(2).isBrokenNow(), "コンテキストパスから組み立てたもの");
    }

    @Test
    @DisplayName("/app に配備すると、コンテキストパス付きのものだけが生き残る")
    void onlyContextPathLinkSurvivesOnSubPathDeployment() {
        List<Link> links = ContextPathServlet.links("", HERE);

        assertTrue(links.get(0).isBrokenOther(), "サーバのルートから書いたものは 404 になる");
        assertTrue(links.get(1).isBrokenOther(), "相対で書いたものも 404 のまま");
        assertFalse(links.get(2).isBrokenOther(), "コンテキストパスから組み立てたものだけが届く");

        assertEquals("/app/assets/favicon.svg", links.get(2).getResolvedOther());
    }

    @Test
    @DisplayName("コンテキストパス付きで配備していても判定できる")
    void worksWhenAlreadyDeployedUnderContextPath() {
        List<Link> links = ContextPathServlet.links("/current", "/current" + HERE);

        // 実際のファイルは /current/assets/favicon.svg にある
        assertTrue(links.get(0).isBrokenNow(), "/assets/... は配備先の外を指してしまう");
        assertFalse(links.get(2).isBrokenNow());
        assertEquals("/current/assets/favicon.svg", links.get(2).getResolvedNow());
    }
}
