<%--
  座学メモ 1 件分のカード。一覧系の画面 (座学メモ一覧 / 検索) で共通利用します。

    <t:topicCard topic="${topic}" />
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" body-content="empty" %>
<%@ attribute name="topic" required="true" type="com.example.servletsample.catalog.Topic" %>
<%@ attribute name="columnClass" type="java.lang.String" %>
<%@ attribute name="showGroup" type="java.lang.Boolean" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<div class="${empty columnClass ? 'col-md-6 col-xl-4' : columnClass} mb-4">
  <div class="card sample-card topic-card h-100 ${topic.visitable ? '' : 'sample-card--planned'}">
    <div class="card-body">
      <div class="sample-card__meta">
        <c:if test="${empty showGroup or showGroup}">
          <span class="badge badge-topic">
            <t:icon name="${topic.group.icon}" size="12" cssClass="mr-1" />${topic.group.label}
          </span>
        </c:if>
        <span class="topic-reading">約 ${topic.readingMinutes} 分</span>
        <c:if test="${topic.status ne 'READY'}">
          <span class="badge badge-${topic.status.variant}">${topic.status.label}</span>
        </c:if>
      </div>

      <h3 class="sample-card__title">
        <c:choose>
          <c:when test="${topic.visitable}">
            <a href="${ctx}${topic.path}" class="stretched-link">${fn:escapeXml(topic.title)}</a>
          </c:when>
          <c:otherwise>${fn:escapeXml(topic.title)}</c:otherwise>
        </c:choose>
      </h3>

      <p class="sample-card__summary">${fn:escapeXml(topic.summary)}</p>

      <c:if test="${not empty topic.tags}">
        <ul class="tag-list tag-list--sm">
          <c:forEach var="tag" items="${topic.tags}" end="3">
            <li>#${fn:escapeXml(tag)}</li>
          </c:forEach>
        </ul>
      </c:if>
    </div>
  </div>
</div>
