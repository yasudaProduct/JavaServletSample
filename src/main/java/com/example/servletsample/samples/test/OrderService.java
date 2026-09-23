package com.example.servletsample.samples.test;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

/**
 * 【サンプル】注文を受け付けるサービス層。
 *
 * <p>やることは 3 つだけです。</p>
 * <ol>
 *   <li>商品を調べ、在庫が足りるか確かめる</li>
 *   <li>{@link OrderPricing} に金額を計算してもらう</li>
 *   <li>在庫を減らして注文を保存し、受注番号を返す</li>
 * </ol>
 *
 * <h2>テストのために意識してあること</h2>
 * <ul>
 *   <li><b>依存はコンストラクタで受け取る</b> … DB もカレンダーも {@code new} しません。
 *       外から渡してもらうので、テストでは偽物を渡せます。</li>
 *   <li><b>時計を外から渡す</b> … {@code LocalDateTime.now()} を直接呼ぶと、
 *       受注番号や受付日時が実行するたびに変わり、{@code assertEquals} が書けません。
 *       {@link Clock} を受け取る形にしておけば、テストでは
 *       {@code Clock.fixed(...)} で時刻を止められます。</li>
 *   <li><b>画面の都合を持ち込まない</b> … 引数は {@link OrderRequest}、戻り値は {@link OrderResult}。
 *       {@code HttpServletRequest} は出てきません。</li>
 * </ul>
 */
public class OrderService {

    private static final DateTimeFormatter ORDER_NUMBER_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    private final OrderRepository repository;
    private final Clock clock;

    /**
     * 使うものを外から受け取る。
     *
     * @param repository データ置き場 (本番は H2、テストはメモリ上の偽物)
     * @param clock      時計 (本番はシステム時刻、テストは固定した時刻)
     */
    public OrderService(OrderRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    /** 注文できる商品の一覧。 */
    public List<Item> findItems() {
        return repository.findItems();
    }

    /** 直近の注文。 */
    public List<OrderEntry> findRecentOrders(int limit) {
        return repository.findRecentOrders(limit);
    }

    /** データを初期状態に戻す (サンプルを繰り返し試すため)。 */
    public void reset() {
        repository.reset();
    }

    /**
     * 注文を受け付ける。
     *
     * <p>受け付けられなかった場合も例外にはせず、理由を持った {@link OrderResult} を返します。</p>
     */
    public OrderResult place(OrderRequest request) {
        Optional<Item> found = repository.findItem(request.getItemCode());
        if (!found.isPresent()) {
            return OrderResult.failure("商品が見つかりません: " + request.getItemCode());
        }
        Item item = found.get();

        int quantity = request.getQuantity();
        if (quantity < 1 || quantity > OrderPricing.MAX_QUANTITY) {
            return OrderResult.failure("数量は 1 〜 " + OrderPricing.MAX_QUANTITY + " で指定してください");
        }

        if (item.getStock() < quantity) {
            // ここで打ち切る。在庫を減らしも保存もしないことが大事で、
            // テストでは「呼ばれていないこと」まで確かめます (下の OrderServiceTest 参照)。
            return OrderResult.failure(
                    "在庫が足りません（" + item.getName() + "の残りは " + item.getStock() + " 個です）");
        }

        OrderAmount amount = OrderPricing.calculate(item.getUnitPrice(), quantity, request.getMemberRank());

        LocalDateTime acceptedAt = LocalDateTime.now(clock);
        OrderEntry order = new OrderEntry(
                nextOrderNumber(acceptedAt),
                request.getCustomerName(),
                item.getCode(),
                item.getName(),
                quantity,
                request.getMemberRank(),
                amount,
                acceptedAt);

        repository.decreaseStock(item.getCode(), quantity);
        repository.save(order);

        return OrderResult.success(order);
    }

    /**
     * 受注番号を組み立てる。例: {@code ORD-20250401-001}
     *
     * <p>日付が入るので、時計を固定しないとテストで期待値が書けません。</p>
     */
    private String nextOrderNumber(LocalDateTime acceptedAt) {
        int sequence = repository.countOrders() + 1;
        return String.format("ORD-%s-%03d", ORDER_NUMBER_DATE.format(acceptedAt), sequence);
    }
}
