package com.example.servletsample.samples.file;

import java.time.LocalDate;
import java.util.List;

/**
 * CSV 出力のサンプルで使うデモ用のデータ。
 *
 * <p>本来はデータベースから取ってくるところですが、
 * このサンプルで見せたいのは<b>「取ってきた値をどう CSV にするか」</b>なので、
 * 固定のデータにしています。</p>
 *
 * <p>大量の行を出すときの書き方は、解説のタブに載せています
 * (すべてをメモリに載せず、1 行取り出しては 1 行書く形にします)。</p>
 */
public final class SalesRecords {

    /**
     * デモ用のデータ。
     *
     * <p>2 件目以降には、CSV が壊れる原因になる値をわざと入れてあります。</p>
     */
    private static final List<SalesRecord> RECORDS = List.of(
            new SalesRecord("SO-1001", LocalDate.of(2026, 4, 1),
                    "株式会社アルファ", "USB ハブ 4 ポート", 3, 8400, ""),

            // 区切り文字 (カンマ) を含む
            new SalesRecord("SO-1002", LocalDate.of(2026, 4, 2),
                    "ベータ商事", "LAN ケーブル, 2m", 10, 12000, "色は青を指定"),

            // ダブルクォートを含む
            new SalesRecord("SO-1003", LocalDate.of(2026, 4, 5),
                    "ガンマ工業", "幅 24\" モニタ", 2, 78000, ""),

            // 改行を含む
            new SalesRecord("SO-1004", LocalDate.of(2026, 4, 7),
                    "デルタ物産", "キーボード（日本語配列）", 5, 24500,
                    "至急\n先方へ連絡済み"),

            // 数式に見える値 (利用者が備考欄に入力したという想定)
            new SalesRecord("SO-1005", LocalDate.of(2026, 4, 8),
                    "イプシロン", "マウスパッド", 20, 9000, "=1+1"),

            // 前後に空白がある
            new SalesRecord("SO-1006", LocalDate.of(2026, 4, 10),
                    "  ゼータ株式会社  ", "webカメラ", 1, 6800, "  要納期確認  "),

            // 負の数 (返品)。数式ガードで文字列にしてしまうと集計できなくなる
            new SalesRecord("SO-1007", LocalDate.of(2026, 4, 12),
                    "イータ販売", "HDMI ケーブル", -2, -3600, "返品"),

            // 区切り文字とダブルクォートの両方
            new SalesRecord("SO-1008", LocalDate.of(2026, 4, 15),
                    "シータ電機", "変換アダプタ (USB-C, \"L 字\")", 8, 15200, "")
    );

    private SalesRecords() {
    }

    /** デモ用のデータ。 */
    public static List<SalesRecord> all() {
        return RECORDS;
    }
}
