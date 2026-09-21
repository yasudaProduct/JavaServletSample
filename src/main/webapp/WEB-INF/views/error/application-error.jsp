<%--
  業務例外 (ApplicationException) 専用のエラーページ。

  web.xml で例外の型ごとに割り当てています。
    <error-page>
      <exception-type>com.example.servletsample.samples.advanced.ApplicationException</exception-type>
      <location>/WEB-INF/views/error/application-error.jsp</location>
    </error-page>

  コンテナは継承関係のうち「もっとも近い型」の設定を選ぶため、
  java.lang.Throwable の設定 (500.jsp) より、こちらが優先されます。

  システムエラーの画面と分けている理由は、伝えるべきことが違うからです。
    システムエラー … 利用者には直せない。「時間をおいて再度お試しください」
    業務エラー     … 利用者が対処できる。「何が起きて、次に何をすればよいか」を具体的に出す
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="appException" value="${requestScope['javax.servlet.error.exception']}" />
<t:layout title="処理を続けられません">
  <div class="error-page">
    <t:icon name="shield-lock" size="40" cssClass="error-page__icon" />
    <h1 class="error-page__title">処理を続けられません</h1>

    <%-- 業務例外のメッセージは「利用者に見せてよい文言」として作っているので、そのまま出せます --%>
    <p class="error-page__text">
      <c:choose>
        <c:when test="${not empty appException}">${fn:escapeXml(appException.message)}</c:when>
        <c:otherwise>入力内容を確認して、もう一度お試しください。</c:otherwise>
      </c:choose>
    </p>

    <%-- エラーコードは問い合わせを受けたときにログと突き合わせるための目印 --%>
    <c:if test="${not empty appException.code}">
      <p class="error-page__text">
        エラーコード: <code>${fn:escapeXml(appException.code)}</code>
      </p>
    </c:if>

    <a class="btn btn-primary" href="${ctx}/samples/advanced/error-handling">サンプルへ戻る</a>
    <p class="error-page__note">
      この画面は業務例外 (<code>ApplicationException</code>) のときだけ表示されます。
      仕組みは
      <a href="${ctx}/samples/advanced/error-handling">エラー処理とエラーページ</a>
      のサンプルで解説しています。
    </p>
  </div>
</t:layout>
