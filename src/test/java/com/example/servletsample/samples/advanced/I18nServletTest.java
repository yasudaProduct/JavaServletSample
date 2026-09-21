package com.example.servletsample.samples.advanced;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Properties;
import java.util.ResourceBundle;
import java.util.Set;
import java.util.TreeSet;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * 国際化のサンプル ({@link I18nServlet}) と、メッセージファイルのテスト。
 *
 * <p>とくに最後の「key がそろっているか」は、言語を増やしたときに効きます。
 * 訳の入れ忘れは画面に {@code ???key???} と出るだけで<b>例外にはならない</b>ため、
 * 人の目で気付くのは難しいからです。</p>
 */
class I18nServletTest {

    @ParameterizedTest
    @CsvSource({
            "ja, ja_JP",
            "en, en_US",
            "fr, fr_FR"
    })
    @DisplayName("言語コードは国まで含んだロケールになる (通貨や日付の書式が国で決まるため)")
    void mapsLanguageToLocaleWithCountry(String lang, String expected) {
        assertEquals(expected, I18nServlet.toLocale(lang).toString());
    }

    @ParameterizedTest
    @CsvSource({
            "ja, ja",
            "en, en"
    })
    @DisplayName("用意してある言語なら、その言語の properties が読まれる")
    void usesBundleOfRequestedLanguage(String lang, String expectedBundleLanguage) {
        Locale bundleLocale = I18nServlet.bundleLocaleOf(I18nServlet.toLocale(lang));

        assertNotNull(bundleLocale);
        assertEquals(expectedBundleLanguage, bundleLocale.getLanguage());
    }

    @Test
    @DisplayName("用意していない言語を頼むと、既定の messages.properties まで落ちる")
    void fallsBackWhenBundleIsMissing() {
        Locale original = Locale.getDefault();
        try {
            // フォールバック先は「JVM の既定ロケール」→「言語指定なし」の順。
            // テストの結果が動いている環境に左右されないよう、既定を固定して確かめる
            Locale.setDefault(Locale.ROOT);
            ResourceBundle.clearCache(I18nServlet.class.getClassLoader());

            Locale bundleLocale = I18nServlet.bundleLocaleOf(Locale.FRANCE);

            assertNotNull(bundleLocale);
            assertEquals(Locale.ROOT, bundleLocale, "messages.properties が使われるはず");
        } finally {
            Locale.setDefault(original);
            ResourceBundle.clearCache(I18nServlet.class.getClassLoader());
        }
    }

    @Test
    @DisplayName("言語ごとの properties で key がそろっている (訳の入れ忘れを見つける)")
    void allBundlesHaveTheSameKeys() {
        Set<String> base = keysOf("");
        assertTrue(base.size() >= 5, "既定の messages.properties が空です");

        for (String suffix : new String[] {"_ja", "_en"}) {
            assertEquals(base, keysOf(suffix),
                    "messages" + suffix + ".properties の key が既定と一致しません");
        }
    }

    /**
     * properties ファイルが「そのファイル自身で」持っている key の一覧。
     *
     * <p>{@link ResourceBundle} 経由で読むと、見つからない key は
     * フォールバック先のものが見えてしまい、入れ忘れに気付けません。
     * ここではファイルを直接読んでいます。</p>
     *
     * @param suffix {@code ""} / {@code "_ja"} / {@code "_en"}
     */
    private static Set<String> keysOf(String suffix) {
        String resource = "/" + I18nServlet.BUNDLE_BASE_NAME + suffix + ".properties";
        Properties properties = new Properties();
        try (InputStream in = I18nServletTest.class.getResourceAsStream(resource)) {
            assertNotNull(in, resource + " が見つかりません");
            // Java 9 以降、properties は UTF-8 として読むのが既定
            properties.load(new InputStreamReader(in, StandardCharsets.UTF_8));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return new TreeSet<>(properties.stringPropertyNames());
    }
}
