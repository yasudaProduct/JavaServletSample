<%--
  【サンプル】入力チェック (サーバ側)

  JavaScript を使わず、送られてきた値をサーバ側だけで確かめる形のサンプルです。

  InputValidationServlet が次の値をセットします。
    form   … 画面から受け取った入力値 (MemberForm)。初期表示では空のもの
    errors … 入力チェックの結果 (ValidationErrors)。初期表示では空のもの
    flash  … 登録完了メッセージ (リダイレクト後の 1 回だけ)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/form/input-validation" />
<t:sample sampleId="input-validation">

  <jsp:attribute name="explanation">
    <h2>処理の流れ</h2>
    <ol>
      <li>画面が <code>POST</code> でフォームを送る</li>
      <li><code>InputValidationServlet#doPost</code> が
          <code>MemberForm.from(request)</code> で入力値を受け取る（この時点では良し悪しを判断しない）</li>
      <li><code>form.validate()</code> が <code>ValidationErrors</code> を返す</li>
      <li>
        エラーがある → 入力値とエラーを <code>request</code> スコープに入れて
        <strong>同じ JSP へ forward</strong>。画面の先頭にエラー一覧、各項目に赤い枠とメッセージを出す
      </li>
      <li>
        エラーが無い → 登録処理を行い（このサンプルでは保存はしていません）、
        完了メッセージを <code>Flash</code> に預けて
        <strong>リダイレクト</strong>（PRG パターン）。移動先で完了モーダルが開く
      </li>
    </ol>

    <h2>サーバ側のチェックが「最後の砦」です</h2>
    <p>
      ブラウザ側のチェック（HTML の <code>required</code> や JavaScript）は、
      <strong>利用者にその場で気づいてもらうため</strong>のものです。
      親切ではありますが、次のように簡単に迂回できます。
    </p>
    <ul>
      <li>ブラウザの設定で JavaScript を無効にする</li>
      <li>開発者ツールで <code>required</code> や <code>maxlength</code> を消してから送信する</li>
      <li>そもそもブラウザを使わず、<code>curl</code> などで直接 POST する</li>
    </ul>
<pre><code class="language-plaintext">curl -X POST https://example.com/samples/form/input-validation \
     -d "name=&amp;email=xxx&amp;age=999&amp;password=1"</code></pre>
    <p>
      サーバから見れば、これは画面から送られたリクエストと区別がつきません。
      <strong>受け取った値を信用してよい理由はどこにも無い</strong>ので、
      画面側で何を確かめていたとしても、サーバ側でもう一度すべて確かめます。
      このサンプルでは、その動きを確かめてもらうために
      <strong>ブラウザ側のチェックをあえて外して</strong>あります
      （<code>required</code> を付けず、年齢も <code>type="number"</code> にしていません）。
    </p>
    <p class="text-muted">
      逆に言うと、ブラウザ側のチェックは「無くても動く」ものです。
      先にサーバ側を書いてから、使い勝手のために画面側を足す、という順で考えると迷いません
      （入力しながらその場で気づける形は
      <a href="${ctx}/samples/form/realtime-validation">フォーカスアウト時のチェック</a>
      のサンプルで扱っています）。
    </p>
    <p class="text-muted">
      文字種（半角英数・全角カタカナ）、日付の実在、選択肢の妥当性、マスタとの突き合わせなど、
      チェックの種類ごとの書き方は
      <a href="${ctx}/samples/form/validation-rules">入力チェックの種類</a>
      のサンプルにまとめてあります。
    </p>

    <h2>チェックの順番と「1 項目 1 メッセージ」</h2>
    <p>1 つの項目については、次の順に見て、引っかかったらそこで打ち切ります。</p>
<pre><code class="language-plaintext">必須 → 形式 → 範囲 → （最後に）相関</code></pre>
    <p>
      順番に意味があります。未入力の年齢に「0 から 120 の範囲で入力してください」と言っても
      的外れですし、<code>三十</code> という文字列に範囲の判定はできません。
      <strong>手前のチェックを通った値だけが、次のチェックの前提を満たしている</strong>と考えると
      自然に順番が決まります。
    </p>
<pre><code class="language-java">// 年齢 : 任意 → 形式 → 範囲
if (age.isEmpty()) {
    return;                       // 任意項目なので未入力は OK
}
if (!INTEGER.matcher(age).matches()) {
    errors.add("age", "年齢は半角数字で入力してください。(例: 30)");
    return;                       // 形が違う値に範囲の判定はできない
}
int value = Integer.parseInt(age);
if (value &lt; 0 || value &gt; 120) {
    errors.add("age", "年齢は 0 から 120 の範囲で入力してください。");
}</code></pre>
    <p>
      そして<strong>1 つの欄に出すメッセージは 1 つ</strong>にします。
      「8 文字以上にしてください」「英字と数字を含めてください」「一致しません」が
      同時に並ぶと、どれから直せばよいのか分からなくなるためです。
      <code>ValidationErrors</code> は同じ項目に 2 件目を入れても
      <strong>最初の 1 件だけ</strong>を残すようになっているので、
      呼ぶ側は気にせず <code>add</code> できます。
    </p>

    <h3>相関チェック（項目をまたぐチェック）は最後に</h3>
    <p>
      「パスワードと確認用パスワードが一致すること」のように、
      <strong>2 つ以上の項目を見ないと判定できない</strong>ものを相関チェックと呼びます。
      これは各項目が妥当だと分かってから行います。
    </p>
<pre><code class="language-java">private void validatePasswordConfirm(ValidationErrors errors) {
    // パスワード側がエラーなら、一致の判定はしない
    // (「8 文字以上に」と「一致しません」が並ぶと直し方が分からなくなる)
    if (errors.has("password")) {
        return;
    }
    if (passwordConfirm.isEmpty()) {
        errors.add("passwordConfirm", "確認のため、パスワードをもう一度入力してください。");
    } else if (!password.equals(passwordConfirm)) {
        errors.add("passwordConfirm", "パスワードが一致しません。もう一度入力してください。");
    }
}</code></pre>
    <p>
      エラーを付ける項目は<strong>確認欄の側だけ</strong>にしています。
      両方を赤くすると「どちらが正しいのか」が伝わりません。
    </p>

    <h2>前後の空白の扱い</h2>
    <p>
      氏名やメールアドレスは、受け取った時点で前後の空白を落とします。
      そうしないと<strong>スペースだけの氏名</strong>が「入力あり」として通ってしまいます。
    </p>
    <p>
      落とすのには <code>trim()</code> ではなく <code>strip()</code>（Java 11 以降）を使っています。
      <code>trim()</code> が削るのは <code>U+0020</code> 以下の文字だけなので、
      <strong>全角スペースが残ってしまう</strong>ためです。
    </p>
<pre><code class="language-java">"　".trim()    // → "　"  (全角スペースが残る)
"　".strip()   // → ""    (Unicode の空白判定なので落ちる)</code></pre>
    <p>
      一方で<strong>パスワードは削りません</strong>。空白もパスワードに使える文字なので、
      サーバが勝手に削ると「登録したはずのパスワードでログインできない」という事故になります。
      「どの項目を削り、どの項目を削らないか」は<strong>決めて、書いておく</strong>種類の判断です。
    </p>

    <h2>入力値を保持して返す</h2>
    <p>
      エラーで戻すときに入力値が消えていると、利用者は全部打ち直しになります。
      そこで <code>forward</code> でそのまま同じ JSP に戻し、<code>value</code> に入れ直します。
    </p>
<pre><code class="language-java">// Servlet 側
request.setAttribute("form", form);       // 受け取った値そのもの
request.setAttribute("errors", errors);
forward(request, response, VIEW);         // sendRedirect では request スコープが消える</code></pre>
<pre><code class="language-xml">&lt;input type="text" class="form-control ${"${errors.has('name') ? 'is-invalid' : ''}"}"
       name="name" value="${"${fn:escapeXml(form.name)}"}"&gt;
&lt;div class="invalid-feedback"&gt;${"${fn:escapeXml(errors.get('name'))}"}&lt;/div&gt;</code></pre>
    <p>
      <code>value</code> に入れ直す値は<strong>必ずエスケープします</strong>。
      利用者が打った文字列をそのまま書き戻す場所なので、ここを抜かすと
      <code>"&gt;&lt;script&gt;...</code> のような入力で HTML が壊れます
      （クロスサイトスクリプティング）。
    </p>

    <h3>パスワードは戻さない</h3>
    <p>
      パスワード欄だけは <code>value</code> を空のままにします。
    </p>
    <ul>
      <li>HTML に平文で書き出されるため、画面のソースやキャッシュに残る</li>
      <li>打ち直してもらったほうが、打ち間違いに気づける</li>
    </ul>
    <p>
      そのため、エラーのときはパスワードだけ再入力になります。これは仕様です。
      <code>MemberForm</code> にパスワードの getter を作っていないのも同じ理由で、
      <strong>うっかり画面に出せないようにする</strong>ためです（<code>toString()</code> にも含めていません）。
    </p>

    <h2>エラーなら forward、成功ならリダイレクト</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>結果</th><th>やること</th><th>理由</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>エラーあり</td>
            <td><code>forward</code>（同じ画面へ）</td>
            <td>
              入力値とエラーをリクエストスコープのまま渡せる。
              アドレス欄は変わらないので、再読み込みすると再送信の確認が出ます
            </td>
          </tr>
          <tr>
            <td>エラーなし</td>
            <td><code>sendRedirect</code>（PRG パターン）</td>
            <td>完了後に再読み込みされても、登録が 2 回実行されない</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      成功時のメッセージはリダイレクトで消えてしまうので、
      <code>Flash</code>（セッションに預けて次の 1 回だけ取り出す仕組み）を使っています。
      詳しくは
      <a href="${ctx}/samples/design/modal-dialog">モーダル（ダイアログ）の出し方</a>
      のサンプルで扱っています。
    </p>

    <h2>正規表現によるメールアドレス検証の限界</h2>
    <p>このサンプルが使っているのは、これだけです。</p>
<pre><code class="language-java">Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");</code></pre>
    <p>
      「ゆるすぎるのでは」と感じるかもしれませんが、意図的にこうしています。
    </p>
    <ul>
      <li>
        <strong>RFC に忠実な正規表現は現実的ではない</strong>：
        引用符付きのローカル部やコメントまで考えると数百文字になり、読めなくなります
      </li>
      <li>
        <strong>厳しくすると実在するアドレスを弾く</strong>：
        <code>+</code> を使ったエイリアス、新しい TLD、国際化ドメインなど、
        「見たことがない形＝間違い」ではありません。
        弾かれた利用者には回避手段がありません
      </li>
      <li>
        <strong>形が合っていても届くとは限らない</strong>：
        実在するかどうかは<strong>確認メールを送って初めて分かります</strong>。
        本気で確かめたいなら、正規表現を磨くより確認メールを実装するほうが確実です
      </li>
    </ul>
    <p>
      ここでのチェックの目的は「<code>@</code> を入れ忘れた」「スペースが混ざった」といった
      <strong>打ち間違いに気づいてもらうこと</strong>です。それ以上は狙いません。
    </p>

    <h2>エラーメッセージの文面</h2>
    <p>
      メッセージは<strong>何をどう直せばよいかが分かる</strong>ように書きます。
      「入力が不正です」と言われても、利用者にできることがありません。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>避けたい書き方</th><th>このサンプルの書き方</th><th>違い</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>入力が不正です</td>
            <td>氏名を入力してください。</td>
            <td>どの項目の話かが分かる</td>
          </tr>
          <tr>
            <td>桁数エラー</td>
            <td>氏名は 50 文字以内で入力してください。(現在 51 文字)</td>
            <td>上限と、いま何文字なのかが分かる</td>
          </tr>
          <tr>
            <td>形式が正しくありません</td>
            <td>郵便番号は 7 桁の数字で入力してください。(例: 1234567 または 123-4567)</td>
            <td>正しい例がその場に書いてある</td>
          </tr>
          <tr>
            <td>ERROR: age out of range</td>
            <td>年齢は 0 から 120 の範囲で入力してください。</td>
            <td>利用者の言葉になっている</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      文体も揃えます（このサンプルは「〜してください。」で統一し、句点も付けています）。
      揃っていないと、画面の先頭にエラーが 5 件並んだときにちぐはぐに見えます。
    </p>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>文字化けした値をそのままチェックしてしまう</strong>：
        リクエストの文字コードを決めておかないと、日本語の氏名が化けた状態で届きます。
        化けた文字列に「50 文字以内」を当てても意味がありません。しかも
        <code>request.setCharacterEncoding("UTF-8")</code> は
        <strong>最初の <code>getParameter</code> より前</strong>に呼ばないと効きません
        （呼んだあとでは手遅れです）。このサンプル集では <code>web.xml</code> に
        <code>&lt;request-character-encoding&gt;UTF-8&lt;/request-character-encoding&gt;</code>
        （Servlet 4.0 の機能）を書いてあるので、Servlet 側では何もしていません。
      </li>
      <li>
        <strong>チェックボックスは、チェックしないと値が届かない</strong>：
        <code>request.getParameter("agree")</code> は <code>"off"</code> ではなく
        <code>null</code> を返します。値ではなく<strong>パラメータの有無</strong>で判定します。
      </li>
      <li>
        <strong><code>Integer.parseInt("２０")</code> は 20 を返す</strong>：
        全角数字も通ってしまいます。画面の表示と保存した値がずれるので、
        先に <code>^-?[0-9]+$</code> のような形のチェックを通しています。
      </li>
      <li>
        <strong>数字だけでも <code>parseInt</code> は失敗しうる</strong>：
        <code>99999999999999999999</code> は <code>int</code> に収まらず
        <code>NumberFormatException</code> になります。500 エラーにせず、
        範囲外として扱います。
      </li>
      <li>
        <strong><code>String.length()</code> は文字数ではない</strong>：
        UTF-16 の単位数なので、絵文字や一部の漢字（𠮟 など）は 2 と数えられます。
        「50 文字以内」と書いたなら <code>codePointCount</code> で数えるほうが親切です。
      </li>
      <li>
        <strong><code>is-invalid</code> だけでは赤いメッセージが出ない</strong>：
        Bootstrap の <code>.invalid-feedback</code> は既定で非表示で、
        <code>.is-invalid</code> を持つ要素の<strong>あとに続く兄弟要素</strong>のときだけ表示されます。
        順番を入れ替えると出てきません。
      </li>
      <li>
        <strong>エラー一覧を出したのに、どの欄か分からない</strong>：
        画面の先頭にまとめるだけでなく、<strong>項目のそばにも</strong>出します。
        入力欄が多い画面では、先頭の一覧だけだとスクロールして探すことになります。
      </li>
      <li>
        <strong><code>${'${errors.empty}'}</code> と書くと画面が落ちる</strong>：
        <code>empty</code> は EL の予約語です。
        このサンプルでは <code>${'${not empty errors.messages}'}</code> と
        <code>${"${errors.has('name')}"}</code>（EL 3.0 のメソッド呼び出し）を使っています。
      </li>
      <li>
        <strong>チェックの数字が画面と Java で食い違う</strong>：
        画面に「50 文字以内」と書いたのに実装が 40 だった、という食い違いはよくあります。
        上限は定数にして、メッセージもその定数から組み立てます。
      </li>
    </ul>

    <h2>テストを書いておく</h2>
    <p>
      入力チェックは<strong>間違っていても画面からは気づけません</strong>
      （「1 文字多くても通ってしまう」を目で見つけるのは無理です）。
      <code>MemberForm</code> を Servlet API から切り離して純粋な Java にしてあるのは、
      Tomcat を起動せずにテストできるようにするためです。
    </p>
<pre><code class="language-java">@Test
@DisplayName("50 文字ちょうどは通る")
void acceptsExactly50() {
    assertFalse(withName(repeat("あ", 50)).has("name"));
}

@Test
@DisplayName("51 文字はエラー")
void rejects51() {
    assertTrue(withName(repeat("あ", 51)).has("name"));
}</code></pre>
    <p>
      確かめるのは<strong>境界値</strong>、つまり「ちょうど通る値」と「1 つだけ外れた値」です。
      0 文字 / 50 文字 / 51 文字、年齢の -1 / 0 / 120 / 121 のように、
      境目をまたぐ 2 つを必ずセットで書きます。
      テストの全文は
      <code>src/test/java/com/example/servletsample/samples/form/MemberFormTest.java</code>
      にあります（境界値を並べただけなので、量のわりには読むのが楽です）。
    </p>
  </jsp:attribute>

  <jsp:body>
    <t:panel title="会員登録フォーム" note="JavaScript は使っていません。すべてサーバ側で確かめています">

      <c:if test="${not empty errors.messages}">
        <div class="alert alert-danger" role="alert">
          <strong>入力内容を確認してください（${errors.count} 件）</strong>
          <ul class="mb-0 mt-2">
            <c:forEach var="message" items="${errors.messages}">
              <li>${fn:escapeXml(message)}</li>
            </c:forEach>
          </ul>
        </div>
      </c:if>

      <form action="${formUrl}" method="post" novalidate>

        <div class="form-group">
          <label for="name">氏名 <span class="badge badge-danger">必須</span></label>
          <input type="text" class="form-control ${errors.has('name') ? 'is-invalid' : ''}"
                 id="name" name="name" value="${fn:escapeXml(form.name)}"
                 placeholder="例: 山田太郎"
                 aria-describedby="nameHelp">
          <div class="invalid-feedback">${fn:escapeXml(errors.get('name'))}</div>
          <small id="nameHelp" class="form-text text-muted">50 文字以内で入力してください。</small>
        </div>

        <div class="form-group">
          <label for="email">メールアドレス <span class="badge badge-danger">必須</span></label>
          <input type="text" class="form-control ${errors.has('email') ? 'is-invalid' : ''}"
                 id="email" name="email" value="${fn:escapeXml(form.email)}"
                 placeholder="例: taro@example.com"
                 aria-describedby="emailHelp">
          <div class="invalid-feedback">${fn:escapeXml(errors.get('email'))}</div>
          <small id="emailHelp" class="form-text text-muted">
            ブラウザ側のチェックを働かせないため、<code>type="email"</code> ではなく
            <code>type="text"</code> にしています。
          </small>
        </div>

        <div class="form-row">
          <div class="form-group col-md-4">
            <label for="age">年齢 <span class="badge badge-secondary">任意</span></label>
            <input type="text" class="form-control ${errors.has('age') ? 'is-invalid' : ''}"
                   id="age" name="age" value="${fn:escapeXml(form.age)}"
                   placeholder="例: 30"
                   aria-describedby="ageHelp">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('age'))}</div>
            <small id="ageHelp" class="form-text text-muted">0 から 120 の半角数字。</small>
          </div>

          <div class="form-group col-md-4">
            <label for="zipCode">郵便番号 <span class="badge badge-secondary">任意</span></label>
            <input type="text" class="form-control ${errors.has('zipCode') ? 'is-invalid' : ''}"
                   id="zipCode" name="zipCode" value="${fn:escapeXml(form.zipCode)}"
                   placeholder="例: 123-4567"
                   aria-describedby="zipCodeHelp">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('zipCode'))}</div>
            <small id="zipCodeHelp" class="form-text text-muted">ハイフンは有っても無くても構いません。</small>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group col-md-6">
            <label for="password">パスワード <span class="badge badge-danger">必須</span></label>
            <input type="password" class="form-control ${errors.has('password') ? 'is-invalid' : ''}"
                   id="password" name="password" value=""
                   aria-describedby="passwordHelp">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('password'))}</div>
            <small id="passwordHelp" class="form-text text-muted">
              8 文字以上で、英字と数字を両方含めてください。
            </small>
          </div>

          <div class="form-group col-md-6">
            <label for="passwordConfirm">パスワード（確認） <span class="badge badge-danger">必須</span></label>
            <input type="password"
                   class="form-control ${errors.has('passwordConfirm') ? 'is-invalid' : ''}"
                   id="passwordConfirm" name="passwordConfirm" value=""
                   aria-describedby="passwordConfirmHelp">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('passwordConfirm'))}</div>
            <small id="passwordConfirmHelp" class="form-text text-muted">
              同じものをもう一度入力してください。
            </small>
          </div>
        </div>

        <div class="form-group">
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input ${errors.has('agree') ? 'is-invalid' : ''}"
                   id="agree" name="agree" ${form.agreed ? 'checked' : ''}>
            <label class="custom-control-label" for="agree">
              利用規約に同意します <span class="badge badge-danger">必須</span>
            </label>
            <div class="invalid-feedback">${fn:escapeXml(errors.get('agree'))}</div>
          </div>
        </div>

        <button type="submit" class="btn btn-primary">
          <t:icon name="check-circle" cssClass="mr-1" />登録する
        </button>
        <a class="btn btn-link" href="${formUrl}">入力をクリア</a>
      </form>

      <p class="text-muted small mt-3 mb-0">
        パスワードは、エラーで戻したときも<strong>再表示していません</strong>
        （HTML に平文で書き出さないため）。他の項目は入力したまま残ります。
      </p>
    </t:panel>

    <t:panel title="このフォームのチェック内容" note="画面の説明文と Java の実装が食い違わないよう、同じ内容を書いています">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th scope="col">項目</th>
              <th scope="col">必須</th>
              <th scope="col">チェックの内容</th>
              <th scope="col">試してみる値</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">氏名</th>
              <td>必須</td>
              <td>50 文字以内（サロゲートペアも 1 文字として数える）</td>
              <td><code>（空白だけ）</code></td>
            </tr>
            <tr>
              <th scope="row">メールアドレス</th>
              <td>必須</td>
              <td><code>@</code> の前後があり、後ろ側にドットがあること</td>
              <td><code>taro.example.com</code></td>
            </tr>
            <tr>
              <th scope="row">年齢</th>
              <td>任意</td>
              <td>半角数字で 0 から 120</td>
              <td><code>２０</code> / <code>-1</code> / <code>121</code></td>
            </tr>
            <tr>
              <th scope="row">郵便番号</th>
              <td>任意</td>
              <td>7 桁（<code>1234567</code> / <code>123-4567</code>）</td>
              <td><code>1234-567</code></td>
            </tr>
            <tr>
              <th scope="row">パスワード</th>
              <td>必須</td>
              <td>8 文字以上で、英字と数字を両方含む</td>
              <td><code>password</code></td>
            </tr>
            <tr>
              <th scope="row">パスワード（確認）</th>
              <td>必須</td>
              <td>パスワードと一致していること（相関チェック）</td>
              <td><code>PASS1234</code></td>
            </tr>
            <tr>
              <th scope="row">利用規約への同意</th>
              <td>必須</td>
              <td>チェックが付いていること</td>
              <td><code>（チェックしない）</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="ブラウザを通さずに送ってみる" note="サーバ側のチェックが最後の砦である理由">
      <p>
        このフォームには <code>required</code> も <code>maxlength</code> も付けていません。
        付けていたとしても、次のようにブラウザを使わずに送れば素通りします。
      </p>
      <pre class="code-snippet mb-0"><code class="language-plaintext">curl -X POST "${fn:escapeXml(pageContext.request.scheme)}://${fn:escapeXml(pageContext.request.serverName)}:${pageContext.request.serverPort}${fn:escapeXml(formUrl)}" \
     -d "name=&amp;email=xxx&amp;age=999&amp;password=1&amp;passwordConfirm=2"</code></pre>
      <p class="text-muted small mt-3 mb-0">
        この POST に対しても、サーバ側は同じようにエラーを返します。
        画面側のチェックは「早く気づいてもらうための親切」であって、
        <strong>データを守っているのはサーバ側のチェックだけ</strong>です。
      </p>
    </t:panel>

    <t:resultModal message="${flash}" />
  </jsp:body>
</t:sample>
