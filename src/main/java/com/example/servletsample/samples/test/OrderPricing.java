package com.example.servletsample.samples.test;

/**
 * 【サンプル】注文金額の計算ルール。単体テストの練習台になる「計算ロジック層」。
 *
 * <h2>計算ルール</h2>
 * <ol>
 *   <li>小計 = 単価 × 数量 (税抜)</li>
 *   <li>まとめ買い割引 : 数量が {@value #BULK_QUANTITY} 個以上なら小計の {@value #BULK_DISCOUNT_PERCENT}%</li>
 *   <li>会員割引 : まとめ買い割引を引いたあとの額に、会員ランクの割引率を掛ける</li>
 *   <li>送料 : 割引後の商品代金が {@value #FREE_SHIPPING_THRESHOLD} 円以上なら無料、未満なら {@value #SHIPPING_FEE} 円</li>
 *   <li>消費税 : (割引後の商品代金 + 送料) × {@value #TAX_PERCENT}%</li>
 *   <li>請求金額 = 割引後の商品代金 + 送料 + 消費税</li>
 * </ol>
 * <p>割引額・消費税の円未満は<b>切り捨て</b>ます。</p>
 *
 * <h2>なぜこの形なのか (テストの観点)</h2>
 * <ul>
 *   <li><b>Servlet から切り離してある</b> : {@code HttpServletRequest} も DB も出てきません。
 *       だから Tomcat を起動せずに {@code new} すら要らず、メソッドを呼ぶだけでテストできます。</li>
 *   <li><b>戻り値で答える</b> : 画面に書き出したりログに出したりせず、
 *       {@link OrderAmount} を返します。「呼んで、返ってきた値を確かめる」形が一番テストしやすい形です。</li>
 *   <li><b>ルールの数値を定数にしてある</b> : テスト側でも同じ定数を使えるので、
 *       送料が 600 円から変わってもテストの修正が 1 か所で済みます。
 *       ただし<b>期待値まで定数で計算してしまうと、実装と同じ式を書くことになり</b>
 *       テストの意味が無くなります。境界値のテストでは実際の数字を直接書きます。</li>
 * </ul>
 *
 * <p>テストは {@code src/test/java/com/example/servletsample/samples/test/OrderPricingTest.java} です
 * (このページの「ソースコード」タブで並べて読めます)。</p>
 */
public final class OrderPricing {

    /** まとめ買い割引が効き始める数量。 */
    public static final int BULK_QUANTITY = 10;

    /** まとめ買い割引の割引率 (%)。 */
    public static final int BULK_DISCOUNT_PERCENT = 5;

    /** 送料が無料になる金額 (割引後・税抜)。 */
    public static final int FREE_SHIPPING_THRESHOLD = 5_000;

    /** 送料 (税抜)。 */
    public static final int SHIPPING_FEE = 600;

    /** 消費税率 (%)。 */
    public static final int TAX_PERCENT = 10;

    /** 1 回の注文で指定できる最大数量。 */
    public static final int MAX_QUANTITY = 99;

    /** 扱える単価の上限。 */
    public static final int MAX_UNIT_PRICE = 1_000_000;

    private OrderPricing() {
    }

    /**
     * 注文 1 件分の金額を計算する。
     *
     * @param unitPrice 単価 (税抜、0 〜 {@value #MAX_UNIT_PRICE} 円)
     * @param quantity  数量 (1 〜 {@value #MAX_QUANTITY} 個)
     * @param rank      会員ランク (null は {@link MemberRank#REGULAR} として扱う)
     * @return 金額の内訳
     * @throws IllegalArgumentException 単価・数量が扱える範囲の外のとき
     */
    public static OrderAmount calculate(int unitPrice, int quantity, MemberRank rank) {
        // 【引数の検査】
        // ここは「プログラムの間違い」を知らせるための検査なので例外にします。
        // 一方、利用者の打ち間違い (数量に "あ" と入れた等) は例外ではなく
        // 画面にメッセージを出して直してもらうもの → OrderForm / OrderService 側の仕事です。
        // この線引きがあいまいだと、利用者の打ち間違いで 500 エラーの画面が出ます。
        if (unitPrice < 0 || unitPrice > MAX_UNIT_PRICE) {
            throw new IllegalArgumentException("単価が範囲外です: " + unitPrice);
        }
        if (quantity < 1 || quantity > MAX_QUANTITY) {
            throw new IllegalArgumentException("数量が範囲外です: " + quantity);
        }

        MemberRank effectiveRank = (rank == null) ? MemberRank.REGULAR : rank;

        int subtotal = unitPrice * quantity;

        int bulkDiscount = (quantity >= BULK_QUANTITY) ? percentOf(subtotal, BULK_DISCOUNT_PERCENT) : 0;

        // 会員割引は「まとめ買い割引を引いたあと」の額に掛ける。
        // どちらを先に引くかで金額が変わるので、仕様として決めておく必要があります
        // (テストでは、両方の割引が効く組み合わせを 1 件は必ず用意します)。
        int afterBulk = subtotal - bulkDiscount;
        int memberDiscount = percentOf(afterBulk, effectiveRank.getDiscountPercent());

        int discountedSubtotal = afterBulk - memberDiscount;

        // 送料の判定は「割引後」の金額で行う。
        // 割引前で判定すると、割引したせいで無料ラインを割った注文が無料のままになります。
        int shippingFee = (discountedSubtotal >= FREE_SHIPPING_THRESHOLD) ? 0 : SHIPPING_FEE;

        int tax = percentOf(discountedSubtotal + shippingFee, TAX_PERCENT);

        return new OrderAmount(subtotal, bulkDiscount, memberDiscount, shippingFee, tax);
    }

    /**
     * {@code amount} の {@code percent}% を、円未満切り捨てで求める。
     *
     * <p>{@code (int) (amount * percent / 100.0)} と小数で計算すると、
     * 丸め誤差で 1 円ずれることがあります (例: 0.1 は 2 進数で正確に表せません)。
     * 金額は整数のまま計算するのが安全です。</p>
     */
    private static int percentOf(int amount, int percent) {
        return (int) ((long) amount * percent / 100);
    }
}
