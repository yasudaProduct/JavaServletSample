<%--
  【サンプル】入力チェックの種類 (必須 / 文字種 / 桁数 / 形式 / 範囲 / 相関 / 選択 / 突き合わせ)

  ValidationRulesServlet が次の値をセットします。
    form         … 画面から受け取った入力値 (LeaveRequestForm)。初期表示では空のもの
    errors       … 入力チェックの結果 (ValidationErrors)。初期表示では空のもの
    leaveTypes   … 休暇の種類の選択肢 (LeaveType の一覧)
    employees    … 社員マスタの代わり (EmployeeMaster.Employee の一覧)
    today        … 今日の日付 (uuuu-MM-dd)
    limitDate    … 申請できる最終日 (uuuu-MM-dd)
    codeLength / kanaMaxLength / reasonMaxLength / maxPeriodDays /
    minBackups / maxBackups / maxMonthsAhead … Java 側の定数 (画面の説明文と揃えるため)
    flash        … 受付完了メッセージ (リダイレクト後の 1 回だけ)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/form/validation-rules" />
<t:sample sampleId="validation-rules">

  <jsp:attribute name="explanation">
    <h2>「入力チェック」には種類があります</h2>
    <p>
      入力チェックと一口に言っても、確かめている内容はさまざまです。
      種類を知っておくと、新しい画面を作るときに
      <strong>「この項目には何と何を課すべきか」を漏れなく並べられます</strong>。
      この画面は、その種類を 1 つのフォーム（休暇申請）に詰め込んだものです。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>種類</th><th>確かめること</th><th>この画面での例</th></tr>
        </thead>
        <tbody>
          <tr><td>必須</td><td>入力されているか</td><td>社員コード・フリガナ・理由</td></tr>
          <tr><td>文字種</td><td>使ってよい文字だけか</td><td>社員コード（半角英数）・フリガナ（全角カタカナ）</td></tr>
          <tr><td>桁数</td><td>長さが決まりどおりか</td><td>社員コード（${codeLength} 桁ちょうど）・理由（${reasonMaxLength} 文字以内）</td></tr>
          <tr><td>形式</td><td>決まった形に読めるか</td><td>開始日・終了日（<code>uuuu-MM-dd</code> で実在する日）</td></tr>
          <tr><td>範囲</td><td>値が許した幅に収まるか</td><td>開始日は今日以降・${maxMonthsAhead} か月先まで</td></tr>
          <tr><td>相関</td><td>項目どうしの関係が成り立つか</td><td>開始日 ≦ 終了日・期間 ${maxPeriodDays} 日以内・引継ぎ先に自分を入れない</td></tr>
          <tr><td>選択（単一）</td><td>用意した選択肢の値か</td><td>休暇の種類</td></tr>
          <tr><td>選択（複数）</td><td>選んだ数が決まりどおりか</td><td>引継ぎ先（${minBackups} 〜 ${maxBackups} 名）</td></tr>
          <tr><td>突き合わせ</td><td>マスタに実在するか</td><td>社員コード・引継ぎ先</td></tr>
        </tbody>
      </table>
    </div>
    <p class="text-muted">
      チェックの基本（受け取る → 確かめる → エラーなら forward、成功ならリダイレクト）は
      <a href="${ctx}/samples/form/input-validation">入力チェック（サーバ側）</a>
      のサンプルで扱っています。この画面はその続きとして、
      <strong>種類ごとの書き方</strong>に絞って並べています。
    </p>

    <h2>順番 : 安いチェックから、重いチェックは最後に</h2>
    <p>1 つの項目に複数のチェックを課すときは、次の順に見て、引っかかったらそこで打ち切ります。</p>
<pre><code class="language-plaintext">必須 → 文字種 → 桁数 → 形式 → 範囲 → （項目をまたぐ）相関 → （外部を見る）突き合わせ</code></pre>
    <p>
      前のチェックを通った値だけが、次のチェックの前提を満たしているからです。
      未入力の値に「${codeLength} 桁で」と言っても的外れですし、
      <code>あいう</code> という社員コードでマスタを検索しても見つからないに決まっています。
      そして<strong>データベースを見るチェックがいちばん高くつく</strong>ので、いちばん最後に置きます。
    </p>
<pre><code class="language-java">// 社員コード : 必須 → 文字種 → 桁数 → マスタ突き合わせ
if (Validators.isBlank(employeeCode)) {
    errors.add("employeeCode", "社員コードを入力してください。");
    return;
}
if (!Validators.isHalfWidthAlphanumeric(employeeCode)) {
    errors.add("employeeCode", "社員コードは半角の英数字で入力してください。(例: E1001)");
    return;
}
if (!Validators.isLengthExactly(employeeCode, CODE_LENGTH)) {
    errors.add("employeeCode", "社員コードは 5 桁で入力してください。");
    return;
}
if (!EmployeeMaster.exists(employeeCode)) {      // ← ここだけがマスタを見る
    errors.add("employeeCode", "社員コード " + employeeCode + " は登録されていません。");
}</code></pre>

    <h2>種類ごとの書き方</h2>

    <h3>① 必須チェック</h3>
    <p>
      「空文字か」ではなく「<strong>空白だけでないか</strong>」を見ます。
      スペースだけの理由が通ってしまうと、必須にした意味がありません。
    </p>
<pre><code class="language-java">public static boolean isBlank(String value) {
    return value == null || value.strip().isEmpty();
}</code></pre>
    <p>
      落とすのに <code>trim()</code> ではなく <code>strip()</code>（Java 11 以降）を使うのが要点です。
      <code>trim()</code> が削るのは <code>U+0020</code> 以下の文字だけなので、
      <strong>全角スペースだけを入力されると素通りします</strong>。
    </p>

    <h3>② 文字種チェック</h3>
    <p>
      「半角英数字だけか」「全角カタカナだけか」のように、使ってよい文字を決めます。
      正規表現で書くときは <code>^</code> と <code>$</code>（またはメソッドの選び方）に注意します。
    </p>
<pre><code class="language-java">Pattern HALF_WIDTH_ALPHANUMERIC = Pattern.compile("^[0-9A-Za-z]+$");

HALF_WIDTH_ALPHANUMERIC.matcher("E1001").matches()   // → true
HALF_WIDTH_ALPHANUMERIC.matcher("Ｅ１００１").matches() // → false (全角)
HALF_WIDTH_ALPHANUMERIC.matcher("E-100").matches()   // → false (ハイフン)</code></pre>
    <ul>
      <li>
        <strong><code>matches()</code> と <code>find()</code> は別物</strong>：
        <code>matches()</code> は文字列全体が一致するか、<code>find()</code> は
        <strong>どこかに含まれるか</strong>です。
        <code>find()</code> で書くと <code>あいうE1001</code> が通ってしまいます
      </li>
      <li>
        <strong><code>\w</code> は使わない</strong>：
        <code>_</code> を含みますし、設定によっては全角の英数字にも当たります。
        使ってよい文字は<strong>並べて書く</strong>ほうが確実です
      </li>
    </ul>
    <p>フリガナ（全角カタカナ）は、次の範囲を許しています。</p>
<pre><code class="language-java">Pattern.compile("^[ァ-ヶー・　 ]+$");
//                 ~~~~ 全角カタカナ (U+30A1〜U+30F6)
//                      ~ 長音 (U+30FC) : カタカナの範囲に入っていないので別に足す
//                       ~ 中点 (U+30FB) : 「サン・テグジュペリ」など
//                        ~~~~~~~ 全角スペース (U+3000) と半角スペース : 姓と名の区切り</code></pre>
    <p>
      <strong>半角カタカナ（<code>ﾔﾏﾀﾞ</code>）は通していません</strong>。
      文字化けの原因になりやすく、保存後に並び替えても全角と混ざって
      期待どおりの順にならないためです。
      「入力する側に直してもらう」か「サーバ側で全角に変換する」かは決めの問題ですが、
      <strong>どちらにするかを決めて、画面にも書いておく</strong>ことが大切です。
    </p>

    <h3>③ 桁数チェック</h3>
    <p>固定長（ちょうど）と上限（以内）を区別します。数え方には少し落とし穴があります。</p>
<pre><code class="language-java">// 人が数えた文字数に合わせる (絵文字や 𠮟 のような文字は length() だと 2 になる)
public static int length(String value) {
    return value == null ? 0 : value.codePointCount(0, value.length());
}</code></pre>
    <p>
      テキストエリア（理由）では、<strong>改行が送信時に <code>\r\n</code> の 2 文字になります</strong>。
      そのまま数えると「画面では ${reasonMaxLength} 文字なのにサーバではエラー」という食い違いが起きるので、
      受け取った時点で <code>\n</code> に揃えてから数えています。
    </p>

    <h3>④ 形式チェック（日付）</h3>
    <p>
      日付は「形が合っているか」と「<strong>その日が実在するか</strong>」の両方を見ます。
      <code>2026-02-30</code> は形は合っていますが、存在しない日です。
    </p>
<pre><code class="language-java">private static final DateTimeFormatter STRICT_DATE =
        DateTimeFormatter.ofPattern("uuuu-MM-dd").withResolverStyle(ResolverStyle.STRICT);

LocalDate.parse("2026-02-30", STRICT_DATE);   // → DateTimeParseException (これが欲しい)</code></pre>
    <ul>
      <li>
        <strong><code>yyyy</code> ではなく <code>uuuu</code></strong>：
        <code>STRICT</code> と組み合わせると <code>yyyy</code> は年号（西暦か紀元前か）の指定も要求し、
        <code>2026-04-01</code> すら解析に失敗します。<code>uuuu</code> は元号を持たない通し番号の年です
      </li>
      <li>
        <strong>既定の <code>SMART</code> は勝手に丸める</strong>：
        <code>2026-02-30</code> が 2 月 28 日として通ってしまい、
        利用者は<strong>打ち間違いに気づけません</strong>
      </li>
      <li>
        <strong><code>&lt;input type="date"&gt;</code> に頼らない</strong>：
        ブラウザの日付ピッカーは便利ですが、対応していない環境もありますし、
        直接 POST すれば何でも送れます。このサンプルは動きを試せるように
        <code>type="text"</code> にしてあります
      </li>
    </ul>

    <h3>⑤ 範囲チェック</h3>
    <p>
      数値なら上限・下限、日付なら「今日以降」「${maxMonthsAhead} か月先まで」のような幅です。
      ここで大切なのは<strong>「今日」を外から渡すこと</strong>です。
    </p>
<pre><code class="language-java">// Servlet 側
ValidationErrors errors = form.validate(LocalDate.now());

// フォーム側
public ValidationErrors validate(LocalDate today) { ... }</code></pre>
    <p>
      チェックの中で <code>LocalDate.now()</code> を呼ぶと、
      <strong>テストが実行した日によって結果が変わってしまいます</strong>。
      基準になる日時を引数で受け取る形にしておくと、
      「2026-04-01 を今日として、3 月 31 日はエラー」と素直に書けます。
    </p>

    <h3>⑥ 相関チェック（項目をまたぐ）</h3>
    <p>
      2 つ以上の項目を見ないと判定できないものです。
      <strong>関係する項目がそれぞれ妥当だと分かってから</strong>行います。
    </p>
<pre><code class="language-java">private void validatePeriod(ValidationErrors errors,
                            Optional&lt;LocalDate&gt; start, Optional&lt;LocalDate&gt; end) {
    if (start.isEmpty() || end.isEmpty()) {
        return;                      // 片方が読めていないなら、前後関係は判定しない
    }
    if (end.get().isBefore(start.get())) {
        errors.add("endDate", "終了日は開始日以降の日付を入力してください。");
        return;
    }
    long days = ChronoUnit.DAYS.between(start.get(), end.get()) + 1;
    if (days &gt; MAX_PERIOD_DAYS) {
        errors.add("endDate", "続けて申請できるのは 30 日までです。");
    }
}</code></pre>
    <p>
      エラーを付けるのは<strong>片方の項目だけ</strong>にします（ここでは終了日）。
      両方を赤くすると「どちらを直せばよいのか」が伝わりません。
    </p>

    <h3>⑦ 選択肢のチェック（単一・複数）</h3>
    <p>
      プルダウンやチェックボックスは「画面に出した選択肢しか送られてこない」ように見えますが、
      <strong>開発者ツールで書き換えたり、直接 POST したりすれば何でも送れます</strong>。
      受け取った値が一覧にあるかどうかを必ず確かめます（ホワイトリスト方式）。
    </p>
<pre><code class="language-java">// 選択肢は enum で持つ。画面の選択肢もチェックも同じ一覧から作る
if (LeaveType.findByCode(leaveType).isEmpty()) {
    errors.add("leaveType", "休暇の種類の値が正しくありません。選び直してください。");
}</code></pre>
    <p>
      <code>LeaveType.valueOf(code)</code> を入力チェックに使ってはいけません。
      知らない名前を渡されると <code>IllegalArgumentException</code> を投げるので、
      <strong>エラー表示ではなく 500 エラーになります</strong>。
    </p>
    <p>複数選択（チェックボックス）では、数え方に 2 つの注意点があります。</p>
<pre><code class="language-java">String[] values = request.getParameterValues("backupCodes");
// ① 1 つも選ばれていないと、空の配列ではなく null が返る
// ② 直接 POST されれば同じ値を何度でも送れるので、重複を 1 つにまとめてから数える</code></pre>

    <h3>⑧ マスタとの突き合わせ</h3>
    <p>
      「その社員コードは実在するか」のように、<strong>サーバに聞かないと分からないチェック</strong>です。
      形式のチェックを通った値だけを問い合わせます。
    </p>
    <p>
      なお、登録の直前に「重複していないか」を確かめても、
      <strong>確かめてから登録するまでの間に他の人が登録する</strong>ことがあります。
      画面でのチェックは親切のため、最後の砦はデータベースの一意制約、という二段構えにしておくと安全です。
    </p>

    <h2>チェックを部品にまとめる</h2>
    <p>
      「必須」「半角英数字か」「日付として実在するか」は、どの画面でも同じものを書くことになります。
      <code>common/Validators.java</code> にまとめておくと、
      <strong>フォームのクラスには「どの項目に何を課すか」だけが並びます</strong>。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>部品に置くもの</th><th>フォームのクラスに書くもの</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>どのアプリでも意味が変わらない判定<br>（空白か / 半角英数か / 日付として読めるか）</td>
            <td>業務の決めごと<br>（社員コードは ${codeLength} 桁 / 申請は ${maxMonthsAhead} か月先まで）</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      桁数の「${codeLength}」を部品側に書いてしまうと、別の画面で桁数が違ったときに直せません。
      <strong>判定の仕方は部品へ、決めごとは使う側へ</strong>と分けておくのが目安です。
    </p>

    <h2>画面の説明文と実装をズラさない</h2>
    <p>
      画面に「${reasonMaxLength} 文字以内」と書いたのに実装は 100 文字だった、という食い違いはよく起きます。
      上限は Java 側の定数にして、<strong>画面にはその値を渡して表示します</strong>。
    </p>
<pre><code class="language-java">// Servlet 側
request.setAttribute("reasonMaxLength", LeaveRequestForm.REASON_MAX_LENGTH);</code></pre>
<pre><code class="language-xml">&lt;small class="form-text text-muted"&gt;${"${reasonMaxLength}"} 文字以内で入力してください。&lt;/small&gt;</code></pre>
    <p>この画面に出ている数字は、すべて Java 側の定数から来ています。</p>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>チェックボックスは、選ばないと <code>null</code></strong>：
        <code>getParameterValues</code> は空の配列ではなく <code>null</code> を返します。
        そのまま <code>for</code> に渡すと <code>NullPointerException</code> です。
      </li>
      <li>
        <strong><code>Integer.parseInt("２０")</code> は 20 を返す</strong>：
        全角数字も通ります。数値にする前に <code>^-?[0-9]+$</code> で形を見ます。
      </li>
      <li>
        <strong><code>DateTimeFormatter</code> の <code>yyyy</code> と <code>uuuu</code></strong>：
        <code>STRICT</code> にすると <code>yyyy</code> は年号を要求します。<code>uuuu</code> を使います。
      </li>
      <li>
        <strong><code>find()</code> は「どこかに含まれるか」</strong>：
        <code>^[0-9A-Za-z]+$</code> と書いていても、<code>find()</code> で判定すると
        <code>"E1001\n"</code> のような値を通してしまいます
        （<code>$</code> は最後の改行の手前にも当たるためです）。
        文字列全体を確かめるのは <code>matches()</code> です
        （<code>matches()</code> なら最後まで一致しないので通りません）。
      </li>
      <li>
        <strong>エラーメッセージに入力値をそのまま載せる</strong>：
        「社員コード ○○ は登録されていません」のように利用者の入力を混ぜるときは、
        画面に出すときのエスケープ（<code>fn:escapeXml</code>）を忘れないでください。
      </li>
      <li>
        <strong>相関チェックを前提が崩れたまま行う</strong>：
        開始日が読めていないのに「開始日以降にしてください」と出すと、混乱させるだけです。
      </li>
      <li>
        <strong>マスタ突き合わせを最初に書く</strong>：
        空文字や 100 文字の文字列でデータベースを検索することになります。
        安いチェックを通ってから問い合わせます。
      </li>
      <li>
        <strong>チェックが 1 か所に集まりすぎる</strong>：
        <code>doPost</code> に <code>if</code> を 50 行並べると読めなくなります。
        項目ごとのメソッドに分けると、順番も見通せます。
      </li>
    </ul>

    <h2>テストは境界値を並べる</h2>
    <p>
      入力チェックの間違いは<strong>画面を見ても気づけません</strong>
      （「1 文字多くても通る」を目で見つけるのは無理です）。
      確かめるのは境界、つまり「ちょうど通る値」と「1 つだけ外れた値」です。
    </p>
<pre><code class="language-java">@Test
@DisplayName("開始日が今日ちょうどなら通る")
void acceptsToday() {
    assertFalse(validate(form("2026-04-01", "2026-04-01"), LocalDate.of(2026, 4, 1))
            .has("startDate"));
}

@Test
@DisplayName("開始日が昨日ならエラー")
void rejectsYesterday() {
    assertTrue(validate(form("2026-03-31", "2026-03-31"), LocalDate.of(2026, 4, 1))
            .has("startDate"));
}</code></pre>
    <p>
      基準日を引数で渡しているので、<strong>いつ実行しても同じ結果</strong>になります。
      テストの全文は
      <code>src/test/java/com/example/servletsample/samples/form/LeaveRequestFormTest.java</code> と
      <code>ValidatorsTest.java</code> にあります。
    </p>

    <h2>関連するサンプル</h2>
    <ul>
      <li>
        <a href="${ctx}/samples/form/input-validation">入力チェック（サーバ側）</a>
        … チェックの基本の流れ、エラー表示、入力値の保持
      </li>
      <li>
        <a href="${ctx}/samples/form/realtime-validation">入力チェック（フォーカスアウト時）</a>
        … 画面側で早く気づかせる方法と、サーバ側との二重化
      </li>
      <li>
        <a href="${ctx}/samples/basic/request-parameter">リクエストパラメータの受け取り方</a>
        … <code>getParameterValues</code> や <code>null</code> と空文字の違い
      </li>
      <li>
        <a href="${ctx}/samples/ajax/ajax-form">Ajax でフォームを送信する</a>
        … 同じチェックの結果を JSON で返す形
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <t:panel title="休暇申請フォーム"
             note="JavaScript は使っていません。すべてサーバ側で確かめています">

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

      <form action="${formUrl}" method="post" novalidate>

        <div class="form-row">
          <div class="form-group col-md-5">
            <label for="employeeCode">
              社員コード <span class="badge badge-danger">必須</span>
              <span class="badge badge-light">文字種・桁数・突き合わせ</span>
            </label>
            <input type="text" class="form-control ${errors.has('employeeCode') ? 'is-invalid' : ''}"
                   id="employeeCode" name="employeeCode"
                   value="${fn:escapeXml(form.employeeCode)}"
                   placeholder="例: E1001" aria-describedby="employeeCodeHelp">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('employeeCode'))}</div>
            <small id="employeeCodeHelp" class="form-text text-muted">
              半角英数字 ${codeLength} 桁。下の社員マスタにあるコードだけを受け付けます。
            </small>
          </div>

          <div class="form-group col-md-7">
            <label for="nameKana">
              フリガナ <span class="badge badge-danger">必須</span>
              <span class="badge badge-light">文字種・桁数</span>
            </label>
            <input type="text" class="form-control ${errors.has('nameKana') ? 'is-invalid' : ''}"
                   id="nameKana" name="nameKana" value="${fn:escapeXml(form.nameKana)}"
                   placeholder="例: ヤマダ タロウ" aria-describedby="nameKanaHelp">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('nameKana'))}</div>
            <small id="nameKanaHelp" class="form-text text-muted">
              全角カタカナ ${kanaMaxLength} 文字以内。ひらがな・漢字・半角カタカナは受け付けません。
            </small>
          </div>
        </div>

        <div class="form-group">
          <label for="leaveType">
            休暇の種類 <span class="badge badge-danger">必須</span>
            <span class="badge badge-light">選択（単一）</span>
          </label>
          <select class="form-control ${errors.has('leaveType') ? 'is-invalid' : ''}"
                  id="leaveType" name="leaveType" aria-describedby="leaveTypeHelp">
            <option value="">-- 選んでください --</option>
            <c:forEach var="type" items="${leaveTypes}">
              <option value="${fn:escapeXml(type.code)}"
                      ${form.leaveType eq type.code ? 'selected' : ''}>
                ${fn:escapeXml(type.label)}（${fn:escapeXml(type.note)}）
              </option>
            </c:forEach>
          </select>
          <div class="invalid-feedback">${fn:escapeXml(errors.get('leaveType'))}</div>
          <small id="leaveTypeHelp" class="form-text text-muted">
            送られてきたコードが一覧にあるかどうかを、サーバ側でも確かめています。
          </small>
        </div>

        <div class="form-row">
          <div class="form-group col-md-4">
            <label for="startDate">
              開始日 <span class="badge badge-danger">必須</span>
              <span class="badge badge-light">形式・範囲</span>
            </label>
            <input type="text" class="form-control ${errors.has('startDate') ? 'is-invalid' : ''}"
                   id="startDate" name="startDate" value="${fn:escapeXml(form.startDate)}"
                   placeholder="例: ${today}" aria-describedby="startDateHelp">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('startDate'))}</div>
            <small id="startDateHelp" class="form-text text-muted">
              <code>uuuu-MM-dd</code> の形式。今日（${today}）から ${limitDate} まで。
            </small>
          </div>

          <div class="form-group col-md-4">
            <label for="endDate">
              終了日 <span class="badge badge-danger">必須</span>
              <span class="badge badge-light">形式・相関</span>
            </label>
            <input type="text" class="form-control ${errors.has('endDate') ? 'is-invalid' : ''}"
                   id="endDate" name="endDate" value="${fn:escapeXml(form.endDate)}"
                   placeholder="例: ${today}" aria-describedby="endDateHelp">
            <div class="invalid-feedback">${fn:escapeXml(errors.get('endDate'))}</div>
            <small id="endDateHelp" class="form-text text-muted">
              開始日以降で、続けて ${maxPeriodDays} 日まで。
            </small>
          </div>

          <div class="form-group col-md-4">
            <span class="d-inline-block mb-2">申請日数</span>
            <p class="form-control-plaintext py-0">
              <c:choose>
                <c:when test="${form.days gt 0}"><strong>${form.days}</strong> 日間</c:when>
                <c:otherwise><span class="text-muted">—</span></c:otherwise>
              </c:choose>
            </p>
            <small class="form-text text-muted">両端を含めて数えます。</small>
          </div>
        </div>

        <div class="form-group">
          <label>
            引継ぎ先 <span class="badge badge-danger">必須</span>
            <span class="badge badge-light">選択（複数）・突き合わせ・相関</span>
          </label>
          <div class="border rounded p-2 ${errors.has('backupCodes') ? 'border-danger' : ''}">
            <div class="form-row">
              <c:forEach var="employee" items="${employees}">
                <div class="col-md-4">
                  <div class="custom-control custom-checkbox mb-1">
                    <input type="checkbox" class="custom-control-input"
                           id="backup-${fn:escapeXml(employee.code)}"
                           name="backupCodes" value="${fn:escapeXml(employee.code)}"
                           ${form.hasBackup(employee.code) ? 'checked' : ''}>
                    <label class="custom-control-label" for="backup-${fn:escapeXml(employee.code)}">
                      ${fn:escapeXml(employee.name)}
                      <span class="text-muted small">${fn:escapeXml(employee.code)}</span>
                    </label>
                  </div>
                </div>
              </c:forEach>
            </div>
          </div>
          <c:if test="${errors.has('backupCodes')}">
            <div class="text-danger small mt-1">${fn:escapeXml(errors.get('backupCodes'))}</div>
          </c:if>
          <small class="form-text text-muted">
            ${minBackups} 〜 ${maxBackups} 名。申請者本人は選べません。
          </small>
        </div>

        <div class="form-group">
          <label for="reason">
            理由 <span class="badge badge-danger">必須</span>
            <span class="badge badge-light">桁数</span>
          </label>
          <textarea class="form-control ${errors.has('reason') ? 'is-invalid' : ''}"
                    id="reason" name="reason" rows="3"
                    aria-describedby="reasonHelp">${fn:escapeXml(form.reason)}</textarea>
          <div class="invalid-feedback">${fn:escapeXml(errors.get('reason'))}</div>
          <small id="reasonHelp" class="form-text text-muted">
            ${reasonMaxLength} 文字以内（現在 ${form.reasonLength} 文字）。
            改行は送信時に 2 文字になるため、サーバ側で <code>\n</code> に揃えてから数えています。
          </small>
        </div>

        <button type="submit" class="btn btn-primary">
          <t:icon name="check-circle" cssClass="mr-1" />申請する
        </button>
        <a class="btn btn-link" href="${formUrl}">入力をクリア</a>
      </form>
    </t:panel>

    <t:panel title="このフォームのチェック内容"
             note="画面の説明文と Java の実装が食い違わないよう、同じ値を使っています">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th scope="col">種類</th>
              <th scope="col">項目</th>
              <th scope="col">チェックの内容</th>
              <th scope="col">試してみる値</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">必須</th>
              <td>社員コード / フリガナ / 理由</td>
              <td>空白だけの入力も「未入力」として扱う</td>
              <td><code>（全角スペースだけ）</code></td>
            </tr>
            <tr>
              <th scope="row">文字種</th>
              <td>社員コード</td>
              <td>半角の英数字だけ</td>
              <td><code>Ｅ１００１</code>（全角）/ <code>E-101</code></td>
            </tr>
            <tr>
              <th scope="row">文字種</th>
              <td>フリガナ</td>
              <td>全角カタカナ（長音・中点・スペースを含む）</td>
              <td><code>やまだ</code> / <code>ﾔﾏﾀﾞ</code>（半角）/ <code>山田</code></td>
            </tr>
            <tr>
              <th scope="row">桁数</th>
              <td>社員コード</td>
              <td>${codeLength} 桁ちょうど</td>
              <td><code>E100</code> / <code>E10011</code></td>
            </tr>
            <tr>
              <th scope="row">桁数</th>
              <td>フリガナ / 理由</td>
              <td>${kanaMaxLength} 文字以内 / ${reasonMaxLength} 文字以内（コードポイントで数える）</td>
              <td><code>（長い文章を貼り付ける）</code></td>
            </tr>
            <tr>
              <th scope="row">形式</th>
              <td>開始日 / 終了日</td>
              <td><code>uuuu-MM-dd</code> で、実在する日付</td>
              <td><code>2026-02-30</code> / <code>2026/04/01</code> / <code>2026-4-1</code></td>
            </tr>
            <tr>
              <th scope="row">範囲</th>
              <td>開始日</td>
              <td>今日（${today}）以降、${maxMonthsAhead} か月先（${limitDate}）まで</td>
              <td><code>2020-01-01</code> / <code>2099-12-31</code></td>
            </tr>
            <tr>
              <th scope="row">相関</th>
              <td>終了日</td>
              <td>開始日以降であること / 続けて ${maxPeriodDays} 日以内</td>
              <td><code>開始日より前の日</code></td>
            </tr>
            <tr>
              <th scope="row">選択（単一）</th>
              <td>休暇の種類</td>
              <td>選択必須。用意した選択肢のコードであること</td>
              <td><code>（選ばない）</code></td>
            </tr>
            <tr>
              <th scope="row">選択（複数）</th>
              <td>引継ぎ先</td>
              <td>${minBackups} 〜 ${maxBackups} 名（重複は 1 件として数える）</td>
              <td><code>（選ばない）</code> / <code>（4 名選ぶ）</code></td>
            </tr>
            <tr>
              <th scope="row">相関</th>
              <td>引継ぎ先</td>
              <td>申請者本人を含めない</td>
              <td><code>社員コードと同じ人を選ぶ</code></td>
            </tr>
            <tr>
              <th scope="row">突き合わせ</th>
              <td>社員コード / 引継ぎ先</td>
              <td>社員マスタに実在すること</td>
              <td><code>E9999</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="社員マスタ（突き合わせに使う一覧）"
             note="本来はデータベースを引きます。このサンプルでは固定のデータです">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr><th scope="col">社員コード</th><th scope="col">氏名</th><th scope="col">所属</th></tr>
          </thead>
          <tbody>
            <c:forEach var="employee" items="${employees}">
              <tr>
                <th scope="row"><code>${fn:escapeXml(employee.code)}</code></th>
                <td>${fn:escapeXml(employee.name)}</td>
                <td>${fn:escapeXml(employee.department)}</td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        「実在するか」はサーバに聞かないと分かりません。
        こうしたチェックは、形式のチェックを通った値だけを問い合わせます。
      </p>
    </t:panel>

    <t:panel title="ブラウザを通さずに送ってみる" note="選択肢のチェックが必要な理由">
      <p>
        休暇の種類も引継ぎ先も、画面では選択肢しか選べません。
        しかし次のように送れば、画面に無い値でもサーバまで届きます。
      </p>
      <pre class="code-snippet mb-0"><code class="language-plaintext">curl -X POST "${fn:escapeXml(pageContext.request.scheme)}://${fn:escapeXml(pageContext.request.serverName)}:${pageContext.request.serverPort}${fn:escapeXml(formUrl)}" \
     -d "employeeCode=E1001&amp;nameKana=ヤマダ&amp;leaveType=99" \
     -d "startDate=${today}&amp;endDate=${today}&amp;backupCodes=E9999&amp;reason=テスト"</code></pre>
      <p class="text-muted small mt-3 mb-0">
        <code>leaveType=99</code> も <code>backupCodes=E9999</code> も画面には無い値です。
        <strong>「選択肢だから安全」ということはありません</strong>。
        受け取った値が一覧にあるかどうかは、サーバ側で確かめます。
      </p>
    </t:panel>

    <t:resultModal message="${flash}" />
  </jsp:body>
</t:sample>
