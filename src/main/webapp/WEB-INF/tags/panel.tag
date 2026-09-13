<%--
  サンプルページの中で使う、見出し付きの枠。

    <t:panel title="入力フォーム">
      ... 中身 ...
    </t:panel>
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ attribute name="title" type="java.lang.String" %>
<%@ attribute name="note" type="java.lang.String" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<div class="demo-panel">
  <c:if test="${not empty title}">
    <div class="demo-panel__head">
      <span class="demo-panel__title">${fn:escapeXml(title)}</span>
      <c:if test="${not empty note}"><span class="demo-panel__note">${fn:escapeXml(note)}</span></c:if>
    </div>
  </c:if>
  <div class="demo-panel__body">
    <jsp:doBody />
  </div>
</div>
