package com.example.servletsample.catalog;

/**
 * サンプルの公開状態。
 *
 * <p>「これから作る予定のサンプル」もカタログに登録しておけるようにするための区分です。
 * {@link #READY} 以外は一覧にグレー表示され、リンクは張られません。</p>
 */
public enum SampleStatus {

    /** 公開中。閲覧できる。 */
    READY("公開中", "success"),

    /** 作成途中。動くが未完成。 */
    WIP("作成中", "warning"),

    /** これから作る予定。ページはまだ無い。 */
    PLANNED("準備中", "secondary");

    private final String label;
    private final String variant;

    SampleStatus(String label, String variant) {
        this.label = label;
        this.variant = variant;
    }

    /** 画面に表示するラベル。 */
    public String getLabel() {
        return label;
    }

    /** Bootstrap のバッジ色 (badge-success など)。 */
    public String getVariant() {
        return variant;
    }

    /** 閲覧可能かどうか。 */
    public boolean isVisitable() {
        return this != PLANNED;
    }
}
