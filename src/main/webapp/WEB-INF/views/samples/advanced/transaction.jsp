<%--
  【サンプル】データベースのトランザクション（commit と rollback）

  TransactionServlet が次の値をセットします。
    accounts     … 口座と残高
    totalBalance … 残高の合計（振替では変わらないはずの値）
    initialTotal … 初期状態の合計
    history      … 振替の履歴
    outcome      … 直前に実行した結果（TransferOutcome）
    formError    … 入力の誤り
    flash        … 「元に戻しました」

  データはメモリ上の H2 に入っていて、アプリを再起動すると消えます。
  また、このサイトを見ている全員で共有しています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/advanced/transaction" />
<t:sample sampleId="transaction">

  <jsp:attribute name="explanation">
    <h2>「全部やるか、1 つもやらないか」</h2>
    <p>
      振替は 1 つの処理に見えて、中身は 3 つの更新です。
    </p>
<pre><code class="language-sql">-- ① 送金元から引く
UPDATE accounts SET balance = balance - 10000 WHERE id = 1;
-- ② 送金先に足す
UPDATE accounts SET balance = balance + 10000 WHERE id = 2;
-- ③ 履歴を残す
INSERT INTO transfers (from_code, to_code, amount) VALUES ('A-001', 'A-002', 10000);</code></pre>
    <p>
      ①だけ成功して②で落ちたら、<strong>お金が消えます</strong>。
      「途中まで」を作らないための仕組みがトランザクションです。
    </p>

    <h2>書き方</h2>
<pre><code class="language-java">try (Connection connection = Database.getConnection()) {
    connection.setAutoCommit(false);        // ここから
    try {
        withdraw(connection, fromId, amount);
        deposit(connection, toId, amount);
        insertHistory(connection, fromId, toId, amount);
        connection.commit();                // ここまでをまとめて確定
    } catch (RuntimeException e) {
        connection.rollback();              // まとめて取り消す
        throw e;
    } finally {
        connection.setAutoCommit(true);     // 接続を返す前に戻す
    }
}</code></pre>
    <p>
      JDBC の既定は<strong>自動コミット</strong>で、1 文ごとに確定します。
      まとめたいときだけ <code>setAutoCommit(false)</code> で切ります。
    </p>

    <h3>finally で戻すのを忘れない</h3>
    <p>
      コネクションプールを使っていると、<code>close()</code> しても接続は
      <strong>捨てられずにプールへ返るだけ</strong>です。
      自動コミットを切ったまま返すと、次にその接続を借りた処理が
      <strong>commit されないまま終わります</strong>。
      「借りたときの状態に戻してから返す」が鉄則です。
    </p>

    <h2>いちばんの落とし穴 : 接続が別だとまとまらない</h2>
    <p>
      トランザクションは<strong>コネクション 1 本に対して</strong>効きます。
      DAO のメソッドがそれぞれ接続を開いていると、別々のトランザクションになり、
      まとめて取り消せません。
    </p>
<pre><code class="language-java">// 【駄目な例】 それぞれが接続を開いている
accountDao.withdraw(fromId, amount);   // ← 接続 A。ここで確定してしまう
accountDao.deposit(toId, amount);      // ← 接続 B。ここで落ちても A は戻らない

// 【良い例】 開いた接続を引き回す
try (Connection connection = Database.getConnection()) {
    connection.setAutoCommit(false);
    accountDao.withdraw(connection, fromId, amount);
    accountDao.deposit(connection, toId, amount);
    connection.commit();
}</code></pre>
    <p>
      そのため、このサンプルの更新メソッドは <code>Connection</code> を引数で受け取ります。
      <strong>「どこからどこまでが 1 つのまとまりか」を決めるのは呼び出し側の仕事</strong>だからです。
    </p>

    <h3>境界はどこに置くか</h3>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>層</th><th>トランザクションの扱い</th></tr></thead>
        <tbody>
          <tr><td>Servlet（画面）</td><td>持たない。画面の都合とデータの整合性は別の話</td></tr>
          <tr><td><strong>サービス（業務処理）</strong></td>
              <td><strong>ここで始めて、ここで終える</strong>。「振替」という業務の単位と一致する</td></tr>
          <tr><td>DAO（データ）</td><td>持たない。渡された接続を使うだけ</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      このサンプルはサービス層を作らず <code>TransferDao#transfer</code> に置いていますが、
      画面が増えてきたら分けてください。
      Spring を使うと <code>@Transactional</code> を付けるだけでこの境界を宣言できます。
    </p>

    <h2>SELECT してから UPDATE、にしない</h2>
    <p>
      残高チェックをこう書きたくなります。
    </p>
<pre><code class="language-java">// 【危ない】 2 つの間に、別のリクエストが割り込める
int balance = selectBalance(connection, fromId);
if (balance &lt; amount) {
    throw new ApplicationException("E-4001", "残高が足りません。");
}
updateBalance(connection, fromId, balance - amount);</code></pre>
    <p>
      同じ口座に同時に 2 件の出金が来ると、<strong>両方とも「足りる」と判定して</strong>
      残高がマイナスになりえます。判定を UPDATE の条件に含めてしまえば、
      データベースが 1 つの操作として扱ってくれます。
    </p>
<pre><code class="language-java">// 【安全】 条件に入れて、更新できた件数で判断する
String sql = "UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance &gt;= ?";
if (statement.executeUpdate() == 0) {
    throw new ApplicationException("E-4001", "残高が足りません。");
}</code></pre>
    <p>
      <code>balance = balance - ?</code> と書いているのもポイントです。
      Java 側で計算した値を書き込むのではなく<strong>データベースに計算させる</strong>ことで、
      読んでから書くまでの隙間を無くしています。
    </p>

    <h2>分離レベル</h2>
    <p>
      同時に動いている他のトランザクションの途中経過が、どこまで見えるかの設定です。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>レベル</th><th>起きうること</th><th>備考</th></tr>
        </thead>
        <tbody>
          <tr><td>READ UNCOMMITTED</td><td>未確定の値が見える（ダーティリード）</td><td>まず使いません</td></tr>
          <tr><td><strong>READ COMMITTED</strong></td><td>同じ行を 2 回読むと値が変わりうる</td>
              <td>PostgreSQL / Oracle / SQL Server の既定</td></tr>
          <tr><td><strong>REPEATABLE READ</strong></td><td>件数が変わりうる</td>
              <td>MySQL（InnoDB）/ H2 の既定</td></tr>
          <tr><td>SERIALIZABLE</td><td>ほぼ起きない</td><td>その代わり待ちが増えます</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      既定のままで済むことがほとんどです。
      <strong>変えるのは、困ったことが起きてから</strong>で構いません。
      「同時に更新されたら困る」だけなら、分離レベルではなく
      <a href="${ctx}/samples/list/optimistic-lock">楽観ロック</a>で解くほうが素直です。
    </p>

    <h2>知っておくとよいこと</h2>
    <ul>
      <li>
        <strong>ロールバックしても採番は戻りません</strong> …
        <code>IDENTITY</code> や <code>SEQUENCE</code> は取り消されないので、
        ID に欠番ができます。「連番でなければならない伝票番号」は別の仕組みで採ります
      </li>
      <li>
        <strong>長いトランザクションを避ける</strong> …
        画面をまたいで開きっぱなしにしない、中で外部 API を呼ばない。
        その間ずっと行がロックされ、他の処理が待たされます
      </li>
      <li>
        <strong>DDL は暗黙にコミットされることがあります</strong> …
        処理の途中で <code>CREATE TABLE</code> などを実行しないでください
      </li>
      <li>
        <strong>rollback も失敗しうる</strong> …
        接続が切れていれば例外になります。元の例外を消さないよう、
        ログに残しつつ元の例外を投げ直します
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>

    <t:resultModal message="${flash}" />

    <t:panel title="① 口座の残高" note="振替では、合計は変わらないはずです">
      <div class="table-responsive">
        <table class="table table-sm table-bordered">
          <thead>
            <tr><th>口座番号</th><th>名義</th><th class="text-right">残高</th></tr>
          </thead>
          <tbody>
            <c:forEach var="account" items="${accounts}">
              <tr>
                <td><code>${fn:escapeXml(account.code)}</code></td>
                <td>${fn:escapeXml(account.name)}</td>
                <td class="text-right"><fmt:formatNumber value="${account.balance}" /> 円</td>
              </tr>
            </c:forEach>
          </tbody>
          <tfoot>
            <tr class="${totalBalance ne initialTotal ? 'table-danger' : 'table-light'}">
              <th colspan="2">合計</th>
              <th class="text-right"><fmt:formatNumber value="${totalBalance}" /> 円</th>
            </tr>
          </tfoot>
        </table>
      </div>

      <c:if test="${totalBalance ne initialTotal}">
        <div class="alert alert-danger mb-0" role="alert">
          <strong>合計が初期状態（<fmt:formatNumber value="${initialTotal}" /> 円）と違います。</strong>
          振替でお金が増えたり減ったりすることはありません。
          トランザクションを使わずに途中で失敗させたため、
          <strong>出金だけが確定したまま残っています</strong>。
          これが「途中まで実行された」状態です。
        </div>
      </c:if>
    </t:panel>

    <t:panel title="② 振替する" note="トランザクションの有無と、途中で失敗させるかを選べます">
      <c:if test="${not empty formError}">
        <div class="alert alert-warning" role="alert">${fn:escapeXml(formError)}</div>
      </c:if>

      <form action="${formUrl}" method="post">
        <div class="form-row">
          <div class="form-group col-md-4">
            <label for="fromId">送金元</label>
            <select class="form-control" id="fromId" name="fromId">
              <c:forEach var="account" items="${accounts}" varStatus="s">
                <option value="${account.id}" ${s.first ? 'selected' : ''}>
                  ${fn:escapeXml(account.code)} ${fn:escapeXml(account.name)}
                </option>
              </c:forEach>
            </select>
          </div>
          <div class="form-group col-md-4">
            <label for="toId">送金先</label>
            <select class="form-control" id="toId" name="toId">
              <c:forEach var="account" items="${accounts}" varStatus="s">
                <option value="${account.id}" ${s.index eq 1 ? 'selected' : ''}>
                  ${fn:escapeXml(account.code)} ${fn:escapeXml(account.name)}
                </option>
              </c:forEach>
            </select>
          </div>
          <div class="form-group col-md-4">
            <label for="amount">金額</label>
            <input type="text" class="form-control" id="amount" name="amount" value="10000">
          </div>
        </div>

        <div class="form-group">
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="useTransaction"
                   name="useTransaction" value="1" checked>
            <label class="custom-control-label" for="useTransaction">
              トランザクションを使う<span class="text-muted">（setAutoCommit(false) → commit / rollback）</span>
            </label>
          </div>
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="failMidway"
                   name="failMidway" value="1">
            <label class="custom-control-label" for="failMidway">
              出金のあとでわざと失敗させる<span class="text-muted">（デモ用）</span>
            </label>
          </div>
        </div>

        <button type="submit" class="btn btn-primary">振替する</button>
      </form>

      <hr>
      <p class="mb-0 text-muted small">
        <strong>試してほしい順番:</strong>
        ①「トランザクションを使う」＋「わざと失敗」→ 残高は変わりません（rollback）。
        ②「トランザクションを使わない」＋「わざと失敗」→
        <strong>出金だけが確定して、合計が減ったまま戻りません</strong>。
        ③「元に戻す」で初期状態に戻せます。
      </p>
    </t:panel>

    <c:if test="${not empty outcome}">
      <t:panel title="③ 実行した結果" note="どの手順まで進んだかを並べています">
        <c:choose>
          <c:when test="${outcome.committed}">
            <div class="alert alert-success" role="alert">
              <strong>commit しました。</strong> ${fn:escapeXml(outcome.message)}
            </div>
          </c:when>
          <c:when test="${outcome.rolledBack}">
            <div class="alert alert-warning" role="alert">
              <strong>rollback しました。</strong>
              ${fn:escapeXml(outcome.message)}
              <span class="badge badge-secondary ml-1">${fn:escapeXml(outcome.errorType)}</span>
              <div class="mt-1">
                途中まで実行した更新は、すべて取り消されました。残高は変わっていません。
              </div>
            </div>
          </c:when>
          <c:otherwise>
            <div class="alert alert-danger" role="alert">
              <strong>失敗しましたが、取り消せませんでした。</strong>
              ${fn:escapeXml(outcome.message)}
              <span class="badge badge-secondary ml-1">${fn:escapeXml(outcome.errorType)}</span>
              <div class="mt-1">
                自動コミットのまま実行したため、出金はすでに確定しています。
              </div>
            </div>
          </c:otherwise>
        </c:choose>

        <ol class="mb-0">
          <c:forEach var="step" items="${outcome.steps}">
            <li><code class="small">${fn:escapeXml(step)}</code></li>
          </c:forEach>
        </ol>
      </t:panel>
    </c:if>

    <t:panel title="④ 振替の履歴" note="commit されたものだけが残ります">
      <c:choose>
        <c:when test="${empty history}">
          <p class="text-muted mb-0">まだ履歴はありません。</p>
        </c:when>
        <c:otherwise>
          <ul class="mb-0">
            <c:forEach var="line" items="${history}">
              <li><code>${fn:escapeXml(line)}</code></li>
            </c:forEach>
          </ul>
        </c:otherwise>
      </c:choose>
      <hr>
      <p class="mb-0 text-muted small">
        rollback した振替は、履歴にも残りません（INSERT ごと取り消されるため）。
        「失敗したことを記録に残したい」場合は、
        <strong>別のトランザクションで</strong>書く必要があります。
      </p>
    </t:panel>

    <t:panel title="⑤ 元に戻す" note="何度でも試せます">
      <form action="${formUrl}" method="post">
        <input type="hidden" name="action" value="reset">
        <button type="submit" class="btn btn-outline-secondary">初期状態に戻す</button>
      </form>
      <hr>
      <p class="mb-0 text-muted small">
        このデータはメモリ上の H2 に入っていて、<strong>このサイトを見ている全員で共有しています</strong>。
        アプリを再起動すると消えます。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
