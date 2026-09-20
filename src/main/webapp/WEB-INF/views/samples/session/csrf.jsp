<%--
  【サンプル】CSRF 対策（ワンタイムトークン）

  CsrfServlet が次の値をセットします。
    csrfToken          … セッションに入っているトークン
    csrfParameterName  … 隠し項目の名前（_csrf）
    csrfHeaderName     … Ajax 用のヘッダ名（X-CSRF-Token）
    currentEmail       … いま登録されているメールアドレス（デモ用）
    csrfError          … トークンが一致しなかったときのメッセージ
    apiPath            … Ajax で呼ぶ URL
    flash              … 変更完了メッセージ
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/session/csrf" />
<t:sample sampleId="csrf">

  <jsp:attribute name="explanation">
    <h2>ブラウザは Cookie を勝手に付ける</h2>
    <p>
      これが CSRF のすべての出発点です。ブラウザは、あるサイト宛のリクエストに
      <strong>そのサイトの Cookie を自動で付けます</strong>。
      それが罠のページから送られたものであっても、です。
    </p>
<pre><code class="language-plaintext">① 利用者は業務システムにログイン済み（JSESSIONID の Cookie を持っている）
② 罠のページを開く（メールのリンク、掲示板、広告…）
③ 罠のページが、業務システム宛にフォームを自動送信する
④ ブラウザは業務システムの Cookie を付けて POST してしまう
⑤ サーバから見ると「ログイン済みの本人からの正しい依頼」に見える</code></pre>
<pre><code class="language-xml">&lt;!-- 罠のページに置かれているもの。利用者には何も見えません --&gt;
&lt;form action="https://example.com/user/email" method="post"&gt;
  &lt;input type="hidden" name="email" value="attacker@evil.example"&gt;
&lt;/form&gt;
&lt;script&gt;document.forms[0].submit();&lt;/script&gt;</code></pre>
    <p>
      <strong>利用者は何も入力していないのに、処理が実行されます。</strong>
      退会、パスワード変更、送金、権限の付与――
      「ログインしていればできること」はすべて狙われます。
    </p>

    <h2>対策は「自分のサイトが出したフォームか」を確かめること</h2>
    <p>
      推測できない値をセッションに持ち、同じ値をフォームの隠し項目にも入れておいて、
      送信時に突き合わせます（Synchronizer Token Pattern）。
    </p>
<pre><code class="language-plaintext">［画面を出すとき］
  セッション : token = xY9kf...
  フォーム   : &lt;input type="hidden" name="_csrf" value="xY9kf..."&gt;

［受け取るとき］
  送られてきた _csrf と、セッションの token が一致するか</code></pre>
    <p>
      罠のページは<strong>この値を知りようがありません</strong>。
      Cookie は自動で付いても、フォームの中身までは作れないからです
      （別のサイトから他サイトの画面の中身を読むことは、ブラウザが禁じています）。
    </p>
<pre><code class="language-java">// 入力チェックより先に確かめる。合わない時点で中身を見る必要はない
if (!CsrfToken.verify(request)) {
    getServletContext().log("CSRF トークンが一致しませんでした: " + request.getServletPath());
    response.sendError(403);
    return;
}</code></pre>

    <h2>トークンの寿命をどうするか</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th></th><th>セッションに 1 つ（このサンプル）</th><th>画面ごとに作り直す</th></tr>
        </thead>
        <tbody>
          <tr><td>安全性</td><td>十分</td><td>より高い（使い回しも防げる）</td></tr>
          <tr><td>複数タブ</td><td>問題なし</td><td><strong>古いタブで送れなくなる</strong></td></tr>
          <tr><td>戻るボタン</td><td>問題なし</td><td><strong>エラーになりやすい</strong></td></tr>
        </tbody>
      </table>
    </div>
    <p>
      一般的な業務システムでは前者で十分です。後者にすると、利用者から
      「戻ってもう一度送ったらエラーになった」という問い合わせが増えます。
      ただし<strong>ログインの前後では必ず作り直します</strong>。
      ログイン前に配ったトークンをそのまま使うと、セッション固定攻撃と同じ理屈で
      攻撃者に既知の値を使わせられます。
    </p>

    <h2>二重送信の防止とは別もの</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th></th><th>CSRF トークン</th><th>二重送信防止トークン</th></tr></thead>
        <tbody>
          <tr><td>防ぎたいこと</td><td>他サイトからの偽の依頼</td><td>同じ依頼が 2 回処理されること</td></tr>
          <tr><td>相手</td><td>攻撃者</td><td>うっかり二度押しした利用者</td></tr>
          <tr><td>使い回し</td><td>する（セッション中ずっと同じ）</td><td><strong>しない</strong>（1 回で捨てる）</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      名前も仕組みも似ていますが、目的が違うので<strong>両方必要</strong>です。
      1 つのトークンで兼ねようとすると、どちらかが中途半端になります。
    </p>

    <h2>SameSite Cookie があれば要らない？</h2>
    <p>
      最近のブラウザは Cookie の <code>SameSite</code> 属性の既定値を <code>Lax</code> にしており、
      <strong>別サイトからの POST には Cookie を付けません</strong>。
      これだけでも多くの CSRF は防げます。ただし、
    </p>
    <ul>
      <li>古いブラウザには効かない</li>
      <li>同じサイトの中に投稿できる箇所があると回避されうる</li>
      <li>ブラウザ任せの対策であって、サーバ側の保証ではない</li>
    </ul>
    <p>
      という理由から、<strong>トークンによる対策は今も必要</strong>です。両方やります。
    </p>

    <h2>ほかに守ること</h2>
    <ul>
      <li>
        <strong>GET で状態を変えない</strong> …
        トークンを URL に付けると、履歴・アクセスログ・<code>Referer</code> に残ります。
        更新処理は必ず POST で受けます
      </li>
      <li>
        <strong>トークンを Cookie だけに置かない</strong> …
        Cookie は自動で付くので、Cookie 同士を比べても意味がありません
        （二重送信 Cookie 方式にする場合は、必ず本文やヘッダの値と比べます）
      </li>
      <li>
        <strong><code>Referer</code> の確認だけで済ませない</strong> …
        送られてこないことがあります。補助として使うのは構いません
      </li>
      <li>
        <strong>セッションが切れていたら素通しにしない</strong> …
        「トークンが無い＝チェックしない」と書いてしまうと、対策の意味がなくなります
      </li>
    </ul>

    <h2>実務ではフィルタに置く</h2>
    <p>
      このサンプルは分かりやすさのため Servlet の中で確かめていますが、
      本来は<strong>更新系のリクエストすべてに掛かるフィルタ</strong>に置きます。
      画面ごとに書くと、ログインの確認と同じで必ず書き漏れます。
    </p>
<pre><code class="language-java">String method = request.getMethod();
boolean readOnly = "GET".equals(method) || "HEAD".equals(method) || "OPTIONS".equals(method);
if (!readOnly &amp;&amp; !CsrfToken.verify(request)) {
    response.sendError(403);
    return;                       // chain.doFilter を呼ばない
}
chain.doFilter(request, response);</code></pre>
    <p>
      このサイトでは、他のサンプルの POST まで弾いてしまわないよう、フィルタにはしていません。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // Ajax でトークンを送る / 送らないを比べる
      (function () {
        'use strict';
        var panel = document.getElementById('csrfApiDemo');
        if (!panel) {
          return;
        }
        var apiPath = panel.dataset.apiPath;
        var headerName = panel.dataset.headerName;
        var token = panel.dataset.token;
        var output = document.getElementById('csrfApiOutput');

        Array.prototype.forEach.call(panel.querySelectorAll('[data-send]'), function (button) {
          button.addEventListener('click', function () {
            var withToken = button.dataset.send === 'with-token';
            output.textContent = '送信中...';

            var headers = { 'Accept': 'application/json' };
            if (withToken) {
              // フォームの隠し項目の代わりに、ヘッダで送る
              headers[headerName] = token;
            }

            var body = new URLSearchParams();
            body.set('email', 'ajax@example.com');

            fetch(apiPath, { method: 'POST', headers: headers, body: body })
              .then(function (res) {
                return res.json().then(function (json) {
                  output.textContent = [
                    'ステータス : ' + res.status + ' ' + res.statusText,
                    '',
                    JSON.stringify(json, null, 2),
                    '',
                    res.ok ? '→ トークンが一致したので受け付けられました。'
                           : '→ トークンが無い／違うので中止されました。'
                  ].join('\n');
                });
              })
              .catch(function (e) {
                output.textContent = '通信できませんでした: ' + e.message;
              });
          });
        });
      })();
    </script>
  </jsp:attribute>

  <jsp:body>

    <t:resultModal message="${flash}" />

    <c:if test="${not empty csrfError}">
      <div class="alert alert-danger" role="alert">
        <strong>処理を中止しました。</strong>
        ${fn:escapeXml(csrfError)}
      </div>
    </c:if>

    <t:panel title="① いまの状態" note="題材は「メールアドレスの変更」です">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0 doc-table">
          <tbody>
            <tr>
              <th scope="row">登録されているメールアドレス</th>
              <td><code>${fn:escapeXml(currentEmail)}</code></td>
            </tr>
            <tr>
              <th scope="row">セッションのトークン</th>
              <td><code class="small">${fn:escapeXml(csrfToken)}</code></td>
            </tr>
            <tr>
              <th scope="row">隠し項目の名前</th>
              <td><code>${fn:escapeXml(csrfParameterName)}</code></td>
            </tr>
            <tr>
              <th scope="row">Ajax 用のヘッダ名</th>
              <td><code>${fn:escapeXml(csrfHeaderName)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        このトークンはセッションに 1 つです。画面を再読み込みしても変わりません。
        ログアウトして入り直すと、新しい値になります。
      </p>
    </t:panel>

    <t:panel title="② 正しいトークンを付けて送る" note="自分のサイトが出したフォーム">
      <form action="${formUrl}" method="post" class="form-inline">
        <%-- ここが対策の本体。値はセッションのものと同じ --%>
        <input type="hidden" name="${fn:escapeXml(csrfParameterName)}"
               value="${fn:escapeXml(csrfToken)}">

        <label class="mr-2" for="email1">新しいメールアドレス</label>
        <input type="text" class="form-control mr-2" id="email1" name="email" size="28"
               value="hanako@example.com">
        <button type="submit" class="btn btn-primary">変更する</button>
      </form>
      <hr>
      <p class="mb-0 text-muted small">
        受け付けられ、完了モーダルが出ます（PRG でリダイレクトしています）。
      </p>
    </t:panel>

    <t:panel title="③ トークンを付けずに送る" note="罠のページから送られてきた形">
      <form action="${formUrl}" method="post" class="form-inline">
        <%-- 隠し項目をあえて入れていません --%>
        <label class="mr-2" for="email2">新しいメールアドレス</label>
        <input type="text" class="form-control mr-2" id="email2" name="email" size="28"
               value="attacker@evil.example">
        <button type="submit" class="btn btn-outline-danger">変更する（弾かれます）</button>
      </form>
      <hr>
      <p class="mb-0 text-muted small">
        <code>403</code> で中止され、メールアドレスは変わりません。
        罠のページから送られてくるのは、ちょうどこの形です。
      </p>
    </t:panel>

    <t:panel title="④ でたらめなトークンを付けて送る" note="値を推測して当てられるか">
      <form action="${formUrl}" method="post" class="form-inline">
        <input type="hidden" name="${fn:escapeXml(csrfParameterName)}" value="guessed-token-1234">

        <label class="mr-2" for="email3">新しいメールアドレス</label>
        <input type="text" class="form-control mr-2" id="email3" name="email" size="28"
               value="attacker@evil.example">
        <button type="submit" class="btn btn-outline-danger">変更する（弾かれます）</button>
      </form>
      <hr>
      <p class="mb-0 text-muted small">
        トークンは <code>SecureRandom</code> で作った 32 バイトの値です。
        当てずっぽうで一致させることは、現実的にはできません。
        比較も <code>MessageDigest.isEqual</code> で行い、
        「何文字目まで合っていたか」が応答時間から漏れないようにしています。
      </p>
    </t:panel>

    <t:panel title="⑤ Ajax から送る" note="隠し項目の代わりにヘッダで送ります">
      <div id="csrfApiDemo"
           data-api-path="${fn:escapeXml(apiPath)}"
           data-header-name="${fn:escapeXml(csrfHeaderName)}"
           data-token="${fn:escapeXml(csrfToken)}">
        <p>
          フォームではないので隠し項目が使えません。
          代わりに <code>${fn:escapeXml(csrfHeaderName)}</code> ヘッダに入れて送ります。
        </p>
        <div class="btn-group mb-3" role="group" aria-label="送り方">
          <button type="button" class="btn btn-outline-primary" data-send="with-token">
            ヘッダにトークンを付けて送る
          </button>
          <button type="button" class="btn btn-outline-danger" data-send="without-token">
            付けずに送る
          </button>
        </div>
        <pre class="code-snippet mb-0" id="csrfApiOutput" aria-live="polite">ボタンを押すと、返ってきた内容をここに表示します。</pre>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        トークンを画面に埋め込んでおき、JavaScript がそこから読んで付けるのが定石です
        （<code>&lt;meta name="csrf-token" content="..."&gt;</code> に置く作りもよく見ます）。
        なお、この URL を GET で開くと <code>405</code> が返ります。
        状態を変える処理を GET で受けないためです。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
