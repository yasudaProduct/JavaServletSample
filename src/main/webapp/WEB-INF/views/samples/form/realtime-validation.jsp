<%--
  【サンプル】入力チェック (フォーカスアウト時)

  入力欄からフォーカスが外れた時点で、その場でチェックして知らせる形のサンプルです。
  画面側 (JavaScript) とサーバ側 (RealtimeValidationServlet) で同じチェックをしていて、
  「JavaScript のチェックを無効にして送る」ボタンで、サーバ側が弾く様子も試せます。

  RealtimeValidationServlet が次の値をセットします。
    form             … 画面から受け取った入力値 (ContactForm)。初期表示では空のもの
    errors           … サーバ側の入力チェックの結果 (ValidationErrors)
    nameMaxLength    … お名前の上限 (Java の定数をそのまま渡している)
    messageMaxLength … お問い合わせ内容の上限
    flash            … 受付完了メッセージ (リダイレクト後の 1 回だけ)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/form/realtime-validation" />
<t:sample sampleId="realtime-validation">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>処理の流れ</h2>
    <ol>
      <li>利用者が入力欄を離れる（<code>blur</code>）と、JavaScript がその欄だけをチェックする</li>
      <li>
        結果に応じて <code>is-valid</code> / <code>is-invalid</code> を付け替え、
        <code>invalid-feedback</code> にメッセージを入れる
      </li>
      <li>
        エラーが出ている欄を打ち直している間（<code>input</code>）は、
        <strong>直ったときにエラーを消すだけ</strong>。新しいエラーは出さない
      </li>
      <li>送信ボタンを押したら全項目をチェックし直し、エラーがあれば送信を止めて最初のエラー欄にフォーカスする</li>
      <li>
        送信されると <code>RealtimeValidationServlet#doPost</code> が
        <strong>同じチェックをもう一度</strong>行う
      </li>
      <li>
        サーバ側でエラー → 同じ画面へ forward して画面上部に一覧を出す。
        エラー無し → <code>Flash</code> に完了メッセージを預けてリダイレクト（PRG パターン）
      </li>
    </ol>

    <h2>クライアント側は「親切」、サーバ側は「防御」</h2>
    <p>
      この 2 つは<strong>目的が違うので、どちらか一方では足りません</strong>。
      画面側のチェックは「送信する前に気づいてもらう」ためのもので、
      無くてもアプリは成立します。サーバ側のチェックは「おかしなデータを受け入れない」ためのもので、
      これが無いとアプリが壊れます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th></th><th>クライアント側（JavaScript）</th><th>サーバ側（Servlet）</th></tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">目的</th>
            <td>早く気づいてもらう（親切）</td>
            <td>おかしなデータを受け入れない（防御）</td>
          </tr>
          <tr>
            <th scope="row">いつ動くか</th>
            <td>入力中・フォーカスアウト時・送信ボタンを押したとき</td>
            <td>リクエストを受け取ったとき</td>
          </tr>
          <tr>
            <th scope="row">迂回できるか</th>
            <td>できる（JavaScript を切る、<code>form.submit()</code>、<code>curl</code> で直接 POST）</td>
            <td>できない（サーバの中で動くため）</td>
          </tr>
          <tr>
            <th scope="row">無いとどうなるか</th>
            <td>送信して戻ってくるまで間違いに気づけない（使い勝手の問題）</td>
            <td>不正なデータが保存される（データの問題）</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      サーバ側だけで確かめる形は
      <a href="${ctx}/samples/form/input-validation">入力チェック（サーバ側）</a>
      のサンプルで扱っています。書く順番としては
      <strong>先にサーバ側を作り、あとから画面側を足す</strong>と迷いません。
      画面側は「無くても動くもの」なので、後から足しても壊れないからです。
    </p>

    <h2><code>blur</code> と <code>input</code> と <code>change</code> の使い分け</h2>
    <p>
      「リアルタイムにチェックする」と言っても、<strong>打っている最中に怒るのは親切ではありません</strong>。
      メールアドレス欄に <code>t</code> と 1 文字打った瞬間に
      「メールアドレスの形式が正しくありません」と出たら、入力し終わるまでずっと赤いままです。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>イベント</th><th>いつ起きるか</th><th>このサンプルでの使い道</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>blur</code></td>
            <td>その欄からフォーカスが外れたとき</td>
            <td><strong>チェックしてエラーを出す</strong>（入力が一区切りついた合図として使う）</td>
          </tr>
          <tr>
            <td><code>input</code></td>
            <td>値が変わるたび（1 文字ごと）</td>
            <td><strong>すでに出ているエラーを消す</strong>／文字数カウンタの更新</td>
          </tr>
          <tr>
            <td><code>change</code></td>
            <td>値が確定したとき（テキストは blur 時、チェックボックスや <code>select</code> は選んだ時点）</td>
            <td>選択系の項目に使う（このサンプルでは「緑を付ける」チェックボックス）</td>
          </tr>
        </tbody>
      </table>
    </div>
<pre><code class="language-javascript">// 入力が一区切りついたところでチェックする
field.addEventListener('blur', function () {
  validateField(field);
});

// 打ち直している間は「解除」だけ。新しくエラーは出さない
field.addEventListener('input', function () {
  if (!field.classList.contains('is-invalid')) {
    return;                      // まだエラーが出ていない欄には何もしない
  }
  if (rules[field.name](field.value) === '') {
    markValid(field);            // 直ったので、その場で赤を消す
  }
});</code></pre>
    <p>
      テキスト入力に <code>change</code> を使うと <code>blur</code> とほぼ同じ挙動になりますが、
      <strong>値が変わらなかったときは発生しません</strong>。
      「一度エラーを出した欄を、何も直さずに通り過ぎた」場合にチェックが走らないので、
      入力チェックには <code>blur</code> のほうが向いています。
    </p>
    <p class="text-muted">
      なお <code>blur</code> は<strong>バブリングしません</strong>。
      欄が多いフォームで <code>form.addEventListener('blur', ...)</code> のように
      まとめて受けたい場合は、バブリングする <code>focusout</code> を使います
      （<code>event.target</code> でどの欄かを見分けます）。
    </p>

    <h2>緑（<code>is-valid</code>）を全部に付けるか</h2>
    <p>
      Bootstrap には <code>is-valid</code>（緑の枠 + チェックマーク）がありますが、
      <strong>全部の欄に付けると画面がうるさくなります</strong>。
      正しく入力できているのは当たり前なので、わざわざ褒める必要はない、という考え方です。
      デモの「問題のない欄にも緑を付ける」チェックボックスで切り替えて見比べてみてください。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>方針</th><th>向いている画面</th><th>気になる点</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>エラーだけ出す（緑は付けない）</td>
            <td>ふつうの入力フォーム</td>
            <td>チェックが働いているのか分かりにくい、と言われることがある</td>
          </tr>
          <tr>
            <td>触った欄だけ緑を付ける</td>
            <td>項目が多い / 長い申込フォーム</td>
            <td>「どこまで済んだか」が分かる。このサンプルの既定</td>
          </tr>
          <tr>
            <td>最初から全部に色を付ける</td>
            <td>（あまり無い）</td>
            <td>何も触っていないのに赤だらけになり、見てもらえなくなる</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      色だけで伝えないことも大切です。赤枠だけでなく
      <strong>必ず文章のメッセージを添えます</strong>
      （色が見分けにくい人にも、読み上げソフトにも伝わるようにするため）。
    </p>

    <h2>文字数カウンタ</h2>
    <p>
      「残り n 文字」は、<code>input</code> で更新します。
      <strong>これは「エラーを出している」のではなく「状況を見せている」</strong>ので、
      打っている最中に動いても邪魔になりません。
      上限を超えたときだけ、例外的に入力中でも赤くしています
      （超えていることは打っている本人にも明らかなので、驚かせません）。
    </p>
<pre><code class="language-javascript">function updateCounter() {
  // サーバ側は strip() してから数えるので、こちらも trim() してから数える
  var used = countChars(messageField.value.trim());
  var rest = messageMax - used;
  counter.textContent = rest &gt;= 0
      ? '残り ' + rest + ' 文字'
      : '上限を ' + (-rest) + ' 文字超えています';
  counter.classList.toggle('text-danger', rest &lt; 0);
}</code></pre>

    <h3><code>maxlength</code> を付けない理由</h3>
    <p>
      <code>maxlength</code> を付けると、上限を超えた入力は<strong>黙って捨てられます</strong>。
      長い文章を貼り付けた利用者は、途中で切れたことに気づかないまま送信してしまいます。
      このサンプルでは <code>maxlength</code> を付けず、
      <strong>超えて入力できるが、超えていることを知らせる</strong>形にしています。
    </p>

    <h3>文字数の数え方をサーバと合わせる</h3>
    <p>
      JavaScript の <code>value.length</code> も Java の <code>String.length()</code> も、
      返すのは UTF-16 の単位数です。絵文字や一部の漢字（𠮟 など）は 2 と数えられます。
      画面に「200 文字以内」と書いたなら、人が数えた文字数に合わせておくのが親切です。
    </p>
<pre><code class="language-javascript">'𠮟'.length                // 2
Array.from('𠮟').length     // 1  ← こちらで数える</code></pre>
<pre><code class="language-java">value.length();                                 // 2
value.codePointCount(0, value.length());        // 1  ← こちらで数える</code></pre>
    <p>
      <strong>数え方が食い違うと、利用者には理由の分からない現象になります</strong>
      （「画面では残り 3 文字なのに、送信したらサーバに怒られた」）。
    </p>

    <h3>textarea の改行は送信時に 2 文字になる</h3>
    <p>
      これは気づきにくい落とし穴です。
      JavaScript から見える <code>textarea.value</code> の改行は <code>\n</code> の 1 文字ですが、
      <strong>フォームが送信されるときには <code>\r\n</code> の 2 文字に変換されます</strong>。
      そのまま数えると、改行 1 つにつきサーバ側だけ 1 文字増えます。
    </p>
<pre><code class="language-java">// サーバ側 : 数える前に改行を \n へ揃える
private static String normalizeNewlines(String value) {
    return value.replace("\r\n", "\n").replace("\r", "\n");
}</code></pre>
    <p class="text-muted">
      10 行の問い合わせなら 10 文字ずれます。文字数制限のある <code>textarea</code> では必ず出る話です。
    </p>

    <h2>送信ボタンを押したとき</h2>
    <p>
      <code>blur</code> のチェックだけでは<strong>一度も触っていない欄が残ります</strong>
      （何も入力せずにいきなり送信ボタンを押す人は必ずいます）。
      そこで <code>submit</code> で全項目をチェックし直します。
    </p>
<pre><code class="language-javascript">form.addEventListener('submit', function (event) {
  var firstInvalid = null;
  fields.forEach(function (field) {
    if (!validateField(field) &amp;&amp; firstInvalid === null) {
      firstInvalid = field;       // 最初に見つかったエラー欄を覚えておく
    }
  });
  if (firstInvalid !== null) {
    event.preventDefault();       // 送信を止める
    showSummary();                // 画面上部にまとめて出す
    firstInvalid.focus();         // そこまで連れて行く（利用者に探させない）
  }
});</code></pre>
    <p>
      <code>focus()</code> を忘れると、画面の下のほうでエラーが出たときに
      <strong>「押しても何も起きないボタン」</strong>になってしまいます。
      エラーの一覧を画面の上部に出すなら、項目名も一緒に書いて、どこを直すのかを分かるようにします。
    </p>
    <p class="text-muted">
      「エラーがある間は送信ボタンを <code>disabled</code> にする」という作りも見かけますが、
      <strong>なぜ押せないのかが利用者に分かりません</strong>。
      押させて、その場でエラーを出すほうが親切です。
    </p>

    <h2>JavaScript のチェックを無効にして送る</h2>
    <p>デモの赤いボタンがやっているのは、これだけです。</p>
<pre><code class="language-javascript">document.getElementById('rv-bypass').addEventListener('click', function () {
  form.submit();     // submit イベントは発生しない = 上のチェックを通らない
});</code></pre>
    <p>
      <strong><code>form.submit()</code> は <code>submit</code> イベントを発生させません</strong>。
      これはブラウザの仕様です（そうしないと、送信処理の中で <code>submit()</code> を呼んだときに
      無限ループになります）。つまり、
      <strong>画面側のチェックは「ページの JavaScript」だけで簡単に迂回できます</strong>。
      ブラウザの設定で JavaScript を切る、開発者ツールから呼ぶ、<code>curl</code> で直接 POST する、
      といった方法もあります。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>やり方</th><th><code>submit</code> イベント</th><th>HTML5 の検証（<code>required</code> など）</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>送信ボタンを押す</td>
            <td>起きる</td>
            <td>働く（<code>novalidate</code> が無ければ）</td>
          </tr>
          <tr>
            <td><code>form.submit()</code></td>
            <td><strong>起きない</strong></td>
            <td><strong>働かない</strong></td>
          </tr>
          <tr>
            <td><code>form.requestSubmit()</code></td>
            <td>起きる</td>
            <td>働く</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      自分のコードからフォームを送りたいときは、
      <strong>検証を飛ばしたくないなら <code>requestSubmit()</code></strong> を使います
      （<code>submit()</code> だと自前のチェックまで素通りしてしまいます）。
      このサンプルは<strong>あえて</strong> <code>submit()</code> を使って、
      素通りしたリクエストをサーバ側が弾くところを見せています。
    </p>

    <h2>アクセシビリティ（読み上げへの配慮）</h2>
    <ul>
      <li>
        <strong><code>aria-invalid="true"</code></strong>：
        赤枠は目で見える人にしか伝わりません。エラーにした欄にはこの属性を付けて、
        直ったら<strong>外します</strong>（付けっぱなしだと「ずっとエラー」と読まれます）。
      </li>
      <li>
        <strong><code>aria-describedby</code></strong>：
        補足説明とエラーメッセージの <code>id</code> を並べて指定しておくと、
        欄にフォーカスしたときに一緒に読み上げられます。
<pre class="mb-0"><code class="language-xml">&lt;input id="rv-name" aria-describedby="rv-name-help rv-name-feedback"&gt;
&lt;div class="invalid-feedback" id="rv-name-feedback"&gt;&lt;/div&gt;
&lt;small class="form-text text-muted" id="rv-name-help"&gt;30 文字以内&lt;/small&gt;</code></pre>
      </li>
      <li>
        <strong>メッセージは書き換える、作り直さない</strong>：
        <code>invalid-feedback</code> の中身を <code>textContent</code> で入れ替える形にしておくと、
        <code>aria-describedby</code> の参照が切れません。
        要素ごと作り直すと <code>id</code> の対応が壊れがちです。
      </li>
      <li>
        <strong>まとめて出すエラーには <code>role="alert"</code></strong>：
        送信を止めたときの一覧は、出た瞬間に読み上げてほしい情報です。
        逆に文字数カウンタのような「変わり続けるもの」は
        <code>aria-live="polite"</code>（読んでいる途中を邪魔しない）にします。
      </li>
      <li>
        <strong><code>label</code> と <code>for</code> を必ず結ぶ</strong>：
        読み上げのためでもあり、ラベルをクリックすると入力欄にフォーカスが移るという
        使い勝手のためでもあります。
      </li>
    </ul>

    <h2>HTML5 の <code>required</code> / <code>type="email"</code> との併用</h2>
    <p>
      ブラウザには最初から入力チェックの仕組みがあります。ただ、実務では
      <strong>文面と出し方を自分で決めたい</strong>ことがほとんどです。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th></th><th>ブラウザ標準（<code>required</code> など）</th><th>自前の JavaScript</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>書く量</td>
            <td>属性を付けるだけ</td>
            <td>それなりに書く</td>
          </tr>
          <tr>
            <td>メッセージ</td>
            <td>ブラウザ任せ（文面も言語も変えにくい）</td>
            <td>自由</td>
          </tr>
          <tr>
            <td>出る場所</td>
            <td>吹き出し。<strong>最初の 1 件だけ</strong>で、スクロールすると消える</td>
            <td>欄の下に、全部まとめて</td>
          </tr>
          <tr>
            <td>見た目</td>
            <td>ブラウザごとに違う</td>
            <td>揃えられる</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>このサンプルは「属性は付けるが、表示は自前でやる」という組み合わせにしています。</p>
<pre><code class="language-xml">&lt;form action="..." method="post" novalidate&gt;
  &lt;input type="email" name="email" required&gt;</code></pre>
    <ul>
      <li>
        <code>type="email"</code> / <code>type="tel"</code> は付けておく …
        <strong>スマートフォンで出るキーボードが変わります</strong>。
        入力チェックのためというより、入力しやすさのためです
      </li>
      <li>
        <code>required</code> も付けておく …
        支援技術に「必須の項目」と伝わります（見た目の「必須」バッジだけでは伝わりません）
      </li>
      <li>
        <code>novalidate</code> を付ける …
        <strong>ブラウザの吹き出しだけを止めます</strong>。
        これが無いと、ブラウザの吹き出しと自前のメッセージが二重に出ます
      </li>
    </ul>
    <p class="text-muted">
      逆に「ブラウザ標準に寄せる」道もあります。その場合は <code>novalidate</code> を付けず、
      <code>setCustomValidity()</code> で文面だけ差し替えるか、
      <code>invalid</code> イベントを拾って自分で表示します。
      <strong>どちらかに寄せることが大事</strong>で、混ぜると二重に出ます。
    </p>

    <h2>サーバに聞かないと分からないチェック</h2>
    <p>
      「このメールアドレスはすでに登録されています」「この社員番号は存在しません」のような、
      <strong>手元のデータだけでは判断できないチェック</strong>は、
      フォーカスアウトのタイミングでサーバへ問い合わせることになります。
      そのやり方は
      <a href="${ctx}/samples/ajax/ajax-form">非同期通信のサンプル（ajax-form）</a>
      で扱います。考えることが増えます。
    </p>
    <ul>
      <li>打つたびに問い合わせない（<code>input</code> ごとに投げると通信だらけになる。待ってから送る）</li>
      <li>応答が返るまでの表示（「確認中…」を出す。押せないボタンを黙って置かない）</li>
      <li>古い応答が後から返ってくる問題（順番が入れ替わるので、最後のリクエスト以外は捨てる）</li>
      <li>通信できなかったときの扱い（<strong>「確認できなかった」であって「OK」ではありません</strong>）</li>
      <li>それでも<strong>登録時にサーバ側でもう一度確かめる</strong>（確認と登録の間に他の人が登録するかもしれません）</li>
    </ul>

    <h2>同じ規則を 2 か所に書くことについて</h2>
    <p>
      画面側とサーバ側に同じチェックを書くことになります。これは避けられません。
      避けられないなら、<strong>せめてズレにくくします</strong>。
      このサンプルでは、文字数の上限を Java の定数から画面へ渡しています。
    </p>
<pre><code class="language-java">// Servlet
request.setAttribute("nameMaxLength", ContactForm.NAME_MAX_LENGTH);</code></pre>
<pre><code class="language-xml">&lt;form id="contactForm" data-name-max="${'${nameMaxLength}'}" ...&gt;
&lt;small class="form-text text-muted"&gt;${'${nameMaxLength}'} 文字以内で入力してください。&lt;/small&gt;</code></pre>
<pre><code class="language-javascript">var nameMax = Number(form.getAttribute('data-name-max'));</code></pre>
    <p>
      こうしておくと、上限を 30 から 40 に変えるときに直すのは Java の定数 1 か所だけです。
      画面の説明文・JavaScript のチェック・サーバ側のチェックが、同時に付いてきます。
    </p>
    <p class="text-muted">
      それでも「正規表現」や「チェックの順番」は 2 か所に残ります。
      どうしても 1 か所にしたい場合は、規則を JSON でサーバから配って
      画面側がそれを解釈する、という作りもありますが、そこまでやる価値があるかは規模次第です。
      <strong>食い違ったときはサーバ側が正しい</strong>、という決めだけは共有しておきます。
    </p>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong><code>blur</code> はバブリングしない</strong>：
        親要素でまとめて拾えません。イベント委譲をしたいときは <code>focusout</code> を使います。
      </li>
      <li>
        <strong><code>form.submit()</code> では自前のチェックが動かない</strong>：
        このサンプルではそれを利用していますが、逆に言うと
        <strong>「JavaScript でフォームを送る画面」を作るとチェックがすり抜けます</strong>。
        <code>requestSubmit()</code> を使うか、送る前に自分でチェックを呼びます。
      </li>
      <li>
        <strong><code>is-invalid</code> を付けても赤いメッセージが出ない</strong>：
        Bootstrap の <code>.invalid-feedback</code> は既定で非表示で、
        <code>.is-invalid</code> を持つ要素の<strong>あとに続く兄弟要素</strong>のときだけ表示されます。
        順番を入れ替えたり、<code>div</code> で包んだりすると出てきません。
      </li>
      <li>
        <strong>値を直しても赤が消えない</strong>：
        <code>is-invalid</code> は付けたら自動では外れません。
        直ったことを確かめて<strong>自分で外す</strong>処理（このサンプルの <code>input</code> の部分）が要ります。
      </li>
      <li>
        <strong>サーバ側のエラーで戻ってきた直後の状態</strong>：
        JSP が出した <code>is-invalid</code> を JavaScript が知らないと、
        打ち直してもエラーが消えません。このサンプルは初期化で
        <strong>「すでに赤い欄は、触った扱いにする」</strong>ようにしています。
      </li>
      <li>
        <strong>日本語入力（IME）の変換中にも <code>input</code> は起きる</strong>：
        「やま」「山」と変換していく途中の値でチェックすると、意味のないエラーが出ます。
        入力中にエラーを出さない作りにしておけば、この問題はほとんど避けられます
        （どうしても必要なら <code>compositionstart</code> / <code>compositionend</code> で変換中を判定します）。
      </li>
      <li>
        <strong>自動入力（オートフィル）では <code>input</code> が飛ばないことがある</strong>：
        ブラウザが値を入れた直後は、緑にも赤にもならないまま残ることがあります。
        送信時に全項目をチェックし直す作りにしておけば、取りこぼしません。
      </li>
      <li>
        <strong>エラーメッセージを <code>innerHTML</code> で入れない</strong>：
        入力値をメッセージに含めるとき（「現在 31 文字」など）、
        <code>innerHTML</code> に組み立てるとクロスサイトスクリプティングの穴になります。
        <code>textContent</code> を使います。
      </li>
      <li>
        <strong>全角数字</strong>：
        電話番号を IME が有効なまま打つと <code>０９０…</code> になります。
        このサンプルは弾いていますが、
        「サーバ側で半角に直してから検証する」という方針もあります（どちらにするかを決めておきます）。
      </li>
      <li>
        <strong>画面の説明文と実装の食い違い</strong>：
        「30 文字以内」と書いてあるのに実装は 40 だった、はよくあります。
        上限は定数にして、説明文もメッセージもそこから組み立てます。
      </li>
    </ul>

    <h2>関連するサンプル</h2>
    <ul>
      <li>
        <a href="${ctx}/samples/form/input-validation">入力チェック（サーバ側）</a>
        … サーバ側だけで確かめる形。チェックの順番、エラーメッセージの文面、境界値のテスト
      </li>
      <li>
        <a href="${ctx}/samples/ajax/ajax-form">非同期通信のサンプル（ajax-form）</a>
        … サーバに問い合わせないと分からないチェック（重複チェックなど）
      </li>
      <li>
        <a href="${ctx}/samples/design/modal-dialog">モーダル（ダイアログ）の出し方</a>
        … 送信後の完了モーダルと <code>Flash</code> の仕組み
      </li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {

        var form = document.getElementById('contactForm');
        if (!form) {
          return;
        }

        // 上限の数字は Java の定数を data-* 経由で受け取る。
        // JavaScript に 30 と直接書くと、Java 側を変えたときにここだけ取り残される
        var nameMax = Number(form.getAttribute('data-name-max'));
        var messageMax = Number(form.getAttribute('data-message-max'));

        // サーバ側 (ContactForm) と同じ正規表現・同じ文面にしてある。
        // 食い違うと「画面では OK なのにサーバでエラー」という一番困る状態になる
        var EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        var TEL = /^0[0-9]{9,10}$|^0[0-9]{1,4}-[0-9]{1,4}-[0-9]{3,4}$/;

        // 文字数の数え方。value.length は UTF-16 の長さなので絵文字などが 2 と数えられる。
        // Java 側の codePointCount と揃えるため、Array.from で数える
        function countChars(value) {
          return Array.from(value).length;
        }

        // 項目ごとの規則。返すのはエラーメッセージで、問題なければ空文字。
        // 「必須 → 形式 → 長さ」の順に見て、引っかかったらそこで打ち切る
        var rules = {
          name: function (value) {
            var text = value.trim();
            if (text === '') {
              return 'お名前を入力してください。';
            }
            var length = countChars(text);
            if (length > nameMax) {
              return 'お名前は ' + nameMax + ' 文字以内で入力してください。(現在 ' + length + ' 文字)';
            }
            return '';
          },
          email: function (value) {
            var text = value.trim();
            if (text === '') {
              return 'メールアドレスを入力してください。';
            }
            if (!EMAIL.test(text)) {
              return 'メールアドレスの形式が正しくありません。(例: taro@example.com)';
            }
            return '';
          },
          tel: function (value) {
            var text = value.trim();
            if (text === '') {
              // 任意の項目。空のままフォーカスを外しても何も言わない。
              // 任意なのに毎回何か出ると、利用者はエラー表示そのものを見なくなる
              return '';
            }
            if (!TEL.test(text)) {
              return '電話番号は半角数字とハイフンで入力してください。(例: 09012345678 または 090-1234-5678)';
            }
            return '';
          },
          message: function (value) {
            var text = value.trim();
            if (text === '') {
              return 'お問い合わせ内容を入力してください。';
            }
            var length = countChars(text);
            if (length > messageMax) {
              return 'お問い合わせ内容は ' + messageMax + ' 文字以内で入力してください。(現在 ' + length + ' 文字)';
            }
            return '';
          }
        };

        var fields = ['name', 'email', 'tel', 'message'].map(function (key) {
          return document.getElementById('rv-' + key);
        });
        var messageField = document.getElementById('rv-message');
        var counter = document.getElementById('rv-message-counter');
        var showValidBox = document.getElementById('rv-show-valid');
        var summary = document.getElementById('rv-js-summary');
        var summaryList = document.getElementById('rv-js-summary-list');
        var logList = document.getElementById('rv-log');

        // 「この欄はもう触った」かどうか。触っていない欄を勝手に緑にしないために持つ
        var touched = {};

        // 入力欄と、その下のメッセージ欄は id の規則で結び付けてある
        function feedbackOf(field) {
          return document.getElementById(field.id + '-feedback');
        }

        // ラベルの文字（先頭のテキストだけ。「必須」バッジは拾わない）
        function labelOf(field) {
          var label = document.querySelector('label[for="' + field.id + '"]');
          return label && label.firstChild ? label.firstChild.textContent.trim() : field.name;
        }

        function markInvalid(field, message) {
          field.classList.add('is-invalid');
          field.classList.remove('is-valid');
          // 赤枠は目で見える人にしか伝わらない。読み上げソフトにはこの属性で伝える
          field.setAttribute('aria-invalid', 'true');
          // 入力値を含むメッセージなので innerHTML は使わない (XSS になる)
          feedbackOf(field).textContent = message;
        }

        function markValid(field) {
          field.classList.remove('is-invalid');
          // 直ったら必ず外す。付けっぱなしだと「ずっとエラー」と読まれてしまう
          field.removeAttribute('aria-invalid');
          feedbackOf(field).textContent = '';
          // 緑を付けるかは方針次第 (チェックボックスで切り替えられるようにしている)
          if (showValidBox.checked && field.value.trim() !== '') {
            field.classList.add('is-valid');
          } else {
            field.classList.remove('is-valid');
          }
        }

        // 1 項目を確かめる。エラーが無ければ true
        function validateField(field) {
          var message = rules[field.name](field.value);
          if (message === '') {
            markValid(field);
            return true;
          }
          markInvalid(field, message);
          return false;
        }

        // 文字数カウンタ。これは「エラー」ではなく「状況の表示」なので input で更新してよい
        function updateCounter() {
          // サーバ側は strip() で前後の空白を落としてから数える。
          // ここで trim() を忘れると、末尾に空白を打っただけで
          // 「上限を 3 文字超えています」と出るのに送信は通る、という食い違いになる
          var used = countChars(messageField.value.trim());
          var rest = messageMax - used;
          counter.textContent = rest >= 0
              ? '残り ' + rest + ' 文字'
              : '上限を ' + (-rest) + ' 文字超えています';
          counter.classList.toggle('text-danger', rest < 0);
          counter.classList.toggle('text-muted', rest >= 0);
          // 上限超過だけは入力中でも赤くする。
          // 打っている本人にも原因が明らかなので、驚かせる心配がない
          if (rest < 0) {
            markInvalid(messageField, rules.message(messageField.value));
          }
        }

        function showSummary(messages) {
          summaryList.innerHTML = '';
          messages.forEach(function (text) {
            var item = document.createElement('li');
            item.textContent = text;
            summaryList.appendChild(item);
          });
          summary.classList.remove('d-none');
        }

        function hideSummary() {
          summary.classList.add('d-none');
        }

        // 画面下の「発火したイベント」に 1 行足す (このサンプルの説明用。実務では不要)
        var LOG_BADGE = {
          blur: 'badge-primary',
          input: 'badge-info',
          change: 'badge-secondary',
          submit: 'badge-dark',
          click: 'badge-danger'
        };

        function log(type, field, text) {
          var placeholder = document.getElementById('rv-log-empty');
          if (placeholder) {
            placeholder.parentNode.removeChild(placeholder);
          }
          var item = document.createElement('li');
          var badge = document.createElement('span');
          badge.className = 'badge ' + (LOG_BADGE[type] || 'badge-secondary') + ' mr-2';
          badge.textContent = type;
          item.appendChild(badge);
          item.appendChild(document.createTextNode(
              (field ? labelOf(field) + ' : ' : '') + text));
          logList.insertBefore(item, logList.firstChild);
          while (logList.children.length > 8) {
            logList.removeChild(logList.lastElementChild);
          }
        }

        fields.forEach(function (field) {

          // ① フォーカスが外れた時点でチェックする。
          //    input (1 文字ごと) にすると、メールアドレスを 1 文字打った瞬間に
          //    「形式が正しくありません」と出てしまう
          field.addEventListener('blur', function () {
            touched[field.name] = true;
            var ok = validateField(field);
            log('blur', field, ok ? 'チェック OK' : 'エラーを表示しました');
          });

          // ② 打ち直している間は「解除」だけを行う。ここで新しいエラーは出さない
          field.addEventListener('input', function () {
            if (field === messageField) {
              updateCounter();
            }
            if (!field.classList.contains('is-invalid')) {
              return;                       // まだエラーが出ていない欄には何もしない
            }
            if (rules[field.name](field.value) === '') {
              markValid(field);
              log('input', field, 'エラーが直ったので解除しました');
            }
          });
        });

        // ③ 送信時は全項目を確かめ直す。
        //    blur だけでは「一度も触っていない欄」が残るため
        form.addEventListener('submit', function (event) {
          var firstInvalid = null;
          var messages = [];

          fields.forEach(function (field) {
            touched[field.name] = true;
            if (!validateField(field)) {
              if (firstInvalid === null) {
                firstInvalid = field;
              }
              messages.push(labelOf(field) + ' : ' + feedbackOf(field).textContent);
            }
          });

          if (firstInvalid === null) {
            hideSummary();
            log('submit', null, 'エラーが無いのでサーバへ送信します');
            return;                          // 何もしなければ、そのまま送信される
          }

          event.preventDefault();            // 送信を止める
          showSummary(messages);
          firstInvalid.focus();              // 最初のエラー項目へ連れて行く
          log('submit', firstInvalid, 'エラーがあるので送信を止めました');
        });

        // ④ JavaScript のチェックを通さずに送る。
        //    form.submit() は submit イベントを発生させないので、③ は呼ばれない。
        //    「画面側のチェックは迂回できる」ことを画面上で試せるようにしたもの
        document.getElementById('rv-bypass').addEventListener('click', function () {
          log('click', null, 'JS のチェックを通さずに送信します (form.submit())');
          form.submit();
        });

        // ⑤ チェックボックスは change で見る (選び終わったことを表すのは change のほう)
        showValidBox.addEventListener('change', function () {
          fields.forEach(function (field) {
            if (!touched[field.name] || field.classList.contains('is-invalid')) {
              return;
            }
            markValid(field);                // 緑を付け直す / 外す
          });
          log('change', null, showValidBox.checked
              ? 'OK の欄にも緑を付けます'
              : '緑を消しました (エラーだけ出す方針)');
        });

        document.getElementById('rv-log-clear').addEventListener('click', function () {
          logList.innerHTML = '';
        });

        // 初期化 : サーバ側のチェックで赤くなって戻ってきた欄は「もう触った」扱いにする。
        // こうしておかないと、打ち直してもエラーが消えない
        // (② は「すでにエラーが出ている欄」しか見ないため、状態を合わせておく必要がある)
        fields.forEach(function (field) {
          if (field.classList.contains('is-invalid')) {
            touched[field.name] = true;
            field.setAttribute('aria-invalid', 'true');
          }
        });
        updateCounter();
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:panel title="お問い合わせフォーム" note="各欄からフォーカスを外した時点でチェックします">

      <c:if test="${not empty errors.messages}">
        <div class="alert alert-danger" role="alert">
          <strong>サーバ側のチェックで弾きました（${errors.count} 件）</strong>
          <p class="small mb-2 mt-1">
            画面側の JavaScript を通さずに送られてきたため、
            <code>RealtimeValidationServlet</code> が同じチェックを行って止めています。
          </p>
          <ul class="mb-0">
            <c:forEach var="message" items="${errors.messages}">
              <li>${fn:escapeXml(message)}</li>
            </c:forEach>
          </ul>
        </div>
      </c:if>

      <div class="alert alert-warning d-none" id="rv-js-summary" role="alert">
        <strong>入力内容を確認してください</strong>
        <ul class="mb-0 mt-2" id="rv-js-summary-list"></ul>
      </div>

      <form action="${formUrl}" method="post" id="contactForm" novalidate
            data-name-max="${nameMaxLength}" data-message-max="${messageMaxLength}">

        <div class="form-group">
          <label for="rv-name">お名前 <span class="badge badge-danger">必須</span></label>
          <input type="text" class="form-control ${errors.has('name') ? 'is-invalid' : ''}"
                 id="rv-name" name="name" value="${fn:escapeXml(form.name)}"
                 placeholder="例: 山田太郎" required
                 aria-describedby="rv-name-help rv-name-feedback">
          <div class="invalid-feedback" id="rv-name-feedback">${fn:escapeXml(errors.get('name'))}</div>
          <small id="rv-name-help" class="form-text text-muted">
            ${nameMaxLength} 文字以内で入力してください。
          </small>
        </div>

        <div class="form-row">
          <div class="form-group col-md-7">
            <label for="rv-email">メールアドレス <span class="badge badge-danger">必須</span></label>
            <input type="email" class="form-control ${errors.has('email') ? 'is-invalid' : ''}"
                   id="rv-email" name="email" value="${fn:escapeXml(form.email)}"
                   placeholder="例: taro@example.com" required
                   aria-describedby="rv-email-help rv-email-feedback">
            <div class="invalid-feedback" id="rv-email-feedback">${fn:escapeXml(errors.get('email'))}</div>
            <small id="rv-email-help" class="form-text text-muted">
              <code>type="email"</code> を付けていますが、フォームに <code>novalidate</code> を
              付けてあるので、ブラウザの吹き出しは出ません（表示は自前で行います）。
            </small>
          </div>

          <div class="form-group col-md-5">
            <label for="rv-tel">電話番号 <span class="badge badge-secondary">任意</span></label>
            <input type="tel" class="form-control ${errors.has('tel') ? 'is-invalid' : ''}"
                   id="rv-tel" name="tel" value="${fn:escapeXml(form.tel)}"
                   placeholder="例: 090-1234-5678"
                   aria-describedby="rv-tel-help rv-tel-feedback">
            <div class="invalid-feedback" id="rv-tel-feedback">${fn:escapeXml(errors.get('tel'))}</div>
            <small id="rv-tel-help" class="form-text text-muted">
              任意なので、空のままフォーカスを外しても何も出ません。
            </small>
          </div>
        </div>

        <div class="form-group">
          <label for="rv-message">お問い合わせ内容 <span class="badge badge-danger">必須</span></label>
          <textarea class="form-control ${errors.has('message') ? 'is-invalid' : ''}"
                    id="rv-message" name="message" rows="4" required
                    placeholder="ご用件をご記入ください。"
                    aria-describedby="rv-message-help rv-message-feedback rv-message-counter">${fn:escapeXml(form.message)}</textarea>
          <div class="invalid-feedback" id="rv-message-feedback">${fn:escapeXml(errors.get('message'))}</div>
          <div class="d-flex justify-content-between">
            <small id="rv-message-help" class="form-text text-muted">
              ${messageMaxLength} 文字以内。<code>maxlength</code> は付けていません
              （黙って切り捨てず、超えたことに気づいてもらうため）。
            </small>
            <small id="rv-message-counter" class="form-text text-muted text-nowrap ml-3"
                   aria-live="polite">残り ${messageMaxLength} 文字</small>
          </div>
        </div>

        <div class="form-group">
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="rv-show-valid" checked>
            <label class="custom-control-label" for="rv-show-valid">
              問題のない欄にも緑（<code>is-valid</code>）を付ける
            </label>
          </div>
          <small class="form-text text-muted">
            外すと「エラーのときだけ知らせる」方針になります。見比べてみてください。
          </small>
        </div>

        <button type="submit" class="btn btn-primary">
          <t:icon name="check-circle" cssClass="mr-1" />送信する
        </button>
        <button type="button" class="btn btn-outline-danger ml-2" id="rv-bypass">
          JavaScript のチェックを無効にして送る
        </button>
        <a class="btn btn-link" href="${formUrl}">入力をクリア</a>
      </form>

      <p class="text-muted small mt-3 mb-0">
        赤いボタンは <code>form.submit()</code> を呼ぶだけのボタンです。
        <code>form.submit()</code> は <code>submit</code> イベントを起こさないため、
        上の JavaScript のチェックを通らずにサーバへ届きます。
      </p>
    </t:panel>

    <t:panel title="発火したイベント" note="どの操作でチェックが動いたのかを新しい順に記録します">
      <ul class="list-unstyled small mb-2" id="rv-log">
        <li class="text-muted" id="rv-log-empty">
          （まだ何も起きていません。上のフォームを操作してみてください）
        </li>
      </ul>
      <button type="button" class="btn btn-sm btn-outline-secondary" id="rv-log-clear">
        <t:icon name="arrow-repeat" size="14" cssClass="mr-1" />ログを消す
      </button>
    </t:panel>

    <t:panel title="このフォームのチェック内容" note="画面側の JavaScript と ContactForm で同じ内容を確かめています">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th scope="col">項目</th>
              <th scope="col">必須</th>
              <th scope="col">チェックの内容</th>
              <th scope="col">いつ出るか</th>
              <th scope="col">試してみる値</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">お名前</th>
              <td>必須</td>
              <td>${nameMaxLength} 文字以内（サロゲートペアも 1 文字として数える）</td>
              <td>フォーカスアウト時</td>
              <td><code>（空白だけ）</code></td>
            </tr>
            <tr>
              <th scope="row">メールアドレス</th>
              <td>必須</td>
              <td><code>@</code> の前後があり、後ろ側にドットがあること</td>
              <td>フォーカスアウト時</td>
              <td><code>taro.example.com</code></td>
            </tr>
            <tr>
              <th scope="row">電話番号</th>
              <td>任意</td>
              <td>
                0 で始まる 10 桁か 11 桁の数字、またはハイフンで 3 つに区切った形
                （<code>090-1234-5678</code> / <code>03-1234-5678</code>）
              </td>
              <td>フォーカスアウト時（空欄なら何も出ない）</td>
              <td><code>０９０１２３４５６７８</code>（全角）</td>
            </tr>
            <tr>
              <th scope="row">お問い合わせ内容</th>
              <td>必須</td>
              <td>${messageMaxLength} 文字以内</td>
              <td>フォーカスアウト時＋<strong>超過は入力中も</strong></td>
              <td><code>（${messageMaxLength} 文字を超える文章を貼り付ける）</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="試してみる手順" note="画面側とサーバ側、どちらが働いているのかを見分けられます">
      <ol class="mb-0">
        <li>
          お名前欄をクリックして、<strong>何も入力せずに</strong>次の欄へ移る
          → その場で赤くなります（<code>blur</code>）
        </li>
        <li>
          赤くなった欄に 1 文字入力する
          → 打った瞬間にエラーが消えます（<code>input</code> での解除）
        </li>
        <li>
          メールアドレスに <code>taro</code> とだけ入れてフォーカスを外す
          → 形式のエラーが出ます
        </li>
        <li>
          お問い合わせ内容に長い文章を貼り付ける
          → 「残り n 文字」が減り、超えると赤くなります
        </li>
        <li>
          全部空のまま<strong>「送信する」</strong>を押す
          → 送信は止まり、画面上部に一覧が出て、最初のエラー欄にフォーカスが移ります
        </li>
        <li>
          全部空のまま<strong>「JavaScript のチェックを無効にして送る」</strong>を押す
          → 画面側のチェックは動かず、<strong>サーバ側が弾いて</strong>赤い一覧付きで戻ってきます
        </li>
        <li>
          正しく入力して「送信する」
          → PRG（POST → リダイレクト → GET）で完了モーダルが開きます
        </li>
      </ol>
    </t:panel>

    <t:panel title="関連するサンプル">
      <ul class="mb-0">
        <li>
          <a href="${ctx}/samples/form/input-validation">入力チェック（サーバ側）</a>
          … こちらはサーバ側だけで確かめる形です。対になるサンプルなので、続けて読むと違いが分かります
        </li>
        <li>
          <a href="${ctx}/samples/ajax/ajax-form">非同期通信のサンプル（ajax-form）</a>
          … メールアドレスの重複チェックのように、サーバに聞かないと分からないチェック
        </li>
      </ul>
    </t:panel>

    <t:resultModal message="${flash}" />
  </jsp:body>
</t:sample>
