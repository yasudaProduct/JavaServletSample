<%--
  【座学メモ】Servlet コンテナと WAR（Tomcat は何をしているのか）
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="servlet-container">

  <h2>main メソッドはどこにあるのか</h2>
  <p>
    Java を習うと最初に <code>public static void main</code> を書きます。
    ところが Servlet のプロジェクトには main がありません。それでも動きます。
  </p>
  <p>
    main を持っているのは <strong>Tomcat のほう</strong>だからです。
    起動しているアプリケーションは Tomcat であって、自分が書いた WAR は
    Tomcat に<strong>読み込ませる部品</strong>です。関係が逆になっています。
  </p>
<pre class="topic-figure">ふつうの Java アプリ          Servlet アプリ
  自分のコードが main          Tomcat が main
  必要なライブラリを呼ぶ        Tomcat が自分のコードを呼ぶ
                               （いつ呼ぶかを決めるのも Tomcat）</pre>
  <p>
    「自分が呼ぶ」ではなく「呼ばれるものを置いておく」。
    この形は Servlet に限らず、フィルタ・リスナー・JSP すべてに共通しています。
    <code>init()</code> や <code>destroy()</code> を自分で呼ばないのはこのためです。
  </p>

  <h2>コンテナが引き受けていること</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th>やること</th><th>やってくれなかったら</th></tr></thead>
      <tbody>
        <tr><th scope="row">ポートで待つ</th><td>ServerSocket を自分で書く</td></tr>
        <tr><th scope="row">HTTP を解釈する</th><td>ヘッダの解析、文字コード、multipart を自分で書く</td></tr>
        <tr><th scope="row">スレッドを割り当てる</th><td>スレッドプールを自分で管理する</td></tr>
        <tr><th scope="row">URL から Servlet を選ぶ</th><td>巨大な if 文で振り分ける</td></tr>
        <tr><th scope="row">セッションを管理する</th><td>Cookie の発行と紐づけ、期限切れの掃除を自分で書く</td></tr>
        <tr><th scope="row">JSP を Java に変換する</th><td>HTML を文字列連結で書く</td></tr>
        <tr><th scope="row">エラーページに差し替える</th><td>例外を全部 catch して回る</td></tr>
      </tbody>
    </table>
  </div>
  <p>
    つまり Servlet を学ぶということは、<strong>「どこまでがコンテナの仕事か」を覚えること</strong>でもあります。
    ここを知らないと、コンテナがすでにやっていることを自分で書いてしまいます。
  </p>

  <h2>WAR の中身</h2>
  <p>
    ビルドすると <code>ROOT.war</code> ができます。中身はただの ZIP で、決まった形をしています。
  </p>
<pre class="topic-figure">ROOT.war
├── index.jsp, assets/ …        ← ブラウザから直接取れる (公開領域)
└── WEB-INF/                     ← ブラウザから絶対に取れない
    ├── web.xml                  アプリ全体の設定
    ├── classes/                 自分の .class と .properties
    ├── lib/                     依存ライブラリの .jar
    ├── views/                   (このサイトの決め事) 画面の JSP
    └── tags/ tlds/              (このサイトの決め事) 独自タグ</pre>

  <div class="topic-callout">
    <p class="topic-callout__title">WEB-INF が「取れない」のは仕様</p>
    <p class="mb-0">
      Tomcat の設定ではなく Servlet 仕様で決まっています。だから
      <code>/WEB-INF/views/…</code> はブラウザから開けず、
      <code>forward</code> でなら開けます。転送はサーバの中の移動で、ブラウザは関与しないからです。
      このサイトが JSP を全部 <code>WEB-INF/views/</code> に置いているのは、
      <strong>「Servlet を通さずに JSP が開かれる」事故を仕組みで防ぐ</strong>ためです。
    </p>
  </div>

  <h2>設定は 2 通りで書ける</h2>
  <p>
    Servlet 3.0 から、<code>web.xml</code> に書いていた登録をアノテーションでも書けるようになりました。
    どちらか一方ではなく、<strong>両方が有効</strong>です。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 12rem;"></th><th>@WebServlet など</th><th>web.xml</th></tr></thead>
      <tbody>
        <tr><th scope="row">書く場所</th><td>クラスの真上。近くて分かりやすい</td><td>1 か所にまとまる</td></tr>
        <tr><th scope="row">1 クラスの登録数</th><td>1 つだけ</td><td>何回でも（設定違いで使い回せる）</td></tr>
        <tr><th scope="row">フィルタの順番</th><td>指定できない</td><td><code>filter-mapping</code> を書いた順</td></tr>
        <tr><th scope="row">変更</th><td>再ビルドが必要</td><td>XML だけ差し替えられる</td></tr>
      </tbody>
    </table>
  </div>
  <p>
    このサイトも使い分けています。ふつうの Servlet はアノテーション、
    <strong>順番が意味を持つフィルタ</strong>と、
    <strong>同じクラスを設定違いで 2 回登録する例</strong>は <code>web.xml</code> です
    （「基本 &gt; 設定値の渡し方」で実際に 2 台並べています）。
  </p>

  <h2>クラスローダは 1 本ではない</h2>
  <p>
    Tomcat は、自分が使うライブラリとアプリのライブラリを<strong>別のクラスローダ</strong>で読みます。
    さらにアプリごとにも分かれています。
  </p>
<pre class="topic-figure">Bootstrap （JDK 本体）
  └ System
      └ Common      … Tomcat 自身 + $CATALINA_HOME/lib （servlet-api.jar はここ）
          ├ WebApp1 … アプリ1 の WEB-INF/classes → WEB-INF/lib
          └ WebApp2 … アプリ2 の WEB-INF/classes → WEB-INF/lib</pre>
  <p>
    これで「同じサーバに載せた別のアプリが、違うバージョンのライブラリを使っていても衝突しない」が成り立ちます。
    ただし探し方に癖があり、事故の形も決まっています。
  </p>
  <ul>
    <li><strong><code>NoClassDefFoundError</code>（実行時）</strong> …
        コンパイルは通ったのに <code>WEB-INF/lib</code> に jar が入っていない。
        Maven なら <code>&lt;scope&gt;provided&lt;/scope&gt;</code> を付けすぎていないか確認する</li>
    <li><strong>servlet-api.jar を WAR に同梱してしまう</strong> …
        コンテナ側と二重になり、不可解な型エラーになる。
        だから <code>pom.xml</code> ではこれだけ <code>provided</code> にする</li>
    <li><strong>アプリを再配備してもメモリが減らない</strong> …
        アプリのクラスローダごと捨てられるはずが、
        止め忘れたスレッドや <code>ThreadLocal</code> が参照を握って捨てられない</li>
  </ul>

  <h2>JSP はいつ Java になるのか</h2>
  <p>
    JSP は HTML に見えますが、最初のアクセス時に <strong>Servlet の .java に変換されてコンパイル</strong>されます。
    以後はその .class が動きます。
  </p>
<pre class="topic-figure">hello.jsp → hello_jsp.java → hello_jsp.class → 実行
            (_jspService メソッドの中に HTML が out.write(...) として並ぶ)</pre>
  <p>
    JSP を直すとブラウザの再読み込みだけで反映されるのに、
    Java を直すと再ビルドが要るのは、この違いです。
    Tomcat は JSP のタイムスタンプを見張っていて、変わっていれば作り直します。
  </p>
  <p>
    変換後にどう並ぶかは「基本 &gt; JSP の記法」で項目ごとに追えます。
  </p>

  <h2>配備（デプロイ）の形</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 14rem;">形</th><th>中身</th></tr></thead>
      <tbody>
        <tr><th scope="row">WAR を置く</th>
            <td><code>webapps/</code> に war を置くと自動で展開される。ファイル名がコンテキストパスになる</td></tr>
        <tr><th scope="row">展開済みを置く</th>
            <td>ディレクトリのまま置く。開発中はこちらが速い</td></tr>
        <tr><th scope="row">ROOT にする</th>
            <td><code>ROOT.war</code> という名前にするとコンテキストパスが空文字になる</td></tr>
      </tbody>
    </table>
  </div>
  <div class="topic-callout topic-callout--warn">
    <p class="topic-callout__title">ROOT 配備は間違いを隠す</p>
    <p class="mb-0">
      コンテキストパスが空文字なので、<code>/assets/app.css</code> のような書き方でも動いてしまいます。
      <code>/app</code> に配備した瞬間、CSS と画像だけ 404 になります。
      このサイトも開発時は ROOT ですが、
      「基本 &gt; コンテキストパスと相対パス」で<strong>わざと両方を並べて</strong>違いを見せています。
    </p>
  </div>

  <h2>アプリの一生に割り込む</h2>
  <p>
    起動・停止に処理をはさみたいときは <code>ServletContextListener</code> を置きます。
    このサイトでも、サンプルの目次を組み立てて <code>application</code> スコープに載せるのに使っています
    （<code>CatalogInitializer</code>）。
  </p>
  <p>
    大事なのは<strong>後始末</strong>です。起動時に作ったスレッドや接続を停止時に閉じないと、
    再配備のたびにゴミが残ります。「応用・その他 &gt; リスナー」で、
    後始末を書かないとどうなるかも含めて扱っています。
  </p>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li>呼ぶのは常にコンテナ。自分のコードは「呼ばれる側」として置いてある</li>
      <li><code>WEB-INF</code> の下はブラウザから取れない。これは仕様であって設定ではない</li>
      <li>ライブラリは <code>WEB-INF/lib</code>。ただし servlet-api だけはコンテナのものを使う</li>
      <li>JSP は Servlet に変換されてから動く。だから保存だけで反映される</li>
    </ul>
  </div>

</t:topic>
