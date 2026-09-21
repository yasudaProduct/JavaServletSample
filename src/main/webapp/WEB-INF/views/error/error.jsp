<%--
  404 / 500 以外の HTTP ステータス (400 / 403 / 405 など) をまとめて受けるエラーページ。

  ステータスコードごとに JSP を作ってもよいのですが、画面の作りが同じなら
  1 枚で受けて、見出しだけをコードで切り替えるほうが保守が楽になります。

  ■ 大事なこと : エラーページはステータスコードを引き継ぎます
    コンテナはこの JSP の出力を、元のステータスコード (400 など) のまま返します。
    「エラーページが表示できた = 200 OK」にはなりません。
    検索エンジンや API の呼び出し元はステータスコードで判断するので、
    ここで response.setStatus(200) のように書き換えてはいけません。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="status" value="${requestScope['javax.servlet.error.status_code']}" />
<%-- ステータスコードごとの文言。当てはまらないものは既定の文言にする --%>
<c:choose>
  <c:when test="${status eq 400}">
    <c:set var="errorTitle" value="リクエストの内容が正しくありません" />
    <c:set var="errorText" value="送信された内容をサーバが解釈できませんでした。入力内容を確認して、もう一度お試しください。" />
  </c:when>
  <c:when test="${status eq 403}">
    <c:set var="errorTitle" value="この操作は許可されていません" />
    <c:set var="errorText" value="必要な権限が無いため、この操作を行えませんでした。" />
  </c:when>
  <c:when test="${status eq 405}">
    <c:set var="errorTitle" value="この方法では呼び出せません" />
    <c:set var="errorText" value="この URL は、送られてきた方法 (GET / POST など) を受け付けていません。" />
  </c:when>
  <c:otherwise>
    <c:set var="errorTitle" value="リクエストを処理できませんでした" />
    <c:set var="errorText" value="時間をおいて、もう一度お試しください。" />
  </c:otherwise>
</c:choose>
<t:layout title="${errorTitle}">
  <div class="error-page">
    <p class="error-page__code">${empty status ? 'エラー' : status}</p>
    <h1 class="error-page__title">${errorTitle}</h1>
    <p class="error-page__text">${errorText}</p>

    <t:errorDetail />

    <a class="btn btn-primary" href="${ctx}/">ホームへ戻る</a>
    <p class="error-page__note">
      このエラーページの仕組みは
      <a href="${ctx}/samples/advanced/error-handling">エラー処理とエラーページ</a>
      のサンプルで解説しています。
    </p>
  </div>
</t:layout>
