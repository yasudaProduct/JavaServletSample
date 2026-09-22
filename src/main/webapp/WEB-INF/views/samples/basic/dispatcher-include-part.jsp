<%--
  【サンプル】include される側の部品。

  この JSP は単体では画面になりません。呼び出し元の JSP から
  <jsp:include page="..."> で差し込まれて、その位置に出力されます。

  値の受け取り方は 2 通りあります。
    ${param.title}   … <jsp:param> で渡されたもの (その include の間だけ)
    ${noticeCount}   … 呼び出し元が request スコープに入れたもの (共有)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<div class="card mb-3">
  <div class="card-body">
    <h5 class="card-title mb-2">
      ${empty param.title ? '(タイトル未指定)' : fn:escapeXml(param.title)}
    </h5>
    <p class="card-text small mb-2">
      ${empty param.body ? '(本文未指定)' : fn:escapeXml(param.body)}
    </p>
    <ul class="small text-muted mb-0">
      <li>
        <code>${'${param.title}'}</code> …
        <code>&lt;jsp:param&gt;</code> で渡された値（この差し込みの間だけ）
      </li>
      <li>
        <code>${'${noticeCount}'}</code> …
        呼び出し元が request スコープに入れた値 → <strong>${noticeCount}</strong>
      </li>
      <li>
        <code>${'${requestScope["javax.servlet.include.servlet_path"]}'}</code> …
        <code>${fn:escapeXml(requestScope['javax.servlet.include.servlet_path'])}</code>
      </li>
    </ul>
  </div>
</div>
