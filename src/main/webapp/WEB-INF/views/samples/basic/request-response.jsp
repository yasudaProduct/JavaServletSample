<%--
  【サンプル】リクエストとレスポンスの中身を見る

  RequestResponseServlet が次の値をセットします。
    requestLine … 組み立て直したリクエストの 1 行目
    facts       … リクエストから取れる代表的な値 (メソッド名 → 値)
    headers     … 届いたリクエストヘッダ (名前 → 値)

  レスポンス側 (ステータスコード・ヘッダ・Content-Type) は
  RequestResponseApiServlet を fetch で呼んで確かめます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="apiUrl" value="${ctx}/samples/basic/request-response/api" />
<t:sample sampleId="request-response">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>Servlet は HTTP を Java にしたもの</h2>
    <p>
      ブラウザとサーバのやりとりは、もともと<strong>ただのテキスト</strong>です。
      <code>HttpServletRequest</code> と <code>HttpServletResponse</code> は、
      そのテキストを Java から読み書きできるようにしたものにすぎません。
      メソッド名が何を返すか迷ったときは、この形を思い出すと当てがつきます。
    </p>

<pre><code class="language-plaintext">GET /samples/basic/request-response?x=1 HTTP/1.1   ← リクエスト行（メソッド・パス・バージョン）
Host: localhost:8080                                ← ヘッダ（何行でも続く）
User-Agent: Mozilla/5.0 ...
Accept-Language: ja,en-US;q=0.9
                                                    ← 空行（ここまでがヘッダ）
（本文。GET には普通ありません。POST のフォームの値はここに入ります）</code></pre>

<pre><code class="language-plaintext">HTTP/1.1 200 OK                                     ← ステータス行
Content-Type: text/html;charset=UTF-8               ← ヘッダ
Cache-Control: no-store
                                                    ← 空行
&lt;!DOCTYPE html&gt;...                                  ← 本文</code></pre>

    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 14rem;">HTTP のどこ</th>
            <th>Java では</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>リクエスト行</td>
            <td><code>getMethod()</code> / <code>getRequestURI()</code> / <code>getQueryString()</code> / <code>getProtocol()</code></td>
          </tr>
          <tr>
            <td>リクエストヘッダ</td>
            <td><code>getHeader(名前)</code> / <code>getHeaders(名前)</code> / <code>getHeaderNames()</code></td>
          </tr>
          <tr>
            <td>リクエスト本文</td>
            <td><code>getParameter(...)</code>（フォーム）/ <code>getInputStream()</code>（JSON など）</td>
          </tr>
          <tr>
            <td>ステータス行</td>
            <td><code>setStatus(コード)</code> / <code>sendError(コード)</code></td>
          </tr>
          <tr>
            <td>レスポンスヘッダ</td>
            <td><code>setHeader(名前, 値)</code> / <code>setContentType(...)</code> / <code>addCookie(...)</code></td>
          </tr>
          <tr>
            <td>レスポンス本文</td>
            <td><code>getWriter()</code>（文字）/ <code>getOutputStream()</code>（バイト）</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>間違えやすいメソッド</h2>
    <ul>
      <li>
        <code>getRequestURI()</code> は<strong>パスだけ</strong>（<code>/app/samples/...</code>）、
        <code>getRequestURL()</code> は<strong>スキームとホストを含む</strong>
        （<code>http://localhost:8080/app/samples/...</code>）。
        どちらも<strong>クエリ文字列は含みません</strong>。必要なら
        <code>getQueryString()</code> を自分でつなぎます
      </li>
      <li>
        <code>getRemoteAddr()</code> は<strong>直接つないできた相手</strong>のアドレスです。
        ロードバランサやリバースプロキシの後ろでは、そちらのアドレスになります。
        本当の利用者を知りたいときは <code>X-Forwarded-For</code> ヘッダを見ますが、
        <strong>これは自己申告なので信用しすぎない</strong>でください
      </li>
      <li>
        ヘッダ名は<strong>大文字小文字を区別しません</strong>。
        <code>getHeader("user-agent")</code> でも取れます
      </li>
      <li>
        同じ名前のヘッダは複数回現れてよい決まりです。
        <code>getHeader</code> は最初の 1 つだけを返すので、
        全部要るときは <code>getHeaders</code> を使います
      </li>
    </ul>

    <h2>ステータスコード</h2>
    <p>3 桁の最初の数字で大きく分かれます。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <tbody>
          <tr><td style="width: 6rem;"><code>2xx</code></td><td>成功。<code>200 OK</code>、<code>201 Created</code>（作った）、<code>204 No Content</code>（成功したが本文なし）</td></tr>
          <tr><td><code>3xx</code></td><td>場所が違う。<code>301</code>（恒久的）、<code>302</code>（一時的）、<code>304 Not Modified</code>（前回から変わっていない）</td></tr>
          <tr><td><code>4xx</code></td><td><strong>頼んだ側</strong>の問題。<code>400</code>（入力が変）、<code>401</code>（誰か分からない）、<code>403</code>（分かるが許可がない）、<code>404</code>（無い）、<code>405</code>（そのメソッドは受け付けない）、<code>409</code>（競合）</td></tr>
          <tr><td><code>5xx</code></td><td><strong>受けた側</strong>の問題。<code>500</code>（想定外の例外）、<code>503</code>（いまは無理。停止中・過負荷）</td></tr>
        </tbody>
      </table>
    </div>
    <p class="text-muted small">
      <code>401</code> と <code>403</code> の使い分けは
      「セッション・認証 &gt; フィルタで未ログインを弾く」で詳しく扱っています。
    </p>

    <h2><code>setStatus</code> と <code>sendError</code></h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 10rem;">&nbsp;</th>
            <th><code>setStatus(404)</code></th>
            <th><code>sendError(404)</code></th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>本文</td>
            <td><strong>自分で書く</strong></td>
            <td><strong>コンテナが差し替える</strong>（<code>web.xml</code> の <code>&lt;error-page&gt;</code>）</td>
          </tr>
          <tr>
            <td>向いている場面</td>
            <td>JSON を返す API。エラーも決まった形で返したいとき</td>
            <td>画面遷移のある普通のページ。共通のエラー画面を出したいとき</td>
          </tr>
          <tr>
            <td>注意</td>
            <td>本文を書き忘れると真っ白な画面になります</td>
            <td>Ajax に使うと、JSON を待っている画面に HTML が返ります</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>ヘッダに入力値を入れるとき</h2>
    <p>
      HTTP のヘッダは<strong>改行で区切られています</strong>。
      入力された値をそのままヘッダに入れると、改行を混ぜられたときに
      そこから先が別のヘッダや本文として読まれてしまいます（HTTP ヘッダインジェクション）。
    </p>
<pre><code class="language-java">// × 画面から来た値をそのまま入れる
response.setHeader("X-Sample-Note", request.getParameter("note"));

// ○ 改行と制御文字を落としてから入れる（長さも切る）
response.setHeader("X-Sample-Note", sanitizeHeaderValue(request.getParameter("note")));</code></pre>
    <p class="text-muted small">
      最近のコンテナは不正な値を弾くことが多いのですが、<strong>弾かれる前提で書かない</strong>のが原則です。
      同じことがファイル名（<code>Content-Disposition</code>）やリダイレクト先（<code>Location</code>）にも当てはまります。
    </p>

    <h2>JSP からも見られる</h2>
    <p>Servlet を書かなくても、EL の暗黙オブジェクトから読めます。</p>
<pre><code class="language-xml">${'${pageContext.request.method}'}        &lt;%-- GET / POST --%&gt;
${'${header["User-Agent"]}'}             &lt;%-- ヘッダ 1 件 --%&gt;
${'${headerValues["Accept"]}'}           &lt;%-- 同じ名前が複数あるとき --%&gt;
&lt;c:forEach var="h" items="${'${header}'}"&gt;${'${h.key}'} : ${'${h.value}'}&lt;/c:forEach&gt;</code></pre>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {

        var apiUrl = '${apiUrl}';
        var $result = $('#httpResult');

        // 選んだ条件で API を叩き、返ってきたものをそのまま並べる
        async function call(params) {
          var url = apiUrl + '?' + $.param(params);
          var line = [];

          try {
            // redirect: 'follow' (既定) なので、302 が返るとブラウザが勝手に追いかけます。
            // そのため最後に見えるのは追いかけた先の 200 です
            var res = await fetch(url, {headers: {'Accept': 'application/json'}});
            var body = await res.text();

            line.push('リクエスト : GET ' + url);
            line.push('');
            line.push('HTTP ' + res.status + (res.redirected ? '  （302 を追いかけた結果です）' : ''));
            line.push('Content-Type  : ' + (res.headers.get('Content-Type') || '(なし)'));
            line.push('Cache-Control : ' + (res.headers.get('Cache-Control') || '(なし)'));
            line.push('X-Sample-Mode : ' + (res.headers.get('X-Sample-Mode') || '(なし)'));
            line.push('X-Sample-Note : ' + (res.headers.get('X-Sample-Note') || '(なし)'));
            line.push('');
            line.push('本文 (' + body.length + ' 文字)');
            line.push(body.length === 0 ? '(空。204 や 304 は本文を持てません)' : body.slice(0, 600));
          } catch (e) {
            console.error(e);
            line.push('通信できませんでした: ' + e);
          }

          // 受け取った文字列は text() で入れる（innerHTML に入れると XSS になります）
          $result.text(line.join('\n'));
        }

        // ---- ステータスコードを選んで返す ----
        $('[data-status]').on('click', function () {
          call({
            status: $(this).data('status'),
            mode: $('input[name="mode"]:checked').val(),
            type: 'json'
          });
        });

        // ---- Content-Type とヘッダを変えて返す ----
        $('#sendHeaders').on('click', function () {
          call({
            status: 200,
            mode: 'setStatus',
            type: $('#typeSelect').val(),
            note: $('#noteInput').val()
          });
        });

        // ---- ブラウザで直接開く（Content-Type による見え方の違い） ----
        $('#openInBrowser').on('click', function () {
          window.open(apiUrl + '?' + $.param({
            status: 200, mode: 'setStatus', type: $('#typeSelect').val()
          }), '_blank');
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="届いたリクエスト" note="いまこの画面を開くために送られてきた内容です">
      <p class="small text-muted mb-2">リクエストの 1 行目を組み立て直したもの</p>
      <pre class="code-snippet mb-3">${fn:escapeXml(requestLine)}</pre>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th style="width: 18rem;">メソッド</th>
              <th>返ってきた値</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="fact" items="${facts}">
              <tr>
                <td><code>${fn:escapeXml(fact.key)}</code></td>
                <td><code>${fn:escapeXml(fact.value)}</code></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="リクエストヘッダ" note="ブラウザが毎回黙って付けているもの">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th style="width: 14rem;">名前</th>
              <th>値</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="entry" items="${headers}">
              <tr>
                <td><code>${fn:escapeXml(entry.key)}</code></td>
                <td class="small"><code>${fn:escapeXml(entry.value)}</code></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        <code>Cookie</code> ヘッダにはセッション ID（<code>JSESSIONID</code>）が入っています。
        画面を人に見せるときは、この行を隠してください。
        値の読み方は「Cookie の基本」で扱います。
      </p>
    </t:panel>

    <t:panel title="ステータスコードを選んで返す"
             note="同じコードでも setStatus と sendError で返ってくる本文が変わります">
      <div class="form-inline mb-3">
        <div class="form-check mr-3">
          <input class="form-check-input" type="radio" name="mode" id="modeSetStatus"
                 value="setStatus" checked>
          <label class="form-check-label" for="modeSetStatus">
            <code>setStatus</code>（本文は自分で書く）
          </label>
        </div>
        <div class="form-check">
          <input class="form-check-input" type="radio" name="mode" id="modeSendError"
                 value="sendError">
          <label class="form-check-label" for="modeSendError">
            <code>sendError</code>（エラーページに差し替わる）
          </label>
        </div>
      </div>

      <div class="mb-3">
        <button type="button" class="btn btn-sm btn-outline-success mr-1 mb-1" data-status="200">200 OK</button>
        <button type="button" class="btn btn-sm btn-outline-success mr-1 mb-1" data-status="201">201 Created</button>
        <button type="button" class="btn btn-sm btn-outline-success mr-1 mb-1" data-status="204">204 No Content</button>
        <button type="button" class="btn btn-sm btn-outline-info mr-1 mb-1" data-status="302">302 Found</button>
        <button type="button" class="btn btn-sm btn-outline-info mr-1 mb-1" data-status="304">304 Not Modified</button>
        <button type="button" class="btn btn-sm btn-outline-warning mr-1 mb-1" data-status="400">400 Bad Request</button>
        <button type="button" class="btn btn-sm btn-outline-warning mr-1 mb-1" data-status="401">401 Unauthorized</button>
        <button type="button" class="btn btn-sm btn-outline-warning mr-1 mb-1" data-status="403">403 Forbidden</button>
        <button type="button" class="btn btn-sm btn-outline-warning mr-1 mb-1" data-status="404">404 Not Found</button>
        <button type="button" class="btn btn-sm btn-outline-warning mr-1 mb-1" data-status="409">409 Conflict</button>
        <button type="button" class="btn btn-sm btn-outline-danger mr-1 mb-1" data-status="500">500 Server Error</button>
        <button type="button" class="btn btn-sm btn-outline-danger mr-1 mb-1" data-status="503">503 Unavailable</button>
      </div>

      <p class="small text-muted mb-0">
        <code>sendError</code> で 4xx / 5xx を選ぶと、返ってくるのは JSON ではなく
        <code>web.xml</code> に登録したエラーページの HTML になります。
        <strong>これが「Ajax で sendError を使ってはいけない」と言われる理由</strong>です。
      </p>
    </t:panel>

    <t:panel title="Content-Type とヘッダを変えて返す">
      <div class="form-inline mb-3">
        <label class="mr-2" for="typeSelect">Content-Type</label>
        <select class="form-control mr-3" id="typeSelect">
          <option value="json">application/json</option>
          <option value="text">text/plain</option>
          <option value="html">text/html</option>
        </select>

        <label class="mr-2" for="noteInput">X-Sample-Note</label>
        <input type="text" class="form-control mr-3" id="noteInput" size="18" value="こんにちは">

        <button type="button" class="btn btn-primary mr-2" id="sendHeaders">受け取る</button>
        <button type="button" class="btn btn-outline-secondary" id="openInBrowser">
          ブラウザで直接開く
        </button>
      </div>

      <p class="small text-muted mb-0">
        「ブラウザで直接開く」と、<strong>同じ中身でも <code>Content-Type</code> によって
        見え方が変わる</strong>ことが分かります（<code>text/html</code> ならタグとして解釈され、
        <code>text/plain</code> なら文字として見えます）。
        <code>X-Sample-Note</code> に改行を入れても、サーバ側で落としてから載せています。
      </p>
    </t:panel>

    <t:panel title="返ってきたもの">
      <pre class="code-snippet mb-0" id="httpResult">上のボタンを押すと、ここに結果が出ます。</pre>
    </t:panel>
  </jsp:body>
</t:sample>
