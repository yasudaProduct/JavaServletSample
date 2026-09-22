package com.example.servletsample.samples.test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * 注文サンプルの初期データ (商品マスタ)。
 *
 * <p>本番用 (H2) とテスト用 (メモリ) の両方から使います。
 * 初期データを 1 か所にまとめておくと、
 * 「テストでは通るのに画面では動かない」というズレが起きにくくなります。</p>
 */
final class OrderSampleData {

    private OrderSampleData() {
    }

    /**
     * 初期状態の商品一覧。
     *
     * <p>単価は、金額計算のルールが分かれるところを試せるように選んであります。</p>
     * <ul>
     *   <li>333 円 … 割引・消費税で円未満の端数が出る</li>
     *   <li>1,000 円 … 10 個買うとまとめ買い割引が効く</li>
     *   <li>5,200 円 … 一般会員は送料無料、ゴールド会員は割引で無料ラインを割る</li>
     *   <li>在庫 3 個 … 在庫不足をすぐ試せる</li>
     * </ul>
     */
    static List<Item> initialItems() {
        return new ArrayList<>(Arrays.asList(
                new Item("A-100", "ボールペン（黒・10本入）", 333, 50),
                new Item("B-200", "コピー用紙（A4・1箱）", 1_000, 40),
                new Item("C-300", "オフィスチェア", 5_200, 3),
                new Item("D-400", "モニターアーム", 12_800, 10)));
    }
}
