<%--
  モーダルのサンプル ④ で、完了モーダルを閉じたあとに移動してくる画面。

  ModalDialogEntriesServlet が ${entries} (セッションに溜めた受付) をセットします。
  サンプルページ (t:sample) ではなく、ふつうの画面 (t:layout) として作っています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="samplePath" value="${ctx}/samples/design/modal-dialog" />
<t:layout title="受付一覧" description="モーダルのサンプルで登録した受付の一覧" activeCategory="design">

  <jsp:attribute name="breadcrumb">
    <li class="breadcrumb-item"><a href="${ctx}/categories/design">画面デザイン</a></li>
    <li class="breadcrumb-item"><a href="${samplePath}">モーダルの出し方</a></li>
    <li class="breadcrumb-item active" aria-current="page">受付一覧</li>
  </jsp:attribute>

  <jsp:body>
    <div class="page-header">
      <h1 class="page-header__title">受付一覧</h1>
      <p class="page-header__lead">
        モーダルのサンプル ④「確認 → 登録 → 完了モーダル → 画面遷移」で移動してくる画面です。
        完了モーダルを閉じたあと、ここへ送られてきました。
      </p>
    </div>

    <c:choose>
      <c:when test="${empty entries}">
        <div class="empty-state">
          <t:icon name="list" size="32" cssClass="empty-state__icon" />
          <p class="empty-state__text">まだ受付がありません。</p>
          <a class="btn btn-outline-primary btn-sm" href="${samplePath}#pane-demo">
            サンプルへ戻って登録する
          </a>
        </div>
      </c:when>
      <c:otherwise>
        <div class="demo-panel">
          <div class="demo-panel__head">
            <span class="demo-panel__title">登録された受付</span>
            <span class="demo-panel__note">セッションに保存しているため、見えるのは登録した本人だけです</span>
          </div>
          <div class="demo-panel__body">
            <div class="table-responsive">
              <table class="table table-sm table-hover mb-0">
                <thead class="thead-light">
                  <tr>
                    <th scope="col">受付番号</th>
                    <th scope="col">お名前</th>
                    <th scope="col">登録日時</th>
                  </tr>
                </thead>
                <tbody>
                  <c:forEach var="entry" items="${entries}" varStatus="status">
                    <tr class="${status.first ? 'table-success' : ''}">
                      <td class="align-middle"><code>${fn:escapeXml(entry.receiptNumber)}</code></td>
                      <td class="align-middle">
                        ${fn:escapeXml(entry.name)}
                        <c:if test="${status.first}">
                          <span class="badge badge-success ml-1">いま登録した分</span>
                        </c:if>
                      </td>
                      <td class="align-middle">${entry.registeredAtText}</td>
                    </tr>
                  </c:forEach>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <p class="text-muted small">
          ${fn:length(entries)} 件（新しい順）
        </p>
      </c:otherwise>
    </c:choose>

    <div class="mt-3">
      <a class="btn btn-primary" href="${samplePath}#pane-demo">
        <t:icon name="chevron-right" size="12" cssClass="mr-1" />モーダルのサンプルへ戻る
      </a>
      <a class="btn btn-link" href="${samplePath}#pane-note">解説を読む</a>
    </div>
  </jsp:body>
</t:layout>
