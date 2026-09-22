<%--
  【サンプル】URL と Servlet の対応づけ（url-pattern の優先順位）

  UrlMappingServlet が次の値をセットします。
    rules        … このサイトに登録されている url-pattern の一覧
    match        … 入力された URL の判定結果 (UrlMappingRules.Match)
    searchOrder  … コンテナが探す順番
    inputPath    … 入力欄に残す値

  「どのパターンが選ばれるか」はサーバ側 (UrlMappingRules) で判定し、
  「実際にどの Servlet が答えたか」はデモの fetch で確かめます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/basic/url-mapping" />
<t:sample sampleId="url-mapping">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>URL から Servlet が選ばれるまで</h2>
    <p>
      ブラウザから URL が届くと、コンテナ (Tomcat) は登録されている
      <code>url-pattern</code> の中から 1 つを選んで呼び出します。選び方は
      <strong>書いた順でも、登録した順でもありません</strong>。
      次の順に探して、見つかったところで打ち切ります。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 3rem;">順</th>
            <th style="width: 8rem;">形</th>
            <th style="width: 12rem;">書き方</th>
            <th>意味</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>1</td>
            <td><span class="badge badge-success">完全一致</span></td>
            <td><code>/samples/basic/scope</code></td>
            <td>URL がパターンと同じ。いちばん強く、他がどれだけ当てはまってもこれが勝ちます</td>
          </tr>
          <tr>
            <td>2</td>
            <td><span class="badge badge-primary">前方一致</span></td>
            <td><code>/samples/*</code></td>
            <td>
              その下すべてに当たります。当てはまるものが複数あれば
              <strong>いちばん長いもの</strong>が選ばれます
              （<code>/a/b/*</code> と <code>/a/*</code> なら前者）
            </td>
          </tr>
          <tr>
            <td>3</td>
            <td><span class="badge badge-warning">拡張子一致</span></td>
            <td><code>*.do</code></td>
            <td>
              URL の<strong>最後の階層</strong>の拡張子で判断します。
              前方一致で決まらなかったときだけ見られます
            </td>
          </tr>
          <tr>
            <td>4</td>
            <td><span class="badge badge-secondary">既定</span></td>
            <td><code>/</code></td>
            <td>
              どれにも当たらなかったものを受けます。Tomcat では
              <strong>静的ファイルを返す Servlet</strong> が最初から割り当たっていて、
              CSS や画像はここが返しています（ファイルが無ければ 404）
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <p class="text-muted small">
      パターンに使えるのはこの 4 つの形だけです。パスの途中に <code>*</code> を入れる
      <code>/samples/*/edit</code> のような書き方や、正規表現は使えません。
    </p>

    <h2>2 つの落とし穴</h2>
    <ul>
      <li>
        <strong><code>/foo/*</code> は <code>/foo</code> 自身にも当たる</strong>：
        「下の階層だけ」のつもりで書くと、入口のページにも掛かってしまいます。
        このサイトでは認証フィルタの <code>url-pattern</code> をあえて 1 本ずつ書いていますが、
        これは <code>/samples/session/auth-filter/*</code> と書くと
        説明ページ自身まで保護されてしまうためです（<code>web.xml</code> にも同じ注意書きがあります）。
      </li>
      <li>
        <strong>拡張子一致はアプリ全体に効く</strong>：
        <code>*.do</code> を登録すると、どの階層の <code>.do</code> も横取りします。
        限られた場所だけで使いたいなら、前方一致か完全一致にしてください。
      </li>
    </ul>

    <h2>URL の分け方（getServletPath と getPathInfo）</h2>
    <p>
      前方一致で呼ばれた Servlet は、URL を「自分に割り当たっている部分」と
      「その余り」に分けて受け取ります。
    </p>
<pre><code class="language-plaintext">http://localhost:8080/app/samples/basic/scope?x=1
                     |___|_______|____________|
                       |     |         |
        getContextPath()  getServletPath()  getPathInfo()     ← /samples/* で呼ばれた場合
                     /app  /samples   /basic/scope

getRequestURI()  = /app/samples/basic/scope    （クエリ文字列は含まない）
getQueryString() = x=1
getRequestURL()  = http://localhost:8080/app/samples/basic/scope</code></pre>

    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 12rem;">呼ばれ方</th>
            <th style="width: 14rem;"><code>getServletPath()</code></th>
            <th><code>getPathInfo()</code></th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>完全一致</td>
            <td>URL 全体</td>
            <td><code>null</code>（空文字ではありません）</td>
          </tr>
          <tr>
            <td>前方一致</td>
            <td><code>/*</code> を除いた部分</td>
            <td>余りの部分。余りが無ければ <code>null</code></td>
          </tr>
          <tr>
            <td>拡張子一致</td>
            <td>URL 全体</td>
            <td><code>null</code></td>
          </tr>
        </tbody>
      </table>
    </div>

    <p>
      <code>getPathInfo()</code> が <code>null</code> になり得ることを忘れると、
      前方一致の Servlet で <code>NullPointerException</code> が出ます。
      このサイトの <code>SampleDispatcherServlet</code> も、最初に
      <code>pathInfo == null</code> を見てからトップページへ戻しています。
    </p>

    <h2><code>@WebServlet</code> と <code>web.xml</code></h2>
    <p>どちらでも登録できます。両方書くと <code>web.xml</code> の内容が優先されます。</p>
<pre><code class="language-java">// アノテーションで書く（このサイトはこちら）
@WebServlet(name = "urlMapping", urlPatterns = {"/samples/basic/url-mapping"})
public class UrlMappingServlet extends HttpServlet { ... }</code></pre>
<pre><code class="language-xml">&lt;!-- web.xml で書く --&gt;
&lt;servlet&gt;
  &lt;servlet-name&gt;urlMapping&lt;/servlet-name&gt;
  &lt;servlet-class&gt;com.example.servletsample.samples.basic.UrlMappingServlet&lt;/servlet-class&gt;
  &lt;!-- 起動時に初期化しておきたいときに書く（数が小さいほど早い） --&gt;
  &lt;load-on-startup&gt;1&lt;/load-on-startup&gt;
&lt;/servlet&gt;
&lt;servlet-mapping&gt;
  &lt;servlet-name&gt;urlMapping&lt;/servlet-name&gt;
  &lt;url-pattern&gt;/samples/basic/url-mapping&lt;/url-pattern&gt;
&lt;/servlet-mapping&gt;</code></pre>

    <ul>
      <li>
        <strong>アノテーション</strong>は、クラスと URL が同じファイルに並ぶので追いやすい。
        ただし変更するたびにビルドが要ります。
      </li>
      <li>
        <strong><code>web.xml</code></strong> は、配備先ごとに URL を変えたいときや、
        設定を 1 か所で見渡したいときに向きます。
        フィルタのように<strong>順番が意味を持つもの</strong>は <code>web.xml</code> でしか指定できません。
      </li>
      <li>
        <code>urlPatterns</code> は配列なので、1 つの Servlet に複数のパターンを登録できます。
        このサンプルのデモ用 Servlet が実例です（完全一致・前方一致・拡張子一致の 3 つ）。
      </li>
    </ul>

    <h2>コンテナが最初から持っているマッピング</h2>
    <ul>
      <li><code>/</code> … 静的ファイル用の Servlet（<code>default</code>）。CSS も画像もここが返します</li>
      <li><code>*.jsp</code> … JSP 用の Servlet。JSP が「Servlet に変換されてから動く」のはこの受け口があるからです</li>
    </ul>
    <p>
      <code>/</code> を自分の Servlet で上書きすると、静的ファイルまで自分で返すことになります。
      「CSS だけ 404 になる」という事故の典型なので、フレームワークを入れるときは
      <code>/*</code> ではなく <code>/</code> を避けた形で登録するのが普通です。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {

        var $log = $('#tryLog');

        // 叩いて、返ってきたものを 1 行足す
        async function tryUrl(url) {
          var status = '-';
          var servlet = '（応答なし）';
          var paths = '';

          try {
            var res = await fetch(url, {headers: {'Accept': 'application/json'}});
            status = res.status;

            // Content-Type で「JSON かどうか」を見ます。
            // 既定の Servlet が答えたときは CSS や HTML が返ってくるので、
            // JSON.parse しようとすると例外になります
            var type = res.headers.get('Content-Type') || '';
            var body = await res.text();

            if (type.indexOf('application/json') >= 0) {
              var data = JSON.parse(body);
              servlet = data.servletName;
              paths = data.servletPath + '  /  ' + (data.pathInfo === null ? 'null' : data.pathInfo);
            } else {
              servlet = '既定 (default)';
              paths = 'JSON ではなく ' + (type.split(';')[0] || '不明') + ' が返りました';
            }
          } catch (e) {
            console.error(e);
            paths = '通信できませんでした';
          }

          $('#tryLogEmpty').remove();
          // 値は必ず text() で入れる（innerHTML に入れると XSS になります）
          $('<tr>')
            .append($('<td>').append($('<code>').text(url)))
            .append($('<td>').text(status))
            .append($('<td>').append($('<code>').text(servlet)))
            .append($('<td>').addClass('small').append($('<code>').text(paths)))
            .prependTo($log);
        }

        $('[data-try]').on('click', function () {
          tryUrl($(this).data('try'));
        });

        $('#clearLog').on('click', function () {
          $log.empty().append(
            $('<tr id="tryLogEmpty">').append(
              $('<td colspan="4" class="text-muted text-center">').text('まだ叩いていません')));
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="このページはどう呼ばれたか" note="完全一致で呼ばれています">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" style="width: 16rem;"><code>getRequestURI()</code></th>
              <td><code>${fn:escapeXml(pageContext.request.requestURI)}</code></td>
            </tr>
            <tr>
              <th scope="row"><code>getContextPath()</code></th>
              <td>
                <code>${empty ctx ? '"" (空文字)' : fn:escapeXml(ctx)}</code>
                <span class="d-block text-muted small mt-1">
                  このサイトはコンテキストルート（<code>ROOT</code>）に配備しているので空文字です。
                  <code>/app</code> の下に置けばここが <code>/app</code> になります。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row"><code>getServletPath()</code></th>
              <td><code>${fn:escapeXml(thisServletPath)}</code></td>
            </tr>
            <tr>
              <th scope="row"><code>getPathInfo()</code></th>
              <td>
                <code>${empty thisPathInfo ? 'null' : fn:escapeXml(thisPathInfo)}</code>
                <span class="d-block text-muted small mt-1">
                  完全一致で呼ばれているので余りはありません。
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        この URL は前方一致の <code>/samples/*</code>（<code>SampleDispatcherServlet</code>）にも
        当てはまりますが、完全一致が優先されるので <code>UrlMappingServlet</code> が呼ばれています。
      </p>
    </t:panel>

    <t:panel title="登録されているパターン" note="このサイトに実際に登録されているもの（サンプルごとの完全一致は 2 件だけ抜粋）">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th style="width: 20rem;">url-pattern</th>
              <th style="width: 11rem;">Servlet</th>
              <th>ひとこと</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="rule" items="${rules}">
              <tr>
                <td><code>${fn:escapeXml(rule.patternLabel)}</code></td>
                <td><code>${fn:escapeXml(rule.servletName)}</code></td>
                <td class="small">${fn:escapeXml(rule.note)}</td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="URL を入れて判定する" note="コンテキストパスより後ろの部分を入れてください">
      <form action="${sampleUrl}" method="get" class="form-inline mb-3">
        <label class="mr-2" for="pathInput">URL</label>
        <input type="text" class="form-control mr-2 flex-grow-1" id="pathInput" name="path"
               value="${fn:escapeXml(inputPath)}" placeholder="/samples/basic/url-mapping/demo/a/b">
        <button type="submit" class="btn btn-primary">判定する</button>
      </form>

      <div class="mb-3">
        <span class="text-muted small mr-2">例:</span>
        <a class="badge badge-light border mr-1" href="${sampleUrl}?path=/samples/basic/url-mapping/demo/exact">/demo/exact</a>
        <a class="badge badge-light border mr-1" href="${sampleUrl}?path=/samples/basic/url-mapping/demo/exact/more">/demo/exact/more</a>
        <a class="badge badge-light border mr-1" href="${sampleUrl}?path=/samples/basic/url-mapping/demo/report.mapping">/demo/report.mapping</a>
        <a class="badge badge-light border mr-1" href="${sampleUrl}?path=/report.mapping">/report.mapping</a>
        <a class="badge badge-light border mr-1" href="${sampleUrl}?path=/categories/basic">/categories/basic</a>
        <a class="badge badge-light border mr-1" href="${sampleUrl}?path=/assets/css/app.css">/assets/css/app.css</a>
        <a class="badge badge-light border mr-1" href="${sampleUrl}?path=/">/</a>
      </div>

      <div class="alert alert-${match.kind.variant} mb-3">
        <div class="mb-1">
          <code>${fn:escapeXml(match.path)}</code> は
          <strong>${fn:escapeXml(match.kind.label)}</strong>
          <c:if test="${match.matched}">
            で <code>${fn:escapeXml(match.rule.patternLabel)}</code>
            （<code>${fn:escapeXml(match.rule.servletName)}</code>）が呼ばれます。
          </c:if>
          <c:if test="${not match.matched}">
            です。受け口が無いので 404 になります。
          </c:if>
        </div>
        <div class="small mb-0">${fn:escapeXml(match.kind.description)}</div>
      </div>

      <c:if test="${match.matched}">
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-0">
            <tbody>
              <tr>
                <th scope="row" style="width: 16rem;">呼ばれる Servlet</th>
                <td><code>${fn:escapeXml(match.rule.servletName)}</code></td>
              </tr>
              <tr>
                <th scope="row"><code>getServletPath()</code></th>
                <td><code>${fn:escapeXml(match.servletPathLabel)}</code></td>
              </tr>
              <tr>
                <th scope="row"><code>getPathInfo()</code></th>
                <td><code>${fn:escapeXml(match.pathInfoLabel)}</code></td>
              </tr>
            </tbody>
          </table>
        </div>
      </c:if>

      <p class="mt-3 mb-1 small text-muted">コンテナが探した順（上から順に見て、最初に当たったところで打ち切り）</p>
      <ol class="small text-muted mb-0">
        <c:forEach var="step" items="${searchOrder}">
          <li><code>${fn:escapeXml(step)}</code></li>
        </c:forEach>
      </ol>
    </t:panel>

    <t:panel title="実際に叩いて確かめる" note="判定どおりの Servlet が答えるかを、その場で呼んで確認します">
      <p class="small text-muted">
        デモ用の Servlet は、呼ばれたときの <code>getServletPath()</code> などを JSON で返します。
        <strong>JSON が返れば</strong>デモ用 Servlet が、
        <strong>CSS や HTML が返れば</strong>既定の Servlet が答えた、ということです。
      </p>

      <div class="mb-3">
        <button type="button" class="btn btn-sm btn-outline-primary mr-1 mb-1"
                data-try="${ctx}/samples/basic/url-mapping/demo/exact">完全一致</button>
        <button type="button" class="btn btn-sm btn-outline-primary mr-1 mb-1"
                data-try="${ctx}/samples/basic/url-mapping/demo/exact/more">前方一致（完全一致の下）</button>
        <button type="button" class="btn btn-sm btn-outline-primary mr-1 mb-1"
                data-try="${ctx}/samples/basic/url-mapping/demo/report.mapping">前方一致 vs 拡張子一致</button>
        <button type="button" class="btn btn-sm btn-outline-primary mr-1 mb-1"
                data-try="${ctx}/report.mapping">拡張子一致</button>
        <button type="button" class="btn btn-sm btn-outline-secondary mr-1 mb-1"
                data-try="${ctx}/assets/css/app.css">既定（静的ファイル）</button>
        <button type="button" class="btn btn-sm btn-outline-secondary mr-1 mb-1"
                data-try="${ctx}/nowhere.html">既定（ファイルが無い）</button>
        <button type="button" class="btn btn-sm btn-link mb-1" id="clearLog">消す</button>
      </div>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th style="width: 20rem;">叩いた URL</th>
              <th style="width: 5rem;">HTTP</th>
              <th style="width: 10rem;">答えた Servlet</th>
              <th>getServletPath() / getPathInfo()</th>
            </tr>
          </thead>
          <tbody id="tryLog">
            <tr id="tryLogEmpty">
              <td colspan="4" class="text-muted text-center">まだ叩いていません</td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>
  </jsp:body>

</t:sample>
