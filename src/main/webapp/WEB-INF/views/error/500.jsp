<%--
  500 (サーバ内部エラー) 用のエラーページ。
  isErrorPage="true" にすると ${pageContext.exception} で例外を参照できます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="errorException" value="${requestScope['javax.servlet.error.exception']}" />
<t:layout title="エラーが発生しました">
  <div class="error-page">
    <p class="error-page__code">500</p>
    <h1 class="error-page__title">エラーが発生しました</h1>
    <p class="error-page__text">
      処理中に問題が発生しました。時間をおいて再度お試しください。
    </p>

    <%-- サンプル集なので、原因が分かるように例外の概要も表示しています。
         （本番環境では利用者に例外を見せないのが一般的です） --%>
    <c:if test="${not empty errorException}">
      <div class="error-page__detail">
        <p class="error-page__detail-title">例外の内容</p>
        <pre>${fn:escapeXml(errorException['class'].name)}: ${fn:escapeXml(errorException.message)}</pre>
      </div>
    </c:if>

    <a class="btn btn-primary" href="${ctx}/">ホームへ戻る</a>
  </div>
</t:layout>
