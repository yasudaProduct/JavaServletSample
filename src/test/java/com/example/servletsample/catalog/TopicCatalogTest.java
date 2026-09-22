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
 * 座学メモの登録内容に矛盾が無いかを確認するテスト。
 *
 * <p>メモを追加したときは {@code mvn test} を流すと、
 * JSP の置き忘れ・ID の重複・関連サンプルの書き間違いにすぐ気付けます。</p>
 */
class TopicCatalogTest {

    private final TopicCatalog topics = TopicCatalog.getInstance();

    @Test
    @DisplayName("座学メモが 1 件以上登録されている")
    void hasTopics() {
        assertFalse(topics.getTopics().isEmpty(), "座学メモが 1 件も登録されていません");
    }

    @Test
    @DisplayName("ID と URL が重複していない")
    void idsAndPathsAreUnique() {
        Set<String> ids = new HashSet<>();
        Set<String> paths = new HashSet<>();
        for (Topic topic : topics.getTopics()) {
            assertTrue(ids.add(topic.getId()), "ID が重複しています: " + topic.getId());
            assertTrue(paths.add(topic.getPath()), "URL が重複しています: " + topic.getPath());
        }
    }

    @Test
    @DisplayName("URL と JSP のパスが ID から組み立てられている")
    void pathsFollowConvention() {
        for (Topic topic : topics.getTopics()) {
            assertEquals("/topics/" + topic.getId(), topic.getPath());
            assertEquals("/WEB-INF/views/topics/" + topic.getId() + ".jsp", topic.getViewPath());
        }
    }

    @Test
    @DisplayName("公開中の座学メモの JSP が実際に存在する")
    void viewFilesExist() {
        Path webapp = Paths.get("src", "main", "webapp");
        for (Topic topic : topics.getVisitableTopics()) {
            Path view = webapp.resolve(topic.getViewPath().substring(1));
            assertTrue(Files.exists(view), "JSP が見つかりません: " + view);
        }
    }

    @Test
    @DisplayName("タイトル・説明・タグが空でない")
    void hasDescriptiveText() {
        for (Topic topic : topics.getTopics()) {
            assertFalse(topic.getTitle().trim().isEmpty(), "タイトルが空です: " + topic.getId());
            assertFalse(topic.getSummary().trim().isEmpty(), "説明が空です: " + topic.getId());
            assertFalse(topic.getTags().isEmpty(), "タグが未登録です: " + topic.getId());
            assertTrue(topic.getReadingMinutes() > 0, "読了時間が 0 以下です: " + topic.getId());
        }
    }

    @Test
    @DisplayName("関連サンプルに書いた ID がカタログに実在する")
    void relatedSampleIdsExist() {
        SampleCatalog samples = SampleCatalog.getInstance();
        for (Topic topic : topics.getTopics()) {
            for (String sampleId : topic.getRelatedSampleIds()) {
                assertNotNull(samples.byId(sampleId),
                        "関連サンプルの ID が見つかりません: " + topic.getId() + " → " + sampleId);
            }
        }
    }

    @Test
    @DisplayName("ID で座学メモを取得できる")
    void findsById() {
        Topic topic = topics.byId("request-lifecycle");
        assertNotNull(topic, "request-lifecycle が見つかりません");
        assertEquals(TopicGroup.MECHANISM, topic.getGroup());
    }

    @Test
    @DisplayName("キーワードで座学メモを検索できる")
    void searchesByKeyword() {
        List<Topic> results = topics.search("セッション");
        assertFalse(results.isEmpty(), "セッションで検索できませんでした");

        // 空のキーワードなら全件が返る
        assertEquals(topics.getTopics().size(), topics.search("").size());
    }

    @Test
    @DisplayName("前後のメモが一覧の並び順どおりにつながっている")
    void neighboursFollowListOrder() {
        List<Topic> visitable = topics.getVisitableTopics();
        for (int i = 0; i < visitable.size(); i++) {
            Topic current = visitable.get(i);
            Topic expectedPrevious = i == 0 ? null : visitable.get(i - 1);
            Topic expectedNext = i == visitable.size() - 1 ? null : visitable.get(i + 1);
            assertEquals(expectedPrevious, topics.previous(current), "前のメモがずれています: " + current.getId());
            assertEquals(expectedNext, topics.next(current), "次のメモがずれています: " + current.getId());
        }
    }
}
