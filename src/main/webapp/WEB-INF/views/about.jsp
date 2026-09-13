<%--
  このサンプル集について。構成・使い方・動作環境をまとめたページ。
  AboutServlet が ${serverInfo} などをセットします。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:layout title="このサイトについて" activeNav="about">

  <jsp:attribute name="breadcrumb">
    <li class="breadcrumb-item active" aria-current="page">このサイトについて</li>
  </jsp:attribute>

  <jsp:body>
    <div class="page-header">
      <h1 class="page-header__title">このサイトについて</h1>
      <p class="page-header__lead">${fn:escapeXml(initParam.siteDescription)}</p>
    </div>

    <div class="doc-body">

      <h2>何ができるサイトか</h2>
      <p>
        JSP・Servlet・Bootstrap 4 で Web システムを作るときに繰り返し出てくる画面や機能を、
        1 つずつ「動く状態」で置いてあるサンプル集です。
        各ページは <strong>デモ</strong>（実際に動く画面）、<strong>ソースコード</strong>（その画面を動かしているコード）、
        <strong>解説</strong> の 3 つのタブで構成しています。
      </p>

      <h2>技術構成</h2>
      <div class="table-responsive">
        <table class="table table-sm table-bordered doc-table">
          <tbody>
            <tr><th scope="row">言語</th><td>Java 17</td></tr>
            <tr><th scope="row">サーバ</th><td>Apache Tomcat 9 (Docker コンテナ)</td></tr>
            <tr><th scope="row">API</th><td>Servlet 4.0 / JSP 2.3 / JSTL 1.2（<code>javax.*</code> 名前空間）</td></tr>
            <tr><th scope="row">画面</th><td>Bootstrap 4.6（CDN ではなくリポジトリに同梱）</td></tr>
            <tr><th scope="row">ビルド</th><td>Maven（WAR パッケージング）</td></tr>
            <tr><th scope="row">エディタ</th><td>Visual Studio Code（設定・デバッグ構成を同梱）</td></tr>
          </tbody>
        </table>
      </div>

      <h2>画面の作り</h2>
      <p>
        JSP はすべて <code>/WEB-INF/views/</code> の下に置き、ブラウザから直接開けないようにしています。
        画面を出すのは Servlet の役割で、Servlet が値を用意して JSP に転送（forward）します。
        共通のヘッダー・サイドバー・フッターは <code>/WEB-INF/tags/layout.tag</code> にまとめてあり、
        各ページはこのタグで囲むだけで同じ見た目になります。
      </p>

      <pre class="doc-tree">src/main/
├── java/com/example/servletsample/
│   ├── catalog/   … サンプル一覧（目次）の定義
│   ├── common/    … 共通処理（土台となる Servlet など）
│   ├── web/       … サイト自体の画面（トップ・カテゴリ・検索）
│   └── samples/   … 各サンプルの Servlet
└── webapp/
    ├── WEB-INF/
    │   ├── views/  … 画面の JSP（samples/ の下がサンプル本体）
    │   ├── tags/   … 共通レイアウトのタグファイル
    │   └── web.xml … アプリ全体の設定
    └── assets/     … CSS / JavaScript / Bootstrap</pre>

      <h2>サンプルの増やし方</h2>
      <ol>
        <li><code>WEB-INF/views/samples/{カテゴリ}/{ID}.jsp</code> に画面を作る</li>
        <li><code>SampleDefinitions.define()</code> に 1 件追加する</li>
        <li>Servlet が必要なら <code>@WebServlet("/samples/{カテゴリ}/{ID}")</code> で作る</li>
      </ol>
      <p>
        詳しい手順はリポジトリの <code>docs/ADD_SAMPLE.md</code> にまとめてあります。
      </p>

      <h2>いま動いている環境</h2>
      <div class="table-responsive">
        <table class="table table-sm table-bordered doc-table">
          <tbody>
            <tr><th scope="row">サーブレットコンテナ</th><td>${fn:escapeXml(serverInfo)}</td></tr>
            <tr><th scope="row">Servlet API</th><td>${fn:escapeXml(servletVersion)}</td></tr>
            <tr><th scope="row">Java</th><td>${fn:escapeXml(javaVersion)}</td></tr>
          </tbody>
        </table>
      </div>

      <p class="mt-4">
        <a class="btn btn-outline-primary btn-sm" href="${initParam.githubUrl}" target="_blank" rel="noopener noreferrer">
          <t:icon name="github" cssClass="mr-1" />GitHub でソースを見る
        </a>
      </p>
    </div>
  </jsp:body>
</t:layout>
