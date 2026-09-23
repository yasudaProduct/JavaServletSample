<%--
  【サンプル】単体テストの基本（JUnit 5・境界値）

  PricingDemoServlet が OrderPricing を呼んだ結果を表示します。
  画面で境界値を自分の手で確かめられるようにしたものです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/test/unit-test-basics" />
<t:sample sampleId="unit-test-basics">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>単体テストとは</h2>
    <p>
      クラスやメソッドを <strong>1 つだけ取り出して、決めた入力に対して決めた答えを返すか</strong>
      を自動で確かめるテストです。画面を開いて手で確かめる作業と違い、
      <code>mvn test</code> と打てば何百件でも数秒で終わり、何度でも同じ条件で繰り返せます。
    </p>
    <p>
      効いてくるのは<strong>直すとき</strong>です。消費税率が変わった、割引の順番が変わった——
      そのときテストがあれば「他を壊していないか」が数秒で分かります。
      無ければ、関係しそうな画面を人手でひと通り触り直すことになります。
    </p>

    <h2>テストの形：AAA（準備・実行・検証）</h2>
    <p>テストは 3 つの段に分けて書くと読みやすくなります。</p>
<pre><code class="language-java">@Test
@DisplayName("単価 × 数量に送料と消費税が乗る")
void calculatesSimpleOrder() {
    // Arrange（準備）: 何を計算させたいのかを置く
    int unitPrice = 1200;
    int quantity = 3;

    // Act（実行）: 試したいメソッドは 1 つだけ呼ぶ
    OrderAmount amount = OrderPricing.calculate(unitPrice, quantity, MemberRank.REGULAR);

    // Assert（検証）: 期待した値になっているか
    assertEquals(600, amount.getShippingFee(), "送料");
    assertEquals(4620, amount.getTotal(), "請求金額");
}</code></pre>
    <ul>
      <li>
        <strong>1 つのテストに観点は 1 つ</strong>：
        いろいろ詰め込むと、落ちたときに何が壊れたのか分かりません。
      </li>
      <li>
        <strong>名前で仕様が読めるようにする</strong>：
        <code>@DisplayName</code> に日本語で書けます。
        テスト結果の一覧が、そのまま仕様の一覧になります。
      </li>
      <li>
        <strong>期待値は手で計算して直接書く</strong>：
        <code>assertEquals(unitPrice * quantity * 1.1, ...)</code> のように
        実装と同じ式を書くと、式が間違っていても一緒に間違えるので、テストが通ってしまいます。
      </li>
    </ul>

    <h2>境界値を狙う</h2>
    <p>
      不具合は「ちょうど」のところに集まります。
      <code>&gt;=</code> と <code>&gt;</code> の書き間違い、1 つずれた比較。
      だから<strong>ルールが切り替わる値の前後を、必ずセットで</strong>試します。
    </p>
    <table class="table table-sm table-bordered">
      <thead class="thead-light">
        <tr><th>ルール</th><th>試す値</th></tr>
      </thead>
      <tbody>
        <tr><td>10 個以上でまとめ買い割引</td><td>9 個 / <strong>10 個</strong> / 11 個</td></tr>
        <tr><td>5,000 円以上で送料無料</td><td>4,999 円 / <strong>5,000 円</strong> / 5,001 円</td></tr>
        <tr><td>数量は 1 〜 99</td><td>0 / <strong>1</strong> / <strong>99</strong> / 100</td></tr>
        <tr><td>円未満は切り捨て</td><td>166.5 円 → 166 円 になるか</td></tr>
      </tbody>
    </table>

    <h2>同じ形のテストは表にまとめる</h2>
    <p>
      入力と期待値だけが違うテストは <code>@ParameterizedTest</code> で 1 つにまとめられます。
      条件を足すのが 1 行で済むので、境界値を増やす気になります。
    </p>
<pre><code class="language-java">@ParameterizedTest(name = "割引後 {0} 円 → 送料 {1} 円")
@CsvSource({
        "4999, 600",    // 1 円足りない
        "5000,   0",    // ちょうど → 無料
        "5001,   0",
})
void freeShippingFromThreshold(int unitPrice, int expectedShippingFee) {
    assertEquals(expectedShippingFee,
            OrderPricing.calculate(unitPrice, 1, MemberRank.REGULAR).getShippingFee());
}</code></pre>

    <h2>例外もテストする</h2>
    <p>
      「こういう値を渡したら例外にする」も仕様です。<code>assertThrows</code> で確かめます。
      このとき<strong>例外にならない側も必ず書きます</strong>。
      通る値のテストが無いと、常に例外を投げる実装でもテストが通ってしまうからです。
    </p>
<pre><code class="language-java">@ParameterizedTest
@ValueSource(ints = {0, -1, 100})
void rejectsQuantityOutOfRange(int quantity) {
    IllegalArgumentException e = assertThrows(IllegalArgumentException.class,
            () -&gt; OrderPricing.calculate(1000, quantity, MemberRank.REGULAR));

    // メッセージまで見ておくと、別の原因の例外を掴んでいないと分かる
    assertTrue(e.getMessage().contains("数量"));
}</code></pre>

    <h2>テストしやすいコードの条件</h2>
    <p>
      このサンプルの <code>OrderPricing</code> は、単体テストが書きやすい形になっています。
      条件はこの 3 つです。
    </p>
    <ul>
      <li><strong>入力が引数だけ</strong>：リクエストも DB も見ない</li>
      <li><strong>出力が戻り値だけ</strong>：画面に書いたりログに出したりしない</li>
      <li><strong>同じ入力なら必ず同じ答え</strong>：現在時刻や乱数に左右されない</li>
    </ul>
    <p>
      この 3 つが揃うと、テストは「呼んで、返り値を見る」だけになります。
      逆に Servlet や DAO に業務ルールを書くと、テストのために
      Tomcat や DB を用意することになります。
      時刻や DB が絡む場合にどうするかは、次のサンプル
      <a href="${ctx}/samples/test/test-double">テストダブルでデータベースから切り離す</a>
      で扱います。
    </p>

    <h2>動かし方</h2>
<pre><code class="language-bash">mvn test                       # 全部流す
mvn test -Dtest=OrderPricingTest   # このサンプルのテストだけ流す</code></pre>
    <p>
      結果は <code>target/surefire-reports/</code> に残ります。
      このリポジトリでは GitHub Actions でも <code>mvn verify</code> を実行しており、
      テストが落ちるとデプロイされません。
    </p>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="金額を計算してみる"
             note="テスト対象の OrderPricing.calculate をそのまま呼んでいます">
      <form action="${formUrl}" method="get" class="form-row align-items-end">
        <div class="form-group col-sm-3">
          <label for="unitPrice">単価（円・税抜）</label>
          <input type="text" class="form-control" id="unitPrice" name="unitPrice"
                 value="${fn:escapeXml(unitPrice)}" inputmode="numeric">
        </div>
        <div class="form-group col-sm-3">
          <label for="quantity">数量</label>
          <input type="text" class="form-control" id="quantity" name="quantity"
                 value="${fn:escapeXml(quantity)}" inputmode="numeric">
        </div>
        <div class="form-group col-sm-3">
          <label for="memberRank">会員ランク</label>
          <select class="form-control" id="memberRank" name="memberRank">
            <c:forEach var="rank" items="${ranks}">
              <option value="${rank}" ${rank eq memberRank ? 'selected' : ''}>
                ${fn:escapeXml(rank.label)}（${rank.discountPercent}% 引き）
              </option>
            </c:forEach>
          </select>
        </div>
        <div class="form-group col-sm-3">
          <button type="submit" class="btn btn-primary btn-block">計算する</button>
        </div>
      </form>

      <c:if test="${not empty error}">
        <div class="alert alert-warning mb-0" role="alert">
          <strong>計算できませんでした</strong>
          <div class="mt-1"><code>${fn:escapeXml(error)}</code></div>
          <div class="small mt-2 mb-0">
            数量 0 や 100 のように範囲外の値を渡すと、<code>OrderPricing</code> は
            <code>IllegalArgumentException</code> を投げます。
            これはテストコードで <code>assertThrows</code> を使って確かめている動きです。
          </div>
        </div>
      </c:if>

      <c:if test="${not empty amount}">
        <div class="table-responsive mt-3">
          <table class="table table-sm table-bordered mb-0">
            <tbody>
              <tr>
                <th scope="row" class="w-50">小計（単価 × 数量）</th>
                <td class="text-right">${fn:escapeXml(amount.subtotal)} 円</td>
              </tr>
              <tr>
                <th scope="row">まとめ買い割引（10 個以上で 5%）</th>
                <td class="text-right">
                  <c:choose>
                    <c:when test="${amount.bulkDiscount gt 0}">− ${amount.bulkDiscount} 円</c:when>
                    <c:otherwise><span class="text-muted">なし</span></c:otherwise>
                  </c:choose>
                </td>
              </tr>
              <tr>
                <th scope="row">会員割引</th>
                <td class="text-right">
                  <c:choose>
                    <c:when test="${amount.memberDiscount gt 0}">− ${amount.memberDiscount} 円</c:when>
                    <c:otherwise><span class="text-muted">なし</span></c:otherwise>
                  </c:choose>
                </td>
              </tr>
              <tr>
                <th scope="row">割引後の商品代金</th>
                <td class="text-right">${amount.discountedSubtotal} 円</td>
              </tr>
              <tr>
                <th scope="row">送料（5,000 円以上で無料）</th>
                <td class="text-right">
                  <c:choose>
                    <c:when test="${amount.freeShipping}">
                      <span class="badge badge-success">無料</span>
                    </c:when>
                    <c:otherwise>${amount.shippingFee} 円</c:otherwise>
                  </c:choose>
                </td>
              </tr>
              <tr>
                <th scope="row">消費税（10%・切り捨て）</th>
                <td class="text-right">${amount.tax} 円</td>
              </tr>
              <tr class="table-active">
                <th scope="row">請求金額</th>
                <td class="text-right"><strong>${amount.total} 円</strong></td>
              </tr>
            </tbody>
          </table>
        </div>
      </c:if>
    </t:panel>

    <t:panel title="テストが押さえている境界値"
             note="OrderPricingTest と同じ条件です。上のフォームに入れて確かめられます">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th>単価</th>
              <th>数量</th>
              <th class="text-right">まとめ買い割引</th>
              <th class="text-right">会員割引</th>
              <th class="text-right">送料</th>
              <th class="text-right">請求金額</th>
              <th>ここで見ていること</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="row" items="${cases}">
              <tr>
                <td>${row.unitPrice} 円</td>
                <td>${row.quantity} 個</td>
                <td class="text-right">
                  <c:choose>
                    <c:when test="${row.amount.bulkDiscount gt 0}">− ${row.amount.bulkDiscount} 円</c:when>
                    <c:otherwise><span class="text-muted">−</span></c:otherwise>
                  </c:choose>
                </td>
                <td class="text-right">
                  <c:choose>
                    <c:when test="${row.amount.memberDiscount gt 0}">− ${row.amount.memberDiscount} 円</c:when>
                    <c:otherwise><span class="text-muted">−</span></c:otherwise>
                  </c:choose>
                </td>
                <td class="text-right">
                  <c:choose>
                    <c:when test="${row.amount.freeShipping}"><span class="badge badge-success">無料</span></c:when>
                    <c:otherwise>${row.amount.shippingFee} 円</c:otherwise>
                  </c:choose>
                </td>
                <td class="text-right"><strong>${row.amount.total} 円</strong></td>
                <td class="small text-muted">
                  <c:choose>
                    <c:when test="${row.unitPrice eq 1000 and row.quantity eq 9}">まとめ買い割引の 1 つ手前</c:when>
                    <c:when test="${row.unitPrice eq 1000 and row.quantity eq 10}">まとめ買い割引ちょうど</c:when>
                    <c:when test="${row.unitPrice eq 4999}">送料無料まであと 1 円</c:when>
                    <c:when test="${row.unitPrice eq 5000}">送料無料ちょうど</c:when>
                    <c:when test="${row.unitPrice eq 5200}">割引で無料ラインを割ることがある</c:when>
                    <c:otherwise>円未満の端数が出る</c:otherwise>
                  </c:choose>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        会員ランクを「ゴールド会員」にして 5,200 円の行を見てください。
        割引した結果 4,680 円になり<strong>送料無料ラインを割る</strong>ため、
        一般会員より請求金額が高くなります。
        テストにこの 1 件を書き残しておくと、「バグに見えるが仕様どおり」であることが後から分かります。
      </p>
    </t:panel>

    <t:panel title="このサンプルのテストを流す">
<pre class="mb-0"><code class="language-bash">mvn test -Dtest=OrderPricingTest</code></pre>
    </t:panel>
  </jsp:body>
</t:sample>
