package com.example.servletsample.samples.test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import com.example.servletsample.common.Flash;
import com.example.servletsample.common.ValidationErrors;

/**
 * 【サンプル】Servlet そのものの単体テスト ({@link OrderServlet})。
 *
 * <p>Tomcat は起動しません。偽の {@link FakeHttpServletRequest} /
 * {@link FakeHttpServletResponse} を作って {@code doGet} / {@code doPost} を
 * <b>ただのメソッドとして直接呼びます</b>。</p>
 *
 * <h2>Servlet のテストで確かめること</h2>
 * <ul>
 *   <li><b>行き先</b> … forward した JSP のパス、リダイレクト先の URL</li>
 *   <li><b>画面に渡した値</b> … {@code request.setAttribute} で入れたもの</li>
 *   <li><b>サービスの呼び方</b> … 呼んだ / 呼んでいない、渡した引数</li>
 * </ul>
 * <p>逆に、<b>HTML の中身は見ません</b>。それは JSP の仕事で、
 * ここで確かめようとすると Tomcat が必要になります
 * (画面まで通した確認は、ブラウザを自動操作する結合テストの役目です)。</p>
 *
 * <p>テストクラスを {@code OrderServlet} と同じパッケージに置いてあるので、
 * {@code protected} の {@code doGet} / {@code doPost} と、
 * テスト用コンストラクタを呼べます。</p>
 */
class OrderServletTest {

    private static final Clock FIXED_CLOCK =
            Clock.fixed(Instant.parse("2025-04-01T00:00:00Z"), ZoneId.of("Asia/Tokyo"));

    private InMemoryOrderRepository repository;
    private OrderServlet servlet;

    @BeforeEach
    void setUp() {
        // DB の代わりにメモリ上のリポジトリを使うサービスを組み立て、Servlet に渡す。
        // 本番用のコンストラクタ (引数なし) を使うと H2 に繋ぎにいってしまいます。
        repository = new InMemoryOrderRepository();
        servlet = new OrderServlet(new OrderService(repository, FIXED_CLOCK));
    }

    // ======================================================================
    // 表示 (GET)
    // ======================================================================

    @Test
    @DisplayName("GET : 商品一覧と空のフォームを渡して JSP へ forward する")
    void showsFormOnGet() throws Exception {
        FakeHttpServletRequest request = new FakeHttpServletRequest().withMethod("GET");
        FakeHttpServletResponse response = new FakeHttpServletResponse();

        servlet.doGet(request, response);

        assertEquals(OrderServlet.VIEW, request.getForwardedPath(), "転送先の JSP");
        assertNull(response.getRedirectedTo(), "GET ではリダイレクトしない");

        @SuppressWarnings("unchecked")
        List<Item> items = (List<Item>) request.getAttribute("items");
        assertEquals(4, items.size(), "商品一覧を画面に渡している");

        OrderForm form = (OrderForm) request.getAttribute("form");
        assertNotNull(form, "JSP が ${form.xxx} を書けるよう、空でも必ず入れておく");
        assertEquals("", form.getCustomerName());
    }

    // ======================================================================
    // 注文 (POST)
    // ======================================================================

    @Nested
    @DisplayName("POST : 正常に受け付けたとき")
    class Accepted {

        @Test
        @DisplayName("リダイレクトする (PRG パターン)")
        void redirectsAfterPost() throws Exception {
            FakeHttpServletRequest request = postRequest("山田 太郎", "B-200", "10", "REGULAR");
            FakeHttpServletResponse response = new FakeHttpServletResponse();

            servlet.doPost(request, response);

            assertEquals("/samples/test/servlet-test", response.getRedirectedTo(),
                    "再読み込みで二重注文にならないよう、成功時はリダイレクト");
            assertEquals(302, response.getStatus());
            assertNull(request.getForwardedPath(), "成功時は JSP へ forward しない");
        }

        @Test
        @DisplayName("注文が登録され、完了メッセージをセッションに預ける")
        void savesOrderAndFlash() throws Exception {
            FakeHttpServletRequest request = postRequest("山田 太郎", "B-200", "10", "REGULAR");

            servlet.doPost(request, new FakeHttpServletResponse());

            assertEquals(1, repository.getSaveCount());
            assertEquals(30, repository.findItem("B-200").orElseThrow().getStock());

            // リダイレクト先で出すメッセージは、セッションに預けてから移動します (Flash)。
            // リダイレクト後の画面がやること (セッションから取り出す) をここで再現して確かめます。
            Flash.consume(request);
            Flash.Message message = (Flash.Message) request.getAttribute(Flash.ATTRIBUTE_NAME);
            assertNotNull(message, "完了メッセージが預けられていません");
            assertEquals("success", message.getVariant());
            assertTrue(message.getText().contains("ORD-20250401-001"), message.getText());
        }
    }

    @Nested
    @DisplayName("POST : 入力に誤りがあるとき")
    class InvalidInput {

        @Test
        @DisplayName("同じ画面へ forward し、入力値とエラーを渡す")
        void forwardsBackWithErrors() throws Exception {
            // 氏名が空、数量が全角
            FakeHttpServletRequest request = postRequest("", "B-200", "１０", "REGULAR");
            FakeHttpServletResponse response = new FakeHttpServletResponse();

            servlet.doPost(request, response);

            assertEquals(OrderServlet.VIEW, request.getForwardedPath(),
                    "入力し直してもらうので forward (リダイレクトでは入力値が消える)");
            assertNull(response.getRedirectedTo());

            ValidationErrors errors = (ValidationErrors) request.getAttribute("errors");
            assertTrue(errors.has("customerName"), "氏名のエラー");
            assertTrue(errors.has("quantity"), "数量のエラー: " + errors.get("quantity"));

            OrderForm form = (OrderForm) request.getAttribute("form");
            assertEquals("１０", form.getQuantity(), "打ち直さずに済むよう、入力値はそのまま戻す");
        }

        @Test
        @DisplayName("入力エラーのときはサービスを呼ばない")
        void doesNotCallServiceOnValidationError() throws Exception {
            servlet.doPost(postRequest("", "", "", ""), new FakeHttpServletResponse());

            assertEquals(0, repository.getSaveCount(), "保存してはいけない");
            assertEquals(0, repository.getDecreaseStockCount(), "在庫を減らしてもいけない");
        }
    }

    @Nested
    @DisplayName("POST : 在庫が足りないとき")
    class OutOfStock {

        @Test
        @DisplayName("画面全体のエラーとして理由を出し、同じ画面へ戻す")
        void showsReasonAsGlobalError() throws Exception {
            // オフィスチェアの在庫は 3 個
            FakeHttpServletRequest request = postRequest("山田 太郎", "C-300", "4", "REGULAR");
            FakeHttpServletResponse response = new FakeHttpServletResponse();

            servlet.doPost(request, response);

            assertEquals(OrderServlet.VIEW, request.getForwardedPath());
            assertNull(response.getRedirectedTo());

            ValidationErrors errors = (ValidationErrors) request.getAttribute("errors");
            assertEquals(1, errors.getGlobals().size(), "入力欄ではなく画面全体のエラー");
            assertTrue(errors.getGlobals().get(0).contains("在庫が足りません"),
                    errors.getGlobals().get(0));

            assertEquals(0, repository.getSaveCount());
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
