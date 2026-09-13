package com.example.servletsample.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * カタログの登録内容に矛盾が無いかを確認するテスト。
 *
 * <p>サンプルを追加したときは {@code mvn test} を流すと、
 * JSP の置き忘れや ID の重複にすぐ気付けます。</p>
 */
class SampleCatalogTest {

    private final SampleCatalog catalog = SampleCatalog.getInstance();

    @Test
    @DisplayName("サンプルが 1 件以上登録されている")
    void hasSamples() {
        assertFalse(catalog.getSamples().isEmpty(), "サンプルが 1 件も登録されていません");
    }

    @Test
    @DisplayName("サンプル ID と URL が重複していない")
    void idsAndPathsAreUnique() {
        Set<String> ids = new HashSet<>();
        Set<String> paths = new HashSet<>();
        for (Sample sample : catalog.getSamples()) {
            assertTrue(ids.add(sample.getId()), "ID が重複しています: " + sample.getId());
            assertTrue(paths.add(sample.getPath()), "URL が重複しています: " + sample.getPath());
        }
    }

    @Test
    @DisplayName("URL と JSP のパスがカテゴリと ID から組み立てられている")
    void pathsFollowConvention() {
        for (Sample sample : catalog.getSamples()) {
            String categoryId = sample.getCategory().getId();
            assertEquals("/samples/" + categoryId + "/" + sample.getId(), sample.getPath());
            if (sample.isVisitable()) {
                assertEquals("/WEB-INF/views/samples/" + categoryId + "/" + sample.getId() + ".jsp",
                        sample.getViewPath());
            }
        }
    }

    @Test
    @DisplayName("公開中サンプルの JSP が実際に存在する")
    void viewFilesExist() {
        Path webapp = Paths.get("src", "main", "webapp");
        for (Sample sample : catalog.getVisitableSamples()) {
            Path view = webapp.resolve(sample.getViewPath().substring(1));
            assertTrue(Files.exists(view), "JSP が見つかりません: " + view);
        }
    }

    @Test
    @DisplayName("公開中サンプルには表示するソースが 1 件以上ある")
    void visitableSamplesHaveSources() {
        for (Sample sample : catalog.getVisitableSamples()) {
            assertFalse(sample.getSources().isEmpty(), "ソースが未登録です: " + sample.getId());
        }
    }

    @Test
    @DisplayName("ID でサンプルを取得できる")
    void findsById() {
        Sample sample = catalog.byId("hello-world");
        assertNotNull(sample, "hello-world が見つかりません");
        assertEquals(Category.BASIC, sample.getCategory());
    }

    @Test
    @DisplayName("キーワードでサンプルを検索できる")
    void searchesByKeyword() {
        List<Sample> results = catalog.search("Bootstrap");
        assertFalse(results.isEmpty(), "Bootstrap で検索できませんでした");

        // 空のキーワードなら全件が返る
        assertEquals(catalog.getSamples().size(), catalog.search("").size());
    }

    @Test
    @DisplayName("検索結果は公開中のサンプルが先に並ぶ")
    void visitableSamplesComeFirstInSearchResults() {
        boolean seenPlanned = false;
        for (Sample sample : catalog.search("")) {
            if (!sample.isVisitable()) {
                seenPlanned = true;
            } else {
                assertFalse(seenPlanned, "準備中のサンプルより後ろに公開中のサンプルが並んでいます");
            }
        }
    }
}
