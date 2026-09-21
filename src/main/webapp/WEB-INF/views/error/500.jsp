<%--
  500 (サーバ内部エラー) 用のエラーページ。
  web.xml の <error-code>500</error-code> と <exception-type>java.lang.Throwable</exception-type>
  の両方から呼ばれます。

  isErrorPage="true" にすると ${pageContext.exception} で例外を参照できます。
  ただし web.xml から呼ばれる場合は requestScope['javax.servlet.error.exception'] にも入るため、
  このページでは <t:errorDetail> でまとめて表示しています。

  ■ エラーページで気をつけること
    - エラーページ自身でエラーを起こさないこと (無限に入れ子にならないよう、処理は最小限に)
    - 利用者に見せてよい情報だけを出すこと (本番では例外の中身は見せない)
    - 画面の途中で送信が始まっていると差し替えられないこと
      → web.xml の <jsp-property-group> でバッファを 64kb に広げています
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="エラーが発生しました">
  <div class="error-page">
    <p class="error-page__code">500</p>
    <h1 class="error-page__title">エラーが発生しました</h1>
    <p class="error-page__text">
      処理中に問題が発生しました。時間をおいて再度お試しください。
    </p>

    <%-- サンプル集なので、原因が分かるように例外の概要も表示しています。
         （本番環境では利用者に例外を見せないのが一般的です） --%>
    <t:errorDetail />

    <a class="btn btn-primary" href="${ctx}/">ホームへ戻る</a>
    <p class="error-page__note">
      このエラーページの仕組みは
      <a href="${ctx}/samples/advanced/error-handling">エラー処理とエラーページ</a>
      のサンプルで解説しています。
    </p>
  </div>
</t:layout>
