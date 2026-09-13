<%--
  カテゴリ別のサンプル一覧。
  CategoryServlet が ${category} と ${samples} をセットします。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="${category.label}" description="${category.description}" activeCategory="${category.id}">

  <jsp:attribute name="breadcrumb">
    <li class="breadcrumb-item active" aria-current="page">${fn:escapeXml(category.label)}</li>
  </jsp:attribute>

  <jsp:body>
    <div class="page-header">
      <div class="page-header__meta">
        <span class="badge badge-category">
          <t:icon name="${category.icon}" size="12" cssClass="mr-1" />カテゴリ
        </span>
      </div>
      <h1 class="page-header__title">${fn:escapeXml(category.label)}</h1>
      <p class="page-header__lead">${fn:escapeXml(category.description)}</p>
    </div>

    <c:choose>
      <c:when test="${empty samples}">
        <div class="empty-state">
          <t:icon name="lightbulb" size="32" cssClass="empty-state__icon" />
          <p class="empty-state__text">このカテゴリのサンプルはまだありません。</p>
          <a class="btn btn-outline-primary btn-sm" href="${ctx}/">ホームへ戻る</a>
        </div>
      </c:when>
      <c:otherwise>
        <p class="list-count">${fn:length(samples)} 件</p>
        <div class="row">
          <c:forEach var="sample" items="${samples}">
            <t:sampleCard sample="${sample}" showCategory="false" columnClass="col-md-6 col-xl-4" />
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>
  </jsp:body>
</t:layout>
