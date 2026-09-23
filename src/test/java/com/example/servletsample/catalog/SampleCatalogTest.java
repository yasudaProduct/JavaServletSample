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

    /**
     * WAR の中のパスから、リポジトリ上の実ファイルの場所を割り出す。
     *
     * <p>ビルド (pom.xml の {@code <webResources>} / build.xml の {@code explode})
     * が「どこから WAR のどこへ入れるか」の裏返しです。
     * ここが合っていないと、画面の「ソースコード」タブが空になります。</p>
     */
    private static Path repositoryPathOf(String warPath) {
        String path = warPath.substring(1);
        if (path.startsWith("WEB-INF/sources/java/")) {
            return Paths.get("src", "main", "java")
                    .resolve(path.substring("WEB-INF/sources/java/".length()));
        }
        if (path.startsWith("WEB-INF/sources/shared/")) {
            return Paths.get("shared", "src", "main", "java")
                    .resolve(path.substring("WEB-INF/sources/shared/".length()));
        }
        if (path.startsWith("WEB-INF/sources/build/")) {
            // ビルド設定そのもの。リポジトリのルート付近に散っている
            String name = path.substring("WEB-INF/sources/build/".length());
            if (name.equals("org.eclipse.wst.common.component")) {
                return Paths.get(".settings", name);
            }
            return Paths.get(name);
        }
        if (path.startsWith("WEB-INF/classes/")) {
            return Paths.get("src", "main", "resources")
                    .resolve(path.substring("WEB-INF/classes/".length()));
        }
        return Paths.get("src", "main", "webapp").resolve(path);
    }

    @Test
    @DisplayName("登録したソースファイルがすべて実在する")
    void sourceFilesExist() {
        for (Sample sample : catalog.getVisitableSamples()) {
            for (SourceFile source : sample.getSources()) {
                Path actual = repositoryPathOf(source.getPath());
                assertTrue(Files.exists(actual),
                        "ソースが見つかりません: " + sample.getId()
                                + " / " + source.getPath() + " → " + actual);
            }
        }
    }

    @Test
    @DisplayName("ビルド設定のソースは、Docker が COPY するものだけを参照している")
    void buildConfigSourcesAreCopiedByDocker() throws Exception {
        // pom.xml の <webResources> が参照するファイルを Dockerfile が COPY していないと、
        // Docker ビルドが「basedir ... does not exist」で失敗します。
        // ローカルには全部あるので mvn verify では気付けないため、ここで見張ります。
        String dockerfile = Files.readString(Paths.get("docker", "tomcat", "Dockerfile"));

        for (Sample sample : catalog.getVisitableSamples()) {
            for (SourceFile source : sample.getSources()) {
                if (!source.getPath().startsWith("/WEB-INF/sources/build/")) {
                    continue;
                }
                Path repoPath = repositoryPathOf(source.getPath());
                // COPY 行に、そのファイル自身かその親フォルダが出てくること
                String fileName = repoPath.getFileName().toString();
                Path parent = repoPath.getParent();
                boolean copied = dockerfile.contains("COPY " + repoPath)
                        || dockerfile.contains(" " + fileName + " ")
                        || dockerfile.contains("COPY " + fileName + " ")
                        || (parent != null && dockerfile.contains("COPY " + parent + " "));
                assertTrue(copied,
                        "docker/tomcat/Dockerfile が COPY していません: " + repoPath
                                + "（pom.xml の <webResources> が参照しているので必要です）");
            }
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
