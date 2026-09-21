<%--
  【サンプル】フィルタで未ログインを弾く

  AuthFilterServlet が次の値をセットします。
    memberPath / adminPath / apiPath / loginPath … 保護された URL とログイン画面の URL

  この説明ページ自体は誰でも開けます。保護されているのは下の 3 つの URL です。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="auth-filter">

  <jsp:attribute name="explanation">
    <h2>確認を「画面ごと」に書くと必ず漏れる</h2>
    <p>
      ログインしているかどうかの確認は、たった 3 行です。
      ですが、これを画面の数だけ書くと<strong>いつか 1 か所で書き忘れます</strong>。
      そして 1 か所漏れれば、そこから中に入れてしまいます。
    </p>
<pre><code class="language-java">// これを 50 画面に書き、49 画面にしか書かなかった日に事故が起きる
HttpSession session = request.getSession(false);
if (session == null || session.getAttribute("loginUser") == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
}</code></pre>
    <p>
      フィルタなら <strong>URL で一括して</strong>掛けられます。
      新しい画面を足しても、URL が保護対象に入っていれば自動的に守られます。
    </p>

    <h2>認証と認可は別もの</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th></th><th>認証（Authentication）</th><th>認可（Authorization）</th></tr>
        </thead>
        <tbody>
          <tr><td>問い</td><td>あなたは<strong>誰</strong>ですか</td>
              <td>あなたに<strong>それを許してよい</strong>ですか</td></tr>
          <tr><td>通らないとき</td><td><code>401</code> Unauthorized</td>
              <td><code>403</code> Forbidden</td></tr>
          <tr><td>利用者の対処</td><td>ログインすれば通る</td><td>ログインし直しても通らない</td></tr>
          <tr><td>このサンプル</td><td><code>AuthenticationFilter</code></td>
              <td><code>AuthorizationFilter</code></td></tr>
        </tbody>
      </table>
    </div>
    <p>
      名前に反して <code>401 Unauthorized</code> は「<strong>認証</strong>されていない」という意味です。
      ログイン済みで権限が足りないときは <code>403</code> を返します。
      ここを取り違えると、利用者は「ログインし直せば直るのか」が分からなくなります。
    </p>
    <p>
      2 つのフィルタの順番は <code>web.xml</code> の
      <code>&lt;filter-mapping&gt;</code> を書いた順で決まります。
      逆にすると「ログインしていない人に 403 を返す」ことになってしまいます。
    </p>

    <h2>画面と API で返し方を変える</h2>
    <p>
      <strong>Ajax の呼び先でリダイレクトを返してはいけません。</strong>
      <code>fetch</code> はリダイレクトを自動で追いかけるので、
      画面側は<strong>ログイン画面の HTML を JSON として受け取ろうとして</strong>壊れます。
      「なぜか JSON が壊れる」の原因がセッション切れだった、というのはよくある話です。
    </p>
<pre><code class="language-plaintext">［画面］ 未ログイン → 302 でログイン画面へ（戻り先を ?next= で覚えておく）
［API ］ 未ログイン → 401 + {"ok":false,"loginUrl":"..."}</code></pre>
<pre><code class="language-javascript">const res = await fetch(apiUrl, { headers: { Accept: 'application/json' } });
if (res.status === 401) {
  const body = await res.json();
  location.href = body.loginUrl;   // セッションが切れている
  return;
}</code></pre>
    <p>
      長く開きっぱなしにされる画面ほど、この分岐が効きます。
      入れていないと、セッションが切れた瞬間に「ボタンを押しても何も起きない」画面になります。
    </p>

    <h2>ログイン後に元の画面へ戻す</h2>
    <p>
      弾くときに「どこへ行こうとしていたか」を覚えておき、ログイン後にそこへ送り返します。
    </p>
<pre><code class="language-java">String next = request.getRequestURI().substring(request.getContextPath().length());
response.sendRedirect(request.getContextPath() + "/login?next="
        + URLEncoder.encode(next, StandardCharsets.UTF_8));</code></pre>
    <p>
      ここで大事なのは、<strong>受け取った側でも必ず形を確かめる</strong>ことです。
      <code>?next=https://example.com/</code> のような値をそのままリダイレクト先にすると、
      自サイトのログイン画面を踏み台に外部サイトへ飛ばせてしまいます
      （<strong>オープンリダイレクト</strong>。フィッシングの入口になります）。
    </p>
<pre><code class="language-java">// 通してよい形を決めて、外れたら既定の画面へ倒す
if (!value.startsWith("/samples/session/")) return "";
if (value.startsWith("//") || value.contains(":")) return "";   // "//example.com" は別サイト</code></pre>

    <h2>画面で隠すだけでは守れない</h2>
    <p>
      「管理者以外にはボタンを出さない」は<strong>親切心であって、対策ではありません</strong>。
      URL を直接打たれたら素通りです。守りは 3 つの層で重ねます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>層</th><th>やること</th><th>注意</th></tr></thead>
        <tbody>
          <tr><td>画面（JSP）</td><td>使えないボタンを隠す</td>
              <td><strong>これだけで守ったつもりにならない</strong></td></tr>
          <tr><td>フィルタ</td><td>URL 単位でまとめて弾く</td>
              <td>細かい判定には向かない</td></tr>
          <tr><td>業務の処理</td><td>「その注文は自分のものか」を確かめる</td>
              <td><strong>忘れがち。</strong><code>?orderId=1234</code> を書き換えられていないか</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      3 番目を忘れると、ログインさえすれば他人のデータを開けてしまう画面ができます
      （アクセス制御の不備）。URL が通ってよいことと、そのデータを見てよいことは別の話です。
    </p>

    <h2>url-pattern の落とし穴</h2>
    <p>
      <code>/samples/session/auth-filter/*</code> と書くと、
      <strong>末尾の <code>/*</code> が無い <code>/samples/session/auth-filter</code> 自身にも掛かります</strong>。
      前方一致のマッピングは、その前置き部分そのものにも一致するためです。
      このサンプルでは説明ページを誰でも開けるようにしたいので、
      保護したい URL を 1 つずつ列挙しています。
    </p>
<pre><code class="language-xml">&lt;filter-mapping&gt;
  &lt;filter-name&gt;authenticationFilter&lt;/filter-name&gt;
  &lt;url-pattern&gt;/samples/session/auth-filter/member&lt;/url-pattern&gt;
  &lt;url-pattern&gt;/samples/session/auth-filter/admin&lt;/url-pattern&gt;
  &lt;url-pattern&gt;/samples/session/auth-filter/api&lt;/url-pattern&gt;
&lt;/filter-mapping&gt;

&lt;filter-mapping&gt;
  &lt;filter-name&gt;authorizationFilter&lt;/filter-name&gt;
  &lt;url-pattern&gt;/samples/session/auth-filter/admin&lt;/url-pattern&gt;
&lt;/filter-mapping&gt;</code></pre>
    <p>
      サイト全体に掛けるときは <code>/*</code> にしたうえで、
      ログイン画面・静的ファイル・エラーページを<strong>除外</strong>する形になります。
      除外の書き忘れで「ログイン画面がログインを要求する」無限ループになりやすいところです。
    </p>

    <h2>コンテナの認証機能を使う手もある</h2>
    <p>
      Servlet の仕様には、<code>web.xml</code> に書くだけで使える認証の仕組みもあります
      （<code>&lt;security-constraint&gt;</code> と <code>&lt;login-config&gt;</code>）。
      設定だけで済む反面、利用者マスタをコンテナ側に持たせる必要があり、
      画面の作りも合わせにくいため、業務システムでは
      <strong>このサンプルのように自前のフィルタで書くほうが一般的</strong>です。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // 保護された API を呼んで、ログイン状態による応答の違いを見る
      (function () {
        'use strict';
        var panel = document.getElementById('authApiDemo');
        if (!panel) {
          return;
        }
        var apiPath = panel.dataset.apiPath;
        var output = document.getElementById('authApiOutput');

        panel.querySelector('[data-call-api]').addEventListener('click', function () {
          output.textContent = '通信中...';

          fetch(apiPath, { headers: { 'Accept': 'application/json' } })
            .then(function (res) {
              return res.text().then(function (body) {
                var lines = ['ステータス : ' + res.status + ' ' + res.statusText, ''];
                try {
                  var json = JSON.parse(body);
                  lines.push(JSON.stringify(json, null, 2));
                  lines.push('');
                  if (res.status === 401) {
                    lines.push('→ 未ログインです。画面側は loginUrl へ送ればよいと分かります。');
                  } else if (res.status === 403) {
                    lines.push('→ ログイン済みですが権限が足りません。ログインし直しても通りません。');
                  } else {
                    lines.push('→ フィルタを通り抜けて API まで届いています。');
                  }
                } catch (e) {
                  lines.push('JSON として読めませんでした:');
                  lines.push(body.slice(0, 200));
                }
                output.textContent = lines.join('\n');
              });
            })
            .catch(function (e) {
              output.textContent = '通信できませんでした: ' + e.message;
            });
        });
      })();
    </script>
  </jsp:attribute>

  <jsp:body>

    <t:panel title="① いまのログイン状態" note="この説明ページ自体は誰でも開けます">
      <c:choose>
        <c:when test="${empty loginUser}">
          <div class="alert alert-warning" role="alert">
            <strong>ログインしていません。</strong>
            この状態で下のリンクを開くと、ログイン画面へ送られます。
          </div>
          <a class="btn btn-primary" href="${loginPath}">ログイン画面へ</a>
        </c:when>
        <c:otherwise>
          <p>
            <strong>${fn:escapeXml(loginUser.name)}</strong> さんとしてログイン中です。
            <span class="badge badge-${loginUser.role.variant}">
              ${fn:escapeXml(loginUser.role.label)}
            </span>
          </p>
          <c:if test="${not loginUser.admin}">
            <p class="mb-0 text-muted small">
              管理者ページも試すには、<a href="${loginPath}">ログイン画面</a>で
              いったんログアウトし、<code>admin</code> でログインし直してください。
            </p>
          </c:if>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <t:panel title="② 保護された画面を開く" note="フィルタが通すか弾くかを決めます">
      <div class="list-group">
        <a class="list-group-item list-group-item-action" href="${memberPath}">
          <strong>会員ページ</strong>
          <span class="badge badge-success ml-2">ログインしていれば誰でも</span>
          <small class="d-block text-muted">
            未ログインなら、ログイン画面へ送られます（<code>?next=</code> に戻り先が付きます）。
            ログインすると、この画面に戻ってきます
          </small>
        </a>
        <a class="list-group-item list-group-item-action" href="${adminPath}">
          <strong>管理者ページ</strong>
          <span class="badge badge-danger ml-2">管理者だけ</span>
          <small class="d-block text-muted">
            一般の利用者でログインしていると <code>403</code> になります。
            ログインし直しても通らないので、ログイン画面へは送りません
          </small>
        </a>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        開いた先の <code>ProtectedPageServlet</code> には、
        ログインを確かめるコードが<strong>1 行もありません</strong>。
        フィルタが済ませてくれているためです。
      </p>
    </t:panel>

    <t:panel title="③ 保護された API を呼ぶ" note="Ajax にリダイレクトを返さない、の実例">
      <div id="authApiDemo" data-api-path="${fn:escapeXml(apiPath)}">
        <p>
          同じフィルタが掛かっていますが、<code>Accept: application/json</code> が付いているので、
          未ログインのときはリダイレクトではなく <strong>401 と JSON</strong> が返ります。
        </p>
        <button type="button" class="btn btn-outline-primary mb-3" data-call-api>
          API を呼ぶ
        </button>
        <pre class="code-snippet mb-0" id="authApiOutput" aria-live="polite">ボタンを押すと、返ってきた内容をここに表示します。</pre>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        ログイン前と後で押し比べてみてください。
        もしここでリダイレクトを返していたら、<code>fetch</code> はそれを追いかけて
        <strong>ログイン画面の HTML</strong> を受け取り、
        <code>res.json()</code> が「Unexpected token &lt;」で失敗します。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
