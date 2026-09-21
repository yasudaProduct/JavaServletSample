<%--
  【サンプル】マスタメンテナンス（登録・編集・削除）

  CrudServlet が次の値をセットします。
    mode      … "list" / "new" / "edit" / "delete"
    customers … 取引先の一覧
    form      … 入力中の内容
    errors    … 入力チェックの結果
    flash     … 完了メッセージ

  取引先マスタは「更新の競合（楽観ロック）」のサンプルと共有しています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/list/crud" />
<t:sample sampleId="crud">

  <jsp:attribute name="explanation">
    <h2>一覧を起点にする</h2>
<pre><code class="language-plaintext">               ┌──────────────┐
               │     一覧      │←──────────┐
               └──────────────┘            │
                 │    │     │              │
         新規登録 │    │編集  │削除          │ リダイレクト
                 ↓    ↓     ↓              │ (PRG)
             ［入力］ ［入力］ ［確認］ ──POST─┘</code></pre>
    <p>
      登録・編集・削除は、終わったら必ず一覧へ戻します。
      「どこへ戻ればよいか分からない画面」を作らないための、いちばん簡単な決めごとです。
    </p>

    <h2>表示は GET、更新は POST</h2>
    <p>
      すべての土台です。とくに<strong>削除を GET のリンクにしてはいけません</strong>。
    </p>
<pre><code class="language-xml">&lt;!-- 【駄目】 クローラやブラウザの先読みが、勝手に削除して回る --&gt;
&lt;a href="/crud?action=delete&amp;id=1"&gt;削除&lt;/a&gt;

&lt;!-- 【良い】 --&gt;
&lt;form action="/crud" method="post"&gt;
  &lt;input type="hidden" name="action" value="delete"&gt;
  &lt;input type="hidden" name="id" value="1"&gt;
  &lt;button type="submit"&gt;削除&lt;/button&gt;
&lt;/form&gt;</code></pre>
    <p>
      「管理画面のデータが全部消えた」という事故の典型がこれです。
      ログインが要る画面でも、社内のクローラや
      ブラウザの拡張機能がリンクを先読みすることがあります。
    </p>

    <h2>削除は確認をはさむ</h2>
    <p>
      このサンプルでは、確認用の画面を 1 枚はさんでいます。
    </p>
<pre><code class="language-plaintext">GET  ?action=delete&amp;id=1   → 確認画面（何を消すのかを見せる）
POST action=delete         → 実際に消す</code></pre>
    <p>
      モーダルで確認する作りもあります
      （<a href="${ctx}/samples/design/modal-dialog">モーダルの出し方</a>）。
      どちらでも構いませんが、<strong>「何を消すのか」を必ず見せてください</strong>。
      「本当によろしいですか？」だけでは、押し間違いを防げません。
    </p>

    <h2>登録したあとはリダイレクト（PRG）</h2>
<pre><code class="language-java">long id = dao.insert(form);
Flash.set(request, "success", "登録しました", form.getName() + " を登録しました。");
response.sendRedirect(request.getContextPath() + PATH);</code></pre>
    <p>
      <code>forward</code> で完了画面を出すと、利用者が再読み込みしたときに
      ブラウザが「再送信しますか？」と聞いてきます。
      ここで「はい」を押されると、<strong>もう 1 件登録されます</strong>。
    </p>

    <h2>一意性のチェックは 2 段構え</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th></th><th>アプリでの確認</th><th>データベースの UNIQUE 制約</th></tr>
        </thead>
        <tbody>
          <tr><td>目的</td><td>利用者に分かりやすく伝える</td><td>何があってもデータを壊さない</td></tr>
          <tr><td>同時実行</td><td><strong>すり抜ける</strong>（確認と登録の間に割り込める）</td>
              <td>確実に防げる</td></tr>
          <tr><td>メッセージ</td><td>項目のそばに出せる</td><td>そのままでは利用者に見せられない</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      アプリだけだと同時登録をすり抜け、データベースだけだと
      「制約違反です」としか言えません。
      両方あって初めて、<strong>ふだんは親切に、いざというときは確実に</strong>なります。
    </p>
<pre><code class="language-sql">CONSTRAINT uk_customers_code UNIQUE (code)</code></pre>

    <h2>更新・削除には version を付ける</h2>
    <p>
      一覧を表示してから操作するまでの間に、誰かが同じ行を触っているかもしれません。
      更新と削除の条件に <code>version</code> を入れ、
      <strong>更新できた件数が 0 なら競合</strong>として扱います。
    </p>
<pre><code class="language-sql">UPDATE customers SET ..., version = version + 1 WHERE id = ? AND version = ?
DELETE FROM customers                           WHERE id = ? AND version = ?</code></pre>
    <p>
      詳しくは
      <a href="${ctx}/samples/list/optimistic-lock">更新の競合（楽観ロック）</a>
      のサンプルにあります。
    </p>

    <h2>入力エラーのときは、入力画面に戻す</h2>
    <p>
      リダイレクトしません。<code>forward</code> で同じ画面に戻し、
      <strong>入力値を保持したまま</strong>メッセージを出します。
      リダイレクトすると別のリクエストになり、入力値が消えてしまいます。
    </p>
<pre><code class="language-java">if (errors.hasErrors()) {
    render(request, response, dao, MODE_EDIT, form, errors);   // forward
    return;
}
...
response.sendRedirect(...);   // 成功したときだけリダイレクト</code></pre>

    <h2>実務で足していくもの</h2>
    <ul>
      <li>
        <strong>検索と絞り込み</strong> …
        件数が増えたら一覧だけでは足りません
        （<a href="${ctx}/samples/list/search-list">検索つき一覧画面</a>）
      </li>
      <li>
        <strong>論理削除</strong> …
        「消したことにする」列を持ち、実際には消さない。
        伝票から参照されているマスタは、物理削除すると過去の伝票が表示できなくなります
      </li>
      <li>
        <strong>更新履歴</strong> … 誰がいつ何を変えたかを別テーブルに残す
      </li>
      <li>
        <strong>権限</strong> … 参照だけの人、更新できる人を分ける
        （<a href="${ctx}/samples/session/auth-filter">フィルタで未ログインを弾く</a>）
      </li>
      <li>
        <strong>参照されている行の削除を止める</strong> …
        外部キー制約、または削除前の件数チェック
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>

    <t:resultModal message="${flash}" />

    <c:choose>
      <%-- ============================ 削除の確認 ============================ --%>
      <c:when test="${mode eq 'delete'}">
        <t:panel title="削除の確認" note="この内容で削除します">
          <div class="alert alert-danger" role="alert">
            <strong>この取引先を削除します。元に戻せません。</strong>
          </div>

          <div class="table-responsive">
            <table class="table table-sm table-bordered doc-table">
              <tbody>
                <tr><th scope="row">取引先コード</th><td><code>${fn:escapeXml(form.code)}</code></td></tr>
                <tr><th scope="row">取引先名</th><td>${fn:escapeXml(form.name)}</td></tr>
                <tr><th scope="row">担当者</th><td>${fn:escapeXml(form.contact)}</td></tr>
                <tr><th scope="row">メールアドレス</th><td>${fn:escapeXml(form.email)}</td></tr>
              </tbody>
            </table>
          </div>

          <div class="d-flex">
            <a class="btn btn-outline-secondary mr-2" href="${sampleUrl}">やめる</a>
            <form action="${sampleUrl}" method="post">
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="${fn:escapeXml(form.id)}">
              <%-- 一覧を開いたあとに誰かが変更していたら削除させない --%>
              <input type="hidden" name="version" value="${fn:escapeXml(form.version)}">
              <button type="submit" class="btn btn-danger">削除する</button>
            </form>
          </div>
        </t:panel>
      </c:when>

      <%-- ============================ 登録 / 編集 ============================ --%>
      <c:when test="${mode eq 'new' or mode eq 'edit'}">
        <c:set var="editing" value="${mode eq 'edit'}" />
        <t:panel title="${editing ? '取引先の編集' : '取引先の新規登録'}"
                 note="${editing ? '隠し項目に version を持たせています' : '取引先コードは AB-123 の形式です'}">

          <c:if test="${not empty errors.messages}">
            <div class="alert alert-danger" role="alert">
              <strong>入力内容を確認してください（${errors.count} 件）</strong>
              <ul class="mb-0 mt-2">
                <c:forEach var="message" items="${errors.messages}">
                  <li>${fn:escapeXml(message)}</li>
                </c:forEach>
              </ul>
            </div>
          </c:if>

          <form action="${sampleUrl}" method="post" novalidate>
            <input type="hidden" name="action" value="${editing ? 'update' : 'create'}">
            <c:if test="${editing}">
              <input type="hidden" name="id" value="${fn:escapeXml(form.id)}">
              <input type="hidden" name="version" value="${fn:escapeXml(form.version)}">
            </c:if>

            <div class="form-row">
              <div class="form-group col-md-4">
                <label for="code">取引先コード <span class="badge badge-danger">必須</span></label>
                <input type="text" class="form-control ${errors.has('code') ? 'is-invalid' : ''}"
                       id="code" name="code" value="${fn:escapeXml(form.code)}"
                       placeholder="例: AL-001">
                <div class="invalid-feedback">${fn:escapeXml(errors.get('code'))}</div>
              </div>
              <div class="form-group col-md-8">
                <label for="name">取引先名 <span class="badge badge-danger">必須</span></label>
                <input type="text" class="form-control ${errors.has('name') ? 'is-invalid' : ''}"
                       id="name" name="name" value="${fn:escapeXml(form.name)}"
                       placeholder="例: 株式会社アルファ">
                <div class="invalid-feedback">${fn:escapeXml(errors.get('name'))}</div>
              </div>
            </div>

            <div class="form-row">
              <div class="form-group col-md-4">
                <label for="contact">担当者 <span class="badge badge-danger">必須</span></label>
                <input type="text" class="form-control ${errors.has('contact') ? 'is-invalid' : ''}"
                       id="contact" name="contact" value="${fn:escapeXml(form.contact)}"
                       placeholder="例: 田中 一郎">
                <div class="invalid-feedback">${fn:escapeXml(errors.get('contact'))}</div>
              </div>
              <div class="form-group col-md-8">
                <label for="email">メールアドレス <span class="badge badge-danger">必須</span></label>
                <input type="text" class="form-control ${errors.has('email') ? 'is-invalid' : ''}"
                       id="email" name="email" value="${fn:escapeXml(form.email)}"
                       placeholder="例: tanaka@example.com">
                <div class="invalid-feedback">${fn:escapeXml(errors.get('email'))}</div>
              </div>
            </div>

            <button type="submit" class="btn btn-primary">
              ${editing ? '更新する' : '登録する'}
            </button>
            <a class="btn btn-link" href="${sampleUrl}">一覧へ戻る</a>
          </form>
        </t:panel>
      </c:when>

      <%-- ============================ 一覧 ============================ --%>
      <c:otherwise>
        <t:panel title="取引先マスタ" note="登録・編集・削除の起点になる画面です">
          <div class="mb-3">
            <a class="btn btn-primary" href="${sampleUrl}?action=new">新規登録</a>
          </div>

          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <thead>
                <tr>
                  <th>コード</th><th>取引先名</th><th>担当者</th><th>メールアドレス</th>
                  <th class="text-center">version</th><th style="width: 9rem;"></th>
                </tr>
              </thead>
              <tbody>
                <c:choose>
                  <c:when test="${empty customers}">
                    <tr>
                      <td colspan="6" class="text-center text-muted">
                        登録されている取引先がありません。
                      </td>
                    </tr>
                  </c:when>
                  <c:otherwise>
                    <c:forEach var="customer" items="${customers}">
                      <tr>
                        <td><code>${fn:escapeXml(customer.code)}</code></td>
                        <td>${fn:escapeXml(customer.name)}</td>
                        <td>${fn:escapeXml(customer.contact)}</td>
                        <td class="small">${fn:escapeXml(customer.email)}</td>
                        <td class="text-center">
                          <span class="badge badge-secondary">${customer.version}</span>
                        </td>
                        <td>
                          <a class="btn btn-sm btn-outline-primary"
                             href="${sampleUrl}?action=edit&id=${customer.id}">編集</a>
                          <%-- 削除は「確認画面を開く」だけなので GET でよい。
                               実際に消すのは確認画面からの POST --%>
                          <a class="btn btn-sm btn-outline-danger"
                             href="${sampleUrl}?action=delete&id=${customer.id}">削除</a>
                        </td>
                      </tr>
                    </c:forEach>
                  </c:otherwise>
                </c:choose>
              </tbody>
            </table>
          </div>
        </t:panel>

        <t:panel title="元に戻す" note="何度でも試せます">
          <form action="${sampleUrl}" method="post">
            <input type="hidden" name="action" value="reset">
            <button type="submit" class="btn btn-outline-secondary">初期状態に戻す</button>
          </form>
          <hr>
          <p class="mb-0 text-muted small">
            この取引先マスタは
            <a href="${ctx}/samples/list/optimistic-lock">更新の競合（楽観ロック）</a>
            のサンプルと共有しています。
            データはメモリ上の H2 に入っていて、このサイトを見ている全員で共有しています。
          </p>
        </t:panel>
      </c:otherwise>
    </c:choose>

  </jsp:body>
</t:sample>
