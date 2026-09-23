<%--
  【サンプル】共通処理を JAR に切り出す

  SharedJarServlet が次の値をセットします。
    rows          … クラスごとの読み込み元 (SharedJarServlet.Row)
    sharedVersion … 共通ライブラリの版
    sharedJar     … 共通 JAR の場所 (URL)

  読み込み元は getProtectionDomain().getCodeSource() から取っているので、
  表示されている内容はその場で調べた実際の値です。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="shared-jar">

  <jsp:attribute name="explanation">
    <h2>まず用語をそろえる : 共有ではなく「同梱」</h2>
    <p>
      サーバーを 2 台に分けると、真っ先に出てくるのが「共通処理をどこに置くか」です。
      ここで一番多い誤解が <strong>「共通 JAR は 2 台の間で共有されている」</strong>
      という思い込みです。共有されていません。
      <strong>それぞれの WAR の中にコピーが入っている</strong>だけです。
    </p>
<pre><code class="language-text">サーバー 1                             サーバー 2
├─ app.war                            ├─ app.war
│   ├─ WEB-INF/classes/               │   ├─ WEB-INF/classes/
│   └─ WEB-INF/lib/                   │   └─ WEB-INF/lib/
│        servlet-sample-shared-1.0.0.jar    servlet-sample-shared-1.0.0.jar
│                                     │         ↑ 同じ版のコピーが 2 つある
└─ (Tomcat)                           └─ (Tomcat)</code></pre>
    <p>
      デモの表がこれを示しています。共通ライブラリのクラスは
      <code>WEB-INF/lib/...jar</code> から、アプリ本体のクラスは
      <code>WEB-INF/classes/</code> から読まれていて、
      <strong>どちらもアプリのクラスローダ</strong>が読んでいます。
      Tomcat 側のクラスだけがクラスローダが違い、そこが共有の境界です。
    </p>
    <p>
      「同梱」だと分かると、次のことが自然に出てきます。
    </p>
    <ul>
      <li><strong>WAR を戻せば共通処理の版も戻る</strong>（ロールバックが 1 単位で済む）</li>
      <li><strong>2 台に手で配る作業が無い</strong>（ビルドが入れてくれる）</li>
      <li>逆に、<strong>状態は共通化できない</strong>（コピーが 2 つある＝メモリも 2 つ）</li>
    </ul>
    <p>
      3 つ目が一番効いてきます。詳しくは
      <a href="${ctx}/samples/shared/shared-state">共通化できないもの（状態）</a>で扱います。
    </p>

    <h2>プロジェクトをどう分けるか</h2>
    <p>
      共通処理は<strong>別プロジェクト</strong>にします。同じプロジェクトの中で
      パッケージだけ分けても、「アプリの都合を知らないコード」にはなりません
      （すぐ隣のクラスを参照できてしまうので、いつのまにか依存します）。
    </p>
<pre><code class="language-text">JavaServletSample/          ← Web アプリ (war)
├── src/main/java/              画面ごとの Servlet
├── shared/                     ← 共通ライブラリ (jar)。別プロジェクト
│   ├── pom.xml
│   └── src/main/java/com/example/servletsample/shared/
├── pom.xml
└── build.xml</code></pre>
    <p>
      依存の向きは <strong>アプリ → 共通</strong> の一方向だけです。
      共通ライブラリの <code>pom.xml</code> に依存関係が
      <strong>1 つも無い</strong>のを見てください。JDK 以外に何も要らない状態を保つのが、
      共通ライブラリを長持ちさせるコツです。
    </p>

    <h3>共通に置くもの・置かないもの</h3>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr><th>置く</th><th>置かない</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>入力チェック、書式変換、コード変換</td>
            <td><strong>状態</strong>（<code>static</code> のカウンタ、キャッシュ、セッション）</td>
          </tr>
          <tr>
            <td>DTO、値オブジェクト、列挙型</td>
            <td><strong>業務の決めごと</strong>（「社員コードは 5 桁」）</td>
          </tr>
          <tr>
            <td>どのアプリでも意味が変わらない判定</td>
            <td>Servlet API に触る処理（共通側が Web の事情を知り始める）</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      判断の軸は「今たまたま同じか」ではなく <strong>「変更理由が同じか」</strong>です。
      たまたま同じものを共通化すると、片方の事情で変えたくなったときに
      <code>if (アプリA なら…)</code> が生えて動かせなくなります。
      <strong>分岐フラグを入れたくなった時点で共通化の失敗</strong>なので、
      そのクラスはアプリ側へ戻します。共通側に業務ルールを置かずに済ませる方法は
      <a href="${ctx}/samples/shared/shared-interface">インタフェースで切り離す</a>にあります。
    </p>

    <h2>Eclipse でのプロジェクト構成</h2>
    <p>
      ワークスペースに <strong>2 つのプロジェクト</strong>を並べます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr><th>プロジェクト</th><th>種類</th><th>ファセット</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>JavaServletSample</code></td>
            <td>動的 Web プロジェクト</td>
            <td><code>jst.web</code></td>
          </tr>
          <tr>
            <td><code>servlet-sample-shared</code></td>
            <td>Java プロジェクト（ユーティリティ・モジュール）</td>
            <td><code>jst.utility</code></td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <code>jst.utility</code> が「WAR に JAR として同梱されるプロジェクト」という意味になります。
      これが付いていないと、Web プロジェクト側のデプロイメント・アセンブリーから選べません。
    </p>

    <h3>設定は 2 か所。片方だけだと実行時に落ちる</h3>
    <p>
      Eclipse WTP で一番多い詰まりどころがここです。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr><th>設定場所</th><th>決めること</th><th>忘れると</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>プロパティ → <strong>Java のビルド・パス → プロジェクト</strong></td>
            <td>コンパイルが通るか</td>
            <td>エディタに赤線が出る（すぐ気付ける）</td>
          </tr>
          <tr class="table-danger">
            <td>プロパティ → <strong>デプロイメント・アセンブリー</strong></td>
            <td>WAR の <code>WEB-INF/lib</code> に入るか</td>
            <td><strong>エディタは通るのに、実行時に <code>NoClassDefFoundError</code></strong></td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      「Eclipse 上ではエラーが無いのにサーバーで落ちる」場合、まずここを見ます。
      ソースコードのタブに、このリポジトリの <code>.classpath</code> と
      <code>org.eclipse.wst.common.component</code>（デプロイメント・アセンブリーの実体）を
      並べてあるので、実物を見比べてください。
    </p>

    <h3>依存の向きを逆にしないこと</h3>
    <p>
      Eclipse のプロジェクト参照は<strong>循環も作れてしまいます</strong>
      （共通 → アプリ を参照させてしまう）。ビルドは通ることがありますが、
      共通ライブラリを単体でリリースできなくなり、分けた意味がなくなります。
      共通側の <code>.classpath</code> に Web プロジェクトが出てきたら、それは事故です。
    </p>

    <h2>ビルド設定 : 3 つのツールで同じことを書く</h2>
    <p>
      やることは 3 つとも同じです。<strong>共通ライブラリを JAR にして、
      WAR の <code>WEB-INF/lib</code> に入れる</strong>。書き方だけが違います。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr><th>やること</th><th>Eclipse</th><th>Ant</th><th>Maven</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>共通を JAR にする</td>
            <td><code>jst.utility</code> ファセット</td>
            <td><code>shared-jar</code> ターゲット</td>
            <td><code>shared/pom.xml</code> を <code>install</code></td>
          </tr>
          <tr>
            <td>コンパイルを通す</td>
            <td>ビルド・パス → プロジェクト</td>
            <td><code>classpath.compile</code></td>
            <td><code>&lt;dependency&gt;</code></td>
          </tr>
          <tr>
            <td>WAR に同梱する</td>
            <td>デプロイメント・アセンブリー</td>
            <td><code>explode</code> ターゲット ③</td>
            <td><code>&lt;dependency&gt;</code>（自動）</td>
          </tr>
          <tr>
            <td>版を決める</td>
            <td>（JAR 名）</td>
            <td><code>shared.version</code></td>
            <td><code>&lt;version&gt;</code></td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      Maven だけ <strong>2 段階</strong>になります。共通ライブラリを別プロジェクトにしたので、
      先にローカルリポジトリへ入れる必要があるためです。
    </p>
<pre><code class="language-bash">mvn -f shared/pom.xml install   # ① 共通ライブラリを先に
mvn package                     # ② アプリ側

ant                             # Ant は 1 つのビルドの中で順番に作る</code></pre>
    <p>
      これは Maven の面倒なところではなく、<strong>現場の順番そのもの</strong>です。
      共通ライブラリを先にリリースし、アプリはその版を参照します。
      Docker のビルドもこの順番で書いてあります（<code>docker/tomcat/Dockerfile</code>）。
    </p>

    <h3>provided と runtime を混ぜない</h3>
    <p>
      <code>servlet-api</code> のように <strong>Tomcat が持っているもの</strong>は、
      コンパイルには要りますが WAR に入れてはいけません。入れると Tomcat 側のものと
      二重になり、起動時に
      <code>offending class: javax/servlet/Servlet.class</code> で落ちます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr><th></th><th>Maven</th><th>Ant / Eclipse</th><th>WAR に入るか</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>Tomcat が持っている</td>
            <td><code>&lt;scope&gt;provided&lt;/scope&gt;</code></td>
            <td><code>lib/provided/</code></td>
            <td>入れない</td>
          </tr>
          <tr>
            <td>実行時に必要</td>
            <td><code>compile</code>（既定）</td>
            <td><code>lib/runtime/</code></td>
            <td>入れる</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      Ant には <code>provided</code> スコープに当たるものが無いので、
      <strong>フォルダで分けて代替します</strong>。
      共通ライブラリ側でも同じで、<code>shared/pom.xml</code> に
      <code>servlet-api</code> を足したくなったら、それは
      「共通に置くべきでないもの」を入れようとしている合図です。
    </p>

    <h2>版を固定する。これが一番大事</h2>
    <p>
      複数サーバー構成では
      <strong>「どのサーバーのどのアプリが、どの版の共通処理で動いているか」</strong>
      を後から追えることが最優先です。障害が出たときに、これが分からないと手が止まります。
    </p>
    <ul>
      <li>版は <strong>固定版</strong>で参照する（<code>-SNAPSHOT</code> にしない）。
          ビルドした日によって中身が変わると、再現も切り分けもできません</li>
      <li>版は <strong>JAR のファイル名に入れる</strong>
          （<code>servlet-sample-shared-1.0.0.jar</code>）。WAR を開けば分かります</li>
      <li>共通ライブラリを直したら、<strong>それを使うすべてのアプリで確認する</strong>。
          片方だけで済ませると、もう片方は次のリリースまで壊れたまま気付けません</li>
      <li>共通側は<strong>後方互換</strong>を保つ（メソッドを消さず <code>@Deprecated</code> を経由）。
          そうすると <strong>アプリを 1 つずつデプロイできます</strong></li>
    </ul>
    <p>
      最後の 1 つが、2 台構成の見返りそのものです。後方互換が崩れていると
      「両方同時に上げないと動かない」状態になり、1 台ずつ上げて確かめる道が消えます。
    </p>

    <h3>Tomcat の共有 lib には置かない</h3>
    <p>
      <code>$CATALINA_BASE/lib</code> に共通 JAR を置く方法もありますが、
      複数サーバー構成では<strong>そもそも目的を達成できません</strong>。
      共有クラスローダが届くのは<strong>その Tomcat の中だけ</strong>で、
      サーバーをまたげないからです。加えて、
    </p>
    <ul>
      <li>2 台に手で配ることになり、<strong>配り忘れで版がズレる</strong></li>
      <li>ズレても <strong>WAR を戻しても直らない</strong>（WAR の外にあるので）</li>
      <li>手元や CI で再現しない</li>
    </ul>
    <p>
      例外は <strong>JDBC ドライバだけ</strong>です（Tomcat 公式もそう案内しています）。
      それ以外は WAR に同梱します。
    </p>
  </jsp:attribute>

  <jsp:body>

    <t:panel title="この画面を動かしているクラスは、どこから読まれているか"
             note="getProtectionDomain().getCodeSource() でその場で調べた値です">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-2">
          <thead>
            <tr>
              <th style="width: 18%">クラス</th>
              <th style="width: 22%">何か</th>
              <th style="width: 20%">読み込み元</th>
              <th style="width: 18%">場所</th>
              <th>クラスローダ</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="row" items="${rows}">
              <tr class="${row.origin.place eq 'BUNDLED_JAR' ? 'table-success'
                          : (row.origin.place eq 'CONTAINER' ? 'table-warning' : '')}">
                <td><code>${fn:escapeXml(row.origin.simpleName)}</code></td>
                <td>${fn:escapeXml(row.note)}</td>
                <td><code>${fn:escapeXml(row.origin.codeSourceName)}</code></td>
                <td>
                  ${fn:escapeXml(row.origin.place.label)}<br>
                  <small class="text-muted">${fn:escapeXml(row.origin.place.description)}</small>
                </td>
                <td><small><code>${fn:escapeXml(row.origin.classLoader)}</code></small></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <p class="mb-0">
        <span class="badge badge-success">緑</span> が共通ライブラリ（WAR に同梱された JAR）、
        <span class="badge badge-warning">黄</span> が Tomcat / JDK 側です。
        <strong>緑と白（アプリ本体）のクラスローダが同じ</strong>で、
        黄だけ違うことを確かめてください。そこが「共有される範囲」の境界です。
      </p>
    </t:panel>

    <t:panel title="共通ライブラリの版と置き場所">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th style="width: 30%"><code>SharedLibrary.VERSION</code></th>
              <td><code>${fn:escapeXml(sharedVersion)}</code></td>
            </tr>
            <tr>
              <th>JAR の実際の場所</th>
              <td><code class="text-break">${fn:escapeXml(sharedJar)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <div class="alert alert-info mb-0">
      <strong>次に読むもの</strong>
      <ul class="mb-0">
        <li>
          JAR を分けるだけでは足りない理由 →
          <a href="${ctx}/samples/shared/shared-interface">インタフェースで共通側とアプリ側を切り離す</a>
        </li>
        <li>
          JAR を共通化しても共通化できないもの →
          <a href="${ctx}/samples/shared/shared-state">共通化できないもの（状態）</a>
        </li>
      </ul>
    </div>

  </jsp:body>
</t:sample>
