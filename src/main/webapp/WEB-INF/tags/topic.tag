<%--
  座学メモ共通の枠組み。
  見出し・パンくず・関連サンプル・前後リンクを自動で作ります。

    <t:topic topicId="request-lifecycle">
      ... 本文 (h2 / p / table / pre で書く) ...
    </t:topic>

  タイトル・説明・関連サンプルは
  com.example.servletsample.catalog.TopicDefinitions の登録内容から取得します。
  サンプルページ (t:sample) と違い、デモもソースコードのタブもありません。
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ attribute name="topicId" required="true" type="java.lang.String" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<%-- カタログからこのメモの情報を取り出す (JSP からも ${topic} で参照できるように request スコープへ) --%>
<c:set var="topic" value="${topics.byId(topicId)}" scope="request" />

<c:choose>
<c:when test="${empty topic}">
  <t:layout title="座学メモが見つかりません">
    <div class="alert alert-danger">
      座学メモ「${fn:escapeXml(topicId)}」がカタログに登録されていません。<br>
      <code>TopicDefinitions.define()</code> に定義を追加してください。
    </div>
  </t:layout>
</c:when>
<c:otherwise>
<t:layout title="${topic.title}" description="${topic.summary}"
          activeNav="topics" activeTopicGroup="${topic.group.id}">

  <jsp:attribute name="breadcrumb">
    <li class="breadcrumb-item"><a href="${ctx}/topics">座学メモ</a></li>
    <li class="breadcrumb-item active" aria-current="page">${fn:escapeXml(topic.title)}</li>
  </jsp:attribute>

  <jsp:body>
    <%-- ---------------- 見出し ---------------- --%>
    <div class="page-header">
      <div class="page-header__meta">
        <a class="badge badge-topic" href="${ctx}/topics#${topic.group.id}">
          <t:icon name="${topic.group.icon}" size="12" cssClass="mr-1" />${fn:escapeXml(topic.group.label)}
        </a>
        <span class="topic-reading">
          <t:icon name="book" size="12" cssClass="mr-1" />読むだけ・約 ${topic.readingMinutes} 分
        </span>
        <c:if test="${topic.status ne 'READY'}">
          <span class="badge badge-${topic.status.variant}">${topic.status.label}</span>
        </c:if>
      </div>
      <h1 class="page-header__title">${fn:escapeXml(topic.title)}</h1>
      <p class="page-header__lead">${fn:escapeXml(topic.summary)}</p>
      <c:if test="${not empty topic.tags}">
        <ul class="tag-list">
          <c:forEach var="tag" items="${topic.tags}">
            <li><a href="${ctx}/search?q=${fn:escapeXml(tag)}">#${fn:escapeXml(tag)}</a></li>
          </c:forEach>
        </ul>
      </c:if>
    </div>

    <%-- ---------------- 本文 ---------------- --%>
    <article class="doc-body topic-body">
      <jsp:doBody />
    </article>

    <%-- ---------------- 関連サンプル ---------------- --%>
    <c:set var="relatedSamples" value="${topic.relatedSamples}" />
    <c:if test="${not empty relatedSamples}">
      <section class="section">
        <h2 class="section__title">
          <t:icon name="grid" cssClass="section__icon" />読んだあとに触ってみる
        </h2>
        <p class="text-muted small mb-3">ここまでの話が実際に動く形で置いてあるサンプルです。</p>
        <div class="row">
          <c:forEach var="sample" items="${relatedSamples}">
            <t:sampleCard sample="${sample}" columnClass="col-md-6 col-xl-4" />
          </c:forEach>
        </div>
      </section>
    </c:if>

    <%-- ---------------- 前後のメモ ---------------- --%>
    <c:set var="prevTopic" value="${topics.previous(topic)}" />
    <c:set var="nextTopic" value="${topics.next(topic)}" />
    <c:if test="${not empty prevTopic or not empty nextTopic}">
      <nav class="sample-pager" aria-label="前後の座学メモ">
        <div class="sample-pager__side">
          <c:if test="${not empty prevTopic}">
            <a class="sample-pager__link" href="${ctx}${prevTopic.path}">
              <span class="sample-pager__label">← 前のメモ</span>
              <span class="sample-pager__title">${fn:escapeXml(prevTopic.title)}</span>
            </a>
          </c:if>
        </div>
        <div class="sample-pager__side sample-pager__side--right">
          <c:if test="${not empty nextTopic}">
            <a class="sample-pager__link" href="${ctx}${nextTopic.path}">
              <span class="sample-pager__label">次のメモ →</span>
              <span class="sample-pager__title">${fn:escapeXml(nextTopic.title)}</span>
            </a>
          </c:if>
        </div>
      </nav>
    </c:if>
  </jsp:body>
</t:layout>
</c:otherwise>
</c:choose>
