<%--
  サイト共通のレイアウト。すべての画面はこのタグを通して出力します。

    <t:layout title="ページタイトル" activeCategory="basic">
      <jsp:attribute name="breadcrumb"> ... </jsp:attribute>
      <jsp:body> ページ本体 </jsp:body>
    </t:layout>
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ attribute name="title" required="true" type="java.lang.String" %>
<%@ attribute name="description" type="java.lang.String" %>
<%@ attribute name="activeCategory" type="java.lang.String" %>
<%@ attribute name="activeNav" type="java.lang.String" %>
<%@ attribute name="breadcrumb" fragment="true" %>
<%@ attribute name="head" fragment="true" %>
<%@ attribute name="scripts" fragment="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <meta name="description" content="${fn:escapeXml(empty description ? initParam.siteDescription : description)}">
  <title>${fn:escapeXml(title)} | ${fn:escapeXml(initParam.siteTitle)}</title>
  <link rel="icon" type="image/svg+xml" href="${ctx}/assets/favicon.svg">
  <link rel="stylesheet" href="${ctx}/assets/vendor/bootstrap/bootstrap.min.css">
  <link rel="stylesheet" href="${ctx}/assets/vendor/highlight/github.min.css">
  <link rel="stylesheet" href="${ctx}/assets/css/app.css">
  <c:if test="${not empty head}"><jsp:invoke fragment="head" /></c:if>
</head>
<body>

<%--
  キーボード操作の人が、ヘッダーのリンクを全部たどらずに本文へ飛べるようにするリンク。
  普段は sr-only で見えず、Tab でフォーカスが当たったときだけ現れます。
  解説: /samples/a11y/keyboard-operation
--%>
<a class="sr-only sr-only-focusable skip-link" href="#main-content">本文へスキップ</a>

<%-- ============================ ヘッダー ============================ --%>
<header class="site-header">
  <nav class="navbar navbar-expand-lg navbar-dark">
    <div class="container-fluid">
      <a class="navbar-brand" href="${ctx}/">
        <t:icon name="code-slash" size="20" cssClass="navbar-brand__icon" />
        <span>${fn:escapeXml(initParam.siteTitle)}</span>
      </a>

      <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#siteNav"
              aria-controls="siteNav" aria-expanded="false" aria-label="メニューを開く">
        <span class="navbar-toggler-icon"></span>
      </button>

      <div class="collapse navbar-collapse" id="siteNav">
        <ul class="navbar-nav mr-auto">
          <li class="nav-item ${activeNav eq 'home' ? 'active' : ''}">
            <a class="nav-link" href="${ctx}/">ホーム</a>
          </li>
          <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle" href="#" id="navCategories" role="button"
               data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">カテゴリ</a>
            <div class="dropdown-menu" aria-labelledby="navCategories">
              <c:forEach var="category" items="${catalog.categories}">
                <a class="dropdown-item" href="${ctx}/categories/${category.id}">
                  <t:icon name="${category.icon}" cssClass="mr-2 text-muted" />${category.label}
                  <span class="text-muted small">(${catalog.count(category)})</span>
                </a>
              </c:forEach>
            </div>
          </li>
          <li class="nav-item ${activeNav eq 'about' ? 'active' : ''}">
            <a class="nav-link" href="${ctx}/about">このサイトについて</a>
          </li>
        </ul>

        <form class="form-inline site-header__search" action="${ctx}/search" method="get" role="search">
          <label class="sr-only" for="siteSearch">サンプルを検索</label>
          <input class="form-control form-control-sm" type="search" id="siteSearch" name="q"
                 value="${fn:escapeXml(param.q)}" placeholder="サンプルを検索" aria-label="サンプルを検索">
          <button class="btn btn-sm btn-outline-light ml-2" type="submit">
            <t:icon name="search" /><span class="sr-only">検索</span>
          </button>
        </form>

        <a class="site-header__github ml-lg-3" href="${initParam.githubUrl}"
           target="_blank" rel="noopener noreferrer" title="GitHub で見る">
          <t:icon name="github" size="20" /><span class="d-lg-none ml-2">GitHub</span>
        </a>
      </div>
    </div>
  </nav>
</header>

<%-- ============================ 本体 ============================ --%>
<div class="site-body">
  <div class="container-fluid">
    <div class="row">

      <%-- サイドバー (カテゴリ一覧) --%>
      <aside class="col-lg-3 col-xl-2 d-none d-lg-block site-sidebar">
        <nav class="site-sidebar__inner" aria-label="カテゴリ">
          <p class="site-sidebar__title">カテゴリ</p>
          <ul class="site-sidebar__list">
            <c:forEach var="category" items="${catalog.categories}">
              <c:set var="isActive" value="${activeCategory eq category.id}" />
              <li>
                <a class="site-sidebar__link ${isActive ? 'is-active' : ''}"
                   href="${ctx}/categories/${category.id}">
                  <t:icon name="${category.icon}" cssClass="site-sidebar__icon" />
                  <span class="site-sidebar__label">${category.label}</span>
                  <span class="site-sidebar__count">${catalog.count(category)}</span>
                </a>
                <c:if test="${isActive and catalog.count(category) > 0}">
                  <ul class="site-sidebar__sublist">
                    <c:forEach var="item" items="${catalog.byCategory(category)}">
                      <li>
                        <c:choose>
                          <c:when test="${item.visitable}">
                            <a class="site-sidebar__sublink" href="${ctx}${item.path}">${fn:escapeXml(item.title)}</a>
                          </c:when>
                          <c:otherwise>
                            <span class="site-sidebar__sublink is-disabled">${fn:escapeXml(item.title)}</span>
                          </c:otherwise>
                        </c:choose>
                      </li>
                    </c:forEach>
                  </ul>
                </c:if>
              </li>
            </c:forEach>
          </ul>

          <p class="site-sidebar__note">
            公開中のサンプル <strong>${catalog.totalCount}</strong> 件
          </p>
        </nav>
      </aside>

      <%-- メイン --%>
      <main class="col-lg-9 col-xl-10 site-main" id="main-content" tabindex="-1">
        <c:if test="${not empty breadcrumb}">
          <nav aria-label="パンくずリスト">
            <ol class="breadcrumb site-breadcrumb">
              <li class="breadcrumb-item"><a href="${ctx}/">ホーム</a></li>
              <jsp:invoke fragment="breadcrumb" />
            </ol>
          </nav>
        </c:if>

        <jsp:doBody />
      </main>

    </div>
  </div>
</div>

<%-- ============================ フッター ============================ --%>
<footer class="site-footer">
  <div class="container-fluid">
    <div class="row">
      <div class="col-md-5 mb-3">
        <p class="site-footer__title">${fn:escapeXml(initParam.siteTitle)}</p>
        <p class="site-footer__text">${fn:escapeXml(initParam.siteDescription)}</p>
      </div>
      <div class="col-md-4 mb-3">
        <p class="site-footer__title">構成</p>
        <ul class="site-footer__list">
          <li>Java 17 / Servlet 4.0 / JSP 2.3 (JSTL 1.2)</li>
          <li>Apache Tomcat 9 (Docker)</li>
          <li>Bootstrap 4.6</li>
        </ul>
      </div>
      <div class="col-md-3 mb-3">
        <p class="site-footer__title">リンク</p>
        <ul class="site-footer__list">
          <li><a href="${ctx}/about">このサイトについて</a></li>
          <li>
            <a href="${initParam.githubUrl}" target="_blank" rel="noopener noreferrer">
              GitHub リポジトリ <t:icon name="external" size="12" />
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</footer>

<script src="${ctx}/assets/vendor/jquery/jquery.slim.min.js"></script>
<script src="${ctx}/assets/vendor/bootstrap/bootstrap.bundle.min.js"></script>
<script src="${ctx}/assets/vendor/highlight/highlight.min.js"></script>
<script src="${ctx}/assets/js/app.js"></script>
<c:if test="${not empty scripts}"><jsp:invoke fragment="scripts" /></c:if>
</body>
</html>
