<%--
  エラーページで「何が起きたか」を表示する枠。

    <t:errorDetail />

  コンテナはエラーページへ転送するとき、リクエストスコープに javax.servlet.error.* という
  属性を入れてくれます。このタグはそれを読んで表にするだけのものです。

  ┌ javax.servlet.error.status_code    … HTTP のステータスコード (Integer)
  ├ javax.servlet.error.message        … sendError の第 2 引数、または例外のメッセージ
  ├ javax.servlet.error.exception_type … 例外の型 (Class)
  ├ javax.servlet.error.exception      … 例外そのもの (Throwable)
  ├ javax.servlet.error.request_uri    … エラーが起きた URL (エラーページ自身の URL ではない)
  └ javax.servlet.error.servlet_name   … エラーが起きた Servlet の名前

  ※ このサンプル集は「何が起きたか」を学ぶ場なので例外の中身まで表示しています。
     本番環境では、利用者に見せるのは問い合わせ番号程度にとどめ、
     例外の内容はサーバのログにだけ残すのが一般的です。
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" body-content="empty" %>
<%@ attribute name="title" type="java.lang.String" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="errStatus" value="${requestScope['javax.servlet.error.status_code']}" />
<c:set var="errMessage" value="${requestScope['javax.servlet.error.message']}" />
<c:set var="errType" value="${requestScope['javax.servlet.error.exception_type']}" />
<c:set var="errException" value="${requestScope['javax.servlet.error.exception']}" />
<c:set var="errUri" value="${requestScope['javax.servlet.error.request_uri']}" />
<c:set var="errServlet" value="${requestScope['javax.servlet.error.servlet_name']}" />
<%-- どれか 1 つでも入っていれば、コンテナがエラーページとして呼んだということ --%>
<c:if test="${not empty errStatus or not empty errException or not empty errUri}">
  <div class="error-page__detail">
    <p class="error-page__detail-title">
      ${fn:escapeXml(empty title ? 'コンテナが渡してくれた情報 (javax.servlet.error.*)' : title)}
    </p>
    <table class="table table-sm mb-0 error-detail-table">
      <tbody>
        <c:if test="${not empty errStatus}">
          <tr>
            <th scope="row"><code>status_code</code></th>
            <td>${fn:escapeXml(errStatus)}</td>
          </tr>
        </c:if>
        <c:if test="${not empty errMessage}">
          <tr>
            <th scope="row"><code>message</code></th>
            <td>${fn:escapeXml(errMessage)}</td>
          </tr>
        </c:if>
        <c:if test="${not empty errUri}">
          <tr>
            <th scope="row"><code>request_uri</code></th>
            <td><code>${fn:escapeXml(errUri)}</code></td>
          </tr>
        </c:if>
        <c:if test="${not empty errServlet}">
          <tr>
            <th scope="row"><code>servlet_name</code></th>
            <td>${fn:escapeXml(errServlet)}</td>
          </tr>
        </c:if>
        <c:if test="${not empty errType}">
          <tr>
            <th scope="row"><code>exception_type</code></th>
            <td><code>${fn:escapeXml(errType.name)}</code></td>
          </tr>
        </c:if>
        <c:if test="${not empty errException}">
          <tr>
            <th scope="row"><code>exception</code></th>
            <td>
              <code>${fn:escapeXml(errException['class'].name)}</code>:
              ${fn:escapeXml(errException.message)}
              <%-- 原因つきの例外は、元の例外までたどれることが大事 --%>
              <c:if test="${not empty errException.cause}">
                <div class="mt-1 text-muted">
                  原因 (cause):
                  <code>${fn:escapeXml(errException.cause['class'].name)}</code>:
                  ${fn:escapeXml(errException.cause.message)}
                </div>
              </c:if>
            </td>
          </tr>
        </c:if>
      </tbody>
    </table>
  </div>
</c:if>
