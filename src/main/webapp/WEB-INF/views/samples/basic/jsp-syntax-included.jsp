<%--
  【サンプル】JSP の記法 : 動的インクルード (<jsp:include page="..." />) で呼ばれるページ

  静的インクルードとの違いを見せるための部品です。

    - このファイルは「別の JSP」として翻訳・実行されます
      (呼び出し側のスクリプトレット変数は見えません)
    - <jsp:param> で渡された値は ${param.xxx} で受け取れます
    - request スコープは同じリクエストなので共有されます
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<div class="alert alert-info mb-0">
  <p class="mb-1">
    <strong>ここは <code>jsp-syntax-included.jsp</code> が出力しています。</strong>
  </p>
  <ul class="mb-0">
    <li>
      <code>&lt;jsp:param&gt;</code> で受け取った値 :
      <code>${empty param.label ? '(渡されていません)' : fn:escapeXml(param.label)}</code>
    </li>
    <li>
      リクエストスコープは共有されます :
      <code>${empty requestScope.sharedNote ? '(未設定)' : fn:escapeXml(requestScope.sharedNote)}</code>
    </li>
    <li>
      取り込まれた自分のパス :
      <code>${fn:escapeXml(requestScope['javax.servlet.include.servlet_path'])}</code><br>
      リクエストのパス自体は<strong>呼び出し側のまま</strong>です :
      <code>${fn:escapeXml(pageContext.request.requestURI)}</code>
    </li>
  </ul>
</div>
