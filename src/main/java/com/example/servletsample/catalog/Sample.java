package com.example.servletsample.catalog;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

/**
 * サンプル 1 件分の情報。
 *
 * <p>URL と JSP の場所は ID とカテゴリから自動的に決まります。</p>
 * <ul>
 *   <li>URL &nbsp;: {@code /samples/{カテゴリID}/{サンプルID}}</li>
 *   <li>JSP &nbsp;: {@code /WEB-INF/views/samples/{カテゴリID}/{サンプルID}.jsp}</li>
 * </ul>
 *
 * <p>登録は {@link SampleDefinitions} で行います。</p>
 */
public final class Sample {

    private final String id;
    private final Category category;
    private final String title;
    private final String summary;
    private final SampleStatus status;
    private final List<String> tags;
    private final List<SourceFile> sources;
    private final String path;
    private final String viewPath;

    private Sample(Builder builder) {
        this.id = builder.id;
        this.category = builder.category;
        this.title = builder.title;
        this.summary = builder.summary;
        this.status = builder.status;
        this.tags = Collections.unmodifiableList(new ArrayList<>(builder.tags));
        this.path = builder.path != null ? builder.path : "/samples/" + builder.category.getId() + "/" + builder.id;
        this.viewPath = builder.viewPath != null ? builder.viewPath
                : "/WEB-INF/views/samples/" + builder.category.getId() + "/" + builder.id + ".jsp";

        List<SourceFile> allSources = new ArrayList<>(builder.sources);
        // 画面そのものの JSP は必ずソース一覧に載せる (明示登録されていなければ末尾に追加)
        boolean viewRegistered = allSources.stream().anyMatch(source -> source.getPath().equals(this.viewPath));
        if (!viewRegistered && this.status.isVisitable()) {
            allSources.add(SourceFile.jsp(this.viewPath));
        }
        this.sources = Collections.unmodifiableList(allSources);
    }

    /** サンプル定義を組み立てる。{@code Sample.builder("hello-world", Category.BASIC)} */
    public static Builder builder(String id, Category category) {
        return new Builder(id, category);
    }

    /** URL に使う識別子。 */
    public String getId() {
        return id;
    }

    public Category getCategory() {
        return category;
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

    /** 絞り込み・検索に使うキーワード。 */
    public List<String> getTags() {
        return tags;
    }

    /** ページに表示するソースファイル一覧。 */
    public List<SourceFile> getSources() {
        return sources;
    }

    /** コンテキストルートからのパス。例: {@code /samples/basic/hello-world} */
    public String getPath() {
        return path;
    }

    /** 転送先 JSP。例: {@code /WEB-INF/views/samples/basic/hello-world.jsp} */
    public String getViewPath() {
        return viewPath;
    }

    /** 閲覧できるサンプルかどうか (PLANNED はリンクを張らない)。 */
    public boolean isVisitable() {
        return status.isVisitable();
    }

    /** 検索キーワードに一致するか。 */
    public boolean matches(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return true;
        }
        String lower = keyword.trim().toLowerCase();
        if (id.toLowerCase().contains(lower)
                || title.toLowerCase().contains(lower)
                || summary.toLowerCase().contains(lower)
                || category.getLabel().toLowerCase().contains(lower)) {
            return true;
        }
        return tags.stream().anyMatch(tag -> tag.toLowerCase().contains(lower));
    }

    @Override
    public String toString() {
        return category.getId() + "/" + id;
    }

    /** {@link Sample} の組み立て用ビルダー。 */
    public static final class Builder {

        private final String id;
        private final Category category;
        private String title;
        private String summary = "";
        private SampleStatus status = SampleStatus.READY;
        private final List<String> tags = new ArrayList<>();
        private final List<SourceFile> sources = new ArrayList<>();
        private String path;
        private String viewPath;

        private Builder(String id, Category category) {
            this.id = Objects.requireNonNull(id, "id");
            this.category = Objects.requireNonNull(category, "category");
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

        public Builder tags(String... tags) {
            this.tags.addAll(Arrays.asList(tags));
            return this;
        }

        /** 表示したいソースファイルを追加する (登録した順に表示される)。 */
        public Builder source(SourceFile source) {
            this.sources.add(source);
            return this;
        }

        /** Java クラスのソースを追加する。 */
        public Builder source(Class<?> type) {
            return source(SourceFile.of(type));
        }

        /** URL を既定 ({@code /samples/カテゴリ/ID}) から変更したい場合に指定する。 */
        public Builder path(String path) {
            this.path = path;
            return this;
        }

        /** 転送先 JSP を既定から変更したい場合に指定する。 */
        public Builder viewPath(String viewPath) {
            this.viewPath = viewPath;
            return this;
        }

        public Sample build() {
            return new Sample(this);
        }
    }
}
