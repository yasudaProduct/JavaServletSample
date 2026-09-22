<%--
  【サンプル】テストダブルでデータベースから切り離す

  TestDoubleDemoServlet が、同じ OrderService を
  「本番の組み立て（H2 + システム時刻）」と「テストの組み立て（メモリ + 止めた時計）」の
  2 通りで動かした結果を並べます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/test/test-double" />
<t:sample sampleId="test-double">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>何が困るのか</h2>
    <p>
      サービス層は DB を読み書きします。テストのたびに本物の DB を使うと、こうなります。
    </p>
    <ul>
      <li>テスト用の DB を用意し、接続情報を合わせ、実行前にデータを作り直す必要がある</li>
      <li>遅い。1 件あたり数十ミリ秒でも、数百件流せば体感できる待ち時間になる</li>
      <li>前のテストが残した在庫が次のテストを壊す（単体では通るのに、全部流すと落ちる）</li>
      <li><strong>「在庫が 0 のとき」を作るのが面倒</strong>。テストのために更新 SQL を流すことになる</li>
    </ul>

    <h2>インターフェースを 1 枚挟む</h2>
    <p>
      サービスが <code>JdbcOrderRepository</code> を直接 <code>new</code> していると、
      差し替える隙がありません。間にインターフェースを置き、
      <strong>使うものを外から渡してもらう</strong>形にします（依存性の注入）。
    </p>
<pre><code class="language-java">// 【困る形】サービスが自分で組み立てている
public class OrderService {
    private final OrderRepository repository = new JdbcOrderRepository();  // ← 差し替えられない
}

// 【テストできる形】使うものを受け取る
public class OrderService {
    private final OrderRepository repository;
    private final Clock clock;

    public OrderService(OrderRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }
}</code></pre>
<pre><code class="language-java">// 本番（Servlet の入口で 1 回だけ組み立てる）
new OrderService(new JdbcOrderRepository(), Clock.systemDefaultZone());

// テスト
new OrderService(new InMemoryOrderRepository(), FIXED_CLOCK);</code></pre>

    <h2>テストダブルの種類</h2>
    <p>
      テストのときに本物の代わりに使う部品をまとめて<strong>テストダブル</strong>（代役）と呼びます。
      役割で呼び分けます。
    </p>
    <table class="table table-sm table-bordered">
      <thead class="thead-light">
        <tr><th>呼び方</th><th>役割</th><th>このサンプルでの例</th></tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>スタブ</strong></td>
          <td>決まった値を返すだけ</td>
          <td><code>setStock("B-200", 0)</code> で「在庫 0 のとき」を作る</td>
        </tr>
        <tr>
          <td><strong>フェイク</strong></td>
          <td>簡略版だが本当に動く</td>
          <td><code>InMemoryOrderRepository</code>（Map で在庫を持つ）</td>
        </tr>
        <tr>
          <td><strong>スパイ</strong></td>
          <td>呼ばれた回数や引数を記録する</td>
          <td><code>getSaveCount()</code> で保存されたかを確かめる</td>
        </tr>
        <tr>
          <td><strong>モック</strong></td>
          <td>「こう呼ばれるはず」を先に宣言し、違えば失敗する</td>
          <td>このサンプルでは使っていません（Mockito などが提供します）</td>
        </tr>
      </tbody>
    </table>
    <p>
      現場では全部まとめて「モック」と呼ばれることも多いですが、
      <strong>“値を返させたい” のか “呼ばれ方を確かめたい” のか</strong>を区別しておくと、
      テストの意図がはっきりします。
    </p>

    <h2>「やっていないこと」を確かめる</h2>
    <p>
      在庫不足のとき、大事なのは「失敗が返ること」より
      <strong>在庫を減らしていない・注文を保存していないこと</strong>です。
      戻り値を見るだけでは、保存だけしてしまう不具合に気付けません。
      記録を持つ代役（スパイ）を使うと、これが書けます。
    </p>
<pre><code class="language-java">@Test
@DisplayName("在庫が足りなければ理由を返し、何も書き換えない")
void rejectsWhenStockIsShort() {
    OrderResult result = service.place(new OrderRequest("山田 太郎", "C-300", 4, MemberRank.REGULAR));

    assertFalse(result.isSuccess());
    assertEquals(0, repository.getDecreaseStockCount(), "在庫を減らしてはいけない");
    assertEquals(0, repository.getSaveCount(), "注文を保存してはいけない");
}</code></pre>

    <h2>時計も差し替える</h2>
    <p>
      受注番号には日付が入ります。サービスの中で <code>LocalDateTime.now()</code> を直接呼んでいると、
      実行するたびに値が変わるので <code>assertEquals("ORD-20250401-001", ...)</code> と書けません。
      <code>java.time.Clock</code> を外から受け取る形にしておけば、テストでは時計を止められます。
    </p>
<pre><code class="language-java">private static final Clock FIXED_CLOCK =
        Clock.fixed(Instant.parse("2025-04-01T00:00:00Z"), ZoneId.of("Asia/Tokyo"));

assertEquals("ORD-20250401-001", result.getOrder().getOrderNumber());</code></pre>
    <p>
      同じ考え方は、乱数・UUID・ファイルの作成日時・外部 API の呼び出しにも当てはまります。
      <strong>「毎回変わるもの」「外の世界に触るもの」は、外から渡してもらう</strong>と覚えてください。
    </p>

    <h2>では DB を使う部分は誰が確かめるのか</h2>
    <p>
      <code>JdbcOrderRepository</code> の SQL が正しいかは、この方法では分かりません。
      そこは<strong>本物の DB を使うテスト</strong>の担当です。
      このサイトの <code>ProductDaoTest</code> / <code>TransferDaoTest</code> は、
      組み込みデータベース（H2）をメモリ上で動かして実際に SQL を流しています。
    </p>
    <ul>
      <li><strong>業務ルール</strong>（割引・在庫の判定・手順）… 代役を使って速く大量に</li>
      <li><strong>SQL やマッピング</strong> … 本物の DB を使って少数だけ</li>
    </ul>
    <p>この二段構えにしておくと、テスト全体が速いまま、危ないところは押さえられます。</p>

    <h2>動かし方</h2>
<pre><code class="language-bash">mvn test -Dtest=OrderServiceTest</code></pre>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="同じ処理を 2 通りの組み立てで動かす"
             note="注文すると、本番用（H2）とテスト用（メモリ）の両方に同じ注文を流します">
      <form action="${formUrl}" method="post" class="form-row align-items-end">
        <div class="form-group col-sm-3">
          <label for="customerName">お名前</label>
          <input type="text" class="form-control" id="customerName" name="customerName"
                 value="${empty customerName ? '山田 太郎' : fn:escapeXml(customerName)}">
        </div>
        <div class="form-group col-sm-4">
          <label for="itemCode">商品</label>
          <select class="form-control" id="itemCode" name="itemCode">
            <c:forEach var="item" items="${realItems}">
              <option value="${fn:escapeXml(item.code)}"
                      ${item.code eq itemCode ? 'selected' : ''}>
                ${fn:escapeXml(item.name)}（${item.unitPrice} 円）
              </option>
            </c:forEach>
          </select>
        </div>
        <div class="form-group col-sm-2">
          <label for="quantity">数量</label>
          <input type="text" class="form-control" id="quantity" name="quantity"
                 value="${empty quantity ? '1' : fn:escapeXml(quantity)}" inputmode="numeric">
        </div>
        <div class="form-group col-sm-2">
          <label for="memberRank">会員</label>
          <select class="form-control" id="memberRank" name="memberRank">
            <c:forEach var="rank" items="${ranks}">
              <option value="${rank}" ${rank eq memberRank ? 'selected' : ''}>
                ${fn:escapeXml(rank.label)}
              </option>
            </c:forEach>
          </select>
        </div>
        <div class="form-group col-sm-1">
          <button type="submit" class="btn btn-primary btn-block">注文</button>
        </div>
      </form>
      <form action="${formUrl}" method="post" class="mt-n2">
        <input type="hidden" name="action" value="reset">
        <button type="submit" class="btn btn-sm btn-outline-secondary">在庫と履歴を元に戻す</button>
      </form>
    </t:panel>

    <div class="row">
      <%-- ---------------- 本番の組み立て ---------------- --%>
      <div class="col-lg-6">
        <t:panel title="本番の組み立て" note="JdbcOrderRepository（H2）＋ システム時刻">
          <c:if test="${not empty realResult}">
            <div class="alert ${realResult.success ? 'alert-success' : 'alert-danger'} py-2">
              ${fn:escapeXml(realResult.message)}
              <c:if test="${realResult.success}">
                <div class="small mt-1">
                  受注番号 <code>${fn:escapeXml(realResult.order.orderNumber)}</code> /
                  請求 ${realResult.order.amount.total} 円
                </div>
              </c:if>
            </div>
          </c:if>

          <table class="table table-sm table-bordered">
            <thead class="thead-light">
              <tr><th>商品</th><th class="text-right">単価</th><th class="text-right">在庫</th></tr>
            </thead>
            <tbody>
              <c:forEach var="item" items="${realItems}">
                <tr>
                  <td>${fn:escapeXml(item.name)}</td>
                  <td class="text-right">${item.unitPrice} 円</td>
                  <td class="text-right">${item.stock}</td>
                </tr>
              </c:forEach>
            </tbody>
          </table>

          <p class="small text-muted mb-1">直近の注文</p>
          <c:choose>
            <c:when test="${empty realOrders}">
              <p class="text-muted small mb-0">まだありません</p>
            </c:when>
            <c:otherwise>
              <ul class="list-unstyled small mb-0">
                <c:forEach var="order" items="${realOrders}">
                  <li>
                    <code>${fn:escapeXml(order.orderNumber)}</code>
                    ${fn:escapeXml(order.itemName)} × ${order.quantity}
                    <span class="text-muted">（${fn:escapeXml(order.acceptedAtText)}）</span>
                  </li>
                </c:forEach>
              </ul>
            </c:otherwise>
          </c:choose>
        </t:panel>
      </div>

      <%-- ---------------- テストの組み立て ---------------- --%>
      <div class="col-lg-6">
        <t:panel title="テストの組み立て" note="InMemoryOrderRepository（メモリ）＋ 止めた時計">
          <c:if test="${not empty fakeResult}">
            <div class="alert ${fakeResult.success ? 'alert-success' : 'alert-danger'} py-2">
              ${fn:escapeXml(fakeResult.message)}
              <c:if test="${fakeResult.success}">
                <div class="small mt-1">
                  受注番号 <code>${fn:escapeXml(fakeResult.order.orderNumber)}</code> /
                  請求 ${fakeResult.order.amount.total} 円
                </div>
              </c:if>
            </div>
          </c:if>

          <table class="table table-sm table-bordered">
            <thead class="thead-light">
              <tr><th>商品</th><th class="text-right">単価</th><th class="text-right">在庫</th></tr>
            </thead>
            <tbody>
              <c:forEach var="item" items="${fakeItems}">
                <tr>
                  <td>${fn:escapeXml(item.name)}</td>
                  <td class="text-right">${item.unitPrice} 円</td>
                  <td class="text-right">${item.stock}</td>
                </tr>
              </c:forEach>
            </tbody>
          </table>

          <p class="small text-muted mb-1">スパイが数えた呼び出し回数</p>
          <ul class="list-unstyled small mb-2">
            <li><code>save()</code> … <strong>${saveCount}</strong> 回</li>
            <li><code>decreaseStock()</code> … <strong>${decreaseStockCount}</strong> 回</li>
          </ul>

          <p class="small text-muted mb-1">直近の注文</p>
          <c:choose>
            <c:when test="${empty fakeOrders}">
              <p class="text-muted small mb-0">まだありません</p>
            </c:when>
            <c:otherwise>
              <ul class="list-unstyled small mb-0">
                <c:forEach var="order" items="${fakeOrders}">
                  <li>
                    <code>${fn:escapeXml(order.orderNumber)}</code>
                    ${fn:escapeXml(order.itemName)} × ${order.quantity}
                    <span class="text-muted">（${fn:escapeXml(order.acceptedAtText)}）</span>
                  </li>
                </c:forEach>
              </ul>
            </c:otherwise>
          </c:choose>
        </t:panel>
      </div>
    </div>

    <t:panel title="ここで見てほしいこと">
      <ul class="mb-0">
        <li>
          <strong>サービスのコードは 1 つだけ</strong>：
          左右で違うのは「何を渡して組み立てたか」だけです。
          <code>OrderService</code> は自分が H2 を使っているのかメモリを使っているのかを知りません。
        </li>
        <li>
          <strong>受付日時が動かない</strong>：
          右側は時計を <code>2025/04/01 09:00:00</code> で止めてあるので、
          何度注文しても同じ日時・同じ日付の受注番号になります。だから <code>assertEquals</code> が書けます。
        </li>
        <li>
          <strong>在庫を試しやすい</strong>：
          オフィスチェアは在庫 3 個です。4 個注文すると、両方とも同じ理由で断られます。
          そのとき右側の <code>save()</code> の回数が増えないことを確かめてください。
          これが <code>OrderServiceTest</code> で書いている検証そのものです。
        </li>
        <li>
          <strong>右側だけ他の人と混ざらない</strong>：
          テスト用のリポジトリはセッションごとに持っています。
          本番用（左）は全員で 1 つの H2 を共有しているので、他の人の操作でも在庫が減ります。
          テストが独立して動くべき理由が、そのまま見て取れます。
        </li>
      </ul>
    </t:panel>
  </jsp:body>
</t:sample>
