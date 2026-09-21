<%--
  【サンプル】コンテキストパスと相対パス（リンクが 404 になる）

  ContextPathServlet が次の値をセットします。
    contextPath / currentPath / requestUrl … いまの配備と URL
    endsWithSlash                          … 末尾スラッシュ付きで開かれたか
    links                                  … 3 通りの書き方とその解決先
    targetPath                             … 実際にファイルが置いてある場所

  デモでは「いまの配備（ROOT）」と「/app に配備したら」を並べています。
  ROOT 配備だと間違ったリンクでもたまたま動いてしまい、気付けないためです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/basic/context-path" />
<t:sample sampleId="context-path">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>コンテキストパスとは</h2>
    <p>
      アプリがサーバのどこに置かれているかを表す部分です。
      同じアプリでも、置き場所によって URL の頭が変わります。
    </p>

<pre><code class="language-plaintext">http://localhost:8080/samples/basic/context-path        ROOT に配備 → コンテキストパスは "" (空文字)
http://localhost:8080/app/samples/basic/context-path    /app に配備 → コンテキストパスは "/app"
                     ^^^^</code></pre>

    <p>
      やっかいなのは、<strong>ROOT に配備していると間違いに気付けない</strong>ことです。
      コンテキストパスが空文字なので、<code>/assets/app.css</code> と書いても動いてしまいます。
      配備先が変わった瞬間、<strong>CSS と画像だけ出ない</strong>という形で表に出ます。
    </p>

    <h2>3 通りの書き方</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 16rem;">書き方</th>
            <th>意味</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>/assets/favicon.svg</code></td>
            <td>
              <strong>サーバのルート</strong>から見た位置。いまの URL とは関係ありません。
              ROOT 配備では動きますが、<code>/app</code> に置くと 404 です
            </td>
          </tr>
          <tr>
            <td><code>assets/favicon.svg</code></td>
            <td>
              <strong>いまの URL のディレクトリ</strong>から見た位置。
              画面ごとに指す先が変わるので、どこに置いても危ういです
            </td>
          </tr>
          <tr class="table-success">
            <td><code>${'${pageContext.request.contextPath}'}/assets/favicon.svg</code></td>
            <td>
              <strong>これを使います。</strong>配備先が変われば、書き出される文字列も変わります
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <p>
      毎回書くのは長いので、このサイトでは各 JSP の先頭で 1 回だけ変数に入れています。
    </p>
<pre><code class="language-xml">&lt;c:set var="ctx" value="${'${pageContext.request.contextPath}'}" /&gt;
&lt;link rel="stylesheet" href="${'${ctx}'}/assets/css/app.css"&gt;
&lt;a href="${'${ctx}'}/samples/basic/scope"&gt;スコープのサンプル&lt;/a&gt;</code></pre>

    <h2>相対パスの基準は「JSP の場所」ではない</h2>
    <p>
      ここが最大の落とし穴です。相対パスの基準は
      <strong>ブラウザのアドレスバーに出ている URL</strong> であって、
      JSP がどこに置かれているかは<strong>まったく関係ありません</strong>。
    </p>
    <p>
      このサイトの JSP は <code>/WEB-INF/views/samples/basic/</code> にありますが、
      forward してもアドレスバーは <code>/samples/basic/context-path</code> のままです。
      ブラウザは <code>/WEB-INF/</code> のことなど知らないので、
      相対パスは <code>/samples/basic/</code> を基準に解決されます。
    </p>

    <h2>末尾のスラッシュで基準が変わる</h2>
<pre><code class="language-plaintext">/samples/basic/context-path   の相対 "assets/x.svg" → /samples/basic/assets/x.svg
/samples/basic/context-path/  の相対 "assets/x.svg" → /samples/basic/context-path/assets/x.svg</code></pre>
    <p>
      スラッシュ 1 つで指す先が変わります。
      「ファイルを指すのか、ディレクトリを指すのか」の違いです。
      <code>&lt;base href="..."&gt;</code> を置いて基準を固定する手もありますが、
      ページ内のすべての相対パスに効いてしまうため、影響範囲が読みにくくなります。
    </p>

    <h2>コンテキストパスを付けるところ・付けないところ</h2>
    <p>
      <strong>ブラウザが使うパスには付け、サーバの中だけで使うパスには付けません。</strong>
      ブラウザはアプリの置き場所を知らないので教える必要があり、
      サーバは自分のアプリの中を探すので要らない、と考えると整理できます。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 20rem;">書く場所</th>
            <th style="width: 8rem;">付ける？</th>
            <th>例</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>HTML の <code>href</code> / <code>src</code> / <code>action</code></td>
            <td><strong>付ける</strong></td>
            <td><code>${'${ctx}'}/samples/basic/scope</code></td>
          </tr>
          <tr>
            <td><code>response.sendRedirect(...)</code></td>
            <td><strong>付ける</strong></td>
            <td><code>request.getContextPath() + "/samples/..."</code></td>
          </tr>
          <tr>
            <td><code>cookie.setPath(...)</code></td>
            <td><strong>付ける</strong></td>
            <td><code>request.getContextPath() + "/"</code></td>
          </tr>
          <tr class="table-info">
            <td><code>request.getRequestDispatcher(...)</code></td>
            <td>付けない</td>
            <td><code>/WEB-INF/views/samples/basic/context-path.jsp</code></td>
          </tr>
          <tr class="table-info">
            <td><code>&lt;jsp:include page="..."&gt;</code></td>
            <td>付けない</td>
            <td><code>/WEB-INF/views/parts/header.jsp</code></td>
          </tr>
          <tr class="table-info">
            <td><code>@WebServlet</code> / <code>web.xml</code> の <code>url-pattern</code></td>
            <td>付けない</td>
            <td><code>/samples/basic/context-path</code></td>
          </tr>
        </tbody>
      </table>
    </div>

    <p class="text-muted small">
      <code>sendRedirect</code> は、Servlet 3.0 以降は相対 URL も渡せます。
      ただし「どこから見た相対か」を毎回考えることになるので、
      <strong>コンテキストパスから組み立てる書き方に統一する</strong>のが安全です。
    </p>

    <h2>気付くための工夫</h2>
    <ul>
      <li>
        開発でも<strong>ROOT 以外に配備して一度動かしてみる</strong>。
        <code>/app</code> に置くだけで、間違ったリンクはすべて 404 になります
      </li>
      <li>
        <code>grep</code> で <code>href="/</code> や <code>src="/</code> を探す。
        <code>${'${ctx}'}</code> が付いていない絶対パスはそこで見つかります
      </li>
      <li>
        リンクを書く場所を決めておく（このサイトは各 JSP の先頭の <code>ctx</code> 変数に統一）
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="いまの配備">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" style="width: 20rem;"><code>getContextPath()</code></th>
              <td>
                <code>${empty contextPath ? '"" (空文字)' : fn:escapeXml(contextPath)}</code>
                <span class="d-block text-muted small mt-1">
                  このサイトは ROOT に配備しているので空文字です
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">アドレスバーの URL</th>
              <td><code>${fn:escapeXml(requestUrl)}</code></td>
            </tr>
            <tr>
              <th scope="row">相対パスの基準</th>
              <td>
                <code>${fn:escapeXml(currentPath)}</code> の
                <c:choose>
                  <c:when test="${endsWithSlash}">
                    <strong>末尾がスラッシュ</strong>なので、この URL 自身がディレクトリ扱いです
                  </c:when>
                  <c:otherwise>
                    最後の <code>/</code> までが基準です
                  </c:otherwise>
                </c:choose>
              </td>
            </tr>
            <tr>
              <th scope="row">ファイルが実際にある場所</th>
              <td><code>${fn:escapeXml(targetPath)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="3 通りの書き方はどこを指すか"
             note="いまの配備（ROOT）と、/app に配備した場合を並べています">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th style="width: 18rem;">HTML に書く文字列</th>
              <th>ROOT 配備（いま）</th>
              <th>/app に配備したら</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="link" items="${links}">
              <tr>
                <td>
                  <code>${fn:escapeXml(link.href)}</code>
                  <span class="d-block text-muted small mt-1">${fn:escapeXml(link.description)}</span>
                </td>
                <td class="small ${link.brokenNow ? 'table-danger' : 'table-success'}">
                  <code>${fn:escapeXml(link.resolvedNow)}</code>
                  <span class="d-block mt-1">${link.brokenNow ? '404（ファイルは無い）' : 'ファイルに届く'}</span>
                </td>
                <td class="small ${link.brokenOther ? 'table-danger' : 'table-success'}">
                  <code>${fn:escapeXml(link.resolvedOther)}</code>
                  <span class="d-block mt-1">${link.brokenOther ? '404（ファイルは無い）' : 'ファイルに届く'}</span>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>

      <p class="small text-muted mt-3 mb-2">
        実際に同じ画像を 3 通りの書き方で貼ってみます。読み込めなかったものは枠だけが残ります。
      </p>
      <div class="d-flex flex-wrap">
        <c:forEach var="link" items="${links}">
          <div class="text-center mr-4 mb-2">
            <img src="${fn:escapeXml(link.href)}" alt="読み込めませんでした"
                 width="48" height="48" style="border: 1px solid #ddd; padding: 4px;">
            <span class="d-block small text-muted mt-1" style="max-width: 12rem;">
              ${fn:escapeXml(link.description)}
            </span>
          </div>
        </c:forEach>
      </div>
      <p class="small text-muted mt-2 mb-0">
        ROOT 配備のいまは、真ん中（相対）だけが壊れます。
        <code>/app</code> に置けば、いちばん左（サーバのルートから）も壊れます。
      </p>
    </t:panel>

    <t:panel title="末尾のスラッシュで基準が変わる">
      <p class="small text-muted">
        同じ画面を、末尾スラッシュあり・なしの 2 つの URL で開けるようにしてあります。
        開き直すと、上の表の「相対で書く」の行が変わります。
      </p>
      <p class="mb-0">
        <a class="btn btn-sm btn-outline-primary mr-2" href="${sampleUrl}">
          スラッシュなしで開く
        </a>
        <a class="btn btn-sm btn-outline-primary" href="${sampleUrl}/">
          スラッシュありで開く
        </a>
      </p>
    </t:panel>

    <t:panel title="サーバの中で使うパスには付けない">
      <p class="small text-muted mb-2">
        この画面を出すために Servlet が書いているパスです。
        ブラウザに渡すものではないので、コンテキストパスは付けません。
      </p>
<pre class="code-snippet mb-0">// Servlet → JSP（サーバの中だけの話なので、コンテキストパスは付けない）
request.getRequestDispatcher("/WEB-INF/views/samples/basic/context-path.jsp")
       .forward(request, response);

// ブラウザに「ここへ行き直して」と返すときは付ける
response.sendRedirect(request.getContextPath() + "/samples/basic/context-path");</pre>
    </t:panel>
  </jsp:body>
</t:sample>
