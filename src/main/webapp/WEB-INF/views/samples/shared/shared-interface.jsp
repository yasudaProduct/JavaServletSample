<%--
  【サンプル】インタフェースで共通側とアプリ側を切り離す

  SharedInterfaceServlet が次の値をセットします。
    rows            … ServiceLoader が見つけた実装とその読み込み元 (SharedInterfaceServlet.Row)
    employeeSamples … 社員コードの手本
    productSamples  … 商品コードの手本
    input           … 入力された値
    normalized      … 表記を揃えた値
    chosen          … 選ばれた実装
    chosenOrigin    … その実装の読み込み元
    resolved        … 引き当てた名前
    message         … 引き当てられなかった理由
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="formUrl" value="${ctx}/samples/shared/shared-interface" />
<t:sample sampleId="shared-interface">

  <jsp:attribute name="explanation">
    <h2>JAR を分けただけでは解けない問題</h2>
    <p>
      <a href="${ctx}/samples/shared/shared-jar">共通処理を JAR に切り出す</a>で、
      同じコードを 2 つのアプリに配れるようになりました。
      しかし JAR は<strong>配る単位</strong>を分ける道具でしかありません。
      次の問題が残ります。
    </p>
    <p>
      <strong>共通側が、アプリの事情を知ってしまう。</strong>
    </p>
    <p>
      たとえば「コードから名前を引き当てる」処理を共通化したくなったとします。
      素直に書くとこうなります。
    </p>
<pre><code class="language-java">// 共通ライブラリ側（駄目な例）
public final class CodeLookup {
    public static String resolve(String code) {
        if (code.matches("^E[0-9]{4}$")) {      // ← 社員コードの決めごと
            return EmployeeMaster.nameOf(code); // ← アプリ側のクラスを参照している
        }
        return null;
    }
}</code></pre>
    <p>
      この時点で 2 つ壊れています。
    </p>
    <ul>
      <li><strong>依存の向きが逆になった。</strong>
          共通 → アプリ を参照しているので、共通ライブラリを単体でリリースできません</li>
      <li><strong>業務の決めごとが共通側に来た。</strong>
          別のアプリで桁数が違ったときに直せません</li>
    </ul>
    <p>
      そして妥協が始まります。
    </p>
<pre><code class="language-java">public static String resolve(String code, boolean isAdminApp) {
    if (isAdminApp) { ... } else { ... }   // ← ここが共通化の失敗点
}</code></pre>
    <p>
      <strong>分岐フラグが生えた時点で、その共通化は失敗しています。</strong>
      共通 JAR が全アプリの事情を抱え込み、片方の都合では触れないコードになります。
      こうなったら、そのクラスはアプリ側へ戻すのが正しい対処です。
    </p>

    <h2>インタフェースは「依存の向きを変える」道具</h2>
    <p>
      共通側は「コードを渡すと名前が返る」という<strong>形</strong>だけを持ちます。
      何のコードかは各アプリが決めます。
    </p>
<pre><code class="language-java">// 共通ライブラリ側 : 形だけ
public interface CodeResolver {
    boolean accepts(String code);
    String resolve(String code);
}</code></pre>
<pre><code class="language-java">// アプリ側 : 業務の決めごとはここ
public class EmployeeCodeResolver implements CodeResolver {
    private static final Pattern FORM = Pattern.compile("^E[0-9]{4}$");
    ...
}</code></pre>
    <p>
      矢印の向きが変わります。共通側はアプリを指さず、
      <strong>アプリが共通側のインタフェースを指します</strong>。
    </p>
<pre><code class="language-text">【駄目な例】                      【インタフェースで切り離す】

  アプリ ──→ 共通                   アプリ ──→ 共通
     ↑        │                        │        （インタフェース）
     └────────┘                        └──→ 実装はアプリ側
   循環している                      一方向。共通は実装を知らない</code></pre>

    <h3>JAR とインタフェースの使い分け</h3>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr><th>道具</th><th>解決すること</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>JAR</strong></td>
            <td>同じコードを複数のアプリに<strong>配る</strong></td>
          </tr>
          <tr>
            <td><strong>インタフェース</strong></td>
            <td>共通側がアプリの事情を<strong>知らないようにする</strong></td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      どちらか一方ではなく、<strong>両方使います</strong>。
      「jar を分けるか、インタフェースか」ではなく、
      「jar で配り、インタフェースで向きを整える」が答えです。
    </p>

    <h2>実装の登録 : ServiceLoader</h2>
    <p>
      共通側が実装クラスの名前を知らないのなら、誰が実装を見つけるのか。
      JDK 標準の <code>ServiceLoader</code> です。
      クラスパス上の登録ファイルを読んで、実装を組み立てて返します。
    </p>
<pre><code class="language-java">// 共通ライブラリ側。実装クラス名がどこにも出てこない
for (CodeResolver resolver : ServiceLoader.load(CodeResolver.class)) {
    ...
}</code></pre>
    <p>
      登録は、インタフェースの完全修飾名と同じ名前のファイルに実装クラス名を書くだけです。
    </p>
<pre><code class="language-text">src/main/resources/
  META-INF/services/
    com.example.servletsample.shared.CodeResolver   ← ファイル名がインタフェース名
        com.example.servletsample.samples.shared.EmployeeCodeResolver
        com.example.servletsample.samples.shared.ProductCodeResolver</code></pre>

    <h3>Eclipse での置き場所に注意</h3>
    <p>
      この登録ファイルは <strong><code>src/main/resources</code> の下</strong>に置きます。
      <code>src/main/java</code> に置くとコンパイル対象外として無視され、
      <code>WEB-INF/classes</code> にコピーされません。
      その結果 <strong>「実装が 0 件」</strong>になり、
      例外も出ないので原因が分かりにくい詰まり方をします。
    </p>
    <p>
      このリポジトリでは <code>src/main/resources</code> をソース・フォルダとして
      <code>WEB-INF/classes</code> に割り当ててあるので、置くだけで動きます
      （<code>.classpath</code> の <code>src/main/resources</code> の行）。
      Ant と Maven も同じ場所を見ています。
    </p>

    <h3>実装は「引数の無いコンストラクタ」が必須</h3>
    <p>
      <code>ServiceLoader</code> は実装を <code>new</code> で作るので、
      <strong><code>public</code> で引数の無いコンストラクタ</strong>が必要です。
      private にしたり引数を付けると、実行時に見つからなくなります。
    </p>

    <h3>どのクラスローダから探すか</h3>
    <p>
      <code>ServiceLoader.load(Class)</code> は
      <strong>スレッドのコンテキストクラスローダ</strong>から探します。
      Tomcat のリクエスト処理スレッドではアプリのクラスローダが設定されているため、
      そのアプリの <code>WEB-INF/classes</code> と <code>WEB-INF/lib</code> の登録が見つかります。
    </p>
    <p>
      つまり<strong>アプリごとに違う実装が入っていてよい</strong>ということです。
      利用者画面には社員コードの実装だけ、管理画面には両方、といった分け方ができます。
      同じ共通 JAR を配りながら、振る舞いはアプリごとに変わります。
    </p>

    <h3>選ばれる順番は登録順で決まる</h3>
    <p>
      デモの「自動で選ぶ」は <code>accepts()</code> が最初に true を返した実装を使います。
      形が重なる実装を登録すると<strong>意図しない方が選ばれます</strong>。
      実務では、どれを使うかを呼び出し側が明示的に決めるほうが安全です。
    </p>

    <h2>ServiceLoader を使わない場合</h2>
    <p>
      仕組みを増やしたくないなら、アプリ側で組み立てて渡すだけでも同じ効果が得られます。
      大事なのは <code>ServiceLoader</code> ではなく<strong>依存の向き</strong>です。
    </p>
<pre><code class="language-java">// アプリの起動時（リスナーなど）に、使う実装を決めて渡す
List&lt;CodeResolver&gt; resolvers = List.of(
        new EmployeeCodeResolver(),
        new ProductCodeResolver());</code></pre>
    <p>
      共通側が受け取る形にしておけば、共通側は実装を知らずに済みます。
      <code>ServiceLoader</code> の利点は、<strong>アプリ側のコードを 1 行も書かずに
      登録ファイルだけで差し替えられる</strong>ことです。
    </p>

    <h2>共通側に置いてよかったもの</h2>
    <p>
      このサンプルで共通側にあるのは 3 つだけです。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr><th>クラス</th><th>役割</th><th>なぜ共通に置けるか</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>CodeResolver</code></td>
            <td>形（インタフェース）</td>
            <td>実装を知らないので、アプリが増えても変わらない</td>
          </tr>
          <tr>
            <td><code>CodeFormatter</code></td>
            <td>表記を揃える</td>
            <td>「全角を半角に」「前後の空白を落とす」は<strong>どのアプリでも意味が変わらない</strong></td>
          </tr>
          <tr>
            <td><code>ResolverRegistry</code></td>
            <td>実装を集める窓口</td>
            <td>集め方だけを知っている。状態を持たない</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <code>CodeFormatter</code> に「社員コードは E + 4 桁」を書かなかったのが要点です。
      この線引きは、このリポジトリの <code>common/Validators.java</code> と同じ考え方です。
    </p>
    <p>
      なお <code>ResolverRegistry</code> は結果を <code>static</code> に<strong>持ちません</strong>。
      持つと、それ自体が「共通化できない状態」になります
      （→ <a href="${ctx}/samples/shared/shared-state">共通化できないもの（状態）</a>）。
    </p>
  </jsp:attribute>

  <jsp:body>

    <t:panel title="登録されている実装"
             note="共通側は ServiceLoader 経由でしか知りません">
      <c:choose>
        <c:when test="${empty rows}">
          <div class="alert alert-danger mb-0">
            実装が 1 件も見つかりません。
            <code>src/main/resources/META-INF/services/</code> の登録ファイルが
            <code>WEB-INF/classes</code> にコピーされているか確認してください。
          </div>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <thead>
                <tr>
                  <th style="width: 16%">名前</th>
                  <th style="width: 34%">説明</th>
                  <th style="width: 26%">実装クラス</th>
                  <th>読み込み元</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="row" items="${rows}">
                  <tr>
                    <td><strong>${fn:escapeXml(row.resolver.name())}</strong></td>
                    <td>${fn:escapeXml(row.resolver.description())}</td>
                    <td><code>${fn:escapeXml(row.origin.simpleName)}</code></td>
                    <td>
                      <small>
                        ${fn:escapeXml(row.origin.place.label)}
                        （<code>${fn:escapeXml(row.origin.codeSourceName)}</code>）
                      </small>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <t:panel title="引き当ててみる" note="共通側のインタフェース経由で、アプリ側の実装が動きます">
      <form method="get" action="${formUrl}" class="form-inline mb-3">
        <label class="mr-2" for="code">コード</label>
        <input type="text" class="form-control mr-2" id="code" name="code"
               value="${fn:escapeXml(input)}" placeholder="E1001 / P001" style="width: 12rem">
        <button type="submit" class="btn btn-primary mr-2">引き当てる</button>
        <a class="btn btn-outline-secondary" href="${formUrl}">クリア</a>
      </form>

      <c:if test="${not empty input}">
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-3">
            <tbody>
              <tr>
                <th style="width: 34%">入力された値</th>
                <td><code>${fn:escapeXml(input)}</code></td>
              </tr>
              <tr>
                <th>
                  表記を揃えた値
                  <small class="text-muted d-block">共通側の <code>CodeFormatter</code></small>
                </th>
                <td><code>${fn:escapeXml(normalized)}</code></td>
              </tr>
              <c:if test="${not empty chosen}">
                <tr>
                  <th>
                    選ばれた実装
                    <small class="text-muted d-block">アプリ側</small>
                  </th>
                  <td>
                    <strong>${fn:escapeXml(chosen.name())}</strong>
                    <code>${fn:escapeXml(chosenOrigin.simpleName)}</code>
                    <small class="text-muted">
                      （${fn:escapeXml(chosenOrigin.place.label)}）
                    </small>
                  </td>
                </tr>
              </c:if>
              <c:if test="${not empty resolved}">
                <tr class="table-success">
                  <th>引き当てた結果</th>
                  <td><strong>${fn:escapeXml(resolved)}</strong></td>
                </tr>
              </c:if>
            </tbody>
          </table>
        </div>

        <c:if test="${not empty message}">
          <div class="alert alert-warning mb-3">${fn:escapeXml(message)}</div>
        </c:if>
      </c:if>

      <p class="mb-2">
        <strong>試しかた</strong>:
        <code>E1001</code> と <code>P001</code> を入れ比べてください。
        <strong>同じ共通コードを通っているのに、別の実装が動いています</strong>。
        全角の <code>Ｅ１００１</code> や前後に空白を入れても通ります
        （共通側の <code>CodeFormatter</code> が表記を揃えるため）。
      </p>

      <div class="row">
        <div class="col-md-6">
          <table class="table table-sm table-bordered mb-0">
            <thead><tr><th colspan="2">社員コード（E + 4 桁）</th></tr></thead>
            <tbody>
              <c:forEach var="employee" items="${employeeSamples}" end="3">
                <tr>
                  <td style="width: 6rem"><code>${fn:escapeXml(employee.code)}</code></td>
                  <td>${fn:escapeXml(employee.name)}</td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
        <div class="col-md-6">
          <table class="table table-sm table-bordered mb-0">
            <thead><tr><th colspan="2">商品コード（P + 3 桁）</th></tr></thead>
            <tbody>
              <c:forEach var="product" items="${productSamples}" end="3">
                <tr>
                  <td style="width: 6rem"><code>${fn:escapeXml(product.key)}</code></td>
                  <td>${fn:escapeXml(product.value)}</td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
      </div>
    </t:panel>

    <div class="alert alert-info mb-0">
      <strong>ここで確かめたこと</strong>
      <ul class="mb-0">
        <li>共通側は実装クラスの名前を 1 つも知らないまま、アプリ側の処理を動かしている</li>
        <li>実装を増やすとき、<strong>共通ライブラリは一切変わらない</strong>
            （版を上げる必要も、他のアプリを確認する必要もない）</li>
        <li>業務の決めごと（コードの桁数）はアプリ側にあるので、分岐フラグが要らない</li>
      </ul>
    </div>

  </jsp:body>
</t:sample>
