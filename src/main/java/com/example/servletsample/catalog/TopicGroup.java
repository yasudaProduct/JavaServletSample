package com.example.servletsample.catalog;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * 座学メモ ({@link Topic}) の分類。
 *
 * <p>座学メモの一覧ページとサイドバーは、この列挙型の定義順に並びます。</p>
 */
public enum TopicGroup {

    MECHANISM("mechanism", "動く仕組み",
            "リクエストが届いてから返るまで、コンテナが裏で何をしているか", "hdd-stack"),

    PRACTICE("practice", "設計と作法",
            "どこに何を書くか。あとから読む人・直す人が困らない形にするための判断", "lightbulb"),

    OPERATION("operation", "本番とこの先",
            "localhost では起きないこと。運用に乗せるときに要ること、次に学ぶこと", "shield-lock");

    private final String id;
    private final String label;
    private final String description;
    private final String icon;

    TopicGroup(String id, String label, String description, String icon) {
        this.id = id;
        this.label = label;
        this.description = description;
        this.icon = icon;
    }

    /** URL のアンカーなどに使う識別子。例: {@code /topics#mechanism} */
    public String getId() {
        return id;
    }

    /** 画面に表示する名前。 */
    public String getLabel() {
        return label;
    }

    /** 一覧に表示する説明文。 */
    public String getDescription() {
        return description;
    }

    /** アイコン名 (WEB-INF/tags/icon.tag が解釈する)。 */
    public String getIcon() {
        return icon;
    }

    /** 定義順のグループ一覧。 */
    public static List<TopicGroup> all() {
        return Arrays.asList(values());
    }

    /** ID からグループを探す。見つからなければ空。 */
    public static Optional<TopicGroup> findById(String id) {
        return Arrays.stream(values())
                .filter(group -> group.id.equalsIgnoreCase(id))
                .findFirst();
    }
}
