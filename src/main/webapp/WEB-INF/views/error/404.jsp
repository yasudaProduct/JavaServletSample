<%-- 404 (ページが見つからない) 用のエラーページ。web.xml の <error-page> から呼ばれます。 --%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="ページが見つかりません">
  <div class="error-page">
    <p class="error-page__code">404</p>
    <h1 class="error-page__title">ページが見つかりません</h1>
    <p class="error-page__text">
      お探しのページは移動または削除された可能性があります。
    </p>

    <t:errorDetail />

    <a class="btn btn-primary" href="${ctx}/">ホームへ戻る</a>
    <p class="error-page__note">
      このエラーページの仕組みは
      <a href="${ctx}/samples/advanced/error-handling">エラー処理とエラーページ</a>
      のサンプルで解説しています。
    </p>
  </div>
</t:layout>
