<%--
  検索結果。SearchServlet が ${keyword} と ${results} をセットします。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="検索結果">

  <jsp:attribute name="breadcrumb">
    <li class="breadcrumb-item active" aria-current="page">検索結果</li>
  </jsp:attribute>

  <jsp:body>
    <div class="page-header">
      <h1 class="page-header__title">検索結果</h1>
      <p class="page-header__lead">
        <c:choose>
          <c:when test="${empty keyword}">キーワードを入力すると、タイトル・説明・タグから検索します。</c:when>
          <c:otherwise>「<strong>${fn:escapeXml(keyword)}</strong>」の検索結果</c:otherwise>
        </c:choose>
      </p>
      <form class="search-form" action="${ctx}/search" method="get" role="search">
        <div class="input-group">
          <input type="search" class="form-control" name="q" value="${fn:escapeXml(keyword)}"
                 placeholder="キーワードを入力" aria-label="サンプルを検索">
          <div class="input-group-append">
            <button class="btn btn-primary" type="submit">
              <t:icon name="search" cssClass="mr-1" />検索
            </button>
          </div>
        </div>
      </form>
    </div>

    <c:choose>
      <c:when test="${empty results}">
        <div class="empty-state">
          <t:icon name="search" size="32" cssClass="empty-state__icon" />
          <p class="empty-state__text">一致するサンプルが見つかりませんでした。</p>
          <a class="btn btn-outline-primary btn-sm" href="${ctx}/">ホームへ戻る</a>
        </div>
      </c:when>
      <c:otherwise>
        <p class="list-count">${fn:length(results)} 件</p>
        <div class="row">
          <c:forEach var="sample" items="${results}">
            <t:sampleCard sample="${sample}" />
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>
  </jsp:body>
</t:layout>
