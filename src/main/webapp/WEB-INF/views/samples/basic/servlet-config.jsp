<%--
  【サンプル】設定値の渡し方（init-param と context-param）

  ServletConfigServlet が次の値をセットします。
    servletName / initParams / pageSize / greeting / initializedAt … この Servlet だけの設定
    contextParams / contextFacts                                  … アプリ全体の設定
    demoPathA / demoPathB                                         … 同じクラスの 2 つの登録

  同じクラスを web.xml で 2 回登録したデモは、fetch で呼んで違いを見ます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="servlet-config">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>あとで変えたくなる値はソースに書かない</h2>
    <p>
      1 ページに出す件数、外部サービスの URL、上限値。こうした値をソースに直接書くと、
      変えるたびにビルドと再配備が要ります。Servlet には、これを外に出す仕組みが
      2 段階で用意されています。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 9rem;">&nbsp;</th>
            <th><code>&lt;context-param&gt;</code></th>
            <th><code>&lt;init-param&gt;</code></th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>届く範囲</td>
            <td>アプリ全体</td>
            <td>書いた Servlet（またはフィルタ）1 つだけ</td>
          </tr>
          <tr>
            <td>読む相手</td>
            <td><code>ServletContext</code></td>
            <td><code>ServletConfig</code></td>
          </tr>
          <tr>
            <td>Java から</td>
            <td><code>getServletContext().getInitParameter("名前")</code></td>
            <td><code>getInitParameter("名前")</code></td>
          </tr>
          <tr>
            <td>JSP から</td>
            <td><code>${'${initParam.名前}'}</code></td>
            <td>直接は読めない（Servlet が request に載せる）</td>
          </tr>
          <tr>
            <td>向いているもの</td>
            <td>サイト名、問い合わせ先、共通の URL</td>
            <td>その Servlet 固有の件数・上限・動作の切り替え</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>書き方は 2 通り</h2>
<pre><code class="language-java">// ① アノテーションで書く（クラスと設定が並ぶので追いやすい）
@WebServlet(
        name = "servletConfig",
        urlPatterns = {"/samples/basic/servlet-config"},
        initParams = {
                @WebInitParam(name = "pageSize", value = "20"),
                @WebInitParam(name = "greeting", value = "設定ファイルからこんにちは")
        })
public class ServletConfigServlet extends HttpServlet { ... }</code></pre>

<pre><code class="language-xml">&lt;!-- ② web.xml で書く（配備先ごとに変えられる。両方あれば web.xml が優先） --&gt;
&lt;servlet&gt;
  &lt;servlet-name&gt;servletConfigDemoA&lt;/servlet-name&gt;
  &lt;servlet-class&gt;...ServletConfigDemoServlet&lt;/servlet-class&gt;
  &lt;init-param&gt;
    &lt;param-name&gt;label&lt;/param-name&gt;
    &lt;param-value&gt;A 号機&lt;/param-value&gt;
  &lt;/init-param&gt;
&lt;/servlet&gt;</code></pre>

    <h2>同じクラスを、違う設定で何度でも</h2>
    <p>
      <code>web.xml</code> なら、<strong>同じクラスを別の名前で何度でも登録できます</strong>。
      登録した数だけインスタンスが作られ、それぞれに <code>init()</code> が呼ばれ、
      それぞれ自分の <code>&lt;init-param&gt;</code> を持ちます。
      「同じコードを設定違いで使い回す」のが <code>init-param</code> の値打ちです。
      アノテーションは 1 クラス 1 登録なので、この書き方はできません。
    </p>

    <h2>読むのは <code>init()</code> で 1 回だけ</h2>
<pre><code class="language-java">private int pageSize;

@Override
public void init() throws ServletException {
    // 設定はアプリが動いている間は変わらない。毎回読み直す必要はない
    pageSize = pageSizeOf(getInitParameter("pageSize"));
}</code></pre>
    <ul>
      <li>
        <strong>設定値も「人が手で書いた文字列」です。</strong>
        空欄・全角数字・桁あふれ・大きすぎる値が来ます。読めない値は既定値に倒し、
        上限は自分で決めておきます
      </li>
      <li>
        <strong>気付くのは早いほどよい。</strong>
        <code>init()</code> で確かめれば、おかしな設定は起動時に分かります。
        リクエストのたびに読んでいると、利用者が操作したときに初めて表に出ます
      </li>
      <li>
        <code>init(ServletConfig)</code> の方を上書きするときは
        <code>super.init(config)</code> を忘れないこと。忘れると
        <code>getInitParameter</code> が動かなくなります
        （引数なしの <code>init()</code> を使えば、この事故は起きません）
      </li>
      <li>
        どうしても起動できない設定なら <code>UnavailableException</code> を投げます。
        中途半端に動き続けるより、起動しない方が安全な場合があります
      </li>
    </ul>

    <h2>web.xml だけでは足りないこと</h2>
    <p>
      <code>web.xml</code> は WAR の中に入るので、<strong>環境ごとに値を変えるのは苦手</strong>です
      （開発・検証・本番で別の WAR を作ることになります）。実務では次を使い分けます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 14rem;">置き場所</th>
            <th>向いているもの</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>web.xml</code> / アノテーション</td>
            <td>環境で変わらない値（件数、表示名、動作の切り替え）</td>
          </tr>
          <tr>
            <td><code>context.xml</code> / JNDI</td>
            <td>DB 接続など、サーバ側が持つ資源。WAR を作り直さずに変えられます</td>
          </tr>
          <tr>
            <td>環境変数 / システムプロパティ</td>
            <td>環境ごとに変わる値。コンテナでの実行と相性がよい</td>
          </tr>
          <tr>
            <td><code>.properties</code></td>
            <td>文言や一覧など、量のある値（「応用・その他 &gt; 国際化」を参照）</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p class="text-muted small">
      <strong>パスワードや API キーは、どの方法でもリポジトリに入れない</strong>のが原則です。
      環境変数か、サーバ側の秘密管理の仕組みに置きます。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {
        // 同じクラスの 2 つの登録を、順番に呼んで並べる
        $('#callBoth').on('click', async function () {
          var rows = [];
          for (var url of ['${demoPathA}', '${demoPathB}']) {
            try {
              var res = await fetch(url, {headers: {'Accept': 'application/json'}});
              var data = await res.json();
              rows.push(url);
              rows.push('  servlet-name : ' + data.servletName);
              rows.push('  クラス        : ' + data.servletClass + ' ' + data.instance);
              rows.push('  label        : ' + data.label);
              rows.push('  pageSize     : ' + data.pageSize
                + '（web.xml には ' + data.initParams.pageSize + ' と書いてあります）');
              rows.push('');
            } catch (e) {
              console.error(e);
              rows.push(url + ' : 呼び出しに失敗しました');
            }
          }
          $('#demoResult').text(rows.join('\n'));
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="この Servlet だけの設定（init-param）"
             note="@WebServlet(initParams = ...) で書いています">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" style="width: 18rem;"><code>getServletName()</code></th>
              <td><code>${fn:escapeXml(servletName)}</code></td>
            </tr>
            <c:forEach var="entry" items="${initParams}">
              <tr>
                <td><code>getInitParameter("${fn:escapeXml(entry.key)}")</code></td>
                <td><code>${fn:escapeXml(entry.value)}</code></td>
              </tr>
            </c:forEach>
            <tr class="table-success">
              <th scope="row">init() で確かめたあとの <code>pageSize</code></th>
              <td>
                <code>${pageSize}</code>
                <span class="d-block text-muted small mt-1">
                  読めない値なら 20、大きすぎる値なら 100 に丸めています
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row"><code>init()</code> が呼ばれた時刻</th>
              <td>
                <code>${fn:escapeXml(initializedAt)}</code>
                <span class="d-block text-muted small mt-1">
                  画面を何度読み込んでも変わりません。設定を読むのは 1 回だけです
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-3 mb-0">${fn:escapeXml(greeting)}</p>
    </t:panel>

    <t:panel title="アプリ全体の設定（context-param）" note="web.xml に書いてあるもの">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th style="width: 14rem;">名前</th>
              <th>値</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="entry" items="${contextParams}">
              <tr>
                <td><code>${fn:escapeXml(entry.key)}</code></td>
                <td class="small"><code>${fn:escapeXml(entry.value)}</code></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        JSP からは <code>${'${initParam.siteTitle}'}</code> で読めます
        → <code>${fn:escapeXml(initParam.siteTitle)}</code><br>
        このサイトのヘッダーとフッターも、この値を使って表示しています。
      </p>
    </t:panel>

    <t:panel title="同じクラス、違う設定" note="web.xml で 2 回登録した Servlet を呼び分けます">
      <p class="small text-muted">
        下の 2 つの URL は<strong>同じクラス</strong>が受けています。
        違うのは <code>web.xml</code> に書いた <code>&lt;init-param&gt;</code> だけです。
      </p>
      <ul class="small">
        <li><code>${fn:escapeXml(demoPathA)}</code> … <code>label = A 号機</code> / <code>pageSize = 10</code></li>
        <li><code>${fn:escapeXml(demoPathB)}</code> … <code>label = B 号機</code> / <code>pageSize = 500</code>（上限を超えています）</li>
      </ul>

      <button type="button" class="btn btn-primary mb-3" id="callBoth">2 つとも呼んでみる</button>
      <pre class="code-snippet mb-0" id="demoResult">ボタンを押すと、それぞれの応答が並びます。</pre>

      <p class="text-muted small mt-3 mb-0">
        <code>servlet-name</code> と<strong>インスタンスの番号が違う</strong>ことに注目してください。
        登録した数だけインスタンスが作られています。
        B 号機の <code>pageSize</code> は <code>web.xml</code> に 500 と書いてありますが、
        <code>init()</code> の中で上限の 100 に丸めています。
      </p>
    </t:panel>

    <t:panel title="ServletContext から取れるもの" note="設定以外にも、アプリ自身の情報が取れます">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <c:forEach var="entry" items="${contextFacts}">
              <tr>
                <th scope="row" style="width: 22rem;"><code>${fn:escapeXml(entry.key)}</code></th>
                <td><code>${fn:escapeXml(entry.value)}</code></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        <code>ServletContext</code> はアプリに 1 つだけで、application スコープの置き場所でもあります
        （「スコープ」のサンプルを参照）。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
