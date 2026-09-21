<%--
  【サンプル】include と forward（画面の一部を差し込む）

  DispatcherIncludeServlet が次の値をセットします。
    noticeCount … 差し込む部品に渡す値
    demoPath    … forward / include を呼び分けるデモの URL
    partPath    … 部品そのものの URL
    forwardKeys / includeKeys … コンテナが置く目印の名前

  デモでは同じ部品 (dispatcher-include-part.jsp) を 2 回 include しています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="dispatcher-include">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>渡し方は 2 つある</h2>
    <p>
      サーバの中で他の資源（Servlet や JSP）に処理を渡すのが
      <code>RequestDispatcher</code> です。渡し方は 2 つあり、
      <strong>戻ってくるかどうか</strong>が決定的に違います。
    </p>

<pre><code class="language-java">RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/views/part.jsp");

dispatcher.forward(request, response);   // 渡したら戻ってこない。画面を丸ごと任せる
dispatcher.include(request, response);   // 差し込んで戻ってくる。画面の一部を任せる</code></pre>

    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 14rem;">&nbsp;</th>
            <th><code>forward</code></th>
            <th><code>include</code></th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>処理の流れ</td>
            <td>渡したら<strong>戻ってこない</strong></td>
            <td>差し込んだあと<strong>戻ってくる</strong></td>
          </tr>
          <tr>
            <td>それまでに書いた本文</td>
            <td><strong>捨てられる</strong></td>
            <td>残る（その続きに差し込まれる）</td>
          </tr>
          <tr>
            <td>渡された側のヘッダ・ステータス</td>
            <td>効く</td>
            <td><strong>無視される</strong></td>
          </tr>
          <tr>
            <td><code>getRequestURI()</code></td>
            <td>転送先を指す</td>
            <td>元のまま</td>
          </tr>
          <tr>
            <td>使いどころ</td>
            <td>Servlet → JSP で画面を作る</td>
            <td>ヘッダー・メニュー・共通の枠を差し込む</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>渡された側が置かれる目印</h2>
    <p>
      渡された側からは「自分が直接呼ばれたのか」が分かりません。
      そこでコンテナが、決まった名前のリクエスト属性に元の情報を入れてくれます。
      <strong>forward と include で入っているものが逆</strong>なので注意してください。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 8rem;">&nbsp;</th>
            <th style="width: 20rem;">属性</th>
            <th>入っているもの</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>forward</code></td>
            <td><code>javax.servlet.forward.request_uri</code> ほか</td>
            <td><strong>元の</strong> URL（ブラウザが最初に叩いた方）</td>
          </tr>
          <tr>
            <td><code>include</code></td>
            <td><code>javax.servlet.include.request_uri</code> ほか</td>
            <td><strong>差し込まれている側</strong>の URL（いま動いている方）</td>
          </tr>
        </tbody>
      </table>
    </div>

    <p class="text-muted small">
      Tomcat 10 以降（Jakarta EE）では、属性名の頭が
      <code>jakarta.servlet.</code> に変わります。
    </p>

    <h2>値の渡し方</h2>
    <ul>
      <li>
        <strong>リクエストスコープ</strong>…
        <code>request.setAttribute(...)</code> で入れた値は、
        forward 先でも include 先でもそのまま読めます（同じリクエストなので）
      </li>
      <li>
        <strong><code>&lt;jsp:param&gt;</code></strong>…
        <code>&lt;jsp:include&gt;</code> のときだけ使える渡し方です。
        <strong>その差し込みの間だけ</strong>パラメータが増え、終わると元に戻ります。
        同じ部品を違う値で何度も差し込むときに向きます
      </li>
    </ul>

<pre><code class="language-xml">&lt;jsp:include page="/WEB-INF/views/samples/basic/dispatcher-include-part.jsp"&gt;
  &lt;jsp:param name="title" value="お知らせ" /&gt;
&lt;/jsp:include&gt;</code></pre>

    <h2><code>&lt;jsp:include&gt;</code> と <code>&lt;%@ include %&gt;</code></h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 10rem;">&nbsp;</th>
            <th><code>&lt;jsp:include page="..."&gt;</code></th>
            <th><code>&lt;%@ include file="..." %&gt;</code></th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>いつ取り込む</td>
            <td><strong>実行時</strong>（出力を差し込む）</td>
            <td><strong>翻訳時</strong>（ソースを貼り込む）</td>
          </tr>
          <tr>
            <td>変数</td>
            <td>別のページなので共有されない</td>
            <td>同じページになるので共有される（名前の衝突に注意）</td>
          </tr>
          <tr>
            <td>向いているもの</td>
            <td>値によって中身が変わる部品</td>
            <td>共通の宣言、定数（<code>.jspf</code>）</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p class="text-muted small">
      この 2 つの違いは「基本 &gt; JSP の記法」でも、変換後の Servlet と合わせて扱っています。
      なお、このサイトの共通レイアウトは include ではなく
      <strong>タグファイル</strong>（<code>/WEB-INF/tags/layout.tag</code>）にまとめています。
      属性を受け取れて、本文を差し込める（<code>&lt;jsp:doBody /&gt;</code>）ぶん、
      枠として使うには素直です。
    </p>

    <h2>気をつけること</h2>
    <ul>
      <li>
        <strong>forward のあとに書かない。</strong>
        forward した時点でレスポンスは相手に任されています。
        続けて書くと <code>IllegalStateException</code> になるか、黙って捨てられます。
        <code>forward</code> や <code>sendRedirect</code> のあとは <code>return</code> する癖をつけてください
      </li>
      <li>
        <strong>すでに送り始めていると forward できません。</strong>
        forward は「それまでの本文を捨ててやり直す」ものなので、
        送信済みだと捨てられず例外になります
      </li>
      <li>
        <strong>渡す先のパスにコンテキストパスは付けません。</strong>
        サーバの中の話なので、<code>/WEB-INF/views/...</code> のように
        アプリのルートから書きます
      </li>
      <li>
        <code>request.getRequestDispatcher(...)</code> は相対パスも使えますが、
        <code>getServletContext().getRequestDispatcher(...)</code> は
        <code>/</code> から始まるパスだけです
      </li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {
        $('[data-mode]').on('click', async function () {
          var url = '${demoPath}?mode=' + $(this).data('mode');
          try {
            var res = await fetch(url);
            var body = await res.text();
            $('#dispatcherResult').text('GET ' + url + '\n\n' + body);
          } catch (e) {
            console.error(e);
            $('#dispatcherResult').text('通信できませんでした: ' + e);
          }
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="この画面自身も forward で作られています">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <c:forEach var="key" items="${forwardKeys}">
              <tr>
                <td style="width: 24rem;"><code>${fn:escapeXml(key)}</code></td>
                <td>
                  <code>${empty requestScope[key] ? 'null' : fn:escapeXml(requestScope[key])}</code>
                </td>
              </tr>
            </c:forEach>
            <tr>
              <td><code>getRequestURI()</code>（いまの値）</td>
              <td><code>${fn:escapeXml(pageContext.request.requestURI)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        <code>getRequestURI()</code> は<strong>転送先の JSP</strong> を指していて、
        ブラウザが叩いた URL は <code>javax.servlet.forward.request_uri</code> に残っています。
        アドレスバーは前者ではなく後者のままです。
      </p>
    </t:panel>

    <t:panel title="同じ部品を 2 回差し込む" note="jsp:include で、渡す値だけ変えています">
      <jsp:include page="/WEB-INF/views/samples/basic/dispatcher-include-part.jsp">
        <jsp:param name="title" value="お知らせ" />
        <jsp:param name="body" value="1 つ目の差し込みです。jsp:param の値が違います。" />
      </jsp:include>

      <jsp:include page="/WEB-INF/views/samples/basic/dispatcher-include-part.jsp">
        <jsp:param name="title" value="メンテナンス予定" />
        <jsp:param name="body" value="2 つ目の差し込みです。部品の JSP は 1 つだけです。" />
      </jsp:include>

      <p class="text-muted small mb-0">
        JSP ファイルは 1 つですが、2 回差し込まれています。
        <code>&lt;jsp:param&gt;</code> の値は差し込みごとに違い、
        request スコープに入れた <code>noticeCount</code> は両方で同じです。
      </p>
    </t:panel>

    <t:panel title="forward と include を呼び分ける"
             note="同じ部品を呼び、何が残るかを見比べます">
      <p class="small text-muted">
        呼び出し元は「①」を書き、部品を呼び、そのあと「③」を書こうとします。
        どれが利用者に届くでしょうか。
      </p>

      <div class="mb-3">
        <button type="button" class="btn btn-sm btn-outline-primary mr-1 mb-1"
                data-mode="include">include で呼ぶ</button>
        <button type="button" class="btn btn-sm btn-outline-primary mr-1 mb-1"
                data-mode="forward">forward で呼ぶ</button>
        <button type="button" class="btn btn-sm btn-outline-danger mr-1 mb-1"
                data-mode="forward-after-commit">送信済みになってから forward する</button>
        <a class="btn btn-sm btn-outline-secondary mb-1" href="${fn:escapeXml(partPath)}"
           target="_blank">部品を直接開く</a>
      </div>

      <pre class="code-snippet mb-0" id="dispatcherResult">ボタンを押すと、返ってきた本文がそのまま出ます。</pre>

      <p class="text-muted small mt-3 mb-0">
        <strong>include</strong> なら ①・部品・③ がすべて出ます。
        <strong>forward</strong> では ① が捨てられ、部品の出力だけになり、③ は届きません。
        <strong>送信済みになってから</strong>の forward は
        <code>IllegalStateException</code> です。<br>
        「部品を直接開く」と、同じ Servlet が<strong>直接呼ばれた</strong>と報告します。
        目印が付くかどうかで、呼ばれ方を見分けているためです。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
