<%--
  【サンプル】エラー処理とエラーページ

  ErrorHandlingServlet が次の値をセットします。
    stock          … 出庫できる在庫数
    inputQuantity  … 入力された数量 (POST のとき)
    formError      … 画面に出す業務エラー / 入力エラーのメッセージ
    formErrorCode  … 業務エラーのコード (E-1001 など)
    flash          … 出庫完了メッセージ (リダイレクト後の 1 回だけ)

  「どのエラーを、どこで受け止めるか」を実際に起こして確かめるサンプルです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/advanced/error-handling" />
<c:set var="apiUrl" value="${ctx}/samples/advanced/error-handling/api" />
<t:sample sampleId="error-handling">

  <jsp:attribute name="explanation">
    <h2>エラーは 3 つに分けて考える</h2>
    <p>
      「エラー処理」と一口に言っても、やるべきことは中身によって正反対です。
      まず次の 3 つに分けると、どこで受け止めるべきかが自然に決まります。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr>
            <th>種類</th>
            <th>例</th>
            <th>受け止める場所</th>
            <th>画面に出すもの</th>
            <th>ログ</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>入力の誤り</strong></td>
            <td>未入力、数字でない、桁数オーバー</td>
            <td><strong>例外にしない</strong>。その場で判定して画面に戻す</td>
            <td>どの項目をどう直せばよいか</td>
            <td>不要</td>
          </tr>
          <tr>
            <td><strong>業務上の都合</strong></td>
            <td>在庫不足、締め切り超過、二重申請</td>
            <td>業務例外を投げ、<strong>画面を返せる場所</strong>で受け止める</td>
            <td>何が起きて、次に何をすればよいか</td>
            <td>WARN 相当（コードとキーだけ）</td>
          </tr>
          <tr>
            <td><strong>システムの異常</strong></td>
            <td>DB に繋がらない、NullPointerException</td>
            <td><strong>受け止めない</strong>。エラーページに任せる</td>
            <td>「エラーが発生しました」だけ</td>
            <td>ERROR。スタックトレースを必ず残す</td>
          </tr>
        </tbody>
      </table>
    </div>

    <p>
      迷いやすいのは 3 つめです。<strong>その場で直せない例外を受け止めてはいけません。</strong>
      握りつぶすと、画面は一見成功したように見えるのにデータは中途半端なまま進み、
      あとから原因も追えなくなります。
    </p>
<pre><code class="language-java">// 【悪い例】 何も直せないのに受け止めている
try {
    orderDao.insert(order);
} catch (Exception e) {
    // 何もしない → 登録できていないのに「登録しました」と表示されてしまう
}

// 【悪い例】 画面に出してしまう
} catch (SQLException e) {
    request.setAttribute("message", e.getMessage());   // DB のホスト名やテーブル名が漏れる
}

// 【良い例】 直せないものは投げたまま通す。ログはコンテナかフィルタに任せる
orderDao.insert(order);</code></pre>

    <h2>エラーページは web.xml で決める</h2>
    <p>
      受け止められなかった例外と <code>response.sendError(...)</code> は、
      コンテナが <code>web.xml</code> の <code>&lt;error-page&gt;</code> を見て、
      対応する JSP へ<strong>転送</strong>します。リダイレクトではないので、
      ブラウザのアドレス欄は元の URL のままです。
    </p>
<pre><code class="language-xml">&lt;error-page&gt;                        &lt;!-- ステータスコードで割り当てる --&gt;
  &lt;error-code&gt;404&lt;/error-code&gt;
  &lt;location&gt;/WEB-INF/views/error/404.jsp&lt;/location&gt;
&lt;/error-page&gt;

&lt;error-page&gt;                        &lt;!-- 例外の型で割り当てる --&gt;
  &lt;exception-type&gt;com.example.servletsample.samples.advanced.ApplicationException&lt;/exception-type&gt;
  &lt;location&gt;/WEB-INF/views/error/application-error.jsp&lt;/location&gt;
&lt;/error-page&gt;

&lt;error-page&gt;                        &lt;!-- 最後の受け皿 --&gt;
  &lt;exception-type&gt;java.lang.Throwable&lt;/exception-type&gt;
  &lt;location&gt;/WEB-INF/views/error/500.jsp&lt;/location&gt;
&lt;/error-page&gt;</code></pre>
    <ul>
      <li>例外の型は<strong>継承関係でもっとも近いもの</strong>が選ばれます（上の例では業務例外が優先）</li>
      <li><code>&lt;error-page&gt;</code> を 1 つも書かないと、コンテナ既定の画面が出ます。
          設定によってはスタックトレースがそのまま表示されるので、必ず用意します</li>
      <li>エラーページの JSP も <code>/WEB-INF/</code> の下に置きます。
          ブラウザから直接開けると、エラーでもないのにエラー画面が出せてしまいます</li>
    </ul>

    <h2>コンテナが渡してくれる情報</h2>
    <p>
      エラーページへ転送されるとき、コンテナはリクエストスコープに次の属性を入れてくれます。
      このサイトでは <code>WEB-INF/tags/errorDetail.tag</code> にまとめて、
      どのエラーページからも同じ形で表示できるようにしています。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>属性名</th><th>入っているもの</th></tr>
        </thead>
        <tbody>
          <tr><td><code>javax.servlet.error.status_code</code></td><td>HTTP のステータスコード</td></tr>
          <tr><td><code>javax.servlet.error.message</code></td>
              <td><code>sendError</code> の第 2 引数、または例外のメッセージ</td></tr>
          <tr><td><code>javax.servlet.error.exception_type</code></td><td>例外の型（<code>Class</code>）</td></tr>
          <tr><td><code>javax.servlet.error.exception</code></td><td>例外そのもの（<code>Throwable</code>）</td></tr>
          <tr><td><code>javax.servlet.error.request_uri</code></td>
              <td><strong>エラーが起きた URL</strong>（エラーページ自身の URL ではありません）</td></tr>
          <tr><td><code>javax.servlet.error.servlet_name</code></td><td>エラーが起きた Servlet の名前</td></tr>
        </tbody>
      </table>
    </div>

    <p>
      <code>javax.*</code> という名前のとおり Servlet 4.0（Tomcat 9）での名前です。
      Tomcat 10 以降（Jakarta EE 9）では <code>jakarta.servlet.error.*</code> に変わります。
    </p>

    <h2>ページ単位で指定する errorPage 属性</h2>
    <p>
      JSP には、その 1 ページだけのエラーページを指定する書き方もあります。
      アプリ全体の設定（<code>web.xml</code>）より、こちらが優先されます。
    </p>
<pre><code class="language-xml">&lt;%-- 例外を起こす側 --%&gt;
&lt;%@ page errorPage="/WEB-INF/views/samples/advanced/error-handling-jsp-error.jsp" %&gt;

&lt;%-- 受け止める側。暗黙オブジェクト exception が使えるようになる --%&gt;
&lt;%@ page isErrorPage="true" %&gt;
${'${pageContext.exception.message}'}</code></pre>
    <p>
      ひとつ落とし穴があります。<code>errorPage</code> 属性で呼ばれた場合、
      <strong>ステータスコードは 200 のまま</strong>です。
      「画面にはエラーと書いてあるのに、機械には成功と伝わる」状態になるので、
      受け止める側で <code>response.setStatus(500)</code> と書いておきます。
    </p>

    <h2>画面が真っ白になる / エラー画面が継ぎ足される</h2>
    <p>
      エラーページへの差し替えは、<strong>まだブラウザへ送信していない</strong>場合にしかできません。
      JSP は出力をいったんバッファに溜めますが、あふれると送信が始まってしまい、
      そのあとに例外が起きても書きかけの HTML を取り消せなくなります。
      結果として「書きかけの画面の後ろにエラーページが継ぎ足される」
      「画面が途中で切れて真っ白に見える」ことになります。
    </p>
<pre><code class="language-xml">&lt;!-- web.xml : JSP のバッファを既定の 8kb から広げておく --&gt;
&lt;jsp-config&gt;
  &lt;jsp-property-group&gt;
    &lt;url-pattern&gt;*.jsp&lt;/url-pattern&gt;
    &lt;buffer&gt;64kb&lt;/buffer&gt;
  &lt;/jsp-property-group&gt;
&lt;/jsp-config&gt;</code></pre>
    <p>
      根本的には<strong>画面を組み立て始める前に処理を終わらせておく</strong>ことです。
      DB アクセスや計算は Servlet 側で済ませ、JSP は受け取った値を並べるだけにします。
    </p>

    <h2>非同期通信（Ajax）の呼び先では例外を外へ出さない</h2>
    <p>
      JSON を返す API で例外をそのまま投げると、コンテナは
      <code>&lt;error-page&gt;</code> にしたがって <strong>HTML のエラーページ</strong>を返します。
      <code>response.json()</code> を待っていた画面側は
      「Unexpected token &lt;」のような、原因と関係のない例外で止まります。
      API の入口で受け止めて、形の決まった JSON に変換してください。
    </p>
<pre><code class="language-java">try {
    ...
} catch (ApplicationException e) {          // 業務エラー : メッセージをそのまま返してよい
    response.setStatus(400);
    Json.write(response, Json.object().put("ok", false).put("message", e.getMessage()));
} catch (RuntimeException e) {              // システムエラー : 中身は返さずログへ
    getServletContext().log("API でエラーが発生しました", e);
    response.setStatus(500);
    Json.write(response, Json.object().put("ok", false)
            .put("message", "処理中に問題が発生しました。"));
}</code></pre>

    <h2>ログに何を残すか</h2>
    <p>
      画面に出せない情報こそ、ログに残す価値があります。
      このサンプル集では、ライブラリを増やさずに済む
      <code>getServletContext().log(...)</code> を使っています
      （Tomcat では <code>logs/localhost.*.log</code> に出ます。
      Docker で動かしているときは <code>docker compose logs -f tomcat</code> で見られます）。
    </p>
    <ul>
      <li>実務では SLF4J + Logback などのログライブラリを使い、レベル（ERROR / WARN / INFO）を分けます</li>
      <li><strong>例外は必ず引数で渡します</strong>。
          <code>log("失敗: " + e.getMessage())</code> ではスタックトレースが残りません</li>
      <li>同じ例外を何度もログに出さないこと。
          受け止めて投げ直すたびにログを書くと、1 件の障害が何重にも記録されて読めなくなります</li>
      <li>パスワード・カード番号・個人情報はログにも書かないこと</li>
    </ul>

    <h2>本番環境ではどこまで見せるか</h2>
    <p>
      このサンプル集は「何が起きたか」を学ぶ場なので、
      エラーページに例外の型とメッセージまで表示しています。
      実際のアプリでは、利用者に見せるのは<strong>問い合わせ番号程度</strong>にとどめ、
      例外の内容はサーバのログにだけ残すのが一般的です。
      例外のメッセージには、テーブル名・ホスト名・ファイルパスといった
      攻撃の手がかりが含まれていることがあります。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // ⑥ のデモ : 呼び先が JSON を返すか、HTML のエラーページを返すかを見比べる
      (function () {
        'use strict';
        var panel = document.getElementById('apiDemo');
        if (!panel) {
          return;
        }
        var apiUrl = panel.dataset.apiUrl;
        var output = document.getElementById('apiDemoOutput');

        function show(lines) {
          output.textContent = lines.join('\n');
        }

        Array.prototype.forEach.call(panel.querySelectorAll('[data-api-mode]'), function (button) {
          button.addEventListener('click', function () {
            var mode = button.dataset.apiMode;
            show(['通信中...']);

            fetch(apiUrl + '?mode=' + encodeURIComponent(mode), {
              headers: { 'Accept': 'application/json' }
            }).then(function (res) {
              var contentType = res.headers.get('Content-Type') || '(なし)';
              // 本文を「まず文字列で」受け取るのが安全。いきなり res.json() を呼ぶと、
              // HTML が返ってきたときに中身を確かめられないまま例外になる
              return res.text().then(function (body) {
                var lines = [
                  'ステータス      : ' + res.status + ' ' + res.statusText,
                  'Content-Type : ' + contentType,
                  ''
                ];
                try {
                  var json = JSON.parse(body);
                  lines.push('JSON として読めました:');
                  lines.push(JSON.stringify(json, null, 2));
                  lines.push('');
                  lines.push(json.ok ? '→ 画面には成功の表示を出します。'
                                     : '→ 画面には message をそのまま出せます。');
                } catch (e) {
                  lines.push('JSON として読めませんでした: ' + e.message);
                  lines.push('');
                  lines.push('返ってきた本文の先頭:');
                  lines.push(body.slice(0, 300));
                  lines.push('');
                  lines.push('→ HTML のエラーページが返っています。');
                  lines.push('   画面側は「何が起きたか」を利用者に伝えられません。');
                }
                show(lines);
              });
            }).catch(function (e) {
              // 通信そのものが失敗した場合 (サーバが落ちている、圏外など)
              show(['通信できませんでした: ' + e.message]);
            });
          });
        });
      })();
    </script>
  </jsp:attribute>

  <jsp:body>

    <%-- 出庫が成功したときの完了モーダル (リダイレクト後の 1 回だけ出る) --%>
    <t:resultModal message="${flash}" />

    <t:panel title="① 想定内のエラーは、その場で受け止める"
             note="入力の誤りと在庫不足。どちらもエラーページへは飛ばしません">
      <p>
        在庫は <strong>${stock} 個</strong>です。
        数量を空にする・文字を入れる・${stock} より大きい数を入れる、で動きを確かめてください。
        どの場合も<strong>同じ画面に戻ってメッセージが出る</strong>だけで、エラーページにはなりません。
      </p>

      <c:if test="${not empty formError}">
        <div class="alert alert-warning" role="alert">
          <c:if test="${not empty formErrorCode}">
            <span class="badge badge-warning mr-1">${fn:escapeXml(formErrorCode)}</span>
          </c:if>
          ${fn:escapeXml(formError)}
        </div>
      </c:if>

      <form action="${sampleUrl}" method="post" class="form-inline" novalidate>
        <label class="mr-2" for="quantity">出庫数量</label>
        <input type="text" class="form-control mr-2 ${not empty formError ? 'is-invalid' : ''}"
               id="quantity" name="quantity" size="8"
               value="${fn:escapeXml(inputQuantity)}" placeholder="例: 3">
        <button type="submit" class="btn btn-primary">出庫する</button>
      </form>

      <hr>
      <p class="mb-0 text-muted small">
        入力の誤り（数字でない）は <code>ErrorHandlingServlet#toQuantity</code> が受け止め、
        在庫不足は <code>ApplicationException</code> を投げて
        <code>doPost</code> が受け止めています。
        「判定する場所」と「画面を返す場所」を分けられるのが、例外で知らせる利点です。
      </p>
    </t:panel>

    <t:panel title="② 想定外のエラーは、エラーページに任せる"
             note="受け止めずに投げると web.xml の設定が選ばれます">
      <p>
        ここから先はリンクを押すと<strong>エラーページに移動</strong>します。
        戻るときはブラウザの戻るボタン、またはエラーページのリンクを使ってください。
      </p>
      <div class="list-group">
        <a class="list-group-item list-group-item-action" href="${sampleUrl}?raise=runtime">
          <strong>実行時例外を投げる</strong>
          <span class="badge badge-danger ml-2">500</span>
          <small class="d-block text-muted">
            <code>throw new IllegalStateException(...)</code> →
            <code>&lt;exception-type&gt;java.lang.Throwable&lt;/exception-type&gt;</code> の設定が選ばれます
          </small>
        </a>
        <a class="list-group-item list-group-item-action" href="${sampleUrl}?raise=npe">
          <strong>NullPointerException を起こす</strong>
          <span class="badge badge-danger ml-2">500</span>
          <small class="d-block text-muted">
            「無ければ null を返す」メソッドの戻り値を確かめずに使った場合。
            Java 17 では、どの変数が null だったかまでメッセージに出ます
          </small>
        </a>
        <a class="list-group-item list-group-item-action" href="${sampleUrl}?raise=cause">
          <strong>原因つきの例外を投げる</strong>
          <span class="badge badge-danger ml-2">500</span>
          <small class="d-block text-muted">
            下位で起きた例外を <code>cause</code> として包んで投げ直した場合。
            エラーページで元の例外までたどれます
          </small>
        </a>
      </div>
    </t:panel>

    <t:panel title="③ 例外ではなく、HTTP のステータスで返す"
             note="response.sendError(...) と、URL が存在しない場合">
      <div class="list-group">
        <a class="list-group-item list-group-item-action" href="${sampleUrl}?raise=status-400">
          <strong><code>sendError(400, "...")</code></strong>
          <span class="badge badge-warning ml-2">400</span>
          <small class="d-block text-muted">
            送られてきた内容がそもそもおかしいとき。第 2 引数は
            <code>javax.servlet.error.message</code> に入ります
          </small>
        </a>
        <a class="list-group-item list-group-item-action" href="${sampleUrl}?raise=status-403">
          <strong><code>sendError(403, "...")</code></strong>
          <span class="badge badge-warning ml-2">403</span>
          <small class="d-block text-muted">
            ログインはしているが権限が足りないとき
          </small>
        </a>
        <a class="list-group-item list-group-item-action" href="${ctx}/samples/advanced/error-handling/nowhere">
          <strong>存在しない URL を開く</strong>
          <span class="badge badge-secondary ml-2">404</span>
          <small class="d-block text-muted">
            リンク切れや打ち間違い。<code>&lt;error-code&gt;404&lt;/error-code&gt;</code> の設定が選ばれます
          </small>
        </a>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        <code>sendError</code> を呼んだあとに画面へ書き込んではいけません。
        すでにエラーページへ差し替わっているため、
        <code>IllegalStateException</code> になるか、出力が混ざります。
        呼んだら必ず <code>return</code> します。
      </p>
    </t:panel>

    <t:panel title="④ 業務例外だけ、専用のエラーページへ"
             note="例外の型ごとにエラーページを割り当てる">
      <p>
        「受付時間を過ぎています」のように<strong>利用者が対処できる</strong>エラーは、
        システムエラーと同じ画面に出すべきではありません。
        <code>web.xml</code> で例外の型ごとに割り当てると、画面を分けられます。
      </p>
      <a class="btn btn-outline-primary" href="${sampleUrl}?raise=business">
        業務例外を投げる（<code>ApplicationException</code>）
      </a>
      <hr>
      <p class="mb-0 text-muted small">
        <code>ApplicationException</code> は <code>RuntimeException</code> を継承していますが、
        コンテナは継承関係で<strong>もっとも近い型</strong>の設定を選ぶため、
        <code>java.lang.Throwable</code> の設定（500 のページ）より優先されます。
      </p>
    </t:panel>

    <t:panel title="⑤ JSP を組み立てている途中で起きた例外"
             note="page ディレクティブの errorPage 属性">
      <p>
        画面を組み立てている最中に例外が起きると、
        それまでに書いた HTML は<strong>バッファごと捨てられ</strong>、
        エラーページの HTML に差し替わります。
      </p>
      <a class="btn btn-outline-primary" href="${sampleUrl}?raise=jsp">
        JSP の中で例外を起こす
      </a>
      <hr>
      <p class="mb-0 text-muted small">
        差し替えられるのは、まだブラウザへ送信していない場合だけです。
        バッファがあふれて送信が始まっていると取り消せず、
        「書きかけの画面の後ろにエラーページが継ぎ足される」ことになります。
      </p>
    </t:panel>

    <t:panel title="⑥ 非同期通信（Ajax）の呼び先で起きた例外"
             note="HTML のエラーページが返ると、画面側は何も伝えられません">
      <div id="apiDemo" data-api-url="${apiUrl}">
        <p>
          同じ「集計に失敗した」状況を、<strong>JSON に変換して返した場合</strong>と
          <strong>例外をそのまま投げた場合</strong>で見比べます。
        </p>
        <div class="btn-group mb-3" role="group" aria-label="呼び出し方">
          <button type="button" class="btn btn-outline-secondary" data-api-mode="ok">
            成功する
          </button>
          <button type="button" class="btn btn-outline-primary" data-api-mode="json">
            JSON に変換して返す
          </button>
          <button type="button" class="btn btn-outline-danger" data-api-mode="html">
            例外をそのまま投げる
          </button>
          <button type="button" class="btn btn-outline-warning" data-api-mode="business">
            業務エラーを返す
          </button>
        </div>
        <pre class="code-snippet mb-0" id="apiDemoOutput" aria-live="polite">ボタンを押すと、返ってきた内容をここに表示します。</pre>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        画面側で <code>res.json()</code> をいきなり呼ばず、
        <code>res.text()</code> で受け取ってから解釈しているのは、
        HTML が返ってきたときに<strong>中身を確かめられるようにする</strong>ためです。
        通信そのものが失敗した場合（サーバが落ちている、圏外）は
        <code>fetch</code> の <code>catch</code> に来ます。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
