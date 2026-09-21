<%--
  【サンプル】入力 → 確認 → 完了

  ConfirmFormServlet が次の値をセットします。
    step           … "input"（入力画面）か "confirm"（確認画面）
    form           … 入力値（SeminarForm）
    errors         … 入力チェックの結果
    carry          … 値の持ち回り方（"hidden" か "session"）
    sessionCarry   … セッション方式かどうか
    availableDates … 選べる参加日
    oneTimeToken   … 二重送信を防ぐための 1 回きりのトークン（確認画面のみ）
    flash          … 完了メッセージ（リダイレクト後の 1 回だけ）

  画面は 3 つですが、URL は 1 つです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/form/confirm-form" />
<t:sample sampleId="confirm-form">

  <jsp:attribute name="explanation">
    <h2>画面は 3 つ、URL は 1 つ</h2>
<pre><code class="language-plaintext">［入力］ --POST action=confirm--> ［確認］ --POST action=submit--> ［完了］
   ↑                                 │
   └-------POST action=back----------┘</code></pre>
    <p>
      どの段階を表示するかは、リクエストごとに Servlet が決めます。
      URL を分けて <code>/input</code> <code>/confirm</code> <code>/complete</code> と
      作る流儀もありますが、その場合は
      <strong>確認画面の URL を直接開かれたとき</strong>の扱いを決めておく必要があります
      （入力画面へ戻す、が定石です）。
    </p>

    <h2>確認画面へ進むのも POST</h2>
    <p>
      GET にすると、入力値が URL に出ます。
      ブラウザの履歴・アクセスログ・<code>Referer</code> に残り、肩越しにも見えます。
      <strong>入力値を運ぶのは常に POST</strong> です。
    </p>

    <h2>値の持ち回り方は 2 つ</h2>
    <p>このサンプルでは、上のスイッチでどちらも試せます。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th></th><th>隠し項目（hidden）</th><th>セッション</th></tr>
        </thead>
        <tbody>
          <tr><td>置き場所</td><td>画面（HTML の中）</td><td>サーバのメモリ</td></tr>
          <tr><td>複数タブ</td><td><strong>問題なし</strong>（タブごとに独立）</td>
              <td><strong>混ざる</strong>（あとから開いたタブの値で上書きされる）</td></tr>
          <tr><td>改ざん</td><td><strong>される前提で考える</strong></td><td>されない</td></tr>
          <tr><td>大きなデータ</td><td>向かない（画面が重くなる）</td><td>向く</td></tr>
          <tr><td>消し忘れ</td><td>起きない</td><td><strong>起きる</strong>（明示的に消す）</td></tr>
          <tr><td>戻るボタン</td><td>素直に動く</td><td>ずれることがある</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      項目が少なければ隠し項目、ファイルや大きなデータを含むならセッション、
      が目安です。セッションを使うときは<strong>使い終わったら必ず消します</strong>。
    </p>
<pre><code class="language-java">// 登録が終わったら片づける。消し忘れるとメモリに残り続ける
session.removeAttribute("confirmFormSample.form");
session.removeAttribute("confirmFormSample.token");</code></pre>

    <h2>確定するときに、必ず検証をやり直す</h2>
    <p>
      これがこのサンプルでいちばん大事なところです。
      <strong>「確認画面を通ったから正しいはず」は成り立ちません。</strong>
    </p>
    <ul>
      <li>
        隠し項目は<strong>書き換えられます</strong>。
        開発者ツールで value を変えて送るのは誰にでもできます
      </li>
      <li>
        セッションの値も、<strong>確認画面を出した時点では正しかった</strong>だけです。
        その間に在庫が無くなったり、締め切りを過ぎたりしているかもしれません
      </li>
      <li>
        そもそも確認画面を通さずに、<strong>直接 POST を投げることもできます</strong>
      </li>
    </ul>
<pre><code class="language-java">// 確認画面へ進むとき
ValidationErrors errors = form.validate();

// 確定するとき ―― もう一度
ValidationErrors errors = form.validate();</code></pre>
    <p>
      「二度手間では？」と思うかもしれませんが、
      <strong>入力チェックは通信のたびに行うもの</strong>です。
      画面を信用してよいのは、利用者に親切にするときだけです。
    </p>

    <h2>二重送信を防ぐ</h2>
    <p>
      確認画面で「登録する」を二度押しされると、同じ申し込みが 2 件できます。
      通信が遅いときほど起きます。
    </p>
    <p>
      確認画面を出すときに<strong>1 回きりのトークン</strong>を埋めておき、
      受け取ったら<strong>すぐ捨てます</strong>。2 回目はトークンが無いので弾けます。
    </p>
<pre><code class="language-java">// 確認画面を出すとき
session.setAttribute(TOKEN_KEY, newToken());

// 受け取ったとき
synchronized (session) {
    Object expected = session.getAttribute(TOKEN_KEY);
    if (!expected.equals(request.getParameter("token"))) {
        return false;            // 2 回目はここで弾かれる
    }
    session.removeAttribute(TOKEN_KEY);   // 使ったら捨てる
}</code></pre>
    <p>
      <code>synchronized</code> にしているのは、二度押しの 2 回のリクエストが
      <strong>本当に同時に届く</strong>ことがあるためです。
      確かめてから消すまでの間に割り込まれると、両方が通ってしまいます。
    </p>

    <h3>CSRF トークンとは別もの</h3>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th></th><th>二重送信防止トークン</th><th>CSRF トークン</th></tr></thead>
        <tbody>
          <tr><td>防ぎたいこと</td><td>同じ依頼が 2 回処理されること</td><td>他サイトからの偽の依頼</td></tr>
          <tr><td>相手</td><td>うっかり二度押しした利用者</td><td>攻撃者</td></tr>
          <tr><td>使い回し</td><td><strong>しない</strong>（1 回で捨てる）</td><td>する（セッション中ずっと同じ）</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      目的が違うので<strong>両方必要</strong>です。
      CSRF のほうは
      <a href="${ctx}/samples/session/csrf">CSRF 対策</a>のサンプルで扱っています。
    </p>

    <h2>完了は PRG（POST → リダイレクト → GET）</h2>
    <p>
      登録したあとに完了画面をそのまま <code>forward</code> で出すと、
      利用者が再読み込みしたときにブラウザが「再送信しますか？」と聞いてきます。
      ここで「はい」を押されると、また登録されます。
    </p>
<pre><code class="language-java">Flash.set(request, "success", "申し込みを受け付けました", "受付番号は " + receiptNo + " です。");
response.sendRedirect(request.getContextPath() + PATH);</code></pre>
    <p>
      リダイレクトすると別のリクエストになるので、
      <code>request.setAttribute</code> で入れた値は消えます。
      完了メッセージは<strong>セッションに 1 回だけ預けて渡します</strong>
      （<code>common/Flash.java</code>）。
    </p>

    <h2>確認画面でもエスケープする</h2>
    <p>
      確認画面は「入力された値をそのまま出す」画面なので、
      <strong>XSS がいちばん出やすい場所</strong>です。
      <code>&lt;script&gt;alert(1)&lt;/script&gt;</code> と入力して確認画面へ進んでみてください。
      このサンプルでは <code>fn:escapeXml</code> を通しているので、文字として表示されます。
    </p>
<pre><code class="language-xml">&lt;%-- 必ずエスケープする --%&gt;
${'${fn:escapeXml(form.name)}'}

&lt;%-- 隠し項目の value も同じ。ここを忘れると属性から抜け出される --%&gt;
&lt;input type="hidden" name="name" value="${'${fn:escapeXml(form.name)}'}"&gt;</code></pre>

    <h2>確認画面はいつも必要か</h2>
    <p>
      「間違えると取り返しがつかない」処理には向きますが、
      <strong>何にでも付ければよいものではありません</strong>。
      手数が増えて入力をやめてしまう原因にもなります。
    </p>
    <ul>
      <li><strong>向く</strong> … 申込、発注、送金、退会、一括削除</li>
      <li><strong>向かない</strong> … 検索条件の保存、下書きの保存、いつでも直せる設定変更</li>
      <li>
        代わりの手として、入力欄のそばで随時チェックする
        （<a href="${ctx}/samples/form/realtime-validation">入力チェック（フォーカスアウト時）</a>）、
        登録後に取り消せるようにする、という形もあります
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>

    <t:resultModal message="${flash}" />

    <t:panel title="値の持ち回り方" note="どちらでも同じ流れになります。違いは解説のタブに">
      <div class="btn-group" role="group" aria-label="持ち回り方">
        <a class="btn ${not sessionCarry ? 'btn-primary' : 'btn-outline-primary'}"
           href="${formUrl}?carry=hidden">隠し項目（hidden）で運ぶ</a>
        <a class="btn ${sessionCarry ? 'btn-primary' : 'btn-outline-primary'}"
           href="${formUrl}?carry=session">セッションに預ける</a>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        <c:choose>
          <c:when test="${sessionCarry}">
            確認画面の HTML には入力値が入りません（サーバのメモリに預けています）。
            確認画面でブラウザの「ソースを表示」をしてみてください。
            別のタブで同時に入力すると、<strong>あとから確認画面へ進んだほうの値で上書きされます</strong>。
          </c:when>
          <c:otherwise>
            確認画面の HTML に、入力値が隠し項目として入ります。
            開発者ツールで書き換えて送信してみてください。
            <strong>確定時にもう一度検証している</strong>ので、
            おかしな値は弾かれます。
          </c:otherwise>
        </c:choose>
      </p>
    </t:panel>

    <%-- 画面の先頭にエラーの一覧を出す --%>
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

    <c:choose>
      <%-- ============================ 入力画面 ============================ --%>
      <c:when test="${step eq 'input'}">
        <t:panel title="① 入力" note="セミナー申込フォーム">
          <form action="${formUrl}" method="post" novalidate>
            <input type="hidden" name="action" value="confirm">
            <input type="hidden" name="carry" value="${fn:escapeXml(carry)}">

            <div class="form-group">
              <label for="name">氏名 <span class="badge badge-danger">必須</span></label>
              <input type="text" class="form-control ${errors.has('name') ? 'is-invalid' : ''}"
                     id="name" name="name" value="${fn:escapeXml(form.name)}"
                     placeholder="例: 山田太郎">
              <div class="invalid-feedback">${fn:escapeXml(errors.get('name'))}</div>
            </div>

            <div class="form-group">
              <label for="company">会社名 <span class="badge badge-secondary">任意</span></label>
              <input type="text" class="form-control ${errors.has('company') ? 'is-invalid' : ''}"
                     id="company" name="company" value="${fn:escapeXml(form.company)}"
                     placeholder="例: 株式会社サンプル">
              <div class="invalid-feedback">${fn:escapeXml(errors.get('company'))}</div>
            </div>

            <div class="form-group">
              <label for="email">メールアドレス <span class="badge badge-danger">必須</span></label>
              <input type="text" class="form-control ${errors.has('email') ? 'is-invalid' : ''}"
                     id="email" name="email" value="${fn:escapeXml(form.email)}"
                     placeholder="例: taro@example.com">
              <div class="invalid-feedback">${fn:escapeXml(errors.get('email'))}</div>
            </div>

            <div class="form-row">
              <div class="form-group col-md-6">
                <label for="attendDate">参加日 <span class="badge badge-danger">必須</span></label>
                <select class="form-control ${errors.has('attendDate') ? 'is-invalid' : ''}"
                        id="attendDate" name="attendDate">
                  <option value="">選んでください</option>
                  <c:forEach var="date" items="${availableDates}">
                    <option value="${date}" ${form.attendDate eq date ? 'selected' : ''}>${date}</option>
                  </c:forEach>
                </select>
                <div class="invalid-feedback">${fn:escapeXml(errors.get('attendDate'))}</div>
              </div>

              <div class="form-group col-md-6">
                <label for="headcount">人数 <span class="badge badge-danger">必須</span></label>
                <input type="text" class="form-control ${errors.has('headcount') ? 'is-invalid' : ''}"
                       id="headcount" name="headcount" value="${fn:escapeXml(form.headcount)}"
                       placeholder="例: 2">
                <div class="invalid-feedback">${fn:escapeXml(errors.get('headcount'))}</div>
                <small class="form-text text-muted">1 〜 10 の半角数字。</small>
              </div>
            </div>

            <div class="form-group">
              <label for="note">備考 <span class="badge badge-secondary">任意</span></label>
              <textarea class="form-control ${errors.has('note') ? 'is-invalid' : ''}"
                        id="note" name="note" rows="3"
                        placeholder="200 文字以内">${fn:escapeXml(form.note)}</textarea>
              <div class="invalid-feedback">${fn:escapeXml(errors.get('note'))}</div>
            </div>

            <button type="submit" class="btn btn-primary">確認画面へ</button>
          </form>
        </t:panel>
      </c:when>

      <%-- ============================ 確認画面 ============================ --%>
      <c:otherwise>
        <t:panel title="② 確認" note="この内容で申し込みます">
          <div class="alert alert-info" role="alert">
            まだ申し込みは完了していません。内容を確かめて「この内容で申し込む」を押してください。
          </div>

          <div class="table-responsive">
            <table class="table table-sm table-bordered doc-table">
              <tbody>
                <tr><th scope="row">氏名</th><td>${fn:escapeXml(form.name)}</td></tr>
                <tr>
                  <th scope="row">会社名</th>
                  <td>
                    <c:choose>
                      <c:when test="${empty form.company}"><span class="text-muted">（未入力）</span></c:when>
                      <c:otherwise>${fn:escapeXml(form.company)}</c:otherwise>
                    </c:choose>
                  </td>
                </tr>
                <tr><th scope="row">メールアドレス</th><td>${fn:escapeXml(form.email)}</td></tr>
                <tr><th scope="row">参加日</th><td>${fn:escapeXml(form.attendDateText)}</td></tr>
                <tr><th scope="row">人数</th><td>${form.headcountValue} 名</td></tr>
                <tr>
                  <th scope="row">備考</th>
                  <td>
                    <c:choose>
                      <c:when test="${empty form.note}"><span class="text-muted">（未入力）</span></c:when>
                      <c:otherwise>
                        <%-- 改行を見たとおりに出す。値そのものは必ずエスケープする --%>
                        <span style="white-space: pre-line;">${fn:escapeXml(form.note)}</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="d-flex">
            <%-- 戻る : 値を保持したまま入力画面へ。検証はしない --%>
            <form action="${formUrl}" method="post" class="mr-2">
              <input type="hidden" name="action" value="back">
              <input type="hidden" name="carry" value="${fn:escapeXml(carry)}">
              <c:if test="${not sessionCarry}">
                <input type="hidden" name="name" value="${fn:escapeXml(form.name)}">
                <input type="hidden" name="company" value="${fn:escapeXml(form.company)}">
                <input type="hidden" name="email" value="${fn:escapeXml(form.email)}">
                <input type="hidden" name="attendDate" value="${fn:escapeXml(form.attendDate)}">
                <input type="hidden" name="headcount" value="${fn:escapeXml(form.headcount)}">
                <input type="hidden" name="note" value="${fn:escapeXml(form.note)}">
              </c:if>
              <button type="submit" class="btn btn-outline-secondary">修正する</button>
            </form>

            <%-- 確定 : 二重送信を防ぐトークンを付けて送る --%>
            <form action="${formUrl}" method="post">
              <input type="hidden" name="action" value="submit">
              <input type="hidden" name="carry" value="${fn:escapeXml(carry)}">
              <input type="hidden" name="token" value="${fn:escapeXml(oneTimeToken)}">
              <c:if test="${not sessionCarry}">
                <input type="hidden" name="name" value="${fn:escapeXml(form.name)}">
                <input type="hidden" name="company" value="${fn:escapeXml(form.company)}">
                <input type="hidden" name="email" value="${fn:escapeXml(form.email)}">
                <input type="hidden" name="attendDate" value="${fn:escapeXml(form.attendDate)}">
                <input type="hidden" name="headcount" value="${fn:escapeXml(form.headcount)}">
                <input type="hidden" name="note" value="${fn:escapeXml(form.note)}">
              </c:if>
              <button type="submit" class="btn btn-primary">この内容で申し込む</button>
            </form>
          </div>

          <hr>
          <p class="mb-0 text-muted small">
            <c:choose>
              <c:when test="${sessionCarry}">
                この画面の HTML には入力値が入っていません（サーバのメモリに預けています）。
                入っているのは、持ち回り方とトークンだけです。
              </c:when>
              <c:otherwise>
                この画面の HTML には、入力値が隠し項目として入っています。
                開発者ツールで書き換えて送ってみてください。
                <strong>確定時にもう一度検証している</strong>ので、おかしな値は弾かれます。
              </c:otherwise>
            </c:choose>
            申し込んだあとにブラウザの「戻る」で確認画面へ戻り、
            もう一度送信すると<strong>二重送信として弾かれます</strong>。
          </p>
        </t:panel>
      </c:otherwise>
    </c:choose>

  </jsp:body>
</t:sample>
