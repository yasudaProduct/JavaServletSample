<%--
  【座学メモ】スレッドとプール（同時アクセスをさばく仕組み）
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="threads-and-pools">

  <h2>なぜサンプルにしにくいか</h2>
  <p>
    この話が表に出るのは、<strong>同時に何十人・何百人が使ったとき</strong>だけです。
    1 人でブラウザを触っている限り、何も起きません。
    そして本番で初めて出会うと、症状は「アプリ全体が返ってこない」という一番分かりにくい形で現れます。
  </p>

  <h2>リクエスト 1 本 = スレッド 1 本</h2>
  <p>
    Tomcat はリクエストが届くと、スレッドプールからスレッドを 1 本借り、
    フィルタ → Servlet → JSP を最後まで走らせ、返し終わったらプールへ戻します。
  </p>
<pre class="topic-figure">スレッドプール (既定 maxThreads = 200)
 ┌──────────────────────────────┐
 │ ●●●●●●●○○○○○○○○○○ … 200 本 │   ● = 処理中  ○ = 空き
 └──────────────────────────────┘
        ↑ 空きが無くなると、次のリクエストは「待ち行列」へ
        ↑ 待ち行列 (acceptCount) も溢れると、接続自体が拒否される</pre>
  <p>
    ここから、業務アプリで一番効く事実が出てきます。
  </p>
  <div class="topic-callout topic-callout--warn">
    <p class="topic-callout__title">遅い画面が 1 つあると、全部が遅くなる</p>
    <p class="mb-0">
      1 回 10 秒かかる画面があり、そこに毎秒 25 人が来るとします。
      10 秒 × 25 人 = 常時 250 本のスレッドが必要ですが、上限は 200 本です。
      あふれた瞬間から<strong>他の画面のリクエストもプールの空き待ちになり</strong>、
      軽いはずのトップページまで返らなくなります。
      「特定の画面が遅い」は、放っておくと「全部止まる」に変わります。
    </p>
  </div>

  <h2>スレッドはほとんど「待っている」</h2>
  <p>
    Web アプリのスレッドは、計算で忙しいのではなく、たいてい<strong>何かの返事を待って止まっています</strong>。
  </p>
  <ul>
    <li>DB に SQL を投げて、結果が返るのを待つ</li>
    <li>外部 API を呼んで、応答を待つ</li>
    <li>ファイルの読み書きを待つ</li>
  </ul>
  <p>
    待っている間、そのスレッドは何もしていないのに<strong>占有されたまま</strong>です。
    CPU 使用率が低いのにリクエストが返らない、という状態はこうして生まれます。
    「CPU が空いているから余裕があるはず」という読み方は、ここでは通用しません。
  </p>

  <h2>プールは 1 つではない</h2>
  <p>
    もう 1 つ、DB 接続にもプールがあります。<strong>この 2 つの数がかみ合っていないと詰まります。</strong>
  </p>
<pre class="topic-figure">Tomcat スレッド (200)        DB コネクション (10)
  ●●●●●●●●●● … 200 本  →  ●●●●●●●●●● 10 本
                              ↑ 残り 190 本はここで順番待ち</pre>
  <p>
    DB 接続は「毎回つなぐ」と遅いので、あらかじめ数本つないで使い回します。
    これがコネクションプールです。DataSource から借りて、使い終わったら返します。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 16rem;">起きること</th><th>見え方</th></tr></thead>
      <tbody>
        <tr><td>接続を返し忘れる（リーク）</td>
            <td>少しずつ減り、しばらく経つと「接続が取れない」で全滅する。
                再起動すると直るので原因が分かりにくい</td></tr>
        <tr><td>プールが小さすぎる</td>
            <td>DB は暇なのにアプリだけ遅い</td></tr>
        <tr><td>プールが大きすぎる</td>
            <td>DB 側が悲鳴をあげる。アプリが複数台なら合計値で考える必要がある</td></tr>
      </tbody>
    </table>
  </div>
  <p>
    リークを防ぐ書き方は 1 つだけ覚えれば足ります。
    <strong><code>try-with-resources</code> で借りて、そのブロックの中で使い切る</strong>ことです。
  </p>
<pre><code class="language-java">try (Connection con = dataSource.getConnection();
     PreparedStatement ps = con.prepareStatement(sql)) {
    // ここで使い切る。Connection を戻り値で返したり、フィールドに持ったりしない
} // ここで必ず返却される（例外が飛んでも返る）</code></pre>

  <h2>「遅い」と「詰まる」は別の症状</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 10rem;"></th><th>遅い</th><th>詰まる</th></tr></thead>
      <tbody>
        <tr><th scope="row">見え方</th><td>いつも同じくらい待たされる</td><td>ある時刻から急に、全部返らない</td></tr>
        <tr><th scope="row">人数との関係</th><td>1 人でも遅い</td><td>人が増えたときだけ起きる</td></tr>
        <tr><th scope="row">原因</th><td>処理そのもの（SQL・件数・往復回数）</td><td>資源の上限（スレッド・接続・メモリ）</td></tr>
        <tr><th scope="row">直し方</th><td>処理を速くする → <a href="${ctx}/topics/performance-basics">「遅い」と言われたときに見るところ</a></td>
            <td>上限を揃える、待ち時間に上限を付ける、遅い処理を切り離す</td></tr>
      </tbody>
    </table>
  </div>

  <h2>止まったときに見るもの：スレッドダンプ</h2>
  <p>
    「全部返ってこない」ときにログを見ても、たいてい何も出ていません。
    <strong>例外が起きていないから</strong>です。止まっているだけです。
    そこで、その瞬間に全スレッドが何をしているかを撮ります。
  </p>
<pre class="topic-figure">jcmd &lt;pid&gt; Thread.print        (または jstack &lt;pid&gt;)
  ↓
"http-nio-8080-exec-1" ... RUNNABLE
   at java.net.SocketInputStream.socketRead0 ...
   at com.example...OrderDao.findAll(OrderDao.java:42)   ← ここで DB 待ち
"http-nio-8080-exec-2" ... 同じ場所
"http-nio-8080-exec-3" ... 同じ場所
   … 200 本が同じ行で止まっていたら、そこが犯人</pre>
  <p>
    読み方はほぼ 1 つで足ります。<strong>同じ行に固まっているスレッドを探す</strong>。
    数秒あけて 2 〜 3 回撮り、同じ場所に居続けるものが止まっている処理です。
  </p>

  <h2>打ち手</h2>
  <ol>
    <li><strong>待ち時間に上限を付ける</strong>。
        外部 API 呼び出しや SQL にタイムアウトを設定する。
        タイムアウトの無い呼び出しは、相手が黙ると<strong>こちらが道連れになります</strong></li>
    <li><strong>数を揃える</strong>。スレッド数・DB 接続数・外部接続数の関係を意識する。
        アプリが複数台なら DB 接続は台数分の合計で考える</li>
    <li><strong>長い処理を同じスレッドでやらない</strong>。
        帳票作成や一括取込のような処理は、リクエストのスレッドを占有させず、
        受け付けだけ返して裏で進める（「応用・その他 &gt; 非同期処理」「非同期通信 &gt; 進捗をポーリング」）</li>
    <li><strong>状態をスレッドに残さない</strong>。
        スレッドは使い回されるので、<code>ThreadLocal</code> に入れたまま消さないと、
        <strong>次の人のリクエストに前の人の値が見えます</strong>。フィルタの後処理で必ず消す</li>
  </ol>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li>スレッドは有限。遅い処理は、その本数を長く占有するという意味で「他人に迷惑」</li>
      <li>CPU が空いていても詰まる。待ちで占有されているから</li>
      <li>タイムアウトの無い外部呼び出しは、いつか必ず全体を止める</li>
      <li>返ってこないときのログは無言。スレッドダンプを撮る</li>
    </ul>
  </div>

</t:topic>
