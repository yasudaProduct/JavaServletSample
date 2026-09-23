package com.example.servletsample.shared;

import java.util.Locale;

/**
 * コードの表記を揃える処理。<b>共通 JAR に置いてよいものの見本</b>です。
 *
 * <p>「前後の空白を落とす」「全角の英数字を半角にする」「英字を大文字に揃える」は、
 * <b>どのアプリでも意味が変わりません</b>。だから共通側に置けます。</p>
 *
 * <p>逆に「社員コードは E + 4 桁」のような<b>業務の決めごとは置きません</b>。
 * それは各アプリの {@link CodeResolver} 実装が持ちます。
 * この線引きは、このリポジトリの {@code common/Validators.java} と同じ考え方です。</p>
 *
 * <h2>判断の軸</h2>
 * <p>「今たまたま同じか」ではなく<b>「変更理由が同じか」</b>で決めます。
 * たまたま同じものを共通化すると、片方の事情で変えたくなったときに
 * 分岐フラグが生えて動かせなくなります。</p>
 */
public final class CodeFormatter {

    /** 全角の英数字の開始 (Ａ = U+FF21 ではなく、！ = U+FF01 から始まる範囲)。 */
    private static final char FULL_WIDTH_START = '！';

    /** 全角の英数字の終了 (～ = U+FF5E)。 */
    private static final char FULL_WIDTH_END = '～';

    /** 全角と半角のずれ幅 (！ U+FF01 - ! U+0021 = 0xFEE0)。 */
    private static final int FULL_TO_HALF_OFFSET = 0xFEE0;

    private CodeFormatter() {
    }

    /**
     * コードの表記を揃える。
     *
     * <p>「　Ｅ１００１　」のようにコピー＆ペーストで入ってきた値を
     * 「E1001」にします。入力チェックの<b>前</b>に通すのが定石です
     * (先に判定すると、全角で入力しただけで弾いてしまいます)。</p>
     *
     * @param code 入力された値。{@code null} なら空文字を返す
     * @return 表記を揃えた値
     */
    public static String normalize(String code) {
        if (code == null) {
            return "";
        }
        StringBuilder normalized = new StringBuilder(code.length());
        for (int i = 0; i < code.length(); i++) {
            char c = code.charAt(i);
            if (c == '　') {
                // 全角スペースは半角スペースにしてから、後でまとめて落とす
                normalized.append(' ');
            } else if (c >= FULL_WIDTH_START && c <= FULL_WIDTH_END) {
                normalized.append((char) (c - FULL_TO_HALF_OFFSET));
            } else {
                normalized.append(c);
            }
        }
        // ロケールを指定しないと、トルコ語環境で i が İ になり判定がずれる
        return normalized.toString().trim().toUpperCase(Locale.ROOT);
    }

    /** 中身があるか (空白だけなら無いものとして扱う)。 */
    public static boolean hasValue(String code) {
        return !normalize(code).isEmpty();
    }
}
