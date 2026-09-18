<%--
  処理結果を知らせる完了モーダル。

    <t:resultModal message="${flash}" />

  message には com.example.servletsample.common.Flash.Message を渡します。
  空なら何も出力しないので、呼び出し側で c:if を書く必要はありません。

  モーダルの中身を自分で組み立てたい場合は
  /WEB-INF/views/samples/design/modal-dialog.jsp を参照してください
  (このタグは、その ③ のパターンを使い回せるようにまとめたものです)。
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" body-content="empty" %>
<%@ attribute name="message" required="true"
              type="com.example.servletsample.common.Flash.Message" %>
<%@ attribute name="id" type="java.lang.String" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:if test="${not empty message}">
  <c:set var="modalId" value="${empty id ? 'resultModal' : id}" />
  <div class="modal fade" id="${modalId}" tabindex="-1" role="dialog"
       aria-labelledby="${modalId}Title" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="${modalId}Title">
            <t:icon name="check-circle" cssClass="text-${message.variant} mr-2" />${fn:escapeXml(message.title)}
          </h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <p class="mb-0">${fn:escapeXml(message.text)}</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-${message.variant}" data-dismiss="modal">OK</button>
        </div>
      </div>
    </div>
  </div>
  <script>
    // jQuery はページの末尾で読み込まれるため、ここでは DOMContentLoaded を待ってから開く
    document.addEventListener('DOMContentLoaded', function () {
      jQuery('#${modalId}').modal('show');
    });
  </script>
</c:if>
