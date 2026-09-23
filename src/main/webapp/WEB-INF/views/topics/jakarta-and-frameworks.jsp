<%--
  【座学メモ】javax から jakarta へ、そしてフレームワークへ
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="jakarta-and-frameworks">

  <h2>import 文が 2 種類ある理由</h2>
  <p>
    Web で Servlet のコードを探すと、2 種類が混ざって出てきます。
  </p>
<pre><code class="language-java">import javax.servlet.http.HttpServlet;    // 古い記事・書籍・既存システム
import jakarta.servlet.http.HttpServlet;  // 新しい記事</code></pre>
  <p>
    <strong>中身はほぼ同じです。</strong>名前空間（パッケージ名）だけが変わりました。
    理由は技術的なものではなく、権利の話です。
    Java EE が Oracle から Eclipse Foundation に移管された際、
    「javax」という名前を引き続き使うことができなかったため、
    Jakarta EE 9 で一斉に <code>jakarta.*</code> へ改名されました。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 11rem;">世代</th><th>名前空間</th><th>動くコンテナ</th></tr></thead>
      <tbody>
        <tr><td>Servlet 3.1 / 4.0</td><td><code>javax.servlet</code></td><td>Tomcat 8 / 9</td></tr>
        <tr><td>Servlet 5.0 以降</td><td><code>jakarta.servlet</code></td><td>Tomcat 10 以降</td></tr>
      </tbody>
    </table>
  </div>
  <div class="topic-callout topic-callout--warn">
    <p class="topic-callout__title">混ぜると動かない</p>
    <p class="mb-0">
      <code>javax</code> で作った WAR を Tomcat 10 に置いても、Servlet として認識されません。
      エラーではなく<strong>ただ 404 になる</strong>ので、原因が分かりにくいのが厄介です。
      「Tomcat のバージョンを上げたら全部 404」は、まずこれを疑います。
    </p>
  </div>

  <h2>このサイトが javax なのはなぜか</h2>
  <p>
    学習・参照用だからです。
    日本語の解説記事、書籍、社内の既存システムの多くが <code>javax.servlet</code> 前提で書かれています。
    読み替えなしで照らし合わせられるほうが、学ぶときの摩擦が小さいという判断です。
  </p>
  <p>
    新規に作るなら <code>jakarta</code> を選びます。移行そのものは、思ったより機械的です。
  </p>
  <ol>
    <li><code>import javax.servlet</code> → <code>import jakarta.servlet</code> に一括置換</li>
    <li>JSP のタグライブラリ URI を変更する
        （JSTL が <code>http://java.sun.com/jsp/jstl/core</code> →
        <code>jakarta.tags.core</code>）</li>
    <li>依存ライブラリを Jakarta 対応版に上げる（JSTL、DB ドライバ、PDF ライブラリなど）</li>
    <li><code>web.xml</code> のスキーマ宣言を新しいものにする</li>
    <li>Tomcat 10 以降で動かす</li>
  </ol>
  <p>
    自分のコードだけなら 1 〜 2 時間の作業ですが、
    <strong>止まるのはたいてい依存ライブラリ</strong>です。
    対応版が出ていない古いライブラリがあると、そこで足が止まります。
    Tomcat には変換ツール（Migration Tool for Jakarta EE）もあり、
    WAR を置くだけで自動変換させることもできます。
  </p>

  <h2>Spring MVC は Servlet 1 個</h2>
  <p>
    「現場では Spring を使うから、Servlet は覚えなくてよい」と言われることがあります。
    実際には逆で、<strong>Spring MVC は Servlet の上に乗っているだけ</strong>です。
  </p>
<pre class="topic-figure">ブラウザ
  ▼
[ Servlet コンテナ ]           ← ここは今までと同じ
  ▼
DispatcherServlet              ← 「/*」に対応づけられた Servlet が 1 個だけ
  ├ どの @Controller のどのメソッドを呼ぶか決める   (= URL マッピング)
  ├ パラメータを引数に詰める                        (= getParameter)
  ├ 戻り値からビューを決める                        (= forward 先の決定)
  └ 例外を拾ってエラー応答にする                    (= error-page)</pre>
  <p>
    つまり、今まで自分で書いていたことを 1 個の Servlet が肩代わりしています。
    対応はほぼ 1 対 1 です。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 18rem;">素の Servlet</th><th>Spring MVC</th></tr></thead>
      <tbody>
        <tr><td><code>@WebServlet("/orders")</code></td><td><code>@GetMapping("/orders")</code></td></tr>
        <tr><td><code>request.getParameter("id")</code></td><td><code>@RequestParam String id</code></td></tr>
        <tr><td><code>request.setAttribute(...)</code> + forward</td><td><code>Model</code> に詰めてビュー名を返す</td></tr>
        <tr><td><code>Filter</code></td><td><code>Filter</code>（そのまま）/ <code>HandlerInterceptor</code></td></tr>
        <tr><td><code>web.xml</code> の <code>error-page</code></td><td><code>@ExceptionHandler</code> / <code>@ControllerAdvice</code></td></tr>
        <tr><td><code>HttpSession</code></td><td><code>HttpSession</code>（そのまま）</td></tr>
      </tbody>
    </table>
  </div>
  <p>
    <strong>右側だけ覚えると、うまくいかないときに手が止まります。</strong>
    404 が返る、文字化けする、Cookie が送られない、セッションが消える。
    これらはフレームワークの層ではなく、下の層で起きていることだからです。
  </p>

  <h2>Spring Boot になると Tomcat はどこへ行くのか</h2>
  <p>
    Spring Boot では WAR を作らず、実行可能な JAR を作って <code>java -jar</code> で起動します。
    Tomcat が消えたわけではなく、<strong>JAR の中に組み込まれています</strong>（組み込み Tomcat）。
  </p>
<pre class="topic-figure">これまで                    Spring Boot
  Tomcat を立てる             java -jar app.jar
  WAR を置く                   ↓
  Tomcat が WAR を読む        アプリが Tomcat を起動する（内側にいる）</pre>
  <p>
    関係が裏返っただけで、ポートで待ち、スレッドを割り当て、Servlet を呼ぶ流れは同じです。
    だからスレッド数の話も、セッションの話も、そのまま通用します。
  </p>

  <h2>画面の作り方はどこへ向かったか</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 13rem;">やり方</th><th>いま</th></tr></thead>
      <tbody>
        <tr>
          <td>JSP</td>
          <td>既存システムでは現役。新規で選ばれることは減った
              （Spring Boot の JAR 起動と相性が悪い）</td>
        </tr>
        <tr>
          <td>Thymeleaf など</td>
          <td>サーバ側で HTML を組み立てる路線の後継。考え方は JSP とほぼ同じ</td>
        </tr>
        <tr>
          <td>SPA（React / Vue）+ API</td>
          <td>サーバは JSON を返すだけ。画面はブラウザ側で組み立てる</td>
        </tr>
      </tbody>
    </table>
  </div>
  <p>
    3 つめに進んでも、サーバ側でやることは変わりません。
    URL の設計、認証・認可、入力検証、トランザクション、エラーの返し方。
    <strong>このサイトの非同期通信カテゴリでやっていることが、そのまま API 側の仕事</strong>です。
  </p>

  <h2>次に何を学ぶか</h2>
  <ol>
    <li><strong>SQL と DB。</strong>
        業務システムの難所はほぼここにあります。索引、トランザクション、ロック</li>
    <li><strong>Java の標準ライブラリ。</strong>
        コレクション、<code>java.time</code>、<code>Optional</code>、例外。
        フレームワークを変えても残る知識です</li>
    <li><strong>ビルドと依存管理。</strong>
        Maven / Gradle。「動かない」の半分は依存関係の問題です</li>
    <li><strong>テスト。</strong>
        JUnit。層を分けておくと書けるようになります
        （→ <a href="${ctx}/topics/layering">どこに何を書くか</a>）</li>
    <li><strong>そのあとでフレームワーク。</strong>
        Spring Boot。ここまで来ていれば、
        何を肩代わりしてくれているのかが分かった状態で使えます</li>
  </ol>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li><code>javax</code> と <code>jakarta</code> は名前だけの違い。ただし<strong>混ぜると動かない</strong></li>
      <li>Tomcat 9 までが <code>javax</code>、10 以降が <code>jakarta</code></li>
      <li>Spring MVC は「<code>/*</code> に対応づけられた Servlet 1 個」から始まっている</li>
      <li>フレームワークが隠してくれるのは書く量であって、仕組みではない</li>
    </ul>
  </div>

</t:topic>
