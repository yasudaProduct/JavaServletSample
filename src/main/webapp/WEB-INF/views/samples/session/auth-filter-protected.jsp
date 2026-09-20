<%--
  【サンプル】フィルタで守られている画面。

  ProtectedPageServlet が次の値をセットします。
    adminOnly … 管理者専用の画面かどうか
    backPath  … 説明ページへ戻る URL

  この画面には「ログインしているか」を確かめるコードが 1 行もありません。
  フィルタが済ませてくれているためです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="${adminOnly ? '管理者ページ' : '会員ページ'}" activeCategory="session">

  <jsp:attribute name="breadcrumb">
    <li class="breadcrumb-item"><a href="${ctx}/categories/session">セッション・認証</a></li>
    <li class="breadcrumb-item"><a href="${backPath}">フィルタで未ログインを弾く</a></li>
    <li class="breadcrumb-item active" aria-current="page">
      ${adminOnly ? '管理者ページ' : '会員ページ'}
    </li>
  </jsp:attribute>

  <jsp:body>
    <div class="page-header">
      <div class="page-header__meta">
        <c:choose>
          <c:when test="${adminOnly}">
            <span class="badge badge-danger">管理者だけが開けます</span>
          </c:when>
          <c:otherwise>
            <span class="badge badge-success">ログインしていれば開けます</span>
          </c:otherwise>
        </c:choose>
      </div>
      <h1 class="page-header__title">${adminOnly ? '管理者ページ' : '会員ページ'}</h1>
      <p class="page-header__lead">
        フィルタを通り抜けて、この画面まで届きました。
      </p>
    </div>

    <div class="demo-panel">
      <div class="demo-panel__head">
        <span class="demo-panel__title">いまログインしているのは</span>
      </div>
      <div class="demo-panel__body">
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-0 doc-table">
            <tbody>
              <tr>
                <th scope="row">氏名</th>
                <td>${fn:escapeXml(loginUser.name)}</td>
              </tr>
              <tr>
                <th scope="row">ログイン ID</th>
                <td><code>${fn:escapeXml(loginUser.loginId)}</code></td>
              </tr>
              <tr>
                <th scope="row">役割</th>
                <td>
                  <span class="badge badge-${loginUser.role.variant}">
                    ${fn:escapeXml(loginUser.role.label)}
                  </span>
                </td>
              </tr>
              <tr>
                <th scope="row">この画面の URL</th>
                <td><code>${fn:escapeXml(pageContext.request.requestURI)}</code></td>
              </tr>
            </tbody>
          </table>
        </div>

        <hr>
        <p class="mb-0 text-muted small">
          <code>ProtectedPageServlet</code> には、ログインを確かめるコードが 1 行もありません。
          ここへ処理が届いた時点で、フィルタが済ませてくれているためです。
          「確認を書き忘れた画面」が生まれないのが、フィルタにまとめる最大の利点です。
        </p>
      </div>
    </div>

    <a class="btn btn-outline-primary" href="${backPath}">サンプルの説明へ戻る</a>
  </jsp:body>
</t:layout>
