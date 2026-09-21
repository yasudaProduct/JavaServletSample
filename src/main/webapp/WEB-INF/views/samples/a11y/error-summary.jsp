<%--
  【サンプル】エラーの伝え方（エラーサマリとフォーカス移動）

  ErrorSummaryServlet から errors / form / fieldIds / fieldLabels を受け取ります。
  入力チェックの中身ではなく、「結果をどう画面に出すか」だけを扱うサンプルです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="error-summary">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>エラーは「出す」だけでは伝わらない</h2>
    <p>
      入力チェックに引っかかったとき、欄の下に赤い文字を出して終わり、という画面をよく見ます。
      目で全体を見渡せる人はそれで気づけますが、次の人たちは気づけません。
    </p>
    <ul>
      <li>
        <strong>スクリーンリーダーの利用者</strong>：送信ボタンを押した後、
        ページの先頭に戻されるだけです。「何か変わった」ことすら分からず、
        エラーの赤字は<strong>ページの途中まで読み進めて初めて</strong>出てきます
      </li>
      <li>
        <strong>画面を拡大している人</strong>：一度に見える範囲が狭いため、
        画面の下の方にあるエラーに気づけません
      </li>
      <li>
        <strong>色が見分けにくい人</strong>：枠が赤くなっただけでは、
        正常な欄との区別が付きません
      </li>
    </ul>

    <h2>やること 4 つ</h2>
    <ol>
      <li>
        <strong>画面の先頭にエラーサマリ（一覧）を出す</strong>。
        「何件エラーがあるか」と「それぞれの内容」を、フォームの前にまとめます
      </li>
      <li>
        <strong>サマリから各欄へリンクする</strong>。
        <code>&lt;a href="#esName"&gt;</code> のように入力欄の <code>id</code> を指すと、
        クリック（Enter）でその欄へ飛べます
      </li>
      <li>
        <strong>サマリにフォーカスを移す</strong>。
        画面が再表示された直後に <code>focus()</code> することで、
        スクリーンリーダーがその場でエラーを読み上げます
      </li>
      <li>
        <strong>各欄に <code>aria-invalid</code> と <code>aria-describedby</code> を付ける</strong>。
        欄へ飛んだときに、その欄のメッセージが読まれるようにします
      </li>
    </ol>

    <h2>エラーサマリの書き方</h2>
    <pre><code class="language-xml">&lt;div class="alert alert-danger" role="alert" id="errorSummary" tabindex="-1"&gt;
  &lt;h2&gt;入力内容に 2 件の誤りがあります&lt;/h2&gt;
  &lt;ul&gt;
    &lt;li&gt;&lt;a href="#esName"&gt;氏名を入力してください。&lt;/a&gt;&lt;/li&gt;
    &lt;li&gt;&lt;a href="#esQuantity"&gt;数量は 1 以上 99 以下で入力してください。&lt;/a&gt;&lt;/li&gt;
  &lt;/ul&gt;
&lt;/div&gt;</code></pre>
    <ul>
      <li>
        <strong><code>tabindex="-1"</code></strong> … 「Tab では止まらないが、
        JavaScript からはフォーカスできる」状態にします。
        これを付けないと <code>focus()</code> が効きません。
        <strong><code>tabindex="0"</code> にしてはいけません</strong>
        （Tab の順番に割り込んで、毎回そこで止まるようになります）
      </li>
      <li>
        <strong><code>role="alert"</code></strong> … 読み上げソフトに
        「割り込んででも読む内容」だと伝えます。
        ただし<strong>ページ全体を読み込み直した直後は読まれないことがある</strong>ため、
        フォーカス移動と<strong>両方</strong>やります
      </li>
      <li>
        <strong>件数を書く</strong> … 「2 件」と先に伝えると、
        画面を見ていない人でも<strong>どれだけ直す必要があるか</strong>が分かります
      </li>
      <li>
        <strong>並び順は画面の並び順と揃える</strong> …
        サマリと欄の順番が違うと、上から順に直していく人が迷います。
        このサンプルでは Servlet 側の <code>LinkedHashMap</code> で順番を固定しています
      </li>
    </ul>

    <h2>各欄に付けるもの</h2>
    <pre><code class="language-xml">&lt;label for="esName"&gt;氏名（必須）&lt;/label&gt;
&lt;input type="text" id="esName" name="name" class="form-control is-invalid"
       aria-invalid="true" aria-describedby="esNameError"&gt;
&lt;div class="invalid-feedback" id="esNameError"&gt;
  &lt;strong&gt;エラー：&lt;/strong&gt;氏名を入力してください。
&lt;/div&gt;</code></pre>
    <ul>
      <li>
        <code>aria-invalid="true"</code> … 読み上げで「無効な入力」と伝わります。
        <strong>エラーが無い欄には付けません</strong>
        （<code>aria-invalid="false"</code> をわざわざ書く必要もありません）
      </li>
      <li>
        <code>aria-describedby</code> … メッセージの <code>id</code> を指します。
        注記もある欄は <code>aria-describedby="esNameHelp esNameError"</code> と
        半角スペースで並べます（読まれる順番も書いた順です）
      </li>
      <li>
        メッセージの先頭に <strong>「エラー：」という文字</strong>を入れています。
        赤い色が見えない人にも、そこがエラーだと伝わるようにするためです
        （<strong>色だけに頼らない</strong>：WCAG 達成基準 1.4.1）
      </li>
    </ul>

    <h2>メッセージの書き方</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 34%;">✗ こう書かない</th><th>✓ こう書く</th></tr>
        </thead>
        <tbody>
          <tr><td>入力エラーです</td><td>氏名を入力してください。</td></tr>
          <tr><td>不正な値です</td><td>数量は 1 以上 99 以下で入力してください。</td></tr>
          <tr><td>形式が違います</td><td>メールアドレスは taro@example.com の形式で入力してください。</td></tr>
          <tr><td>20 文字以内です</td><td>氏名は 20 文字以内で入力してください。（現在 25 文字）</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      <strong>項目名を必ず入れます。</strong>
      エラーサマリでは欄から切り離されて読まれるため、
      「入力してください」だけでは何のことか分かりません。
    </p>

    <h2>成功したときも同じように伝える</h2>
    <p>
      登録が終わったときも、画面の上に緑の帯を出すだけでは読み上げ利用者に伝わりません。
      完了メッセージにも <code>tabindex="-1"</code> を付けてフォーカスを移します。
      このサンプルでは <code>Flash</code>（セッション経由の受け渡し）でメッセージを持ち回り、
      リダイレクト後の画面で読み上げています。
    </p>

    <h2>さらにやるなら</h2>
    <ul>
      <li>
        <strong><code>&lt;title&gt;</code> にもエラーを入れる</strong>：
        「エラー：依頼フォーム | サイト名」のようにすると、
        タブを見ただけで分かり、読み上げでもページ読み込み時に伝わります
      </li>
      <li>
        <strong>ブラウザ標準の吹き出しに頼らない</strong>：
        <code>required</code> だけだと、ブラウザが出す吹き出しは<strong>数秒で消え</strong>、
        拡大表示では画面外に出ることもあります。サーバ側のチェックと画面表示が本体です
      </li>
      <li>
        <strong>フォーカスアウトのたびにエラーを出す場合</strong>は、
        入力の途中で割り込まないよう <code>role="alert"</code> ではなく
        <code>aria-live="polite"</code> を使います
        （<a href="${ctx}/samples/form/realtime-validation">入力チェック（フォーカスアウト時）</a>）
      </li>
    </ul>

    <h2>関連するサンプル</h2>
    <ul>
      <li><a href="${ctx}/samples/form/input-validation">入力チェック（サーバ側）</a> … チェックの仕組みそのもの</li>
      <li><a href="${ctx}/samples/form/validation-rules">入力チェックの種類</a> … 必須・文字種・桁数・相関チェックの書き分け</li>
      <li><a href="${ctx}/samples/a11y/form-labels">ラベルの付け方と入力欄のグループ化</a> … <code>aria-describedby</code> の基本</li>
      <li><a href="${ctx}/samples/a11y/live-region">画面の変化を知らせる</a> … <code>role="alert"</code> と <code>aria-live</code> の使い分け</li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // エラーサマリ / 完了メッセージにフォーカスを移します。
      //
      // ページを読み込み直した直後は role="alert" が読まれないことがあるため、
      // 「フォーカスを移す」方を本命の手段にしています。
      // tabindex="-1" が付いているので focus() できます。
      (function () {
        'use strict';

        var target = document.getElementById('errorSummary')
                  || document.getElementById('successMessage');
        if (!target) {
          return;
        }

        // preventScroll は指定しません。画面もその位置まで動いてほしいためです。
        target.focus();
      })();
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <div class="alert alert-info" role="alert">
      <strong>何も入力せずに「送信する」を押してみてください。</strong>
      画面の先頭にエラーの一覧が出て、そこにフォーカスが移ります。
      一覧の項目をクリック（または Enter）すると、その入力欄へ飛べます。
    </div>

    <t:panel title="依頼フォーム">

      <c:if test="${not empty flash}">
        <%--
          完了メッセージ。
          role="status" は「今読んでいる内容を邪魔せずに読む」指定です。
          ここでもフォーカスを移すので tabindex="-1" を付けています。
        --%>
        <div class="alert alert-success" role="status" id="successMessage" tabindex="-1">
          <h2 class="h5 alert-heading">
            <t:icon name="check-circle" cssClass="mr-1" />${fn:escapeXml(flash.title)}
          </h2>
          <p class="mb-0">${fn:escapeXml(flash.text)}</p>
        </div>
      </c:if>

      <c:if test="${not empty errors.messages}">
        <%--
          エラーサマリ。
          並び順は Servlet の fieldIds / fieldLabels の登録順 = 画面の並び順です。
        --%>
        <div class="alert alert-danger" role="alert" id="errorSummary" tabindex="-1">
          <h2 class="h5 alert-heading">
            入力内容に ${errors.count} 件の誤りがあります
          </h2>
          <p class="mb-2">次の項目を修正してから、もう一度送信してください。</p>
          <ul class="mb-0">
            <c:forEach var="entry" items="${errors.fields}">
              <li>
                <a class="alert-link" href="#${fieldIds[entry.key]}">
                  ${fn:escapeXml(entry.value)}
                </a>
              </li>
            </c:forEach>
          </ul>
        </div>
      </c:if>

      <form method="post" action="${ctx}/samples/a11y/error-summary" novalidate>

        <%-- 氏名 --%>
        <c:set var="nameInvalid" value="${errors.has('name')}" />
        <div class="form-group">
          <label for="esName">氏名（必須）</label>
          <input type="text" class="form-control ${nameInvalid ? 'is-invalid' : ''}"
                 id="esName" name="name" value="${fn:escapeXml(form.name)}"
                 autocomplete="name" maxlength="40"
                 aria-describedby="esNameHelp${nameInvalid ? ' esNameError' : ''}"
                 ${nameInvalid ? 'aria-invalid="true"' : ''}>
          <c:if test="${nameInvalid}">
            <div class="invalid-feedback" id="esNameError">
              <strong>エラー：</strong>${fn:escapeXml(errors.get('name'))}
            </div>
          </c:if>
          <small id="esNameHelp" class="form-text text-muted">20 文字以内で入力してください。</small>
        </div>

        <%-- メールアドレス --%>
        <c:set var="emailInvalid" value="${errors.has('email')}" />
        <div class="form-group">
          <label for="esEmail">メールアドレス（必須）</label>
          <input type="email" class="form-control ${emailInvalid ? 'is-invalid' : ''}"
                 id="esEmail" name="email" value="${fn:escapeXml(form.email)}"
                 autocomplete="email" placeholder="taro@example.com"
                 aria-describedby="esEmailHelp${emailInvalid ? ' esEmailError' : ''}"
                 ${emailInvalid ? 'aria-invalid="true"' : ''}>
          <c:if test="${emailInvalid}">
            <div class="invalid-feedback" id="esEmailError">
              <strong>エラー：</strong>${fn:escapeXml(errors.get('email'))}
            </div>
          </c:if>
          <small id="esEmailHelp" class="form-text text-muted">結果の連絡先として使います。</small>
        </div>

        <div class="form-row">
          <%-- 数量 --%>
          <c:set var="quantityInvalid" value="${errors.has('quantity')}" />
          <div class="form-group col-md-6">
            <label for="esQuantity">数量（必須）</label>
            <input type="text" class="form-control ${quantityInvalid ? 'is-invalid' : ''}"
                   id="esQuantity" name="quantity" value="${fn:escapeXml(form.quantity)}"
                   inputmode="numeric" maxlength="2"
                   aria-describedby="esQuantityHelp${quantityInvalid ? ' esQuantityError' : ''}"
                   ${quantityInvalid ? 'aria-invalid="true"' : ''}>
            <c:if test="${quantityInvalid}">
              <div class="invalid-feedback" id="esQuantityError">
                <strong>エラー：</strong>${fn:escapeXml(errors.get('quantity'))}
              </div>
            </c:if>
            <small id="esQuantityHelp" class="form-text text-muted">1 以上 99 以下の半角数字。</small>
          </div>

          <%-- 希望日 --%>
          <c:set var="wantedOnInvalid" value="${errors.has('wantedOn')}" />
          <div class="form-group col-md-6">
            <label for="esWantedOn">希望日（必須）</label>
            <input type="date" class="form-control ${wantedOnInvalid ? 'is-invalid' : ''}"
                   id="esWantedOn" name="wantedOn" value="${fn:escapeXml(form.wantedOn)}"
                   aria-describedby="esWantedOnHelp${wantedOnInvalid ? ' esWantedOnError' : ''}"
                   ${wantedOnInvalid ? 'aria-invalid="true"' : ''}>
            <c:if test="${wantedOnInvalid}">
              <div class="invalid-feedback" id="esWantedOnError">
                <strong>エラー：</strong>${fn:escapeXml(errors.get('wantedOn'))}
              </div>
            </c:if>
            <small id="esWantedOnHelp" class="form-text text-muted">
              対応できない日は、後から連絡します。
            </small>
          </div>
        </div>

        <button type="submit" class="btn btn-primary">送信する</button>
        <a class="btn btn-link" href="${ctx}/samples/a11y/error-summary">入力をやり直す</a>
      </form>

      <p class="small text-muted mt-3 mb-0">
        <code>novalidate</code> を付けて、ブラウザ標準のエラー表示を止めてあります。
        サーバ側のチェック結果だけで画面を組み立てているのを見てもらうためです。
        実際の画面では <code>required</code> を付けて、<strong>両方</strong>効かせます。
      </p>
    </t:panel>

    <t:panel title="よくある「伝わらない」出し方">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 赤い枠だけ</span>
            <label for="badColorOnly">数量</label>
            <input type="text" class="form-control is-invalid" id="badColorOnly" value="0">
            <p class="small mt-2 mb-0">
              色が見えない人には、正常な欄と区別が付きません。
              <strong>何がだめなのか</strong>もどこにも書かれていません。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ アイコンだけ</span>
            <label for="badIconOnly">数量</label>
            <div class="input-group">
              <input type="text" class="form-control is-invalid" id="badIconOnly" value="0">
              <div class="input-group-append">
                <span class="input-group-text text-danger">✗</span>
              </div>
            </div>
            <p class="small mt-2 mb-0">
              読み上げでは記号がそのまま読まれるか、読み飛ばされます。
              理由が分からないのは同じです。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 文字で理由を書く</span>
            <label for="goodMessage">数量</label>
            <input type="text" class="form-control is-invalid" id="goodMessage" value="0"
                   aria-invalid="true" aria-describedby="goodMessageError">
            <div class="invalid-feedback d-block" id="goodMessageError">
              <strong>エラー：</strong>数量は 1 以上 99 以下で入力してください。
            </div>
            <p class="small mt-2 mb-0">
              色・アイコン・文字の 3 つで伝えます。<strong>文字が主役</strong>です。
            </p>
          </div>
        </div>
      </div>
      <p class="mb-0 small text-muted">
        <code>alert()</code> でエラーを出す作りも避けます。
        一度閉じると内容を読み返せず、どの欄の話なのかも分からなくなります。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
