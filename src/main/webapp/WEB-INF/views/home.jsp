<%--
  トップページ (サンプル集の目次)。
  表示するデータは application スコープの ${catalog} / ${topics} と
  HomeServlet がセットした ${featuredSamples} / ${featuredTopics} です。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="ホーム" activeNav="home">

  <%-- ======================= ヒーロー ======================= --%>
  <section class="hero">
    <p class="hero__eyebrow">JSP &middot; Servlet &middot; Bootstrap 4</p>
    <h1 class="hero__title">${fn:escapeXml(initParam.siteTitle)}</h1>
    <p class="hero__lead">
      Web システムでよく使う画面や機能を、実際に動くコードで 1 つずつ確認できるサンプル集です。<br class="d-none d-md-inline">
      画面を触って動きを見て、そのままソースコードを読めます。
    </p>
    <form class="hero__search" action="${ctx}/search" method="get" role="search">
      <div class="input-group input-group-lg">
        <input type="search" class="form-control" name="q" placeholder="やりたいことで検索 (例: フォーム、一覧、ファイル)"
               value="${fn:escapeXml(param.q)}" aria-label="サンプルを検索">
        <div class="input-group-append">
          <button class="btn btn-primary" type="submit">
            <t:icon name="search" cssClass="mr-1" />検索
          </button>
        </div>
      </div>
    </form>
    <p class="hero__stats">
      公開中のサンプル <strong>${catalog.totalCount}</strong> 件 /
      カテゴリ <strong>${fn:length(catalog.categories)}</strong> 種類 /
      座学メモ <strong>${topics.totalCount}</strong> 件
    </p>
  </section>

  <%-- ======================= カテゴリ ======================= --%>
  <section class="section">
    <h2 class="section__title">
      <t:icon name="grid" cssClass="section__icon" />カテゴリから探す
    </h2>
    <div class="row">
      <c:forEach var="category" items="${catalog.categories}">
        <div class="col-sm-6 col-xl-3 mb-4">
          <a class="category-card" href="${ctx}/categories/${category.id}">
            <span class="category-card__icon"><t:icon name="${category.icon}" size="22" /></span>
            <span class="category-card__body">
              <span class="category-card__label">${fn:escapeXml(category.label)}</span>
              <span class="category-card__desc">${fn:escapeXml(category.description)}</span>
            </span>
            <span class="category-card__count">${catalog.count(category)}</span>
          </a>
        </div>
      </c:forEach>
    </div>
  </section>

  <%-- ======================= ピックアップ ======================= --%>
  <c:if test="${not empty featuredSamples}">
    <section class="section">
      <h2 class="section__title">
        <t:icon name="list" cssClass="section__icon" />サンプルを見てみる
      </h2>
      <div class="row">
        <c:forEach var="sample" items="${featuredSamples}">
          <t:sampleCard sample="${sample}" />
        </c:forEach>
      </div>
    </section>
  </c:if>

  <%-- ======================= 座学メモ ======================= --%>
  <c:if test="${not empty featuredTopics}">
    <section class="section">
      <h2 class="section__title">
        <t:icon name="book" cssClass="section__icon" />読むだけのメモ（座学メモ）
      </h2>
      <p class="text-muted mb-3">
        サンプルにしにくい話 &mdash; サーバが 2 台になったとき、同時に 200 人が来たとき、
        本番だけ挙動が違うとき &mdash; を読み物にしています。
      </p>
      <div class="row">
        <c:forEach var="topic" items="${featuredTopics}">
          <t:topicCard topic="${topic}" columnClass="col-md-6 col-xl-4" />
        </c:forEach>
      </div>
      <p>
        <a class="btn btn-outline-primary btn-sm" href="${ctx}/topics">
          座学メモをすべて見る（${topics.totalCount} 件）
          <t:icon name="chevron-right" size="12" cssClass="ml-1" />
        </a>
      </p>
    </section>
  </c:if>

  <%-- ======================= 使い方 ======================= --%>
  <section class="section">
    <h2 class="section__title">
      <t:icon name="lightbulb" cssClass="section__icon" />このサンプル集の使い方
    </h2>
    <div class="row">
      <div class="col-md-4 mb-3">
        <div class="howto">
          <span class="howto__step">1</span>
          <h3 class="howto__title">デモで動きを見る</h3>
          <p class="howto__text">各サンプルページの「デモ」タブで、実際に画面を操作して挙動を確認します。</p>
        </div>
      </div>
      <div class="col-md-4 mb-3">
        <div class="howto">
          <span class="howto__step">2</span>
          <h3 class="howto__title">ソースコードを読む</h3>
          <p class="howto__text">「ソースコード」タブに、その画面を動かしている JSP と Servlet がそのまま載っています。</p>
        </div>
      </div>
      <div class="col-md-4 mb-3">
        <div class="howto">
          <span class="howto__step">3</span>
          <h3 class="howto__title">手元で動かす</h3>
          <p class="howto__text">
            表示されているファイルのパスをたどれば、同じコードが手元のリポジトリにあります。
            <a href="${ctx}/about">構成の説明はこちら</a>。
          </p>
        </div>
      </div>
    </div>
  </section>

</t:layout>
