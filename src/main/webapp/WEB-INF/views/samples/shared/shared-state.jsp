<%--
  【サンプル】共通化できないもの（状態）

  SharedStateServlet が次の値をセットします。
    history         … 採番の履歴 (SharedStateServlet.Issue)
    staticA/staticB … それぞれのサーバーの static の現在値
    dbValue         … DB の採番の現在値
    loaderA/loaderB … それぞれを読み込んだクラスローダ
    sameClass       … A と B が同じ Class オブジェクトか（false になる）
    simulationError … サーバー B を用意できなかった場合の理由
    sharedVersion   … 共通ライブラリの版

  static のカウンタと DB の採番はこのサイトを見ている全員で共有しています
  （履歴だけがブラウザごと＝セッションごとです）。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/shared/shared-state" />
<t:sample sampleId="shared-state">

  <jsp:attribute name="explanation">
    <h2>JAR を共通化しても、状態は共通化できない</h2>
    <p>
      <a href="${ctx}/samples/shared/shared-jar">共通処理を JAR に切り出す</a>で、
      共通 JAR は<strong>共有されているのではなく、それぞれの WAR に同梱されている</strong>
      ことを確かめました。ここからまっすぐ出てくる結論がこれです。
    </p>
    <p>
      サーバーが 2 台あれば <strong>JVM も 2 つ</strong>あります。
      共通 JAR のクラスはそれぞれの JVM に別々に読み込まれ、
      <strong><code>static</code> もそれぞれ別に存在します</strong>。
      同じ JAR を配っても、同じ版を使っても、状態は 1 つになりません。
    </p>
<pre><code class="language-java">// 共通ライブラリに置いた採番。1 台なら完璧に動く
public final class SequenceCounter {
    private static final AtomicInteger COUNTER = new AtomicInteger();
    public static int next() { return COUNTER.incrementAndGet(); }
}</code></pre>
<pre><code class="language-text">サーバー A : 1, 2, 3 ...
サーバー B : 1, 2, 3 ...   ← 同じ番号が発行される</code></pre>
    <p>
      <code>AtomicInteger</code> なのでスレッドセーフです。同時アクセスでも重複しません。
      <strong>サーバーが 1 台である限りは</strong>何の問題もありません。
      2 台にした日から番号が重複し始めます。
    </p>
    <p>
      しかも<strong>ロードバランサの振り分け次第で再現しない</strong>ため、
      「たまに受付番号が重複する」という形で現れ、原因を掴みにくい類の事故になります。
    </p>

    <h2>なぜ 1 台の Tomcat で再現できるのか</h2>
    <p>
      このデモは 2 台用意していません。共通 JAR を
      <strong>別のクラスローダでもう一度読み込んで</strong>「サーバー B」にしています。
    </p>
<pre><code class="language-java">// 共通 JAR の場所を、そのクラス自身から調べる
URL jar = SequenceCounter.class.getProtectionDomain()
        .getCodeSource().getLocation();

// 親を null にして、自分で JAR から読ませる
URLClassLoader loader = new URLClassLoader(new URL[]{jar}, null);
Class&lt;?&gt; counter = loader.loadClass("com.example.servletsample.shared.SequenceCounter");</code></pre>
    <p>
      Java のクラスの同一性は
      <strong>「完全修飾名」だけでなく「どのクラスローダが読んだか」との組</strong>で決まります。
      同じ <code>SequenceCounter</code> でも、別のクラスローダが読めば別のクラスとして扱われ、
      <code>static</code> フィールドもそれぞれ別に確保されます。
      デモの表で「同じ <code>Class</code> オブジェクトか」が <code>false</code> になっているのがこれです。
    </p>
    <p>
      サーバーが 2 台あるときに起きているのはまさにこれです
      （そちらは JVM が 2 つなので、もっと徹底的に別物です）。
    </p>

    <h3>親クラスローダを null にする理由</h3>
    <p>
      親をアプリのクラスローダにすると、<strong>親に委譲してしまう</strong>ので
      親が既に持っている <code>SequenceCounter</code> が返ってきて、別物になりません。
      <code>null</code> にすると親に委譲せず、自分で JAR から読みます。
    </p>
    <p>
      その代わり、読めるのは <code>java.*</code> だけになります。だから
      <code>SequenceCounter</code> は <strong>JDK 以外に依存しない作り</strong>にしてあります。
      ここに <code>javax.servlet</code> を参照するコードを足すと、この実演は動かなくなります。
    </p>

    <h3>クラスローダは閉じる</h3>
    <p>
      <code>URLClassLoader</code> は開いた JAR を掴んだままになるので、
      <strong>アプリの停止時に必ず閉じます</strong>
      （<code>SharedStateServlet.destroy()</code>）。
      閉じ忘れると、アプリを入れ替えても古いクラスローダがメモリに居座ります。
      Tomcat が警告を出す「クラスローダリーク」がこれです。
    </p>

    <h2>正しい置き場所 : 数えている場所を 1 つにする</h2>
    <p>
      DB は 1 台です。だから DB に寄せれば 1 つの連番になります。
      デモの右の列がそれです。<strong>A から採番しても B から採番しても、通しで増えます</strong>。
    </p>
<pre><code class="language-sql">-- 更新と読み取りを 1 つのトランザクションにまとめる
UPDATE shared_sequence SET next_value = next_value + 1 WHERE name = ?;
SELECT next_value FROM shared_sequence WHERE name = ?;</code></pre>
    <p>
      「読んでから +1 して書き戻す」と書くと、2 台が同時に来たときに同じ番号を掴みます
      （読んだ後、書く前に割り込まれる）。<code>UPDATE</code> が行ロックを取るので、
      もう一方はこの 2 文が終わるまで待ちます。
    </p>
    <p>
      DB のシーケンス（<code>CREATE SEQUENCE</code>）や <code>IDENTITY</code> 列が使えるなら、
      そちらのほうが速くて簡単です。採番テーブルにするのは
      「年度ごとに 1 番から」のような業務上の都合があるときです。
    </p>

    <h2>置き場所の早見表</h2>
    <p>
      迷ったときの判定は<strong>「状態を持つか」</strong>の一点です。
      持たないならロジックなので共通 JAR、持つなら DB。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr><th>共通化したいもの</th><th>置き場所</th><th>2 台にするとどうなるか</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>入力チェック、書式変換、DTO</td>
            <td><strong>共通 JAR</strong></td>
            <td>状態が無いので、コピーが 2 つあっても同じ答えを返す。問題なし</td>
          </tr>
          <tr class="table-danger">
            <td>採番（受付番号・伝票番号）</td>
            <td><strong>DB</strong><br>シーケンス / 採番テーブル</td>
            <td>カウンタが台ごとに独立し、<strong>同じ番号が 2 つ発行される</strong></td>
          </tr>
          <tr class="table-danger">
            <td>ログイン状態・CSRF トークン<br>（<code>HttpSession</code>）</td>
            <td><strong>LB のスティッキー</strong><br>または DB / セッションクラスタ</td>
            <td>振り分け先が変わるとログアウト扱い、CSRF チェックも落ちる</td>
          </tr>
          <tr class="table-danger">
            <td>起動時の DDL・初期データ<br>（<code>contextInitialized</code>）</td>
            <td><strong>Flyway / Liquibase</strong><br>デプロイ手順から 1 回</td>
            <td>2 台が同時に DDL を流す</td>
          </tr>
          <tr class="table-danger">
            <td>定期実行・非同期ジョブ</td>
            <td><strong>DB で排他</strong><br>または片方の cron へ</td>
            <td>同じ仕事が 2 回実行される</td>
          </tr>
          <tr class="table-danger">
            <td>マスタのメモリキャッシュ<br>（application スコープ）</td>
            <td><strong>キャッシュしない</strong><br>短い TTL / <code>updated_at</code> で判定</td>
            <td>片方で更新しても、もう片方は古いまま</td>
          </tr>
          <tr class="table-danger">
            <td>アップロードファイル</td>
            <td><strong>DB の BLOB</strong><br>または共有ストレージ</td>
            <td>ローカルに書くと片方からしか見えない</td>
          </tr>
          <tr>
            <td>整合性の担保<br>一意・外部キー・楽観ロック</td>
            <td><strong>DB 制約</strong></td>
            <td>2 台から同時に来ても効く唯一の場所。アプリの <code>if</code> では守れない</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h3>セッションの扱い（素のサーブレットでの現実解）</h3>
    <p>
      <code>HttpSession</code> もサーバーごとに別です。上から順に現実的です。
    </p>
    <ol>
      <li>
        <strong>ロードバランサのスティッキーセッション</strong>＋セッションに載せるものを最小限に。
        一番トラブルが少ない。「片方が落ちたらそのユーザーは再ログイン」を許容できるならこれで十分
      </li>
      <li>
        <strong>セッションに置かず、毎回 DB を見る。</strong>
        Cookie にはユーザー ID だけ、権限やマスタは都度 DB。2 台構成が一番素直に効く
      </li>
      <li>
        <strong>Tomcat のセッションクラスタリング</strong>
        （<code>&lt;Cluster&gt;</code> + <code>web.xml</code> に <code>&lt;distributable/&gt;</code>）。
        2 ノードなら現実的だが、<strong>セッションに入れる全オブジェクトが
        <code>Serializable</code> でないと落ちます</strong>
      </li>
    </ol>
    <p>
      このサンプルの履歴クラス <code>SharedStateServlet.Issue</code> が
      <code>Serializable</code> なのはそのためです。このリポジトリの
      <code>Flash</code> と <code>ValidationErrors</code> も同じ理由で
      <code>Serializable</code> にしてあります。
    </p>
    <p>
      なお <code>PersistentManager</code> + <code>JDBCStore</code> は
      「再起動をまたいでセッションを残す／アイドルを退避する」仕組みで、
      <strong>2 台でセッションを共有する目的には使えません</strong>。混同されがちなので注意。
    </p>

    <h3>DAO を共通に出すときの注意</h3>
    <p>
      DAO を共通 JAR に出すと、<strong>スキーマ変更が両方のアプリに同時に効きます</strong>。
      切り戻しの道を残すために、スキーマ変更は
      「新旧どちらのアプリでも動く形」に分けます（expand / contract）。
    </p>
    <ol>
      <li>列を<strong>足す</strong>（旧アプリも動く）</li>
      <li>新しいコードを載せる</li>
      <li>使わなくなった列を<strong>消す</strong></li>
    </ol>
    <p>
      列の削除やリネームを、それを使うコードと同じリリースに入れると、
      <strong>切り戻した瞬間に旧版が落ちます</strong>。
    </p>

    <h2>このデモの注意</h2>
    <p>
      <code>static</code> のカウンタと DB の採番は<strong>アプリ全体で 1 つ</strong>なので、
      このサイトを見ている全員で共有しています
      （履歴だけがブラウザごと＝セッションごとです）。
      他の人が同時に触っていると数字が飛びますが、
      それ自体が「アプリ全体で共有されている状態」の見本になっています。
    </p>
  </jsp:attribute>

  <jsp:body>

    <c:if test="${not empty simulationError}">
      <div class="alert alert-danger">
        ${fn:escapeXml(simulationError)}
      </div>
    </c:if>

    <t:panel title="2 台構成を模擬している仕組み"
             note="共通 JAR を別のクラスローダでもう一度読み込んでいます">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-2">
          <thead>
            <tr>
              <th style="width: 20%"></th>
              <th style="width: 40%">サーバー A（実際に動いている Tomcat）</th>
              <th>サーバー B（模擬）</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th>読み込んだクラスローダ</th>
              <td><small><code>${fn:escapeXml(loaderA)}</code></small></td>
              <td>
                <small><code>${empty loaderB ? '(利用できません)' : fn:escapeXml(loaderB)}</code></small>
              </td>
            </tr>
            <tr>
              <th><code>SequenceCounter</code> の現在値</th>
              <td><span class="badge badge-secondary">${staticA}</span></td>
              <td><span class="badge badge-secondary">${staticB}</span></td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mb-0">
        同じ <code>Class</code> オブジェクトか :
        <strong class="text-danger">${sameClass ? 'true' : 'false'}</strong>
        &nbsp;—&nbsp;
        クラス名は同じでも、<strong>クラスローダが違うので別のクラス</strong>として扱われます。
        だから <code>static</code> も別に存在します。
      </p>
    </t:panel>

    <t:panel title="採番してみる"
             note="1 回押すと、static と DB の両方から採番して 1 行追加します">
      <form method="post" action="${formUrl}" class="mb-3">
        <button type="submit" name="action" value="issue-a" class="btn btn-primary mr-2">
          サーバー A で採番
        </button>
        <button type="submit" name="action" value="issue-b" class="btn btn-primary mr-2"
                ${empty loaderB ? 'disabled' : ''}>
          サーバー B で採番
        </button>
        <button type="submit" name="action" value="reset" class="btn btn-outline-secondary">
          最初から
        </button>
      </form>

      <c:choose>
        <c:when test="${empty history}">
          <div class="alert alert-info mb-0">
            <strong>試しかた</strong>:
            「サーバー A で採番」→「サーバー B で採番」→「サーバー A で採番」… と
            <strong>交互に押してください</strong>。
            左の列（共通 JAR の <code>static</code>）は同じ番号が出て、
            右の列（DB）は通しで増えます。
          </div>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-2">
              <thead>
                <tr>
                  <th style="width: 10%">#</th>
                  <th style="width: 24%">採番したサーバー</th>
                  <th style="width: 33%">
                    共通 JAR の <code>static</code>
                    <small class="text-muted d-block">SequenceCounter.next()</small>
                  </th>
                  <th>
                    DB の採番テーブル
                    <small class="text-muted d-block">SharedSequenceDao.next()</small>
                  </th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="issue" items="${history}">
                  <tr>
                    <td>${issue.seq}</td>
                    <td>${fn:escapeXml(issue.server)}</td>
                    <td class="${issue.duplicated ? 'table-danger' : ''}">
                      <strong>${issue.staticValue}</strong>
                      <c:if test="${issue.duplicated}">
                        <span class="badge badge-danger ml-2">重複</span>
                      </c:if>
                    </td>
                    <td class="table-success">
                      <strong>${issue.dbValue}</strong>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <p class="mb-0">
            <c:choose>
              <c:when test="${hasDuplicate}">
                左の列に <span class="badge badge-danger">重複</span> が出ました。
              </c:when>
              <c:otherwise>
                もう片方のサーバーでも採番すると、左の列に
                <span class="badge badge-danger">重複</span> が出ます。
              </c:otherwise>
            </c:choose>
            これが、共通 JAR に <code>static</code> の採番を置いたまま
            2 台構成にしたときに起きることです。
            右の列（DB）は数えている場所が 1 つなので重複しません。
          </p>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <t:panel title="いまの値">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th style="width: 40%">サーバー A の <code>static</code></th>
              <td>${staticA}</td>
            </tr>
            <tr>
              <th>サーバー B の <code>static</code></th>
              <td>${staticB}</td>
            </tr>
            <tr class="table-success">
              <th>DB の採番テーブル</th>
              <td>${dbValue}</td>
            </tr>
            <tr>
              <th>共通ライブラリの版</th>
              <td><code>${fn:escapeXml(sharedVersion)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

  </jsp:body>
</t:sample>
