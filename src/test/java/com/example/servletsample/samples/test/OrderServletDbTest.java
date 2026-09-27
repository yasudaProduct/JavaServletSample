package com.example.servletsample.samples.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.format.DateTimeFormatter;
import java.util.List;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.parallel.ResourceLock;

import com.example.servletsample.samples.test.OrderTables.OrderRow;

/**
 * 【サンプル】doPost から DB まで通して確かめるテスト ({@link OrderServlet} + {@link JdbcOrderRepository} + H2)。
 *
 * <p>{@link OrderServletTest} との違いは、<b>中身を何も差し替えていない</b>ことです。</p>
 * <table border="1">
 *   <caption>2 つのテストの違い</caption>
 *   <tr><th></th><th>OrderServletTest (単体)</th><th>このテスト (DB まで通す)</th></tr>
 *   <tr><th>Servlet の作り方</th><td>テスト用コンストラクタに偽物のサービスを渡す</td>
 *       <td>本番と同じ引数なしコンストラクタ</td></tr>
 *   <tr><th>データ置き場</th><td>メモリ上の偽物</td><td>本物の DB (H2)</td></tr>
 *   <tr><th>確かめるもの</th><td>行き先・画面に渡した値</td><td>行き先 + <b>テーブルの中身</b></td></tr>
 *   <tr><th>偽物にしているもの</th><td>request / response / リポジトリ</td><td>request / response だけ</td></tr>
 * </table>
 *
 * <p>本番のコンストラクタをそのまま使うので、<b>テストのためにソースを変える必要がありません</b>。
 * テストしやすい作りになっていない既存のシステムでも、同じ形で書けます。</p>
 *
 * <h2>書き方の決まりごと</h2>
 * <ul>
 *   <li><b>データはテストごとに自分で用意する</b> … 前のテストが残したデータに頼らない。
 *       {@code @BeforeEach} でテーブルを空にしてから、必要な商品だけを入れます。</li>
 *   <li><b>結果は自分の SQL で確かめる</b> … {@link OrderTables} がテーブルを直接読みます。
 *       テスト対象の読み込み処理で確かめると、書き込みと同じ間違いをしていても気付けません。</li>
 *   <li><b>DB を使うテスト同士は同時に動かさない</b> … {@code @ResourceLock} を付けておきます。
 *       このプロジェクトは並列実行を有効にしていないので今は何も起きませんが、
 *       あとで並列にしたときに、他のテストと同じテーブルを取り合わずに済みます。</li>
 * </ul>
 */
@ResourceLock("order-tables")
class OrderServletDbTest {

    private static final DateTimeFormatter YYYYMMDD = DateTimeFormatter.ofPattern("yyyyMMdd");

    private OrderServlet servlet;

    @BeforeEach
    void setUp() throws Exception {
        // 本番と同じ組み立て。中で JdbcOrderRepository が作られ、テーブルも用意される。
        servlet = new OrderServlet();

        // テストに必要なデータだけを入れる (初期データの内容に頼らない)
        OrderTables.clear();
        OrderTables.insertItem("B-200", "コピー用紙（A4・1箱）", 1_000, 40);
        OrderTables.insertItem("C-300", "オフィスチェア", 5_200, 3);
    }

    @AfterEach
    void tearDown() {
        // 画面や他のテストが前提にしている初期状態へ戻しておく
        new JdbcOrderRepository().reset();
    }

    // ======================================================================
    // 表示 (GET)
    // ======================================================================

    @Test
    @DisplayName("GET : DB に入っている商品を画面に渡す")
    void showsItemsFromDatabase() throws Exception {
        FakeHttpServletRequest request = new FakeHttpServletRequest().withMethod("GET");

        servlet.doGet(request, new FakeHttpServletResponse());

        @SuppressWarnings("unchecked")
        List<Item> items = (List<Item>) request.getAttribute("items");
        assertEquals(2, items.size(), "setUp で入れた 2 件だけが読まれる");
        assertEquals("B-200", items.get(0).getCode());
        assertEquals(40, items.get(0).getStock());
    }

    // ======================================================================
    // 注文 (POST)
    // ======================================================================

    @Nested
    @DisplayName("POST : 正常に受け付けたとき")
    class Accepted {

        @Test
        @DisplayName("注文テーブルに 1 行入り、リダイレクトする")
        void insertsOrderRow() throws Exception {
            FakeHttpServletResponse response = new FakeHttpServletResponse();

            servlet.doPost(postRequest("山田 太郎", "B-200", "10", "REGULAR"), response);

            assertEquals(OrderServlet.PATH, response.getRedirectedTo(), "成功時はリダイレクト (PRG)");

            List<OrderRow> orders = OrderTables.findOrders();
            assertEquals(1, orders.size(), "注文が 1 行だけ入っている");

            OrderRow order = orders.get(0);
            assertEquals("山田 太郎", order.customerName());
            assertEquals("B-200", order.itemCode());
            assertEquals(10, order.quantity());
            assertEquals("REGULAR", order.memberRank());
            assertEquals(10_000, order.subtotal(), "1,000 円 × 10 個");
            assertEquals(10_450, order.total(), "まとめ買い割引・送料・消費税まで反映した請求金額");
        }

        @Test
        @DisplayName("受注番号には受付日が入る")
        void orderNumberContainsAcceptedDate() throws Exception {
            servlet.doPost(postRequest("山田 太郎", "B-200", "1", "REGULAR"), new FakeHttpServletResponse());

            // 本番のコンストラクタはシステム時計を使うため、時刻を止められません。
            // 「今日の日付」を期待値に書くと日付をまたいだ瞬間に落ちるので、
            // 同じ行に保存された受付日時と食い違っていないかを確かめます。
            OrderRow order = OrderTables.findOrders().get(0);
            assertEquals("ORD-" + order.acceptedAt().format(YYYYMMDD) + "-001", order.orderNumber());
        }

        @Test
        @DisplayName("注文した商品の在庫だけが減る")
        void decreasesStock() throws Exception {
            servlet.doPost(postRequest("山田 太郎", "B-200", "10", "REGULAR"), new FakeHttpServletResponse());

            assertEquals(30, OrderTables.stockOf("B-200"), "40 個から 10 個減る");
            assertEquals(3, OrderTables.stockOf("C-300"), "注文していない商品はそのまま");
        }

        @Test
        @DisplayName("続けて注文すると、受注番号の連番が DB の件数から振られる")
        void numbersOrdersFromDatabase() throws Exception {
            servlet.doPost(postRequest("山田 太郎", "B-200", "1", "REGULAR"), new FakeHttpServletResponse());
            servlet.doPost(postRequest("鈴木 花子", "C-300", "1", "GOLD"), new FakeHttpServletResponse());

            List<OrderRow> orders = OrderTables.findOrders();
            assertEquals(2, orders.size());
            assertTrue(orders.get(0).orderNumber().endsWith("-001"), orders.get(0).orderNumber());
            assertTrue(orders.get(1).orderNumber().endsWith("-002"), orders.get(1).orderNumber());
        }
    }

    @Nested
    @DisplayName("POST : 受け付けられないとき")
    class Rejected {

        @Test
        @DisplayName("在庫が足りなければ、同じ画面へ戻り DB は何も変わらない")
        void doesNotWriteWhenStockIsShort() throws Exception {
            FakeHttpServletRequest request = postRequest("山田 太郎", "C-300", "4", "REGULAR");
            FakeHttpServletResponse response = new FakeHttpServletResponse();

            servlet.doPost(request, response);

            assertEquals(OrderServlet.VIEW, request.getForwardedPath());
            assertNull(response.getRedirectedTo());

            // 単体テストでは「保存を呼んでいないこと」を回数で見ました。
            // ここでは結果そのもの ── テーブルの中身 ── を見ます。
            assertEquals(0, OrderTables.findOrders().size(), "注文は入っていない");
            assertEquals(3, OrderTables.stockOf("C-300"), "在庫も減っていない");
        }

        @Test
        @DisplayName("入力に誤りがあれば、DB は何も変わらない")
        void doesNotWriteOnValidationError() throws Exception {
            FakeHttpServletRequest request = postRequest("", "B-200", "１０", "REGULAR");

            servlet.doPost(request, new FakeHttpServletResponse());

            assertEquals(OrderServlet.VIEW, request.getForwardedPath());
            assertEquals(0, OrderTables.findOrders().size());
            assertEquals(40, OrderTables.stockOf("B-200"));
        }
    }

    /** POST のリクエストを組み立てる (テストを読みやすくするための補助)。 */
    private static FakeHttpServletRequest postRequest(String customerName, String itemCode,
                                                      String quantity, String memberRank) {
        return new FakeHttpServletRequest()
                .withMethod("POST")
                .withParameter("customerName", customerName)
                .withParameter("itemCode", itemCode)
                .withParameter("quantity", quantity)
                .withParameter("memberRank", memberRank);
    }
}
