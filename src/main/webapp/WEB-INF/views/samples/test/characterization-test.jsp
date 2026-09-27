<%--
  【サンプル】仕様化テストで今の動きを記録する

  「古い作り」の LegacyEstimateServlet と、それを直した EstimateServlet の
  どちらで計算するかを選べる見積もりフォームです。
  2 つの Servlet がこの JSP へ forward してきます（GET はサンプルの共通処理が表示）。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="baseUrl" value="${ctx}/samples/test/characterization-test" />
<c:set var="calculatedBy" value="${requestScope['javax.servlet.forward.servlet_path']}" />
<t:sample sampleId="characterization-test">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>仕様化テストとは</h2>
    <p>
      <strong>今のコードが実際にどう動いているかを、そのまま記録するテスト</strong>です。
      英語では Characterization Test。
      Michael Feathers『レガシーコード改善ガイド』で紹介された考え方で、
      「コードの振る舞いを特徴づける（characterize）」ことから名前が付いています。
    </p>
    <p>ふつうのテストとの違いは、<strong>期待値をどこから持ってくるか</strong>です。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th></th><th>ふつうのテスト</th><th>仕様化テスト</th></tr>
        </thead>
        <tbody>
          <tr><th>期待値の出どころ</th><td>仕様書・正しい答え</td><td><strong>今のコードが実際に返した値</strong></td></tr>
          <tr><th>確かめること</th><td>正しく動いているか</td><td><strong>前と同じに動いているか</strong></td></tr>
          <tr><th>バグがあったら</th><td>テストが落ちる</td><td>バグも含めて記録する</td></tr>
          <tr><th>仕様書</th><td>必要</td><td>無くても書ける</td></tr>
          <tr><th>寿命</th><td>コードと一緒に残り続ける</td><td>直し終えたら、ふつうのテストへ置き換える</td></tr>
        </tbody>
      </table>
    </div>

    <h2>何のために書くのか</h2>
    <p>テストの無い古いコードを直そうとすると、次の板挟みになります。</p>
    <ul>
      <li>テストを書くには、テストしやすい形にコードを直す必要がある</li>
      <li>でもテストが無いので、直して何かを壊しても気付けない</li>
    </ul>
    <p>
      仕様化テストは、この板挟みを抜ける最初の一歩です。
      「正しいかどうか」は問わず、<strong>今の動きを写し取って安全網にします</strong>。
      安全網があれば、直した結果どこかの動きが変わったときにテストが教えてくれるので、
      安心して手を入れられるようになります。
    </p>

    <h2>活用できる場面</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 30%">場面</th><th>使い方</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>リファクタリングの前</td>
            <td>直す範囲の動きを記録してから整理する。<strong>整理の前後で記録が変わらない</strong>ことが、動きを壊していない証拠になる（このサンプルがこれ）</td>
          </tr>
          <tr>
            <td>不具合を直す前</td>
            <td>周りの動きを記録しておくと、直した結果「直したい 1 か所」以外が変わっていないことを確かめられる。変わった行を見れば、影響の範囲がそのまま分かる</td>
          </tr>
          <tr>
            <td>Java・ライブラリ・フレームワークの更新</td>
            <td>更新の前に記録し、更新後に同じ記録で流す。計算の丸め・文字コード・日付の扱いなど、気付きにくい変化を拾える</td>
          </tr>
          <tr>
            <td>作り直し・別システムへの移行</td>
            <td>旧システムの入出力を記録し、新システムに同じ入力を流して比べる（新旧比較）。「前と同じ結果になること」が受け入れの基準になる</td>
          </tr>
          <tr>
            <td>性能改善</td>
            <td>速くするための書き換え（SQL の変更、キャッシュの追加）で結果が変わっていないかを確かめる</td>
          </tr>
          <tr>
            <td>仕様書の無いシステムを読み解く</td>
            <td>「この入力ならこう返す」を並べた記録は、それ自体が<strong>動く仕様書</strong>になる。引き継ぎの資料や、業務担当への確認の材料にも使える</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>このサンプルの題材</h2>
    <p>
      <code>LegacyEstimateServlet</code> は、現場でよく見かける「全部 <code>doPost</code> に書いてある」Servlet です。
      <strong>わざとテストしにくく書いてあり</strong>、このクラスは一切書き換えずにテストしています。
    </p>
    <ul>
      <li>入力の受け取り・送料の計算・画面の切り替えがすべて <code>doPost</code> の中にある</li>
      <li>計算だけを呼び出す入口が無い</li>
      <li>見積番号に現在時刻が入り、実行するたびに結果が変わる</li>
      <li>仕様書が無く、境界の <code>&lt;=</code> と <code>&lt;</code> が正しいのか誰にも分からない</li>
    </ul>

    <h2>書き方 ① 1 件ずつ記録する</h2>
    <p>手順はとても機械的です。</p>
    <ol>
      <li>テスト対象を動かすテストを書き、期待値には<strong>わざと適当な値</strong>（0 など）を書く</li>
      <li>実行して落とす。失敗メッセージに「実際の値」が出る</li>
      <li>その値を期待値に<strong>書き写す</strong></li>
      <li>もう一度実行して通ることを確かめる</li>
    </ol>
<pre><code class="language-java">@Test
@DisplayName("東京・2,000g・3,000 円・一般 → 送料 800 円、請求 4,180 円")
void tokyoUpTo2kg() throws Exception {
    // 最初は assertEquals(0, ...) と書いて実行し、
    // 「expected: &lt;0&gt; but was: &lt;800&gt;」の 800 を書き写した。
    Map&lt;String, Object&gt; result = estimate("東京", "3000", "1", "2000", null);

    assertEquals(800, result.get("ship"));
    assertEquals(4180, result.get("total"));
}</code></pre>
    <p>
      Servlet は偽の request / response を渡して動かし、<code>request.setAttribute</code> で
      画面に渡された値を取り出しています（<code>EstimateRequests</code>）。
      「Servlet を単体テストする」と同じやり方なので、<strong>本番のコードを変えずに書けます</strong>。
    </p>

    <div class="alert alert-info">
      <strong>思い込みと違った例</strong><br>
      このサンプルを作るとき、「全角数字を入れたら例外になるはず」と考えて
      <code>assertThrows</code> で書いたところ、<strong>テストが落ちました</strong>。
      <code>Integer.parseInt</code> は全角の数字も数字として読むので、<code>３０００</code> は 3000 として計算されます。
      頭の中の仕様ではなく、<strong>実際に動かした結果</strong>を記録する理由がここにあります。
    </div>

    <h3 class="h5">入力の選び方</h3>
    <p>全部を網羅する必要はありません。<strong>これから触る部分</strong>を優先して、次の観点で選びます。</p>
    <ul>
      <li><strong>分岐の両側</strong>：会員と一般、北海道・沖縄とそれ以外</li>
      <li><strong>境界の前後</strong>：2,000g と 2,001g、10,000 円と 10,001 円</li>
      <li><strong>変な入力</strong>：数量 0、マイナス、空欄、カンマ付き、全角。例外が出るならそれも記録する</li>
      <li><strong>よく使われる値</strong>：本番のログや、実際の画面操作でよく出る値</li>
    </ul>
    <p>
      カバレッジツール（JaCoCo など）で、<strong>直す予定の範囲の行がテストで実行されているか</strong>を見ながら
      入力を足していくと、漏れを防げます。
    </p>

    <h2>書き方 ② まとめて記録する（ゴールデンマスター）</h2>
    <p>
      組み合わせが多いときは、結果を 1 行ずつテキストにして<strong>記録ファイル</strong>と比べます。
      <code>EstimateGoldenMasterTest</code> は、地域 × 重さの境界 × 金額の境界 × 会員の 160 通りに、
      数量と変な入力を足した約 170 件を流しています。
    </p>
<pre><code class="language-plaintext">pref=東京 price=5000 qty=1 weight=2000 member=1 -&gt; amount=5000 ship=0 discount=250 tax=475 total=5225 estimateNo=EST-{日時}
pref=沖縄 price=5000 qty=1 weight=2000 member=1 -&gt; amount=5000 ship=1200 discount=250 tax=595 total=6545 estimateNo=EST-{日時}
pref=東京 price=3,000 qty=1 weight=2000 member=(なし) -&gt; 例外 NumberFormatException</code></pre>
    <p>記録ファイルは、テストクラスの隣に <code>EstimateGoldenMasterTest.approved.txt</code> という名前で置き、リポジトリにコミットします。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 30%">状況</th><th>テストの動き</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>記録ファイルが無い（初回）</td>
            <td>今の結果を書き出して、<strong>わざと失敗する</strong>。中身を目で確かめてからコミットする</td>
          </tr>
          <tr>
            <td>記録と同じ</td>
            <td>成功</td>
          </tr>
          <tr>
            <td>記録と違う</td>
            <td>違う行を表示して失敗する。今回の結果を <code>*.received.txt</code> に書き出すので、差分ツールで見比べられる（コミットしない）</td>
          </tr>
          <tr>
            <td>わざと動きを変えた</td>
            <td><code>-Dapprove=true</code> を付けて実行すると記録を書き直す。<strong>差分を確かめてから</strong>コミットする</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      記録するときの工夫が 2 つあります。
      例外は<strong>クラス名だけ</strong>を書きます。メッセージは Java のバージョンや書き方の細かい違いで変わるので、
      記録すると「動きは同じなのに落ちる」テストになります。
      また、送られてこなかったパラメータは <code>(なし)</code>、空文字は <code>(空)</code> と書き分けて、
      どちらの入力だったかが記録から読めるようにしています。
    </p>
    <p>
      Java には、同じことをしてくれる <strong>ApprovalTests</strong> というライブラリもあります。
      記録ファイルの名前の付け方（<code>*.approved.txt</code> / <code>*.received.txt</code>）はそれに合わせました。
      このサンプルではライブラリを増やさず、JUnit だけで書いています。
    </p>

    <h2>毎回変わる値の扱い</h2>
    <p>
      現在時刻・乱数・連番の ID が結果に混ざると、何もしていなくても毎回テストが落ちます。
      見積番号 <code>EST-20260927123456</code> には現在時刻が入るので、次のように扱っています。
    </p>
    <ul>
      <li>1 件ずつのテスト：値ではなく<strong>形</strong>（<code>EST-</code> と 14 桁の数字）を確かめる</li>
      <li>ゴールデンマスター：比べる前に <code>EST-{日時}</code> へ<strong>置き換える</strong></li>
    </ul>
    <p>
      時計を外から渡せる作りなら、時刻を止めるのがいちばん確実です（直した後の <code>EstimateServlet</code> はそうしてあります）。
      並び順が決まらない結果は、並べ替えてから比べます。
    </p>

    <h2>おかしな動きを見つけたら</h2>
    <p>
      記録している途中で「これ、おかしくない？」という動きが見つかります。
      <strong>その場では直さず、今の動きのまま記録して印を付けます</strong>。
    </p>
<pre><code class="language-java">@Test
@DisplayName("要確認: 数量 0 でも送料と消費税だけ請求される（880 円）")
void zeroQuantityStillCharged() throws Exception { ... }</code></pre>
    <ul>
      <li>利用者や他のシステムが、そのおかしな動きを前提にしていることがある</li>
      <li>直すかどうかを決めるのは業務の担当者で、テストを書く人ではない</li>
      <li>「整理（動きを変えない）」と「修正（動きを変える）」を 1 つの変更に混ぜると、
        結果が変わったときにどちらが原因か分からなくなる</li>
    </ul>
    <p>このサンプルで見つかった「要確認」は次のとおりです。デモタブで実際に試せます。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>動き</th><th>入力の例</th></tr>
        </thead>
        <tbody>
          <tr><td>5,000g ちょうどの送料の境界が、本州と北海道・沖縄で揃っていない</td><td>北海道・5000g → 2,500 円 / 東京・5000g → 1,100 円</td></tr>
          <tr><td>送料無料の条件が、会員は「以上」、一般は「超える」</td><td>一般・10,000 円 → 送料あり</td></tr>
          <tr><td>沖縄は送料無料にならず、重い荷物ではかえって安くなる</td><td>沖縄・会員・3000g：4,999 円 → 1,800 円 / 5,000 円 → 1,200 円</td></tr>
          <tr><td>数量 0 でも送料と消費税が請求される</td><td>数量 0 → 880 円</td></tr>
          <tr><td>数量がマイナスだと請求金額もマイナスになる</td><td>数量 -1 → -2,420 円</td></tr>
          <tr><td>都道府県が空だと本州の料金になる</td><td>未選択 → 800 円</td></tr>
          <tr><td>会員の判定が <code>member=1</code> のときだけ</td><td><code>true</code> や <code>on</code> は一般扱い</td></tr>
        </tbody>
      </table>
    </div>

    <h2>記録を安全網にして直す</h2>
    <p>
      記録ができたら、計算部分を <code>EstimateCalculator</code> に切り出しました（<code>EstimateServlet</code> から使います）。
      Servlet を動かさなくても、引数を渡すだけで計算を確かめられる形です。
      ゴールデンマスターは、<strong>同じ記録ファイルを直す前と直した後の両方に当てています</strong>。
    </p>
<pre><code class="language-java">static Stream&lt;Arguments&gt; implementations() {
    return Stream.of(
            Arguments.of("直す前 LegacyEstimateServlet", new LegacyEstimateServlet()),
            Arguments.of("直した後 EstimateServlet", new EstimateServlet()));
}</code></pre>
    <p>
      両方が通るので、「形は変えたが、170 件の動きは 1 つも変わっていない」と言えます。
      では、整理のついでに「境界を揃えておこう」と北海道・沖縄の <code>&lt; 5000</code> を
      <code>&lt;= 5000</code> に変えるとどうなるでしょうか。実際に試すと、次のように落ちます。
    </p>
<pre><code class="language-plaintext">直した後 EstimateServlet の動きが記録と違います
70 行目
  記録: pref=北海道 price=4999 qty=1 weight=5000 member=(なし) -&gt; amount=4999 ship=2500 ... total=8248
  今回: pref=北海道 price=4999 qty=1 weight=5000 member=(なし) -&gt; amount=4999 ship=1800 ... total=7478</code></pre>
    <p>
      善意の「ついでの修正」が、請求金額を変えてしまったことがすぐ分かります。
      このように、<strong>動きを変えたつもりのない変更で動きが変わったとき</strong>に気付けるのが、仕様化テストの価値です。
      本当に境界を揃えるべきなら、業務の担当者に確認したうえで<strong>別の変更として</strong>直し、
      <code>-Dapprove=true</code> で記録を更新します。そのとき記録ファイルの差分が、「何がどう変わるか」の説明になります。
    </p>

    <h2>役目を終えたら</h2>
    <p>
      仕様化テストは<strong>工事中の足場</strong>です。
      「なぜこの値なのか」を説明できないテストなので、ずっと残すと、あとから読む人が困ります。
      コードが整理され、業務の担当者と仕様を確認できたら、
      <code>OrderPricingTest</code> のような<strong>仕様にもとづくテスト</strong>に置き換えていきます。
    </p>

    <h2>進め方のまとめ</h2>
    <ol>
      <li>次に直したい箇所を決める</li>
      <li>その箇所を通る入力を選び、今の結果を記録する（1 件ずつ・まとめて）</li>
      <li>カバレッジで、直す範囲がテストで実行されているかを確かめる</li>
      <li>記録に守られた状態で、少しずつ直す。動きを変える修正は別の変更にする</li>
      <li>テストしやすくなった部分から、仕様にもとづくテストへ置き換える</li>
    </ol>

    <h2>注意点</h2>
    <ul>
      <li>
        <strong>通っても「正しい」とは限らない</strong>：「前と同じ」という意味でしかありません。
        最初から間違っていた部分は、ずっと間違ったまま通ります。
      </li>
      <li>
        <strong>記録の更新は、差分を見てから</strong>：落ちたら <code>-Dapprove=true</code> で更新、を習慣にすると、
        安全網の意味が無くなります。記録ファイルの差分もコードレビューの対象です。
      </li>
      <li>
        <strong>細かすぎるものを記録しない</strong>：画面の HTML を丸ごと記録すると、
        見た目を少し直しただけで落ちます。確かめたい値（金額・行き先・テーブルの中身）に絞ります。
      </li>
      <li>
        <strong>時間をかけすぎない</strong>：目的は直すための安全網です。
        直す予定の無い部分まで網羅しようとしないでください。
      </li>
    </ul>

    <h2>動かし方</h2>
<pre><code class="language-bash"># 仕様化テスト（1 件ずつ・まとめて）
mvn test -Dtest='LegacyEstimateCharacterizationTest,EstimateGoldenMasterTest'

# わざと動きを変えたときに、記録ファイルを書き直す
mvn test -Dtest=EstimateGoldenMasterTest -Dapprove=true</code></pre>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:panel title="見積もりフォーム"
             note="同じ入力を、直す前と直した後のどちらの Servlet でも計算できます">
      <form method="post" action="${baseUrl}/legacy" novalidate>
        <div class="form-row">
          <div class="form-group col-md-3">
            <label for="pref">都道府県</label>
            <select class="form-control" id="pref" name="pref">
              <c:forEach var="option" items="東京,大阪,北海道,沖縄">
                <option value="${option}" ${param.pref eq option ? 'selected' : ''}>${option}</option>
              </c:forEach>
              <option value="" ${not empty param and empty param.pref ? 'selected' : ''}>（未選択）</option>
            </select>
          </div>
          <div class="form-group col-md-3">
            <label for="price">単価（円）</label>
            <input type="text" class="form-control" id="price" name="price" inputmode="numeric"
                   value="${empty param.price ? '3000' : fn:escapeXml(param.price)}">
          </div>
          <div class="form-group col-md-2">
            <label for="qty">数量</label>
            <input type="text" class="form-control" id="qty" name="qty" inputmode="numeric"
                   value="${empty param.qty ? '1' : fn:escapeXml(param.qty)}">
          </div>
          <div class="form-group col-md-2">
            <label for="weight">1 個の重さ（g）</label>
            <input type="text" class="form-control" id="weight" name="weight" inputmode="numeric"
                   value="${empty param.weight ? '2000' : fn:escapeXml(param.weight)}">
          </div>
          <div class="form-group col-md-2 d-flex align-items-end">
            <div class="form-check mb-2">
              <input type="checkbox" class="form-check-input" id="member" name="member" value="1"
                     ${param.member eq '1' ? 'checked' : ''}>
              <label class="form-check-label" for="member">会員</label>
            </div>
          </div>
        </div>

        <button type="submit" class="btn btn-secondary">直す前の Servlet で計算</button>
        <button type="submit" class="btn btn-primary" formaction="${baseUrl}/refactored">直した後の Servlet で計算</button>
      </form>

      <p class="text-muted small mt-3 mb-0">
        どちらのボタンでも、同じ入力なら同じ結果になります（それをゴールデンマスターが確かめています）。
        カンマ付きの金額（<code>3,000</code>）や空欄を送ると、どちらも 500 エラーになります。
        これも「今の動き」として記録してあります。
      </p>
    </t:panel>

    <c:if test="${not empty requestScope.total}">
      <t:panel title="見積もり結果"
               note="${fn:endsWith(calculatedBy, '/refactored') ? '直した後の EstimateServlet が計算しました' : '直す前の LegacyEstimateServlet が計算しました'}">
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-0">
            <tbody>
              <tr><th style="width: 40%">見積番号</th><td><code>${fn:escapeXml(estimateNo)}</code>（毎回変わる）</td></tr>
              <tr><th>商品代金</th><td class="text-right">${amount} 円</td></tr>
              <tr><th>会員割引</th><td class="text-right">${discount > 0 ? '-' : ''}${discount} 円</td></tr>
              <tr><th>送料</th><td class="text-right">${ship} 円</td></tr>
              <tr><th>消費税</th><td class="text-right">${tax} 円</td></tr>
              <tr class="table-active"><th>請求金額</th><td class="text-right"><strong>${total} 円</strong></td></tr>
            </tbody>
          </table>
        </div>
      </t:panel>
    </c:if>

    <t:panel title="試してほしい入力" note="仕様化テストで「要確認」として記録した動き">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr><th>入力</th><th>結果</th><th>気になる点</th></tr>
          </thead>
          <tbody>
            <tr>
              <td>北海道・5000g と 東京・5000g</td>
              <td>送料 2,500 円 / 1,100 円</td>
              <td>境界（&lt; と &lt;=）が揃っていない</td>
            </tr>
            <tr>
              <td>一般・単価 10000</td>
              <td>送料 800 円</td>
              <td>会員は「以上」なのに、一般は「超える」で無料</td>
            </tr>
            <tr>
              <td>沖縄・会員・3000g、単価 4999 と 5000</td>
              <td>送料 1,800 円 / 1,200 円</td>
              <td>無料の対象外のはずが、条件を満たすと安くなる</td>
            </tr>
            <tr>
              <td>数量 0</td>
              <td>請求 880 円</td>
              <td>何も買っていないのに送料が掛かる</td>
            </tr>
            <tr>
              <td>数量 -1</td>
              <td>請求 -2,420 円</td>
              <td>マイナスの請求になる</td>
            </tr>
            <tr>
              <td>単価 ３０００（全角）</td>
              <td>3000 と同じ</td>
              <td>例外になると思い込んでいたが、そのまま計算される</td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>
  </jsp:body>
</t:sample>
