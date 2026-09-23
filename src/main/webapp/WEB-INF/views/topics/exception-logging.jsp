<%--
  【座学メモ】例外とログ（障害を追えるアプリにする）
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="exception-logging">

  <h2>障害調査は書いた時点で勝負がついている</h2>
  <p>
    「昨日の午後、登録できなかったそうです。誰かは分かりません」。
    実際に来る連絡はこの粒度です。ここから原因にたどり着けるかどうかは、
    調査の腕ではなく、<strong>その日のコードに何が残っているか</strong>で決まります。
  </p>
  <p>
    動いているときのコードは誰が書いても同じです。差が出るのは、壊れたときの書き方だけです。
  </p>

  <h2>例外は 3 種類に分けて考える</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead>
        <tr><th style="width: 11rem;">種類</th><th>例</th><th>返し方</th></tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>入力の誤り</strong></td>
          <td>必須が空、日付の形式が違う</td>
          <td>そもそも例外にしない。入力画面に戻して赤字で指摘する。
              入力値は保持する</td>
        </tr>
        <tr>
          <td><strong>業務上の都合</strong></td>
          <td>在庫不足、締め切り超過、二重申請</td>
          <td>専用の例外（<code>ApplicationException</code> など）にして、
              <strong>何が起きたかを利用者の言葉で</strong>伝える。ログは WARN 程度</td>
        </tr>
        <tr>
          <td><strong>システムの異常</strong></td>
          <td>DB に繋がらない、NullPointerException、設定ミス</td>
          <td>利用者には「時間をおいて…」とだけ伝え、
              <strong>詳細はログへ</strong>。ERROR で全部残す</td>
        </tr>
      </tbody>
    </table>
  </div>
  <p>
    区別が要るのは、<strong>利用者への伝え方が違う</strong>からです。
    在庫不足に「システムエラーが発生しました」と出すと問い合わせが来ますし、
    DB 障害に「入力内容を確認してください」と出すと利用者が無限に入力し直します。
  </p>
  <p>
    <code>web.xml</code> の <code>&lt;error-page&gt;</code> は
    <strong>例外の型でページを割り当てられる</strong>ので、この分類とそのまま対応します。
    このサイトでも業務例外だけ専用ページにしています（「応用・その他 &gt; エラー処理とエラーページ」）。
  </p>

  <h2>やってはいけない 4 つ</h2>

  <h3>1. 握りつぶす</h3>
<pre><code class="language-java">try {
    dao.insert(order);
} catch (SQLException e) {
    // 何もしない  ← 一番やってはいけない
}</code></pre>
  <p>
    画面は「登録しました」と出て、データは入っていません。
    しかもログに何も残らないので、<strong>後から追う手段が存在しません</strong>。
    「とりあえず動かす」ために書いた空の catch は、必ず残ります。
  </p>

  <h3>2. 原因を捨てる</h3>
<pre><code class="language-java">catch (SQLException e) {
    throw new RuntimeException("登録に失敗しました");     // 悪い: e が消える
}
catch (SQLException e) {
    throw new RuntimeException("登録に失敗しました", e);   // 良い: 原因が繋がる
}</code></pre>
  <p>
    第 2 引数に元の例外を渡すと、ログに <code>Caused by:</code> として連なります。
    捨ててしまうと「登録に失敗しました」としか残らず、
    <strong>制約違反なのか接続断なのかが永久に分かりません</strong>。
  </p>

  <h3>3. 文字列にして捨てる</h3>
<pre><code class="language-java">log.error("エラー: " + e.getMessage());   // 悪い: 発生場所が消える
log.error("注文の登録に失敗 orderId=" + id, e);  // 良い: 例外そのものを渡す
</code></pre>
  <p>
    <code>getMessage()</code> だけだと行番号が出ません。
    <code>NullPointerException</code> に至っては <code>null</code> と出るだけです。
    ログ出力は<strong>例外オブジェクトをそのまま渡す</strong>のが原則です。
  </p>

  <h3>4. 同じ例外を何度もログに出す</h3>
  <p>
    各層で「ログに出して、投げ直す」をやると、同じスタックトレースが 3 回出ます。
    調査時に「3 件エラーが起きた」と誤読します。
    <strong>ログに出すのは受け止める人が 1 回だけ</strong>。途中の層は、情報を足して投げ直すだけにします。
  </p>

  <h2>スタックトレースの読み方</h2>
<pre class="topic-figure">java.lang.RuntimeException: 注文の登録に失敗しました
    at com.example.OrderService.order(OrderService.java:38)
    at com.example.OrderServlet.doPost(OrderServlet.java:25)
    ...
Caused by: java.sql.SQLIntegrityConstraintViolationException: 一意制約違反
    at com.example.OrderDao.insert(OrderDao.java:61)      ← 本当の発生場所
    ... 24 more</pre>
  <ul>
    <li><strong><code>Caused by</code> は下にいくほど原因に近い</strong>。一番下の <code>Caused by</code> から読む</li>
    <li>その中で<strong>自分のパッケージ名が出てくる最初の行</strong>が、実際に直す場所</li>
    <li><code>... 24 more</code> は「上と同じなので省略」の意味。気にしなくてよい</li>
  </ul>

  <h2>ログレベルは「誰が見るか」で決める</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 7rem;">レベル</th><th>意味</th><th>出すもの</th></tr></thead>
      <tbody>
        <tr><th scope="row">ERROR</th><td>人がすぐ対応する</td><td>システムの異常。放置できないもの</td></tr>
        <tr><th scope="row">WARN</th><td>すぐでなくても気になる</td><td>業務例外、リトライした、設定が既定値のまま</td></tr>
        <tr><th scope="row">INFO</th><td>あとで流れを追う</td><td>起動・停止、重要な業務操作（誰が何を更新した）</td></tr>
        <tr><th scope="row">DEBUG</th><td>開発中だけ</td><td>SQL、変数の中身。本番では基本オフ</td></tr>
      </tbody>
    </table>
  </div>
  <div class="topic-callout topic-callout--warn">
    <p class="topic-callout__title">全部 ERROR にすると ERROR が無意味になる</p>
    <p class="mb-0">
      「在庫不足」を ERROR で出していると、毎日数百件の ERROR が出ます。
      すると誰も見なくなり、本物の障害が埋もれます。
      <strong>ERROR は「人を呼ぶ」という意味だと決めておく</strong>と、レベル選びで迷いません。
    </p>
  </div>

  <h2>1 リクエストぶんをつなげる</h2>
  <p>
    本番のログは、何人ぶんもの行が入り混じって出ます。
    1 件の問い合わせを追うには、<strong>同じリクエストの行を拾い集められる印</strong>が要ります。
  </p>
  <p>
    やり方は単純です。入口のフィルタでリクエストごとに ID を採番し、全部のログ行に付けます。
  </p>
<pre class="topic-figure">2026-09-22 14:03:11 INFO  [a1b2c3] POST /orders 開始 user=1042
2026-09-22 14:03:11 DEBUG [a1b2c3] 在庫確認 itemId=55 stock=3
2026-09-22 14:03:12 ERROR [a1b2c3] 注文の登録に失敗 orderId=8891
                     ↑ この [a1b2c3] で grep すれば 1 件ぶんが揃う</pre>
  <p>
    ログ基盤があれば MDC（<code>ThreadLocal</code> の仕組み）を使うのが定番です。
    ただし<strong>フィルタの後処理で必ず消す</strong>こと。
    スレッドは使い回されるので、消し忘れると次の人のログに前の人の ID が付きます。
  </p>
  <p>
    フィルタで往復を捕まえる形は「応用・その他 &gt; フィルタで共通処理をはさむ」で、
    実際に 1 往復ぶん記録して表示しています。
  </p>

  <h2>ログに出してはいけないもの</h2>
  <ul>
    <li>パスワード、トークン、セッション ID、クレジットカード番号</li>
    <li>マイナンバー、口座番号などの、それ単体で価値のある番号</li>
    <li>個人情報を含むリクエストボディの丸ごとダンプ</li>
  </ul>
  <p>
    ログは調査のためにコピーされ、チャットに貼られ、長期保管されます。
    <strong>「ログに書いた時点で、社内に広く配ったのと同じ」</strong>と考えて選びます。
    追跡には「誰か」ではなく<strong>ユーザ ID のような識別子</strong>を出せば十分です。
  </p>

  <h2>利用者に見せる画面</h2>
  <p>
    スタックトレースが画面に出るのは、単に見苦しいだけでなく、
    <strong>クラス構成やライブラリのバージョンを外部に教える</strong>ことになります。
    利用者に見せるのは次の 3 つで足ります。
  </p>
  <ul>
    <li>何が起きたか（一言）</li>
    <li>どうすればよいか（やり直す・時間をおく・窓口に連絡する）</li>
    <li><strong>問い合わせ番号</strong>（= 先ほどのリクエスト ID）</li>
  </ul>
  <p>
    3 つめが効きます。利用者が番号を伝えてくれれば、ログを 1 回 grep するだけで該当箇所に着きます。
  </p>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li>空の catch は書かない。何もしないなら、せめてログに出す</li>
      <li>投げ直すときは原因の例外を必ず添える（第 2 引数）</li>
      <li>ログには例外オブジェクトをそのまま渡す。<code>getMessage()</code> だけにしない</li>
      <li>ERROR は「人を呼ぶ」。業務の都合は WARN</li>
      <li>リクエスト ID を全行に付ける。画面にも出す</li>
    </ul>
  </div>

</t:topic>
