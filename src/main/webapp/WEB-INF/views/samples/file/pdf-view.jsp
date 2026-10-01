<%--
  【サンプル】PDF を画面に表示する

    ① ファイルとして保存されている PDF を表示する … PdfFromFileServlet が返す
    ② DB に保存されている PDF を表示する           … PdfFromDbServlet が返す
    ③ 同じ画面の中に埋め込む                       … iframe
    ④ 別タブで開く                                 … target="_blank"
    ⑤ ポップアップで開く                           … モーダル / window.open

  ③ 〜 ⑤ はどれも ② と同じ URL を開いているだけで、違うのは画面側の見せ方です。

  PdfViewServlet が次の値をセットします。
    folderLocation … PDF を置いているフォルダ（/WEB-INF/pdf）
    folderFiles    … そのフォルダにある PDF の一覧（PdfFolder.Entry）
    documents      … DB に入っている PDF の一覧（PdfDocument）
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<%-- PDF を返す 2 つの Servlet の URL --%>
<c:set var="fileUrl" value="${ctx}/samples/file/pdf-view/file" />
<c:set var="dbUrl" value="${ctx}/samples/file/pdf-view/db" />
<t:sample sampleId="pdf-view">

  <jsp:attribute name="explanation">
    <h2>5 つのパターンの全体像</h2>
    <p>
      ① ② は<strong>サーバ側</strong>（PDF をどこから読んで、どう返すか）、
      ③ 〜 ⑤ は<strong>画面側</strong>（返ってきた PDF をどこに出すか）の話です。
      ③ 〜 ⑤ はどれも ② と同じ URL を開いているだけで、Servlet は 1 つも増えていません。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>パターン</th><th>仕組み</th><th>向いている場面</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>① ファイルから表示</td>
            <td>フォルダのファイルを Servlet が読んで返す</td>
            <td>マニュアル・規約など、あらかじめ用意してある PDF</td>
          </tr>
          <tr>
            <td>② DB から表示</td>
            <td><code>BLOB</code> 列を Servlet が読んで返す</td>
            <td>見積書・請求書など、システムが作って保存した帳票</td>
          </tr>
          <tr>
            <td>③ 画面の中に埋め込む</td>
            <td><code>&lt;iframe src="PDF の URL"&gt;</code></td>
            <td>一覧と並べて中身を確かめる、内容を確認してから次へ進む</td>
          </tr>
          <tr>
            <td>④ 別タブで開く</td>
            <td><code>&lt;a href="PDF の URL" target="_blank"&gt;</code></td>
            <td>じっくり読む・印刷する。元の画面を残しておきたいとき</td>
          </tr>
          <tr>
            <td>⑤ ポップアップで開く</td>
            <td>モーダルの中の <code>iframe</code>、または <code>window.open</code></td>
            <td>一覧から次々に開いて見比べる、入力しながら参照する</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>「表示」と「ダウンロード」の違いはヘッダの 1 語だけ</h2>
<pre><code class="language-plaintext">Content-Type: application/pdf
Content-Disposition: inline; filename="..."; filename*=UTF-8''...     ← 画面に表示
Content-Disposition: attachment; filename="..."; filename*=UTF-8''... ← 保存させる</code></pre>
    <p>
      このサンプルでは <code>?download=1</code> が付いているかどうかで、
      <code>inline</code> と <code>attachment</code> を切り替えています（<code>PdfResponse</code>）。
    </p>
<pre><code class="language-java">response.setContentType("application/pdf");
response.setContentLengthLong(size);
response.setHeader("Content-Disposition", contentDisposition(download, fileName));
response.setHeader("X-Content-Type-Options", "nosniff");
response.setHeader("X-Frame-Options", "SAMEORIGIN");

try (OutputStream out = response.getOutputStream()) {
    Files.copy(file, out);          // ① ファイルから
    // dao.copyContentTo(id, out);  // ② DB から
}</code></pre>
    <ul>
      <li>
        <strong><code>inline</code> でも <code>filename</code> を書く</strong>：
        PDF ビューアの保存ボタンを押したときの名前になります。
        書かないと、多くのブラウザは URL の末尾（このサンプルなら <code>db</code>）を名前にします。
        日本語は <code>filename*=UTF-8''...</code> で渡します
        （書き方は <a href="${ctx}/samples/file/csv-download">CSV ダウンロード</a> で詳しく扱っています）。
      </li>
      <li>
        <strong>タブの見出し</strong>：多くのブラウザは <strong>PDF の中に書かれたタイトル</strong>
        （文書のプロパティの「タイトル」）を出し、無ければファイル名や URL を出します。
        帳票を作る側でタイトルを入れておくと、タブが並んだときに見分けやすくなります。
      </li>
      <li>
        <strong>ブラウザの設定で必ずダウンロードになることもある</strong>：
        Chrome の「PDF をダウンロードする」設定のように、利用者側で
        「開かずに保存する」を選べます。サーバがどう返しても、最後はブラウザ次第です。
      </li>
    </ul>

    <h2>① ファイルとして保存されている PDF</h2>
    <h3>公開フォルダに置く / Servlet を通す</h3>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>置き方</th><th>良い点</th><th>気をつける点</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>/assets/pdf/manual.pdf</code> のような公開フォルダ</td>
            <td>コードが要らない。Tomcat がキャッシュや途中からの読み込み（<code>Range</code>）にも対応してくれる</td>
            <td>URL を知っていれば<strong>誰でも</strong>開ける。ログインや権限の確認ができない</td>
          </tr>
          <tr>
            <td><code>/WEB-INF</code> の下やサーバのフォルダ + Servlet（このサンプル）</td>
            <td>返す前に権限の確認・アクセスの記録ができる。置き場所を WAR の外にもできる</td>
            <td>ファイル名を画面から受け取るので、<strong>フォルダの外を指されない</strong>ようにする</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <code>/WEB-INF</code> の下は、Tomcat が URL での直接アクセスを断ります。
      「Servlet を通さないと開けない場所」として使えるので、このサンプルではここに置いています。
    </p>

    <h3>フォルダの外を指されないようにする（パストラバーサル対策）</h3>
    <p>
      <code>?name=../web.xml</code> のように <code>..</code> を混ぜられると、
      名前をそのままつないだだけではフォルダの外のファイルまで返してしまいます。
      <strong>つないでから <code>normalize()</code> で <code>..</code> を解決し、
      まだ決めたフォルダの中にあるか</strong>を確かめます（<code>PdfFolder.find</code>）。
    </p>
<pre><code class="language-java">Path file = directory.resolve(name).normalize();   // "../web.xml" → /WEB-INF/web.xml
if (!directory.equals(file.getParent())) {           // フォルダの直下でなければ
    return Optional.empty();                         // 見つからない扱い (404)
}</code></pre>
    <ul>
      <li>
        よく見かける <code>file.startsWith(directory)</code> でも外へ出るのは防げます。
        このサンプルはさらに厳しく「直下だけ」にして、サブフォルダにも潜れないようにしています。
      </li>
      <li>
        拡張子が <code>.pdf</code> かどうかも見ています。フォルダの中に PDF 以外が紛れていても返しません。
      </li>
      <li>
        理由を問わず <strong>404</strong> を返しています。「そのファイルはあるが見せられない」と
        言い分けると、何が置いてあるかを探る手がかりを与えてしまうためです。
      </li>
      <li>
        名前ではなく <strong>ID で指定させる</strong>（ファイル名は DB やマスタで管理する）と、
        この心配自体がなくなります。② の DB 版がこの形です。
      </li>
    </ul>

    <h3>置き場所</h3>
    <p>
      サンプルでは WAR に同梱した <code>${fn:escapeXml(folderLocation)}</code> を
      <code>getServletContext().getRealPath(...)</code> でディスク上のパスに直して使っています。
      実務では、サーバ上の決まったフォルダや共有ストレージを設定ファイルで指定することが多いはずです。
      WAR の中に置いたファイルは、<strong>アプリを入れ替えると消えてしまう</strong>ためです。
    </p>

    <h2>② DB に保存されている PDF</h2>
    <ul>
      <li>
        <strong>一覧では中身を読まない</strong>：一覧に要るのは名前とサイズだけです。
        <code>SELECT *</code> にすると全件の PDF を読み込んでしまうので、列を指定します。
      </li>
      <li>
        <strong>中身は流しながら返す</strong>：<code>byte[]</code> にまとめて読むと、
        大きい PDF を何人かが同時に開いただけでメモリが足りなくなります。
        <code>getBinaryStream</code> で読みながら、そのままレスポンスへ書きます。
      </li>
      <li>
        <strong>キャッシュに残さない</strong>：帳票は個人情報を含むことが多いので、
        <code>Cache-Control: no-store</code> を付けています（① のマニュアルには付けていません）。
      </li>
    </ul>

    <div class="alert alert-warning">
      <strong>実務では必ず「見てよい人か」を確かめてください。</strong><br>
      <code>?id=1</code> を <code>?id=2</code> に書き換えるだけで、他人の請求書が開けてしまう、
      というのはよくある事故です。画面に「表示」ボタンを出さないだけでは防げません。
      中身を返す前に、ログインしている人がその帳票を見てよいかを Servlet 側で確かめます。
      このサンプルは誰でも見られる前提のため省いています。
    </div>

    <h2>③ 同じ画面の中に埋め込む</h2>
<pre><code class="language-xml">&lt;iframe src="/samples/file/pdf-view/db?id=1#page=2"
        title="御見積書のプレビュー"
        style="width: 100%; height: 70vh;"&gt;&lt;/iframe&gt;</code></pre>

    <h3><code>iframe</code> / <code>object</code> / <code>embed</code></h3>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>タグ</th><th>特徴</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>&lt;iframe&gt;</code>（このサンプル）</td>
            <td>いちばん素直に動く。<code>title</code> で読み上げ用の名前を付けられる</td>
          </tr>
          <tr>
            <td><code>&lt;object data="..." type="application/pdf"&gt;</code></td>
            <td>表示できないときに<strong>中に書いた HTML が代わりに出る</strong>（「ダウンロードはこちら」を書いておける）</td>
          </tr>
          <tr>
            <td><code>&lt;embed&gt;</code></td>
            <td>代わりの表示を書けない。昔のプラグイン向けの書き方で、新しく使う理由はあまりない</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h3>URL の <code>#</code> で開き方を指定する</h3>
    <p>
      PDF の URL の後ろに <code>#</code> で指定を付けると、ブラウザの PDF ビューアが読み取ってくれます。
      <strong>対応はブラウザ次第</strong>で、効かなくても PDF 自体は普通に表示されます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>指定</th><th>意味</th><th>効くブラウザの目安</th></tr>
        </thead>
        <tbody>
          <tr><td><code>#page=3</code></td><td>3 ページ目から開く</td><td>Chrome・Edge・Firefox</td></tr>
          <tr><td><code>#zoom=150</code></td><td>150% で開く</td><td>Chrome・Edge・Firefox</td></tr>
          <tr><td><code>#toolbar=0</code></td><td>ツールバーを隠す</td><td>Chrome・Edge（Firefox は効かない）</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      <code>#toolbar=0</code> で保存・印刷ボタンを隠しても、<strong>保存や印刷を禁止したことにはなりません</strong>。
      URL を開けば PDF はそのまま手に入ります。見せたくない PDF は、そもそも返さないようにします。
    </p>
    <p>
      このサンプルでは、ページを切り替えるたびに <code>iframe</code> を作り直しています。
      <code>src</code> の <code>#</code> から後ろだけを書き換えると、
      ブラウザが「同じ文書の中の移動」とみなして読み込み直さず、指定が効かないことがあるためです。
    </p>

    <h3>埋め込みで真っ白になるとき</h3>
    <ul>
      <li>
        <strong>PDF 側に <code>X-Frame-Options: DENY</code> が付いている</strong>：
        セキュリティ対策としてサイト全体で付けていると、自分の画面にも埋め込めなくなります。
        このサンプルは <code>SAMEORIGIN</code>（同じサイトからなら埋め込んでよい）を付けています。
        <code>Content-Security-Policy</code> の <code>frame-ancestors</code> も同じ働きです。
      </li>
      <li>
        <strong>スマートフォン</strong>：PDF を画面の中に埋め込んで表示できないブラウザが多くあります
        （何も出ない・1 ページ目しか見えない・ダウンロードになる、など。機種や OS の版で変わります）。
        埋め込みだけに頼らず、<strong>「別タブで開く」リンクを必ず添えて</strong>おきます。
      </li>
    </ul>
    <p>
      表示できるかどうかは <code>navigator.pdfViewerEnabled</code> で分かります。
      このサンプルでは <code>false</code> のときに案内を出しています。
    </p>
<pre><code class="language-javascript">if (navigator.pdfViewerEnabled === false) {
  // 画面の中には出せないので、別タブで開くよう案内する
}</code></pre>

    <h2>④ 別タブで開く</h2>
<pre><code class="language-xml">&lt;a href="/samples/file/pdf-view/db?id=1" target="_blank" rel="noopener"&gt;
  御見積書
  &lt;span class="sr-only"&gt;（新しいタブで開きます）&lt;/span&gt;
&lt;/a&gt;</code></pre>
    <ul>
      <li>
        <strong>ボタン + JavaScript ではなくリンクにする</strong>：
        リンクなら、中クリックや長押しで「新しいタブで開く」「リンクをコピー」が使え、
        JavaScript が動かない環境でも開けます。
      </li>
      <li>
        <strong>新しいタブで開くことを知らせる</strong>：
        いきなりタブが増えると、読み上げを使う人は元の画面へ戻れなくなります。
        アイコンを添え、読み上げ用に <code>.sr-only</code> で一言書いておきます。
      </li>
      <li>
        <strong><code>rel="noopener"</code></strong>：
        開いた先から <code>window.opener</code> で元の画面を操作させないための指定です。
        今のブラウザは <code>target="_blank"</code> だけで同じ扱いにしてくれますが、
        書いておくと意図がはっきりします。
      </li>
      <li>
        サーバが <code>attachment</code> で返すと、<strong>空のタブが開いてすぐダウンロードになります</strong>。
        別タブで見せたいときは <code>inline</code> で返します。
      </li>
    </ul>

    <h2>⑤ ポップアップで開く</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th></th><th>モーダル（画面の上に重ねる）</th><th>別ウィンドウ（<code>window.open</code>）</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>見え方</td>
            <td>今の画面の上に重なる。閉じれば元どおり</td>
            <td>大きさを指定した別のウィンドウ。元の画面と並べて置ける</td>
          </tr>
          <tr>
            <td>ポップアップブロック</td>
            <td>関係ない（画面の中の部品）</td>
            <td>ブロックされることがある</td>
          </tr>
          <tr>
            <td>スマートフォン</td>
            <td>開くが、中の PDF は ③ と同じく出ないことがある</td>
            <td>大きさの指定は無視され、ただの新しいタブになる</td>
          </tr>
          <tr>
            <td>向いている場面</td>
            <td>ちょっと中身を確かめる</td>
            <td>入力しながら横に資料を出しておく</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h3>モーダル：開くときに読み込み、閉じたら捨てる</h3>
<pre><code class="language-javascript">$('#pdfModal').on('show.bs.modal', function (event) {
  var $button = $(event.relatedTarget);          // 押されたボタン
  $('#pdfModalFrame').attr('src', $button.data('pdfUrl'));
});
$('#pdfModal').on('hidden.bs.modal', function () {
  $('#pdfModalFrame').attr('src', 'about:blank');  // 読み込みを止めて、メモリを返す
});</code></pre>
    <p>
      モーダルは 1 つだけ用意し、押されたボタンの <code>data-</code> 属性から URL を差し替えます。
      画面を開いた時点で全部の PDF を読み込んでおくと、開かないものまで取りに行くことになります。
      閉じたときに <code>about:blank</code> に戻しておかないと、次に別の PDF を開いたときに
      前の PDF が一瞬見えてしまいます。
    </p>

    <h3>別ウィンドウ：クリックの中で開く</h3>
<pre><code class="language-javascript">var popup = window.open(url, 'pdfPopup', 'width=820,height=900,resizable=yes,scrollbars=yes');
if (popup) {
  popup.focus();   // 2 回目以降は裏に隠れていることがあるので前に出す
}</code></pre>
    <ul>
      <li>
        <strong>2 つ目の引数（ウィンドウ名）を決めておく</strong>：同じ名前なら同じウィンドウが使い回されます。
        <code>_blank</code> にすると、押すたびにウィンドウが増えていきます。
      </li>
      <li>
        <strong>ポップアップブロック</strong>：ブラウザは「利用者がクリックした、その処理の中で開いた」ものだけを許します。
        <code>fetch</code> の結果を待ってから開く、タイマーで遅らせて開く、といった書き方はブロックされます。
      </li>
      <li>
        このサンプルのボタンは <code>&lt;a href="..." target="pdfPopup"&gt;</code> にしてあり、
        JavaScript で開けなかったときは、普通のリンクとして（別タブで）開きます。
      </li>
    </ul>

    <h2>よくあるつまずき</h2>
    <ul>
      <li>
        <strong>文字化けした画面が出る / PDF が壊れていると言われる</strong>：
        <code>getWriter()</code> で書いた、または JSP を通して返したのが原因のことが多いです。
        PDF は文字ではなくバイト列なので、<code>getOutputStream()</code> で書きます。
        JSP を通すと、タグの外の改行が PDF に混ざって壊れます。
      </li>
      <li>
        <strong>表示されずにダウンロードになる</strong>：
        <code>Content-Disposition</code> が <code>attachment</code> になっているか、
        <code>Content-Type</code> が <code>application/octet-stream</code> になっています。
        利用者のブラウザ設定の可能性もあります。
      </li>
      <li>
        <strong>保存したファイル名が <code>db.pdf</code> などになる</strong>：
        <code>inline</code> のときにも <code>filename</code> を付けます。
      </li>
      <li>
        <strong>差し替えたはずの PDF が古いまま</strong>：ブラウザのキャッシュです。
        URL に版や更新日時を足す（<code>?id=1&amp;v=20260930</code>）と、確実に新しいものを取りに行きます。
      </li>
      <li>
        <strong>利用者がアップロードした PDF をそのまま <code>inline</code> で出す</strong>：
        PDF の中にはリンクやスクリプトを入れられます。先頭が <code>%PDF-</code> で始まるかを確かめ、
        <code>X-Content-Type-Options: nosniff</code> を付けます。
        よく分からないファイルは、<a href="${ctx}/samples/file/file-upload">ファイルのアップロード</a>
        のように <code>attachment</code> で返すのが安全です。
      </li>
    </ul>

    <h2>このデモのデータ</h2>
    <p>
      ① の PDF は WAR に同梱したファイルです。
      ② の PDF は、アプリの起動時に同梱の PDF（<code>src/main/resources/pdf-seed</code>）を DB に入れたものです。
      DB はメモリ上で動かしているため、アプリを再起動すると入れ直されます。
      どの PDF も、上の帯に「ファイルから」「データベースから」のどちらで読んだかを書いてあります。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // ------------------------------------------------------------------
      // 画面の中に PDF を出せないブラウザ (スマートフォンの多く) には案内を出す
      // (pdfViewerEnabled を知らない古いブラウザは undefined になるので、false のときだけ)
      // ------------------------------------------------------------------
      $(function () {
        if (navigator.pdfViewerEnabled === false) {
          $('[data-pdf-unsupported]').removeClass('d-none');
        }
      });

      // ------------------------------------------------------------------
      // ③ 埋め込み : 選んだ PDF・ページで iframe を開き直す
      // ------------------------------------------------------------------
      $(function () {
        var $document = $('#embedDocument');
        if ($document.length === 0) {
          return;   // PDF が 1 件も無いときは埋め込み欄自体が無い
        }

        /** 選ばれている条件から、iframe に渡す URL を組み立てる。 */
        function buildUrl() {
          var params = [];
          var page = parseInt($('#embedPage').val(), 10);
          if (page > 1) {
            params.push('page=' + page);
          }
          if ($('#embedToolbar').prop('checked')) {
            params.push('toolbar=0');
          }
          return $document.val() + (params.length > 0 ? '#' + params.join('&') : '');
        }

        function show() {
          var url = buildUrl();
          var frame = document.getElementById('embedFrame');

          // src の # から後ろだけを変えても、ブラウザは読み込み直さないことがある。
          // 確実に指定を効かせるため、iframe を作り直して最初から読み込ませる
          var fresh = frame.cloneNode(false);
          fresh.src = url;
          fresh.title = $document.find('option:selected').text() + ' の埋め込み表示';
          frame.parentNode.replaceChild(fresh, frame);

          $('#embedUrl').text(url);
          // 別タブで開くリンクも、同じ PDF を指すように揃えておく
          $('#embedOpen').attr('href', $document.val());
        }

        // ページ番号は数字だけにする (空・0・文字は 1 に戻す)
        $('#embedPage').on('change', function () {
          var page = parseInt($(this).val(), 10);
          $(this).val(page > 0 ? page : 1);
        });
        $('#embedForm').on('submit', function (event) {
          event.preventDefault();   // 画面を送信せず、iframe だけを切り替える
          $('#embedPage').trigger('change');
          show();
        });
        $document.on('change', show);
        $('#embedToolbar').on('change', show);
      });

      // ------------------------------------------------------------------
      // ⑤-1 モーダル : 開くときに読み込み、閉じたら捨てる
      // ------------------------------------------------------------------
      $(function () {
        var $modal = $('#pdfModal');

        $modal.on('show.bs.modal', function (event) {
          // どの PDF を開くかは、押されたボタンの data 属性で受け取る
          // (モーダルを 1 つだけ用意して、全部のボタンで使い回すため)
          var $button = $(event.relatedTarget);
          var url = $button.data('pdfUrl');
          var title = $button.data('pdfTitle');

          $('#pdfModalTitle').text(title);   // text() で入れる (html() だとタグとして解釈される)
          $('#pdfModalFrame').attr({ src: url, title: title + ' のプレビュー' });
          $('#pdfModalOpen').attr('href', url);
          $('#pdfModalDownload').attr('href', url + '&download=1');
        });

        // 閉じたら空にする。
        // 読み込み途中なら止まり、次に別の PDF を開いたときに前の PDF が一瞬見えることもなくなる
        $modal.on('hidden.bs.modal', function () {
          $('#pdfModalFrame').attr('src', 'about:blank');
        });
      });

      // ------------------------------------------------------------------
      // ⑤-2 別ウィンドウ : クリックされたその場で window.open する
      // ------------------------------------------------------------------
      $(function () {
        $('[data-pdf-popup]').on('click', function (event) {
          // 名前 (pdfPopup) を決めておくと、2 回目以降は同じウィンドウが使い回される。
          // 大きさを指定すると、PC のブラウザはタブではなく別ウィンドウで開く
          var popup = window.open(this.href, 'pdfPopup',
              'width=820,height=900,resizable=yes,scrollbars=yes');

          if (popup) {
            event.preventDefault();   // 開けたので、リンク本来の動きは止める
            popup.focus();            // 裏に隠れていたウィンドウを前に出す
          }
          // 開けなかった (ブロックされた) ときは何もしない。
          // href と target が書いてあるので、普通のリンクとして別タブで開く
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ============================================================
         ① ファイルとして保存されている PDF
         ============================================================ --%>
    <t:panel title="① ファイルとして保存されている PDF を表示する"
             note="フォルダのファイル → PdfFromFileServlet → ブラウザ">
      <p>
        サーバのフォルダ <code>${fn:escapeXml(folderLocation)}</code> に置いた PDF を、Servlet が読んで返します。
        「表示」と「ダウンロード」は同じ Servlet で、違いは
        <code>Content-Disposition</code> が <code>inline</code> か <code>attachment</code> かだけです。
      </p>
      <c:choose>
        <c:when test="${empty folderFiles}">
          <div class="empty-state">
            <t:icon name="file-earmark-arrow-up" size="32" cssClass="empty-state__icon" />
            <p class="empty-state__text mb-0">
              <code>${fn:escapeXml(folderLocation)}</code> に PDF がありません。
            </p>
          </div>
        </c:when>
        <c:otherwise>
          <%-- position-relative : 操作列の .sr-only (position: absolute) が横スクロールの枠からはみ出して、
               スマートフォンで画面全体が横に揺れるのを防ぐ --%>
          <div class="table-responsive position-relative">
            <table class="table table-sm table-hover mb-2">
              <thead class="thead-light">
                <tr>
                  <th scope="col">ファイル名</th>
                  <th scope="col" class="text-right">サイズ</th>
                  <th scope="col" class="text-right">操作</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="file" items="${folderFiles}">
                  <%-- ファイル名は URL に入れるので、c:param でエンコードしてもらう --%>
                  <c:url var="fileViewUrl" value="/samples/file/pdf-view/file">
                    <c:param name="name" value="${file.name}" />
                  </c:url>
                  <c:url var="fileDownloadUrl" value="/samples/file/pdf-view/file">
                    <c:param name="name" value="${file.name}" />
                    <c:param name="download" value="1" />
                  </c:url>
                  <tr>
                    <td class="align-middle"><code>${fn:escapeXml(file.name)}</code></td>
                    <td class="align-middle text-right">${file.sizeText}</td>
                    <td class="align-middle text-right text-nowrap">
                      <a class="btn btn-sm btn-primary" href="${fn:escapeXml(fileViewUrl)}">
                        表示<span class="sr-only">：${fn:escapeXml(file.name)}</span>
                      </a>
                      <a class="btn btn-sm btn-outline-secondary ml-1" href="${fn:escapeXml(fileDownloadUrl)}">
                        ダウンロード<span class="sr-only">：${fn:escapeXml(file.name)}</span>
                      </a>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <p class="text-muted small">
            「表示」はこのタブのまま PDF に切り替わります。ブラウザの「戻る」でこの画面に戻れます。
          </p>
        </c:otherwise>
      </c:choose>

      <hr>
      <p class="mb-2"><strong>試してみる</strong>（どれも 404 になれば正しい動きです）</p>
      <ul class="small mb-0">
        <li>
          <a href="${ctx}${fn:escapeXml(folderLocation)}/manual.pdf">WEB-INF の下を URL で直接開く</a>
          … Tomcat が断ります。Servlet を通さないと開けません
        </li>
        <li>
          <a href="${fileUrl}?name=../classes/pdf-seed/estimate.pdf">名前に <code>../</code> を入れてフォルダの外を指す</a>
          … 実在する PDF ですが、決めたフォルダの外なので返しません
        </li>
        <li>
          <a href="${fileUrl}?name=../web.xml">PDF 以外のファイルを指す</a>
          … 拡張子が <code>.pdf</code> でなければ返しません
        </li>
      </ul>
    </t:panel>

    <%-- ============================================================
         ② DB に保存されている PDF
         ============================================================ --%>
    <t:panel title="② DB に保存されている PDF を表示する"
             note="BLOB 列 → PdfFromDbServlet → ブラウザ">
      <p>
        データベースの <code>BLOB</code> 列に入っている PDF を、Servlet が読みながらそのまま返します。
        URL で指定するのはファイル名ではなく <strong>ID</strong> です。
      </p>
      <c:choose>
        <c:when test="${empty documents}">
          <div class="empty-state">
            <t:icon name="file-earmark-arrow-up" size="32" cssClass="empty-state__icon" />
            <p class="empty-state__text mb-0">データベースに PDF がありません。</p>
          </div>
        </c:when>
        <c:otherwise>
          <%-- position-relative : 操作列の .sr-only (position: absolute) が横スクロールの枠からはみ出して、
               スマートフォンで画面全体が横に揺れるのを防ぐ --%>
          <div class="table-responsive position-relative">
            <table class="table table-sm table-hover mb-2">
              <thead class="thead-light">
                <tr>
                  <th scope="col" class="text-right">ID</th>
                  <th scope="col">名前</th>
                  <th scope="col">ファイル名</th>
                  <th scope="col" class="text-right">サイズ</th>
                  <th scope="col" class="text-right">操作</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="doc" items="${documents}">
                  <tr>
                    <td class="align-middle text-right">${doc.id}</td>
                    <td class="align-middle">${fn:escapeXml(doc.title)}</td>
                    <td class="align-middle"><code>${fn:escapeXml(doc.fileName)}</code></td>
                    <td class="align-middle text-right">${doc.sizeText}</td>
                    <td class="align-middle text-right text-nowrap">
                      <a class="btn btn-sm btn-primary" href="${dbUrl}?id=${doc.id}">
                        表示<span class="sr-only">：${fn:escapeXml(doc.title)}</span>
                      </a>
                      <a class="btn btn-sm btn-outline-secondary ml-1" href="${dbUrl}?id=${doc.id}&amp;download=1">
                        ダウンロード<span class="sr-only">：${fn:escapeXml(doc.title)}</span>
                      </a>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <p class="text-muted small">
            ダウンロードすると、日本語のファイル名（<code>Content-Disposition</code> の
            <code>filename*</code>）で保存されます。
          </p>
        </c:otherwise>
      </c:choose>

      <hr>
      <p class="mb-2"><strong>試してみる</strong>（どれも 404 になれば正しい動きです）</p>
      <ul class="small mb-0">
        <li><a href="${dbUrl}?id=9999">存在しない ID を指定する</a></li>
        <li><a href="${dbUrl}?id=abc">数字ではない ID を指定する</a> … 例外で落ちずに 404 を返します</li>
      </ul>
    </t:panel>

    <%-- ============================================================
         ③ 同じ画面の中に埋め込む (iframe)
         ============================================================ --%>
    <t:panel title="③ 同じ画面の中に埋め込む" note="iframe の src に PDF の URL を入れるだけ">
      <c:choose>
        <c:when test="${empty documents}">
          <p class="text-muted mb-0">埋め込む PDF がありません。</p>
        </c:when>
        <c:otherwise>
          <form id="embedForm" class="form-row align-items-end">
            <div class="form-group col-md-5">
              <label for="embedDocument">表示する PDF</label>
              <select class="form-control" id="embedDocument">
                <c:forEach var="doc" items="${documents}" varStatus="status">
                  <%-- 一覧の最後 (5 ページある会議資料) を選んでおき、ページ指定を試しやすくする --%>
                  <option value="${dbUrl}?id=${doc.id}" ${status.last ? 'selected' : ''}>${fn:escapeXml(doc.title)}</option>
                </c:forEach>
              </select>
            </div>
            <div class="form-group col-6 col-md-2">
              <label for="embedPage">ページ</label>
              <input type="text" class="form-control" id="embedPage" value="1"
                     inputmode="numeric" pattern="[0-9]*" maxlength="3" autocomplete="off">
            </div>
            <div class="form-group col-6 col-md-2">
              <button type="submit" class="btn btn-primary btn-block">開き直す</button>
            </div>
            <div class="form-group col-md-3">
              <div class="custom-control custom-checkbox">
                <input type="checkbox" class="custom-control-input" id="embedToolbar">
                <label class="custom-control-label" for="embedToolbar">ツールバーを隠す</label>
              </div>
            </div>
          </form>

          <div class="alert alert-warning d-none" data-pdf-unsupported role="status">
            このブラウザは、PDF を画面の中に表示できません（スマートフォンの多くが当てはまります）。
            下の「別タブで開く」から開いてください。
          </div>

          <%-- 最初に表示する PDF (select で選ばれているもの = 一覧の最後) --%>
          <c:set var="firstEmbedUrl" value="${dbUrl}?id=${documents[fn:length(documents) - 1].id}" />
          <iframe id="embedFrame" src="${firstEmbedUrl}"
                  title="${fn:escapeXml(documents[fn:length(documents) - 1].title)} の埋め込み表示"
                  style="width: 100%; height: 70vh; min-height: 360px; border: 1px solid #dee2e6;"></iframe>

          <p class="text-muted small mt-2 mb-0">
            iframe の URL：<code id="embedUrl">${fn:escapeXml(firstEmbedUrl)}</code><br>
            うまく表示されないときは
            <a id="embedOpen" href="${firstEmbedUrl}" target="_blank" rel="noopener">別タブで開く<t:icon name="external" size="12" cssClass="ml-1" /><span class="sr-only">（新しいタブで開きます）</span></a>
            から見られます。
          </p>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <%-- ============================================================
         ④ 別タブで開く
         ============================================================ --%>
    <t:panel title="④ 別タブで開く" note="target=&quot;_blank&quot; : この画面はそのまま残ります">
      <p>
        ただのリンクに <code>target="_blank"</code> を付けるだけです。
        PDF を <code>inline</code> で返しているので、新しいタブの中で表示されます。
      </p>
      <ul class="mb-0">
        <c:forEach var="doc" items="${documents}">
          <li class="mb-1">
            <a href="${dbUrl}?id=${doc.id}" target="_blank" rel="noopener">${fn:escapeXml(doc.title)}<t:icon name="external" size="12" cssClass="ml-1" /><span class="sr-only">（新しいタブで開きます）</span></a>
            <span class="text-muted small ml-1">${doc.sizeText}</span>
          </li>
        </c:forEach>
      </ul>
    </t:panel>

    <%-- ============================================================
         ⑤ ポップアップで開く (モーダル / 別ウィンドウ)
         ============================================================ --%>
    <t:panel title="⑤ ポップアップで開く" note="画面に重ねるモーダルと、別ウィンドウの 2 通り">
      <div class="row">
        <div class="col-md-6 mb-3 mb-md-0">
          <p class="mb-2"><strong>モーダル</strong>（画面の上に重ねる）</p>
          <p class="text-muted small">
            1 つのモーダルを使い回し、押したボタンの PDF を中の iframe に読み込みます。
          </p>
          <c:forEach var="doc" items="${documents}">
            <button type="button" class="btn btn-outline-primary btn-sm mb-2 mr-1"
                    data-toggle="modal" data-target="#pdfModal"
                    data-pdf-url="${dbUrl}?id=${doc.id}" data-pdf-title="${fn:escapeXml(doc.title)}">
              ${fn:escapeXml(doc.title)}
            </button>
          </c:forEach>
        </div>
        <div class="col-md-6">
          <p class="mb-2"><strong>別ウィンドウ</strong>（<code>window.open</code>）</p>
          <p class="text-muted small">
            大きさを指定した別のウィンドウで開きます。続けて押すと、同じウィンドウの中身が入れ替わります。
          </p>
          <c:forEach var="doc" items="${documents}">
            <%-- JavaScript で開けなかったときは、普通のリンクとして別タブで開く --%>
            <a class="btn btn-outline-secondary btn-sm mb-2 mr-1" href="${dbUrl}?id=${doc.id}"
               target="pdfPopup" data-pdf-popup>
              ${fn:escapeXml(doc.title)}<span class="sr-only">（別のウィンドウで開きます）</span>
            </a>
          </c:forEach>
        </div>
      </div>
    </t:panel>

    <%-- ============================================================
         ⑤ で使うモーダル (ボタンごとに作らず 1 つを使い回す)
         ============================================================ --%>
    <div class="modal fade" id="pdfModal" tabindex="-1" role="dialog"
         aria-labelledby="pdfModalTitle" aria-hidden="true">
      <div class="modal-dialog modal-xl modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="pdfModalTitle">PDF</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body p-0">
            <div class="alert alert-warning d-none m-3" data-pdf-unsupported role="status">
              このブラウザは、PDF を画面の中に表示できません。「別タブで開く」から開いてください。
            </div>
            <%-- src は開くときに JavaScript が入れる (開かない PDF まで読み込まないため) --%>
            <iframe id="pdfModalFrame" src="about:blank" title="PDF のプレビュー"
                    style="display: block; width: 100%; height: calc(100vh - 16rem); min-height: 240px; border: 0;"></iframe>
          </div>
          <div class="modal-footer">
            <a id="pdfModalOpen" class="btn btn-outline-primary" href="#" target="_blank" rel="noopener">
              別タブで開く<t:icon name="external" size="12" cssClass="ml-1" /><span class="sr-only">（新しいタブで開きます）</span>
            </a>
            <a id="pdfModalDownload" class="btn btn-outline-secondary" href="#">ダウンロード</a>
            <button type="button" class="btn btn-secondary" data-dismiss="modal">閉じる</button>
          </div>
        </div>
      </div>
    </div>
  </jsp:body>
</t:sample>
