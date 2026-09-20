package com.example.servletsample.samples.basic;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * forward / redirect サンプルのうち、Servlet コンテナが無くても確かめられる部分のテスト。
 *
 * <p>リダイレクト先の URL の組み立ては間違えても画面が出てしまう
 * (コンテキストパス無しで配備していると気付けない) ので、ここで固めておきます。</p>
 */
class ForwardRedirectServletTest {

    @Test
    @DisplayName("リダイレクト先の URL はコンテキストパスから組み立てられる")
    void buildsGoalUrlFromContextPath() {
        String url = ForwardRedirectServlet.buildGoalUrl("/app", "R-20260919-0001", "yamada");

        assertTrue(url.startsWith("/app/samples/basic/forward-redirect/goal?"),
                "コンテキストパスから始まっていません: " + url);
        assertTrue(url.contains("receipt=R-20260919-0001"), "受付番号が載っていません: " + url);
        assertTrue(url.contains("&name=yamada"), "名前が載っていません: " + url);
    }

    @Test
    @DisplayName("ルート配備 (コンテキストパスが空) でも先頭のスラッシュが保たれる")
    void buildsGoalUrlForRootContext() {
        String url = ForwardRedirectServlet.buildGoalUrl("", "R-0001", "yamada");

        assertTrue(url.startsWith("/samples/basic/forward-redirect/goal?"),
                "サーバのルートからのパスになっていません: " + url);
    }

    @Test
    @DisplayName("クエリ文字列に載せる値は URL エンコードされる")
    void encodesQueryParameters() {
        String url = ForwardRedirectServlet.buildGoalUrl("/app", "R-0001", "山田&太郎");

        // 日本語や & がそのまま URL に出ていると、受け取り側でパラメータが壊れる
        assertFalse(url.contains("山田"), "日本語がエンコードされていません: " + url);
        assertFalse(url.contains("&太郎"), "値の中の & がエンコードされていません: " + url);

        String encodedName = url.substring(url.indexOf("&name=") + "&name=".length());
        assertEquals("山田&太郎", URLDecoder.decode(encodedName, StandardCharsets.UTF_8),
                "元の値に戻せません");
    }

    @Test
    @DisplayName("名前が未入力なら既定の名前を使う")
    void usesDefaultNameWhenBlank() {
        assertEquals(ForwardRedirectServlet.DEFAULT_NAME, ForwardRedirectServlet.orderName(null));
        assertEquals(ForwardRedirectServlet.DEFAULT_NAME, ForwardRedirectServlet.orderName(""));
        assertEquals(ForwardRedirectServlet.DEFAULT_NAME, ForwardRedirectServlet.orderName("   "));
    }

    @Test
    @DisplayName("名前は前後の空白を取り、長すぎる入力は切り詰める")
    void trimsAndTruncatesName() {
        assertEquals("山田太郎", ForwardRedirectServlet.orderName("  山田太郎  "));

        String tooLong = "あ".repeat(30);
        assertEquals(20, ForwardRedirectServlet.orderName(tooLong).length(),
                "20 文字に切り詰められていません");
    }
}
