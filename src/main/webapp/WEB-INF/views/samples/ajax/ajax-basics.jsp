<%--
  【サンプル】非同期通信の基本 (fetch で JSON を取得)

  ボタンを押すと JavaScript が /samples/ajax/ajax-basics/api を fetch して、
  返ってきた JSON で画面の一部だけを書き換えます。

    ・AjaxBasicsServlet     … この画面を表示する (ページを開いた時刻を埋め込む)
    ・AjaxBasicsApiServlet  … /samples/ajax/ajax-basics/api (JSON を返す)

  「わざと遅くする」「わざと 500 を返す」「存在しない URL を叩く」ボタンを並べて、
  うまくいかないときに画面がどう見えるかまで確かめられるようにしています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="ajax-basics">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>非同期通信とは</h2>
    <p>
      リンクを押したりフォームを送信したりすると、ブラウザは<strong>いま見えている画面を捨てて</strong>、
      サーバから返ってきた HTML で新しく作り直します。これが画面遷移です。
      非同期通信 (Ajax) は画面をそのままにして、<strong>JavaScript がサーバと通信し、
      受け取ったデータで画面の一部だけを書き換える</strong>やり方です。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>&nbsp;</th><th>画面遷移（リンク・フォーム送信）</th><th>非同期通信（fetch）</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>通信するのは</td>
            <td>ブラウザ</td>
            <td>JavaScript</td>
          </tr>
          <tr>
            <td>サーバが返すもの</td>
            <td>HTML 1 枚</td>
            <td>JSON などの<strong>データだけ</strong></td>
          </tr>
          <tr>
            <td>画面</td>
            <td>丸ごと作り直される</td>
            <td>書き換えた所だけ変わる</td>
          </tr>
          <tr>
            <td>URL</td>
            <td>変わる</td>
            <td>変わらない</td>
          </tr>
          <tr>
            <td>入力途中の値・スクロール位置</td>
            <td>消える</td>
            <td>残る</td>
          </tr>
          <tr>
            <td>ブラウザの「戻る」</td>
            <td>効く</td>
            <td>効かない（必要なら自分で作る）</td>
          </tr>
          <tr>
            <td>失敗したとき</td>
            <td>ブラウザがエラー画面を出す</td>
            <td><strong>何も起きない</strong>（自分で表示する）</td>
          </tr>
        </tbody>
      </table>
    </div>

    <p>
      いちばん気をつけたいのは最後の行です。画面遷移なら、失敗すればブラウザが何かを表示してくれます。
      非同期通信では<strong>失敗しても画面は黙ったまま</strong>です。
      「押したのに何も起きない」画面にしないために、待っている間の表示と、
      失敗したときの表示を自分で用意する必要があります。
    </p>

    <h3>どんなときに使うか</h3>
    <ul>
      <li>郵便番号から住所を引く、ID の重複を調べるなど、<strong>入力の途中でサーバに聞きたい</strong>とき</li>
      <li>一覧の絞り込み・並べ替え・ページ送り（入力欄やスクロール位置を保ったまま切り替えたいとき）</li>
      <li>「いいね」「お気に入り」のような、画面のごく一部だけが変わる更新</li>
      <li>時間のかかる処理の進み具合を、定期的に問い合わせて見せるとき</li>
    </ul>
    <p>
      反対に、<strong>画面全体が変わるなら素直に画面遷移</strong>のほうが簡単で確実です。
      「登録したら一覧へ」のような流れを無理に非同期にすると、URL・戻るボタン・二重送信の面倒を
      すべて自分で引き受けることになります。
    </p>

    <h2>処理の流れ</h2>
    <ol>
      <li>ボタンが押される</li>
      <li>JavaScript がボタンを <code>disabled</code> にし、ローディング表示を出す（押した反応をすぐ返す）</li>
      <li><code>fetch</code> で <code>/samples/ajax/ajax-basics/api</code> に GET を送る</li>
      <li><code>AjaxBasicsApiServlet</code> がパラメータを検証し、<code>Json.write</code> で JSON を書き出す</li>
      <li>JavaScript が <code>res.ok</code> を確かめ、成功なら本文を JSON として読む</li>
      <li>受け取った値を <code>textContent</code> で画面に入れる（表の中身だけが変わる）</li>
      <li>成功でも失敗でもローディング表示を消し、ボタンを元に戻す（<code>finally</code>）</li>
    </ol>

    <h2>fetch の基本形</h2>
    <p>
      <code>async</code> / <code>await</code> で書くと、上から順に読める形になります。
    </p>
<pre><code class="language-javascript">async function load() {
  const res = await fetch(apiUrl, {headers: {'Accept': 'application/json'}});

  if (!res.ok) {                  // ← これを書かないと、エラーに気づけません
    throw new Error('HTTP ' + res.status);
  }

  const data = await res.json();  // 本文を読むのも通信なので await が要ります
  document.getElementById('time').textContent = data.serverTime;
}</code></pre>
    <p>
      <code>await</code> が 2 回出てくるのは、通信が 2 段階だからです。
      1 回目は<strong>応答のヘッダー（ステータス）が返ってくるまで</strong>、
      2 回目は<strong>本文を最後まで読み終わるまで</strong>を待っています。
      ステータスだけ先に分かるので、<code>res.ok</code> の判定は本文を読む前に書けます。
    </p>
    <p>
      同じ処理を <code>then</code> で書くとこうなります。
      <code>await</code> は「<code>then</code> のつながりを縦に書ける記法」と考えて差し支えありません。
      どちらで書いてもかまいませんが、<strong>混ぜると読みにくい</strong>ので、
      1 つの処理の中では揃えます。
    </p>
<pre><code class="language-javascript">fetch(apiUrl, {headers: {'Accept': 'application/json'}})
  .then(function (res) {
    if (!res.ok) {
      throw new Error('HTTP ' + res.status);
    }
    return res.json();            // Promise を返すと、次の then で中身を受け取れます
  })
  .then(function (data) {
    document.getElementById('time').textContent = data.serverTime;
  })
  .catch(function (e) {           // throw した Error もここに来ます
    showError(e);
  });</code></pre>

    <h2>つまずき ①：404 も 500 も「成功」で返ってくる</h2>
    <p>
      <code>fetch</code> の Promise が失敗（reject）になるのは、
      <strong>通信そのものが成立しなかったとき</strong>だけです。
      サーバが応答を返してきた以上、その中身が 404 でも 500 でも <code>fetch</code> としては成功です。
      <code>res.ok</code>（ステータスが 200〜299 なら <code>true</code>）を自分で見ないと、
      エラー画面の HTML を「取得できたデータ」として扱ってしまいます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>起きたこと</th><th>fetch は</th><th><code>res.ok</code></th><th><code>res.status</code></th><th>気づく方法</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>200 で JSON が返った</td>
            <td>成功</td><td>true</td><td>200</td>
            <td>ふつうに処理する</td>
          </tr>
          <tr>
            <td>URL が違う（404）</td>
            <td><strong>成功</strong></td><td>false</td><td>404</td>
            <td><code>res.ok</code> を見る</td>
          </tr>
          <tr>
            <td>サーバで例外（500）</td>
            <td><strong>成功</strong></td><td>false</td><td>500</td>
            <td><code>res.ok</code> を見る</td>
          </tr>
          <tr>
            <td>オフライン／サーバ停止／CORS で拒否</td>
            <td>失敗（reject）</td><td>―</td><td>―</td>
            <td><code>try-catch</code>（<code>.catch</code>）</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      失敗を画面に出すときに使えるのは <code>res.status</code>（数字）です。
      <code>res.statusText</code>（<code>Not Found</code> のような理由句）は<strong>空文字のことがあります</strong>。
      Tomcat 9 は既定で理由句を返しませんし、HTTP/2 にはそもそも理由句がありません。
      <code>'HTTP ' + res.status + ' (' + res.statusText + ')'</code> のように決め打ちでつなぐと、
      画面に <code>HTTP 404 ()</code> と出ます。中身があるときだけ添えるようにします。
    </p>
    <p>
      とくに 404 は、本文が JSON ではなく<strong>エラー画面の HTML</strong> です。
      <code>res.ok</code> を見ずに <code>res.json()</code> を呼ぶと
      <code>SyntaxError: Unexpected token</code> という、原因の分かりにくい例外になります
      （最初の 1 文字が HTML の開きタグだからです）。
      デモの「存在しない URL を叩く」ボタンで、実際に返ってくる中身が見られます。
    </p>

    <h2>つまずき ②：つながらなかったときは例外になる</h2>
    <p>
      オフライン、サーバが落ちている、ホスト名を間違えている ――
      このときは Promise が失敗するので、<code>try-catch</code>（<code>then</code> なら
      <code>.catch</code>）が必要です。書いていないと、コンソールに
      <code>Uncaught (in promise)</code> と出るだけで、画面は押す前のまま止まります。
      ボタンを <code>disabled</code> にしていた場合は、<strong>二度と押せなくなります</strong>。
    </p>
<pre><code class="language-javascript">try {
  const res = await fetch(url);
  ...
} catch (e) {
  // ここに来るのは「つながらなかった」ときと「JSON として読めなかった」とき
  console.error(e);                       // 詳しい内容はコンソールへ
  showError('通信できませんでした。時間をおいて試してください。');
} finally {
  // 成功でも失敗でも必ず通る。ボタンを戻すのはここに書く
  button.disabled = false;
}</code></pre>
    <p>
      画面に出すのは利用者が読める文にします。<code>e.message</code>（たとえば
      <code>Failed to fetch</code>）をそのまま出しても、何をすればよいのかは伝わりません。
    </p>

    <h2>サーバ側（Servlet）で気をつけること</h2>

    <h3>Content-Type と文字コード</h3>
<pre><code class="language-java">response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");
response.getWriter().write(json);</code></pre>
    <ul>
      <li>
        <code>application/json</code> を付けないと、受け取る側がデータの種類を判断できません。
        ブラウザの開発者ツールで中身がきれいに表示されなくなるのも、たいていこれが理由です
      </li>
      <li>
        <code>setCharacterEncoding("UTF-8")</code> を忘れると<strong>日本語が化けます</strong>。
        既定の文字コードは環境しだいなので、開発機では化けないのにサーバでは化ける、という形で現れます
      </li>
      <li>
        <strong>どちらも <code>getWriter()</code> を呼ぶ前に設定します。</strong>
        書き始めたあとで指定しても効きません
      </li>
    </ul>
    <p>
      このサンプルでは <code>common/Json.java</code> の <code>Json.write</code> がこの 3 行をまとめています。
    </p>

    <h3>GET の応答はキャッシュされることがある</h3>
<pre><code class="language-java">response.setHeader("Cache-Control", "no-store");</code></pre>
    <p>
      同じ URL に何度も GET を送る API では、ブラウザや間にいるサーバが前の応答を使い回すことがあります。
      そうなると「押しても値が変わらない」「古い一覧がいつまでも出る」という形で現れ、
      サーバ側のログには何も残らないので原因を探しにくくなります。
      毎回聞きに行ってほしい API では、このサンプルのように明示的に止めておきます。
    </p>

    <h3>エラーのときも JSON で返す</h3>
<pre><code class="language-java">response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);   // 500
Json.write(response, Json.object()
        .put("ok", false)
        .put("message", "サーバ側で問題が発生しました。"));</code></pre>
    <ul>
      <li>
        <strong>ステータスは正しく 500 にする</strong>：
        200 を返して本文に <code>"ok": false</code> とだけ書く作りにすると、
        監視の仕組みやブラウザの開発者ツールからは「全部成功している」ように見えてしまいます
      </li>
      <li>
        <strong>本文は JSON のままにする</strong>：
        画面側は <code>res.ok</code> で失敗と判断し、本文から理由を読めます。
        <code>response.sendError(500)</code> を使うとコンテナのエラーページ（HTML）が本文になるので、
        API では <code>setStatus</code> ＋ 自前の本文のほうが扱いやすくなります
      </li>
      <li>
        <strong>中身を書きすぎない</strong>：
        例外のスタックトレースや SQL をそのまま返すのは、攻撃者にサーバの構造を教えるのと同じです。
        詳しい情報はログに出し、画面には説明だけを返します
      </li>
    </ul>

    <h3>パラメータは必ず検証する</h3>
<pre><code class="language-java">// ダメな例 : 受け取った値をそのまま使う
Thread.sleep(Long.parseLong(request.getParameter("delay")));

// 検証してから使う (未入力・数字以外・大きすぎる値を、すべてここで潰す)
long delay = parseDelayMillis(request.getParameter("delay"));   // 0 〜 2000 に丸める
Thread.sleep(delay);</code></pre>
    <p>
      画面の JavaScript が組み立てて送る URL であっても、<strong>利用者はそれを自由に書き換えられます</strong>。
      非同期通信の API は「画面からしか呼ばれない」ように見えて、実際は誰でも直接叩ける入口です。
      <code>?delay=600000</code> をそのまま <code>Thread.sleep</code> に渡すと、
      そのリクエストは Tomcat のスレッドを 1 本 10 分間占有します。数回叩かれればアプリは応答しなくなります。
    </p>
    <p>
      数値に直すときの手順は、だいたいいつも同じ形になります。
    </p>
    <ol>
      <li>未入力（<code>null</code> や空文字）を先に片づける</li>
      <li><code>NumberFormatException</code> を捕まえる（数字以外でも、桁が大きすぎても飛んできます）</li>
      <li>範囲を決めて、外れていたら丸めるか、エラーとして返す</li>
    </ol>
    <p>
      このサンプルの <code>delay</code> は見た目だけの値なので、おかしければ黙って 0 に倒しています。
      <strong>業務上の意味を持つ値なら、勝手に直さずエラーにする</strong>ほうが安全です
      （<code>400 Bad Request</code> を返す、など）。
    </p>

    <h3>JSON の組み立てはライブラリに任せる</h3>
    <p>
      このサンプル集の <code>common/Json.java</code> は、依存ライブラリを増やさずに
      「非同期通信で何が起きているか」に集中するための<strong>学習用の最小実装</strong>です。
      <strong>実務では Jackson や Gson を使ってください。</strong>
      オブジェクトをそのまま JSON にでき、日付の書式や <code>null</code> の扱いもまとめて決められます。
      文字列の連結で JSON を組み立てると、<code>"</code>・改行・制御文字のエスケープを
      自分で面倒みることになり、いつか壊れた JSON を返します。
    </p>

    <h2>つまずき ③：受け取った文字列を innerHTML に入れない</h2>
<pre><code class="language-javascript">// 危険 : 中身が HTML として解釈される
element.innerHTML = data.comment;

// 安全 : ただの文字列として表示される
element.textContent = data.comment;</code></pre>
    <p>
      jQuery なら <code>.html()</code> が <code>innerHTML</code>、<code>.text()</code> が
      <code>textContent</code> です。
      「サーバから来た値だから安全」ということはありません。その値は<strong>もとをたどれば誰かが入力したもの</strong>で、
      画像の読み込み失敗を利用した <code>onerror</code> つきのタグなどが混ざっていれば、そのまま動きます
      （クロスサイトスクリプティング）。JSP 側で <code>fn:escapeXml</code> を通すのと同じ用心が、
      JavaScript 側にも必要です。
    </p>
    <p>
      表の行を組み立てるときも、文字列で HTML を作らずに、要素を作って値を入れます。
    </p>
<pre><code class="language-javascript">// 文字列で組み立てる : name の中身しだいでタグが壊れる / 実行される
$('#list').append('&lt;tr&gt;&lt;td&gt;' + data.name + '&lt;/td&gt;&lt;/tr&gt;');

// 要素を作り、値は text() で入れる
$('#list').append($('&lt;tr&gt;').append($('&lt;td&gt;').text(data.name)));</code></pre>

    <h2>つまずき ④：JSP の中に JavaScript を書くときの注意</h2>
    <ul>
      <li>
        <strong>テンプレートリテラルが EL とぶつかる</strong>：
        JavaScript の <code>`${'${data.name}'}`</code> という書き方は、JSP からは EL に見えます。
        JSP に書く JavaScript ではバッククォートを避け、<code>'時刻: ' + data.serverTime</code> のように
        <code>+</code> でつなぐのが安全です
      </li>
      <li>
        <strong>URL はコンテキストパスから組み立てる</strong>：
        <code>'/samples/ajax/ajax-basics/api'</code> と直接書くと、アプリを
        <code>/app</code> の下に配置したときに 404 になります。
        <code>var apiUrl = '${'${ctx}'}/samples/ajax/ajax-basics/api';</code> のように、
        <code>${'${pageContext.request.contextPath}'}</code> を通します
      </li>
      <li>
        <strong>相対パスも避ける</strong>：
        <code>fetch('api')</code> は「いま表示している URL から見た相対」なので、
        末尾のスラッシュの有無だけで行き先が変わります
      </li>
      <li>
        <strong>JSON をそのまま HTML に埋め込むときは <code>&lt;/script&gt;</code> に注意</strong>：
        文字列の中に <code>&lt;/script&gt;</code> があると、そこでタグが閉じてしまいます。
        <code>Json.java</code> が <code>&lt;</code> を <code>\u003C</code> に置き換えているのはこのためです
      </li>
    </ul>

    <h2>待っている間の画面と、連打</h2>
    <ul>
      <li>
        押した瞬間にボタンを <code>disabled</code> にし、ローディング（Bootstrap の
        <code>spinner-border</code>）を出します。通信が一瞬で終わるとは限りません
      </li>
      <li>
        終わったら<strong>必ず</strong>元に戻します。戻す処理を成功時だけに書くと、
        失敗した瞬間にボタンが押せないままになります。<code>finally</code> に書くのはこのためです
      </li>
      <li>
        <code>disabled</code> で防げるのは、同じボタンの連打だけです。
        入力のたびに投げるような作りでは、<strong>遅い応答が後から届いて、新しい結果を上書きする</strong>ことがあります。
        古い通信を <code>AbortController</code> で打ち切るか、最後に投げたものだけを採用します
      </li>
      <li>
        状態を変える処理（登録・更新・削除）は、非同期でも <code>POST</code> にします。
        GET はブラウザや中継サーバに勝手に再実行・キャッシュされることがあるためです
      </li>
    </ul>

    <h2>このデモの API が返す JSON</h2>
<pre><code class="language-plaintext">{
  "ok": true,
  "serverTime": "2026-01-01 12:34:56",
  "serverInfo": "Apache Tomcat/9.0.x",
  "javaVersion": "17.0.x",
  "sampleCount": 12,
  "delayMillis": 0,
  "requestCount": 3,
  "thread": "http-nio-8080-exec-5"
}</code></pre>
    <p>
      <code>sampleCount</code> は、このサイトのカタログが持っている「公開中のサンプル件数」です。
      <strong>サーバ側にしか無い値</strong>を持ってくることが、API を呼ぶ目的そのものです。
      <code>requestCount</code> は API が呼ばれた通算回数で、
      「画面は 1 回しか読み込んでいないのに、通信は何度も起きている」ことの確認に使えます。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {

        // このサンプル専用の JSON API。
        // URL は必ずコンテキストパスから組み立てます。
        // '/samples/...' と直接書くと、アプリを /app の下に置いたときに 404 になります
        var apiUrl = '${ctx}${apiPath}';

        // ボタンの種類ごとの行き先。クエリパラメータの付け方も見えるように並べています
        var urls = {
          normal: apiUrl,
          slow: apiUrl + '?delay=1500',      // サーバが 1.5 秒待ってから返す
          fail: apiUrl + '?fail=server',     // サーバがわざと 500 を返す
          notfound: apiUrl + '-typo'         // わざと間違えた URL。404 (中身は HTML) が返る
        };

        var $buttons = $('[data-ajax-kind]');
        var $status = $('#ajaxStatus');
        var $result = $('#ajaxResult');
        var $error = $('#ajaxError');

        // ------------------------------------------------------------------
        // 本体。async / await で書いています (then で書いた形は解説タブにあります)
        // ------------------------------------------------------------------
        async function request(kind, $button) {
          var url = urls[kind];
          var startedAt = Date.now();
          var elapsed = 0;

          busy(true, $button, url);

          try {
            // ① 送る。ここで待っているのは「応答のヘッダーが返ってくるまで」
            var res = await fetch(url, {headers: {'Accept': 'application/json'}});

            // ② 本文を読む。これも通信なので await が要ります。
            //    res.json() ではなく res.text() で読んでいるのは、受け取った生の文字列を
            //    そのまま画面に出したいからです
            //    (res.json() は「text() してから JSON.parse する」のとほぼ同じ処理です)
            var body = await res.text();
            elapsed = Date.now() - startedAt;

            // ③ ここが肝心。fetch は 404 でも 500 でも「成功」として返ってきます。
            //    res.ok (ステータスが 200〜299 なら true) を自分で見ないと、
            //    エラー画面の HTML を「取得できたデータ」として扱ってしまいます
            if (!res.ok) {
              // res.statusText (Not Found などの理由句) は空のことがあります。
              // Tomcat 9 は既定で理由句を返さないので、ここも空になります。
              // そのまま組み立てると「HTTP 404 ()」と出てしまうため、中身があるときだけ添えます
              var reason = res.statusText ? ' (' + res.statusText + ')' : '';
              showError('サーバが HTTP ' + res.status + reason + ' を返しました。', body);
              addLog(url, res.status, elapsed, '失敗');
              return;                  // return しても finally は必ず通ります
            }

            // ④ 文字列を JSON として読む。本文が JSON でなければ、ここで例外になり catch へ
            var data = JSON.parse(body);
            showResult(data, body, elapsed);
            addLog(url, res.status, elapsed, '成功');

          } catch (e) {
            // ⑤ ここに来るのは「そもそもつながらなかった」ときと「JSON として読めなかった」とき。
            //    オフライン、サーバの停止、ホスト名の間違いなどが前者です。
            //    利用者には e.message (例: Failed to fetch) ではなく、読める文を出します
            elapsed = Date.now() - startedAt;
            console.error(e);          // 詳しい内容はコンソールへ
            showError(e instanceof SyntaxError
              ? '応答を JSON として読めませんでした。JSON 以外のものが返っています。'
              : '通信できませんでした。ネットワークかサーバの状態を確認してください。', String(e));
            addLog(url, '-', elapsed, '例外');

          } finally {
            // ⑥ 成功でも失敗でも必ず通ります。ボタンを元に戻すのはここ。
            //    成功したときだけ戻す書き方にすると、一度失敗したボタンが二度と押せなくなります
            busy(false, $button);
          }
        }

        // 通信中の見た目。押した反応をすぐ返し、二重に押させない
        function busy(isBusy, $button, url) {
          $buttons.prop('disabled', isBusy);                              // どのボタンも押せなくする
          $button.find('.spinner-border').toggleClass('d-none', !isBusy); // 回すのは押されたボタンだけ
          if (isBusy) {
            $error.addClass('d-none');
            $status.text('通信中… ' + url);
          }
        }

        // 受け取った JSON を画面へ反映する
        function showResult(data, body, elapsed) {
          // 値は .text() (= textContent) で入れます。
          // .html() (= innerHTML) に入れると、文字列に混ざったタグがそのまま動いてしまいます
          $('#resultServerTime').text(data.serverTime);
          $('#resultServerInfo').text(data.serverInfo);
          $('#resultJavaVersion').text(data.javaVersion);
          $('#resultSampleCount').text(data.sampleCount);
          $('#resultDelay').text(data.delayMillis + ' ミリ秒');
          $('#resultCount').text(data.requestCount + ' 回目');
          $('#resultThread').text(data.thread);
          $('#resultElapsed').text(elapsed + ' ミリ秒');
          $('#ajaxRaw').text(body);
          $('#lastFetchedAt').text(data.serverTime);

          $result.removeClass('d-none');
          $error.addClass('d-none');
          $status.text('取得しました。画面は読み込み直されていません。');
        }

        // 失敗したことを画面に出す。黙って終わらせないのが非同期通信のいちばんの注意点です
        function showError(message, body) {
          $('#errorMessage').text(message);
          // 404 のときに返ってくるのはエラー画面の HTML です。
          // ここも .text() で入れます (.html() に入れたら、そのエラー画面が動き出します)
          $('#errorBody').text(shorten(body));
          $('#ajaxRaw').text(shorten(body));
          $error.removeClass('d-none');
          $status.text('失敗しました。何が返ってきたかは下の表示で確かめられます。');
        }

        // 長い本文は先頭だけにする (404 のエラー画面は数千文字あります)
        function shorten(text) {
          if (!text) {
            return '(本文はありません)';
          }
          return text.length > 500 ? text.substring(0, 500) + ' …(以下略)' : text;
        }

        // 通信ログに 1 行足す。要素を作って .text() で入れる = 文字列で HTML を組み立てない
        function addLog(url, status, elapsed, result) {
          var $row = $('<tr>')
            .append($('<td>').text(clockText()))
            .append($('<td>').append($('<code>').text(url)))
            .append($('<td>').text(status))
            .append($('<td>').addClass('text-right').text(elapsed + ' ms'))
            .append($('<td>').text(result));
          $('#logBody').prepend($row);
          $('#logEmpty').addClass('d-none');
        }

        // ブラウザ側の時計。API が返す時刻はサーバ側の時計なので、少しずれていても不思議ではありません
        function clockText() {
          var now = new Date();
          return ('0' + now.getHours()).slice(-2) + ':'
            + ('0' + now.getMinutes()).slice(-2) + ':'
            + ('0' + now.getSeconds()).slice(-2);
        }

        // ------------------------------------------------------------------
        // ボタン
        // ------------------------------------------------------------------
        $buttons.on('click', function () {
          // data-ajax-kind の値で行き先を選ぶ
          request($(this).attr('data-ajax-kind'), $(this));
        });

        $('#clearLogButton').on('click', function () {
          $('#logBody').find('tr').not('#logEmpty').remove();
          $('#logEmpty').removeClass('d-none');
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:panel title="① サーバの情報を取得する" note="押しても画面は読み込み直されません">
      <p>
        ボタンを押すと、JavaScript が <code>${fn:escapeXml(apiPath)}</code> へ GET を送り、
        返ってきた JSON で<strong>下の表の中身だけ</strong>を書き換えます。
        URL も変わりませんし、入力中の文字も消えません。
      </p>

      <button type="button" class="btn btn-primary" data-ajax-kind="normal">
        <span class="spinner-border spinner-border-sm mr-1 d-none" role="status" aria-hidden="true"></span>
        サーバの情報を取得
      </button>
      <span class="text-muted small ml-2" id="ajaxStatus">まだ取得していません。</span>

      <div class="table-responsive mt-3 d-none" id="ajaxResult">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" class="w-50">サーバの現在時刻</th>
              <td><code id="resultServerTime">-</code></td>
            </tr>
            <tr>
              <th scope="row">サーバ</th>
              <td id="resultServerInfo">-</td>
            </tr>
            <tr>
              <th scope="row">Java のバージョン</th>
              <td id="resultJavaVersion">-</td>
            </tr>
            <tr>
              <th scope="row">
                公開中のサンプル件数
                <span class="d-block text-muted small">サーバ側にしか無い値を持ってきています</span>
              </th>
              <td><span id="resultSampleCount">-</span> 件</td>
            </tr>
            <tr>
              <th scope="row">サーバが待った時間（<code>delay</code>）</th>
              <td id="resultDelay">-</td>
            </tr>
            <tr>
              <th scope="row">
                この API を呼んだ回数
                <span class="d-block text-muted small">画面は 1 回しか読み込んでいません</span>
              </th>
              <td id="resultCount">-</td>
            </tr>
            <tr>
              <th scope="row">応答したスレッド</th>
              <td><code id="resultThread">-</code></td>
            </tr>
            <tr>
              <th scope="row">往復にかかった時間（ブラウザ側で計測）</th>
              <td id="resultElapsed">-</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="alert alert-danger mt-3 d-none" id="ajaxError">
        <strong id="errorMessage">-</strong>
        <div class="small mt-2 mb-1">
          サーバから返ってきた本文（先頭だけ）。上の表は、最後に成功したときのまま残しています。
        </div>
<pre class="code-snippet mb-0" id="errorBody"></pre>
      </div>

      <div class="mt-3">
        <div class="text-muted small mb-1">受け取った本文（長いときは先頭だけ）</div>
<pre class="code-snippet mb-0" id="ajaxRaw">（まだ取得していません）</pre>
      </div>
    </t:panel>

    <t:panel title="② 画面そのものは読み込み直されていない"
             note="① のボタンを何度か押してから、2 つの時刻を見比べてください">
      <div class="table-responsive">
        <table class="table table-sm table-bordered">
          <tbody>
            <tr>
              <th scope="row" class="w-50">
                このページの HTML が作られた時刻
                <span class="d-block text-muted small">
                  <code>AjaxBasicsServlet</code> が埋め込んだ値
                </span>
              </th>
              <td>
                <code>${fn:escapeXml(openedAt)}</code>
                <span class="d-block text-muted small mt-1">ボタンを何度押しても変わりません</span>
              </td>
            </tr>
            <tr>
              <th scope="row">
                最後に <code>fetch</code> で取得した時刻
                <span class="d-block text-muted small">API が返した値</span>
              </th>
              <td>
                <code id="lastFetchedAt">-</code>
                <span class="d-block text-muted small mt-1">押すたびに新しくなります</span>
              </td>
            </tr>
            <tr>
              <th scope="row">ページを開いた時点の公開サンプル件数</th>
              <td>${pageSampleCount} 件</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="form-group mb-2">
        <label for="memo">メモ欄（サーバには送りません）</label>
        <input type="text" class="form-control" id="memo"
               placeholder="ここに何か書いてから、① のボタンを押してみてください">
        <small class="form-text text-muted">
          非同期通信では、入力途中の値もスクロール位置もそのまま残ります。
          下のリンク（ふつうの画面遷移）で開き直すと消えます。
        </small>
      </div>
      <a class="btn btn-outline-secondary" href="${ctx}/samples/ajax/ajax-basics">
        <t:icon name="arrow-repeat" size="14" cssClass="mr-1" />この画面を読み込み直す（画面遷移）
      </a>
    </t:panel>

    <t:panel title="③ うまくいかないときの出方"
             note="押したときに ① の表示がどう変わるかを見てください">
      <div class="row">
        <div class="col-md-4 mb-3">
          <div class="card h-100">
            <div class="card-body">
              <h6 class="card-title">わざと遅くする</h6>
              <p class="card-text small text-muted">
                <code>?delay=1500</code> を付けて呼びます。サーバが 1.5 秒待ってから返すので、
                ローディング表示とボタンの <code>disabled</code> を確かめられます。
              </p>
              <button type="button" class="btn btn-outline-primary btn-sm" data-ajax-kind="slow">
                <span class="spinner-border spinner-border-sm mr-1 d-none" role="status" aria-hidden="true"></span>
                1.5 秒待たせて取得
              </button>
            </div>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="card h-100">
            <div class="card-body">
              <h6 class="card-title">サーバがエラーを返す</h6>
              <p class="card-text small text-muted">
                <code>?fail=server</code> を付けて呼びます。サーバは <strong>500</strong> を返しますが、
                本文は JSON のままです。<code>fetch</code> はこれを<strong>成功</strong>として返してきます。
              </p>
              <button type="button" class="btn btn-outline-danger btn-sm" data-ajax-kind="fail">
                <span class="spinner-border spinner-border-sm mr-1 d-none" role="status" aria-hidden="true"></span>
                500 を返させる
              </button>
            </div>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="card h-100">
            <div class="card-body">
              <h6 class="card-title">存在しない URL を叩く</h6>
              <p class="card-text small text-muted">
                末尾を <code>-typo</code> にした URL を呼びます。<strong>404</strong> が返り、
                本文は JSON ではなく<strong>エラー画面の HTML</strong> です。
                <code>res.ok</code> を見ていなければ、これを読もうとして例外になります。
              </p>
              <button type="button" class="btn btn-outline-warning btn-sm" data-ajax-kind="notfound">
                <span class="spinner-border spinner-border-sm mr-1 d-none" role="status" aria-hidden="true"></span>
                404 になる URL を叩く
              </button>
            </div>
          </div>
        </div>
      </div>
      <p class="text-muted small mb-0">
        <code>?delay=</code> にもっと大きな値を書いても、サーバ側で 2000 ミリ秒までに丸めています。
        受け取った数をそのまま <code>Thread.sleep</code> に渡すと、
        リクエストを処理するスレッドを好きなだけ占有されてしまうためです。
      </p>
    </t:panel>

    <t:panel title="④ 通信ログ" note="押した順に上から積まれます">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-2">
          <thead>
            <tr>
              <th>時刻（ブラウザ）</th>
              <th>叩いた URL</th>
              <th>HTTP</th>
              <th class="text-right">所要</th>
              <th>結果</th>
            </tr>
          </thead>
          <tbody id="logBody">
            <tr id="logEmpty">
              <td colspan="5" class="text-center text-muted">まだ通信していません。</td>
            </tr>
          </tbody>
        </table>
      </div>
      <button type="button" class="btn btn-outline-secondary btn-sm" id="clearLogButton">ログを消す</button>
      <p class="text-muted small mt-3 mb-0">
        ここに出る時刻はブラウザの時計、① の表に出る時刻はサーバの時計です。
        別々の機械の時計なので、少しずれていても不思議ではありません。
        <strong>所要</strong>は「ボタンを押してから本文を読み終わるまで」をブラウザ側で計った時間で、
        サーバが待った時間（<code>delay</code>）に、通信そのものにかかる時間が足された値になります。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
