package com.example.servletsample.catalog;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * サンプルの分類。
 *
 * <p>サイトのサイドバー・トップページのカテゴリカードは、この列挙型の定義順に並びます。
 * カテゴリを増やしたいときはここに 1 行追加してください。</p>
 */
public enum Category {

    BASIC("basic", "基本", "Servlet と JSP の基本的な流れ", "journal-code"),
    DESIGN("design", "画面デザイン", "Bootstrap 4 を使った画面の組み立て", "palette"),
    ACCESSIBILITY("a11y", "アクセシビリティ", "スマホでの入力、キーボード操作、読み上げへの配慮", "universal-access"),
    FORM("form", "フォーム・入力", "入力・検証・確認画面といった入力まわり", "input-cursor-text"),
    LIST("list", "一覧・検索", "一覧・検索・ページング、マスタの登録・更新・削除", "table"),
    SESSION("session", "セッション・認証", "ログイン、スコープ、権限チェック", "shield-lock"),
    FILE("file", "ファイル", "アップロード、ダウンロード、CSV / PDF 出力", "file-earmark-arrow-up"),
    AJAX("ajax", "非同期通信", "Ajax、JSON API との連携", "arrow-repeat"),
    SHARED("shared", "複数サーバー・共通化",
            "サーバーを分けたときの共通処理の切り出し方とビルド", "diagram-3"),
    ADVANCED("advanced", "応用・その他", "フィルタ、エラー処理、国際化など", "gear"),
    TESTING("test", "テスト", "JUnit 5 で単体テストを書く（計算・サービス・Servlet）", "check-circle");

    private final String id;
    private final String label;
    private final String description;
    private final String icon;

    Category(String id, String label, String description, String icon) {
        this.id = id;
        this.label = label;
        this.description = description;
        this.icon = icon;
    }

    /** URL に使う識別子。例: {@code /categories/basic} */
    public String getId() {
        return id;
    }

    /** 画面に表示する名前。 */
    public String getLabel() {
        return label;
    }

    /** カテゴリカードに表示する説明文。 */
    public String getDescription() {
        return description;
    }

    /** アイコン名 (WEB-INF/tags/icon.tag が解釈する)。 */
    public String getIcon() {
        return icon;
    }

    /** 定義順のカテゴリ一覧。 */
    public static List<Category> all() {
        return Arrays.asList(values());
    }

    /** ID からカテゴリを探す。見つからなければ空。 */
    public static Optional<Category> findById(String id) {
        return Arrays.stream(values())
                .filter(category -> category.id.equalsIgnoreCase(id))
                .findFirst();
    }
}
