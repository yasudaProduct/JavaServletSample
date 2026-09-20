<%--
  【サンプル】CSV ダウンロード

  CsvDownloadServlet が次の値をセットします。
    options         … 画面で選ばれた設定（CsvOptions）
    encodings       … 選べる文字コードの一覧
    csvText         … 選んだ設定で組み立てた CSV そのもの
    records         … 元データ
    downloadUrl     … 同じ設定でダウンロードする URL
    lossyCharacters … その文字コードで表せない文字（Shift_JIS のとき）
    byteLength      … 実際のバイト数

  実際にファイルを書き出すのは CsvExportServlet です。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/file/csv-download" />
<t:sample sampleId="csv-download">

  <jsp:attribute name="explanation">
    <h2>ファイルを返すのに必要なのは 3 つだけ</h2>
<pre><code class="language-java">// ① 何のファイルか
response.setContentType("text/csv");
response.setCharacterEncoding("UTF-8");

// ② ダウンロードさせる／ファイル名はこれ
response.setHeader("Content-Disposition", "attachment; filename=\"sales.csv\"");

// ③ 本文を書く
try (OutputStream out = response.getOutputStream()) {
    out.write(body);
}</code></pre>
    <p>
      <strong>JSP は通しません。</strong>
      JSP は HTML を組み立てるためのもので、タグの外にある改行や空白が
      そのままファイルに混ざります。Servlet から直接書き出します。
    </p>
    <p>
      <code>Content-Disposition</code> を <code>inline</code> にすると、
      ブラウザが開けるファイル（PDF や画像）はその場で表示されます。
      <code>attachment</code> は「保存させる」指定です。
    </p>

    <h2>「Excel で開いたら文字化けした」の正体</h2>
    <p>
      CSV でいちばん多い問い合わせです。原因はほぼ <strong>BOM</strong> です。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>渡す相手</th><th>選ぶもの</th><th>理由</th></tr></thead>
        <tbody>
          <tr>
            <td>Excel で開く人</td>
            <td><strong>UTF-8 + BOM</strong></td>
            <td>BOM が無いと、Excel は環境の既定（日本語 Windows なら Shift_JIS）として読みます</td>
          </tr>
          <tr>
            <td>プログラム</td>
            <td>UTF-8（BOM なし）</td>
            <td>BOM が 1 列目の値に紛れ込んで事故のもとになります</td>
          </tr>
          <tr>
            <td>古いシステム</td>
            <td>Windows-31J</td>
            <td>いわゆる Shift_JIS。<strong>変換できない文字は化けます</strong></td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      BOM は「このファイルは UTF-8 です」という 3 バイト（<code>EF BB BF</code>）の目印です。
      <code>Content-Type</code> の <code>charset</code> だけでは Excel には伝わりません。
      ダウンロードしたあとはただのファイルで、HTTP ヘッダは残らないためです。
    </p>
<pre><code class="language-java">// BOM は「文字」ではなく「3 バイトのデータ」。OutputStream で書くと間違えにくい
try (OutputStream out = response.getOutputStream()) {
    out.write(new byte[] {(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
    out.write(text.getBytes(StandardCharsets.UTF_8));
}</code></pre>
    <p>
      Shift_JIS を選ぶときは、<strong>変換できない文字が黙って <code>?</code> になる</strong>ことに
      注意してください。例外にならないので、渡した相手から指摘されて初めて気付きます。
      出す前に <code>CharsetEncoder#canEncode</code> で確かめられます。
      「①」「㈱」「～」のような文字を出すなら、
      <code>Shift_JIS</code> ではなく <code>Windows-31J</code>（CP932）を使ってください。
    </p>

    <h2>日本語のファイル名</h2>
    <p>
      <code>Content-Disposition</code> ヘッダには、そのままでは ASCII しか書けません。
      日本語のファイル名は <code>filename*</code>（RFC 5987 / RFC 6266）で渡します。
    </p>
<pre><code class="language-plaintext">Content-Disposition: attachment; filename="sales.csv"; filename*=UTF-8''%E5%A3%B2%E4%B8%8A.csv
                                 ~~~~~~~~~~~~~~~~~~~  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                 読めない環境向けの控え   本命（UTF-8 で URL エンコード）</code></pre>
<pre><code class="language-java">String encoded = URLEncoder.encode(fileName, StandardCharsets.UTF_8)
        .replace("+", "%20");   // URLEncoder は空白を + にするが、ここでは %20 でなければならない
response.setHeader("Content-Disposition",
        "attachment; filename=\"sales.csv\"; filename*=UTF-8''" + encoded);</code></pre>
    <p>
      ファイル名に利用者の入力を使うときは、<code>/</code> や <code>\</code>、改行を
      必ず落としてください。改行を入れられると、ヘッダを分割されて
      別のヘッダを差し込まれます（HTTP ヘッダインジェクション）。
    </p>

    <h2>値のエスケープ（RFC 4180）</h2>
    <p>
      CSV は「カンマで区切るだけ」に見えて、<strong>値の中にカンマ・改行・ダブルクォートが
      入った瞬間に壊れます</strong>。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>値の中身</th><th>書き方</th><th>しないとどうなるか</th></tr></thead>
        <tbody>
          <tr><td>区切り文字を含む</td><td>全体を <code>"</code> で囲む</td><td>列がずれる</td></tr>
          <tr><td>改行を含む</td><td>全体を <code>"</code> で囲む</td><td>行が増える</td></tr>
          <tr><td><code>"</code> を含む</td><td>囲んだうえで <code>""</code> に</td><td>囲みが壊れる</td></tr>
          <tr><td>前後に空白</td><td>囲んでおくと安全</td><td>読み込む側で落とされる</td></tr>
        </tbody>
      </table>
    </div>
<pre><code class="language-plaintext">値 : 山田, 太郎       →  "山田, 太郎"
値 : 幅 24" モニタ    →  "幅 24"" モニタ"
値 : 至急
     要確認           →  "至急
     要確認"</code></pre>
    <p>
      下の設定で<strong>「値をエスケープする」を外して</strong>プレビューを見ると、
      列がずれ、行が増える様子がそのまま見られます。
    </p>

    <h2>数式として実行されてしまう（CSV インジェクション）</h2>
    <p>
      <code>=</code> <code>+</code> <code>-</code> <code>@</code> で始まる値は、
      Excel や Google スプレッドシートで開いたときに<strong>数式として解釈されます</strong>。
      利用者が入力した文字列をそのまま CSV に出していると、
      <strong>別の利用者がそのファイルを開いた瞬間に</strong>仕込まれた式が動きます。
    </p>
<pre><code class="language-plaintext">備考欄に入力された値 : =1+1
→ Excel で開くと、セルには 2 と表示される（文字列として扱われない）</code></pre>
    <p>
      対策は、危ない文字で始まる値の前に <code>'</code> を付けて
      「これは文字列です」と伝えることです。ただし
      <strong><code>-100</code> のような負の数まで文字列にしてしまうと集計できなくなる</strong>ので、
      数値として読める値は対象から外します。
    </p>

    <h2>行数が多いとき</h2>
    <p>
      このサンプルは 8 件なのでメモリ上で組み立てていますが、
      数万件・数十万件になると<strong>そのやり方では落ちます</strong>。
      全部をメモリに載せず、<strong>1 行取り出しては 1 行書く</strong>形にします。
    </p>
<pre><code class="language-java">try (Connection connection = Database.getConnection();
     PreparedStatement statement = connection.prepareStatement(SQL);
     ResultSet rs = statement.executeQuery();
     PrintWriter out = response.getWriter()) {

    statement.setFetchSize(1000);   // JDBC ドライバにも「まとめて全部読むな」と伝える

    while (rs.next()) {
        out.print(csvLineOf(rs));   // 1 行ずつ書き出す
    }
}</code></pre>
    <ul>
      <li>
        <code>setContentLength</code> は<strong>付けられません</strong>（書き終わるまで長さが分からない）。
        ブラウザは進捗を出せませんが、それと引き換えにメモリを使わずに済みます
      </li>
      <li>
        <strong>ヘッダは本文を書き始める前に設定します。</strong>
        1 バイトでも本文を送ったあとでは、<code>Content-Disposition</code> を変えられません
      </li>
      <li>
        書き出しの途中で例外が起きると、<strong>壊れたファイルが落ちてきます</strong>
        （すでに送信が始まっているのでエラーページに差し替えられない）。
        時間のかかる出力は、非同期にして完了後にダウンロードさせる形が安全です
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>

    <t:panel title="① 出力する元データ" note="わざと厄介な値を混ぜてあります">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th>受注番号</th><th>受注日</th><th>取引先</th><th>商品名</th>
              <th class="text-right">数量</th><th class="text-right">金額</th><th>備考</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="record" items="${records}">
              <tr>
                <td><code>${fn:escapeXml(record.orderNo)}</code></td>
                <td>${record.orderDate}</td>
                <td>${fn:escapeXml(record.customer)}</td>
                <td>${fn:escapeXml(record.productName)}</td>
                <td class="text-right">${record.quantity}</td>
                <td class="text-right">${record.amount}</td>
                <td><span style="white-space: pre-line;">${fn:escapeXml(record.note)}</span></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        カンマを含む商品名、ダブルクォートを含む商品名、改行を含む備考、
        数式に見える備考（<code>=1+1</code>）、前後に空白のある取引先、
        負の数の金額（返品）が入っています。
        素直なデータだけで試すと、エスケープが要ることに気付けません。
      </p>
    </t:panel>

    <t:panel title="② 出力の設定" note="変えるとプレビューにすぐ反映されます">
      <%-- 状態を変えないので GET。設定が URL に残り、そのまま共有できます --%>
      <form action="${sampleUrl}" method="get">
        <input type="hidden" name="submitted" value="1">

        <div class="form-row">
          <div class="form-group col-md-6">
            <label for="encoding">文字コード</label>
            <select class="form-control" id="encoding" name="encoding">
              <c:forEach var="encoding" items="${encodings}">
                <option value="${encoding.key}"
                        ${options.encoding eq encoding ? 'selected' : ''}>
                  ${fn:escapeXml(encoding.label)}
                </option>
              </c:forEach>
            </select>
          </div>

          <div class="form-group col-md-6">
            <label for="delimiter">区切り文字</label>
            <select class="form-control" id="delimiter" name="delimiter">
              <option value="comma" ${not options.tabDelimited ? 'selected' : ''}>
                カンマ（.csv）
              </option>
              <option value="tab" ${options.tabDelimited ? 'selected' : ''}>
                タブ（.tsv）
              </option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="crlf" name="crlf" value="1"
                   ${options.crlf ? 'checked' : ''}>
            <label class="custom-control-label" for="crlf">
              改行コードを CRLF にする<span class="text-muted">（RFC 4180 の決まり）</span>
            </label>
          </div>
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="header" name="header" value="1"
                   ${options.header ? 'checked' : ''}>
            <label class="custom-control-label" for="header">見出し行を付ける</label>
          </div>
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="quote" name="quote" value="1"
                   ${options.quote ? 'checked' : ''}>
            <label class="custom-control-label" for="quote">
              値をエスケープする<span class="text-muted">（外すと壊れる様子が見られます）</span>
            </label>
          </div>
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="guardFormula"
                   name="guardFormula" value="1" ${options.guardFormula ? 'checked' : ''}>
            <label class="custom-control-label" for="guardFormula">
              数式として解釈されうる値を守る<span class="text-muted">（CSV インジェクション対策）</span>
            </label>
          </div>
        </div>

        <button type="submit" class="btn btn-primary">プレビューを更新</button>
        <a class="btn btn-link" href="${sampleUrl}">初期設定に戻す</a>
      </form>
    </t:panel>

    <t:panel title="③ プレビュー" note="ダウンロードされるファイルの中身そのものです">
      <c:if test="${not options.quote}">
        <div class="alert alert-warning" role="alert">
          <strong>エスケープを外しています。</strong>
          カンマを含む商品名で列がずれ、改行を含む備考で行が増えているはずです。
          表計算ソフトで開くと、ずれた位置に値が入ります。
        </div>
      </c:if>
      <c:if test="${not empty lossyCharacters}">
        <div class="alert alert-danger" role="alert">
          <strong>この文字コードでは表せない文字があります。</strong>
          <code>${fn:escapeXml(lossyCharacters)}</code>
          — そのまま出すと <code>?</code> に化けます（例外にはなりません）。
        </div>
      </c:if>

      <p class="text-muted small">
        ${byteLength} バイト /
        文字コード ${fn:escapeXml(options.encoding.label)} /
        改行 ${options.crlf ? 'CRLF' : 'LF'}
      </p>
      <pre class="code-snippet mb-0">${fn:escapeXml(csvText)}</pre>
    </t:panel>

    <t:panel title="④ ダウンロード" note="上と同じ設定でファイルが落ちてきます">
      <a class="btn btn-primary" href="${downloadUrl}">
        <t:icon name="file-earmark-arrow-up" size="14" cssClass="mr-1" />CSV をダウンロード
      </a>
      <hr>
      <p class="mb-0 text-muted small">
        ファイル名は <code>売上明細.csv</code> です。
        <code>Content-Disposition</code> に <code>filename*</code> で渡しているので、
        日本語のまま保存されます。
        ブラウザの開発者ツール（F12）のネットワークタブで、
        実際に送られているヘッダを確かめてみてください。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
