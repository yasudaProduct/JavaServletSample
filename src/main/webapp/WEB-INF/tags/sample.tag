<%--
  サンプルページ共通の枠組み。
  「デモ / ソースコード / 解説」のタブと、前後のサンプルへのリンクを自動で作ります。

    <t:sample sampleId="hello-world">
      <jsp:attribute name="explanation"> 解説の HTML </jsp:attribute>
      <jsp:body> デモの HTML </jsp:body>
    </t:sample>

  タイトル・説明・ソースファイルの一覧は
  com.example.servletsample.catalog.SampleDefinitions の登録内容から取得します。
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ attribute name="sampleId" required="true" type="java.lang.String" %>
<%@ attribute name="explanation" fragment="true" %>
<%@ attribute name="head" fragment="true" %>
<%@ attribute name="scripts" fragment="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="site" uri="http://example.com/jsp/servlet-sample" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<%-- カタログからこのサンプルの情報を取り出す (JSP からも ${sample} で参照できるように request スコープへ) --%>
<c:set var="sample" value="${catalog.byId(sampleId)}" scope="request" />

<c:choose>
<c:when test="${empty sample}">
  <t:layout title="サンプルが見つかりません">
    <div class="alert alert-danger">
      サンプル「${fn:escapeXml(sampleId)}」がカタログに登録されていません。<br>
      <code>SampleDefinitions.define()</code> に定義を追加してください。
    </div>
  </t:layout>
</c:when>
<c:otherwise>
<t:layout title="${sample.title}" description="${sample.summary}" activeCategory="${sample.category.id}">

  <jsp:attribute name="breadcrumb">
    <li class="breadcrumb-item">
      <a href="${ctx}/categories/${sample.category.id}">${fn:escapeXml(sample.category.label)}</a>
    </li>
    <li class="breadcrumb-item active" aria-current="page">${fn:escapeXml(sample.title)}</li>
  </jsp:attribute>

  <jsp:attribute name="head">
    <c:if test="${not empty head}"><jsp:invoke fragment="head" /></c:if>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <c:if test="${not empty scripts}"><jsp:invoke fragment="scripts" /></c:if>
  </jsp:attribute>

  <jsp:body>
    <%-- ---------------- 見出し ---------------- --%>
    <div class="page-header">
      <div class="page-header__meta">
        <a class="badge badge-category" href="${ctx}/categories/${sample.category.id}">
          <t:icon name="${sample.category.icon}" size="12" cssClass="mr-1" />${fn:escapeXml(sample.category.label)}
        </a>
        <c:if test="${sample.status ne 'READY'}">
          <span class="badge badge-${sample.status.variant}">${sample.status.label}</span>
        </c:if>
      </div>
      <h1 class="page-header__title">${fn:escapeXml(sample.title)}</h1>
      <p class="page-header__lead">${fn:escapeXml(sample.summary)}</p>
      <c:if test="${not empty sample.tags}">
        <ul class="tag-list">
          <c:forEach var="tag" items="${sample.tags}">
            <li><a href="${ctx}/search?q=${fn:escapeXml(tag)}">#${fn:escapeXml(tag)}</a></li>
          </c:forEach>
        </ul>
      </c:if>
    </div>

    <%-- ---------------- タブ ---------------- --%>
    <ul class="nav nav-tabs sample-tabs" id="sampleTab" role="tablist">
      <li class="nav-item">
        <a class="nav-link active" id="tab-demo" data-toggle="tab" href="#pane-demo"
           role="tab" aria-controls="pane-demo" aria-selected="true">
          <t:icon name="grid" size="14" cssClass="mr-1" />デモ
        </a>
      </li>
      <li class="nav-item">
        <a class="nav-link" id="tab-code" data-toggle="tab" href="#pane-code"
           role="tab" aria-controls="pane-code" aria-selected="false">
          <t:icon name="code-slash" size="14" cssClass="mr-1" />ソースコード
          <span class="sample-tabs__count">${fn:length(sample.sources)}</span>
        </a>
      </li>
      <c:if test="${not empty explanation}">
        <li class="nav-item">
          <a class="nav-link" id="tab-note" data-toggle="tab" href="#pane-note"
             role="tab" aria-controls="pane-note" aria-selected="false">
            <t:icon name="lightbulb" size="14" cssClass="mr-1" />解説
          </a>
        </li>
      </c:if>
    </ul>

    <div class="tab-content sample-panes">
      <%-- デモ : サンプル本体 --%>
      <div class="tab-pane fade show active" id="pane-demo" role="tabpanel" aria-labelledby="tab-demo">
        <div class="demo-area">
          <jsp:doBody />
        </div>
      </div>

      <%-- ソースコード : カタログに登録されたファイルを順番に表示 --%>
      <div class="tab-pane fade" id="pane-code" role="tabpanel" aria-labelledby="tab-code">
        <c:forEach var="source" items="${sample.sources}">
          <site:source path="${source.path}" label="${source.label}" language="${source.language}" />
        </c:forEach>
      </div>

      <%-- 解説 --%>
      <c:if test="${not empty explanation}">
        <div class="tab-pane fade" id="pane-note" role="tabpanel" aria-labelledby="tab-note">
          <div class="sample-note">
            <jsp:invoke fragment="explanation" />
          </div>
        </div>
      </c:if>
    </div>

    <%-- ---------------- 前後のサンプル ---------------- --%>
    <c:set var="prevSample" value="${catalog.previous(sample)}" />
    <c:set var="nextSample" value="${catalog.next(sample)}" />
    <c:if test="${not empty prevSample or not empty nextSample}">
      <nav class="sample-pager" aria-label="前後のサンプル">
        <div class="sample-pager__side">
          <c:if test="${not empty prevSample}">
            <a class="sample-pager__link" href="${ctx}${prevSample.path}">
              <span class="sample-pager__label">← 前のサンプル</span>
              <span class="sample-pager__title">${fn:escapeXml(prevSample.title)}</span>
            </a>
          </c:if>
        </div>
        <div class="sample-pager__side sample-pager__side--right">
          <c:if test="${not empty nextSample}">
            <a class="sample-pager__link" href="${ctx}${nextSample.path}">
              <span class="sample-pager__label">次のサンプル →</span>
              <span class="sample-pager__title">${fn:escapeXml(nextSample.title)}</span>
            </a>
          </c:if>
        </div>
      </nav>
    </c:if>
  </jsp:body>
</t:layout>
</c:otherwise>
</c:choose>
