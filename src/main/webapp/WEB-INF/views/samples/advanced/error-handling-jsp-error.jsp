<%--
  【サンプル】JSP の中で例外が起きたとき (その 2 : 受け止める側)

  isErrorPage="true" を付けた JSP は「エラーページ」になり、
  暗黙オブジェクト exception (EL からは ${pageContext.exception}) が使えます。

  ■ 気をつけること
    ・isErrorPage="true" の JSP は、ブラウザから直接開かせてはいけません。
      このサイトはすべての JSP を /WEB-INF/ の下に置いているので、その心配はありません。
    ・errorPage 属性で呼ばれた場合、ステータスコードは 200 のままです。
      「画面にはエラーと書いてあるのに、機械には成功と伝わる」状態になるため、
      ここで 500 に直しています (web.xml の <error-page> 経由なら元のコードが引き継がれます)。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<% response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR); %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="集計に失敗しました">
  <div class="error-page">
    <p class="error-page__code">500</p>
    <h1 class="error-page__title">集計に失敗しました</h1>
    <p class="error-page__text">
      この画面は <code>&lt;%@ page errorPage="..." %&gt;</code> で指定された、
      その JSP 専用のエラーページです。
    </p>

    <div class="error-page__detail">
      <p class="error-page__detail-title">暗黙オブジェクト exception (${'${pageContext.exception}'})</p>
      <pre>${fn:escapeXml(pageContext.exception['class'].name)}: ${fn:escapeXml(pageContext.exception.message)}</pre>
    </div>

    <%-- web.xml 経由と同じ javax.servlet.error.* も入っています (JSP 2.0 以降) --%>
    <t:errorDetail />

    <a class="btn btn-primary" href="${ctx}/samples/advanced/error-handling">サンプルへ戻る</a>
  </div>
</t:layout>
