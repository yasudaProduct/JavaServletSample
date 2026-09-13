<%--
  サンプル 1 件分のカード。一覧系の画面 (トップ / カテゴリ / 検索) で共通利用します。

    <t:sampleCard sample="${sample}" />
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" body-content="empty" %>
<%@ attribute name="sample" required="true" type="com.example.servletsample.catalog.Sample" %>
<%@ attribute name="columnClass" type="java.lang.String" %>
<%@ attribute name="showCategory" type="java.lang.Boolean" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<div class="${empty columnClass ? 'col-md-6 col-xl-4' : columnClass} mb-4">
  <div class="card sample-card h-100 ${sample.visitable ? '' : 'sample-card--planned'}">
    <div class="card-body">
      <div class="sample-card__meta">
        <c:if test="${empty showCategory or showCategory}">
          <span class="badge badge-category">
            <t:icon name="${sample.category.icon}" size="12" cssClass="mr-1" />${sample.category.label}
          </span>
        </c:if>
        <c:if test="${sample.status ne 'READY'}">
          <span class="badge badge-${sample.status.variant}">${sample.status.label}</span>
        </c:if>
      </div>

      <h3 class="sample-card__title">
        <c:choose>
          <c:when test="${sample.visitable}">
            <a href="${ctx}${sample.path}" class="stretched-link">${fn:escapeXml(sample.title)}</a>
          </c:when>
          <c:otherwise>${fn:escapeXml(sample.title)}</c:otherwise>
        </c:choose>
      </h3>

      <p class="sample-card__summary">${fn:escapeXml(sample.summary)}</p>

      <c:if test="${not empty sample.tags}">
        <ul class="tag-list tag-list--sm">
          <c:forEach var="tag" items="${sample.tags}" end="3">
            <li>#${fn:escapeXml(tag)}</li>
          </c:forEach>
        </ul>
      </c:if>
    </div>
  </div>
</div>
