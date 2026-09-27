<%--
  【サンプル】doPost から DB まで通してテストする

  注文サンプル（OrderServlet）が書き込むテーブルの、今の中身を表示します。
  OrderServletDbTest は、このテーブルを SQL で読んで結果を確かめています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="servlet-db-test">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>何を確かめるテストか</h2>
    <p>
      「Servlet を単体テストする」では、リポジトリを偽物に差し替えて
      <strong>Servlet の行き先</strong>だけを確かめました。
      このサンプルでは中身を何も差し替えず、
      <code>doPost</code> を呼んだ結果<strong>テーブルに正しい行が入ったか</strong>までを確かめます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th></th><th>OrderServletTest（単体）</th><th>OrderServletDbTest（DB まで通す）</th></tr>
        </thead>
        <tbody>
          <tr>
            <th>Servlet の作り方</th>
            <td>テスト用コンストラクタに偽物のサービスを渡す</td>
            <td><strong>本番と同じ</strong>引数なしコンストラクタ</td>
          </tr>
          <tr>
            <th>データ置き場</th>
            <td>メモリ上の偽物</td>
            <td>本物の DB（H2）</td>
          </tr>
          <tr>
            <th>偽物にしているもの</th>
            <td>request / response / リポジトリ</td>
            <td>request / response だけ</td>
          </tr>
          <tr>
            <th>確かめるもの</th>
            <td>行き先・画面に渡した値・呼んだ回数</td>
            <td>行き先・<strong>テーブルの中身</strong></td>
          </tr>
          <tr>
            <th>見つけられる不具合</th>
            <td>分岐の間違い、forward / redirect の取り違え</td>
            <td>加えて、SQL の誤り・列の取り違え・部品のつなぎ間違い</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      本番のコンストラクタをそのまま使うので、<strong>テストのためにソースを変える必要がありません</strong>。
      テストしやすい作りになっていない既存のシステムでも、同じ形で書けます。
      業務ロジックと SQL が Servlet の中に混ざっていても、入口（<code>doPost</code>）と
      出口（テーブル）だけを見るので、中の作りに左右されません。
    </p>

    <h2>テストの形</h2>
<pre><code class="language-java">@BeforeEach
void setUp() throws Exception {
    servlet = new OrderServlet();          // 本番と同じ組み立て（中で DB につながる）

    OrderTables.clear();                   // 前のテストの残りを消す
    OrderTables.insertItem("B-200", "コピー用紙（A4・1箱）", 1_000, 40);
    OrderTables.insertItem("C-300", "オフィスチェア", 5_200, 3);
}

@Test
void insertsOrderRow() throws Exception {
    FakeHttpServletResponse response = new FakeHttpServletResponse();

    servlet.doPost(postRequest("山田 太郎", "B-200", "10", "REGULAR"), response);

    assertEquals(OrderServlet.PATH, response.getRedirectedTo());

    List&lt;OrderRow&gt; orders = OrderTables.findOrders();   // 自分の SQL で読む
    assertEquals(1, orders.size());
    assertEquals(10_450, orders.get(0).total());
    assertEquals(30, OrderTables.stockOf("B-200"));      // 40 個から 10 個減った
}</code></pre>

    <h2>書き方の決まりごと</h2>
    <h3 class="h5">1. データはテストごとに自分で用意する</h3>
    <p>
      <code>@BeforeEach</code> でテーブルを空にしてから、そのテストに必要な商品だけを入れます。
      「初期データに B-200 が 40 個あるはず」と当てにすると、
      誰かが初期データを直しただけで関係のないテストが落ちます。
      また、前のテストが減らした在庫が残っていると、
      <strong>1 本ずつなら通るのに、まとめて流すと落ちる</strong>という厄介な状態になります。
    </p>

    <h3 class="h5">2. 結果は自分の SQL で確かめる</h3>
    <p>
      確かめるときに、テスト対象の <code>JdbcOrderRepository.findRecentOrders()</code> を使ってはいけません。
      書き込み（<code>save</code>）と読み込みで同じ列を取り違えていると、
      <strong>間違えて書いたものを間違えて読んで、正しく見えてしまう</strong>からです。
      <code>OrderTables</code> はテーブルを直接 <code>SELECT</code> する、テスト専用の補助クラスです。
    </p>

    <h3 class="h5">3. 後片付けをする</h3>
    <p>
      <code>@AfterEach</code> で初期状態に戻します。
      <code>doPost</code> の中でコミットまで済んでしまうので、
      「テストの最後にロールバックして元に戻す」やり方は使えません。
      消す・入れ直すのが確実です。
    </p>

    <h3 class="h5">4. 時計は止められない前提で書く</h3>
    <p>
      本番のコンストラクタはシステム時計を使うので、受注番号の日付は実行した日で変わります。
      期待値に「今日の日付」を書くと、<strong>日付をまたいだ瞬間に実行すると落ちます</strong>。
      このテストでは、同じ行に保存された受付日時と受注番号が食い違っていないかを見ています。
    </p>
<pre><code class="language-java">OrderRow order = OrderTables.findOrders().get(0);
assertEquals("ORD-" + order.acceptedAt().format(YYYYMMDD) + "-001", order.orderNumber());</code></pre>

    <h2>現場のデータベースで使うとき</h2>
    <p>
      このサンプルは H2 を使っていますが、現場では<strong>そのシステムと同じ種類の DB</strong>を使います。
      H2 は Oracle や PostgreSQL の方言を完全には真似できないので、
      方言に頼った SQL（日付関数、<code>ROWNUM</code>、<code>MERGE</code> など）は
      H2 で通っても本番で動く保証になりません。
    </p>
    <p>ただし、<strong>つなぐ先は「テスト専用」にしてください</strong>。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>つなぐ先</th><th>向き・不向き</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>Testcontainers で立てる DB</td>
            <td>◎ テストのたびに空の DB が Docker で立ち上がる。誰とも取り合わない</td>
          </tr>
          <tr>
            <td>各自の PC に入れた DB / テスト専用スキーマ</td>
            <td>○ 自分しか使わないなら安心して消せる</td>
          </tr>
          <tr>
            <td>チームで共有している開発用 DB</td>
            <td>× テストが <code>DELETE</code> するので、他の人の確認用データを消してしまう</td>
          </tr>
          <tr>
            <td>本番 DB</td>
            <td>× 論外</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      切り替えの方法は、そのシステムが<strong>接続先をどこから取っているか</strong>で決まります。
      設定ファイルやシステムプロパティから読んでいればテスト用の設定を置くだけで済みます。
      Tomcat の JNDI（<code>context.xml</code>）から取っている場合は、
      Tomcat の無いテストでは JNDI を用意するライブラリや Mockito での差し替えが必要になります。
      このサンプルでは <code>Database.getConnection()</code> が接続の入口です。
    </p>

    <h2>並列に実行するとき</h2>
    <p>
      JUnit 5 は、設定しなければテストを 1 本ずつ順に実行します（このプロジェクトもそうです）。
      並列にしたときに DB を使うテスト同士がテーブルを取り合わないよう、
      <code>@ResourceLock</code> を付けておくと安心です。同じ名前のロックを持つテストは同時に動きません。
    </p>
<pre><code class="language-java">@ResourceLock("order-tables")
class OrderServletDbTest { ... }</code></pre>

    <h2>テストのピラミッドでの位置</h2>
    <p>
      単体テストより遅く、書く準備も多いので、<strong>分岐を網羅するのは下の層に任せます</strong>。
      このテストは「正常に登録できる」「断ったときに何も書き込まない」のような
      <strong>代表的な流れ</strong>に絞ります。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>テスト</th><th>必要なもの</th><th>件数の目安</th></tr>
        </thead>
        <tbody>
          <tr><td><code>OrderPricingTest</code></td><td>なし</td><td>多く（境界値を網羅）</td></tr>
          <tr><td><code>OrderServiceTest</code></td><td>代役のリポジトリ・止めた時計</td><td>中くらい</td></tr>
          <tr><td><code>OrderServletTest</code></td><td>偽のリクエスト／レスポンス</td><td>少なく</td></tr>
          <tr class="table-info"><td><code>OrderServletDbTest</code></td><td>偽のリクエスト／レスポンス・DB</td><td>少なく（代表的な流れ）</td></tr>
          <tr><td>画面（E2E）</td><td>Tomcat・ブラウザ自動操作</td><td>ごく少なく</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      テストの無い既存システムでは、この順番が逆になります。
      まず<strong>このテストで今の動きを固定</strong>して安全網を張り、
      それから少しずつ直して下の層のテストを増やしていきます。
    </p>

    <h2>動かし方</h2>
<pre><code class="language-bash">mvn test -Dtest=OrderServletDbTest</code></pre>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:panel title="テストが確かめるテーブル"
             note="注文サンプルが書き込む 2 つのテーブルの、今の中身です">
      <p class="mb-0">
        <a href="${ctx}/samples/test/servlet-test">「Servlet を単体テストする」の注文フォーム</a>
        から注文してから、この画面を開き直してみてください。
        注文テーブルに行が増え、商品テーブルの在庫が減ります。
        <code>OrderServletDbTest</code> は、この変化を <code>doPost</code> を直接呼んで確かめています。
      </p>
    </t:panel>

    <t:panel title="order_items（商品）" note="在庫（stock）が注文のたびに減る">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr><th>code</th><th>name</th><th class="text-right">unit_price</th><th class="text-right">stock</th></tr>
          </thead>
          <tbody>
            <c:forEach var="item" items="${items}">
              <tr>
                <td><code>${fn:escapeXml(item.code)}</code></td>
                <td>${fn:escapeXml(item.name)}</td>
                <td class="text-right">${item.unitPrice}</td>
                <td class="text-right">${item.stock}</td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="order_entries（注文）" note="新しい順に 10 件まで">
      <c:choose>
        <c:when test="${empty orders}">
          <p class="text-muted mb-0">まだ注文はありません。</p>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <thead class="thead-light">
                <tr>
                  <th>order_number</th><th>customer_name</th><th>item_code</th>
                  <th class="text-right">quantity</th><th>member_rank</th>
                  <th class="text-right">subtotal</th><th class="text-right">bulk_discount</th>
                  <th class="text-right">member_discount</th><th class="text-right">shipping_fee</th>
                  <th class="text-right">tax</th><th>accepted_at</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="order" items="${orders}">
                  <tr>
                    <td><code>${fn:escapeXml(order.orderNumber)}</code></td>
                    <td>${fn:escapeXml(order.customerName)}</td>
                    <td><code>${fn:escapeXml(order.itemCode)}</code></td>
                    <td class="text-right">${order.quantity}</td>
                    <td>${order.memberRank}</td>
                    <td class="text-right">${order.amount.subtotal}</td>
                    <td class="text-right">${order.amount.bulkDiscount}</td>
                    <td class="text-right">${order.amount.memberDiscount}</td>
                    <td class="text-right">${order.amount.shippingFee}</td>
                    <td class="text-right">${order.amount.tax}</td>
                    <td>${fn:escapeXml(order.acceptedAtText)}</td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <t:panel title="テストと確かめていること">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr><th>テスト</th><th>操作</th><th>確かめること</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>showsItemsFromDatabase</code></td>
              <td>GET</td>
              <td>order_items に入れた商品が画面に渡る</td>
            </tr>
            <tr>
              <td><code>insertsOrderRow</code></td>
              <td>正常に注文</td>
              <td>order_entries に 1 行入り、金額の列が正しい。リダイレクトする</td>
            </tr>
            <tr>
              <td><code>orderNumberContainsAcceptedDate</code></td>
              <td>正常に注文</td>
              <td>order_number の日付が accepted_at と一致する</td>
            </tr>
            <tr>
              <td><code>decreasesStock</code></td>
              <td>正常に注文</td>
              <td>注文した商品の stock だけが減る</td>
            </tr>
            <tr>
              <td><code>numbersOrdersFromDatabase</code></td>
              <td>2 回注文</td>
              <td>order_number の連番が 001、002 と振られる</td>
            </tr>
            <tr>
              <td><code>doesNotWriteWhenStockIsShort</code></td>
              <td>在庫より多く注文</td>
              <td>同じ画面へ戻り、どちらのテーブルも変わらない</td>
            </tr>
            <tr>
              <td><code>doesNotWriteOnValidationError</code></td>
              <td>入力に誤り</td>
              <td>同じ画面へ戻り、どちらのテーブルも変わらない</td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>
  </jsp:body>
</t:sample>
