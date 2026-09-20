<%--
  【サンプル】Ajax でフォームを送信する

  送信ボタンを押すと JavaScript が /samples/ajax/ajax-form/api へ POST し、
  返ってきた JSON で画面の一部だけを書き換えます。画面は切り替わりません。

    ・AjaxFormServlet     … この画面を表示する (選択肢と上限値を渡す)
    ・AjaxFormApiServlet  … /samples/ajax/ajax-form/api (検証して JSON を返す)

  「通信に失敗したとき」「画面を通さず直接 POST したとき」「同じ内容を送り直したとき」の
  3 つを試せるボタンを置いて、うまくいかない場合の見え方まで確かめられるようにしています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="ajax-form">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>このサンプルがやっていること</h2>
    <p>
      ふつうのフォームは、送信ボタンを押すとブラウザが<strong>いま見えている画面を捨てて</strong>、
      サーバから返ってきた HTML で作り直します。このサンプルでは、その送信をいったん止めて、
      <strong>JavaScript が同じ内容をサーバへ送り、返ってきた JSON で画面の一部だけを書き換えます</strong>。
      画面は切り替わりませんし、URL も変わりません。
    </p>

    <h3>処理の流れ</h3>
    <ol>
      <li>送信ボタンが押される（<code>submit</code> イベントが起きる）</li>
      <li><code>event.preventDefault()</code> で、ブラウザ本来の送信を止める</li>
      <li>送信中フラグを立て、ボタンを <code>disabled</code> にする（二重送信の防止）</li>
      <li><code>URLSearchParams</code> で <code>name=…&amp;mail=…</code> の形の本文を組み立てる</li>
      <li><code>fetch</code> で <code>/samples/ajax/ajax-form/api</code> へ POST する</li>
      <li>
        <code>AjaxFormApiServlet</code> が <code>InquiryForm.validate()</code> で検証する
        <ul>
          <li>エラーあり … <strong>400</strong> と <code>{"ok":false,"errors":{…}}</code></li>
          <li>エラーなし … <strong>200</strong> と <code>{"ok":true,"receipt":"A-0001"}</code></li>
        </ul>
      </li>
      <li>
        JavaScript が <code>res.status</code> を見て振り分ける。
        400 なら項目ごとに <code>is-invalid</code> を付けてメッセージを出し、
        200 ならフォームを隠して受付番号を出す
      </li>
      <li>成功でも失敗でも、送信中フラグを下ろしてボタンを戻す（<code>finally</code>）</li>
    </ol>

    <h2>画面遷移しないことの利点と欠点</h2>
    <p>
      「画面が切り替わらない」は見た目の話ではなく、<strong>ブラウザが持っている仕組みを使わなくなる</strong>
      ということです。良いことも困ることも、そこから出てきます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>&nbsp;</th><th>ふつうのフォーム送信</th><th>Ajax で送信（このサンプル）</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>エラーで戻したときの入力値</td>
            <td>サーバが HTML に埋め込み直さないと<strong>消える</strong></td>
            <td><strong>そのまま残る</strong>（画面を作り直していないので当然）</td>
          </tr>
          <tr>
            <td>スクロール位置・開いていたタブ</td>
            <td>先頭に戻る</td>
            <td>変わらない</td>
          </tr>
          <tr>
            <td>体感の速さ</td>
            <td>HTML 一式を受け取り直す</td>
            <td>数百バイトの JSON だけ。<strong>速い</strong></td>
          </tr>
          <tr>
            <td>ブラウザの「戻る」</td>
            <td>効く</td>
            <td><strong>効かない</strong>（この画面より前へ戻ってしまう）</td>
          </tr>
          <tr>
            <td>ブックマーク・URL の共有</td>
            <td>結果の URL を渡せる</td>
            <td><strong>渡せない</strong>（URL が変わらないため）</td>
          </tr>
          <tr>
            <td>JavaScript が無効／読み込み失敗</td>
            <td>そのまま動く</td>
            <td><strong>何も起きない</strong>（送信自体ができない）</td>
          </tr>
          <tr>
            <td>失敗したとき</td>
            <td>ブラウザがエラー画面を出す</td>
            <td><strong>黙ったまま</strong>。自分で表示を用意する</td>
          </tr>
          <tr>
            <td>二重送信</td>
            <td>送信後の画面で止まるので起きにくい</td>
            <td>画面が残るので<strong>何度でも押せる</strong></td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      向いているのは、<strong>入力を保ったまま何度もやり取りする</strong>画面です。
      入力チェックのエラーを出して直してもらう、といった往復の多い場面では、
      打ち直しが発生しないだけで使い勝手がはっきり変わります。
    </p>
    <p>
      反対に、<strong>送信したら別の画面へ進む</strong>のが自然な流れなら、素直に
      画面遷移（POST → リダイレクト → GET）のほうが簡単で確実です。
      非同期にすると、URL・戻るボタン・二重送信の面倒をすべて自分で引き受けることになります。
    </p>

    <h2>送るところ：本文の形と <code>Content-Type</code></h2>
<pre><code class="language-javascript">// URLSearchParams は「name=値&amp;mail=値」の形を組み立てる道具です。
// 値に含まれる &amp; や = や日本語のパーセントエンコードを自分で書かずに済みます
var params = new URLSearchParams();
params.set('name', document.getElementById('field-name').value);
params.set('mail', document.getElementById('field-mail').value);

var res = await fetch(apiUrl, {
  method: 'POST',
  headers: {
    // これを忘れると、サーバ側の request.getParameter() が null になります
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    'Accept': 'application/json'
  },
  body: params.toString()
});</code></pre>
    <p>
      入力欄が多いときは、フォーム要素からまとめて作れます。
      <code>name</code> 属性の付いた欄が拾われるので、欄を増やしたときに書き足す必要がありません。
    </p>
<pre><code class="language-javascript">var params = new URLSearchParams(new FormData(document.getElementById('inquiryForm')));
// jQuery なら $('#inquiryForm').serialize() でも同じ形の文字列が作れます</code></pre>
    <p>
      ただし <code>FormData</code> をそのまま <code>body</code> に渡すと、
      形式が <code>multipart/form-data</code> になります。
      <strong>ファイルを送らないなら、<code>URLSearchParams</code> に通して
      <code>application/x-www-form-urlencoded</code> で送る</strong>のが素直です
      （ファイルを送るときは <code>FormData</code> をそのまま渡し、
      <code>Content-Type</code> は<strong>指定しません</strong>。
      境界文字列をブラウザに決めてもらう必要があるためです）。
    </p>

    <h3>つまずき：JSON で送ると <code>getParameter()</code> が空になる</h3>
    <p>
      <code>body: JSON.stringify({name: '…'})</code> と書いて送ると、サーバ側の
      <code>request.getParameter("name")</code> は <strong><code>null</code></strong> を返します。
      <code>getParameter()</code> が読めるのは
      <code>application/x-www-form-urlencoded</code> と
      <code>multipart/form-data</code>（こちらは Servlet に <code>@MultipartConfig</code> が
      付いているときだけ）の 2 つで、
      JSON の本文は<strong>ただの文字の並び</strong>として素通りするからです。
      JSON で送るなら、サーバ側で <code>request.getReader()</code> から本文を読み、
      自分で解析することになります（Jackson などのライブラリの出番です）。
      このサンプルでは、既存のフォームと同じ作法で扱えるほうを選んでいます。
    </p>

    <h3>つまずき：日本語が化けるとき</h3>
    <p>
      POST の本文をどの文字コードで読むかは、サーバ側の設定しだいです。
      このリポジトリでは <code>web.xml</code> に書いてあります。
    </p>
<pre><code class="language-xml">&lt;request-character-encoding&gt;UTF-8&lt;/request-character-encoding&gt;</code></pre>
    <p>
      この 1 行（Servlet 4.0 の機能）が無い環境では、
      <strong><code>getParameter()</code> を 1 回でも呼ぶ前に</strong>
      <code>request.setCharacterEncoding("UTF-8")</code> が必要です。
      呼んだ後で設定しても効きません（もう読み終わっているためです）。
      「開発機では化けないのに、サーバでは化ける」という形で現れることが多い箇所です。
    </p>

    <h2>受けるところ：サーバ側の検証は省略できない</h2>
    <p>
      この API の URL が分かれば、<strong>画面を通さずに誰でも POST できます</strong>。
      開発者ツールのコンソールからでも、次の 1 行で送れます。
    </p>
<pre><code class="language-javascript">fetch('/samples/ajax/ajax-form/api', {
  method: 'POST',
  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  body: 'name=&amp;mail=xxx&amp;type=%E6%80%AA%E3%81%97%E3%81%84%E5%80%A4&amp;body='
});</code></pre>
    <p>
      デモの「画面を通さずに直接 POST する」ボタンが、まさにこれをやっています。
      画面側の JavaScript のチェックは<strong>利用者に早く気づいてもらうための親切</strong>であって、
      データを受け入れてよいかどうかを決めるのはサーバ側だけです。
      <code>required</code> 属性も <code>maxlength</code> 属性も、開発者ツールで外せます。
    </p>
    <p>
      とくに見落としやすいのが<strong>セレクトボックスとラジオボタン</strong>です。
      「画面に出した選択肢の中からしか選べないはず」と考えてしまいますが、送られてくる値は
      ただの文字列なので何でも入ります。<strong>受け付けてよい値の一覧と突き合わせて確かめます</strong>
      （ホワイトリスト方式）。
    </p>
<pre><code class="language-java">// 選択肢の一覧は 1 か所だけに持ち、画面の &lt;option&gt; もここから作る
public static final Map&lt;String, String&gt; TYPES;   // "question" → "ご質問" …

if (type.isEmpty()) {
    errors.add("type", "お問い合わせの種別を選んでください。");
} else {
    // 知らない値が来たら弾く。画面に並べた選択肢は書き換えられる前提で考える
    errors.addIf(!TYPES.containsKey(type), "type", "不正な値が指定されました。");
}</code></pre>

    <h2>HTTP ステータスの使い分け</h2>
    <p>
      非同期通信では、<strong>結果の良し悪しを HTTP ステータスで伝える</strong>のが基本です。
      ブラウザの開発者ツール、アクセスログ、監視の仕組みは、どれもステータスを見ています。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>状況</th><th>ステータス</th><th>意味</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>受け付けた</td>
            <td><code>200 OK</code></td>
            <td>処理できた。新しくデータを作ったことを強調するなら <code>201 Created</code> も使えます</td>
          </tr>
          <tr>
            <td>入力に誤りがある</td>
            <td><code>400 Bad Request</code></td>
            <td>送られてきた内容がおかしいので処理できない。<strong>このサンプルはこれです</strong></td>
          </tr>
          <tr>
            <td>形式は正しいが業務ルールに反する</td>
            <td><code>422 Unprocessable Entity</code></td>
            <td>
              「JSON としては読めたが内容が受け入れられない」を 400 と区別したいときに使います。
              区別しない流儀も多く、<strong>チームで決めて揃えるもの</strong>です
            </td>
          </tr>
          <tr>
            <td>ログインしていない／権限が無い</td>
            <td><code>401</code> / <code>403</code></td>
            <td>画面側で「ログイン画面へ促す」など、入力エラーとは別の扱いにします</td>
          </tr>
          <tr>
            <td>POST 以外で呼ばれた</td>
            <td><code>405 Method Not Allowed</code></td>
            <td><code>Allow: POST</code> ヘッダーを付けて返します</td>
          </tr>
          <tr>
            <td>サーバ側の不具合</td>
            <td><code>500 Internal Server Error</code></td>
            <td>
              利用者には直しようがありません。画面には「時間をおいて…」とだけ出し、
              <strong>詳しい内容はログへ</strong>（例外の内容をそのまま返さない）
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <h3><code>ok</code> フラグ方式との違い</h3>
    <p>
      「いつでも 200 を返して、本文の <code>"ok": false</code> で失敗を伝える」書き方もよく見かけます。
      画面側の分岐が 1 か所で済むぶん手軽ですが、次の点で困ります。
    </p>
    <ul>
      <li>
        <strong>ステータスしか見ない相手に、失敗が伝わりません</strong>。
        アクセスログも監視も開発者ツールも「全部成功」に見えるので、
        エラー率のグラフが平らなまま障害に気づけない、ということが起こります
      </li>
      <li>
        リトライやキャッシュの判断も本来はステータスを見て行われます。
        200 と言い切ってしまうと、その判断材料を消すことになります
      </li>
    </ul>
    <p>
      一方で、<strong><code>ok</code> フラグそのものが悪いわけではありません</strong>。
      このサンプルも「<strong>ステータスは正しく 400 / 200 にしたうえで</strong>、
      本文にも <code>ok</code> を入れる」形にしています。
      本文だけを見て判断したい場面（ログに残した JSON を後から読むなど）で役に立ちますし、
      画面側も <code>res.status</code> と <code>data.ok</code> の両方で確かめられます。
      <strong>ステータスの代わりにするのではなく、添えるもの</strong>と考えると迷いません。
    </p>
    <p>
      なお、エラーのときも<strong>本文は JSON のままにします</strong>。
      <code>response.sendError(400)</code> を使うと、本文がコンテナのエラーページ（HTML）に
      差し替わってしまい、画面側が <code>res.json()</code> で読もうとして例外になります。
    </p>
<pre><code class="language-java">// API では sendError ではなく setStatus ＋ 自前の本文
response.setStatus(HttpServletResponse.SC_BAD_REQUEST);   // 400
Json.write(response, errorPayload(errors));</code></pre>

    <h2>エラーの JSON は「項目名をキー」にする</h2>
<pre><code class="language-plaintext">{
  "ok": false,
  "status": 400,
  "message": "入力内容を確認してください。",
  "errorCount": 2,
  "errors": {
    "name": "お名前を入力してください。",
    "mail": "メールアドレスの形式が正しくありません。"
  }
}</code></pre>
    <p>
      <code>errors</code> のキーを<strong>入力欄の名前と同じにする</strong>のが要点です。
      こうしておくと、受け取った側は「キーから欄を引いて、そこにメッセージを出す」だけで済みます。
    </p>
<pre><code class="language-javascript">function showFieldErrors(errors) {
  Object.keys(errors).forEach(function (field) {
    // サーバ側のキー名と、画面の id / name を揃えてあるので、この 2 行で当てられます
    $('#field-' + field).addClass('is-invalid');
    $('#error-' + field).text(errors[field]);   // .html() は使わない
  });
}</code></pre>
    <p>
      これを <code>["お名前を入力してください。", "…"]</code> のような<strong>配列</strong>にすると、
      どの欄のエラーなのかが分からなくなり、画面の上部にまとめて出すことしかできなくなります。
      逆に「1 項目に複数のメッセージ」を返したいなら
      <code>{"name": ["…", "…"]}</code> のように値を配列にします。
      どちらにしても<strong>形は常に同じにする</strong>ことが大切です。
      エラーの有無で <code>errors</code> が無くなったり型が変わったりすると、
      受け取る側に分岐が増えていきます。
    </p>
    <p>
      <code>message</code>（全体に対する一言）と <code>errors</code>（項目ごと）を分けているのは、
      「メールアドレスが重複しています」のように<strong>どの欄にも紐づかないエラー</strong>が
      必ず出てくるからです。
      サーバ側では <code>common/ValidationErrors.java</code> がこの 2 種類を持ち分けています。
    </p>

    <h2>二重送信の防止</h2>
    <p>
      画面が残り続けるぶん、非同期のフォームは<strong>何度でも押せてしまいます</strong>。
      次の 3 段構えにします。前の 2 つは画面側の工夫で、<strong>最後の 1 つだけが確実</strong>です。
    </p>
    <ol>
      <li>
        <strong>ボタンを <code>disabled</code> にする</strong> …
        押した瞬間に押せなくします。通信が終わったら
        <code>finally</code> で必ず戻します。成功時だけ戻す書き方にすると、
        一度失敗したボタンが二度と押せなくなります
      </li>
      <li>
        <strong>送信中フラグを持つ</strong> …
        <code>disabled</code> が効くのは「そのボタンを押す」経路だけです。
        テキスト欄で Enter を押す、別のボタンから同じ関数を呼ぶ、といった経路は素通りします。
        関数の入口で <code>if (sending) return;</code> と書いておくほうが確実です
      </li>
      <li>
        <strong>サーバ側でも防ぐ</strong> …
        通信が途中で切れて利用者が送り直した場合や、画面を通さず直接 POST された場合は、
        画面側の工夫はどれも効きません
      </li>
    </ol>
    <p>
      このサンプルのサーバ側は、<strong>セッション ID と入力内容から鍵を作り、
      ${duplicateWindowSeconds} 秒以内に同じ鍵が来たら採番し直さずに前と同じ受付番号を返す</strong>
      形にしています（デモの「同じ内容をもう一度すぐ送る」で試せます）。
      2 回呼ばれても結果が 1 回分と同じになるので、画面はエラーにせず素直に受付完了を出せます。
    </p>
<pre><code class="language-java">// 鍵にセッション ID を混ぜる。混ぜ忘れると、たまたま同じ内容を送った別人が
// 1 人目の受付番号を受け取ってしまう
String key = fingerprint(request.getSession().getId(), form);

// 「探してから入れる」を 2 文に分けると、その間に割り込まれて 2 つ採番されることがある。
// ConcurrentHashMap#compute なら鍵ごとに 1 つずつ処理される
Result accepted = duplicateGuard.accept(key, System.currentTimeMillis(), this::issueReceipt);</code></pre>
    <p>
      この作りは<strong>アプリのメモリに覚えているだけ</strong>なので、再起動で消えますし、
      サーバを複数台に並べると台ごとに別々の記憶になります。きちんとやるなら次のどちらかです。
    </p>
    <ul>
      <li>
        <strong>ワンタイムトークン</strong> …
        画面を出すときにトークンを発行してセッションに覚えておき、POST で使い終わったら捨てます。
        2 回目はトークンが無いので弾けます。<strong>CSRF 対策も兼ねられる</strong>のが利点です
      </li>
      <li>
        <strong>保存先に一意制約を張る</strong> …
        最後の砦をデータベースに任せます。重複したら制約違反になるので、それを捕まえて
        「すでに受け付け済みです」と返します
      </li>
    </ul>

    <h2>CSRF 対策について（このサンプルでは省いています）</h2>
    <p>
      <strong>このサンプルには CSRF（クロスサイトリクエストフォージェリ）対策が入っていません。</strong>
      非同期でフォームを送る流れに集中するために省略しています。
      <strong>実務では必ず入れてください。</strong>
    </p>
    <p>
      CSRF は、利用者がログインしたままの状態で<strong>攻撃者のページを開いてしまったときに、
      そのページから自分のサイトへ勝手に POST される</strong>攻撃です。
      ブラウザは Cookie（セッション ID）を自動で付けて送るので、サーバから見ると
      <strong>本人の操作と区別が付きません</strong>。「ログインしているか」を確かめるだけでは防げません。
    </p>
    <p>
      定番の対策は、画面を表示するときに推測できないトークンを発行してセッションに覚えておき、
      POST されたトークンと突き合わせる方法です。攻撃者のページはそのトークンを知らないので送れません。
    </p>
<pre><code class="language-java">// 画面を出すとき : トークンを作ってセッションに覚え、hidden か data 属性で画面へ渡す
String token = UUID.randomUUID().toString();
request.getSession().setAttribute("csrfToken", token);

// POST を受けたとき : 突き合わせて、違えば処理しない
String sent = request.getParameter("csrfToken");
if (sent == null || !sent.equals(request.getSession().getAttribute("csrfToken"))) {
    response.setStatus(HttpServletResponse.SC_FORBIDDEN);   // 403
    return;
}</code></pre>
    <ul>
      <li>
        Ajax の場合は、トークンをリクエストヘッダー（<code>X-CSRF-TOKEN</code> など）に
        載せる形もよく使われます
      </li>
      <li>
        Cookie に <code>SameSite=Lax</code>（最近のブラウザの既定）が付いていると、
        別サイトからの POST では Cookie が送られないため、かなりの部分は防げます。
        ただし<strong>ブラウザ任せの防御なので、トークンの代わりにはしません</strong>
      </li>
      <li>
        そもそも<strong>状態を変える処理を GET にしない</strong>ことも大切です。
        GET は画像タグやリンクだけで実行させられます
      </li>
    </ul>

    <h2>その他のつまずきやすい所</h2>
    <ul>
      <li>
        <strong><code>event.preventDefault()</code> を書き忘れる</strong> …
        fetch は飛ぶのに、同時にブラウザ本来の送信も走って画面が切り替わります。
        「一瞬エラーメッセージが見えて消えた」ように見えるときは、たいていこれです
      </li>
      <li>
        <strong><code>fetch</code> は 400 でも 500 でも「成功」として返ってくる</strong> …
        通信そのものが成立しなかったときだけ <code>catch</code> へ行きます。
        <strong>URL を間違えた（404）も <code>catch</code> には来ません</strong>。
        <code>res.ok</code> や <code>res.status</code> を自分で見て振り分けます
        （デモの「通信に失敗したとき」は、存在しない<strong>ホスト</strong>へ送っているので
        <code>catch</code> に入ります）
      </li>
      <li>
        <strong>受け取った文字列を <code>innerHTML</code> に入れない</strong> …
        サーバから来た値でも、元をたどれば誰かが入力したものです。
        <code>textContent</code>（jQuery なら <code>.text()</code>）を使います
      </li>
      <li>
        <strong>エラー表示を消し忘れる</strong> …
        送信のたびに <code>is-invalid</code> と <code>invalid-feedback</code> を全部消してから
        当て直します。消さずに足すと、直した項目のエラーが残り続けます
      </li>
      <li>
        <strong>Bootstrap 4 の <code>invalid-feedback</code> は隠れている</strong> …
        <code>display: none</code> が既定で、表示を切り替えている CSS は
        <code>.is-invalid ~ .invalid-feedback</code> です。<code>~</code> は
        「同じ親の中で、後ろに並んでいる兄弟」を指します。つまり
        <strong>入力欄と同じ親の中で、入力欄より後ろに置く</strong>必要があります。
        入力欄より前に置いたり、<code>form-group</code> の外に出したりすると、
        <code>is-invalid</code> を付けてもメッセージが出ません
      </li>
      <li>
        <strong>JSP に書く JavaScript でバッククォートを使わない</strong> …
        テンプレートリテラルの <code>${'${x}'}</code> は JSP からは EL に見えます。
        文字列は <code>+</code> でつなぎます。URL も
        <code>'${'${ctx}'}/samples/…'</code> のようにコンテキストパスから組み立てます
      </li>
      <li>
        <strong>成功したあとの画面を決めておく</strong> …
        このサンプルはフォームを隠して受付番号を出しています。
        入力欄を残したままにすると「送れたのか分からずもう一度押す」ことになります
      </li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {

        // この画面専用の API。URL は必ずコンテキストパスから組み立てます
        // ('/samples/...' と直接書くと、アプリを /app の下に置いたときに 404 になります)
        var apiUrl = '${ctx}${apiPath}';

        // わざと「サーバに届かない」URL。
        // .invalid は「絶対に実在しない」と決められているドメインなので、名前解決に失敗します。
        // 存在しない "パス" (404) では catch に入らないことに注意してください。
        // 応答が返ってきた時点で fetch としては成功で、404 は res.ok が false になるだけです
        var unreachableUrl = 'https://ajax-form.example.invalid' + '${apiPath}';

        // 本文の文字数の上限 (Java の定数から渡された値。画面に数字を直接書かない)
        var bodyMaxLength = ${bodyMaxLength};

        var $form = $('#inquiryForm');
        var $fields = $('#field-name, #field-mail, #field-type, #field-body');
        var $submitButton = $('#submitButton');
        var $demoButtons = $('[data-demo]');

        // 送信中かどうか。disabled だけに頼らないための印。
        // テキスト欄で Enter を押す経路など、ボタンを通らない送信もあるためです
        var sending = false;

        // 直前に送った本文 (「同じ内容をもう一度」のデモで使い回す)
        var lastSentBody = null;

        // ------------------------------------------------------------------
        // 送信の本体
        // ------------------------------------------------------------------
        async function send(body, options) {
          var url = options.url || apiUrl;

          if (sending) {
            // 連打されてもここで止まります。押した回数ではなく「飛んだ回数」がログに残ります
            addLog(options.label, '-', 0, '送信中だったので送りませんでした');
            return;
          }
          sending = true;
          busy(true);
          clearFieldErrors();
          hideAlert();
          showSent(url, body);

          var startedAt = Date.now();
          var elapsed = 0;

          try {
            // ① 送る。form の値は URLSearchParams で「name=値&mail=値」の形にしてあります
            var res = await fetch(url, {
              method: 'POST',
              headers: {
                // これを忘れると、サーバ側の request.getParameter() が null になります
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'application/json'
              },
              body: body
            });

            // ② 本文を読む。res.json() ではなく res.text() にしているのは、
            //    受け取った生の文字列をそのまま画面に出したいからです
            var text = await res.text();
            elapsed = Date.now() - startedAt;
            showResponse(res.status, text);

            // ③ JSON として読む。エラー画面の HTML が返ってきた場合はここで失敗するので、
            //    例外にせず null にしておき、下の分岐で扱います
            var data = parseJsonOrNull(text);

            // ④ 入力エラー (400)。項目ごとにメッセージを当てます
            if (res.status === 400 && data && data.errors) {
              showFormArea();                       // 受付完了の表示が出ていたらフォームに戻す
              showFieldErrors(data.errors);
              showAlert(data.message || '入力内容を確認してください。');
              addLog(options.label, res.status, elapsed, '入力エラー ' + countOf(data.errors) + ' 件');
              return;
            }

            // ⑤ それ以外の失敗 (405 / 500 / JSON でない応答など)。
            //    res.ok はステータスが 200〜299 なら true です
            if (!res.ok || !data || data.ok !== true) {
              showAlert((data && data.message)
                ? data.message
                : 'サーバが HTTP ' + res.status + ' を返しました。時間をおいて試してください。');
              addLog(options.label, res.status, elapsed, '失敗');
              return;
            }

            // ⑥ 受け付けられた
            lastSentBody = body;
            showReceipt(data);
            addLog(options.label, res.status, elapsed,
              data.duplicate ? '受付済み (' + data.receipt + ' / 採番し直さず)' : '受付 ' + data.receipt);

          } catch (e) {
            // ⑦ ここに来るのは「そもそもサーバに届かなかった」ときです。
            //    オフライン、サーバの停止、ホスト名の間違いなど。
            //    404 や 500 は応答が返ってきているので、ここには来ません
            elapsed = Date.now() - startedAt;
            console.error(e);                       // 詳しい内容はコンソールへ
            showResponse('-', '(応答はありません) ' + String(e));
            // 利用者に出すのは e.message (例: Failed to fetch) ではなく、読める文にします
            showAlert('送信できませんでした。通信の状態を確かめて、もう一度お試しください。'
              + '入力した内容はそのまま残っています。');
            addLog(options.label, '-', elapsed, '通信失敗 (catch)');

          } finally {
            // ⑧ 成功でも失敗でも必ず通ります。ここで戻さないと、一度失敗したきり送れなくなります
            sending = false;
            busy(false);
          }
        }

        // ------------------------------------------------------------------
        // 送る値を組み立てる
        // ------------------------------------------------------------------
        function buildBody() {
          // URLSearchParams が、値に含まれる & や = や日本語のエスケープを引き受けてくれます。
          // 自分で文字列を連結すると、メールアドレスの + や本文の & で壊れます
          var params = new URLSearchParams();
          params.set('name', $('#field-name').val());
          params.set('mail', $('#field-mail').val());
          params.set('type', $('#field-type').val());
          params.set('body', $('#field-body').val());
          return params.toString();

          // 欄が多いときは、フォームからまとめて作れます (name 属性の付いた欄が拾われます)
          //   return new URLSearchParams(new FormData($form[0])).toString();
        }

        // ------------------------------------------------------------------
        // 画面の表示
        // ------------------------------------------------------------------

        // 通信中の見た目。押した反応をすぐ返し、二重に押させない
        function busy(isBusy) {
          $submitButton.prop('disabled', isBusy);
          $demoButtons.prop('disabled', isBusy);
          $submitButton.find('.spinner-border').toggleClass('d-none', !isBusy);
          $('#formStatus').text(isBusy ? '送信中です…' : '');
        }

        // 項目ごとのエラーを当てる
        function showFieldErrors(errors) {
          var names = Object.keys(errors);
          names.forEach(function (field) {
            // サーバ側が返すキー (name / mail / type / body) と、画面の id を揃えてあるので、
            // キーから対象の欄を引けます
            $('#field-' + field).addClass('is-invalid');
            // .text() で入れます。.html() だと、返ってきた文字列の中のタグが動いてしまいます
            $('#error-' + field).text(errors[field]);
          });
          // 最初のエラー項目へ移動する。JSON のキーの順はサーバ側で入れた順 = 画面の項目順です
          if (names.length > 0) {
            $('#field-' + names[0]).trigger('focus');
          }
        }

        // 前回のエラー表示を消す。消さずに足すと、直した項目のエラーが残り続けます
        function clearFieldErrors() {
          $fields.removeClass('is-invalid');
          $('.invalid-feedback').text('');
        }

        function showAlert(message) {
          $('#formAlert').text(message).removeClass('d-none');
        }

        // 受付完了の表示を閉じて、入力フォームに戻す
        function showFormArea() {
          $('#receiptArea').addClass('d-none');
          $('#formArea').removeClass('d-none');
        }

        function hideAlert() {
          $('#formAlert').addClass('d-none').text('');
        }

        // 受付完了。フォームを隠して受付番号を出します。
        // 入力欄を出したままにすると「送れたのか分からず、もう一度押す」ことになります
        function showReceipt(data) {
          $('#receiptNumber').text(data.receipt);
          $('#receiptMessage').text(data.message);
          $('#receiptAt').text(data.acceptedAt);
          $('#receiptType').text(data.received.typeLabel);
          $('#receiptName').text(data.received.name);
          $('#receiptMail').text(data.received.mail);
          $('#receiptBodyLength').text(data.received.bodyLength);
          $('#receiptDuplicate').toggleClass('d-none', data.duplicate !== true);
          $('#formArea').addClass('d-none');
          $('#receiptArea').removeClass('d-none');
          $('#formStatus').text('');
        }

        // 送った内容を画面に出す (何を送ったのかを目で確かめられるように)
        function showSent(url, body) {
          $('#sentUrl').text('POST ' + url);
          $('#sentBody').text(body);
          $('#sentBodyDecoded').text(decodeForDisplay(body));
          $('#responseStatus').text('(応答待ち)');
          $('#responseBody').text('');
        }

        function showResponse(status, text) {
          $('#responseStatus').text(status);
          $('#responseBody').text(text.length > 600 ? text.substring(0, 600) + ' …(以下略)' : text);
        }

        // パーセントエンコードを読める形に戻す (表示のためだけの処理)
        function decodeForDisplay(body) {
          try {
            return decodeURIComponent(body.split('+').join(' '));
          } catch (e) {
            return body;      // 壊れた並びでも画面を止めない
          }
        }

        function parseJsonOrNull(text) {
          try {
            return JSON.parse(text);
          } catch (e) {
            // 404 のときなどは、本文が JSON ではなくエラー画面の HTML です
            return null;
          }
        }

        function countOf(object) {
          return Object.keys(object).length;
        }

        // 通信ログに 1 行足す。要素を作って .text() で入れる = 文字列で HTML を組み立てない
        function addLog(label, status, elapsed, result) {
          var $row = $('<tr>')
            .append($('<td>').text(clockText()))
            .append($('<td>').text(label))
            .append($('<td>').text(status))
            .append($('<td>').addClass('text-right').text(elapsed + ' ms'))
            .append($('<td>').text(result));
          $('#logBody').prepend($row);
          $('#logEmpty').addClass('d-none');
        }

        function clockText() {
          var now = new Date();
          return ('0' + now.getHours()).slice(-2) + ':'
            + ('0' + now.getMinutes()).slice(-2) + ':'
            + ('0' + now.getSeconds()).slice(-2);
        }

        // ------------------------------------------------------------------
        // フォームの操作
        // ------------------------------------------------------------------

        // submit を拾うのがコツです。click だけを見ていると、
        // テキスト欄で Enter を押したときの送信を取りこぼします
        $form.on('submit', function (event) {
          // これを書き忘れると、fetch と同時にブラウザ本来の送信も走って画面が切り替わります
          event.preventDefault();
          send(buildBody(), {label: 'フォームから送信'});
        });

        // 直し始めたらエラー表示を消す (赤いまま入力させない)
        $fields.on('input change', function () {
          $(this).removeClass('is-invalid');
          $('#error-' + $(this).attr('id').substring('field-'.length)).text('');
        });

        // 本文の残り文字数。上限は Java 側の定数から渡された値です
        $('#field-body').on('input', function () {
          var rest = bodyMaxLength - $(this).val().length;
          $('#bodyRest').text(rest);
          $('#bodyRestArea').toggleClass('text-danger', rest < 0);
        });

        $('#fillSampleButton').on('click', function () {
          $('#field-name').val('山田 太郎');
          $('#field-mail').val('taro@example.com');
          $('#field-type').val('question');
          $('#field-body').val('サンプルの動かし方について教えてください。');
          $('#field-body').trigger('input');
          clearFieldErrors();
        });

        $('#resetButton').on('click', function () {
          $form[0].reset();
          clearFieldErrors();
          hideAlert();
          $('#bodyRest').text(bodyMaxLength);
          $('#bodyRestArea').removeClass('text-danger');
          $('#receiptArea').addClass('d-none');
          $('#formArea').removeClass('d-none');
          $('#field-name').trigger('focus');
        });

        // ------------------------------------------------------------------
        // うまくいかないときを試すボタン
        // ------------------------------------------------------------------
        $demoButtons.on('click', function () {
          var kind = $(this).attr('data-demo');

          if (kind === 'unreachable') {
            // 届かないホストへ送ります。応答が無いので catch に入ります
            send(buildBody(), {url: unreachableUrl, label: '届かないホストへ送信'});
            return;
          }

          if (kind === 'direct') {
            // 画面のフォームを通さず、空の値と選択肢に無い種別を直接 POST します。
            // 画面側のチェックを素通りしても、サーバ側が 400 で弾くことを確かめるためのものです
            var params = new URLSearchParams();
            params.set('name', '');
            params.set('mail', 'not-a-mail');
            params.set('type', 'secret-admin');   // 画面には無い値
            params.set('body', '');
            send(params.toString(), {label: '画面を通さず直接 POST'});
            return;
          }

          if (kind === 'again') {
            if (lastSentBody === null) {
              showAlert('先に 1 回送信してください。その内容をそのまま送り直します。');
              return;
            }
            send(lastSentBody, {label: '同じ内容をもう一度'});
          }
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
    <t:panel title="① お問い合わせフォーム" note="送信しても画面は切り替わりません">

      <%-- 項目に紐づかないメッセージ (通信の失敗など) を出す場所。
           受付完了の表示に切り替わっても見えるよう、フォームの外に置いています --%>
      <div class="alert alert-danger d-none" id="formAlert"></div>

      <div id="formArea">
        <p>
          送信ボタンを押すと、JavaScript が <code>${fn:escapeXml(apiPath)}</code> へ POST し、
          返ってきた JSON で画面の一部だけを書き換えます。
          <strong>わざと空のまま送ってみてください。</strong>
          入力した内容が消えないまま、項目ごとにエラーが出ます。
        </p>

        <%-- action と method を書いてあるのは、JavaScript を使わずに送ったときの行き先を
             はっきりさせるためです。実際の送信は submit イベントで止めて fetch に切り替えます --%>
        <form id="inquiryForm" action="${ctx}${apiPath}" method="post" novalidate>

          <div class="form-row">
            <div class="form-group col-md-6">
              <label for="field-name">お名前 <span class="badge badge-danger">必須</span></label>
              <%-- name 属性はサーバ側が受け取るキー、id はエラー表示で使うキーです。
                   どちらも JSON の errors のキーと同じ名前にしてあります --%>
              <input type="text" class="form-control" id="field-name" name="name"
                     placeholder="山田 太郎" autocomplete="off">
              <div class="invalid-feedback" id="error-name"></div>
              <small class="form-text text-muted">
                ${nameMaxLength} 文字以内。
                あえて <code>maxlength</code> を付けていないので、長い名前でサーバ側のチェックを試せます。
              </small>
            </div>

            <div class="form-group col-md-6">
              <label for="field-mail">メールアドレス <span class="badge badge-danger">必須</span></label>
              <%-- type="email" にするとブラウザ自身がチェックして送信を止めてしまうため、
                   サーバ側の応答を見せたいこのサンプルでは text にしています --%>
              <input type="text" class="form-control" id="field-mail" name="mail"
                     placeholder="taro@example.com" autocomplete="off">
              <div class="invalid-feedback" id="error-mail"></div>
              <small class="form-text text-muted">
                <code>@</code> を抜いて送ると、形式のエラーが返ります。
              </small>
            </div>
          </div>

          <div class="form-group">
            <label for="field-type">お問い合わせの種別 <span class="badge badge-danger">必須</span></label>
            <select class="custom-select" id="field-type" name="type">
              <option value="">選んでください</option>
              <%-- 選択肢はサーバ側の定義 (InquiryForm.TYPES) から作っています。
                   サーバが受け付けてよい値の一覧と、画面の選択肢を 1 か所から出すためです --%>
              <c:forEach var="entry" items="${types}">
                <option value="${fn:escapeXml(entry.key)}">${fn:escapeXml(entry.value)}</option>
              </c:forEach>
            </select>
            <div class="invalid-feedback" id="error-type"></div>
            <small class="form-text text-muted">
              選択肢に無い値が送られてくる前提で、サーバ側でも一覧と突き合わせて確かめています。
            </small>
          </div>

          <div class="form-group">
            <label for="field-body">お問い合わせ内容 <span class="badge badge-danger">必須</span></label>
            <textarea class="form-control" id="field-body" name="body" rows="4"
                      placeholder="お困りの内容をご記入ください。"></textarea>
            <div class="invalid-feedback" id="error-body"></div>
            <small class="form-text text-muted" id="bodyRestArea">
              残り <span id="bodyRest">${bodyMaxLength}</span> 文字
            </small>
          </div>

          <button type="submit" class="btn btn-primary" id="submitButton">
            <span class="spinner-border spinner-border-sm mr-1 d-none" role="status" aria-hidden="true"></span>
            この内容で送信する
          </button>
          <button type="button" class="btn btn-outline-secondary" id="fillSampleButton">入力例を入れる</button>
          <span class="text-muted small ml-2" id="formStatus"></span>

          <p class="text-muted small mt-3 mb-0">
            送信中はボタンを <code>disabled</code> にして、二重送信を防いでいます。
            押しっぱなしにしても連打しても、通信は 1 回しか飛びません
            （④ の通信ログで確かめられます）。
          </p>
        </form>
      </div>

      <div class="d-none" id="receiptArea">
        <div class="alert alert-success">
          <h5 class="alert-heading">
            <t:icon name="check-circle" size="16" cssClass="mr-1" />受け付けました
          </h5>
          <p class="mb-2" id="receiptMessage">-</p>
          <p class="mb-0">
            受付番号 <code class="h5" id="receiptNumber">-</code>
            <span class="badge badge-warning ml-2 d-none" id="receiptDuplicate">
              同じ内容だったので採番し直していません
            </span>
          </p>
        </div>

        <div class="table-responsive">
          <table class="table table-sm table-bordered">
            <tbody>
              <tr>
                <th scope="row" class="w-50">
                  サーバが受け取ったお名前
                  <span class="d-block text-muted small">前後の空白は落とされています</span>
                </th>
                <td id="receiptName">-</td>
              </tr>
              <tr>
                <th scope="row">サーバが受け取ったメールアドレス</th>
                <td id="receiptMail">-</td>
              </tr>
              <tr>
                <th scope="row">
                  種別
                  <span class="d-block text-muted small">送ったのは値、表示名はサーバ側の定義から</span>
                </th>
                <td id="receiptType">-</td>
              </tr>
              <tr>
                <th scope="row">お問い合わせ内容の文字数</th>
                <td><span id="receiptBodyLength">-</span> 文字</td>
              </tr>
              <tr>
                <th scope="row">受付日時（サーバの時計）</th>
                <td><code id="receiptAt">-</code></td>
              </tr>
            </tbody>
          </table>
        </div>

        <button type="button" class="btn btn-outline-secondary" id="resetButton">
          <t:icon name="arrow-repeat" size="14" cssClass="mr-1" />別の内容をもう一度送る
        </button>
        <p class="text-muted small mt-3 mb-0">
          ここまで、画面は一度も読み込み直されていません。
          URL も <code>${fn:escapeXml(ctx)}/samples/ajax/ajax-form</code> のままなので、
          ブラウザの「戻る」を押すとこの画面より前へ戻ってしまいます。
          送信の結果を URL で共有したいなら、素直に画面遷移にするほうが向いています。
        </p>
      </div>
    </t:panel>

    <t:panel title="② 送った内容と、返ってきた JSON" note="何がやり取りされているかをそのまま出しています">
      <div class="row">
        <div class="col-lg-6 mb-3">
          <div class="text-muted small mb-1">送ったリクエスト</div>
<pre class="code-snippet mb-2" id="sentUrl">（まだ送信していません）</pre>
          <div class="text-muted small mb-1">
            本文（<code>application/x-www-form-urlencoded</code>）
          </div>
<pre class="code-snippet mb-2" id="sentBody"></pre>
          <div class="text-muted small mb-1">本文を読める形に戻したもの</div>
<pre class="code-snippet mb-0" id="sentBodyDecoded"></pre>
          <p class="text-muted small mt-2 mb-0">
            日本語や記号は <code>%E5%B1%B1</code> のような形（パーセントエンコード）になります。
            この変換は <code>URLSearchParams</code> がやってくれるので、自分で書く必要はありません。
          </p>
        </div>
        <div class="col-lg-6 mb-3">
          <div class="text-muted small mb-1">HTTP ステータス</div>
<pre class="code-snippet mb-2" id="responseStatus">-</pre>
          <div class="text-muted small mb-1">返ってきた本文</div>
<pre class="code-snippet mb-0" id="responseBody"></pre>
          <p class="text-muted small mt-2 mb-0">
            成功は <code>200</code>、入力エラーは <code>400</code> です。
            ステータスを正しく使い分けておくと、アクセスログや監視からも失敗が見えます。
            本文の <code>ok</code> は、ステータスの代わりではなく<strong>添えるもの</strong>です。
          </p>
        </div>
      </div>
    </t:panel>

    <t:panel title="③ うまくいかないときを試す" note="押したときに ① と ② の表示がどう変わるかを見てください">
      <div class="row">
        <div class="col-md-4 mb-3">
          <div class="card h-100">
            <div class="card-body">
              <h6 class="card-title">通信に失敗したとき</h6>
              <p class="card-text small text-muted">
                実在しないホスト（<code>.invalid</code>）へ POST します。応答が返ってこないので、
                <code>fetch</code> の <strong><code>catch</code></strong> に入ります。
                入力した内容はそのまま残ることも確かめてください。
              </p>
              <p class="card-text small text-muted">
                <strong>存在しない「パス」では <code>catch</code> に入りません。</strong>
                404 の応答が返ってきた時点で <code>fetch</code> としては成功だからです。
              </p>
              <button type="button" class="btn btn-outline-warning btn-sm" data-demo="unreachable">
                届かない URL へ送ってみる
              </button>
            </div>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="card h-100">
            <div class="card-body">
              <h6 class="card-title">画面を通さずに直接 POST する</h6>
              <p class="card-text small text-muted">
                フォームを使わず、<strong>空のお名前・形式の違うメール・選択肢に無い種別</strong>を
                そのまま送ります。画面側のチェックはすべて素通りしますが、
                サーバが <strong>400</strong> で弾きます。
              </p>
              <p class="card-text small text-muted">
                API の URL さえ分かれば誰でもこれができます。
                <strong>サーバ側の検証を省けない理由</strong>がこれです。
              </p>
              <button type="button" class="btn btn-outline-danger btn-sm" data-demo="direct">
                おかしな値を直接 POST する
              </button>
            </div>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="card h-100">
            <div class="card-body">
              <h6 class="card-title">同じ内容をもう一度すぐ送る</h6>
              <p class="card-text small text-muted">
                1 回送信してから押してください。ボタンの <code>disabled</code> を迂回して、
                直前とまったく同じ内容をもう一度 POST します。
              </p>
              <p class="card-text small text-muted">
                サーバ側が <strong>${duplicateWindowSeconds} 秒以内の同じ内容</strong>を覚えているので、
                受付番号は<strong>増えません</strong>。画面側の工夫だけに頼らない、ということです。
              </p>
              <button type="button" class="btn btn-outline-secondary btn-sm" data-demo="again">
                同じ内容をもう一度送る
              </button>
            </div>
          </div>
        </div>
      </div>
      <p class="text-muted small mb-0">
        このサンプルには <strong>CSRF 対策が入っていません</strong>（トークンの検証を省いています）。
        実務では、画面を出すときにトークンを発行してセッションに覚えておき、
        POST されたトークンと突き合わせてから処理します。詳しくは解説タブに書いています。
      </p>
    </t:panel>

    <t:panel title="④ 通信ログ" note="飛んだ通信と、飛ばさずに止めた分を記録します">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-2">
          <thead>
            <tr>
              <th>時刻（ブラウザ）</th>
              <th>きっかけ</th>
              <th>HTTP</th>
              <th class="text-right">所要</th>
              <th>結果</th>
            </tr>
          </thead>
          <tbody id="logBody">
            <tr id="logEmpty">
              <td colspan="5" class="text-center text-muted">まだ送信していません。</td>
            </tr>
          </tbody>
        </table>
      </div>
      <button type="button" class="btn btn-outline-secondary btn-sm" id="clearLogButton">ログを消す</button>
      <p class="text-muted small mt-3 mb-0">
        送信ボタンを連打しても、<strong>実際に通信した行は 1 行だけ</strong>です。
        <code>disabled</code> にするだけでなく、送信中かどうかの印を関数の入口で見ているためです。
        止めた分は、何が起きたのかが分かるように
        「送信中だったので送りませんでした」という行として残しています
        （HTTP の欄が <code>-</code> になっているものがそれです）。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
