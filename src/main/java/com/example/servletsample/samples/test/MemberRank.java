package com.example.servletsample.samples.test;

/**
 * 会員ランク。ランクごとに割引率が決まっている。
 *
 * <p>「区分によって計算が変わる」業務ルールの置き場所です。
 * if 文で {@code if ("gold".equals(rank))} と書き散らすより、
 * <b>区分そのものに値を持たせておく</b>ほうがテストも読みやすくなります
 * (テストは「ランクを渡して結果を見る」だけで済み、文字列の綴りに悩まされません)。</p>
 */
public enum MemberRank {

    /** 一般 (割引なし)。 */
    REGULAR("一般", 0),

    /** ゴールド会員 (10% 引き)。 */
    GOLD("ゴールド会員", 10);

    private final String label;
    private final int discountPercent;

    MemberRank(String label, int discountPercent) {
        this.label = label;
        this.discountPercent = discountPercent;
    }

    /** 画面に表示する名前。 */
    public String getLabel() {
        return label;
    }

    /** 割引率 (%)。 */
    public int getDiscountPercent() {
        return discountPercent;
    }

    /**
     * 画面から送られてきた文字列をランクに変換する。
     *
     * <p>利用者は何でも送れるので、知らない値・未入力は {@link #REGULAR} として扱います
     * (例外にすると、URL を直接叩かれただけで 500 エラーになってしまいます)。</p>
     */
    public static MemberRank of(String name) {
        if (name != null) {
            for (MemberRank rank : values()) {
                if (rank.name().equalsIgnoreCase(name.trim())) {
                    return rank;
                }
            }
        }
        return REGULAR;
    }
}
