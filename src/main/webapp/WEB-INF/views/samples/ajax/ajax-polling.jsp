<%--
  【サンプル】処理の進捗をポーリングで取得する

  「集計を開始」を押すと POST でサーバに開始を伝え、そのあとは 1 秒おきに GET で
  進捗を問い合わせて、進捗バーとメッセージを書き換えます。

    ・AjaxPollingServlet     … この画面を表示する (開き直したときの状態も渡す)
    ・AjaxPollingApiServlet  … /samples/ajax/ajax-polling/api (GET で進捗、POST で開始・中止)

  サーバ側ではスレッドもタイマーも作っていません。セッションに開始時刻だけを置き、
  問い合わせが来るたびに「いま - 開始時刻」から進捗を計算しています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="ajax-polling">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>ポーリングとは</h2>
    <p>
      時間のかかる処理を始めたあと、終わったかどうかを<strong>こちらから定期的に聞きに行く</strong>やり方を
      ポーリング（polling）と呼びます。サーバから教えてもらうのではなく、
      「もう終わった？」「まだ？」とブラウザが繰り返し尋ねる形です。
    </p>
    <p>
      仕組みは単純で、必要なのは <code>setInterval</code> と、進捗を返す API が 1 本だけです。
      HTTP の普通のリクエストしか使わないので、特別な設定も追加のライブラリも要りません。
      そのかわり、<strong>聞きに行った回数だけリクエストが発生します</strong>。
      この「回数」をどう抑えるかが、ポーリングを使うときに考えることのほとんどです。
    </p>

    <h3>このデモがやっていること</h3>
    <ol>
      <li>「集計を開始」を押すと、<code>POST .../api</code> に <code>action=start</code> を送る</li>
      <li>サーバはセッションに<strong>開始時刻だけ</strong>を入れる（スレッドもタイマーも作りません）</li>
      <li>画面は <code>setInterval</code> で 1 秒おきに <code>GET .../api</code> を呼ぶ</li>
      <li>
        サーバは「いまの時刻 − 開始時刻」を ${totalSeconds} 秒で割って進捗を計算し、
        JSON で返す
      </li>
      <li>画面は受け取った値で進捗バー・パーセント・経過秒数・メッセージを書き換える</li>
      <li>
        <code>running</code> が <code>false</code> になったら <code>clearInterval</code> で問い合わせを止め、
        <code>done</code> が <code>true</code> なら結果（件数）を表示する
      </li>
    </ol>
    <p>
      擬似処理なので「進捗」は時間の割り算ですが、画面側のコードは本物のジョブでもそのまま通用します。
      サーバ側が返す JSON の形（<code>percent</code> と <code>done</code>）が同じなら、
      中身が時間の計算でも、バッチの進捗テーブルの読み出しでも、画面は区別しません。
    </p>

    <h2>いちばん短い形</h2>
<pre><code class="language-javascript">var timerId = setInterval(async function () {
  const res = await fetch(apiUrl);
  const data = await res.json();

  bar.style.width = data.percent + '%';

  if (data.done) {
    clearInterval(timerId);     // ← 終了条件。これが無いと永久に呼び続けます
    showResult(data);
  }
}, 1000);</code></pre>
    <p>
      短く書けてしまうのがポーリングの良いところであり、危ないところでもあります。
      この短いコードには、あとで説明する落とし穴が 3 つ残っています
      （最初の 1 回まで 1 秒待つ・応答を待たずに次を投げる・失敗したときに止まらない）。
    </p>

    <h2>①　間隔をどう決めるか</h2>
    <p>
      間隔は「速く見せたい」と「サーバに優しくしたい」のつり合いで決めます。
      <strong>短すぎるとサーバが辛く、長すぎると画面が固まっているように見えます。</strong>
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr>
            <th>間隔</th>
            <th>体感</th>
            <th>1 人が 1 分見たときの回数</th>
            <th>100 人が同時に見ていると</th>
            <th>向いている場面</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>0.2 秒</td>
            <td>なめらか</td>
            <td>300 回</td>
            <td><strong>500 リクエスト/秒</strong></td>
            <td>ほぼ無い（この速さが要るなら別の方式を選びます）</td>
          </tr>
          <tr>
            <td>1 秒</td>
            <td>じゅうぶん速い</td>
            <td>60 回</td>
            <td>100 リクエスト/秒</td>
            <td>数秒〜1 分で終わる処理（このデモ）</td>
          </tr>
          <tr>
            <td>5 秒</td>
            <td>少し待つ感じ</td>
            <td>12 回</td>
            <td>20 リクエスト/秒</td>
            <td>数分かかる帳票・取り込み処理</td>
          </tr>
          <tr>
            <td>30 秒</td>
            <td>止まって見える</td>
            <td>2 回</td>
            <td>3.3 リクエスト/秒</td>
            <td>夜間バッチの状況確認画面など</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      「100 人が同時に」の列がポイントです。1 人で試している間は 1 秒おきでも何ともありませんが、
      同時に見ている人数がそのまま掛け算になります。
      デモの「問い合わせの間隔」を変えると、回数の増え方を画面で確かめられます。
    </p>
    <ul>
      <li>
        <strong>処理時間の 1/10 くらいを目安にする</strong>：
        10 秒で終わる処理なら 1 秒、5 分かかる処理なら 10〜30 秒。
        進捗バーが 10 回ほど動けば、人は「進んでいる」と感じます
      </li>
      <li>
        <strong>だんだん間隔を広げる</strong>（バックオフ）：
        最初の数回は 1 秒、そのあと 3 秒、10 秒…と伸ばすと、
        「すぐ終わる処理は速く、長引く処理は軽く」の両立ができます
      </li>
      <li>
        <strong>API 側を軽くする</strong>：
        1 秒おきに呼ばれる API で重い集計をしてはいけません。
        進捗は 1 行の読み出しで返せる形（ジョブのテーブルに <code>percent</code> 列を持つなど）にしておきます
      </li>
    </ul>

    <h2>②　終了条件を必ず作る</h2>
    <p>
      ポーリングの不具合で多いのは、<strong><code>clearInterval</code> の消し忘れ</strong>です。
      タイマーは誰も止めなければ動き続けます。
      画面を開きっぱなしのまま昼休みに入れば、1 秒おきのリクエストが数千回積み上がります。
      しかも画面上は何も起きていないので、気づくのはたいてい<strong>サーバのアクセスログを見たとき</strong>です。
    </p>
    <p>止める条件は、少なくとも次の 4 つを用意します。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>止める条件</th><th>書く場所</th><th>書かないとどうなるか</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>完了した（<code>done === true</code>）</td>
            <td>応答を受け取った直後</td>
            <td>終わったのに聞き続ける</td>
          </tr>
          <tr>
            <td>利用者が中止した</td>
            <td>中止ボタン</td>
            <td>止めたつもりなのに通信が続く</td>
          </tr>
          <tr>
            <td>続けて失敗した（既定では 3 回）</td>
            <td><code>catch</code> の中</td>
            <td>サーバが落ちている間、延々と再試行して追い打ちをかける</td>
          </tr>
          <tr>
            <td>上限回数を超えた</td>
            <td>回数を数えて判定</td>
            <td>サーバ側が壊れて <code>done</code> を返せないとき、永久に止まらない</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      とくに最後の 2 つは忘れられがちです。
      <strong>「サーバが正しく <code>done</code> を返す」前提で書かない</strong>のが要点で、
      相手が黙り込んでも自分から止まれる作りにしておきます。
    </p>
<pre><code class="language-javascript">if (!data.running) {                 // 完了 or もう存在しない
  stopPolling();
}
if (clientPollCount &gt;= MAX_POLLS) {  // 保険。想定より長引いたら諦める
  stopPolling();
  showError('時間がかかりすぎています。画面を開き直してください。');
}</code></pre>

    <h3><code>setInterval</code> は応答を待ってくれない</h3>
    <p>
      <code>setInterval(poll, 1000)</code> は「1 秒ごとに <code>poll</code> を呼ぶ」だけで、
      前回の <code>fetch</code> が返ってきたかどうかは見ていません。
      サーバの応答が 3 秒かかるようになると、返事を待っている間にも次々と新しい問い合わせが飛び、
      <strong>遅いときほどリクエストが増える</strong>という、いちばんまずい形になります。
    </p>
<pre><code class="language-javascript">// 前回の応答がまだなら、この回は飛ばす
if (inFlight) {
  return;
}
inFlight = true;
try {
  ...
} finally {
  inFlight = false;          // 成功でも失敗でも必ず戻す
}</code></pre>
    <p>
      もう一つの書き方として、<code>setInterval</code> をやめて
      <strong>応答が返ってきてから次を予約する</strong>（<code>setTimeout</code> のつなぎ）方法があります。
      間隔が「応答が返ってから 1 秒後」になるので、リクエストが重なりません。
      バックオフで間隔を変えたいときも、こちらのほうが書きやすくなります。
    </p>
<pre><code class="language-javascript">async function poll() {
  const data = await load();
  render(data);
  if (!data.done) {
    timerId = setTimeout(poll, nextInterval());   // 終わってから次を予約する
  }
}</code></pre>
    <p>
      このサンプルは <code>setInterval</code> のほうで書いています
      （そのぶん <code>inFlight</code> の見張りが要ります）。
      止めるときは <code>clearInterval</code>、<code>setTimeout</code> なら
      <code>clearTimeout</code> と、<strong>対になる関数が違う</strong>点に注意してください。
    </p>

    <h2>③　画面を離れたら止める</h2>
    <p>
      タブを裏に回した、別の画面に移った、ノートを閉じた ――
      そのどれもで、進捗を見ている人はもういません。それでもタイマーは動き続けます。
      次の 2 つを書いておくと、無駄な問い合わせをかなり減らせます。
    </p>
<pre><code class="language-javascript">// タブが裏に回ったら止め、戻ってきたら再開する
document.addEventListener('visibilitychange', function () {
  if (document.hidden) {
    stopPolling();
  } else if (needsPolling) {
    startPolling();
    poll();            // 戻った瞬間に 1 回だけ、すぐ最新を取りに行く
  }
});

// 画面を離れるときに後片付けする
window.addEventListener('beforeunload', function () {
  stopPolling();
});</code></pre>
    <ul>
      <li>
        <strong><code>visibilitychange</code> が主役</strong>：
        別のタブを見ている間の問い合わせは、まるごと無駄です。
        戻ってきたときに 1 回すぐ叩けば、見た目には止めていたことが分かりません
      </li>
      <li>
        <strong>止めている間もサーバ側の処理は進んでいます</strong>：
        止めるのは「聞きに行くこと」だけです。進捗を持っているのはサーバなので、
        戻ってきたときには先に進んだ状態が返ってきます
      </li>
      <li>
        <strong><code>beforeunload</code> は保険</strong>：
        ページが閉じられればタイマーも消えるので、
        画面遷移だけを考えるなら無くても動きます。
        画面を切り替えても JavaScript が生き続ける作り（SPA、モーダルの開閉）では、
        後片付けを書いていないとタイマーが残り続けます
      </li>
      <li>
        <strong>モバイルではブラウザが勝手に止めます</strong>：
        裏に回ったタブのタイマーは間隔が延ばされたり、止められたりします。
        「1 秒おきに必ず動く」とは考えず、<strong>時刻はサーバから受け取った値を使います</strong>
      </li>
    </ul>

    <h2>④　進捗はサーバが持つ</h2>
    <p>
      進捗をブラウザの変数だけで持つと、<strong>画面を再読み込みした瞬間に消えます</strong>。
      「処理は続いているのに、画面には何も実行していないと表示される」状態です。
      このサンプルは開始時刻をセッションに入れているので、
      集計の途中で画面を開き直しても、続きから進捗を見られます
      （デモの一番下のリンクで試せます）。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>置き場所</th><th>再読み込み</th><th>別のタブ・別の端末</th><th>サーバ再起動</th><th>向いている場面</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>JavaScript の変数だけ</td>
            <td>消える</td><td>見えない</td><td>―</td>
            <td>数秒で終わる、消えても困らない処理</td>
          </tr>
          <tr>
            <td>セッション（このサンプル）</td>
            <td><strong>残る</strong></td><td>同じブラウザなら見える</td><td>消える</td>
            <td>その人がその場で待つ処理</td>
          </tr>
          <tr>
            <td>データベースのジョブ表</td>
            <td>残る</td><td><strong>見える</strong></td><td><strong>残る</strong></td>
            <td>あとで結果を確認する、担当者が代わる、監視したい処理</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      セッションに置くときの注意も書いておきます。
    </p>
    <ul>
      <li>
        <strong>入れるオブジェクトは <code>Serializable</code> にする</strong>：
        コンテナはセッションをファイルへ書き出したり、複数台のサーバ間で複製したりします
      </li>
      <li>
        <strong>キーの名前を長めにする</strong>：
        セッションはアプリ全体で 1 つの入れ物です。<code>"job"</code> のような名前は
        別の画面とぶつかります（このサンプルは <code>"ajaxPolling.job"</code> にしています）
      </li>
      <li>
        <strong>大きなデータを入れない</strong>：
        進捗のために結果の一覧まで入れると、人数分そのままメモリに載ります。
        セッションに置くのは「どこまで進んだか」だけにして、結果は取りに行かせます
      </li>
      <li>
        <strong>タイムアウトで消える</strong>：
        30 分放置すればセッションごと消えます。
        「昨日流した処理の結果を見たい」が要件に入った時点で、置き場所はデータベースです
      </li>
    </ul>

    <h2>⑤　本当に重い処理をするときは</h2>
    <p>
      このサンプルは時間の割り算で進捗を作っているので、サーバ側には何も走っていません。
      実際に重い処理をやらせたくなったとき、<strong>Servlet の中で
      <code>new Thread(...)</code> を起こすのは避けてください。</strong>
    </p>
    <ul>
      <li>
        <strong>アプリを入れ替えるときに後始末ができません</strong>：
        再配備（デプロイ）でクラスローダが入れ替わっても、自前で起こしたスレッドは走り続けます。
        メモリリークとして現れ、やがてサーバごと再起動する羽目になります
      </li>
      <li>
        <strong>サーバを 2 台に増やせません</strong>：
        進捗は 1 台目のメモリにあるのに、次の問い合わせが 2 台目に振られると
        「そんな処理は知らない」という応答になります
      </li>
      <li>
        <strong>同時に何本走るか誰も決めていません</strong>：
        利用者がボタンを 10 回押せば 10 本走ります。
        重い処理ほど、同時実行数を絞る仕組みが要ります
      </li>
    </ul>
    <p>
      素直な形は「<strong>処理をジョブとして登録し、実行は別の仕組みに任せる</strong>」です。
    </p>
<pre><code class="language-plaintext">［画面］  POST /jobs            → ジョブを 1 行 INSERT (status=WAITING) して、ジョブ ID を返す
［実行］  バッチ / ジョブキュー  → WAITING の行を拾って実行し、percent と status を更新する
［画面］  GET  /jobs/{id}       → その行を 1 件読んで返すだけ (1 秒おきに呼ばれても軽い)</code></pre>
    <ul>
      <li>ジョブ表には「状態・進捗・開始時刻・終了時刻・エラー内容」を持たせます</li>
      <li>
        どのサーバが処理しても、進捗はデータベースにあるので画面から見えます。
        サーバが落ちても、再起動後に途中のジョブを拾い直せます
      </li>
      <li>
        Java EE / Jakarta EE のアプリサーバなら
        <code>ManagedExecutorService</code>（コンテナが管理するスレッドプール）を使う手もあります。
        自前のスレッドと違い、停止時にコンテナが面倒を見てくれます
      </li>
      <li>
        <strong>画面側のコードは変わりません。</strong>
        返す JSON の形さえ同じなら、進捗の作り方が変わっても
        <code>setInterval</code> の部分はこのサンプルのままです
      </li>
    </ul>

    <h2>⑥　WebSocket / Server-Sent Events との比較</h2>
    <p>
      「サーバ側の変化を画面に反映したい」ときの選択肢は 3 つあります。
      ポーリングは<strong>こちらから聞きに行く</strong>、あとの 2 つは<strong>向こうから送られてくる</strong>方式です。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr>
            <th>&nbsp;</th>
            <th>ポーリング</th>
            <th>Server-Sent Events (SSE)</th>
            <th>WebSocket</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>向き</td>
            <td>ブラウザ → サーバ（毎回）</td>
            <td>サーバ → ブラウザ（片方向）</td>
            <td>双方向</td>
          </tr>
          <tr>
            <td>使うもの</td>
            <td>普通の HTTP</td>
            <td>HTTP の接続を開いたまま</td>
            <td>HTTP から専用の接続に切り替え</td>
          </tr>
          <tr>
            <td>サーバ側の実装</td>
            <td><strong>普通の Servlet 1 本</strong></td>
            <td>非同期 Servlet（<code>AsyncContext</code>）</td>
            <td><code>@ServerEndpoint</code>（JSR-356）</td>
          </tr>
          <tr>
            <td>接続の数</td>
            <td>リクエストのたびに終わる</td>
            <td>見ている人数ぶん開きっぱなし</td>
            <td>見ている人数ぶん開きっぱなし</td>
          </tr>
          <tr>
            <td>遅れ</td>
            <td>最大で間隔ぶん（1 秒なら 1 秒）</td>
            <td>ほぼ無し</td>
            <td>ほぼ無し</td>
          </tr>
          <tr>
            <td>途中の切断</td>
            <td>次の問い合わせで勝手に直る</td>
            <td>ブラウザが自動で再接続する</td>
            <td><strong>自分で再接続を書く</strong></td>
          </tr>
          <tr>
            <td>プロキシ・古い環境</td>
            <td>まず通る</td>
            <td>切られることがある</td>
            <td>塞がれていることがある</td>
          </tr>
          <tr>
            <td>向いている用途</td>
            <td>進捗、状態の確認、数十秒で終わる処理</td>
            <td>通知、ログの流し込み、株価の表示</td>
            <td>チャット、共同編集、ゲーム</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>選ぶときの目安は、おおよそ次のとおりです。</p>
    <ul>
      <li>
        <strong>迷ったらポーリング</strong>：
        進捗の表示くらいなら 1〜5 秒の遅れは問題になりません。
        普通の Servlet で書けて、つながらなくなっても次の回で勝手に直るのは大きな利点です
      </li>
      <li>
        <strong>秒以下の即時性が要る、または更新が頻繁なら SSE</strong>：
        「サーバから送りっぱなし」で足りるなら、双方向の WebSocket より簡単です
      </li>
      <li>
        <strong>ブラウザからも頻繁に送るなら WebSocket</strong>：
        チャットや共同編集のように、両方向のやり取りが本質の場合です
      </li>
      <li>
        <strong>人数で考える</strong>：
        SSE と WebSocket は<strong>見ている人数ぶんの接続が開いたまま</strong>になります。
        1000 人が同時に見る画面では、接続を持ち続けるコストのほうが問題になることもあります。
        一方ポーリングは、間隔を 10 秒に延ばすだけで負荷を 1/10 にできます
      </li>
    </ul>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>進捗が途中で止まったまま動かない</strong>：
        GET の応答がキャッシュされている可能性があります。
        サーバ側で <code>response.setHeader("Cache-Control", "no-store")</code> を付けます。
        毎回変わる値を返す API では必須です
      </li>
      <li>
        <strong>ボタンを 2 回押すと集計が 2 つ始まる</strong>：
        画面側で <code>disabled</code> にするのは「押しにくくする」だけです。
        URL を直接叩けば何度でも開始できるので、
        <strong>断るのはサーバの仕事</strong>です（このサンプルは 409 を返します）。
        デモの「わざと二重に開始する」ボタンで、その応答を見られます
      </li>
      <li>
        <strong>完了後に件数が毎回変わる</strong>：
        結果を問い合わせのたびに計算していると起きます
        （<code>Math.random()</code> で作っている、集計をやり直している、など）。
        結果は終わった時点で 1 回だけ確定させ、以後は同じ値を返します
      </li>
      <li>
        <strong>中止したのに、開き直すとまだ動いている</strong>：
        画面のタイマーを止めただけで、サーバ側の状態を消していないときに起きます。
        中止も<strong>サーバに伝える</strong>必要があります
      </li>
      <li>
        <strong>未完了なのに「0 件で完了」と出る</strong>：
        実行中の応答に <code>resultCount: 0</code> を入れていると、
        画面がそれを表示してしまいます。未確定の値は <code>null</code> にして、
        <code>done</code> のときだけ表示します
      </li>
      <li>
        <strong>タイマーが二重に仕掛かる</strong>：
        <code>startPolling()</code> を呼ぶ前に <code>timerId</code> を確かめないと、
        押した回数だけタイマーが増えます。1 秒おきのつもりが 0.3 秒おきになり、
        <code>clearInterval</code> しても最後の 1 本しか止まりません
      </li>
      <li>
        <strong>進捗バーの幅はインラインの <code>style</code> で指定する</strong>：
        Bootstrap の <code>.progress-bar</code> に任意の幅を与えるクラスはないので、
        ここだけは <code>style="width: 37%"</code> の形になります。
        あわせて <code>aria-valuenow</code> も更新してください。
        幅だけ変えると、見た目は進んでいるのに読み上げソフトには 0% のままと伝わります
      </li>
      <li>
        <strong>進捗が 99% で止まる</strong>：
        整数の割り算による切り捨てです。
        「<code>percent</code> が 100 になったら完了」ではなく、
        <strong>完了したかどうかをサーバが <code>done</code> で明示する</strong>ほうが安全です
      </li>
    </ul>

    <h2>この API が返す JSON</h2>
<pre><code class="language-plaintext">{
  "ok": true,               // 要求を受け付けられたか (二重開始を断ったときだけ false)
  "problem": null,          // 断った理由。無ければ null
  "state": "running",       // idle / running / done
  "running": true,          // まだ動いているか (これが false になったら問い合わせを止める)
  "done": false,            // 完了したか (結果を出してよいか)
  "percent": 37,
  "elapsedSeconds": 3,
  "totalSeconds": 8,
  "message": "明細データを読み込んでいます...",
  "startedAt": "12:34:56",
  "resultCount": null,      // 完了するまでは null
  "serverPollCount": 4      // このセッションから問い合わせが来た回数
}</code></pre>
    <p>
      状態によって項目が増えたり消えたりしない形にしておくと、受け取る側が素直に書けます。
      <code>running</code> と <code>done</code> を分けているのは、画面が知りたいことが
      「問い合わせを続けるか」と「結果を出してよいか」の 2 つだからです。
      中止された直後は <code>state: "idle"</code>（両方 <code>false</code>）になります。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {

        // ------------------------------------------------------------------
        // 設定と状態
        // ------------------------------------------------------------------

        // API の URL。必ずコンテキストパスから組み立てます
        // ('/samples/...' と直接書くと、アプリを /app の下に置いたときに 404 になります)
        var apiUrl = '${ctx}${apiPath}';

        // ポーリングの間隔 (ミリ秒)。画面のセレクトで変えられるようにしています
        var intervalMillis = ${defaultIntervalMillis};

        // setInterval が返す ID。null なら「いまタイマーは動いていない」
        var timerId = null;

        // 前回の問い合わせがまだ返ってきていないか。
        // setInterval は応答を待たずに次を呼ぶので、これが無いとリクエストが重なります
        var inFlight = false;

        // タブが裏に回ったせいで止めたのかどうか (表に戻ったときに再開するため)
        var resumeWhenVisible = false;

        var clientPollCount = 0;   // 画面が数えた問い合わせ回数
        var failureCount = 0;      // 続けて失敗した回数
        var currentState = '${resumeState}';   // idle / running / done

        // 止まれなくなったときの保険。
        // サーバが done を返せなくなっても、ここで必ず終わります
        var MAX_FAILURES = 3;
        var MAX_POLLS = 120;

        var $startButton = $('#startButton');
        var $cancelButton = $('#cancelButton');
        var $forceStartButton = $('#forceStartButton');
        var $bar = $('#pollingBar');

        // ------------------------------------------------------------------
        // タイマーの開始と停止
        // ------------------------------------------------------------------

        function startPolling() {
          // すでに動いているなら何もしない。
          // この判定を忘れると、押した回数だけタイマーが増えていきます
          // (1 秒おきのつもりが 0.3 秒おきになり、clearInterval しても 1 本しか止まりません)
          if (timerId !== null) {
            return;
          }
          timerId = setInterval(poll, intervalMillis);
          showTimerState('問い合わせ中（' + intervalMillis + ' ミリ秒ごと）');
        }

        function stopPolling(reason) {
          if (timerId !== null) {
            // ここを忘れると、画面を見ていない間もリクエストが飛び続けます。
            // 画面上は何も起きないので、気づくのはサーバのログを見たときです
            clearInterval(timerId);
            timerId = null;
          }
          showTimerState('停止中' + (reason ? '（' + reason + '）' : ''));
        }

        function showTimerState(text) {
          $('#timerState').text(text);
        }

        // ------------------------------------------------------------------
        // 進捗の問い合わせ (GET)
        // ------------------------------------------------------------------

        async function poll() {

          // 前回の応答がまだ返ってきていないときは、この回を飛ばします。
          // サーバが遅くなったときに問い合わせが積み重なるのを防ぐためで、
          // 「遅いときほどリクエストが増える」といういちばんまずい形を避けられます
          if (inFlight) {
            addLog('GET', '-', '前回の応答待ちのため見送り', '-');
            return;
          }
          inFlight = true;

          clientPollCount++;
          $('#clientPollCount').text(clientPollCount + ' 回');

          var startedAt = Date.now();

          try {
            var res = await fetch(apiUrl, {headers: {'Accept': 'application/json'}});

            // fetch は 404 でも 500 でも「成功」として返ってきます。
            // res.ok (200〜299 なら true) を自分で見ないとエラーに気づけません
            if (!res.ok) {
              throw new Error('HTTP ' + res.status);
            }

            var data = await res.json();
            failureCount = 0;

            render(data);
            addLog('GET', res.status, data.percent + ' %', Date.now() - startedAt);

            // 終了条件 ①：サーバが「もう動いていない」と言ったら止める。
            // 完了 (done) だけでなく、中止されて状態が消えた場合もここに来ます
            if (!data.running) {
              stopPolling(data.done ? '100% になりました' : '集計が見つかりません');
              resumeWhenVisible = false;
            }

            // 終了条件 ②：回数の上限。サーバが done を返せなくなっても、ここで必ず止まります
            if (timerId !== null && clientPollCount >= MAX_POLLS) {
              stopPolling('問い合わせが ' + MAX_POLLS + ' 回に達しました');
              resumeWhenVisible = false;
              showError('時間がかかりすぎています。画面を開き直してください。');
            }

          } catch (e) {
            // ここに来るのは「つながらなかった」ときと「JSON として読めなかった」とき
            console.error(e);
            failureCount++;
            addLog('GET', '-', '失敗（' + failureCount + ' 回目）', Date.now() - startedAt);

            // 終了条件 ③：続けて失敗したら諦める。
            // 止めずに再試行を続けると、落ちているサーバに追い打ちをかけることになります
            if (failureCount >= MAX_FAILURES) {
              stopPolling('通信に ' + MAX_FAILURES + ' 回続けて失敗しました');
              resumeWhenVisible = false;
              showError('サーバと通信できません。時間をおいて開始し直してください。');
            }

          } finally {
            // 成功でも失敗でも必ず通ります。
            // ここで戻し忘れると、一度失敗しただけで二度と問い合わせなくなります
            inFlight = false;
          }
        }

        // ------------------------------------------------------------------
        // 開始・中止 (POST)
        // ------------------------------------------------------------------

        /**
         * 開始・中止をサーバへ送る。
         * 状態を変える操作なので POST です
         * (GET はブラウザや中継サーバに勝手に再実行されることがあります)。
         */
        async function sendAction(action) {
          var startedAt = Date.now();
          try {
            var res = await fetch(apiUrl, {
              method: 'POST',
              // この Content-Type だからこそ、サーバ側は普通のフォームと同じ
              // request.getParameter("action") で受け取れます。
              // JSON を本文に入れて送ると getParameter では取れません
              headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
              body: 'action=' + encodeURIComponent(action)
            });

            // 409 (二重開始) のときも本文は JSON なので、まず読みます
            var data = await res.json();
            addLog('POST ' + action, res.status, data.percent + ' %', Date.now() - startedAt);
            return {status: res.status, data: data};

          } catch (e) {
            console.error(e);
            addLog('POST ' + action, '-', '失敗', Date.now() - startedAt);
            return null;
          }
        }

        async function requestStart() {
          hideAlerts();

          // 応答が返るまで押せないようにします。
          // 連打すると POST が 2 回飛び、2 回目はサーバに 409 で断られます
          // (断れるのは、サーバ側でも二重開始を見ているからです)
          $startButton.prop('disabled', true);

          var result = await sendAction('start');
          if (result === null) {
            showError('通信できませんでした。ネットワークかサーバの状態を確認してください。');
            // 押せないままにしない。失敗したらもう一度押せる状態に戻します
            setButtons(currentState);
            return;
          }

          render(result.data);

          if (result.data.ok) {
            // 新しく始まった。数え直してから問い合わせを開始します
            clientPollCount = 0;
            failureCount = 0;
            $('#clientPollCount').text('0 回');
            startPolling();
            resumeWhenVisible = true;

            // setInterval は「最初の 1 回」も間隔ぶん待ちます。
            // 押した直後に画面が動かないと不安なので、ここで 1 回すぐ叩いています
            poll();
          } else {
            // サーバが断った (すでに実行中)。理由を画面に出し、進捗は見せ続けます
            showConflict(result.data.problem);
            startPolling();
            resumeWhenVisible = true;
          }
        }

        async function requestCancel() {
          hideAlerts();

          // 先に画面のタイマーを止めます。
          // ただしこれだけでは「画面が聞くのをやめた」だけで、サーバ側の状態は残ります。
          // 消さずに開き直すと、中止したはずの集計がまだ進んでいるように見えます
          stopPolling('中止しました');
          resumeWhenVisible = false;
          $cancelButton.prop('disabled', true);

          var result = await sendAction('cancel');
          if (result === null) {
            showError('中止をサーバに伝えられませんでした。画面を開き直して確認してください。');
            setButtons(currentState);   // もう一度中止を押せるように戻す
            return;
          }
          render(result.data);
        }

        // ------------------------------------------------------------------
        // 受け取った JSON を画面へ反映する
        // ------------------------------------------------------------------

        function render(data) {
          currentState = data.state;

          var percent = data.percent;

          // 進捗バーは幅と aria-valuenow の両方を更新します。
          // 幅だけ変えると、読み上げソフトには進捗が伝わりません
          $bar.css('width', percent + '%')
              .attr('aria-valuenow', percent)
              .text(percent + ' %');

          $bar.removeClass('bg-success progress-bar-animated');
          if (data.done) {
            $bar.addClass('bg-success');
          } else if (data.running) {
            // 動いていることが伝わるよう、実行中だけ縞を流します
            $bar.addClass('progress-bar-animated');
          }

          // 値は .text() (= textContent) で入れます。
          // .html() (= innerHTML) に入れると、文字列に混ざったタグがそのまま動きます
          $('#pollingPercent').text(percent + ' %');
          $('#pollingElapsed').text(data.elapsedSeconds + ' 秒');
          $('#pollingTotal').text(data.totalSeconds + ' 秒');
          $('#pollingMessage').text(data.message);
          $('#pollingStartedAt').text(data.startedAt === null ? '-' : data.startedAt);
          $('#serverPollCount').text(data.serverPollCount + ' 回');

          $('#pollingState')
            .removeClass('badge-secondary badge-primary badge-success')
            .addClass(stateBadgeClass(data.state))
            .text(stateLabel(data.state));

          // 結果は done のときだけ出します。
          // 未完了のときに resultCount (null) を出すと「0 件で完了」に見えてしまいます
          if (data.done) {
            $('#resultCount').text(data.resultCount);
            // 「処理にかかった時間」は totalSeconds で頭打ちにします。
            // elapsedSeconds は「開始してから今までの実時間」なので、
            // 完了から時間が経ってから画面を開き直すと 60 秒などに育ちます。
            // そのまま出すと「8 秒で終わる集計に 60 秒かかった」と読めてしまいます
            $('#resultElapsed').text(Math.min(data.elapsedSeconds, data.totalSeconds));
            $('#resultArea').removeClass('d-none');
          } else {
            $('#resultArea').addClass('d-none');
          }

          // 実行中でなくなったら「すでに実行中です」の警告は用済みです。
          // 消さないと、完了した画面に断りの文言が残ります
          if (!data.running) {
            $('#conflictAlert').addClass('d-none');
          }

          // 受け取った生の JSON。何が返っているかを確かめられるように出しています
          $('#lastJson').text(JSON.stringify(data, null, 2));

          setButtons(data.state);
        }

        function stateLabel(state) {
          if (state === 'running') {
            return '実行中';
          }
          if (state === 'done') {
            return '完了';
          }
          return '未実行';
        }

        function stateBadgeClass(state) {
          if (state === 'running') {
            return 'badge-primary';
          }
          if (state === 'done') {
            return 'badge-success';
          }
          return 'badge-secondary';
        }

        // ボタンの出し分け。実行中は開始を押せなくします
        // (ただし「押させない」だけで、二重開始を止めているのはサーバ側です)
        function setButtons(state) {
          var running = (state === 'running');
          $startButton.prop('disabled', running);
          $cancelButton.prop('disabled', !running);
          $forceStartButton.prop('disabled', !running);
        }

        function showError(message) {
          $('#pollingErrorMessage').text(message);
          $('#pollingError').removeClass('d-none');
        }

        function showConflict(message) {
          $('#conflictMessage').text(message);
          $('#conflictAlert').removeClass('d-none');
        }

        function hideAlerts() {
          $('#pollingError').addClass('d-none');
          $('#conflictAlert').addClass('d-none');
        }

        // ------------------------------------------------------------------
        // 通信ログ (ポーリングのコストを目で見るため)
        // ------------------------------------------------------------------

        function addLog(kind, status, note, elapsed) {
          // 文字列で HTML を組み立てず、要素を作って .text() で値を入れます
          var $row = $('<tr>')
            .append($('<td>').text(clockText()))
            .append($('<td>').text(kind))
            .append($('<td>').text(status))
            .append($('<td>').text(note))
            .append($('<td>').addClass('text-right').text(elapsed === '-' ? '-' : elapsed + ' ms'));

          $('#logBody').prepend($row);
          $('#logEmpty').addClass('d-none');

          // 行が増え続けると重くなるので、古いものから捨てます
          var $rows = $('#logBody').find('tr').not('#logEmpty');
          if ($rows.length > 30) {
            $rows.slice(30).remove();
          }
        }

        function clockText() {
          var now = new Date();
          return ('0' + now.getHours()).slice(-2) + ':'
            + ('0' + now.getMinutes()).slice(-2) + ':'
            + ('0' + now.getSeconds()).slice(-2);
        }

        // 間隔を変えたときに、どれだけリクエストが増えるかの目安を出す
        function showEstimate() {
          var perMinute = Math.round(60000 / intervalMillis);
          $('#estimateOne').text(perMinute + ' 回');
          $('#estimateHundred').text((perMinute * 100 / 60).toFixed(1) + ' リクエスト/秒');
        }

        // ------------------------------------------------------------------
        // 画面を離れたときに止める
        // ------------------------------------------------------------------

        // タブが裏に回っている間の問い合わせは、まるごと無駄です。
        // 止めるのは「聞きに行くこと」だけで、サーバ側の処理は進み続けます
        document.addEventListener('visibilitychange', function () {
          if (document.hidden) {
            if (timerId !== null) {
              resumeWhenVisible = true;
              stopPolling('タブが裏に回りました');
              $('#visibilityNote').removeClass('d-none');
            }
          } else if (resumeWhenVisible) {
            $('#visibilityNote').addClass('d-none');
            startPolling();
            poll();   // 戻ってきた瞬間に 1 回だけ、すぐ最新を取りに行く
          }
        });

        // 画面を離れるときの後片付け。
        // ページが閉じられればタイマーも消えるので、画面遷移だけなら無くても動きます。
        // 画面を切り替えても JavaScript が生き続ける作り (SPA など) では必須です
        window.addEventListener('beforeunload', function () {
          stopPolling('画面を離れました');
        });

        // ------------------------------------------------------------------
        // ボタン
        // ------------------------------------------------------------------

        $startButton.on('click', function () {
          requestStart();
        });

        $cancelButton.on('click', function () {
          requestCancel();
        });

        // 実行中にもう一度 start を送って、サーバが 409 を返すところを見せるためのボタン
        $forceStartButton.on('click', function () {
          requestStart();
        });

        $('#intervalSelect').on('change', function () {
          intervalMillis = parseInt($(this).val(), 10);
          showEstimate();

          // 動いている最中に間隔を変えるときは、いったん止めてから仕掛け直します。
          // setInterval は途中で間隔だけを変えることができません
          if (timerId !== null) {
            clearInterval(timerId);
            timerId = null;
            startPolling();
          }
        });

        $('#clearLogButton').on('click', function () {
          $('#logBody').find('tr').not('#logEmpty').remove();
          $('#logEmpty').removeClass('d-none');
        });

        // ------------------------------------------------------------------
        // 画面を開いたとき
        // ------------------------------------------------------------------

        showEstimate();
        setButtons(currentState);
        showTimerState('停止中');

        if (currentState === 'running') {
          // 集計の途中で画面を開き直した場合。
          // 進捗はサーバ (セッション) が持っているので、続きから見られます
          resumeWhenVisible = true;
          startPolling();
          poll();
        }
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:panel title="① 集計の進捗" note="1 秒おきにサーバへ問い合わせます">
      <p class="mb-3">
        「集計を開始」を押すと、${totalSeconds} 秒かかる集計処理（の見立て）が始まります。
        サーバはセッションに<strong>開始時刻だけ</strong>を覚え、
        問い合わせが来るたびに「いま − 開始時刻」から進捗を計算して返します。
        サーバ側でスレッドやタイマーは作っていません。
      </p>

      <div class="progress mb-2">
        <div class="progress-bar progress-bar-striped ${resumeState eq 'running' ? 'progress-bar-animated' : ''} ${resumeState eq 'done' ? 'bg-success' : ''}"
             id="pollingBar" role="progressbar"
             style="width: ${resumePercent}%;"
             aria-valuenow="${resumePercent}" aria-valuemin="0" aria-valuemax="100">${resumePercent} %</div>
      </div>

      <div class="mb-3">
        <span class="badge badge-${resumeState eq 'running' ? 'primary' : (resumeState eq 'done' ? 'success' : 'secondary')}"
              id="pollingState">${resumeState eq 'running' ? '実行中' : (resumeState eq 'done' ? '完了' : '未実行')}</span>
        <span class="ml-2" id="pollingMessage">${fn:escapeXml(resumeMessage)}</span>
      </div>

      <div class="mb-3">
        <button type="button" class="btn btn-primary" id="startButton">
          <t:icon name="arrow-repeat" size="14" cssClass="mr-1" />集計を開始
        </button>
        <button type="button" class="btn btn-outline-secondary ml-1" id="cancelButton" disabled>中止</button>
        <span class="text-muted small ml-3" id="timerState">停止中</span>
      </div>

      <div class="alert alert-warning d-none" id="conflictAlert">
        <strong>サーバに断られました（HTTP 409 Conflict）</strong>
        <div class="small mt-1" id="conflictMessage">-</div>
      </div>

      <div class="alert alert-danger d-none" id="pollingError">
        <span id="pollingErrorMessage">-</span>
      </div>

      <div class="alert alert-success ${resumeState eq 'done' ? '' : 'd-none'}" id="resultArea">
        <t:icon name="check-circle" size="16" cssClass="mr-1" />
        <strong>集計が完了しました。</strong>
        対象件数 <strong><span id="resultCount">${resumeResultCount}</span></strong> 件を、
        <span id="resultElapsed">${resumeElapsedSeconds lt totalSeconds ? resumeElapsedSeconds : totalSeconds}</span> 秒で処理しました。
        <div class="small mt-1">
          結果は開始時刻から決まる値です。完了後にもう一度問い合わせても、同じ件数が返ります。
        </div>
      </div>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" class="w-50">進捗</th>
              <td><span id="pollingPercent">${resumePercent} %</span></td>
            </tr>
            <tr>
              <th scope="row">経過</th>
              <td>
                <span id="pollingElapsed">${resumeElapsedSeconds} 秒</span>
                <span class="text-muted">／ 目安 <span id="pollingTotal">${totalSeconds} 秒</span></span>
              </td>
            </tr>
            <tr>
              <th scope="row">開始した時刻（サーバの時計）</th>
              <td><code id="pollingStartedAt">${empty resumeStartedAt ? '-' : fn:escapeXml(resumeStartedAt)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="② 二重に開始させない" note="押せなくするのは画面、断るのはサーバ">
      <p>
        実行中は「集計を開始」ボタンを <code>disabled</code> にしていますが、
        それは<strong>押しにくくしているだけ</strong>です。
        API の URL は誰でも直接叩けるので、二重開始を実際に止めるのはサーバ側の仕事になります。
      </p>
      <p class="mb-2">
        下のボタンは、実行中にわざともう一度 <code>action=start</code> を送ります。
        サーバは <strong>409 Conflict</strong> と理由を返し、走っている集計はそのまま続きます。
      </p>
      <button type="button" class="btn btn-outline-warning" id="forceStartButton" disabled>
        わざと二重に開始する（実行中のみ押せます）
      </button>
      <p class="text-muted small mt-3 mb-0">
        サーバ側は「実行中の集計があるか」を見てから開始します。
        この判定と登録の間に別のリクエストが割り込まないよう、
        セッションを単位にして 1 つずつ通しています
        （<code>AjaxPollingApiServlet</code> の <code>synchronized</code>）。
        複数台のサーバで動かす場合は、この方法では足りません。
        データベースの一意制約など、<strong>全台で共有できる仕組み</strong>で守ることになります。
      </p>
    </t:panel>

    <t:panel title="③ ポーリングのコスト" note="間隔を変えて、回数の増え方を見てください">
      <div class="form-row align-items-end mb-3">
        <div class="col-md-4 form-group mb-2">
          <label for="intervalSelect">問い合わせの間隔</label>
          <select class="form-control" id="intervalSelect">
            <option value="500">0.5 秒（なめらか・重い）</option>
            <option value="1000" selected>1 秒（このサンプルの既定）</option>
            <option value="3000">3 秒</option>
            <option value="10000">10 秒（遅く見える・軽い）</option>
          </select>
          <small class="form-text text-muted">実行中に変えると、その場で切り替わります。</small>
        </div>
        <div class="col-md-8 form-group mb-2">
          <div class="text-muted small">この間隔だと</div>
          <div>
            1 人が 1 分間見続けると <strong id="estimateOne">60 回</strong>、
            100 人が同時に見ていると <strong id="estimateHundred">100.0 リクエスト/秒</strong>
          </div>
        </div>
      </div>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-2">
          <tbody>
            <tr>
              <th scope="row" class="w-50">
                この画面が問い合わせた回数
                <span class="d-block text-muted small">画面を開き直すと 0 に戻ります</span>
              </th>
              <td><span id="clientPollCount">0 回</span></td>
            </tr>
            <tr>
              <th scope="row">
                サーバが数えた回数
                <span class="d-block text-muted small">
                  セッションごとの数。開始するたびに数え直します
                </span>
              </th>
              <td><span id="serverPollCount">${serverPollCount} 回</span></td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mb-0">
        2 つの数がずれるのは、画面を開き直したときです。
        サーバは「このブラウザから何回来たか」を数え続けているので、
        <strong>画面を開き直しても通信そのものは無かったことにならない</strong>のが分かります。
      </p>
    </t:panel>

    <t:panel title="④ 通信ログ" note="1 回の問い合わせが 1 行です">
      <div class="alert alert-info d-none" id="visibilityNote">
        タブが裏に回ったので、問い合わせを止めました。
        この間もサーバ側の集計は進んでいます。表に戻ると続きから再開します。
      </div>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-2">
          <thead>
            <tr>
              <th>時刻（ブラウザ）</th>
              <th>種類</th>
              <th>HTTP</th>
              <th>結果</th>
              <th class="text-right">所要</th>
            </tr>
          </thead>
          <tbody id="logBody">
            <tr id="logEmpty">
              <td colspan="5" class="text-center text-muted">まだ通信していません。</td>
            </tr>
          </tbody>
        </table>
      </div>
      <button type="button" class="btn btn-outline-secondary btn-sm" id="clearLogButton">ログを消す</button>

      <div class="mt-3">
        <div class="text-muted small mb-1">最後に受け取った JSON</div>
<pre class="code-snippet mb-0" id="lastJson">（まだ取得していません）</pre>
      </div>
    </t:panel>

    <t:panel title="⑤ 画面を開き直してみる" note="進捗を持っているのはサーバです">
      <p>
        集計を開始してすぐ、下のリンクで<strong>この画面を読み込み直して</strong>ください。
        進捗はセッション（サーバ側）にあるので、画面は続きから表示され、
        ポーリングも自動で再開します。
      </p>
      <p>
        もし進捗をブラウザの変数だけで持っていたら、読み込み直した瞬間に
        「何も実行していない画面」に戻ってしまいます。
        <code>AjaxPollingServlet</code> がセッションの状態を読み、
        <code>resumeState</code> として JSP に渡しているのがその仕掛けです。
      </p>
      <a class="btn btn-outline-secondary" href="${ctx}/samples/ajax/ajax-polling">
        <t:icon name="arrow-repeat" size="14" cssClass="mr-1" />この画面を読み込み直す（画面遷移）
      </a>
      <p class="text-muted small mt-3 mb-0">
        いまの状態（サーバがこの画面を作った時点）:
        <code>${fn:escapeXml(resumeState)}</code> / 進捗 ${resumePercent} %
        <c:if test="${resumeState eq 'done'}">
          / 結果 ${resumeResultCount} 件
        </c:if>
        <br>
        セッションが切れる（既定では 30 分放置）と、この状態も消えます。
        「昨日流した処理の結果を見たい」という要件が出てきたら、置き場所はデータベースです。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
