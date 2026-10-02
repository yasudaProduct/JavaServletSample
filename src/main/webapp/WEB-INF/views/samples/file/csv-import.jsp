<%--
  【サンプル】CSV 取り込み（入力チェックとエラー時のログ）

  CsvImportServlet が次の値をセットします。
    sampleFiles     … ダウンロードできる取り込み用 CSV の一覧
    columns         … CSV の列（見出しの並び順・チェック内容・例）
    departments     … 部署マスタ（コード → 名前）
    employmentTypes … 雇用区分の選択肢
    employees       … 登録されている社員
    maxEmployees / maxRows / maxFileSizeKb … 上限
    result          … 直前の取り込み結果（取り込んだ直後だけ）
    logLines        … その取り込みで出たログ（取り込んだ直後だけ）

  取り込み用 CSV のダウンロードは CsvImportTemplateServlet です。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/file/csv-import" />
<t:sample sampleId="csv-import">

  <jsp:attribute name="explanation">
    <h2>取り込みの流れ</h2>
    <p>
      チェックは<strong>外側から順に</strong>行います。
      外側（ファイルそのもの）がおかしいのに、中身の値を 1 つずつ確かめても意味が無いからです。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead><tr><th style="width: 8rem;">段階</th><th>何を確かめるか</th><th style="width: 15rem;">引っかかったら</th></tr></thead>
        <tbody>
          <tr><td>① ファイル</td><td>空でないか / 拡張子は .csv か / 大きすぎないか</td>
              <td rowspan="5">その場で止めて、ファイルごと差し戻す（<code>REJECTED</code>）</td></tr>
          <tr><td>② 文字コード</td><td>選ばれた文字コードで読めるか</td></tr>
          <tr><td>③ CSV の形</td><td><code>"</code> の閉じ忘れが無いか</td></tr>
          <tr><td>④ 見出し</td><td>1 行目がテンプレートと同じか</td></tr>
          <tr><td>⑤ 件数</td><td>データ行が 1 件以上・上限以下か</td></tr>
          <tr><td>⑥ 行ごと</td><td>列の数 → 各列の値 → ファイルの中での重複</td>
              <td>最後の行まで見て、まとめて返す（<code>INVALID</code>）</td></tr>
          <tr><td>⑦ 登録</td><td>全件を 1 つのトランザクションで書く</td>
              <td>全部取り消す（<code>FAILED</code>）</td></tr>
        </tbody>
      </table>
    </div>

    <h2>エラーは最後の行まで見て、まとめて返す</h2>
    <p>
      最初のエラーで止めると、利用者は「直す → 取り込む → 次のエラーが出る」を何十回も繰り返すことになります。
      ⑥ では止めずに最後の行まで確かめ、<strong>行番号・列・入力値・直し方</strong>を一覧にして返します。
    </p>
    <p>
      ただし 1 つの列の中では、<strong>最初に引っかかったところで止めます</strong>。
      空の社員コードに「半角英数字で」「6 文字で」と 3 つ並べても、直す人には 1 つめしか役に立ちません。
      並び順は「必須 → 文字種 → 桁数 → 形式 → 範囲 / マスタ」です
      （フォームの入力チェックと同じ考え方です。「フォーム・入力」カテゴリも参照してください）。
    </p>

    <h2>1 件でもエラーがあれば、1 件も登録しない</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead><tr><th style="width: 13rem;">やり方</th><th>良い点</th><th>困る点</th></tr></thead>
        <tbody>
          <tr>
            <td><strong>全部か、何もしないか</strong>（このサンプル）</td>
            <td>直した CSV をそのまま取り込み直せばよい</td>
            <td>1 行の誤りで全体が止まる</td>
          </tr>
          <tr>
            <td>正しい行だけ登録する</td>
            <td>正しい行はすぐ使える</td>
            <td>取り込み直すとき、<strong>どの行が登録済みか</strong>を利用者が考えることになる。
                二重登録や登録漏れのもと</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      業務システムでは前者が基本です。
      登録も<strong>全件を 1 つのトランザクション</strong>で行い、途中で失敗したら <code>rollback()</code> で全部取り消します。
      デモの「登録の途中で DB 障害を起こす」にチェックを入れて取り込むと、
      途中まで書いた行も残っていないことを確かめられます。
    </p>

    <h2>Excel が作る CSV の癖</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead><tr><th style="width: 13rem;">起きること</th><th>このサンプルでの扱い</th></tr></thead>
        <tbody>
          <tr>
            <td>「CSV (コンマ区切り)」で保存すると <strong>Shift_JIS</strong> になる</td>
            <td>文字コードを選ばせる。読めない文字があれば<strong>化けたまま進まず</strong>差し戻す</td>
          </tr>
          <tr>
            <td>「CSV UTF-8」で保存すると先頭に <strong>BOM</strong> が付く</td>
            <td>BOM があれば UTF-8 と決めて読み、BOM は取り除く（残すと 1 列目の見出しが合わない）</td>
          </tr>
          <tr>
            <td>日付が <code>2026/4/1</code> に書き換わる</td>
            <td><code>2026-04-01</code> と <code>2026/4/1</code> の両方を受け付ける</td>
          </tr>
          <tr>
            <td>最後に <code>,,,,,,</code> だけの行が付く</td>
            <td>空の行は読み飛ばす（エラーにすると、利用者には理由が分からない）</td>
          </tr>
          <tr>
            <td><code>00123</code> が <code>123</code> になる（先頭の 0 が消える）</td>
            <td>社員コードを <code>E</code> で始めて、数値として読まれないようにしている</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      文字コードは <code>new String(bytes, charset)</code> で変換してはいけません。
      読めないバイトが<strong>黙って <code>?</code> や <code>�</code> に置き換わり</strong>、そのまま登録まで進みます。
      <code>CodingErrorAction.REPORT</code> を付けたデコーダを使うと、読めなかったことに気付けます。
    </p>
<pre><code class="language-java">String text = charset.newDecoder()
        .onMalformedInput(CodingErrorAction.REPORT)        // 壊れたバイト列があれば例外
        .onUnmappableCharacter(CodingErrorAction.REPORT)   // 対応する文字が無ければ例外
        .decode(ByteBuffer.wrap(content))
        .toString();</code></pre>

    <h2>行番号の数え方</h2>
    <p>
      見出しを 1 行目として、<strong>Excel で開いたときの行番号</strong>に合わせています。
      値の中に改行がある（<code>"</code> で囲まれた中で改行している）と、
      テキストエディタで見たときの行番号とはずれます。どちらに合わせたかを画面に書いておくと親切です。
    </p>

    <h2>Log4j 2 を使う準備</h2>
    <p>
      <code>pom.xml</code> に 3 つ足し、<code>src/main/resources/log4j2.xml</code> を置くだけです
      （Ant / Eclipse で使う場合は、同じ jar を <code>lib/runtime/</code> に置いています）。
    </p>
<pre><code class="language-xml">&lt;dependency&gt;
  &lt;groupId&gt;org.apache.logging.log4j&lt;/groupId&gt;
  &lt;artifactId&gt;log4j-api&lt;/artifactId&gt;    &lt;!-- コードから呼ぶ側 --&gt;
  &lt;version&gt;2.26.1&lt;/version&gt;
&lt;/dependency&gt;
&lt;dependency&gt;
  &lt;groupId&gt;org.apache.logging.log4j&lt;/groupId&gt;
  &lt;artifactId&gt;log4j-core&lt;/artifactId&gt;   &lt;!-- 実際に書き出す側 --&gt;
  &lt;version&gt;2.26.1&lt;/version&gt;
&lt;/dependency&gt;
&lt;dependency&gt;
  &lt;groupId&gt;org.apache.logging.log4j&lt;/groupId&gt;
  &lt;artifactId&gt;log4j-web&lt;/artifactId&gt;    &lt;!-- アプリの停止時に Log4j を片付ける --&gt;
  &lt;version&gt;2.26.1&lt;/version&gt;
&lt;/dependency&gt;</code></pre>
    <ul>
      <li>
        <strong>Log4j 1.x（<code>log4j:log4j</code>）は使いません。</strong>2015 年に保守が終わっています。
        2.x も <strong>2.17.1 より古い版には Log4Shell（CVE-2021-44228）などの脆弱性</strong>があります
      </li>
      <li>
        <code>log4j-web</code> が無いと、アプリを入れ替えたときに Log4j のスレッドや開いたファイルが残ります
        （Tomcat 9 は jar を入れるだけで自動で読み込みます）
      </li>
      <li>
        テストのときは <code>src/test/resources/log4j2-test.xml</code> が優先されます。
        テスト結果にログが混ざらないよう、こちらは出力先を置いていません
      </li>
    </ul>

    <h2>ログの書き方</h2>
<pre><code class="language-java">// クラスごとに 1 つ、static final で持つ
private static final Logger LOG = LogManager.getLogger(CsvImporter.class);

// 値は {} で埋め込む。+ でつなぐより読みやすく、出さないレベル (DEBUG) では組み立ても省かれる
LOG.info("取り込みを始めます file={} size={}B", fileName, content.length);

// 例外は最後の引数にそのまま渡す ({} の数より 1 つ多い引数は例外として扱われる)
LOG.error("取り込みに失敗しました file={} size={}B", fileName, content.length, e);</code></pre>
    <p>
      <code>LOG.error("失敗: " + e.getMessage())</code> のように<strong>メッセージだけを文字列にするのは間違い</strong>です。
      発生した場所（スタックトレース）と、本当の原因（<code>Caused by:</code>）が消えます。
      <code>NullPointerException</code> なら <code>null</code> としか残りません。
    </p>

    <h2>どのレベルで、何を出すか</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead><tr><th style="width: 6rem;">レベル</th><th>このサンプルで出すもの</th><th>理由</th></tr></thead>
        <tbody>
          <tr>
            <th scope="row">ERROR</th>
            <td>DB に書けなかった（スタックトレース付き）</td>
            <td>人がすぐ見るべきもの。利用者の操作では直らない</td>
          </tr>
          <tr>
            <th scope="row">WARN</th>
            <td>差し戻した理由（文字コード違い・見出し違い）と、入力エラーの<strong>件数</strong></td>
            <td>取り込みが完了しなかった記録。利用者が直せるので人は呼ばない</td>
          </tr>
          <tr>
            <th scope="row">INFO</th>
            <td>取り込みの開始（ファイル名・大きさ）と完了（件数・かかった時間）</td>
            <td>「いつ、何件入ったか」は後から必ず聞かれる</td>
          </tr>
          <tr>
            <th scope="row">DEBUG</th>
            <td>入力エラーの<strong>位置</strong>（行・列・種類）、空行の読み飛ばし、コミット</td>
            <td>開発中の確認用。本番では <code>log4j2.xml</code> で止める</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="topic-callout topic-callout--warn">
      <p class="topic-callout__title">入力エラーを ERROR にしない</p>
      <p class="mb-0">
        利用者の打ち間違いを ERROR で出すと、毎日何百件も ERROR が出ます。
        やがて誰も見なくなり、本物の障害（DB に書けない）が埋もれます。
        ERROR は「人を呼ぶ」と決めておくと、レベル選びで迷いません。
      </p>
    </div>

    <h2>ログに出さないもの</h2>
    <p>
      入力エラーの一覧は、画面には<strong>入力値つき</strong>で出しますが、ログには
      <strong>行番号・列・種類だけ</strong>を出します（<code>CsvImportError#toLogText</code>）。
    </p>
<pre><code class="language-plaintext">画面 : 6 行目 / メールアドレス / ai.shimizu@example / メールアドレスの形になっていません。
ログ : 6 行目に入力エラー [フリガナ:文字種, メールアドレス:形式]</code></pre>
    <p>
      画面は取り込んだ本人が自分のデータを直すためのもの、ログは調査のためにコピーされ、長く保管されるものです。
      氏名やメールアドレスは個人情報なので、ログには出しません。行番号があれば、元のファイルを見れば値は分かります。
    </p>
    <p>
      もう 1 つ、<strong>利用者が送ってきた文字列（ファイル名など）に改行が入っていると、
      偽のログ行を差し込まれます</strong>（ログインジェクション）。
      このサンプルではファイル名から制御文字を落としたうえで、
      書式を <code>%enc{%m}{CRLF}</code> にして、メッセージ中の改行を <code>\r\n</code> という文字に置き換えています。
    </p>

    <h2>1 回の取り込みぶんのログをつなぐ（ThreadContext）</h2>
    <p>
      本番のログには、何人ぶんもの行が入り混じって出ます。
      取り込み 1 回ぶんを拾い集められるよう、<strong>取り込み ID</strong> を全部の行に付けています。
    </p>
<pre><code class="language-java">try (CloseableThreadContext.Instance context =
             CloseableThreadContext.put("importId", importId)) {
    ... // この中で出したログには、DAO の中で出したものも含めて [importId] が付く
}       // 抜けるときに必ず消える</code></pre>
<pre><code class="language-plaintext">&lt;!-- log4j2.xml : %X{importId} の位置に入る --&gt;
%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level [%t] [%X{importId}] %logger{1} - %enc{%m}{CRLF}%n</code></pre>
    <p>
      <code>ThreadContext</code>（SLF4J や Logback では MDC と呼びます）はスレッドごとの入れ物です。
      Tomcat はスレッドを使い回すので、<strong>消し忘れると次の人のリクエストに前の人の ID が付きます</strong>。
      try-with-resources で囲む <code>CloseableThreadContext</code> を使えば、消し忘れが起きません。
    </p>
    <p>
      同じ ID を画面にも<strong>問い合わせ番号</strong>として出しています。
      「IMP-3F9A0C21 で失敗した」と連絡をもらえば、ログを 1 回 grep するだけで、その取り込みの行がすべて揃います。
    </p>

    <h2>ログを見る</h2>
<pre><code class="language-bash">docker compose logs -f tomcat                                # 標準出力 (Console)
docker compose exec tomcat tail -f logs/servlet-sample.log   # ファイル (RollingFile)
docker compose exec tomcat grep IMP-3F9A0C21 logs/servlet-sample.log</code></pre>
    <p>
      デモの「⑤ このとき出たログ」は、同じ行を画面にも出したものです（<code>ImportLogAppender</code>）。
      公開デモではサーバのファイルを見られないので置いている仕掛けで、実際のアプリには要りません。
    </p>

    <h2>このデモの制限</h2>
    <p>
      公開しているデモなので、1 回に取り込めるのは <strong>${maxRows} 行・${maxFileSizeKb} KB まで</strong>、
      登録できる社員は <strong>${maxEmployees} 人まで</strong>にしています。
      DB はメモリ上で動かしているため、<strong>アプリを再起動すると取り込んだ社員は消えます</strong>。
      ほかの人と同じ表を見ているので、知らない社員が増えていることがあります。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // 選んだファイル名をボタンの横に出す (見た目だけの処理)
      $('#csvFile').on('change', function () {
        var name = this.files && this.files.length > 0 ? this.files[0].name : '選択されていません';
        $('#selectedFileName').text(name);
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <t:resultModal message="${flash}" />

    <%-- ============================================================
         ① 取り込み用 CSV のダウンロード
         ============================================================ --%>
    <t:panel title="① 取り込み用の CSV をダウンロードする" note="まずはこれを下の ③ で取り込んでみてください">
      <%-- 狭い画面ではボタンが説明の下に回るよう、表ではなくリストで並べる --%>
      <div class="list-group">
        <c:forEach var="file" items="${sampleFiles}">
          <div class="list-group-item d-flex flex-column flex-md-row align-items-md-center">
            <div class="flex-grow-1 mr-md-3">
              <strong>${fn:escapeXml(file.label)}</strong>
              <small class="text-muted ml-1">${fn:escapeXml(file.fileName)} / ${fn:escapeXml(file.charsetLabel)}</small>
              <p class="small mb-0 mt-1">${fn:escapeXml(file.description)}</p>
            </div>
            <a class="btn btn-outline-primary btn-sm mt-2 mt-md-0 text-nowrap align-self-start align-self-md-center"
               href="${sampleUrl}/download?file=${file.key}">ダウンロード</a>
          </div>
        </c:forEach>
      </div>
    </t:panel>

    <%-- ============================================================
         ② CSV の形式
         ============================================================ --%>
    <t:panel title="② CSV の形式" note="1 行目は見出し、2 行目からデータ">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-3">
          <thead class="thead-light">
            <tr>
              <th style="width: 3rem;">列</th>
              <th style="width: 9rem;">見出し</th>
              <th>チェックの内容</th>
              <th style="width: 13rem;">例</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="column" items="${columns}" varStatus="status">
              <tr>
                <td class="text-center">${status.count}</td>
                <td>${fn:escapeXml(column.label)}</td>
                <td class="small">${fn:escapeXml(column.rule)}</td>
                <td><code>${fn:escapeXml(column.example)}</code></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <div class="row small">
        <div class="col-md-6">
          <p class="mb-1"><strong>部署マスタ</strong></p>
          <ul class="mb-2">
            <c:forEach var="department" items="${departments}">
              <li><code>${fn:escapeXml(department.key)}</code> ${fn:escapeXml(department.value)}</li>
            </c:forEach>
          </ul>
        </div>
        <div class="col-md-6">
          <p class="mb-1"><strong>そのほかの決まり</strong></p>
          <ul class="mb-0">
            <li>文字コードは UTF-8（BOM あり / なし）か Shift_JIS</li>
            <li>1 回に ${maxRows} 行・${maxFileSizeKb} KB まで</li>
            <li>何も入っていない行は読み飛ばす</li>
            <li>社員コードが登録済みなら上書きする</li>
          </ul>
        </div>
      </div>
    </t:panel>

    <%-- ============================================================
         ③ 取り込み
         ============================================================ --%>
    <t:panel title="③ CSV を取り込む" note="1 件でもエラーがあれば、1 件も登録しません">
      <form action="${sampleUrl}" method="post" enctype="multipart/form-data">
        <div class="form-group">
          <label for="csvFile">CSV ファイル</label>
          <input type="file" class="form-control-file" id="csvFile" name="file" accept=".csv,text/csv" required>
          <small class="form-text text-muted">
            選択中: <span id="selectedFileName">選択されていません</span>
          </small>
        </div>

        <fieldset class="form-group">
          <legend class="col-form-label pt-0">文字コード</legend>
          <div class="custom-control custom-radio custom-control-inline">
            <input type="radio" class="custom-control-input" id="encodingUtf8" name="encoding" value="utf8" checked>
            <label class="custom-control-label" for="encodingUtf8">UTF-8</label>
          </div>
          <div class="custom-control custom-radio custom-control-inline">
            <input type="radio" class="custom-control-input" id="encodingSjis" name="encoding" value="sjis">
            <label class="custom-control-label" for="encodingSjis">Shift_JIS</label>
          </div>
          <small class="form-text text-muted">
            先頭に BOM があるファイルは、ここの選択によらず UTF-8 として読みます。
          </small>
        </fieldset>

        <div class="form-group">
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="breakHalfway" name="breakHalfway" value="1">
            <label class="custom-control-label" for="breakHalfway">
              登録の途中で DB 障害を起こす<span class="text-muted">（ERROR ログとロールバックを確かめる用）</span>
            </label>
          </div>
        </div>

        <button type="submit" class="btn btn-primary">
          <t:icon name="file-earmark-arrow-up" cssClass="mr-1" />取り込む
        </button>
      </form>
    </t:panel>

    <%-- ============================================================
         ④ 結果 / ⑤ ログ （取り込んだ直後だけ）
         ============================================================ --%>
    <c:if test="${not empty result}">
      <t:panel title="④ 取り込み結果" note="問い合わせ番号はログの [ ] の中と同じ値です">
        <c:choose>
          <c:when test="${result.success}"><c:set var="variant" value="success" /></c:when>
          <c:when test="${result.failed}"><c:set var="variant" value="danger" /></c:when>
          <c:otherwise><c:set var="variant" value="warning" /></c:otherwise>
        </c:choose>
        <div class="alert alert-${variant}" role="alert">
          <p class="mb-1">
            <strong>
              <c:choose>
                <c:when test="${result.success}">取り込みました</c:when>
                <c:when test="${result.invalid}">入力エラーがあります</c:when>
                <c:when test="${result.rejected}">このファイルは取り込めません</c:when>
                <c:otherwise>システムエラー</c:otherwise>
              </c:choose>
            </strong>
            <c:if test="${not empty result.fileName}">
              <span class="ml-1">（${fn:escapeXml(result.fileName)}）</span>
            </c:if>
          </p>
          <p class="mb-1">${fn:escapeXml(result.message)}</p>
          <c:if test="${result.success}">
            <p class="mb-1">追加 <strong>${result.insertedCount}</strong> 件 / 上書き <strong>${result.updatedCount}</strong> 件</p>
          </c:if>
          <p class="mb-0 small">問い合わせ番号: <code>${fn:escapeXml(result.importId)}</code></p>
        </div>

        <c:if test="${result.invalid}">
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <thead class="thead-light">
                <tr>
                  <th style="width: 4.5rem;" class="text-right">行</th>
                  <th style="width: 9rem;">列</th>
                  <th style="width: 5rem;">種類</th>
                  <th style="width: 12rem;">入力値</th>
                  <th>直し方</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="error" items="${result.errors}">
                  <tr>
                    <td class="text-right">${error.lineNumber} 行目</td>
                    <td>${empty error.column ? '（行全体）' : fn:escapeXml(error.column)}</td>
                    <td><span class="badge badge-light">${fn:escapeXml(error.kind)}</span></td>
                    <td>
                      <c:choose>
                        <c:when test="${empty error.value}"><span class="text-muted">（空）</span></c:when>
                        <c:otherwise><code>${fn:escapeXml(error.value)}</code></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="small">${fn:escapeXml(error.message)}</td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <c:if test="${result.hiddenErrorCount > 0}">
            <p class="text-muted small mt-2 mb-0">
              ほかに ${result.hiddenErrorCount} 件のエラーがあります（画面には先頭の ${fn:length(result.errors)} 件だけを出しています）。
            </p>
          </c:if>
        </c:if>
      </t:panel>

      <t:panel title="⑤ このとき出たログ（Log4j 2）" note="サーバの logs/servlet-sample.log にも同じ行が出ています">
        <c:choose>
          <c:when test="${empty logLines}">
            <p class="text-muted mb-0">ログが見つかりませんでした（アプリを再起動した直後などは消えています）。</p>
          </c:when>
          <c:otherwise>
            <pre class="log-view mb-2"><c:forEach var="line" items="${logLines}"><span class="log-view__line log-view__line--${fn:toLowerCase(line.level)}">${fn:escapeXml(line.text)}</span></c:forEach></pre>
            <p class="text-muted small mb-0">
              入力値（氏名やメールアドレス）はログに出していません。
              どの行も <code>[${fn:escapeXml(result.importId)}]</code> が付いているので、この番号で grep すれば 1 回ぶんが揃います。
            </p>
          </c:otherwise>
        </c:choose>
      </t:panel>
    </c:if>

    <%-- ============================================================
         ⑥ 登録されている社員
         ============================================================ --%>
    <t:panel title="⑥ 登録されている社員" note="${fn:length(employees)} 人 / 上限 ${maxEmployees} 人">
      <div class="table-responsive">
        <table class="table table-sm table-hover mb-3">
          <thead class="thead-light">
            <tr>
              <th style="width: 6rem;">社員コード</th>
              <th style="width: 9rem;">氏名</th>
              <th style="width: 9rem;">フリガナ</th>
              <th>メールアドレス</th>
              <th style="width: 6rem;">部署</th>
              <th style="width: 6rem;">雇用区分</th>
              <th style="width: 7rem;">入社日</th>
              <th style="width: 10rem;">更新日時</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="employee" items="${employees}">
              <tr>
                <td><code>${fn:escapeXml(employee.code)}</code></td>
                <td>${fn:escapeXml(employee.name)}</td>
                <td>${fn:escapeXml(employee.kana)}</td>
                <td class="small">${fn:escapeXml(employee.email)}</td>
                <td>${fn:escapeXml(employee.departmentName)}</td>
                <td>${fn:escapeXml(employee.employmentType)}</td>
                <td>${employee.hireDate}</td>
                <td class="small text-muted">${employee.updatedAtText}</td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <form action="${sampleUrl}" method="post" class="mb-0">
        <input type="hidden" name="action" value="reset">
        <button type="submit" class="btn btn-outline-secondary btn-sm">初期状態に戻す</button>
        <span class="text-muted small ml-2">最初の 3 人（E00001 〜 E00003）だけにします</span>
      </form>
    </t:panel>

  </jsp:body>
</t:sample>
