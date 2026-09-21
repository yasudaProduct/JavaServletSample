<%--
  【サンプル】更新の競合（楽観ロック）

  OptimisticLockServlet が次の値をセットします。
    customers       … 取引先の一覧（version つき）
    form            … 編集中の内容
    errors          … 入力チェックの結果
    simulated       … 「別の人が更新した状況」を作った直後かどうか
    conflict        … 競合が検出されたかどうか
    currentCustomer … いまデータベースに入っている内容（競合時）
    flash           … 完了メッセージ

  取引先マスタは「マスタメンテナンス」のサンプルと共有しています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/list/optimistic-lock" />
<t:sample sampleId="optimistic-lock">

  <jsp:attribute name="explanation">
    <h2>何も対策しないと、黙って消える</h2>
<pre><code class="language-plaintext">10:00  A さんが編集画面を開く      (氏名を直したい)
10:01  B さんが編集画面を開く      (電話番号を直したい)
10:02  B さんが保存               → 電話番号が直る
10:05  A さんが保存               → 画面が持っていた「古い電話番号」で上書き</code></pre>
    <p>
      A さんは氏名しか触っていないつもりでも、
      画面が持っていたのは<strong>10:00 時点のデータ全体</strong>です。
      保存すると、B さんの修正がなかったことになります。
      <strong>誰もエラーに気付きません。</strong>これが「更新の喪失」です。
    </p>
    <p>
      気付かないのがいちばん怖いところです。
      「電話番号を直したはずなのに戻っている」と後日言われて、
      再現もできずに終わります。
    </p>

    <h2>楽観ロック : 更新のときに気付く</h2>
    <p>
      行に <code>version</code> という数を持たせ、更新のたびに 1 ずつ増やします。
      そして<strong>更新の条件に「開いたときの version」を入れます</strong>。
    </p>
<pre><code class="language-sql">UPDATE customers
   SET name = ?, contact = ?, version = version + 1, updated_at = ?
 WHERE id = ? AND version = ?
                 -- ↑ 画面を開いたときの version</code></pre>
<pre><code class="language-java">int updated = statement.executeUpdate();
if (updated == 0) {
    // 誰かが先に更新していた（または行が消えていた）
    return conflict();
}</code></pre>
    <p>
      B さんが先に保存していれば version は 2 になっているので、
      A さんの <code>WHERE ... AND version = 1</code> はどの行にも当たらず、
      <strong>更新件数が 0</strong> になります。これで気付けます。
    </p>

    <h3>先に SELECT して比べては駄目</h3>
<pre><code class="language-java">// 【駄目】 SELECT と UPDATE の間に割り込まれたら、結局すり抜ける
Customer current = dao.findById(id);
if (current.getVersion() != form.getVersion()) {
    return conflict();
}
dao.update(form);</code></pre>
    <p>
      <strong>1 文の UPDATE の条件に入れる</strong>から意味があります。
      データベースが 1 つの操作として扱ってくれるので、割り込む隙間がありません。
    </p>

    <h3>version と updated_at</h3>
    <p>
      <code>updated_at</code>（最終更新日時）で代用することもできますが、
      <strong>同じ秒のうちに 2 回更新されると見分けられません</strong>。
      ミリ秒まで持っていても、サーバの時刻がずれる、時刻が巻き戻る、といった話が付いて回ります。
      <strong>専用の数の列を持つほうが確実</strong>です。
    </p>

    <h2>悲観ロックとの違い</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th></th><th>楽観ロック</th><th>悲観ロック</th></tr></thead>
        <tbody>
          <tr><td>やり方</td><td><code>version</code> 列で、更新時に気付く</td>
              <td><code>SELECT ... FOR UPDATE</code> で、読んだ時点で押さえる</td></tr>
          <tr><td>ロックする時間</td><td>ほぼ無い</td><td>トランザクションが終わるまで</td></tr>
          <tr><td>競合したとき</td><td>更新しようとした人が気付く</td><td>あとから読む人が待たされる</td></tr>
          <tr><td>向く場面</td><td><strong>Web の画面（ほとんどこちら）</strong></td>
              <td>在庫の引き当てなど、短くて確実に押さえたい処理</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      Web で悲観ロックが向かないのは、<strong>利用者が画面を開いたまま帰ってしまう</strong>からです。
      「編集ボタンを押した瞬間にロックして、保存するまで保持する」は、
      昼休みに戻ってこない人が出た時点で破綻します。
      データベースのロックは、<strong>1 つのトランザクションの中で完結する短い処理</strong>にだけ使います。
    </p>
<pre><code class="language-java">// 悲観ロック : 同じトランザクションの中で完結させる
try (Connection connection = Database.getConnection()) {
    connection.setAutoCommit(false);
    Stock stock = selectForUpdate(connection, productId);   // ここで押さえる
    if (stock.getQuantity() &lt; amount) {
        throw new ApplicationException("E-5001", "在庫が足りません。");
    }
    updateQuantity(connection, productId, stock.getQuantity() - amount);
    connection.commit();                                    // ここで放す
}</code></pre>

    <h2>競合したときに、何を見せるか</h2>
    <p>
      <strong>「エラーです」だけで終わらせないこと。</strong>
      利用者は何をすればよいか分かりません。少なくとも次の 3 つを用意します。
    </p>
    <ul>
      <li><strong>いま保存されている内容</strong>を見せる（誰が何を変えたのか）</li>
      <li><strong>自分が入力した内容</strong>も残す（打ち直させない）</li>
      <li><strong>どうするかを選ばせる</strong>（開き直す／上書きする）</li>
    </ul>
    <p>
      「上書きする」を選ばせるかどうかは業務次第です。
      <strong>勝手に上書きしてはいけません</strong>が、
      選択肢を出さないと「何度やっても保存できない」画面になります。
      項目ごとにどちらを採るか選ばせる（マージさせる）作りにすることもあります。
    </p>

    <h2>削除にも version を付ける</h2>
<pre><code class="language-sql">DELETE FROM customers WHERE id = ? AND version = ?</code></pre>
    <p>
      「一覧を表示したあとに誰かが内容を変えた行を、気付かずに消す」のを防げます。
      一覧の行に <code>version</code> を隠して持たせておけば、削除でも同じ確認ができます。
    </p>

    <h2>トランザクションとの関係</h2>
    <p>
      楽観ロックとトランザクションは<strong>別の話</strong>です。
    </p>
    <ul>
      <li>
        <strong>トランザクション</strong> …
        「複数の更新を、全部やるか 1 つもやらないか」にする
        （<a href="${ctx}/samples/advanced/transaction">トランザクションのサンプル</a>）
      </li>
      <li>
        <strong>楽観ロック</strong> …
        「画面を開いてから保存するまでの間に、他の人が変えていないか」を確かめる
      </li>
    </ul>
    <p>
      トランザクションは数ミリ秒で終わりますが、
      画面を開いてから保存するまでは数分かかります。
      <strong>その長い時間を守るのがトランザクションの仕事ではない</strong>、と考えると分かりやすいです。
    </p>
  </jsp:attribute>

  <jsp:body>

    <t:resultModal message="${flash}" />

    <c:if test="${not empty errors.globals}">
      <div class="alert alert-warning" role="alert">
        <c:forEach var="message" items="${errors.globals}">
          <div>${fn:escapeXml(message)}</div>
        </c:forEach>
      </div>
    </c:if>

    <t:panel title="① 取引先の一覧" note="version は更新のたびに 1 つ増えます">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th>コード</th><th>取引先名</th><th>担当者</th>
              <th class="text-center">version</th><th>最終更新</th><th></th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="customer" items="${customers}">
              <tr class="${customer.id eq form.idValue ? 'table-primary' : ''}">
                <td><code>${fn:escapeXml(customer.code)}</code></td>
                <td>${fn:escapeXml(customer.name)}</td>
                <td>${fn:escapeXml(customer.contact)}</td>
                <td class="text-center"><span class="badge badge-secondary">${customer.version}</span></td>
                <td class="small text-muted">${fn:escapeXml(customer.updatedAtText)}</td>
                <td>
                  <a class="btn btn-sm btn-outline-primary"
                     href="${sampleUrl}?id=${customer.id}">編集</a>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </t:panel>

    <c:if test="${simulated}">
      <div class="alert alert-warning" role="alert">
        <strong>別の人が、この取引先を更新しました。</strong>
        データベース側の version は 1 つ進みましたが、
        <strong>この画面はまだ気付いていません</strong>（隠し項目の version は古いままです）。
        この状態で「更新する」を押してみてください。
      </div>
    </c:if>

    <c:if test="${conflict}">
      <t:panel title="⚠ 競合が検出されました" note="更新できた行が 0 件でした">
        <p>
          この取引先は、あなたが画面を開いたあとに<strong>他の人が変更しています</strong>。
          そのまま保存すると相手の変更が消えてしまうため、いったん止めました。
        </p>

        <div class="table-responsive">
          <table class="table table-sm table-bordered">
            <thead>
              <tr>
                <th style="width: 20%;">項目</th>
                <th>あなたが入力した内容</th>
                <th>いま保存されている内容</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <th scope="row">取引先コード</th>
                <td>${fn:escapeXml(form.code)}</td>
                <td class="${form.code ne currentCustomer.code ? 'table-warning' : ''}">
                  ${fn:escapeXml(currentCustomer.code)}
                </td>
              </tr>
              <tr>
                <th scope="row">取引先名</th>
                <td>${fn:escapeXml(form.name)}</td>
                <td class="${form.name ne currentCustomer.name ? 'table-warning' : ''}">
                  ${fn:escapeXml(currentCustomer.name)}
                </td>
              </tr>
              <tr>
                <th scope="row">担当者</th>
                <td>${fn:escapeXml(form.contact)}</td>
                <td class="${form.contact ne currentCustomer.contact ? 'table-warning' : ''}">
                  ${fn:escapeXml(currentCustomer.contact)}
                </td>
              </tr>
              <tr>
                <th scope="row">メールアドレス</th>
                <td>${fn:escapeXml(form.email)}</td>
                <td class="${form.email ne currentCustomer.email ? 'table-warning' : ''}">
                  ${fn:escapeXml(currentCustomer.email)}
                </td>
              </tr>
              <tr>
                <th scope="row">version</th>
                <td>${fn:escapeXml(form.version)} <span class="text-muted">（開いたとき）</span></td>
                <td class="table-warning">${currentCustomer.version} <span class="text-muted">（現在）</span></td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="d-flex">
          <a class="btn btn-primary mr-2" href="${sampleUrl}?id=${form.idValue}">
            最新の内容で開き直す
          </a>
          <form action="${sampleUrl}" method="post">
            <input type="hidden" name="action" value="force">
            <input type="hidden" name="id" value="${fn:escapeXml(form.id)}">
            <input type="hidden" name="code" value="${fn:escapeXml(form.code)}">
            <input type="hidden" name="name" value="${fn:escapeXml(form.name)}">
            <input type="hidden" name="contact" value="${fn:escapeXml(form.contact)}">
            <input type="hidden" name="email" value="${fn:escapeXml(form.email)}">
            <button type="submit" class="btn btn-outline-danger">
              自分の入力で上書きする
            </button>
          </form>
        </div>

        <hr>
        <p class="mb-0 text-muted small">
          「上書きする」は<strong>相手の変更を捨てる</strong>という判断です。
          勝手に行わず、利用者に選ばせたうえで実行します。
          業務によっては、この選択肢を出さない（必ず開き直させる）こともあります。
        </p>
      </t:panel>
    </c:if>

    <t:panel title="② 編集する" note="隠し項目に version を持たせています">
      <c:choose>
        <c:when test="${empty form.id}">
          <p class="text-muted mb-0">一覧から編集する取引先を選んでください。</p>
        </c:when>
        <c:otherwise>
          <form action="${sampleUrl}" method="post" novalidate>
            <input type="hidden" name="action" value="update">
            <input type="hidden" name="id" value="${fn:escapeXml(form.id)}">
            <%-- これが楽観ロックの本体。画面を開いたときの version を持ち回る --%>
            <input type="hidden" name="version" value="${fn:escapeXml(form.version)}">

            <div class="form-row">
              <div class="form-group col-md-4">
                <label for="code">取引先コード</label>
                <input type="text" class="form-control ${errors.has('code') ? 'is-invalid' : ''}"
                       id="code" name="code" value="${fn:escapeXml(form.code)}">
                <div class="invalid-feedback">${fn:escapeXml(errors.get('code'))}</div>
              </div>
              <div class="form-group col-md-8">
                <label for="name">取引先名</label>
                <input type="text" class="form-control ${errors.has('name') ? 'is-invalid' : ''}"
                       id="name" name="name" value="${fn:escapeXml(form.name)}">
                <div class="invalid-feedback">${fn:escapeXml(errors.get('name'))}</div>
              </div>
            </div>

            <div class="form-row">
              <div class="form-group col-md-4">
                <label for="contact">担当者</label>
                <input type="text" class="form-control ${errors.has('contact') ? 'is-invalid' : ''}"
                       id="contact" name="contact" value="${fn:escapeXml(form.contact)}">
                <div class="invalid-feedback">${fn:escapeXml(errors.get('contact'))}</div>
              </div>
              <div class="form-group col-md-8">
                <label for="email">メールアドレス</label>
                <input type="text" class="form-control ${errors.has('email') ? 'is-invalid' : ''}"
                       id="email" name="email" value="${fn:escapeXml(form.email)}">
                <div class="invalid-feedback">${fn:escapeXml(errors.get('email'))}</div>
              </div>
            </div>

            <p class="text-muted small">
              この画面が持っている version: <code>${fn:escapeXml(form.version)}</code>
            </p>

            <button type="submit" class="btn btn-primary">更新する</button>
          </form>

          <hr>

          <form action="${sampleUrl}" method="post">
            <%-- 入力中の値と「古い version」をそのまま持ち回るのが要点。
                 リダイレクトすると version も新しくなり、競合が起きなくなります --%>
            <input type="hidden" name="action" value="simulate">
            <input type="hidden" name="id" value="${fn:escapeXml(form.id)}">
            <input type="hidden" name="version" value="${fn:escapeXml(form.version)}">
            <input type="hidden" name="code" value="${fn:escapeXml(form.code)}">
            <input type="hidden" name="name" value="${fn:escapeXml(form.name)}">
            <input type="hidden" name="contact" value="${fn:escapeXml(form.contact)}">
            <input type="hidden" name="email" value="${fn:escapeXml(form.email)}">
            <button type="submit" class="btn btn-outline-warning btn-sm">
              別の人が先に更新した状況を作る（デモ用）
            </button>
          </form>
          <p class="mt-2 mb-0 text-muted small">
            本来はブラウザを 2 つ開いて試すところですが、1 人でも試せるようにしたボタンです。
            押すと、データベース側の担当者だけが書き換わり version が進みます。
            <strong>この画面の隠し項目は古いまま</strong>なので、
            続けて「更新する」を押すと競合が検出されます。
          </p>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <t:panel title="③ 元に戻す" note="何度でも試せます">
      <form action="${sampleUrl}" method="post">
        <input type="hidden" name="action" value="reset">
        <button type="submit" class="btn btn-outline-secondary">初期状態に戻す</button>
      </form>
      <hr>
      <p class="mb-0 text-muted small">
        この取引先マスタは
        <a href="${ctx}/samples/list/crud">マスタメンテナンス</a>のサンプルと共有しています。
        データはメモリ上の H2 に入っていて、このサイトを見ている全員で共有しています。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
