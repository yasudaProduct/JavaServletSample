package com.example.servletsample.samples.test;

/**
 * 注文を受け付けた結果。成功なら受注内容を、失敗なら理由を持つ。
 *
 * <p><b>在庫不足を例外にしていない</b>のがポイントです。
 * 在庫不足は「起こりうる業務上の結果」であって、プログラムの誤りではありません。
 * 例外にすると呼び出し側が try-catch だらけになり、
 * 「例外を投げること」をテストするはめになります。
 * 戻り値で表すと、テストは {@code assertFalse(result.isSuccess())} と
 * メッセージの確認だけで済みます。</p>
 *
 * <p>逆に、あり得ない引数 ({@link OrderPricing#calculate} の数量 0 など) は例外のままにします。
 * 「業務として起こること」は戻り値、「プログラムの誤り」は例外、という使い分けです。</p>
 */
public final class OrderResult {

    private final boolean success;
    private final String message;
    private final OrderEntry order;

    private OrderResult(boolean success, String message, OrderEntry order) {
        this.success = success;
        this.message = message;
        this.order = order;
    }

    /** 受け付けた。 */
    public static OrderResult success(OrderEntry order) {
        return new OrderResult(true, "注文を受け付けました", order);
    }

    /** 受け付けられなかった (理由付き)。 */
    public static OrderResult failure(String message) {
        return new OrderResult(false, message, null);
    }

    public boolean isSuccess() {
        return success;
    }

    /** 画面に出すメッセージ。 */
    public String getMessage() {
        return message;
    }

    /** 受け付けた注文 (失敗時は null)。 */
    public OrderEntry getOrder() {
        return order;
    }

    @Override
    public String toString() {
        return (success ? "成功: " : "失敗: ") + message;
    }
}
