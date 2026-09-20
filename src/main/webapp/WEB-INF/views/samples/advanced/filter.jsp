<%--
  【サンプル】フィルタ (Filter) で共通処理をはさむ

  FilterServlet が次の値をセットします。
    apiPath … 記録を取り出す API の URL

  フィルタが次の値をリクエストスコープに入れます。
    filterTrace … このリクエストがここまでに通ったフィルタの記録 (FilterTrace)

  画面を組み立てているのはフィルタの「内側」なので、ここで見えるのは行きの分だけです。
  帰りの分まで含めた 1 往復は、下のデモで API から取り出して表示します。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="filter">

  <jsp:attribute name="explanation">
    <h2>フィルタは Servlet の「手前」と「奥」に置く共通処理</h2>
    <p>
      すべての画面で同じことをしたい――アクセスログを残す、ログイン済みか確かめる、
      共通のヘッダを付ける。こうした処理を Servlet ごとに書くと、
      画面が増えるたびに書き漏れが出ます。フィルタに置けば
      <strong>Servlet を 1 行も直さずに</strong>、後から足したり外したりできます。
    </p>
<pre><code class="language-java">public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
        throws IOException, ServletException {

    // ... 行きの処理（Servlet が動く前）...

    chain.doFilter(request, response);   // 次のフィルタ、最後は Servlet へ

    // ... 帰りの処理（Servlet が終わったあと）...
}</code></pre>

    <p>
      <code>chain.doFilter(...)</code> を境に、前が「行き」、後ろが「帰り」です。
      フィルタが複数あるとチェーンは<strong>入れ子</strong>になり、
      行きは上から順に、帰りは逆順に動きます。
    </p>
<pre><code class="language-plaintext">ブラウザ
  ↓
① RequestIdFilter   行き
  ↓
② AccessLogFilter   行き
  ↓
③ AccessCheckFilter 行き
  ↓
■ Servlet ＋ JSP
  ↑
③ AccessCheckFilter 帰り
  ↑
② AccessLogFilter   帰り   ← ここで初めて処理時間とステータスが分かる
  ↑
① RequestIdFilter   帰り
  ↓
ブラウザ</code></pre>

    <h2>帰りの処理は finally に書く</h2>
    <p>
      奥で例外が起きると、<code>chain.doFilter</code> の次の行は実行されません。
      アクセスログや後始末を <code>try</code> の外に書いてしまうと、
      <strong>エラーのときだけ何も残らない</strong>という、いちばん困る状態になります。
    </p>
<pre><code class="language-java">long start = System.nanoTime();
try {
    chain.doFilter(request, response);
} finally {
    long elapsed = (System.nanoTime() - start) / 1_000_000L;
    context.log(request.getMethod() + " " + uri + " " + response.getStatus() + " " + elapsed + " ms");
}</code></pre>

    <h2>止めるときは chain.doFilter を呼ばない</h2>
    <p>
      フィルタのもう 1 つの役目が門番です。<code>chain.doFilter</code> を呼ばなければ、
      その先の Servlet は動きません。
    </p>
<pre><code class="language-java">HttpSession session = request.getSession(false);
if (session == null || session.getAttribute("loginUser") == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;                                   // ← これを忘れると弾いたはずの処理が動く
}
chain.doFilter(request, response);</code></pre>
    <p>
      <strong><code>return</code> の書き忘れがいちばん危ない</strong>ところです。
      リダイレクトやエラーを返したあとに処理が続いてしまうと、
      認証を掛けたつもりが素通りになります。
    </p>

    <h2>登録の仕方 : web.xml と @WebFilter</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th></th><th><code>web.xml</code></th><th><code>@WebFilter</code></th></tr>
        </thead>
        <tbody>
          <tr><td>書く場所</td><td>設定ファイル</td><td>クラスに直接</td></tr>
          <tr><td>適用の順番</td>
              <td><strong>指定できる</strong>（<code>&lt;filter-mapping&gt;</code> を書いた順）</td>
              <td><strong>指定できない</strong>（コンテナ任せ）</td></tr>
          <tr><td>初期化パラメータ</td><td><code>&lt;init-param&gt;</code></td>
              <td><code>@WebInitParam</code></td></tr>
          <tr><td>向いている場面</td><td>順番が意味を持つとき、設定を切り替えたいとき</td>
              <td>単独で動く、順番を問わないフィルタ</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      このサンプルは 3 つのフィルタの順番を見せたいので <code>web.xml</code> に登録しています。
    </p>
<pre><code class="language-xml">&lt;filter&gt;
  &lt;filter-name&gt;accessLogFilter&lt;/filter-name&gt;
  &lt;filter-class&gt;com.example.servletsample.samples.advanced.AccessLogFilter&lt;/filter-class&gt;
  &lt;init-param&gt;
    &lt;param-name&gt;slowMillis&lt;/param-name&gt;
    &lt;param-value&gt;1000&lt;/param-value&gt;
  &lt;/init-param&gt;
&lt;/filter&gt;

&lt;filter-mapping&gt;
  &lt;filter-name&gt;accessLogFilter&lt;/filter-name&gt;
  &lt;url-pattern&gt;/samples/advanced/filter&lt;/url-pattern&gt;
  &lt;url-pattern&gt;/samples/advanced/filter/*&lt;/url-pattern&gt;
&lt;/filter-mapping&gt;</code></pre>

    <h2>いつ呼ばれるか（dispatcher）</h2>
    <p>
      <code>&lt;dispatcher&gt;</code> を書かないと、フィルタが動くのは
      <strong>ブラウザから届いたリクエスト（<code>REQUEST</code>）</strong>のときだけです。
      Servlet から JSP への <code>forward</code> では動きません。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>値</th><th>動くとき</th><th>使いどころ</th></tr></thead>
        <tbody>
          <tr><td><code>REQUEST</code></td><td>ブラウザから直接届いたとき（既定）</td>
              <td>ほとんどの場合これだけでよい</td></tr>
          <tr><td><code>FORWARD</code></td><td><code>forward</code> されたとき</td>
              <td>JSP を直接守りたいとき。付けると画面表示のたびに二重で動く点に注意</td></tr>
          <tr><td><code>INCLUDE</code></td><td><code>include</code> されたとき</td>
              <td>部品の読み込みまで記録したいとき</td></tr>
          <tr><td><code>ERROR</code></td><td>エラーページへ転送されるとき</td>
              <td>エラー画面もログに残したいとき</td></tr>
          <tr><td><code>ASYNC</code></td><td>非同期処理から戻ってきたとき</td>
              <td><code>AsyncContext</code> を使うとき</td></tr>
        </tbody>
      </table>
    </div>

    <h2>フィルタのライフサイクル</h2>
    <p>
      Servlet と同じで、<strong>インスタンスはアプリ全体で 1 つ</strong>です。
      そこへ複数のスレッドが同時に入ってきます。
    </p>
    <ul>
      <li><code>init(FilterConfig)</code> … アプリ起動時に 1 回だけ。設定値の読み込みはここで</li>
      <li><code>doFilter(...)</code> … リクエストのたびに。<strong>同時に何本も動きます</strong></li>
      <li><code>destroy()</code> … アプリ停止時に 1 回だけ。開いたものを閉じる</li>
    </ul>
    <p>
      リクエストごとに変わる値をインスタンス変数に置くと、別の利用者の値が混ざります。
      持ってよいのは、起動時に決まってその後変わらない設定値だけです。
    </p>

    <h2>やりすぎないこと</h2>
    <ul>
      <li>
        <strong>重い処理を置かない</strong> …
        フィルタは全リクエストを通ります。ここで 100 ミリ秒使うと、全ページが 100 ミリ秒遅くなります
      </li>
      <li>
        <strong>画面の内容を書き換えない</strong> …
        <code>HttpServletResponseWrapper</code> で出力を差し替えることもできますが、
        「HTML のどこで何が書き換わったか」が追えなくなります。使うのは圧縮や文字コード変換程度に
      </li>
      <li>
        <strong>掛ける範囲を絞る</strong> …
        <code>/*</code> にすると CSS や画像のリクエストまで通ります。
        ログイン判定のようにコストのある処理は、必要な URL だけに掛けます
      </li>
    </ul>

    <h2>文字コードの設定はフィルタで書かなくてよくなりました</h2>
    <p>
      昔の解説では、<code>request.setCharacterEncoding("UTF-8")</code> を呼ぶための
      フィルタを必ず作っていました。Servlet 4.0 以降は <code>web.xml</code> に
      2 行書けば済みます（このサイトもそうしています）。
    </p>
<pre><code class="language-xml">&lt;request-character-encoding&gt;UTF-8&lt;/request-character-encoding&gt;
&lt;response-character-encoding&gt;UTF-8&lt;/response-character-encoding&gt;</code></pre>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // 1 往復ぶんの記録を API から取り出して表に描く
      (function () {
        'use strict';
        var panel = document.getElementById('traceDemo');
        if (!panel) {
          return;
        }
        var apiPath = panel.dataset.apiPath;
        var status = document.getElementById('traceStatus');
        var body = document.getElementById('traceBody');
        var table = document.getElementById('traceTable');

        /** 記録が保管されるまで少し待って取りに行く（最大 5 回）。 */
        function fetchTrace(requestId, remaining) {
          return fetch(apiPath + '?trace=' + encodeURIComponent(requestId))
            .then(function (res) { return res.json(); })
            .then(function (json) {
              if (json.ok) {
                return json;
              }
              if (remaining <= 0) {
                throw new Error('記録を取り出せませんでした。');
              }
              // いちばん外側のフィルタの後処理が終わるまで、ほんのわずかに間がある
              return new Promise(function (resolve) {
                window.setTimeout(resolve, 150);
              }).then(function () {
                return fetchTrace(requestId, remaining - 1);
              });
            });
        }

        function render(trace) {
          body.innerHTML = '';
          trace.steps.forEach(function (step) {
            var row = document.createElement('tr');

            var seq = document.createElement('td');
            seq.textContent = step.seq;
            row.appendChild(seq);

            var phase = document.createElement('td');
            phase.textContent = step.mark + ' ' + step.phase;
            row.appendChild(phase);

            var name = document.createElement('td');
            // 受け取った文字列は textContent で入れる（innerHTML に入れると XSS になる）
            name.textContent = step.name;
            name.style.paddingLeft = (0.75 + step.depth * 1.5) + 'rem';
            row.appendChild(name);

            var message = document.createElement('td');
            message.textContent = step.message;
            row.appendChild(message);

            body.appendChild(row);
          });
          table.hidden = false;
          status.textContent = 'リクエスト ' + trace.id + '  ' + trace.method + ' ' + trace.uri
            + '  /  全体の処理時間 ' + trace.elapsedMillis + ' ms';
        }

        Array.prototype.forEach.call(panel.querySelectorAll('[data-trace-run]'), function (button) {
          button.addEventListener('click', function () {
            var blocked = button.dataset.traceRun === 'blocked';
            table.hidden = true;
            status.textContent = 'リクエストを送っています...';

            fetch(apiPath + (blocked ? '?blocked=1' : ''))
              .then(function (res) {
                // リクエスト ID はレスポンスヘッダから受け取る。
                // 403 で止められた場合は本文が HTML のエラーページになるため、
                // 本文ではなくヘッダから受け取るのが確実
                var requestId = res.headers.get('X-Request-Id');
                if (!requestId) {
                  throw new Error('X-Request-Id ヘッダがありません。');
                }
                status.textContent = '応答 ' + res.status + ' ' + res.statusText
                  + ' / X-Request-Id: ' + requestId + ' … 記録を取り出しています';
                return fetchTrace(requestId, 5);
              })
              .then(render)
              .catch(function (e) {
                status.textContent = 'うまくいきませんでした: ' + e.message;
              });
          });
        });
      })();
    </script>
  </jsp:attribute>

  <jsp:body>

    <t:panel title="① この画面を表示したリクエストが、ここまでに通った順番"
             note="画面を組み立てているのはフィルタの内側なので、見えるのは「行き」の分だけです">
      <c:choose>
        <c:when test="${empty filterTrace}">
          <div class="alert alert-warning mb-0">
            フィルタの記録が取れませんでした。<code>web.xml</code> の
            <code>&lt;filter-mapping&gt;</code> を確認してください。
          </div>
        </c:when>
        <c:otherwise>
          <p>
            リクエスト ID <code>${fn:escapeXml(filterTrace.id)}</code>
            （<code>${fn:escapeXml(filterTrace.method)}</code>
            <code>${fn:escapeXml(filterTrace.uri)}</code>）
          </p>
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <thead>
                <tr>
                  <th style="width: 3rem;">#</th>
                  <th style="width: 7rem;">区分</th>
                  <th style="width: 14rem;">どこ</th>
                  <th>何をしたか</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="step" items="${filterTrace.steps}">
                  <tr>
                    <td>${step.seq}</td>
                    <td>
                      <span class="badge badge-${step.phase.variant}">
                        ${step.phase.mark} ${fn:escapeXml(step.phase.label)}
                      </span>
                    </td>
                    <td style="padding-left: ${0.75 + step.depth * 1.5}rem;">
                      <code>${fn:escapeXml(step.name)}</code>
                    </td>
                    <td>${fn:escapeXml(step.message)}</td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <p class="mt-3 mb-0 text-muted small">
            この続き（フィルタの「帰り」）は、この HTML を書き終えたあとに動きます。
            そのため、この表には出せません。下のデモで 1 往復の全体を見てください。
          </p>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <t:panel title="② 1 往復の全体を見る"
             note="リクエストを 1 本流してから、その記録を取り出します">
      <div id="traceDemo" data-api-path="${fn:escapeXml(apiPath)}">
        <p>
          ボタンを押すと <code>${fn:escapeXml(apiPath)}</code> へリクエストを 1 本流し、
          そのリクエスト ID を使って記録を取り出します。
        </p>
        <div class="btn-group mb-3" role="group" aria-label="リクエストの種類">
          <button type="button" class="btn btn-outline-primary" data-trace-run="normal">
            ふつうに通す
          </button>
          <button type="button" class="btn btn-outline-danger" data-trace-run="blocked">
            3 番目のフィルタで止める（403）
          </button>
        </div>
        <p class="text-muted small" id="traceStatus" aria-live="polite">
          まだリクエストを送っていません。
        </p>
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-0" id="traceTable" hidden>
            <thead>
              <tr>
                <th style="width: 3rem;">#</th>
                <th style="width: 7rem;">区分</th>
                <th style="width: 14rem;">どこ</th>
                <th>何をしたか</th>
              </tr>
            </thead>
            <tbody id="traceBody"></tbody>
          </table>
        </div>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        「止める」を選ぶと、3 番目のフィルタが <code>chain.doFilter</code> を呼ばずに
        <code>sendError(403)</code> で折り返します。
        <strong>Servlet は 1 度も動きません</strong>が、
        1 番目・2 番目のフィルタの「帰り」は通るので、ログと記録は残ります。
      </p>
    </t:panel>

    <t:panel title="③ ブラウザから確かめる"
             note="開発者ツールでレスポンスヘッダを見てみてください">
      <p class="mb-0">
        この画面を再読み込みして、ブラウザの開発者ツール（F12）の
        <strong>ネットワーク</strong>タブでレスポンスヘッダを見ると、
        1 番目のフィルタが付けた <code>X-Request-Id</code> が入っています。
        サーバ側のログ（<code>docker compose logs -f tomcat</code>）には、
        2 番目のフィルタが出した
        <code>GET /samples/advanced/filter 200 12 ms</code> のような行が出ています。
        同じ ID でログをたどれるようにしておくと、障害調査が一気に楽になります。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
