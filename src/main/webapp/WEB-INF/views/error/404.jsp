<%-- 404 (ページが見つからない) 用のエラーページ。web.xml の <error-page> から呼ばれます。 --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="ページが見つかりません">
  <div class="error-page">
    <p class="error-page__code">404</p>
    <h1 class="error-page__title">ページが見つかりません</h1>
    <p class="error-page__text">
      お探しのページは移動または削除された可能性があります。
      <c:if test="${not empty requestScope['javax.servlet.error.request_uri']}">
        <br><code>${fn:escapeXml(requestScope['javax.servlet.error.request_uri'])}</code>
      </c:if>
    </p>
    <a class="btn btn-primary" href="${ctx}/">ホームへ戻る</a>
  </div>
</t:layout>
