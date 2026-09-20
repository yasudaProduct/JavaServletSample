package com.example.servletsample.samples.basic;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * {@code <jsp:useBean>} で使う JavaBean (注文の入力内容)。
 *
 * <p>JSP の {@code <jsp:useBean>} / {@code <jsp:setProperty>} は、
 * <b>次の決まりを守ったクラス</b>しか扱えません。これを JavaBean と呼びます。</p>
 * <ol>
 *   <li><b>public なクラス</b>であること (入れ子のクラスや package private では動きません)</li>
 *   <li><b>引数なしの public なコンストラクタ</b>があること
 *       ({@code <jsp:useBean>} がこれを呼んで生成します)</li>
 *   <li>値の出し入れが <b>{@code getXxx} / {@code setXxx}</b> という名前であること
 *       (boolean は {@code isXxx} でも可)</li>
 * </ol>
 *
 * <h2>プロパティを文字列で持っている理由</h2>
 * <p>数量を {@code int} で宣言すると、{@code <jsp:setProperty property="*">} は
 * 文字列を<b>自動で数値に変換してくれます</b>。便利ですが、
 * {@code ?qty=abc} のように変換できない値が来ると例外になり、
 * 入力エラーではなく <b>500 エラーの画面</b>になってしまいます。</p>
 *
 * <p>そのため、<b>画面から来る値は文字列で受け取り、変換は自分で行います</b>
 * ({@link #getQuantityValue()})。入力チェックの考え方は
 * {@code samples/form} のサンプルで扱っています。</p>
 *
 * <h2>そのまま画面に出してよいプロパティ</h2>
 * <p>{@code <jsp:getProperty>} は値を<b>エスケープせずに</b>書き出します
 * (EL の {@code ${...}} も同じです)。利用者が入力した文字列をそのまま出すと
 * クロスサイトスクリプティングの穴になるため、このクラスでは
 * <b>サーバ側で決めた値から組み立てた</b> {@link #getSummary()} を用意しています。
 * 入力そのものを出すときは {@code fn:escapeXml} を通してください。</p>
 */
public class OrderBean {

    /** 選べる商品 (画面の選択肢とコードの解釈を 1 か所にまとめる)。 */
    private static final Map<String, String> PRODUCTS = createProducts();

    private static Map<String, String> createProducts() {
        Map<String, String> products = new LinkedHashMap<>();
        products.put("P-01", "ボールペン（黒）");
        products.put("P-02", "ノート A5");
        products.put("P-03", "クリアファイル 10 枚組");
        return Collections.unmodifiableMap(products);
    }

    private String productCode = "";
    private String quantity = "";
    private boolean express;
    private String channel = "";

    /**
     * 引数なしのコンストラクタ。
     *
     * <p>{@code <jsp:useBean>} はこのコンストラクタを呼んでインスタンスを作ります。
     * 引数付きのコンストラクタだけを用意すると
     * 「インスタンス化できません」という例外になります。</p>
     */
    public OrderBean() {
    }

    /**
     * 画面の選択肢。
     *
     * <p>{@code static} にしていないのは、<b>JSP から {@code ${order.products}} で
     * 読めるようにする</b>ためです (EL が見るのは getter を持つインスタンスです)。
     * 選択肢とコードの解釈を同じクラスに置いておくと、片方だけ増やす事故が起きません。</p>
     */
    public Map<String, String> getProducts() {
        return PRODUCTS;
    }

    /** 商品コード (画面から来た値そのもの)。 */
    public String getProductCode() {
        return productCode;
    }

    /** 商品コードを設定する ({@code <jsp:setProperty property="*">} から呼ばれる)。 */
    public void setProductCode(String productCode) {
        this.productCode = productCode == null ? "" : productCode.strip();
    }

    /** 数量 (画面から来た文字列のまま)。 */
    public String getQuantity() {
        return quantity;
    }

    /** 数量を設定する (画面の項目名は {@code qty} なので、JSP 側で明示的に対応づけています)。 */
    public void setQuantity(String quantity) {
        this.quantity = quantity == null ? "" : quantity.strip();
    }

    /**
     * お急ぎ便かどうか。
     *
     * <p>boolean のプロパティは {@code Boolean.valueOf(文字列)} で変換されます。
     * つまり <b>{@code "true"} のときだけ true</b> になります。
     * チェックボックスの既定値 {@code "on"} は false になってしまうので、
     * 画面側で {@code value="true"} と書いています。</p>
     */
    public boolean isExpress() {
        return express;
    }

    /** お急ぎ便かどうかを設定する。 */
    public void setExpress(boolean express) {
        this.express = express;
    }

    /** 受付経路 (画面からではなく {@code <jsp:setProperty value="...">} で入れる値)。 */
    public String getChannel() {
        return channel;
    }

    /** 受付経路を設定する。 */
    public void setChannel(String channel) {
        this.channel = channel == null ? "" : channel;
    }

    /** 商品コードに対応する名前。知らないコードなら「（未選択）」。 */
    public String getProductLabel() {
        return PRODUCTS.getOrDefault(productCode, "（未選択）");
    }

    /**
     * 数量を数値で取り出す。数字でなければ {@code 0}、大きすぎれば 99 に丸める。
     *
     * <p>変換を自分で行っているので、{@code ?qty=abc} と書かれても画面は落ちません。</p>
     */
    public int getQuantityValue() {
        try {
            return Math.max(0, Math.min(99, Integer.parseInt(quantity)));
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    /**
     * 画面にそのまま書き出してよい要約。
     *
     * <p>中身は<b>サーバ側で決めた文字列と数値だけ</b>で組み立てています。
     * だから {@code <jsp:getProperty>} (エスケープしない) で出しても安全です。</p>
     */
    public String getSummary() {
        return getProductLabel() + " を " + getQuantityValue() + " 個"
                + "（" + (express ? "お急ぎ便" : "通常便") + "）"
                + (channel.isEmpty() ? "" : " / 受付: " + channel);
    }

    @Override
    public String toString() {
        return "OrderBean{productCode='" + productCode + "', quantity='" + quantity
                + "', express=" + express + "}";
    }
}
