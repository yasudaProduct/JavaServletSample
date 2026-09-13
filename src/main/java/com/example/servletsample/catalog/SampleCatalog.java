package com.example.servletsample.catalog;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * サンプル集のカタログ (目次)。
 *
 * <p>アプリケーション起動時に 1 度だけ作られ、
 * {@code application} スコープの {@code catalog} として JSP から参照されます。</p>
 *
 * <pre>{@code
 * <c:forEach var="sample" items="${catalog.byCategory(category)}"> ... </c:forEach>
 * }</pre>
 *
 * <p>サンプルそのものの定義は {@link SampleDefinitions} にあります。</p>
 */
public final class SampleCatalog {

    /** JSP から参照するときの application スコープ属性名。 */
    public static final String ATTRIBUTE_NAME = "catalog";

    private static final SampleCatalog INSTANCE = new SampleCatalog(SampleDefinitions.define());

    private final List<Sample> samples;
    private final Map<String, Sample> byId;
    private final Map<String, Sample> byPath;

    SampleCatalog(List<Sample> samples) {
        List<Sample> sorted = new ArrayList<>(samples);
        // カテゴリの定義順 → 登録順 に並べる
        sorted.sort(Comparator.comparingInt(sample -> sample.getCategory().ordinal()));
        this.samples = Collections.unmodifiableList(sorted);

        Map<String, Sample> idMap = new LinkedHashMap<>();
        Map<String, Sample> pathMap = new LinkedHashMap<>();
        for (Sample sample : this.samples) {
            Sample duplicated = idMap.put(sample.getId(), sample);
            if (duplicated != null) {
                throw new IllegalStateException("サンプル ID が重複しています: " + sample.getId());
            }
            pathMap.put(sample.getPath(), sample);
        }
        this.byId = Collections.unmodifiableMap(idMap);
        this.byPath = Collections.unmodifiableMap(pathMap);
    }

    public static SampleCatalog getInstance() {
        return INSTANCE;
    }

    /** 全サンプル (準備中を含む)。 */
    public List<Sample> getSamples() {
        return samples;
    }

    /** 閲覧できるサンプルだけ。 */
    public List<Sample> getVisitableSamples() {
        return samples.stream().filter(Sample::isVisitable).collect(Collectors.toList());
    }

    /** 全カテゴリ (サンプルが 0 件のカテゴリも含む)。 */
    public List<Category> getCategories() {
        return Category.all();
    }

    /** 公開中のサンプル件数。 */
    public int getTotalCount() {
        return getVisitableSamples().size();
    }

    /** カテゴリに属するサンプル。 */
    public List<Sample> byCategory(Category category) {
        return samples.stream()
                .filter(sample -> sample.getCategory() == category)
                .collect(Collectors.toList());
    }

    /** カテゴリ ID に属するサンプル。 */
    public List<Sample> byCategoryId(String categoryId) {
        return Category.findById(categoryId).map(this::byCategory).orElseGet(Collections::emptyList);
    }

    /** カテゴリに属するサンプル件数。 */
    public int count(Category category) {
        return byCategory(category).size();
    }

    /** ID でサンプルを取得する。無ければ null。 */
    public Sample byId(String id) {
        return byId.get(id);
    }

    /** パス ({@code /samples/basic/hello-world}) でサンプルを取得する。無ければ null。 */
    public Sample byPath(String path) {
        return byPath.get(path);
    }

    /**
     * キーワード検索。空文字なら全件返す。
     * <p>準備中のサンプルも「予定」として結果に含め、公開中のものを先に並べます。</p>
     */
    public List<Sample> search(String keyword) {
        return samples.stream()
                .filter(sample -> sample.matches(keyword))
                .sorted(Comparator.comparing(Sample::isVisitable).reversed())
                .collect(Collectors.toList());
    }

    /** 同じカテゴリ内での次のサンプル (無ければ null)。 */
    public Sample next(Sample current) {
        return neighbour(current, 1);
    }

    /** 同じカテゴリ内での前のサンプル (無ければ null)。 */
    public Sample previous(Sample current) {
        return neighbour(current, -1);
    }

    private Sample neighbour(Sample current, int offset) {
        if (current == null) {
            return null;
        }
        List<Sample> siblings = byCategory(current.getCategory()).stream()
                .filter(Sample::isVisitable)
                .collect(Collectors.toList());
        int index = siblings.indexOf(current);
        int target = index + offset;
        if (index < 0 || target < 0 || target >= siblings.size()) {
            return null;
        }
        return siblings.get(target);
    }
}
