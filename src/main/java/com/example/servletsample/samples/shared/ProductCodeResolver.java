package com.example.servletsample.samples.shared;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.regex.Pattern;

import com.example.servletsample.shared.CodeResolver;

/**
 * 【サンプル】商品コードを商品名に引き当てる実装。こちらも<b>アプリ側</b>です。
 *
 * <p>{@link EmployeeCodeResolver} と並べて見ると、
 * <b>共通側を一切変えずに実装を増やせる</b>ことが分かります。
 * これがインタフェースで切り離す一番の効き目です。</p>
 *
 * <p>もし共通ライブラリに直接「コードを名前に変える処理」を書いていたら、
 * 商品コードを足すたびに共通ライブラリの版を上げ、
 * <b>それを使っているすべてのアプリを再ビルドして確認する</b>ことになります。</p>
 */
public class ProductCodeResolver implements CodeResolver {

    /** 商品コードの形。P + 3 桁。社員コードとは別の決めごと。 */
    private static final Pattern FORM = Pattern.compile("^P[0-9]{3}$");

    /** 商品マスタの代わり (固定データ)。 */
    private static final Map<String, String> PRODUCTS = new LinkedHashMap<>();

    static {
        PRODUCTS.put("P001", "A4 コピー用紙 (500 枚)");
        PRODUCTS.put("P002", "ボールペン 黒 (10 本)");
        PRODUCTS.put("P003", "クリアファイル (20 枚)");
        PRODUCTS.put("P010", "ノート PC スタンド");
        PRODUCTS.put("P011", "USB-C ハブ");
    }

    public ProductCodeResolver() {
    }

    @Override
    public String name() {
        return "商品コード";
    }

    @Override
    public String description() {
        return "P + 3 桁。商品マスタから商品名を引き当てます。";
    }

    @Override
    public boolean accepts(String code) {
        return code != null && FORM.matcher(code).matches();
    }

    @Override
    public String resolve(String code) {
        if (!accepts(code)) {
            return null;
        }
        return PRODUCTS.get(code);
    }

    /** 画面に手本として出す一覧。 */
    public static Map<String, String> all() {
        return PRODUCTS;
    }
}
