<%--
  【座学メモ】リクエストが届いて返るまで

  本文だけを書きます。見出し・パンくず・関連サンプル・前後リンクは
  WEB-INF/tags/topic.tag が TopicDefinitions の登録内容から組み立てます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="request-lifecycle">

  <h2>なぜ全体像がいるのか</h2>
  <p>
    Servlet を書いていると、世界は <code>doGet</code> の中から始まるように見えます。
    しかし実際には、そこへ来るまでに 6 〜 7 か所を通っています。
    通り道を知らないと、障害が起きたときに<strong>見る場所を選べません</strong>。
  </p>
  <p>
    「画面が出ない」という連絡を受けたとき、ログを見るのか、DNS を疑うのか、
    プロキシの設定を見るのか。この判断は、地図を持っているかどうかだけで決まります。
  </p>

  <h2>全体図</h2>
<pre class="topic-figure">ブラウザ
  │ ① 名前を引く (DNS)            example.com → 203.0.113.10
  │ ② つなぐ (TCP) / 暗号化 (TLS)  3 ウェイハンドシェイク、証明書の確認
  ▼
[ CDN / ロードバランサ / リバースプロキシ ]   ③ ここで HTTPS を解くことが多い
  │ 静的ファイルはここで返ることもある
  ▼
[ Tomcat のコネクタ ]              ④ HTTP の文字列を Java のオブジェクトにする
  │ スレッドプールから 1 本借りる
  ▼
[ フィルタ ] → [ Servlet ] → [ JSP ]   ⑤ ここが自分の書いたコード
  │            DB / 外部 API を呼ぶ
  ▼
[ レスポンス ]                      ⑥ バッファに溜めて、まとめて返す
  ▼
ブラウザ                            ⑦ HTML を読み、CSS・画像・JS をもう一度取りに来る</pre>

  <h2>① 名前を引く・つなぐ</h2>
  <p>
    ブラウザは URL を「スキーム / ホスト / ポート / パス / クエリ」に分けます。
    ホスト名は DNS で IP アドレスに変換され、その IP へ TCP で接続します。
    <code>https</code> ならさらに TLS の手続き（証明書の確認と鍵の交換）が入ります。
  </p>
  <p>
    ここまでは <strong>Java のコードが 1 行も動いていない</strong>区間です。
    「アプリに何も記録が残っていないのに画面が出ない」ときは、
    たいていこの区間か次の区間で止まっています。
  </p>

  <h2>② 手前にいるもの</h2>
  <p>
    業務システムでは、Tomcat がインターネットに直接面していることはほとんどありません。
    手前に Apache / Nginx / ロードバランサ / CDN のいずれかが立っています。
    理由はだいたい次の 4 つです。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th>役割</th><th>中身</th></tr></thead>
      <tbody>
        <tr><th scope="row">HTTPS を解く</th>
            <td>証明書を持つのは手前の 1 台だけ。Tomcat には HTTP で渡す（TLS 終端）</td></tr>
        <tr><th scope="row">振り分ける</th>
            <td>複数台の Tomcat に分散する。1 台落ちても外さない</td></tr>
        <tr><th scope="row">静的ファイルを返す</th>
            <td>CSS・画像は Java を通さずに返したほうが速い</td></tr>
        <tr><th scope="row">守る</th>
            <td>URL の制限、レート制限、ヘッダの付け外し</td></tr>
      </tbody>
    </table>
  </div>

  <div class="topic-callout topic-callout--warn">
    <p class="topic-callout__title">ここが本番だけおかしくなる原因の半分</p>
    <p class="mb-0">
      手前を通ると、Tomcat から見た「相手」は<strong>プロキシ自身</strong>になります。
      <code>getRemoteAddr()</code> は全員同じ値になり、<code>getScheme()</code> は
      <code>https</code> でアクセスしたのに <code>http</code> を返します。
      詳しくは「<a href="${ctx}/topics/beyond-localhost">localhost と本番の違い</a>」に書きました。
    </p>
  </div>

  <h2>③ Tomcat のコネクタ</h2>
  <p>
    Tomcat がポートで待ち受けている部分を<strong>コネクタ</strong>と呼びます。
    ここがやるのは、届いたバイト列を HTTP として解釈し、
    <code>HttpServletRequest</code> という Java のオブジェクトに詰め替えることです。
  </p>
<pre class="topic-figure">POST /samples/basic/request-parameter HTTP/1.1     → request.getMethod() / getRequestURI()
Host: localhost:8080                               → request.getHeader("Host")
Content-Type: application/x-www-form-urlencoded    → request.getContentType()
Cookie: JSESSIONID=8A3F...                         → request.getCookies() / getSession()
                                                      (空行)
name=%E7%94%B0%E4%B8%AD&amp;age=30                     → request.getParameter("name")</pre>
  <p>
    <code>getParameter</code> が魔法に見えなくなるのは、この対応が見えたときです。
    実際の中身は「基本 &gt; リクエストとレスポンスの中身を見る」で一覧表示できます。
  </p>

  <h2>④ スレッドを 1 本借りる</h2>
  <p>
    コネクタはリクエストごとに、<strong>スレッドプールからスレッドを 1 本取り出します</strong>。
    その 1 本が <code>doGet</code> の最初から最後までを担当し、終わったらプールに返します。
  </p>
  <p>
    ここから次の 2 つが導かれます。どちらも、知らないとバグの原因が分かりません。
  </p>
  <ul>
    <li>Servlet のインスタンスは 1 つで、<strong>複数のスレッドが同時に入ってくる</strong>
        （→ インスタンス変数に値を持つと壊れる）</li>
    <li>スレッドの本数には上限があり、<strong>全部ふさがると次の人は待たされる</strong>
        （→ 遅い処理が 1 つあるだけで、関係ない画面まで返らなくなる）</li>
  </ul>
  <p>
    前者は「基本 &gt; Servlet のライフサイクルとスレッド」で実際にカウンタをずらして確認できます。
    後者は「<a href="${ctx}/topics/threads-and-pools">スレッドとプール</a>」に書きました。
  </p>

  <h2>⑤ フィルタ → Servlet → JSP</h2>
  <p>
    ようやく自分の書いたコードです。ここの順番は決まっています。
  </p>
<pre class="topic-figure">フィルタ1 前処理
  フィルタ2 前処理
    Servlet#service → doGet / doPost
      forward → JSP (ここで HTML を組み立てる)
    Servlet に戻る
  フィルタ2 後処理
フィルタ1 後処理</pre>
  <p>
    入るときと出るときの<strong>両方</strong>を通るのがフィルタの特徴です。
    処理時間の計測や共通ログがフィルタに向くのはこのためです
    （「応用・その他 &gt; フィルタで共通処理をはさむ」で往復を記録して見られます）。
  </p>

  <h2>⑥ 応答はすぐには出ていかない</h2>
  <p>
    <code>out.print()</code> を呼んだ瞬間にブラウザへ届くわけではありません。
    いったん<strong>バッファ</strong>に溜まり、いっぱいになるか、処理が終わるか、
    <code>flushBuffer()</code> を呼んだときに送り出されます。
  </p>
  <p>
    この「まだ送っていない」状態のあいだは、ステータスコードやヘッダを後から変えられます。
    逆に、一度送り始めてしまうと変えられません。
    途中でエラーが起きてもエラーページに差し替えられず、
    <strong>書きかけの HTML の後ろにエラー画面が継ぎ足された、ちぐはぐな画面</strong>になります。
  </p>
  <p>
    このサイトが <code>web.xml</code> で JSP のバッファを 64kb に広げているのは、この事故を防ぐためです。
    挙動そのものは「基本 &gt; Servlet から直接出力する」で確かめられます。
  </p>

  <h2>⑦ 1 画面 = 1 リクエストではない</h2>
  <p>
    HTML が返ったあと、ブラウザは CSS・JavaScript・画像・フォントを<strong>それぞれ別のリクエストで</strong>取りに来ます。
    1 画面を出すのに 30 〜 50 本のリクエストが飛ぶのは普通です。
  </p>
  <p>
    Servlet 側のログを見て「1 回開いただけなのに大量にログが出ている」と驚くのは、これが理由です。
    画面が重いときも、Java の処理が遅いのか、取りに来る回数が多いのかは別問題です。
  </p>

  <h2>症状から見る場所を決める</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 20rem;">見えている症状</th><th>まず疑うところ</th></tr></thead>
      <tbody>
        <tr>
          <td>ブラウザが「サーバが見つかりません」</td>
          <td>① DNS。アプリのログには何も残らない</td>
        </tr>
        <tr>
          <td>502 / 504 が返る</td>
          <td>② 手前のプロキシ。Tomcat が落ちている・返事が遅すぎる</td>
        </tr>
        <tr>
          <td>404 が返る。アクセスログには出ている</td>
          <td>④ URL と Servlet の対応づけ、またはコンテキストパス</td>
        </tr>
        <tr>
          <td>500 が返る</td>
          <td>⑤ 自分のコード。ログにスタックトレースがあるはず</td>
        </tr>
        <tr>
          <td>画面は出るが CSS だけ当たらない</td>
          <td>⑦ 静的ファイルの URL。コンテキストパスの付け忘れが多い</td>
        </tr>
        <tr>
          <td>特定の画面だけでなく全部が返ってこない</td>
          <td>④ スレッドが全部ふさがっている可能性。個別の画面の問題ではない</td>
        </tr>
        <tr>
          <td>手元では動くが本番だけ動かない</td>
          <td>②③ 手前の構成、または環境ごとの設定</td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li>アプリのログに何も残っていなければ、原因は<strong>アプリより手前</strong>にある</li>
      <li>リクエスト 1 本 = スレッド 1 本。だから同時アクセスの話はスレッドの話になる</li>
      <li>レスポンスは「送り始めるまで」は取り消せる。送り始めたら取り消せない</li>
    </ul>
  </div>

</t:topic>
