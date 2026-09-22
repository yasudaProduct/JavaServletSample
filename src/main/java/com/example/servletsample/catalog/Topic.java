package com.example.servletsample.catalog;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

/**
 * 座学メモ 1 件分の情報。
 *
 * <p>座学メモは「動くサンプルを置きにくいが、知らないと詰まる話」をまとめた読み物です。
 * サンプル ({@link Sample}) と違って<b>デモもソースコードも持たない</b>ので、
 * ページは本文 1 つだけで構成します。</p>
 *
 * <p>URL と JSP の場所は ID から自動的に決まります。</p>
 * <ul>
 *   <li>URL &nbsp;: {@code /topics/{ID}}</li>
 *   <li>JSP &nbsp;: {@code /WEB-INF/views/topics/{ID}.jsp}</li>
 * </ul>
 *
 * <p>登録は {@link TopicDefinitions} で行います。</p>
 */
public final class Topic {

    /** 読了時間の目安 (分) の既定値。 */
    private static final int DEFAULT_READING_MINUTES = 5;

    private final String id;
    private final TopicGroup group;
    private final String title;
    private final String summary;
    private final SampleStatus status;
    private final int readingMinutes;
    private final List<String> tags;
    private final List<String> relatedSampleIds;
    private final String path;
    private final String viewPath;

    private Topic(Builder builder) {
        this.id = builder.id;
        this.group = builder.group;
        this.title = builder.title;
        this.summary = builder.summary;
        this.status = builder.status;
        this.readingMinutes = builder.readingMinutes;
        this.tags = Collections.unmodifiableList(new ArrayList<>(builder.tags));
        this.relatedSampleIds = Collections.unmodifiableList(new ArrayList<>(builder.relatedSampleIds));
        this.path = "/topics/" + builder.id;
        this.viewPath = "/WEB-INF/views/topics/" + builder.id + ".jsp";
    }

    /** 座学メモの定義を組み立てる。{@code Topic.builder("request-lifecycle", TopicGroup.MECHANISM)} */
    public static Builder builder(String id, TopicGroup group) {
        return new Builder(id, group);
    }

    /** URL に使う識別子。 */
    public String getId() {
        return id;
    }

    public TopicGroup getGroup() {
        return group;
    }

    /** 画面に表示するタイトル。 */
    public String getTitle() {
        return title;
    }

    /** 一覧に表示する 1 〜 2 行の説明。 */
    public String getSummary() {
        return summary;
    }

    public SampleStatus getStatus() {
        return status;
    }

    /** 読了時間の目安 (分)。 */
    public int getReadingMinutes() {
        return readingMinutes;
    }

    /** 絞り込み・検索に使うキーワード。 */
    public List<String> getTags() {
        return tags;
    }

    /** 本文の最後に並べる、関連するサンプルの ID。 */
    public List<String> getRelatedSampleIds() {
        return relatedSampleIds;
    }

    /** 関連するサンプル (カタログに無い ID は黙って飛ばす)。 */
    public List<Sample> getRelatedSamples() {
        List<Sample> related = new ArrayList<>();
        for (String sampleId : relatedSampleIds) {
            Sample sample = SampleCatalog.getInstance().byId(sampleId);
            if (sample != null && sample.isVisitable()) {
                related.add(sample);
            }
        }
        return related;
    }

    /** コンテキストルートからのパス。例: {@code /topics/request-lifecycle} */
    public String getPath() {
        return path;
    }

    /** 転送先 JSP。例: {@code /WEB-INF/views/topics/request-lifecycle.jsp} */
    public String getViewPath() {
        return viewPath;
    }

    /** 閲覧できる座学メモかどうか (PLANNED はリンクを張らない)。 */
    public boolean isVisitable() {
        return status.isVisitable();
    }

    /** キーワードに一致するか。 */
    public boolean matches(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return true;
        }
        String lower = keyword.trim().toLowerCase();
        if (id.toLowerCase().contains(lower)
                || title.toLowerCase().contains(lower)
                || summary.toLowerCase().contains(lower)
                || group.getLabel().toLowerCase().contains(lower)) {
            return true;
        }
        return tags.stream().anyMatch(tag -> tag.toLowerCase().contains(lower));
    }

    @Override
    public String toString() {
        return "topics/" + id;
    }

    /** {@link Topic} の組み立て用ビルダー。 */
    public static final class Builder {

        private final String id;
        private final TopicGroup group;
        private String title;
        private String summary = "";
        private SampleStatus status = SampleStatus.READY;
        private int readingMinutes = DEFAULT_READING_MINUTES;
        private final List<String> tags = new ArrayList<>();
        private final List<String> relatedSampleIds = new ArrayList<>();

        private Builder(String id, TopicGroup group) {
            this.id = Objects.requireNonNull(id, "id");
            this.group = Objects.requireNonNull(group, "group");
            this.title = id;
        }

        public Builder title(String title) {
            this.title = title;
            return this;
        }

        public Builder summary(String summary) {
            this.summary = summary;
            return this;
        }

        public Builder status(SampleStatus status) {
            this.status = status;
            return this;
        }

        /** 読了時間の目安 (分)。 */
        public Builder readingMinutes(int readingMinutes) {
            this.readingMinutes = readingMinutes;
            return this;
        }

        public Builder tags(String... tags) {
            this.tags.addAll(Arrays.asList(tags));
            return this;
        }

        /** 読んだあとに触ってほしいサンプルの ID を並べる。 */
        public Builder relatedSamples(String... sampleIds) {
            this.relatedSampleIds.addAll(Arrays.asList(sampleIds));
            return this;
        }

        public Topic build() {
            return new Topic(this);
        }
    }
}
