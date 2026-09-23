package com.example.servletsample.catalog;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 座学メモの目次。
 *
 * <p>アプリケーション起動時に 1 度だけ作られ、
 * {@code application} スコープの {@code topics} として JSP から参照されます。</p>
 *
 * <pre>{@code
 * <c:forEach var="topic" items="${topics.byGroup(group)}"> ... </c:forEach>
 * }</pre>
 *
 * <p>メモそのものの定義は {@link TopicDefinitions} にあります。</p>
 */
public final class TopicCatalog {

    /** JSP から参照するときの application スコープ属性名。 */
    public static final String ATTRIBUTE_NAME = "topics";

    private static final TopicCatalog INSTANCE = new TopicCatalog(TopicDefinitions.define());

    private final List<Topic> topics;
    private final Map<String, Topic> byId;
    private final Map<String, Topic> byPath;

    TopicCatalog(List<Topic> topics) {
        List<Topic> sorted = new ArrayList<>(topics);
        // グループの定義順 → 登録順 に並べる
        sorted.sort(Comparator.comparingInt(topic -> topic.getGroup().ordinal()));
        this.topics = Collections.unmodifiableList(sorted);

        Map<String, Topic> idMap = new LinkedHashMap<>();
        Map<String, Topic> pathMap = new LinkedHashMap<>();
        for (Topic topic : this.topics) {
            Topic duplicated = idMap.put(topic.getId(), topic);
            if (duplicated != null) {
                throw new IllegalStateException("座学メモの ID が重複しています: " + topic.getId());
            }
            pathMap.put(topic.getPath(), topic);
        }
        this.byId = Collections.unmodifiableMap(idMap);
        this.byPath = Collections.unmodifiableMap(pathMap);
    }

    public static TopicCatalog getInstance() {
        return INSTANCE;
    }

    /** 全メモ (準備中を含む)。 */
    public List<Topic> getTopics() {
        return topics;
    }

    /** 閲覧できるメモだけ。 */
    public List<Topic> getVisitableTopics() {
        return topics.stream().filter(Topic::isVisitable).collect(Collectors.toList());
    }

    /** 全グループ (メモが 0 件のグループも含む)。 */
    public List<TopicGroup> getGroups() {
        return TopicGroup.all();
    }

    /** 公開中のメモ件数。 */
    public int getTotalCount() {
        return getVisitableTopics().size();
    }

    /** グループに属するメモ。 */
    public List<Topic> byGroup(TopicGroup group) {
        return topics.stream()
                .filter(topic -> topic.getGroup() == group)
                .collect(Collectors.toList());
    }

    /** グループ ID に属するメモ。 */
    public List<Topic> byGroupId(String groupId) {
        return TopicGroup.findById(groupId).map(this::byGroup).orElseGet(Collections::emptyList);
    }

    /** グループに属するメモ件数。 */
    public int count(TopicGroup group) {
        return byGroup(group).size();
    }

    /** ID でメモを取得する。無ければ null。 */
    public Topic byId(String id) {
        return byId.get(id);
    }

    /** パス ({@code /topics/request-lifecycle}) でメモを取得する。無ければ null。 */
    public Topic byPath(String path) {
        return byPath.get(path);
    }

    /**
     * キーワード検索。空文字なら全件返す。
     * <p>準備中のメモも結果に含め、公開中のものを先に並べます。</p>
     */
    public List<Topic> search(String keyword) {
        return topics.stream()
                .filter(topic -> topic.matches(keyword))
                .sorted(Comparator.comparing(Topic::isVisitable).reversed())
                .collect(Collectors.toList());
    }

    /** 次のメモ (グループをまたいで、一覧の並び順で探す。無ければ null)。 */
    public Topic next(Topic current) {
        return neighbour(current, 1);
    }

    /** 前のメモ (グループをまたいで、一覧の並び順で探す。無ければ null)。 */
    public Topic previous(Topic current) {
        return neighbour(current, -1);
    }

    private Topic neighbour(Topic current, int offset) {
        if (current == null) {
            return null;
        }
        List<Topic> visitable = getVisitableTopics();
        int index = visitable.indexOf(current);
        int target = index + offset;
        if (index < 0 || target < 0 || target >= visitable.size()) {
            return null;
        }
        return visitable.get(target);
    }
}
