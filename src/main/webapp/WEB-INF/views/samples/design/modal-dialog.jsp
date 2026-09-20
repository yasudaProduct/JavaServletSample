<%--
  【サンプル】モーダル (ダイアログ) の出し方 6 パターン

    ① ボタンを押したら開く                      … HTML と JavaScript だけで完結
    ② 処理のあとに完了モーダル                  … forward で戻ってきたときに開く
    ③ 画面遷移のあとにモーダル                  … リダイレクト先で開く (PRG パターン)
    ④ 確認 → 登録 → 完了モーダル → 画面遷移    … 知らせてから次の画面へ送る
    ⑤ モーダルの入力を元の画面へ渡す            … 住所入力ダイアログ (通信なし)
    ⑥ モーダルで検索して選んだ行を元の画面へ渡す … 商品検索ダイアログ (候補は先に受け取る)

  ② 〜 ④ は ModalDialogServlet が処理結果をセットします。
  ⑥ の候補 (candidates) も ModalDialogServlet が request に載せています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<%-- ⑤ の都道府県。元の画面とモーダルの両方で同じ選択肢を使うので、1 か所に書いて使い回す --%>
<c:set var="prefectures" value="北海道,宮城県,東京都,神奈川県,愛知県,大阪府,広島県,福岡県,沖縄県" />
<t:sample sampleId="modal-dialog">

  <jsp:attribute name="explanation">
    <h2>6 つのパターンの使い分け</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>パターン</th><th>開くきっかけ</th><th>URL</th><th>向いている場面</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>① ボタンで開く</td>
            <td><code>data-toggle="modal"</code></td>
            <td>変わらない</td>
            <td>確認・注意書き・入力フォームなど、サーバに行く前の確認</td>
          </tr>
          <tr>
            <td>② 処理後の完了モーダル</td>
            <td>forward したページで JavaScript が開く</td>
            <td>POST したまま</td>
            <td>入力エラーで同じ画面に戻す場合（入力値をそのまま残せる）</td>
          </tr>
          <tr>
            <td>③ 画面遷移後のモーダル</td>
            <td>リダイレクト先で JavaScript が開く</td>
            <td>GET に変わる</td>
            <td>登録・更新・削除の完了通知（実務ではこれが基本）</td>
          </tr>
          <tr>
            <td>④ 確認 → 登録 → 完了モーダル → 画面遷移</td>
            <td>③ と同じ。閉じたときに次の画面へ移動する</td>
            <td>GET に変わり、さらに移動先へ</td>
            <td>登録したら一覧や詳細へ送る、入力の締めくくり</td>
          </tr>
          <tr>
            <td>⑤ 入力した内容を元の画面へ渡す</td>
            <td><code>data-toggle="modal"</code></td>
            <td>変わらない</td>
            <td>住所入力・条件設定など、狭い画面に入りきらない入力を別枠で受け取る</td>
          </tr>
          <tr>
            <td>⑥ 検索して選んだ行を元の画面へ渡す</td>
            <td><code>data-toggle="modal"</code></td>
            <td>変わらない</td>
            <td>商品・取引先・担当者などのコード入力（いわゆる検索ダイアログ）</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      ① 〜 ④ は<strong>サーバとのやり取りが主役</strong>のパターン、
      ⑤ と ⑥ は<strong>元の画面のフォームを埋めるのが目的</strong>のパターンです。
      後者はサーバへ行かないので、値の受け渡しをすべて JavaScript で書くことになります。
    </p>

    <h2>① ボタンを押したら開く</h2>
    <p>
      Bootstrap のモーダルは、<strong>開くボタン</strong>と<strong>中身</strong>の 2 つで出来ています。
      ボタンの <code>data-target</code> と、モーダル側の <code>id</code> を合わせるだけです。
      JavaScript を自分で書く必要はありません。
    </p>
<pre><code class="language-xml">&lt;!-- 開くボタン --&gt;
&lt;button type="button" data-toggle="modal" data-target="#confirmModal"&gt;削除する&lt;/button&gt;

&lt;!-- 中身 (画面のどこに置いてもよい) --&gt;
&lt;div class="modal fade" id="confirmModal" tabindex="-1" role="dialog"&gt;
  ...
&lt;/div&gt;</code></pre>

    <h2>② 処理のあとに完了モーダルを出す (forward)</h2>
    <p>
      Servlet が <code>request.setAttribute("resultTitle", ...)</code> で結果を入れて
      同じ JSP へ <code>forward</code> します。JSP 側は「結果が入っていればモーダルを書き出す」だけです。
      あとは読み込み後に JavaScript で開きます。
    </p>
<pre><code class="language-xml">&lt;c:if test="${'${not empty resultTitle}'}"&gt;
  &lt;div class="modal fade" id="resultModal" data-modal-autoshow&gt; ... &lt;/div&gt;
&lt;/c:if&gt;</code></pre>
    <p>
      注意点は <strong>URL が POST のまま</strong>だということです。
      完了モーダルを閉じたあとに再読み込みすると、ブラウザが「再送信しますか？」と聞いてきて、
      同じ処理が 2 回実行されてしまうおそれがあります。
    </p>

    <h2>③ 画面遷移のあとにモーダルを出す (PRG パターン)</h2>
    <p>
      登録・削除のあとは <strong>POST → リダイレクト → GET</strong> の流れにするのが定番です
      （Post / Redirect / Get の頭文字で PRG パターンと呼びます）。
      再読み込みしても GET が繰り返されるだけなので、二重登録が起きません。
    </p>
    <p>
      ただしリダイレクトすると別のリクエストになるため、<code>request.setAttribute</code> の値は消えます。
      そこで<strong>セッションにメッセージを預けて、次の 1 回だけ取り出して消す</strong>という受け渡しをします
      （フラッシュメッセージ）。この処理は <code>common/Flash.java</code> にまとめてあります。
    </p>
<pre><code class="language-java">// POST 側 : メッセージを預けてからリダイレクト
Flash.set(request, "success", "登録が完了しました", "受付番号は ... です。");
response.sendRedirect(request.getContextPath() + "/samples/design/modal-dialog");

// GET 側 : 取り出して request スコープへ移す (セッションからは消える)
Flash.consume(request);</code></pre>
    <p>
      一覧画面へ戻してから完了モーダルを出す、といった<strong>別の画面へ遷移させる場合</strong>も同じ方法で書けます。
      リダイレクト先を変えるだけです。このサンプル集では
      <a href="${ctx}/samples/file/file-upload">ファイルのアップロード</a> がこの形になっています。
      「完了を見せてから次の画面へ送りたい」場合は、続く ④ のように書きます。
    </p>

    <h2>④ 確認 → 登録 → 完了モーダル → 画面遷移</h2>
    <p>
      入力画面の締めくくりでよくある流れです。①（押したら確認）と ③（PRG で完了通知）を
      つなげ、最後に<strong>次の画面へ送る</strong>ところまでを 1 本にしています。
    </p>
<pre><code class="language-plaintext">［登録する］
   └→ 確認モーダル「よろしいですか？」
         └→ POST  (登録処理)
               └→ リダイレクト
                     └→ 完了モーダル「登録しました」
                           └→ 閉じる → 受付一覧へ移動</code></pre>

    <h3>移動先もフラッシュメッセージに預ける</h3>
    <p>
      ③ と違うのは、メッセージと一緒に<strong>移動先の URL</strong> も預けている点だけです。
      画面側は「移動先が入っていれば、閉じたときにそこへ行く」と書いておきます。
    </p>
<pre><code class="language-java">Flash.set(request, "success", "登録が完了しました",
        name + " さんを受付番号 " + receiptNumber + " で登録しました。",
        request.getContextPath() + "/samples/design/modal-dialog/entries");  // ← 移動先
response.sendRedirect(request.getContextPath() + "/samples/design/modal-dialog");</code></pre>

    <h3>閉じ方に関わらず移動させる</h3>
    <p>
      OK ボタンだけにリンクを張ると、<code>×</code> や <code>Esc</code> で閉じた人が
      その場に取り残されます。Bootstrap の <code>hidden.bs.modal</code>
      （閉じ終わったときに発生するイベント）を拾って、どの閉じ方でも移動するようにします。
    </p>
<pre><code class="language-javascript">$('[data-modal-next]').on('hidden.bs.modal', function () {
  window.location.href = $(this).data('modal-next');
});</code></pre>
    <p>
      OK ボタン自体は <code>&lt;a href="..."&gt;</code> にしてあります。
      JavaScript が動かない環境でも、リンクとしてなら移動できるためです。
    </p>

    <h3>なぜ「完了モーダル → 画面遷移」の順にするのか</h3>
    <ul>
      <li>
        <strong>先に遷移してしまうと結果が伝わりにくい</strong>：
        登録したのに何も出ないまま一覧が表示されると、成功したのか分かりません。
        受付番号のような「持ち帰ってほしい情報」がある場合はとくに困ります。
      </li>
      <li>
        <strong>それでも処理自体は先に終わらせる</strong>：
        モーダルを閉じたときに登録するのではなく、<strong>確認モーダルで実行した時点</strong>で
        登録まで終わらせます。閉じる操作を待つと、ブラウザを閉じられたときに登録されません。
      </li>
      <li>
        <strong>移動先は画面ではなくサーバが決める</strong>：
        「登録したら一覧へ」という業務の流れはサーバ側の判断なので、
        遷移先も Servlet が渡すようにしておくと、あとから変えるのが楽になります。
      </li>
    </ul>

    <h2>⑤ モーダルで入力した内容を元の画面へ渡す</h2>
    <p>
      住所や明細のように<strong>項目が多くて元の画面に置きたくない入力</strong>を、
      別枠で受け取るパターンです。モーダルは入力欄の集まりでしかなく、
      サーバへは行きません（最後に送信するのは、あくまで元の画面のフォームです）。
    </p>
    <ol>
      <li>「住所を入力する」ボタンでモーダルを開く</li>
      <li>開く直前に、<strong>元の画面の現在値をモーダルの入力欄へ写す</strong>（親 → モーダル）</li>
      <li>モーダルの中で入力する</li>
      <li>「反映する」で<strong>元の画面のフォームへ書き戻して閉じる</strong>（モーダル → 親）</li>
      <li>「キャンセル」「×」「Esc」で閉じたときは<strong>何もしない</strong></li>
    </ol>

    <h3>項目の対応づけは data 属性で持つ</h3>
    <p>
      「郵便番号は <code>#deliveryZip</code> へ、都道府県は <code>#deliveryPref</code> へ……」と
      1 項目ずつ書くと、項目が増えるたびに JavaScript も増えていきます。
      元の画面とモーダルの入力欄に<strong>同じ目印</strong>を付けておくと、まとめて写せます。
    </p>
<pre><code class="language-xml">&lt;!-- 元の画面 --&gt;
&lt;input type="text" id="deliveryZip" name="zip" data-address-field="zip"&gt;

&lt;!-- モーダルの中 (id は別にする。data 属性だけを合わせる) --&gt;
&lt;input type="text" id="addressZip" data-address-field="zip"&gt;</code></pre>
<pre><code class="language-javascript">// モーダル → 親 : 目印が同じ欄へ値を書き戻す
$modal.find('[data-address-field]').each(function () {
  var name = $(this).data('addressField');
  var $target = $form.find('[data-address-field="' + name + '"]');
  $target.val($(this).val()).trigger('change');
});</code></pre>
    <p>
      <code>&lt;select&gt;</code> でも <code>&lt;input&gt;</code> でも
      <code>.val()</code> の読み書きは同じなので、この書き方なら種類を気にせず扱えます。
    </p>

    <h2>⑥ モーダルで検索して選んだ行を元の画面へ渡す（検索ダイアログ）</h2>
    <p>
      商品コードや取引先コードのように「一覧から選ばせたい」入力で使う形です。
      このサンプルでは、候補を<strong>あらかじめ画面に書き出しておき</strong>、
      モーダルの中の絞り込みは JavaScript だけで行っています（通信しないので一瞬で反応します）。
    </p>
<pre><code class="language-java">// Servlet : 候補を 20 件だけ request に載せる
ProductSearch search = ProductSearch.from(new CandidateRequest(request));
request.setAttribute("candidates", productDao.search(search).getItems());</code></pre>
<pre><code class="language-xml">&lt;c:forEach var="product" items="${'${candidates}'}"&gt;
  &lt;%-- 絞り込みに使う文字列を、小文字にまとめて行に持たせておく --%&gt;
  &lt;c:set var="rowSearch"
         value="${'${fn:toLowerCase(product.code)} ${fn:toLowerCase(product.name)}'}" /&gt;
  &lt;tr data-product-search="${'${fn:escapeXml(rowSearch)}'}"&gt;
    &lt;td&gt;${'${fn:escapeXml(product.code)}'}&lt;/td&gt;
    &lt;td&gt;
      &lt;button type="button" data-product-code="${'${fn:escapeXml(product.code)}'}"
              data-product-price="${'${product.price}'}"&gt;選択&lt;/button&gt;
    &lt;/td&gt;
  &lt;/tr&gt;
&lt;/c:forEach&gt;</code></pre>
    <p>
      区切りの空白をわざわざ <code>c:set</code> の中で入れているのには理由があります。
      このサイトの <code>web.xml</code> では
      <code>&lt;trim-directive-whitespaces&gt;true&lt;/trim-directive-whitespaces&gt;</code> を有効にしているため、
      <strong>空白だけのテンプレート文字は出力から取り除かれます</strong>。
      <code>&lt;tr&gt;</code> のような<strong>ただの HTML</strong>の属性に
      <code>${'${a} ${b}'}</code> と並べて書くと、
      間の空白 1 つがちょうどこれに当たり、出力では
      <code>P-0045</code> と <code>27インチ モニター</code> がくっついて
      <code>p-004527インチ モニター</code> になってしまいます。
      <code>c:set</code> や <code>c:out</code> の<strong>属性値</strong>はテンプレート文字ではないので、
      その中で組み立てれば空白はそのまま残ります。
    </p>
<pre><code class="language-javascript">// 行の「選択」ボタン : 押された行の値を元の画面へ入れて閉じる
$('#productTable').on('click', '[data-product-code]', function () {
  var $button = $(this);
  setFieldValue($('#orderCode'),  $button.data('productCode'));
  setFieldValue($('#orderName'),  $button.data('productName'));
  setFieldValue($('#orderPrice'), $button.data('productPrice'));
  $('#productModal').modal('hide');
});</code></pre>

    <h3>候補を先に書き出してよいのは何件まで？</h3>
    <p>
      目安は<strong>数十件</strong>です。この作りは HTML が大きくなるかわりに、
      絞り込みが速く、通信も起きません。数百件・数千件になると、
      ページの読み込みが重くなるうえ「見せてはいけない行まで画面に書き出してしまう」ことにもなります。
      その場合は<strong>入力のたびにサーバへ問い合わせる</strong>形に切り替えます。
    </p>
    <ul>
      <li>
        件数が多いとき … <a href="${ctx}/samples/ajax/ajax-search">Ajax でインクリメンタル検索</a>
        （キーワードを入力するたびに JSON を取りに行き、結果だけを描き直します）。
        モーダルの中身をその結果で差し替えれば、同じ「検索ダイアログ」になります
      </li>
      <li>
        一覧そのものを見せたいとき …
        <a href="${ctx}/samples/list/search-list">検索つき一覧画面</a>（ページングと並び替え）
      </li>
    </ul>

    <h3>選んだ値をそのまま信用しない</h3>
    <p>
      このサンプルでは単価も画面に入れていますが、<strong>送信された単価を保存してはいけません</strong>。
      画面から来る値はいくらでも書き換えられるためです。
      サーバ側では<strong>商品コードだけを受け取り、名前と単価は DB から引き直す</strong>のが原則です。
      画面の単価は「利用者に見せるための表示」と考えます。
    </p>

    <h2>モーダルと元画面の値のやり取り</h2>

    <h3>親 → モーダル（開くときに現在値を渡す）</h3>
    <p>
      開くたびに元の画面の値を写しておくと、「開き直したら前回の入力が残っていた」という
      分かりにくい状態を防げます。Bootstrap は開く直前に <code>show.bs.modal</code> を発生させ、
      そのイベントの <code>relatedTarget</code> に<strong>開くきっかけになった要素</strong>を入れてくれます。
    </p>
<pre><code class="language-javascript">$('#addressModal').on('show.bs.modal', function (event) {
  var $opener = $(event.relatedTarget);              // 押されたボタン
  var $form = $($opener.data('addressForm'));        // data-address-form="#deliveryForm"
  // ... $form の値をモーダルの入力欄へ写す ...
});</code></pre>
    <p>
      「どのフォームへ返すか」をボタンの <code>data-</code> 属性に書いておくと、
      同じモーダルを<strong>複数の場所から使い回せます</strong>
      （一覧の行ごとに「編集」ボタンがある画面などで効いてきます）。
      JavaScript の中に <code>#deliveryForm</code> と直接書いてしまうと、その 1 か所でしか使えません。
    </p>

    <h3>モーダル → 親（閉じるときに値を返す）</h3>
    <p>
      値を入れるだけなら <code>.val()</code> で足りますが、
      <strong><code>change</code> イベントは自分で起こす</strong>必要があります。
      JavaScript で値を入れても、ブラウザは「利用者が入力した」とは扱ってくれないためです。
    </p>
<pre><code class="language-javascript">$target.val(value).trigger('change');   // ← trigger を忘れると入力チェックが反応しない</code></pre>
    <p>
      「フォーカスが外れたら検査する」「未入力なら送信ボタンを無効にする」といった処理を
      別に書いている場合、この 1 行の有無で挙動が変わります。
    </p>

    <h3>モーダルの中に form を入れ子にしない</h3>
    <p>
      HTML では <code>&lt;form&gt;</code> の中に <code>&lt;form&gt;</code> を書けません
      （書いても内側は無視されます）。元の画面のフォームの<strong>中</strong>にモーダルを置くと、
      モーダルの中で <code>&lt;form&gt;</code> を使えなくなり、
      さらに<strong>モーダルの入力欄が元のフォームと一緒に送信されてしまいます</strong>。
    </p>
    <ul>
      <li>モーダルの HTML は、元の画面のフォームの<strong>外</strong>（多くは画面の末尾）に置く</li>
      <li>値を渡すだけのモーダルなら、中に <code>&lt;form&gt;</code> は要らない（このサンプルもそうしています）</li>
      <li>
        モーダルの入力欄に <code>name</code> を付けない、または
        <code>form="..."</code> で紐づけないでおく
        （「反映する」を押す前の値まで送信されてしまうのを防ぐため）
      </li>
    </ul>

    <h3>id の重複に注意する</h3>
    <p>
      元の画面とモーダルで<strong>同じ項目を扱う</strong>ので、同じ <code>id</code> を付けたくなります。
      ですが <code>id</code> が重複すると <code>$('#zip')</code> は先に見つかった 1 つしか返さず、
      「片方にしか値が入らない」という原因の分かりにくい不具合になります。
      <code>&lt;label for="zip"&gt;</code> をクリックしたときも、同じ理由で
      先に書かれている方の欄にフォーカスが移ってしまいます。
    </p>
<pre><code class="language-plaintext">元の画面   : id="deliveryZip"  data-address-field="zip"
モーダル   : id="addressZip"   data-address-field="zip"   ← id は別、目印は同じ</code></pre>

    <h3>閉じたときに中身を初期化するか</h3>
    <p>
      どちらが正しいということはなく、<strong>「開いたときに必ず埋め直すか」で決めます</strong>。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>やり方</th><th>書く場所</th><th>向いている場面</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>開くときに元の画面の値で埋め直す</td>
            <td><code>show.bs.modal</code></td>
            <td>⑤ の住所入力。前回の状態が残らないので初期化は不要</td>
          </tr>
          <tr>
            <td>閉じたときに入力を消す</td>
            <td><code>hidden.bs.modal</code></td>
            <td>⑥ の検索キーワード。次に開いたときに絞り込みが残っていると戸惑うため</td>
          </tr>
          <tr>
            <td>あえて残す</td>
            <td>（何も書かない）</td>
            <td>同じ条件で何度も検索する画面。「前回の続き」から始められる</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>モーダルを開く JavaScript</h2>
    <p>
      サーバから渡された結果があるときだけ開きたいので、モーダルに目印
      (<code>data-modal-autoshow</code>) を付けておき、画面の読み込み後にまとめて開いています。
    </p>
<pre><code class="language-javascript">$(function () {
  $('[data-modal-autoshow]').modal('show');
});</code></pre>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>モーダルが開かない</strong>：
        jQuery → Bootstrap の順に読み込めているか、<code>data-target</code> と <code>id</code> が
        一致しているかを確認します（<code>#</code> の付け忘れが多いです）。
      </li>
      <li>
        <strong>モーダルの中のボタンで送信できない</strong>：
        モーダルの中に <code>&lt;form&gt;</code> を置くか、モーダルの中の送信ボタンに
        <code>form="フォームの id"</code> を付けて<strong>モーダルの外のフォーム</strong>を指すか、
        どちらかにします（④ は後者です）。<code>&lt;form&gt;</code> の入れ子は無効です。
      </li>
      <li>
        <strong>閉じたあとにもう一度出てしまう</strong>：
        フラッシュメッセージを取り出したあとにセッションから消していないと、次の画面にも出続けます。
      </li>
      <li>
        <strong>移動先の URL を画面から受け取らない</strong>：
        <code>?next=...</code> のように<strong>利用者から</strong>渡された URL へそのまま移動すると、
        外部サイトへ飛ばされる踏み台になります（オープンリダイレクト）。
        ④ の移動先はサーバ側で決め打ちしています。
      </li>
      <li>
        <strong>表示する文字はエスケープする</strong>：
        サーバから渡した文字列をそのまま出すと HTML として解釈されます
        （<code>fn:escapeXml</code> を通します）。
        ⑥ のように <code>data-</code> 属性へ値を埋めるときも同じです。
      </li>
      <li>
        <strong>並べて書いた <code>${'${...}'}</code> の間の空白が消える</strong>：
        <code>web.xml</code> の <code>trim-directive-whitespaces</code> を有効にしていると、
        <strong>空白だけのテンプレート文字</strong>が出力から取り除かれます。
        <code>${'${a} ${b}'}</code> の間の空白 1 つもその対象なので、
        画面では 2 つの値がくっついて出ます
        （⑥ の絞り込み用文字列がこれに当たり、<code>c:set</code> の属性値の中で
        組み立てることで避けています）。
        文章の途中のように前後に文字がある空白は消えないため、気づきにくい落とし穴です。
      </li>
      <li>
        <strong>値を入れたのに入力チェックが動かない</strong>：
        <code>.val()</code> で値を入れても <code>change</code> は発生しません。
        <code>.trigger('change')</code> を添えます（⑤ ⑥ の共通処理にしてあります）。
      </li>
      <li>
        <strong>フォーカスが当たらない</strong>：
        <code>show.bs.modal</code>（開く直前）の時点ではまだ表示されていないため
        <code>.focus()</code> が効きません。開き終わったあとの
        <code>shown.bs.modal</code> で当てます。
      </li>
      <li>
        <strong><code>.data()</code> が文字列を返すとは限らない</strong>：
        jQuery の <code>.data()</code> は、<strong>文字列に戻しても元と同じになる数値</strong>だけを
        数値へ変換します。<code>data-price="38800"</code> は数値の <code>38800</code> になり、
        <code>data-code="P-0045"</code> はもちろん、<code>data-code="0012"</code> も
        （<code>"12"</code> に変わってしまうので）文字列のままです。
        つまり<strong>同じ書き方でも属性の値しだいで型が変わります</strong>。
        <code>.length</code> や <code>.substring()</code> を当てにするところで急に落ちるので、
        文字列として扱いたいときは <code>String(...)</code> で包むか
        <code>.attr('data-code')</code> を使います（⑥ では欄へ入れる直前に
        <code>String(...)</code> で揃えています）。
      </li>
      <li>
        <strong><code>readonly</code> と <code>disabled</code> を取り違える</strong>：
        検索ダイアログで選ばせる欄は編集させたくないので <code>readonly</code> にします。
        <code>disabled</code> にすると<strong>送信されません</strong>
        （どうしても <code>disabled</code> にしたい場合は <code>hidden</code> を別に用意します）。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // サーバ側の処理結果として書き出されたモーダルを開く (② 〜 ④ で使用)
      $(function () {
        $('[data-modal-autoshow]').modal('show');
      });

      // ④ 完了モーダルを閉じたら、預かっていた画面へ移動する
      //    (OK ボタンはリンクにしてあるので、× や Esc で閉じた場合の受け皿)
      $(function () {
        $('[data-modal-next]').on('hidden.bs.modal', function () {
          window.location.href = $(this).data('modal-next');
        });
      });

      // ① の「はい」を押したときの表示切り替え (この画面の中だけで完結する処理)
      $(function () {
        $('#confirmYes').on('click', function () {
          $('#confirmModal').modal('hide');
          $('#confirmResult').removeClass('d-none');
        });
      });

      // ------------------------------------------------------------------
      // ⑤ ⑥ の共通処理 : モーダルから元の画面の欄へ値を入れる
      // ------------------------------------------------------------------

      /**
       * 値が入った欄を一瞬だけ光らせて、どこが変わったのかを分かるようにする。
       * (共通の app.css は編集しない決まりなので、この画面の中でスタイルを当てて時間差で戻している)
       */
      function flashField($field) {
        if ($field.length === 0) {
          return;
        }
        $field.css({ 'transition': 'background-color 0.8s ease', 'background-color': '#fff3cd' });
        window.setTimeout(function () { $field.css('background-color', ''); }, 900);
        window.setTimeout(function () { $field.css('transition', ''); }, 1800);
      }

      /**
       * 欄に値を入れる。変わったときだけ true を返す。
       * 値を JavaScript で入れてもブラウザは change を起こさないので、自分で通知する
       * (入力チェックなど、change を見て動く処理に気づいてもらうため)。
       */
      function setFieldValue($field, value) {
        var text = (value === undefined || value === null) ? '' : String(value);
        var changed = $field.val() !== text;

        $field.val(text).trigger('change');
        if (changed) {
          flashField($field);
        }
        return changed;
      }

      // ------------------------------------------------------------------
      // ⑤ 住所入力ダイアログ (モーダルの入力 → 元の画面のフォーム)
      // ------------------------------------------------------------------
      $(function () {
        var $modal = $('#addressModal');

        // --- 親 → モーダル : 開く直前に、元の画面の現在値を写す ---
        $modal.on('show.bs.modal', function (event) {
          // event.relatedTarget = 開くきっかけになったボタン。
          // 「どのフォームとやり取りするか」はボタンの data 属性で受け取る
          // (こう書いておくと、同じモーダルを別の場所からも使い回せる)
          var $opener = $(event.relatedTarget);
          var $form = $($opener.data('addressForm') || '#deliveryForm');

          // 「反映する」を押したときに使うので、相手のフォームを覚えておく
          $modal.data('targetForm', $form);

          // 目印 (data-address-field) が同じ欄どうしを突き合わせて写す
          $modal.find('[data-address-field]').each(function () {
            var name = $(this).data('addressField');
            $(this).val($form.find('[data-address-field="' + name + '"]').val());
          });
          $('#addressApplied').addClass('d-none');
        });

        // 開き終わってから先頭の欄へフォーカスする。
        // show.bs.modal (開く直前) ではまだ表示されていないのでフォーカスが当たらない
        $modal.on('shown.bs.modal', function () {
          $('#addressZip').trigger('focus');
        });

        // --- モーダル → 親 : 「反映する」で書き戻して閉じる ---
        //     キャンセル・×・Esc で閉じたときはここを通らないので、元の画面は変わらない
        $('#addressApply').on('click', function () {
          var $form = $modal.data('targetForm') || $('#deliveryForm');
          var changed = 0;

          $modal.find('[data-address-field]').each(function () {
            var name = $(this).data('addressField');
            var $target = $form.find('[data-address-field="' + name + '"]');
            if (setFieldValue($target, $(this).val())) {
              changed++;
            }
          });

          $('#addressApplied')
            .text(changed === 0 ? '反映しました（変更はありませんでした）。'
                                : '反映しました（' + changed + ' 項目が変わりました）。')
            .removeClass('d-none');

          $modal.modal('hide');
        });
      });

      // ------------------------------------------------------------------
      // ⑥ 商品検索ダイアログ (描画済みの行を絞り込み → 選んだ行を元の画面へ)
      // ------------------------------------------------------------------
      $(function () {
        var $modal = $('#productModal');
        var $rows = $('#productTable tbody tr[data-product-search]');

        /** キーワードに一致しない行を隠す。通信はしない (行はすでに画面にある)。 */
        function filterRows() {
          // 候補が 0 件のときはキーワード欄自体が無いので、値が取れない場合に備える
          var keyword = ($('#productKeyword').val() || '').trim().toLowerCase();
          var shown = 0;

          $rows.each(function () {
            // .data() は値を自動で型変換するので、String で文字列に揃えてから探す
            var text = String($(this).data('productSearch'));
            var hit = keyword === '' || text.indexOf(keyword) >= 0;

            $(this).toggleClass('d-none', !hit);
            if (hit) {
              shown++;
            }
          });

          $('#productShown').text(shown);
          $('#productNoHit').toggleClass('d-none', shown > 0);
        }

        // 入力のたびに絞り込む (keyup ではなく input にすると、貼り付けや ×ボタンにも反応する)
        $('#productKeyword').on('input', filterRows);

        // 行の「選択」ボタン : 押された行の値を元の画面の 3 つの欄へ入れて閉じる。
        // 行はあとから差し替える可能性があるので、表に対して委譲して待ち受ける
        $('#productTable').on('click', '[data-product-code]', function () {
          var $button = $(this);

          setFieldValue($('#orderCode'), $button.data('productCode'));
          setFieldValue($('#orderName'), $button.data('productName'));
          setFieldValue($('#orderPrice'), $button.data('productPrice'));

          $('#orderEmpty').addClass('d-none');
          $('#orderSelected').removeClass('d-none');
          $modal.modal('hide');
        });

        $modal.on('shown.bs.modal', function () {
          $('#productKeyword').trigger('focus');
        });

        // 閉じたらキーワードを消す。
        // ⑤ と違って「開くときに埋め直す」値が無いので、閉じるときに初期化しておく
        $modal.on('hidden.bs.modal', function () {
          $('#productKeyword').val('');
          filterRows();
        });

        // 選んだ商品を取り消す。
        // 空にするときも change を起こしておく (値を入れるときと同じ理由)
        $('#orderClear').on('click', function () {
          $('#orderForm').find('[data-product-field]').val('').trigger('change');
          $('#orderSelected').addClass('d-none');
          $('#orderEmpty').removeClass('d-none');
        });
      });

      // ⑤ ⑥ のフォームは送信先を用意していないので、Enter キーでの送信だけ止めておく
      $(function () {
        $('#deliveryForm, #orderForm').on('submit', function (event) {
          event.preventDefault();
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ============================================================
         ① ボタンを押したらモーダルを開く (サーバとのやり取りなし)
         ============================================================ --%>
    <t:panel title="① ボタンを押したらモーダルを開く" note="HTML と data 属性だけで動きます">
      <p>
        <code>data-toggle="modal"</code> と <code>data-target="#id"</code> を付けたボタンを押すと、
        同じ <code>id</code> のモーダルが開きます。JavaScript を書く必要はありません。
      </p>

      <button type="button" class="btn btn-outline-primary" data-toggle="modal" data-target="#infoModal">
        お知らせを表示
      </button>
      <button type="button" class="btn btn-outline-danger ml-2" data-toggle="modal" data-target="#confirmModal">
        削除の確認
      </button>

      <div id="confirmResult" class="alert alert-secondary mt-3 mb-0 d-none">
        「はい」が押されました（この画面の中だけで処理しています）。
      </div>
    </t:panel>

    <%-- ============================================================
         ② 処理のあとに完了モーダルを出す (forward)
         ============================================================ --%>
    <t:panel title="② 処理のあとに完了モーダルを出す" note="POST → forward : URL は変わりません">
      <p>
        送信すると Servlet が受付番号を作り、<strong>同じ画面へ forward</strong> して完了モーダルを開きます。
        アドレスバーは POST したときの URL のままです。
      </p>
      <form action="${ctx}/samples/design/modal-dialog" method="post" class="form-inline">
        <input type="hidden" name="action" value="forward">
        <label class="mr-2" for="forwardName">お名前</label>
        <input type="text" class="form-control mr-2" id="forwardName" name="name"
               placeholder="例: 山田太郎" size="20" maxlength="20">
        <button type="submit" class="btn btn-primary">送信する</button>
      </form>
    </t:panel>

    <%-- ============================================================
         ③ 画面遷移のあとにモーダルを出す (PRG パターン)
         ============================================================ --%>
    <t:panel title="③ 画面遷移のあとにモーダルを出す" note="POST → リダイレクト → GET : 再読み込みしても安全">
      <p>
        送信すると Servlet がメッセージをセッションに預けてリダイレクトし、
        <strong>移動した先</strong>で完了モーダルを開きます。
        完了後に再読み込みしても、登録が繰り返されることはありません。
      </p>
      <form action="${ctx}/samples/design/modal-dialog" method="post" class="form-inline">
        <input type="hidden" name="action" value="redirect">
        <label class="mr-2" for="redirectName">お名前</label>
        <input type="text" class="form-control mr-2" id="redirectName" name="name"
               placeholder="例: 山田太郎" size="20" maxlength="20">
        <button type="submit" class="btn btn-primary">送信する</button>
      </form>
    </t:panel>

    <%-- ============================================================
         ④ 確認モーダル → 登録 → 完了モーダル → 画面遷移
         ============================================================ --%>
    <t:panel title="④ 確認 → 登録 → 完了モーダル → 画面遷移"
             note="実務でよくある一連の流れ">
      <p>
        登録ボタンで<strong>確認モーダル</strong>を出し、実行したら登録して
        <strong>完了モーダル</strong>で知らせ、閉じたら<strong>受付一覧へ移動</strong>します。
        ①（確認）と ③（PRG）を組み合わせた形です。
      </p>
      <form id="registerForm" action="${ctx}/samples/design/modal-dialog" method="post" class="form-inline">
        <input type="hidden" name="action" value="move">
        <label class="mr-2" for="moveName">お名前</label>
        <input type="text" class="form-control mr-2" id="moveName" name="name"
               placeholder="例: 山田太郎" size="20" maxlength="20">
        <button type="button" class="btn btn-success" data-toggle="modal" data-target="#registerModal">
          登録する
        </button>
      </form>
      <p class="text-muted small mt-3 mb-0">
        登録した内容は
        <a href="${ctx}/samples/design/modal-dialog/entries">受付一覧</a>
        （セッションに保存。見えるのは自分の分だけです）で確認できます。
      </p>
    </t:panel>

    <%-- ============================================================
         ⑤ モーダルで入力した内容を元の画面のフォームへ渡す
            サーバへは行かない。値の受け渡しはすべて JavaScript。
         ============================================================ --%>
    <t:panel title="⑤ モーダルの入力を元の画面のフォームへ渡す"
             note="住所入力ダイアログ : サーバへは行きません">
      <p>
        「住所を入力する」でモーダルが開きます。開いた時点で<strong>下のフォームの現在値</strong>が
        モーダルに入っていること、「反映する」で戻ってくること、
        「キャンセル」では何も変わらないことを確かめてみてください。
        反映された欄は一瞬だけ色が変わります。
      </p>

      <%-- モーダルはこのフォームの「外」(画面の末尾) に置いている。
           中に置くと form の入れ子になり、モーダルの入力欄まで一緒に送信されてしまう --%>
      <form id="deliveryForm" class="form-row">
        <div class="form-group col-sm-6 col-md-3 mb-2">
          <label for="deliveryZip">郵便番号</label>
          <input type="text" class="form-control" id="deliveryZip" name="zip"
                 data-address-field="zip" placeholder="000-0000" maxlength="8">
        </div>
        <div class="form-group col-sm-6 col-md-3 mb-2">
          <label for="deliveryPref">都道府県</label>
          <select class="form-control" id="deliveryPref" name="pref" data-address-field="pref">
            <option value="">選択してください</option>
            <c:forEach var="pref" items="${fn:split(prefectures, ',')}">
              <option value="${fn:escapeXml(pref)}">${fn:escapeXml(pref)}</option>
            </c:forEach>
          </select>
        </div>
        <div class="form-group col-sm-6 col-md-3 mb-2">
          <label for="deliveryCity">市区町村</label>
          <input type="text" class="form-control" id="deliveryCity" name="city"
                 data-address-field="city" placeholder="例: 千代田区" maxlength="40">
        </div>
        <div class="form-group col-sm-6 col-md-3 mb-2">
          <label for="deliveryStreet">番地・建物名</label>
          <input type="text" class="form-control" id="deliveryStreet" name="street"
                 data-address-field="street" placeholder="例: 丸の内 1-1-1" maxlength="60">
        </div>
      </form>

      <%-- 「どのフォームへ返すか」をボタンの data 属性に書いておく (JS に画面の id を埋め込まない) --%>
      <button type="button" class="btn btn-outline-primary" data-toggle="modal"
              data-target="#addressModal" data-address-form="#deliveryForm">
        <t:icon name="input-cursor-text" size="14" cssClass="mr-1" />住所を入力する
      </button>

      <div id="addressApplied" class="alert alert-success mt-3 mb-0 d-none" role="status"></div>
    </t:panel>

    <%-- ============================================================
         ⑥ モーダルで検索して選んだ行を元の画面のフォームへ渡す
            候補は ModalDialogServlet が request に載せている (candidates)。
         ============================================================ --%>
    <t:panel title="⑥ モーダルで検索して選んだ行を元の画面へ渡す"
             note="商品検索ダイアログ : 候補は先に受け取り、絞り込みは画面の中だけ">
      <p>
        「商品を検索」で候補の一覧が開きます。キーワードを入れると
        <strong>通信せずに</strong>その場で絞り込まれ、「選択」を押すと下の 3 つの欄に入って閉じます。
      </p>

      <form id="orderForm" class="form-row">
        <div class="form-group col-sm-4 col-md-3 mb-2">
          <label for="orderCode">商品コード</label>
          <input type="text" class="form-control" id="orderCode" name="code"
                 data-product-field="code" readonly placeholder="未選択">
        </div>
        <div class="form-group col-sm-8 col-md-6 mb-2">
          <label for="orderName">商品名</label>
          <input type="text" class="form-control" id="orderName" name="name"
                 data-product-field="name" readonly placeholder="未選択">
        </div>
        <div class="form-group col-sm-4 col-md-3 mb-2">
          <label for="orderPrice">単価</label>
          <div class="input-group">
            <%-- 選ばせる欄なので readonly。disabled にすると送信されないので注意 --%>
            <input type="text" class="form-control text-right" id="orderPrice" name="price"
                   data-product-field="price" readonly placeholder="0">
            <div class="input-group-append"><span class="input-group-text">円</span></div>
          </div>
        </div>
      </form>

      <button type="button" class="btn btn-outline-primary" data-toggle="modal" data-target="#productModal">
        <t:icon name="search" size="14" cssClass="mr-1" />商品を検索
      </button>
      <button type="button" class="btn btn-link" id="orderClear">クリア</button>

      <p id="orderEmpty" class="text-muted small mt-3 mb-0">まだ商品が選ばれていません。</p>
      <p id="orderSelected" class="text-muted small mt-3 mb-0 d-none">
        選択しました。サーバへ送って保存するときは<strong>商品コードだけ</strong>を信用し、
        商品名と単価は DB から引き直します（画面の値は書き換えられるためです）。
      </p>
    </t:panel>

    <%-- ============================================================
         モーダルの中身
         ここから下はすべて、上のフォームの「外」に置いている
         ============================================================ --%>

    <%-- ① お知らせ (閉じるだけ) --%>
    <div class="modal fade" id="infoModal" tabindex="-1" role="dialog"
         aria-labelledby="infoModalTitle" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="infoModalTitle">お知らせ</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <p class="mb-0">
              これは <code>data-toggle="modal"</code> だけで開いたモーダルです。
              サーバへのリクエストは発生していません。
            </p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">閉じる</button>
          </div>
        </div>
      </div>
    </div>

    <%-- ① 確認 (はい / いいえ) --%>
    <div class="modal fade" id="confirmModal" tabindex="-1" role="dialog"
         aria-labelledby="confirmModalTitle" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="confirmModalTitle">削除の確認</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <p class="mb-0">このデータを削除します。よろしいですか？</p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">いいえ</button>
            <button type="button" class="btn btn-danger" id="confirmYes">はい</button>
          </div>
        </div>
      </div>
    </div>

    <%-- ④ 登録の確認 (押すと外にあるフォームを送信する) --%>
    <div class="modal fade" id="registerModal" tabindex="-1" role="dialog"
         aria-labelledby="registerModalTitle" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="registerModalTitle">登録の確認</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <p class="mb-0">入力した内容で登録します。よろしいですか？</p>
            <p class="text-muted small mt-2 mb-0">登録すると受付一覧へ移動します。</p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">キャンセル</button>
            <%-- form 属性を使うと、モーダルの外にあるフォームを送信できる --%>
            <button type="submit" class="btn btn-success" form="registerForm">登録する</button>
          </div>
        </div>
      </div>
    </div>

    <%-- ⑤ 住所の入力。
         中に <form> は置かない (送信しないので不要。元の画面のフォームと入れ子にもしない)。
         入力欄に name を付けていないのも、うっかり一緒に送信されないようにするため。
         id は元の画面と重ならないように別名にし、対応づけは data-address-field で行う。 --%>
    <div class="modal fade" id="addressModal" tabindex="-1" role="dialog"
         aria-labelledby="addressModalTitle" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="addressModalTitle">お届け先の入力</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <p class="text-muted small">
              いま元の画面に入っている値を初期表示しています。
              「反映する」を押すと、この内容が元の画面のフォームへ入ります。
            </p>
            <div class="form-group">
              <label for="addressZip">郵便番号</label>
              <input type="text" class="form-control" id="addressZip"
                     data-address-field="zip" placeholder="000-0000" maxlength="8">
            </div>
            <div class="form-group">
              <label for="addressPref">都道府県</label>
              <select class="form-control" id="addressPref" data-address-field="pref">
                <option value="">選択してください</option>
                <c:forEach var="pref" items="${fn:split(prefectures, ',')}">
                  <option value="${fn:escapeXml(pref)}">${fn:escapeXml(pref)}</option>
                </c:forEach>
              </select>
            </div>
            <div class="form-group">
              <label for="addressCity">市区町村</label>
              <input type="text" class="form-control" id="addressCity"
                     data-address-field="city" placeholder="例: 千代田区" maxlength="40">
            </div>
            <div class="form-group mb-0">
              <label for="addressStreet">番地・建物名</label>
              <input type="text" class="form-control" id="addressStreet"
                     data-address-field="street" placeholder="例: 丸の内 1-1-1" maxlength="60">
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">キャンセル</button>
            <button type="button" class="btn btn-primary" id="addressApply">反映する</button>
          </div>
        </div>
      </div>
    </div>

    <%-- ⑥ 商品の検索。
         候補 (candidates) は ModalDialogServlet が request に載せたもの。
         絞り込みに使う文字列は data-product-search に小文字で持たせ、JavaScript から探す。 --%>
    <div class="modal fade" id="productModal" tabindex="-1" role="dialog"
         aria-labelledby="productModalTitle" aria-hidden="true">
      <%-- 候補が 20 件あって縦に長くなるので、modal-dialog-scrollable で
           モーダルの中だけをスクロールさせる (Bootstrap 4.3 以降のクラス) --%>
      <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="productModalTitle">
              <t:icon name="search" size="16" cssClass="mr-2" />商品を検索
            </h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <c:choose>
              <c:when test="${empty candidates}">
                <div class="empty-state mb-0">
                  <t:icon name="search" size="32" cssClass="empty-state__icon" />
                  <p class="empty-state__text mb-0">候補が 1 件もありません。</p>
                </div>
              </c:when>
              <c:otherwise>
                <div class="form-group">
                  <label class="sr-only" for="productKeyword">キーワード</label>
                  <input type="search" class="form-control" id="productKeyword" autocomplete="off"
                         placeholder="商品名・コード・カテゴリで絞り込み（サーバへは問い合わせません）">
                </div>

                <p class="text-muted small mb-2">
                  候補 ${fn:length(candidates)} 件中
                  <strong id="productShown">${fn:length(candidates)}</strong> 件を表示
                </p>

                <div class="table-responsive">
                  <table class="table table-sm table-hover mb-0" id="productTable">
                    <thead class="thead-light">
                      <tr>
                        <th scope="col">コード</th>
                        <th scope="col">商品名</th>
                        <th scope="col">カテゴリ</th>
                        <th scope="col" class="text-right">単価</th>
                        <th scope="col" class="text-right">選択</th>
                      </tr>
                    </thead>
                    <tbody>
                      <c:forEach var="product" items="${candidates}">
                        <%-- 絞り込みに使う文字列は c:set で組み立てる。
                             web.xml で trim-directive-whitespaces を有効にしているため、
                             属性値の中に ${...} を並べて空白で区切ると、
                             その空白 (空白だけのテンプレート文字) が消えて項目どうしがくっついてしまう。
                             c:set の属性値はテンプレート文字ではないので、区切りの空白が残る --%>
                        <c:set var="rowSearch"
                               value="${fn:toLowerCase(product.code)} ${fn:toLowerCase(product.name)} ${fn:toLowerCase(product.category)}" />
                        <tr data-product-search="${fn:escapeXml(rowSearch)}">
                          <td class="align-middle"><code>${fn:escapeXml(product.code)}</code></td>
                          <td class="align-middle">${fn:escapeXml(product.name)}</td>
                          <td class="align-middle">${fn:escapeXml(product.category)}</td>
                          <td class="align-middle text-right">
                            <fmt:formatNumber value="${product.price}" type="number" />
                          </td>
                          <td class="align-middle text-right">
                            <%-- 選んだ値は data 属性で運ぶ。単価はカンマ無しの数値のまま渡す
                                 (画面に出すときだけカンマを付ける) --%>
                            <button type="button" class="btn btn-sm btn-outline-primary"
                                    data-product-code="${fn:escapeXml(product.code)}"
                                    data-product-name="${fn:escapeXml(product.name)}"
                                    data-product-price="${product.price}">選択</button>
                          </td>
                        </tr>
                      </c:forEach>
                      <tr id="productNoHit" class="d-none">
                        <td colspan="5" class="text-center text-muted py-3">
                          キーワードに一致する商品がありません。
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <p class="text-muted small mt-3 mb-0">
                  候補は Servlet が ${fn:length(candidates)} 件だけ取り出して画面に書き出しています。
                  件数が多い場合は、入力のたびにサーバへ問い合わせる
                  <a href="${ctx}/samples/ajax/ajax-search">Ajax 検索</a>に切り替えます。
                </p>
              </c:otherwise>
            </c:choose>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">閉じる</button>
          </div>
        </div>
      </div>
    </div>

    <%-- ② forward で戻ってきたときだけ書き出される完了モーダル --%>
    <c:if test="${not empty resultTitle}">
      <div class="modal fade" id="resultModal" tabindex="-1" role="dialog"
           aria-labelledby="resultModalTitle" aria-hidden="true" data-modal-autoshow>
        <div class="modal-dialog modal-dialog-centered" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="resultModalTitle">
                <t:icon name="check-circle" cssClass="text-success mr-2" />${fn:escapeXml(resultTitle)}
              </h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p class="mb-0">${fn:escapeXml(resultText)}</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-primary" data-dismiss="modal">OK</button>
            </div>
          </div>
        </div>
      </div>
    </c:if>

    <%-- ③ / ④ リダイレクト後にフラッシュメッセージがあるときだけ書き出される完了モーダル。
         ④ では移動先 (flash.nextUrl) も預かっているので、閉じたらその画面へ移動する。 --%>
    <c:if test="${not empty flash}">
      <div class="modal fade" id="flashModal" tabindex="-1" role="dialog"
           aria-labelledby="flashModalTitle" aria-hidden="true" data-modal-autoshow
           <c:if test="${not empty flash.nextUrl}">data-modal-next="${fn:escapeXml(flash.nextUrl)}"</c:if>>
        <div class="modal-dialog modal-dialog-centered" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="flashModalTitle">
                <t:icon name="check-circle" cssClass="text-${flash.variant} mr-2" />${fn:escapeXml(flash.title)}
              </h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p class="mb-0">${fn:escapeXml(flash.text)}</p>
              <c:choose>
                <c:when test="${not empty flash.nextUrl}">
                  <p class="text-muted small mt-3 mb-0">
                    閉じる操作（OK・×・Esc）のどれでも受付一覧へ移動します。
                  </p>
                </c:when>
                <c:otherwise>
                  <p class="text-muted small mt-3 mb-0">
                    アドレスバーの URL が <code>POST</code> から <code>GET</code> に変わっていること、
                    このまま再読み込みしても「再送信しますか？」と聞かれないことを確認してみてください。
                  </p>
                </c:otherwise>
              </c:choose>
            </div>
            <div class="modal-footer">
              <c:choose>
                <c:when test="${not empty flash.nextUrl}">
                  <%-- JavaScript が動かない環境でも移動できるよう、OK はリンクにしておく --%>
                  <a class="btn btn-${flash.variant}" href="${fn:escapeXml(flash.nextUrl)}">
                    OK（受付一覧へ）
                  </a>
                </c:when>
                <c:otherwise>
                  <button type="button" class="btn btn-${flash.variant}" data-dismiss="modal">OK</button>
                </c:otherwise>
              </c:choose>
            </div>
          </div>
        </div>
      </div>
    </c:if>
  </jsp:body>
</t:sample>
