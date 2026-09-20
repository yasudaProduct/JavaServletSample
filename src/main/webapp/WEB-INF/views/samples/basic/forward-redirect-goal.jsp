<%--
  サンプル「forward と redirect の違い」の遷移先。

  forward 版  : ForwardRedirectServlet#doPost が POST のままこの JSP へ処理を渡す
  redirect 版 : ForwardRedirectGoalServlet#doGet (ブラウザが改めて GET したもの) が渡す

  どちらの経路で来たかを ${arrivedBy} で受け取り、
  URL・リクエストスコープ・forward の目印がどう変わるかを並べて表示します。

  サンプル本体ではないので t:sample ではなく t:layout を使っています
  (タブやソース表示が付かない、普通の画面)。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="samplePath" value="${ctx}/samples/basic/forward-redirect" />

<%-- 来た経路 (Servlet が入れた目印)。直接開かれたときは redirect 扱いになる --%>
<c:set var="byForward" value="${arrivedBy eq 'forward'}" />

<%-- ブラウザのアドレスバーに出ている URL。
     この JSP は必ず forward されて動くので、元の URL は forward の目印から取れる。 --%>
<c:set var="forwardUri" value="${requestScope['javax.servlet.forward.request_uri']}" />
<c:set var="browserUri" value="${empty forwardUri ? pageContext.request.requestURI : forwardUri}" />
<c:set var="browserQuery" value="${requestScope['javax.servlet.forward.query_string']}" />
<c:set var="browserUrl" value="${browserUri}${empty browserQuery ? '' : '?'}${browserQuery}" />

<%-- 表示する値。forward 版はリクエストスコープ、redirect 版はクエリ文字列から取る --%>
<c:set var="displayReceipt" value="${empty receiptNumber ? param.receipt : receiptNumber}" />
<c:set var="displayName" value="${empty orderName ? param.name : orderName}" />

<%-- 受付番号がまったく無いのは、サンプルを通さずにこの URL を直接開かれたとき。
     この場合は POST も redirect も起きていないので、経路の説明は出さない。 --%>
<c:set var="direct" value="${empty displayReceipt}" />
<c:set var="pageTitle" value="${direct ? 'forward と redirect の違い : 遷移先' : '注文を受け付けました'}" />

<t:layout title="${pageTitle}"
          description="forward と redirect の違いを確かめるための遷移先の画面"
          activeCategory="basic">

  <jsp:attribute name="breadcrumb">
    <li class="breadcrumb-item"><a href="${ctx}/categories/basic">基本</a></li>
    <li class="breadcrumb-item"><a href="${samplePath}">forward と redirect の違い</a></li>
    <li class="breadcrumb-item active" aria-current="page">遷移先</li>
  </jsp:attribute>

  <jsp:body>
    <div class="page-header">
      <div class="page-header__meta">
        <c:choose>
          <c:when test="${direct}">
            <span class="badge badge-secondary">サンプルの遷移先</span>
          </c:when>
          <c:when test="${byForward}">
            <span class="badge badge-primary">forward で来ました</span>
          </c:when>
          <c:otherwise>
            <span class="badge badge-info">redirect で来ました</span>
          </c:otherwise>
        </c:choose>
      </div>
      <h1 class="page-header__title">${fn:escapeXml(pageTitle)}</h1>
      <p class="page-header__lead">
        <c:choose>
          <c:when test="${direct}">
            この画面はサンプルの遷移先です。サンプルのボタンから実行すると、
            forward で来たのか redirect で来たのかによって何が変わるかを表示します。
          </c:when>
          <c:when test="${byForward}">
            POST を受けた Servlet が、<strong>サーバの中で</strong>この画面へ処理を渡しました。
            ブラウザから見ると、まだ最初の POST が続いています。
          </c:when>
          <c:otherwise>
            POST を受けた Servlet は 302 を返しただけで、
            <strong>ブラウザが改めて</strong>この URL を GET しました。
            さきほどの POST とは別のリクエストです。
          </c:otherwise>
        </c:choose>
      </p>
    </div>

    <%-- ============================================================
         受け付けた内容
         ============================================================ --%>
    <c:choose>
      <c:when test="${direct}">
        <div class="alert alert-warning">
          受付番号がありません。この画面は
          <a href="${samplePath}">forward と redirect の違い</a>
          のサンプルから送信したときの遷移先です。サンプルへ戻って実行してみてください。
        </div>
      </c:when>
      <c:otherwise>
        <div class="demo-panel">
          <div class="demo-panel__head">
            <span class="demo-panel__title">受け付けた内容</span>
            <span class="demo-panel__note">受付番号は POST を処理した Servlet が採番しました</span>
          </div>
          <div class="demo-panel__body">
            <p class="mb-1">
              <t:icon name="check-circle" cssClass="text-success mr-2" />
              <strong>${fn:escapeXml(displayName)}</strong> さんの注文を受け付けました。
            </p>
            <p class="mb-0">
              受付番号: <code>${fn:escapeXml(displayReceipt)}</code>
            </p>
          </div>
        </div>
      </c:otherwise>
    </c:choose>

    <%-- ============================================================
         経路によって何が変わったか
         (直接この URL を開かれたときは forward / redirect のどちらも通っていないので出さない)
         ============================================================ --%>
    <c:if test="${not direct}">
    <div class="demo-panel">
      <div class="demo-panel__head">
        <span class="demo-panel__title">この画面に届いたリクエストの中身</span>
        <span class="demo-panel__note">forward 版と redirect 版で見比べてください</span>
      </div>
      <div class="demo-panel__body">
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-0">
            <tbody>
              <tr>
                <th scope="row" class="w-25">この画面に来た方法</th>
                <td>
                  <c:choose>
                    <c:when test="${byForward}">
                      <code>forward</code>
                      <span class="d-block text-muted small mt-1">
                        POST を処理した Servlet が
                        <code>/WEB-INF/views/samples/basic/forward-redirect-goal.jsp</code>
                        へ直接処理を渡しました。ブラウザは転送に気付いていません。
                      </span>
                    </c:when>
                    <c:otherwise>
                      <code>sendRedirect</code>（302 → ブラウザが改めて GET）
                      <span class="d-block text-muted small mt-1">
                        <code>ForwardRedirectGoalServlet</code> が受け取り、
                        同じ JSP へ forward して表示しています。
                      </span>
                    </c:otherwise>
                  </c:choose>
                </td>
              </tr>
              <tr class="${byForward ? 'table-warning' : 'table-success'}">
                <th scope="row">アドレスバーの URL</th>
                <td>
                  <code>${fn:escapeXml(browserUrl)}</code>
                  <span class="d-block text-muted small mt-1">
                    <c:choose>
                      <c:when test="${byForward}">
                        POST 先の URL のままです。画面の中身は遷移先なのに URL は変わりません。
                      </c:when>
                      <c:otherwise>
                        遷移先の URL に変わりました。再読み込みしても GET が繰り返されるだけです。
                      </c:otherwise>
                    </c:choose>
                  </span>
                </td>
              </tr>
              <tr>
                <th scope="row">HTTP メソッド</th>
                <td>
                  <code>${fn:escapeXml(pageContext.request.method)}</code>
                  <span class="d-block text-muted small mt-1">
                    <c:choose>
                      <c:when test="${byForward}">
                        POST のままなので、再読み込みすると「再送信しますか？」と聞かれます。
                      </c:when>
                      <c:otherwise>
                        POST が GET に変わりました。これが PRG パターンの効き目です。
                      </c:otherwise>
                    </c:choose>
                  </span>
                </td>
              </tr>
              <tr class="${byForward ? 'table-success' : 'table-warning'}">
                <th scope="row">
                  リクエストスコープの受付番号<br>
                  <code class="small">${'${receiptNumber}'}</code>
                </th>
                <td>
                  <c:choose>
                    <c:when test="${empty receiptNumber}">
                      <span class="badge badge-warning">空</span>
                      <span class="d-block text-muted small mt-1">
                        POST の処理で <code>setAttribute</code> した値は、
                        リダイレクトで<strong>別のリクエストになった時点で消えます</strong>。
                      </span>
                    </c:when>
                    <c:otherwise>
                      <code>${fn:escapeXml(receiptNumber)}</code>
                      <span class="badge badge-success ml-2">残っている</span>
                      <span class="d-block text-muted small mt-1">
                        forward は同じリクエストが続いているので、
                        <code>setAttribute</code> した値がそのまま届きます。
                      </span>
                    </c:otherwise>
                  </c:choose>
                </td>
              </tr>
              <tr>
                <th scope="row">
                  クエリ文字列の受付番号<br>
                  <code class="small">${'${param.receipt}'}</code>
                </th>
                <td>
                  <c:choose>
                    <c:when test="${empty param.receipt}">
                      <span class="badge badge-secondary">無し</span>
                      <span class="d-block text-muted small mt-1">
                        forward ではリクエストスコープで渡せるので、URL に載せる必要がありません。
                      </span>
                    </c:when>
                    <c:otherwise>
                      <code>${fn:escapeXml(param.receipt)}</code>
                      <span class="d-block text-muted small mt-1">
                        リクエストスコープが使えないので、遷移先へ渡したい値は
                        URL のクエリ文字列（またはセッション）に載せています。
                      </span>
                    </c:otherwise>
                  </c:choose>
                </td>
              </tr>
              <tr>
                <th scope="row">
                  forward の目印<br>
                  <code class="small">javax.servlet.forward.request_uri</code>
                </th>
                <td>
                  <c:choose>
                    <c:when test="${empty forwardUri}">
                      <span class="badge badge-secondary">無し</span>
                      <span class="d-block text-muted small mt-1">
                        forward されずに直接表示された、ということになります。
                      </span>
                    </c:when>
                    <c:otherwise>
                      <code>${fn:escapeXml(forwardUri)}</code>
                      <span class="d-block text-muted small mt-1">
                        <strong>ブラウザが要求した URL</strong> が入っています。
                        <c:choose>
                          <c:when test="${byForward}">
                            POST 先の URL なのは、そこから forward でここへ来たためです。
                          </c:when>
                          <c:otherwise>
                            この画面の URL なのは、ブラウザがここを GET したあと、
                            <code>ForwardRedirectGoalServlet</code> が JSP へ forward したためです。
                            <strong>リダイレクトの前後はつながっていません。</strong>
                          </c:otherwise>
                        </c:choose>
                      </span>
                    </c:otherwise>
                  </c:choose>
                </td>
              </tr>
              <tr>
                <th scope="row">
                  いま実行中の JSP<br>
                  <code class="small">getRequestURI()</code>
                </th>
                <td>
                  <code>${fn:escapeXml(pageContext.request.requestURI)}</code>
                  <span class="d-block text-muted small mt-1">
                    forward したあとは<strong>転送先</strong>が返ります。
                    ブラウザが叩いた URL とは別物です。
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <%-- ============================================================
         ここで試せること
         ============================================================ --%>
    <div class="alert alert-info">
      <p class="mb-2"><strong>この画面で試してみてください</strong></p>
      <ul class="mb-0 pl-4">
        <li>
          <strong>再読み込み（F5）</strong>：
          <c:choose>
            <c:when test="${byForward}">
              「フォームを再送信しますか？」と聞かれます。
              「はい」を選ぶと注文がもう一度入ってしまいます。
            </c:when>
            <c:otherwise>
              何も聞かれません。GET を繰り返すだけなので、注文が増えることもありません。
            </c:otherwise>
          </c:choose>
        </li>
        <li>
          <strong>ブラウザの「戻る」と「進む」</strong>：
          <c:choose>
            <c:when test="${byForward}">
              「戻る」でフォームを送信する前の画面に戻ります。そこから「進む」でここへ戻ろうとすると、
              履歴に残っているのが POST なので再送信の確認が出ます。
            </c:when>
            <c:otherwise>
              「戻る」でサンプル画面に戻ります。履歴に残っているのはこの画面の GET なので、
              「進む」で戻ってきても何も聞かれません。
            </c:otherwise>
          </c:choose>
        </li>
        <li>
          <strong>もう一方のボタンでも実行する</strong>：
          サンプルへ戻って、
          <c:out value="${byForward ? 'redirect' : 'forward'}" /> のボタンを押すと違いが分かります。
        </li>
      </ul>
    </div>
    </c:if>

    <p class="mb-0">
      <a class="btn btn-outline-primary" href="${samplePath}">
        <t:icon name="chevron-right" size="14" cssClass="mr-1" />サンプルへ戻る
      </a>
    </p>
  </jsp:body>
</t:layout>
