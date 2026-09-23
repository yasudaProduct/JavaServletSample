<%--
  【サンプル】Servlet を単体テストする

  OrderServlet が表示する注文フォームです。
  この画面で起きること（forward で戻る / リダイレクトする）を、
  OrderServletTest が Tomcat 無しで確かめています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/test/servlet-test" />
<t:sample sampleId="servlet-test">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>Servlet はテストしにくい、のか</h2>
    <p>
      <code>doPost</code> は <code>protected</code> なメソッドで、引数は
      <code>HttpServletRequest</code> と <code>HttpServletResponse</code>。
      どちらもインターフェースで、本物は Tomcat が作ります。
      だから「Servlet のテストにはサーバが要る」と思われがちですが、
      <strong>偽物を自分で作って渡せば、ただのメソッド呼び出しです</strong>。
    </p>
<pre><code class="language-java">FakeHttpServletRequest request = new FakeHttpServletRequest()
        .withMethod("POST")
        .withParameter("customerName", "山田 太郎")
        .withParameter("itemCode", "B-200")
        .withParameter("quantity", "10");
FakeHttpServletResponse response = new FakeHttpServletResponse();

servlet.doPost(request, response);   // ← Tomcat は起動していない

assertEquals("/samples/test/servlet-test", response.getRedirectedTo());</code></pre>
    <p>
      テストクラスを Servlet と<strong>同じパッケージ</strong>に置いているので、
      <code>protected</code> の <code>doPost</code> をそのまま呼べます。
    </p>

    <h2>偽物の作り方</h2>
    <p>
      <code>HttpServletRequest</code> には 60 以上のメソッドがあり、全部実装するのは現実的ではありません。
      そこで標準の道具を 2 つ使います。
    </p>
    <ul>
      <li>
        <strong><code>HttpServletRequestWrapper</code></strong>：
        すべてのメソッドが「中の request へ丸投げ」の形で実装済みのクラス。
        継承して<strong>必要なものだけ上書き</strong>します。
      </li>
      <li>
        <strong><code>java.lang.reflect.Proxy</code></strong>：
        その「中の request」として、何を呼ばれても既定値を返すだけの空実装を作ります。
        （Wrapper は <code>null</code> を渡せないので土台が要ります）
      </li>
    </ul>
    <p>
      上書きするのは、テストに必要な分だけです。このサンプルでは
      <code>getParameter</code> / <code>setAttribute</code> / <code>getAttribute</code> /
      <code>getSession</code> / <code>getRequestDispatcher</code> / <code>getContextPath</code>
      の 6 つで足りました。
    </p>
    <p>
      <strong>実務では</strong> Mockito の <code>mock(HttpServletRequest.class)</code> や、
      Spring の <code>MockHttpServletRequest</code> を使うのが一般的です
      （このサンプル集は依存ライブラリを増やさない方針なので手作りしています）。
      やっていることは同じ —— <strong>インターフェースの偽物を作って渡す</strong>だけです。
    </p>

    <h2>何を確かめるか</h2>
    <table class="table table-sm table-bordered">
      <thead class="thead-light">
        <tr><th>確かめること</th><th>書き方</th></tr>
      </thead>
      <tbody>
        <tr>
          <td>どの JSP へ forward したか</td>
          <td><code>request.getForwardedPath()</code>（偽のディスパッチャが記録）</td>
        </tr>
        <tr>
          <td>どこへリダイレクトしたか</td>
          <td><code>response.getRedirectedTo()</code></td>
        </tr>
        <tr>
          <td>画面に渡した値</td>
          <td><code>request.getAttribute("errors")</code> / <code>("form")</code></td>
        </tr>
        <tr>
          <td>サービスを呼んだ / 呼んでいない</td>
          <td>代役のリポジトリが数えた回数</td>
        </tr>
      </tbody>
    </table>
    <p>
      逆に、<strong>出来上がった HTML は見ません</strong>。それは JSP の担当で、
      確かめようとすると結局 Tomcat が必要になります。
      画面まで通した確認は、ブラウザを自動操作する結合テスト（E2E）の役目です。
    </p>

    <h2>テストしやすい Servlet の形</h2>
    <p>この <code>OrderServlet</code> の <code>doPost</code> は、4 つのことしかしていません。</p>
    <ol>
      <li>リクエストから値を取り出す（<code>OrderForm.from</code>）</li>
      <li>入力の形を確かめる（<code>OrderForm.validate</code>）</li>
      <li>サービスに頼む（<code>OrderService.place</code>）</li>
      <li>結果に応じて行き先を決める（forward か redirect か）</li>
    </ol>
    <p>
      金額の計算も在庫の判定もここには書きません。
      <strong>Servlet に業務ロジックを書くほど、そのロジックのテストに Servlet API が必要になります。</strong>
    </p>
    <p>
      もう 1 つの仕掛けがコンストラクタです。
      <code>doPost</code> の中で <code>new OrderService(new JdbcOrderRepository(), ...)</code> と
      書いてしまうと、Servlet のテストに必ず DB が付いてきます。
      <strong>組み立てるのは入口で 1 回だけ</strong>にして、テストからは差し替えられるようにします。
    </p>
<pre><code class="language-java">/** Tomcat が使うコンストラクタ（本番の組み立て） */
public OrderServlet() {
    this(new OrderService(new JdbcOrderRepository(), Clock.systemDefaultZone()));
}

/** テストから偽物のサービスを渡すためのコンストラクタ */
OrderServlet(OrderService service) {
    this.service = service;
}</code></pre>

    <h2>行き先の使い分け（forward と redirect）</h2>
    <ul>
      <li>
        <strong>入力エラー → forward</strong>：
        入力値とエラーをリクエストスコープに入れたまま同じ画面に戻します。
        リダイレクトするとリクエストスコープが消え、打ち直しをお願いすることになります。
      </li>
      <li>
        <strong>成功 → redirect</strong>：
        POST のまま画面を出すと、再読み込みで二重注文になります（PRG パターン）。
        完了メッセージはセッションに預けて渡します（<code>Flash</code>）。
      </li>
    </ul>
    <p>
      この使い分けは<strong>テストで固定できます</strong>。
      「エラー時に forward していること」「成功時にリダイレクトしていること」を書いておけば、
      あとから誰かが直したときに崩れれば落ちます。
    </p>
<pre><code class="language-java">@Test
@DisplayName("同じ画面へ forward し、入力値とエラーを渡す")
void forwardsBackWithErrors() throws Exception {
    FakeHttpServletRequest request = postRequest("", "B-200", "１０", "REGULAR");
    FakeHttpServletResponse response = new FakeHttpServletResponse();

    servlet.doPost(request, response);

    assertEquals(OrderServlet.VIEW, request.getForwardedPath());
    assertNull(response.getRedirectedTo());

    OrderForm form = (OrderForm) request.getAttribute("form");
    assertEquals("１０", form.getQuantity(), "打ち直さずに済むよう、入力値はそのまま戻す");
}</code></pre>

    <h2>テストのピラミッド</h2>
    <p>3 つのサンプルを並べると、どこに何を書くかが見えてきます。</p>
    <table class="table table-sm table-bordered">
      <thead class="thead-light">
        <tr><th>層</th><th>テストの対象</th><th>必要なもの</th><th>件数の目安</th></tr>
      </thead>
      <tbody>
        <tr>
          <td>計算ロジック</td>
          <td><code>OrderPricing</code></td>
          <td>なし</td>
          <td>多く（境界値を網羅）</td>
        </tr>
        <tr>
          <td>サービス</td>
          <td><code>OrderService</code></td>
          <td>代役のリポジトリ・止めた時計</td>
          <td>中くらい（分岐ごとに）</td>
        </tr>
        <tr>
          <td>Servlet</td>
          <td><code>OrderServlet</code></td>
          <td>偽のリクエスト／レスポンス</td>
          <td>少なく（行き先の確認）</td>
        </tr>
        <tr>
          <td>画面（E2E）</td>
          <td>ブラウザでの操作</td>
          <td>Tomcat・ブラウザ自動操作</td>
          <td>ごく少なく（主要な流れだけ）</td>
        </tr>
      </tbody>
    </table>
    <p>
      下にいくほど速くて安定し、上にいくほど遅くて壊れやすくなります。
      <strong>業務ルールは下の層に寄せる</strong>ほど、テストは書きやすく、速くなります。
    </p>

    <h2>動かし方</h2>
<pre><code class="language-bash">mvn test -Dtest=OrderServletTest</code></pre>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:resultModal message="${flash}" />

    <t:panel title="注文フォーム"
             note="この画面の動き（forward / redirect）を OrderServletTest が確かめています">

      <c:if test="${not empty errors.messages}">
        <div class="alert alert-danger" role="alert">
          <strong>注文を受け付けられませんでした（${errors.count} 件）</strong>
          <ul class="mb-0 mt-2">
            <c:forEach var="message" items="${errors.messages}">
              <li>${fn:escapeXml(message)}</li>
            </c:forEach>
          </ul>
        </div>
      </c:if>

      <form action="${formUrl}" method="post" novalidate>
        <div class="form-row">
          <div class="form-group col-md-4">
            <label for="customerName">お名前 <span class="badge badge-danger">必須</span></label>
            <input type="text" class="form-control ${errors.has('customerName') ? 'is-invalid' : ''}"
                   id="customerName" name="customerName"
                   value="${fn:escapeXml(form.customerName)}" placeholder="例: 山田 太郎">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('customerName'))}</div>
          </div>

          <div class="form-group col-md-4">
            <label for="itemCode">商品 <span class="badge badge-danger">必須</span></label>
            <select class="form-control ${errors.has('itemCode') ? 'is-invalid' : ''}"
                    id="itemCode" name="itemCode">
              <option value="">-- 選んでください --</option>
              <c:forEach var="item" items="${items}">
                <option value="${fn:escapeXml(item.code)}"
                        ${form.itemCode eq item.code ? 'selected' : ''}>
                  ${fn:escapeXml(item.name)} / ${item.unitPrice} 円（在庫 ${item.stock}）
                </option>
              </c:forEach>
            </select>
            <div class="invalid-feedback">${fn:escapeXml(errors.get('itemCode'))}</div>
          </div>

          <div class="form-group col-md-2">
            <label for="quantity">数量 <span class="badge badge-danger">必須</span></label>
            <input type="text" class="form-control ${errors.has('quantity') ? 'is-invalid' : ''}"
                   id="quantity" name="quantity" inputmode="numeric"
                   value="${fn:escapeXml(form.quantity)}">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('quantity'))}</div>
          </div>

          <div class="form-group col-md-2">
            <label for="memberRank">会員ランク</label>
            <select class="form-control" id="memberRank" name="memberRank">
              <option value="REGULAR" ${form.memberRank eq 'REGULAR' ? 'selected' : ''}>一般</option>
              <option value="GOLD" ${form.memberRank eq 'GOLD' ? 'selected' : ''}>ゴールド会員</option>
            </select>
          </div>
        </div>

        <button type="submit" class="btn btn-primary">注文する</button>
      </form>

      <p class="text-muted small mt-3 mb-0">
        試してみてください。
        <strong>お名前を空にする</strong>と入力エラーで同じ画面に戻り、入力値は残ります（forward）。
        <strong>オフィスチェアを 4 個</strong>注文すると在庫不足で断られます。
        正常に注文できたときは URL が変わり、再読み込みしても二重注文になりません（リダイレクト）。
      </p>
    </t:panel>

    <t:panel title="この画面で起きたこと" note="上の操作がテストのどの検証に対応するか">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr><th>操作</th><th>Servlet の動き</th><th>テストでの確認</th></tr>
          </thead>
          <tbody>
            <tr>
              <td>画面を開く（GET）</td>
              <td>商品一覧と空のフォームを渡して forward</td>
              <td><code>showsFormOnGet</code></td>
            </tr>
            <tr>
              <td>お名前を空で注文</td>
              <td>入力エラー → 同じ画面へ forward（入力値は保持）</td>
              <td><code>forwardsBackWithErrors</code></td>
            </tr>
            <tr>
              <td>在庫より多く注文</td>
              <td>サービスが断る → 画面全体のエラーとして forward</td>
              <td><code>showsReasonAsGlobalError</code></td>
            </tr>
            <tr>
              <td>正常に注文</td>
              <td>保存 → 完了メッセージを預けてリダイレクト（302）</td>
              <td><code>redirectsAfterPost</code> / <code>savesOrderAndFlash</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="直近の注文">
      <c:choose>
        <c:when test="${empty orders}">
          <p class="text-muted mb-0">まだ注文はありません。</p>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <thead class="thead-light">
                <tr>
                  <th>受注番号</th><th>お名前</th><th>商品</th>
                  <th class="text-right">数量</th><th class="text-right">請求金額</th><th>受付日時</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="order" items="${orders}">
                  <tr>
                    <td><code>${fn:escapeXml(order.orderNumber)}</code></td>
                    <td>${fn:escapeXml(order.customerName)}</td>
                    <td>${fn:escapeXml(order.itemName)}</td>
                    <td class="text-right">${order.quantity}</td>
                    <td class="text-right">${order.amount.total} 円</td>
                    <td>${fn:escapeXml(order.acceptedAtText)}</td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>

      <form action="${formUrl}" method="post" class="mt-3">
        <input type="hidden" name="action" value="reset">
        <button type="submit" class="btn btn-sm btn-outline-secondary">在庫と履歴を元に戻す</button>
      </form>
    </t:panel>
  </jsp:body>
</t:sample>
