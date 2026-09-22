package com.example.servletsample.samples.test;

import java.io.Serializable;
import java.util.OptionalInt;

import javax.servlet.http.HttpServletRequest;

import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.common.Validators;

/**
 * 注文フォームの入力値。画面から届いた<b>文字列のまま</b>持つ入れ物。
 *
 * <p>数量を {@code int} で持たないのは、エラー時に入力欄へ戻すためです。
 * 「あ」と打たれた値を int にしようとした時点で情報が失われ、
 * 打ち直しをお願いすることになります。</p>
 *
 * <h2>テストの観点</h2>
 * <p>{@link #from(HttpServletRequest)} は Servlet API に触れますが、
 * {@link #validate()} は<b>触れません</b>。受け取る処理と確かめる処理を分けておくと、
 * 入力チェックのテストは {@code new OrderForm(...)} だけで書けます。</p>
 */
public final class OrderForm implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 氏名の最大文字数。 */
    public static final int MAX_NAME_LENGTH = 60;

    private final String customerName;
    private final String itemCode;
    private final String quantity;
    private final String memberRank;

    public OrderForm(String customerName, String itemCode, String quantity, String memberRank) {
        this.customerName = Validators.strip(customerName);
        this.itemCode = Validators.strip(itemCode);
        this.quantity = Validators.strip(quantity);
        this.memberRank = Validators.strip(memberRank);
    }

    /** 初期表示用の空のフォーム。 */
    public static OrderForm empty() {
        return new OrderForm("", "", "1", MemberRank.REGULAR.name());
    }

    /** リクエストパラメータから組み立てる。 */
    public static OrderForm from(HttpServletRequest request) {
        return new OrderForm(
                request.getParameter("customerName"),
                request.getParameter("itemCode"),
                request.getParameter("quantity"),
                request.getParameter("memberRank"));
    }

    /**
     * 入力内容を確かめる。
     *
     * <p>ここでは「形」だけを見ます。在庫が足りるかどうかは
     * DB を見ないと分からないので {@link OrderService} の仕事です。
     * <b>どこまでがフォームの責任か</b>を決めておくと、テストの置き場所も決まります。</p>
     */
    public ValidationErrors validate() {
        ValidationErrors errors = new ValidationErrors();

        errors.addIf(Validators.isBlank(customerName), "customerName", "お名前を入力してください");
        errors.addIf(!Validators.isLengthAtMost(customerName, MAX_NAME_LENGTH),
                "customerName", "お名前は " + MAX_NAME_LENGTH + " 文字以内で入力してください");

        errors.addIf(Validators.isBlank(itemCode), "itemCode", "商品を選んでください");

        if (Validators.isBlank(quantity)) {
            errors.add("quantity", "数量を入力してください");
        } else {
            OptionalInt parsed = Validators.toInt(quantity);
            if (!parsed.isPresent()) {
                // 全角数字「１０」やカンマ入り「1,000」もここで弾かれます
                errors.add("quantity", "数量は半角数字で入力してください");
            } else if (parsed.getAsInt() < 1 || parsed.getAsInt() > OrderPricing.MAX_QUANTITY) {
                errors.add("quantity", "数量は 1 〜 " + OrderPricing.MAX_QUANTITY + " で入力してください");
            }
        }

        return errors;
    }

    /**
     * サービス層へ渡す形に詰め替える。
     *
     * <p>{@link #validate()} を通ったあとに呼ぶ前提です。</p>
     */
    public OrderRequest toRequest() {
        return new OrderRequest(customerName, itemCode,
                Validators.toInt(quantity).orElse(0), MemberRank.of(memberRank));
    }

    public String getCustomerName() {
        return customerName;
    }

    public String getItemCode() {
        return itemCode;
    }

    /** 入力された数量 (文字列のまま。画面に戻すために使う)。 */
    public String getQuantity() {
        return quantity;
    }

    public String getMemberRank() {
        return memberRank;
    }

    @Override
    public String toString() {
        return "OrderForm{" + customerName + ", " + itemCode + ", " + quantity + ", " + memberRank + "}";
    }
}
