<%--
  座学メモの一覧。
  表示するデータは application スコープの ${topics} です (TopicServlet 経由で表示)。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="座学メモ" description="サンプルを置きにくいが、知らないと詰まる話をまとめた読み物です。"
          activeNav="topics">

  <jsp:attribute name="breadcrumb">
    <li class="breadcrumb-item active" aria-current="page">座学メモ</li>
  </jsp:attribute>

  <jsp:body>
    <div class="page-header">
      <div class="page-header__meta">
        <span class="badge badge-topic">
          <t:icon name="book" size="12" cssClass="mr-1" />読み物
        </span>
      </div>
      <h1 class="page-header__title">座学メモ</h1>
      <p class="page-header__lead">
        動かして見せにくい話を、読むだけで分かる形にまとめたページです。
      </p>
    </div>

    <div class="doc-body mb-4">
      <h2>サンプルではなくメモにしている理由</h2>
      <p>
        このサイトのサンプルは「画面を触って、ソースを読む」形式です。
        ところが Web アプリの話には、<strong>1 台の localhost では再現できないこと</strong>や、
        <strong>コードではなく判断の話</strong>がいくつもあります。
      </p>
      <ul>
        <li>サーバを 2 台に増やしたら、ときどきログアウトするようになった</li>
        <li>同時に 200 人が使い始めたら、画面が返ってこなくなった</li>
        <li>本番だけ Cookie が消える。本番だけ時刻が 9 時間ずれる</li>
        <li>Servlet に全部書くか、クラスを分けるか</li>
      </ul>
      <p>
        こういう話はデモを作っても「動いているところ」しか見えず、
        肝心の<strong>起きてほしくないほうの挙動</strong>が出せません。
        かといって知らないままだと、本番に出してから初めて出会うことになります。
        そこで、読むだけのメモとしてここに置いています。
      </p>
      <p class="mb-0">
        各メモの最後には、関連するサンプルへのリンクを付けています。
        「読む → 触る」の順でたどれるようにしてあります。
      </p>
    </div>

    <p class="list-count">${topics.totalCount} 件</p>

    <c:forEach var="group" items="${topics.groups}">
      <c:set var="groupTopics" value="${topics.byGroup(group)}" />
      <c:if test="${not empty groupTopics}">
        <section class="section" id="${group.id}">
          <h2 class="section__title">
            <t:icon name="${group.icon}" cssClass="section__icon" />${fn:escapeXml(group.label)}
          </h2>
          <p class="text-muted small mb-3">${fn:escapeXml(group.description)}</p>
          <div class="row">
            <c:forEach var="topic" items="${groupTopics}">
              <t:topicCard topic="${topic}" showGroup="false" columnClass="col-md-6 col-xl-4" />
            </c:forEach>
          </div>
        </section>
      </c:if>
    </c:forEach>

    <div class="alert alert-light border mt-4">
      <t:icon name="lightbulb" cssClass="mr-1 text-muted" />
      動くコードで確かめたいものは
      <a href="${ctx}/">サンプル集</a>（${catalog.totalCount} 件）にあります。
    </div>
  </jsp:body>
</t:layout>
