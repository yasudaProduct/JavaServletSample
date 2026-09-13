<%--
  【サンプル】Hello World (Servlet → JSP)

  HelloWorldServlet が request スコープに入れた値を EL (${...}) で取り出して表示します。
  ページの枠組み (タブ・ソース表示・前後リンク) は t:sample タグが作ります。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="hello-world">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>処理の流れ</h2>
    <ol>
      <li>ブラウザが <code>/samples/basic/hello-world</code> をリクエストする</li>
      <li><code>@WebServlet</code> で URL を割り当てた <code>HelloWorldServlet#doGet</code> が呼ばれる</li>
      <li>Servlet が <code>request.setAttribute("message", ...)</code> で値をリクエストスコープに入れる</li>
      <li><code>forward</code> で JSP に処理を渡す</li>
      <li>JSP が <code>${'${message}'}</code> で値を取り出して HTML を組み立てる</li>
    </ol>

    <h2>ポイント</h2>
    <ul>
      <li>
        <strong>JSP は <code>/WEB-INF/</code> の下に置く</strong>：
        ブラウザから JSP を直接開かれると、Servlet を通らずに画面が表示されてしまいます。
        <code>/WEB-INF/</code> 配下のファイルは外部から直接アクセスできません。
      </li>
      <li>
        <strong>値の受け渡しはリクエストスコープ</strong>：
        <code>setAttribute</code> で入れた値は、その 1 リクエスト（forward 先を含む）の間だけ有効です。
      </li>
      <li>
        <strong>画面に出す値はエスケープする</strong>：
        入力値をそのまま <code>${'${...}'}</code> で出すと HTML として解釈されてしまうため
        （クロスサイトスクリプティング）、<code>fn:escapeXml</code> か <code>&lt;c:out&gt;</code> を通します。
      </li>
      <li>
        <strong>転送(forward)とリダイレクト(sendRedirect)の違い</strong>：
        forward はサーバ内部で処理を渡すだけなので URL は変わりません。
        リダイレクトはブラウザに再リクエストさせるため URL が変わり、リクエストスコープの値は消えます。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:panel title="Servlet から渡された値">
      <p class="hello-message">${fn:escapeXml(message)}</p>
      <p class="text-muted mb-0">
        画面を作った時刻: <code>${fn:escapeXml(now)}</code>
        （Servlet 側で <code>LocalDateTime.now()</code> を整形した値です）
      </p>
    </t:panel>

    <t:panel title="名前を変えてみる" note="GET パラメータ name を Servlet が受け取ります">
      <form action="${ctx}/samples/basic/hello-world" method="get" class="form-inline">
        <label class="mr-2" for="nameInput">名前</label>
        <input type="text" class="form-control mr-2" id="nameInput" name="name"
               value="${fn:escapeXml(inputName)}" placeholder="例: 山田太郎" size="24">
        <button type="submit" class="btn btn-primary">送信</button>
      </form>
      <p class="text-muted small mt-3 mb-0">
        送信すると URL が <code>?name=...</code> 付きになり、Servlet の
        <code>request.getParameter("name")</code> で受け取れます。
      </p>
    </t:panel>

    <t:panel title="いまのリクエストの中身">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" class="w-25">ブラウザがリクエストした URL</th>
              <td>
                <code>${fn:escapeXml(empty requestScope['javax.servlet.forward.request_uri']
                        ? pageContext.request.requestURI
                        : requestScope['javax.servlet.forward.request_uri'])}</code>
              </td>
            </tr>
            <tr>
              <th scope="row">転送先の JSP</th>
              <td>
                <code>${fn:escapeXml(pageContext.request.requestURI)}</code>
                <span class="d-block text-muted small mt-1">
                  forward したあとの <code>getRequestURI()</code> は転送先を返します。
                  元の URL は <code>javax.servlet.forward.request_uri</code> で取れます。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">HTTP メソッド</th>
              <td><code>${fn:escapeXml(pageContext.request.method)}</code></td>
            </tr>
            <tr>
              <th scope="row">パラメータ name</th>
              <td><code>${empty param.name ? '(未指定)' : fn:escapeXml(param.name)}</code></td>
            </tr>
            <tr>
              <th scope="row">転送元の Servlet</th>
              <td><code>com.example.servletsample.samples.basic.HelloWorldServlet</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>
  </jsp:body>
</t:sample>
