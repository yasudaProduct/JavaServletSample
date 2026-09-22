<%--
  【座学メモ】localhost と本番の違い
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="beyond-localhost">

  <h2>手元では絶対に起きないこと</h2>
  <p>
    手元の環境は、本番と次の点が違います。そしてこの違いが、そのまま「本番だけのバグ」になります。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 12rem;"></th><th>手元</th><th>本番</th></tr></thead>
      <tbody>
        <tr><th scope="row">通信</th><td>http</td><td>https（しかも手前で解かれている）</td></tr>
        <tr><th scope="row">相手</th><td>自分だけ</td><td>プロキシ経由で不特定多数</td></tr>
        <tr><th scope="row">台数</th><td>1 台</td><td>複数台。いつ入れ替わるか分からない</td></tr>
        <tr><th scope="row">配備先</th><td>ROOT（コンテキストパスが空）</td><td><code>/app</code> などに置かれることがある</td></tr>
        <tr><th scope="row">設定</th><td>ソースに書いた値</td><td>環境ごとに違う値</td></tr>
        <tr><th scope="row">時刻</th><td>日本時間</td><td>UTC のことが多い</td></tr>
        <tr><th scope="row">ファイル</th><td>置けば残る</td><td>入れ替えで消える</td></tr>
      </tbody>
    </table>
  </div>

  <h2>HTTPS は手前で解かれている</h2>
  <p>
    利用者は <code>https://</code> で来ているのに、
    Tomcat には <code>http://</code> で届く、という構成が一般的です
    （TLS 終端。理由は「<a href="${ctx}/topics/request-lifecycle">リクエストが届いて返るまで</a>」）。
  </p>
  <p>
    すると、Java から見える値が実態とずれます。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 16rem;">呼ぶもの</th><th>本当は</th><th>返ってくる</th></tr></thead>
      <tbody>
        <tr><td><code>request.getScheme()</code></td><td>https</td><td>http</td></tr>
        <tr><td><code>request.isSecure()</code></td><td>true</td><td>false</td></tr>
        <tr><td><code>request.getRemoteAddr()</code></td><td>利用者の IP</td><td><strong>全員プロキシの IP</strong></td></tr>
        <tr><td><code>request.getServerPort()</code></td><td>443</td><td>8080</td></tr>
      </tbody>
    </table>
  </div>
  <div class="topic-callout topic-callout--warn">
    <p class="topic-callout__title">具体的に何が壊れるか</p>
    <ul class="mb-0">
      <li>メールに載せる URL を <code>getScheme()</code> から組み立てていて、
          <strong><code>http://</code> のリンクを送ってしまう</strong></li>
      <li>「同じ IP から 5 回失敗したらロック」が、<strong>全員同じ IP なので全員ロック</strong>される</li>
      <li>アクセスログの IP が全部同じで、調査に使えない</li>
    </ul>
  </div>
  <p>
    プロキシは元の情報を <code>X-Forwarded-For</code> /
    <code>X-Forwarded-Proto</code> というヘッダに入れて渡してきます。
    自分でヘッダを読んでもよいのですが、Tomcat には
    <strong><code>RemoteIpValve</code>（または <code>RemoteIpFilter</code>）</strong>があり、
    これを有効にすると <code>getRemoteAddr()</code> などが正しい値を返すようになります。
    アプリのコードを変えずに済むので、こちらが定番です。
  </p>
  <p>
    ただし注意点があります。<code>X-Forwarded-For</code> は<strong>誰でも付けられるヘッダ</strong>です。
    信頼できるプロキシから来たときだけ信じる設定（<code>internalProxies</code>）が要ります。
    そうしないと、IP 制限を自己申告で突破されます。
  </p>

  <h2>Cookie が本番だけ消える</h2>
  <p>
    <code>Secure</code> 属性を付けた Cookie は HTTPS でしか送られません。
    上のように Tomcat が「自分は http だ」と思っていると、
    <strong>Secure Cookie を発行しないか、発行しても送られない</strong>という状態になります。
    「本番だけログイン状態が保たれない」の典型です。
  </p>
  <p>
    Cookie は他にも、手元では気付きにくい落とし穴があります。
  </p>
  <ul>
    <li><strong><code>Path</code></strong> …
        コンテキストパスが変わると、送られる範囲も変わる</li>
    <li><strong><code>Domain</code></strong> …
        <code>localhost</code> とサブドメイン構成では効き方が違う</li>
    <li><strong><code>SameSite</code></strong> …
        別ドメインの画面から埋め込まれると送られない。
        シングルサインオンや決済からの戻りで効いてくる</li>
  </ul>
  <p>
    属性ごとの挙動は「基本 &gt; Cookie の基本」で切り替えながら確認できます。
  </p>

  <h2>設定を外に出す</h2>
  <p>
    接続先・パスワード・外部 API の URL は、環境ごとに違います。
    <strong>ソースに書くと、環境を増やすたびにビルドし直す</strong>ことになり、
    さらにパスワードがリポジトリに残ります。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 14rem;">置き方</th><th>向き・不向き</th></tr></thead>
      <tbody>
        <tr>
          <td><code>web.xml</code> の <code>context-param</code></td>
          <td>環境で変わらない値（サイト名など）。WAR の中なので環境別にはしにくい</td>
        </tr>
        <tr>
          <td>サーバ側の設定<br>（<code>context.xml</code> の JNDI など）</td>
          <td>DB 接続。<strong>WAR に秘密を含めずに済む</strong>のが利点</td>
        </tr>
        <tr class="table-success">
          <td>環境変数</td>
          <td>コンテナで動かすなら第一候補。
              <code>System.getenv("DB_PASSWORD")</code> で読む</td>
        </tr>
        <tr>
          <td>外部の設定ファイル</td>
          <td>WAR の外に置き、パスだけ環境変数で渡す</td>
        </tr>
      </tbody>
    </table>
  </div>
  <p>
    どの方式でも、<strong>起動時に値が揃っているか確かめて、無ければ起動を止める</strong>ようにします。
    設定漏れは、使われるまで気付かないのが一番まずい形です。
    「基本 &gt; 設定値の渡し方」では、設定値も人が手で書いた文字列である以上、
    読んだ側で検証が要る、という形で扱っています。
  </p>

  <h2>置いたファイルは消える</h2>
  <p>
    アップロードされたファイルを <code>webapps/</code> の下に保存すると、
    <strong>次のデプロイで消えます</strong>。コンテナで動かしていれば、再起動だけで消えます。
  </p>
  <ul>
    <li>永続ディスクにマウントした場所へ置く（パスは設定で渡す）</li>
    <li>オブジェクトストレージ（S3 など）に置く</li>
    <li>件数と容量が小さければ DB の <code>BLOB</code> に入れる
        （このサイトの「ファイル &gt; アップロード・ダウンロード・削除」はこの形）</li>
  </ul>
  <p>
    複数台構成なら、そもそも<strong>ローカルディスクは使えません</strong>。
    A に保存したファイルは、B からは見えないからです。
  </p>

  <h2>時刻とロケール</h2>
  <p>
    サーバの既定タイムゾーンは UTC のことが多く、
    日本時間より 9 時間前です。日付だけを扱う項目でとくに問題になります。
  </p>
<pre class="topic-figure">日本時間 2026-09-22 08:00 に登録
  → UTC では 2026-09-21T23:00Z
  → 日付だけ切り出すと「9/21」になる（前日になる）</pre>
  <ul>
    <li>サーバ既定の <code>new Date()</code> / <code>LocalDate.now()</code> に頼らない。
        <strong>タイムゾーンを明示</strong>する</li>
    <li>保存は UTC、表示のときに変換する、と決めておく</li>
    <li>表示用の書式は <code>Locale</code> によって変わる。
        ブラウザの <code>Accept-Language</code> をそのまま使うと、
        日本語環境以外の人には別形式で出る（「応用・その他 &gt; 国際化」）</li>
  </ul>

  <h2>止めずに入れ替える</h2>
  <p>
    デプロイは「止めて、入れ替えて、上げる」だけではありません。
    利用者が使っている最中に入れ替えるなら、次を考えることになります。
  </p>
  <ul>
    <li><strong>セッションは消える。</strong>入力途中の人は失われる
        （→ <a href="${ctx}/topics/session-scaleout">セッションはどこにあるか</a>）</li>
    <li><strong>DB の変更は先に入れる。</strong>
        新旧どちらのアプリからも動くように、列の追加は先、削除は後</li>
    <li><strong>戻せるようにする。</strong>戻せない変更（列の削除、データの変換）は別の日に分ける</li>
  </ul>

  <h2>出す前の確認</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 22rem;">確認</th><th>怠ると</th></tr></thead>
      <tbody>
        <tr><td>URL を組み立てるとき <code>contextPath</code> を付けているか</td><td>配備先が変わると CSS と画像が 404</td></tr>
        <tr><td>プロキシ配下で IP とスキームが正しく取れるか</td><td>全員同じ IP、リンクが http になる</td></tr>
        <tr><td>Cookie に Secure / HttpOnly / SameSite が付くか</td><td>本番だけログインが続かない</td></tr>
        <tr><td>接続情報がソースに書かれていないか</td><td>リポジトリに秘密が残る</td></tr>
        <tr><td>保存したファイルが再配備で消えないか</td><td>アップロードしたものが消失</td></tr>
        <tr><td>タイムゾーンを明示しているか</td><td>日付が 1 日ずれる</td></tr>
        <tr><td>エラー画面にスタックトレースが出ないか</td><td>内部構造が漏れる</td></tr>
        <tr><td>ログの出力先とローテーションが決まっているか</td><td>ディスクが埋まって止まる</td></tr>
      </tbody>
    </table>
  </div>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li>手前にプロキシがいると、Java から見える「相手」は全部プロキシになる</li>
      <li>環境で変わる値はコードに書かない。起動時に揃っているか確かめる</li>
      <li>ローカルディスクとメモリは<strong>いつか消えるもの</strong>として扱う</li>
      <li>タイムゾーンは明示する。既定に任せない</li>
    </ul>
  </div>

</t:topic>
