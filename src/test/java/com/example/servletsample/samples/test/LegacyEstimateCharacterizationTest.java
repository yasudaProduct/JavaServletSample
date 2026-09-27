package com.example.servletsample.samples.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * 【サンプル】仕様化テスト (Characterization Test) を 1 件ずつ書いたもの。
 *
 * <p>テスト対象は「古い作り」の {@link LegacyEstimateServlet} です。
 * 仕様書はありません。このテストの期待値は、仕様から考えたものではなく、
 * <b>今のコードが実際に返した値を書き写したもの</b>です。</p>
 *
 * <h2>書き方</h2>
 * <ol>
 *   <li>期待値にわざと適当な値 (0 など) を書いて実行する</li>
 *   <li>失敗メッセージ {@code expected: <0> but was: <800>} の「実際の値」を書き写す</li>
 *   <li>もう一度実行して通ることを確かめる</li>
 * </ol>
 * <p>だから、このテストが通っても「正しい」とは限りません。「前と同じ」という意味です。</p>
 *
 * <h2>おかしな動きを見つけたら</h2>
 * <p>その場では直さず、<b>今の動きのまま記録して印を付けます</b> (下の {@code 要確認})。
 * 利用者がその動きを前提にしているかもしれませんし、
 * 直すかどうかを決めるのは業務の担当者だからです。</p>
 *
 * <p>本番のコードには一切手を入れていません。偽の request / response で
 * Servlet を動かし、画面に渡された値を見ているだけです ({@link EstimateRequests})。</p>
 */
class LegacyEstimateCharacterizationTest {

    private final LegacyEstimateServlet servlet = new LegacyEstimateServlet();

    // ======================================================================
    // 送料の料金表
    // ======================================================================

    @Nested
    @DisplayName("送料の料金表")
    class ShippingTable {

        @Test
        @DisplayName("東京・2,000g・3,000 円・一般 → 送料 800 円、請求 4,180 円")
        void tokyoUpTo2kg() throws Exception {
            // 最初は assertEquals(0, ...) と書いて実行し、
            // 「expected: <0> but was: <800>」の 800 を書き写した。
            Map<String, Object> result = estimate("東京", "3000", "1", "2000", null);

            assertEquals(3000, result.get("amount"));
            assertEquals(800, result.get("ship"));
            assertEquals(0, result.get("discount"));
            assertEquals(380, result.get("tax"));
            assertEquals(4180, result.get("total"));
        }

        @Test
        @DisplayName("東京は 2,001g から送料 1,100 円")
        void tokyoOver2kg() throws Exception {
            // 境界は前後を両方記録する (2,000g は上のテスト)
            assertEquals(1100, estimate("東京", "3000", "1", "2001", null).get("ship"));
        }

        @Test
        @DisplayName("重さは 1 個の重さ × 数量で決まる")
        void weightIsMultipliedByQuantity() throws Exception {
            // 1,500g × 2 個 = 3,000g
            assertEquals(1100, estimate("東京", "1000", "2", "1500", null).get("ship"));
        }

        @Test
        @DisplayName("要確認: 5,000g ちょうどは、東京 1,100 円 / 北海道 2,500 円（境界が揃っていない）")
        void boundaryAt5kgDiffersByRegion() throws Exception {
            // 本州は <= 5000、北海道・沖縄は < 5000 で判定している。
            // 仕様なのか書き間違いなのか分からないので、今の動きのまま記録する。
            // TODO: 業務担当に確認する
            assertEquals(1100, estimate("東京", "3000", "1", "5000", null).get("ship"));
            assertEquals(2500, estimate("北海道", "3000", "1", "5000", null).get("ship"));
        }

        @Test
        @DisplayName("要確認: 都道府県が空だと、東京と同じ料金になる")
        void blankPrefectureIsTreatedAsHonshu() throws Exception {
            assertEquals(800, estimate("", "3000", "1", "2000", null).get("ship"));
        }
    }

    // ======================================================================
    // 送料無料
    // ======================================================================

    @Nested
    @DisplayName("送料無料")
    class FreeShipping {

        @Test
        @DisplayName("会員は 5,000 円ちょうどで送料無料になり、5% 割引される")
        void memberFreeFrom5000() throws Exception {
            Map<String, Object> result = estimate("東京", "5000", "1", "2000", "1");

            assertEquals(0, result.get("ship"));
            assertEquals(250, result.get("discount"));
            assertEquals(475, result.get("tax"));
            assertEquals(5225, result.get("total"));
        }

        @Test
        @DisplayName("要確認: 一般は 10,000 円ちょうどでは送料が掛かり、10,001 円から無料")
        void regularFreeOver10000() throws Exception {
            // 会員は「以上」、一般は「超える」。揃っていないが今の動きのまま記録する。
            assertEquals(800, estimate("東京", "10000", "1", "2000", null).get("ship"));
            assertEquals(0, estimate("東京", "10001", "1", "2000", null).get("ship"));
        }

        @Test
        @DisplayName("要確認: 会員かどうかは member=1 のときだけ。true や on は一般扱い")
        void memberFlagMustBeOne() throws Exception {
            assertEquals(0, estimate("東京", "5000", "1", "2000", "true").get("discount"));
            assertEquals(0, estimate("東京", "5000", "1", "2000", "on").get("discount"));
        }

        @Test
        @DisplayName("要確認: 沖縄は送料無料にならず 1,200 円。重い荷物ではかえって安くなる")
        void okinawaIsNeverFree() throws Exception {
            // 「2019/04 改定 沖縄は送料無料の対象外」というコメントで後から足された処理。
            // 無料の条件を満たすと送料が 1,200 円に「戻る」ため、
            // 3,000g (本来 1,800 円) では条件を満たした方が安くなる。
            assertEquals(1200, estimate("沖縄", "5000", "1", "2000", "1").get("ship"));
            assertEquals(1800, estimate("沖縄", "4999", "1", "3000", "1").get("ship"), "無料の条件を満たさない");
            assertEquals(1200, estimate("沖縄", "5000", "1", "3000", "1").get("ship"), "満たすと安くなる");
        }
    }

    // ======================================================================
    // 変な入力
    // ======================================================================

    @Nested
    @DisplayName("変な入力")
    class OddInput {

        @Test
        @DisplayName("要確認: 数量 0 でも送料と消費税だけ請求される（880 円）")
        void zeroQuantityStillCharged() throws Exception {
            Map<String, Object> result = estimate("東京", "3000", "0", "2000", null);

            assertEquals(0, result.get("amount"));
            assertEquals(800, result.get("ship"));
            assertEquals(880, result.get("total"));
        }

        @Test
        @DisplayName("要確認: 数量がマイナスだと、請求金額もマイナスになる")
        void negativeQuantityGivesNegativeTotal() throws Exception {
            assertEquals(-2420, estimate("東京", "3000", "-1", "2000", null).get("total"));
        }

        @Test
        @DisplayName("全角数字は、半角と同じ数値として受け付けられる")
        void fullWidthDigitsAreAccepted() throws Exception {
            // 最初は「全角なら例外になるはず」と思って assertThrows で書いたところ、落ちた。
            // Integer.parseInt は全角の数字も数字として読む。
            // 思い込みではなく、実際の動きを記録するのが仕様化テストです。
            assertEquals(4180, estimate("東京", "３０００", "１", "２０００", null).get("total"));
        }

        @Test
        @DisplayName("カンマ付きの金額は例外になる（画面では 500 エラー）")
        void commaSeparatedPriceThrows() {
            // 例外も「今の動き」の 1 つとして記録する。
            // 直した結果、エラーメッセージを出すようになったら、このテストが落ちて気付ける。
            assertThrows(NumberFormatException.class,
                    () -> estimate("東京", "3,000", "1", "2000", null));
        }

        @Test
        @DisplayName("都道府県が送られてこないと例外になる")
        void missingPrefectureThrows() {
            assertThrows(NullPointerException.class,
                    () -> estimate(null, "3000", "1", "2000", null));
        }
    }

    // ======================================================================
    // 毎回変わる値
    // ======================================================================

    @Test
    @DisplayName("見積番号は EST- と 14 桁の日時（値は毎回変わるので形だけ記録する）")
    void estimateNumberFormat() throws Exception {
        // 見積番号には現在時刻が入る。このクラスは時計を外から受け取らないので止められない。
        // 値そのものではなく「形」を記録する。
        String estimateNo = (String) estimate("東京", "3000", "1", "2000", null).get("estimateNo");

        assertTrue(estimateNo.matches("EST-\\d{14}"), estimateNo);
    }

    private Map<String, Object> estimate(String pref, String price, String qty, String weight,
                                         String member) throws Exception {
        return EstimateRequests.post(servlet, pref, price, qty, weight, member);
    }
}
