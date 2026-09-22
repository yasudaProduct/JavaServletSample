<%--
  【サンプル】Servlet から直接出力する（getWriter とバッファ）

  ResponseOutputServlet が次の値をセットします。
    bufferSize              … Servlet の既定のバッファの大きさ
    committedBeforeForward  … forward する前の isCommitted()
    demoPath                … 書き出しを試す先の URL

  バッファに収まるかどうかで「書いたあとに何ができるか」が変わることを、
  fetch でヘッダを見ながら確かめます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="response-output">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>直接書けるのに、なぜ JSP を使うのか</h2>
    <p>
      Servlet は <code>response.getWriter()</code> で HTML をそのまま書き出せます。
      それでも画面は JSP に任せるのが普通です。理由は単純で、
      <strong>HTML を Java の文字列として書くと読めなくなる</strong>からです。
    </p>

<pre><code class="language-java">// Servlet の中で組み立てる
out.write("&lt;table&gt;");
for (Product product : products) {
    out.write("&lt;tr&gt;&lt;td&gt;" + product.getName() + "&lt;/td&gt;&lt;/tr&gt;");  // ← エスケープ漏れ（XSS）
}
out.write("&lt;/table&gt;");</code></pre>

<pre><code class="language-xml">&lt;%-- JSP で書く。HTML はそのまま、値の埋め込みだけ EL に任せる --%&gt;
&lt;table&gt;
  &lt;c:forEach var="product" items="${'${products}'}"&gt;
    &lt;tr&gt;&lt;td&gt;${'${fn:escapeXml(product.name)}'}&lt;/td&gt;&lt;/tr&gt;
  &lt;/c:forEach&gt;
&lt;/table&gt;</code></pre>

    <p>
      とはいえ、直接書き出す場面もあります。<strong>JSON を返す API</strong>、
      <strong>CSV や PDF のダウンロード</strong>、<strong>画像の出力</strong>。
      HTML 以外を返すときは、JSP を通す方がかえって面倒です。
    </p>

    <h2>文字で書くか、バイトで書くか</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 12rem;">&nbsp;</th>
            <th><code>getWriter()</code></th>
            <th><code>getOutputStream()</code></th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>書くもの</td>
            <td>文字（<code>String</code>）</td>
            <td>バイト（<code>byte[]</code>）</td>
          </tr>
          <tr>
            <td>文字コード</td>
            <td>レスポンスの設定に従って自動で変換</td>
            <td><strong>自分で変換する</strong></td>
          </tr>
          <tr>
            <td>向いているもの</td>
            <td>HTML、JSON、テキスト</td>
            <td>画像、PDF、ZIP、BOM 付き CSV</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <strong>同じレスポンスで両方は使えません。</strong>
      あとから呼んだ方が <code>IllegalStateException</code> になります。
      CSV の BOM のように「1 バイトも違わずに送りたい」ものがあるときは、
      最初から <code>getOutputStream()</code> に決めておきます
      （「ファイル &gt; CSV ダウンロード」を参照）。
    </p>

    <h2>順番の決まり</h2>
<pre><code class="language-java">// ① ステータスとヘッダを決める
response.setStatus(200);
response.setContentType("text/plain; charset=UTF-8");
response.setHeader("Cache-Control", "no-store");

// ② そのあとで書く
PrintWriter out = response.getWriter();
out.write("こんにちは");</code></pre>
    <p>
      逆にすると効きません。<code>getWriter()</code> を呼んだ時点で文字コードが決まり、
      書き始めるとヘッダは送られてしまうためです。
    </p>

    <h2>バッファと「送信済み」</h2>
    <p>
      書いた内容はすぐには送られず、いったん<strong>バッファ</strong>にたまります。
      いっぱいになるか、処理が終わったときにまとめて送られます。
      この「まだ送っていない」状態が、いろいろなことを可能にしています。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 16rem;">やりたいこと</th>
            <th>バッファにいる間</th>
            <th>送り始めたあと</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>ヘッダを足す・変える</td>
            <td class="table-success">できる</td>
            <td class="table-danger">黙って捨てられる（例外にもならない）</td>
          </tr>
          <tr>
            <td><code>resetBuffer()</code> で書き直す</td>
            <td class="table-success">できる</td>
            <td class="table-danger"><code>IllegalStateException</code></td>
          </tr>
          <tr>
            <td><code>sendRedirect</code> / <code>forward</code></td>
            <td class="table-success">できる</td>
            <td class="table-danger"><code>IllegalStateException</code></td>
          </tr>
          <tr>
            <td>エラーページへの差し替え</td>
            <td class="table-success">できる</td>
            <td class="table-danger">途中まで出た HTML の後ろに継ぎ足される</td>
          </tr>
        </tbody>
      </table>
    </div>

    <p>
      いま送り始めているかどうかは <code>response.isCommitted()</code> で分かります。
      「画面の途中で 500 エラーが出たとき、真っ白になるか、途中まで出てから崩れるか」の分かれ目もここです。
      このサイトでは <code>web.xml</code> で JSP のバッファを広げてあります。
    </p>
<pre><code class="language-xml">&lt;jsp-property-group&gt;
  &lt;url-pattern&gt;*.jsp&lt;/url-pattern&gt;
  &lt;buffer&gt;64kb&lt;/buffer&gt;   &lt;!-- 既定の 8kb だと、長い画面は途中で送信が始まってしまう --&gt;
&lt;/jsp-property-group&gt;</code></pre>

    <h2>関係するメソッド</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <tbody>
          <tr><td style="width: 14rem;"><code>getBufferSize()</code></td><td>バッファの大きさ（バイト）</td></tr>
          <tr><td><code>setBufferSize(n)</code></td><td>大きさを変える。<strong>書き始める前だけ</strong></td></tr>
          <tr><td><code>isCommitted()</code></td><td>もう送り始めたか</td></tr>
          <tr><td><code>flushBuffer()</code></td><td>いま送る。<strong>これを呼んだ時点で送信済みになります</strong></td></tr>
          <tr><td><code>resetBuffer()</code></td><td>書いた本文を捨てる（ヘッダは残る）</td></tr>
          <tr><td><code>reset()</code></td><td>本文もヘッダもステータスも捨てる</td></tr>
        </tbody>
      </table>
    </div>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {

        var demoPath = '${demoPath}';

        async function call(params) {
          var url = demoPath + '?' + $.param(params);
          var lines = [];

          try {
            var res = await fetch(url);
            var body = await res.text();

            lines.push('リクエスト : GET ' + url);
            lines.push('');
            lines.push('X-Buffer-Size       : ' + (res.headers.get('X-Buffer-Size') || '(なし)')
              + ' バイト');
            lines.push('X-Committed         : ' + (res.headers.get('X-Committed')
              || '(付いていません。送信済みになったあとの指定は捨てられます)'));
            lines.push('X-Added-After-Write : '
              + (res.headers.get('X-Added-After-Write') || '(付いていません)'));
            lines.push('Content-Length      : ' + (res.headers.get('Content-Length')
              || '(なし。送りながら返す形になっています)'));
            lines.push('');
            lines.push('本文 ' + body.length + ' 文字のうち、最初と最後');
            lines.push(body.length > 400
              ? body.slice(0, 200) + '\n  …（中略）…\n' + body.slice(-260)
              : body);
          } catch (e) {
            console.error(e);
            lines.push('通信できませんでした: ' + e);
          }

          $('#outputResult').text(lines.join('\n'));
        }

        $('[data-demo]').on('click', function () {
          call($(this).data('demo'));
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="いまのレスポンスの状態">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" style="width: 22rem;"><code>response.getBufferSize()</code></th>
              <td>
                <code>${bufferSize}</code> バイト
                <span class="d-block text-muted small mt-1">
                  Servlet の既定値です。この画面を組み立てている JSP は、
                  <code>web.xml</code> の <code>&lt;jsp-config&gt;</code> で 64kb に広げています
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">forward する前の <code>isCommitted()</code></th>
              <td>
                <code>${committedBeforeForward}</code>
                <span class="d-block text-muted small mt-1">
                  まだ何も書いていないので <code>false</code> です。
                  <strong>ここが <code>true</code> だと forward できません</strong>
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="何で書き出すか" note="文字として書くか、バイトとして書くか">
      <button type="button" class="btn btn-sm btn-outline-primary mr-1 mb-1"
              data-demo='{"mode":"writer","size":200}'>getWriter() で書く</button>
      <button type="button" class="btn btn-sm btn-outline-primary mr-1 mb-1"
              data-demo='{"mode":"stream","size":200}'>getOutputStream() で書く</button>
      <button type="button" class="btn btn-sm btn-outline-danger mr-1 mb-1"
              data-demo='{"mode":"both","size":0}'>両方を使おうとする</button>
      <p class="small text-muted mt-2 mb-0">
        「両方」を選ぶと <code>IllegalStateException</code> が起きます。
        例外のメッセージをそのまま本文に載せているので、何を言われるか確かめてください。
      </p>
    </t:panel>

    <t:panel title="バッファに収まるかどうかで変わること"
             note="本文を書いたあとにヘッダを足す／書き直す、を試します">
      <p class="small text-muted">
        バッファは <code>${bufferSize}</code> バイトです。
        本文がこれを超えると、書いている途中で送信が始まります（送信済み）。
      </p>

      <div class="mb-2">
        <span class="d-inline-block mr-2 small" style="width: 12rem;">本文を書いたあとにヘッダを足す</span>
        <button type="button" class="btn btn-sm btn-outline-success mr-1 mb-1"
                data-demo='{"mode":"writer","size":200,"after":"header"}'>
          200 文字（収まる）
        </button>
        <button type="button" class="btn btn-sm btn-outline-danger mr-1 mb-1"
                data-demo='{"mode":"writer","size":20000,"after":"header"}'>
          20000 文字（あふれる）
        </button>
      </div>

      <div class="mb-3">
        <span class="d-inline-block mr-2 small" style="width: 12rem;">書いた本文を捨ててやり直す</span>
        <button type="button" class="btn btn-sm btn-outline-success mr-1 mb-1"
                data-demo='{"mode":"writer","size":200,"after":"reset"}'>
          200 文字（収まる）
        </button>
        <button type="button" class="btn btn-sm btn-outline-danger mr-1 mb-1"
                data-demo='{"mode":"writer","size":20000,"after":"reset"}'>
          20000 文字（あふれる）
        </button>
      </div>

      <p class="small text-muted mb-0">
        あふれた方では、<strong><code>X-Committed</code> も <code>X-Added-After-Write</code> も
        付いてきません</strong>。送信済みになったあとのヘッダ指定は、
        例外も出さずに黙って捨てられるからです（<code>isCommitted()</code> の値は本文の末尾に書いています）。
        書き直しの方は <code>IllegalStateException</code> になり、そのメッセージが本文に残ります。<br>
        <code>Content-Length</code> の有無にも注目してください。
        バッファに収まったときは長さが分かるので付きますが、
        あふれたときは「送りながら返す」形になるため付きません。
      </p>
    </t:panel>

    <t:panel title="返ってきたもの">
      <pre class="code-snippet mb-0" id="outputResult">上のボタンを押すと、ここに結果が出ます。</pre>
    </t:panel>
  </jsp:body>
</t:sample>
