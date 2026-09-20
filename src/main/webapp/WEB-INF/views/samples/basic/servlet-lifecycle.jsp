<%--
  【サンプル】Servlet のライフサイクルとスレッド

  Servlet はリクエストごとに作られるのではなく、アプリ全体で 1 インスタンス。
  そこへリクエストごとの別スレッドが同時に入ってくる、という所を体験する画面です。

    ・LifecycleServlet          … この画面。init の時刻・インスタンス識別子・スレッド名を渡す
    ・LifecycleCounterApiServlet … /samples/basic/servlet-lifecycle/api (JSON)
                                   AtomicInteger と素の int の 2 つのカウンタを持つ

  「同時に 50 回アクセスする」ボタンで API を並列に叩き、
  スレッドセーフでない方のカウンタがずれることを見せます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="servlet-lifecycle">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>Servlet のライフサイクル</h2>
    <p>
      Servlet は、リクエストのたびに <code>new</code> されるのではありません。
      ひとつの Servlet につきインスタンスは<strong>アプリ全体で 1 つ</strong>だけ作られ、
      そこへ<strong>リクエストごとの別々のスレッド</strong>が同時に入ってきます。
      Servlet を書くときの前提は、この一点に尽きます。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>メソッド</th><th>呼ばれるとき</th><th>回数</th><th>ここに書くもの</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>コンストラクタ</code></td>
            <td>コンテナがインスタンスを作るとき</td>
            <td>1 回</td>
            <td>なにも書かない（<code>ServletConfig</code> がまだ渡されていません）</td>
          </tr>
          <tr>
            <td><code>init()</code></td>
            <td>インスタンスが作られた直後</td>
            <td>1 回</td>
            <td>設定の読み込み、重い準備。作った値は<strong>以降変えない</strong>ものにする</td>
          </tr>
          <tr>
            <td><code>service()</code><br>→ <code>doGet()</code> / <code>doPost()</code></td>
            <td>リクエストのたび</td>
            <td>何回でも<br><strong>同時に</strong></td>
            <td>本来の処理。ここは複数スレッドが同時に走っている前提で書く</td>
          </tr>
          <tr>
            <td><code>destroy()</code></td>
            <td>アプリの停止・再配備の直前</td>
            <td>1 回</td>
            <td>後始末（自分で起こしたスレッドの停止など）</td>
          </tr>
        </tbody>
      </table>
    </div>

<pre><code class="language-plaintext">［アプリの起動］
    └─ loadOnStartup を指定した Servlet だけ  new → init()   ← 1 回だけ

［最初のリクエスト］
    └─ 指定していない Servlet はここで        new → init()   ← 1 回だけ

［リクエストが来るたび］
    ├─ スレッド exec-1 ┐
    ├─ スレッド exec-2 ┼─→ 同じ 1 つのインスタンスの service() → doGet / doPost
    └─ スレッド exec-3 ┘

［アプリの停止・再配備］
    └─ destroy()                                            ← 1 回だけ</code></pre>

    <h3>init が呼ばれるのはいつか（loadOnStartup）</h3>
    <p>
      既定では「最初のリクエストが来たとき」です。
      <code>loadOnStartup</code> に 0 以上の数を指定すると、アプリの起動時に作られます
      （数が小さいものから順に初期化されます）。
    </p>
<pre><code class="language-java">// 最初のアクセスまで作られない（既定）
@WebServlet(name = "servletLifecycle", urlPatterns = {"/samples/basic/servlet-lifecycle"})

// アプリの起動時に作って init まで済ませる
@WebServlet(name = "servletLifecycleCounterApi",
        urlPatterns = {"/samples/basic/servlet-lifecycle/api"},
        loadOnStartup = 1)</code></pre>
    <p>
      <code>web.xml</code> で書くなら <code>&lt;load-on-startup&gt;1&lt;/load-on-startup&gt;</code> です。
      起動時に作っておくと「最初にアクセスした人だけ待たされる」ことが無くなり、
      設定ミスにも起動時に気づけます。反対に、起動そのものは遅くなります。
      このサンプルの 2 本の Servlet はわざと指定を変えてあるので、
      デモタブの init の時刻を見比べてみてください。
    </p>

    <h2>1 インスタンスを、たくさんのスレッドが共有する</h2>
    <p>
      Tomcat はリクエストを受け取るたびにスレッドプールからスレッドを 1 本借りて、
      そのスレッドで <code>service()</code> を呼びます。スレッドの名前が
      <code>http-nio-8080-exec-3</code> のように毎回違うのはそのためです。
      呼ばれる相手はいつも<strong>同じインスタンス</strong>です。
    </p>
    <p>
      つまり、<strong>フィールド（インスタンス変数）は全リクエストの共有メモリ</strong>です。
      次のコードは、一見なんでもないように見えて、実際に事故になります。
    </p>
<pre><code class="language-java">public class BadServlet extends HttpServlet {

    private String userName;   // ← 全リクエストで共有される

    protected void doGet(HttpServletRequest request, HttpServletResponse response) {
        userName = request.getParameter("name");   // ① 自分の名前を入れる
        // …ここで別のスレッドが ① を実行して上書きする…
        request.setAttribute("name", userName);    // ② 他人の名前が表示される
    }
}</code></pre>
    <p>
      直し方は簡単で、<strong>ローカル変数にするだけ</strong>です。
      ローカル変数はスレッドごとに別々に用意されるので、他のリクエストから見えません。
    </p>
<pre><code class="language-java">protected void doGet(HttpServletRequest request, HttpServletResponse response) {
    String userName = request.getParameter("name");   // スレッドごとに別物 = 安全
    request.setAttribute("name", userName);
}</code></pre>

    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>値の置き場所</th><th>見える範囲</th><th>同時アクセス</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>ローカル変数・引数</td>
            <td>その呼び出しの中だけ</td>
            <td><strong>安全</strong>（何も考えなくてよい）</td>
          </tr>
          <tr>
            <td><code>request</code> 属性</td>
            <td>その 1 リクエスト（forward 先を含む）</td>
            <td><strong>安全</strong></td>
          </tr>
          <tr>
            <td><code>session</code> 属性</td>
            <td>その利用者</td>
            <td>ほぼ安全。ただし同じ人がタブを 2 つ開けば同時に触られます</td>
          </tr>
          <tr>
            <td>インスタンス変数（フィールド）</td>
            <td>アプリ全体・全リクエスト</td>
            <td><strong>自分で守る必要がある</strong></td>
          </tr>
          <tr>
            <td><code>static</code> 変数</td>
            <td>アプリ全体・全リクエスト</td>
            <td><strong>自分で守る必要がある</strong></td>
          </tr>
          <tr>
            <td><code>ServletContext</code> 属性</td>
            <td>アプリ全体・全リクエスト</td>
            <td><strong>自分で守る必要がある</strong></td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>デモで起きていること（失われた更新）</h2>
    <p>
      デモの 2 つのカウンタは、どちらも同じ Servlet の<strong>フィールド</strong>です。
      違うのは増やし方だけです。
    </p>
<pre><code class="language-java">private final AtomicInteger atomicCount = new AtomicInteger();
private int unsafeCount;

void hit() {
    // 安全 : 「読む・足す・書く」がひとつの操作になっている
    atomicCount.incrementAndGet();

    // 危険 : 3 つの操作に分かれている
    int current = unsafeCount;      // ① 読む
    pauseToWidenTheGap();           // ② この隙間に、別のスレッドも同じ値を読む
    unsafeCount = current + 1;      // ③ 書き戻す → ② で読んだ側の結果を消してしまう
}</code></pre>
    <p>
      2 本のスレッドが重なったときに何が起きるかを並べると、こうなります。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>順番</th><th>スレッド A</th><th>スレッド B</th><th><code>unsafeCount</code></th></tr>
        </thead>
        <tbody>
          <tr><td>1</td><td>10 を読む</td><td></td><td>10</td></tr>
          <tr><td>2</td><td></td><td>10 を読む</td><td>10</td></tr>
          <tr><td>3</td><td>11 を書く</td><td></td><td>11</td></tr>
          <tr><td>4</td><td></td><td>11 を書く</td><td><strong>11</strong>（2 回増やしたのに 1 しか増えていない）</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      これを「失われた更新（lost update）」と呼びます。
      <code>unsafeCount++</code> と 1 行で書いても中身は同じ 3 手順なので、結果は変わりません。
      このサンプルが間に待ちを挟んでいるのは、
      <strong>本来ナノ秒しかない隙間を、人間に見える大きさに広げるため</strong>だけです。
      待ちが無くても同じことは起きます。アクセスが増えるほど、重なる確率が上がります。
    </p>
    <p>
      さらに、<code>volatile</code> を付けていないフィールドは
      <strong>他のスレッドが書いた最新の値が見えるとは限りません</strong>（CPU のキャッシュに残ったままになります）。
      「ずれる」ことより「見えない」ことのほうが、後から追いかけるのは大変です。
    </p>

    <h2>ではどう書くか</h2>
    <h3>1. まず、Servlet に状態を持たせない</h3>
    <p>
      これが一番の解決です。リクエストごとに変わる値は、ローカル変数・リクエストスコープ・
      セッション・データベースのどれかに置きます。
      Servlet のフィールドに置いてよいのは、<strong>init で決めて以降変えない値</strong>
      （設定値、DAO のような状態を持たない部品、不変オブジェクト）だけだと考えてください。
    </p>

    <h3>2. どうしても持つなら、スレッドセーフな入れ物にする</h3>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>やりたいこと</th><th>使うもの</th><th>ひとこと</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>数を数える</td>
            <td><code>AtomicInteger</code> / <code>AtomicLong</code></td>
            <td><code>incrementAndGet()</code> ひとつで完結する</td>
          </tr>
          <tr>
            <td>キーと値を持つ</td>
            <td><code>ConcurrentHashMap</code></td>
            <td><code>HashMap</code> を同時に更新すると壊れます（無限ループの報告もあります）</td>
          </tr>
          <tr>
            <td>複数のフィールドをまとめて更新</td>
            <td><code>synchronized</code> / <code>ReentrantLock</code></td>
            <td>個々がスレッドセーフでも、組み合わせは守られません</td>
          </tr>
          <tr>
            <td>読むだけの共有値</td>
            <td><code>final</code> + 不変オブジェクト</td>
            <td>変わらないものは、そもそも競合しません</td>
          </tr>
        </tbody>
      </table>
    </div>
<pre><code class="language-java">private final Object lock = new Object();
private int total;
private int count;

protected void doPost(HttpServletRequest request, HttpServletResponse response) {
    synchronized (lock) {        // total と count を必ずセットで更新したい
        total += amount;
        count++;
    }
}</code></pre>
    <p>
      ただし <code>synchronized</code> は「その間ほかのリクエストを待たせる」ということでもあります。
      囲む範囲は最小限にし、<strong>中でデータベースアクセスや外部通信をしない</strong>のが鉄則です。
    </p>
    <p>
      なお、<code>AtomicInteger</code> を使っていても、
      <code>if (counter.get() &lt; 10) { counter.incrementAndGet(); }</code> のように
      「読む」と「書く」を分けて書けば、その間はやはり競合します。
      <code>incrementAndGet</code> / <code>compareAndSet</code> / <code>computeIfAbsent</code> のように、
      <strong>ひとつの操作で済ませられるメソッド</strong>を選ぶのがコツです。
    </p>

    <h3>3. SingleThreadModel は解決にならない</h3>
    <p>
      「<code>implements SingleThreadModel</code> と書けば 1 スレッドずつになる」という話を
      古い資料で見かけますが、<strong>Servlet 2.4 で非推奨になっており、使ってはいけません</strong>。
    </p>
    <ul>
      <li>
        コンテナは<strong>インスタンスを複数作って振り分けてもよい</strong>ことになっています。
        守られるのはインスタンス変数だけで、<code>static</code> 変数・セッション・
        <code>ServletContext</code>・データベースは共有されたままです。
      </li>
      <li>
        同時に処理できる数が<strong>インスタンスの数で頭打ち</strong>になります。
        インスタンスを 1 つしか作らないコンテナでは、リクエストが 1 本ずつ順番待ちになります。
      </li>
      <li>
        なにより、<strong>「安全になったつもり」になれてしまう</strong>のが害です。
        フィールドを共有しない、共有するなら同期する ── 解決はこれだけです。
      </li>
    </ul>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>ブラウザは 50 本を同時に投げてはくれない</strong>：
        HTTP/1.1 のブラウザは、同じサーバに対して 6 本程度しか同時に接続しません。
        50 件送っても、実際に重なるのは数本ずつです。
        それでも重なった分はきちんと取りこぼすので、ずれは目で見えます
        （何件ずれるかは毎回変わります）。
      </li>
      <li>
        <strong>差が出ない回もある</strong>：
        競合は「タイミングが重なったときだけ」起きます。
        つまり<strong>テストでは再現せず、本番の忙しい時間帯にだけ起きる</strong>バグになります。
        1 回試してずれなかったことを「安全」と読み替えないでください。
      </li>
      <li>
        <strong>自分ひとりで動かしている限り、絶対に気づけない</strong>：
        開発中は同時アクセスが起きないため、フィールドに値を置いても普通に動いてしまいます。
        「動いた」ではなく「同時に来たらどうなるか」で確認します。
      </li>
      <li>
        <strong><code>HttpServletRequest</code> をフィールドに持たない</strong>：
        もっとも危険な形です。リクエストを一度フィールドに入れてから別メソッドで使う書き方は、
        隣の利用者のリクエストを読むことになります。引数で渡してください。
        同じ理由で、<code>SimpleDateFormat</code> のような
        <strong>スレッドセーフでない道具を <code>static</code> で共有しない</strong>ことも大切です
        （<code>DateTimeFormatter</code> は不変なので共有できます）。
      </li>
      <li>
        <strong>コンストラクタで <code>getServletContext()</code> を呼ぶと落ちる</strong>：
        <code>ServletConfig</code> が渡されるのは init の直前です。初期化処理は <code>init()</code> に書きます。
      </li>
      <li>
        <strong><code>destroy()</code> は必ず呼ばれるわけではない</strong>：
        プロセスを強制終了したときや電源が落ちたときは呼ばれません。
        「終了時にここで保存する」という作りにしないでください。
      </li>
      <li>
        <strong>再配備するとフィールドの値は消える</strong>：
        インスタンスが作り直されるためです（このページのカウンタも 0 に戻ります）。
        残したい値はデータベースなどに置きます。
      </li>
      <li>
        <strong><code>ThreadLocal</code> を使ったら必ず <code>remove()</code></strong>：
        スレッドは使い回されるので、消し忘れると次のリクエストに前の値が見えてしまいます
        （メモリリークの原因にもなります）。
      </li>
    </ul>

    <h2>デモの非同期通信について</h2>
    <p>
      「同時に 50 回アクセスする」ボタンは、<code>fetch</code> を 50 個まとめて作ってしまい、
      返ってきた <code>Promise</code> を配列に溜めて <code>Promise.all</code> で待っています。
      <code>fetch</code> は<strong>呼んだ時点でリクエストが飛ぶ</strong>ので、これで 50 本が同時に出ていきます。
      1 件ずつ結果を待ってから次を送る書き方（<code>await</code> や <code>then</code> の数珠つなぎ）にすると、
      リクエストが順番に流れるだけになり、競合は起きません。
    </p>
<pre><code class="language-javascript">// カウンタは押すたびに積み上がるので、送る前の値を控えておく
load().then(function (before) {

  var requests = [];
  for (var i = 0; i &lt; 50; i++) {
    requests.push(hit());      // ここでは結果を待たない = 50 本が同時に飛ぶ
  }

  return Promise.all(requests).then(function () {
    return load().then(function (after) {
      // 「今回のぶん」だけを比べる。前回の押下ぶんを混ぜないため
      var lost = (after.atomic - before.atomic) - (after.unsafe - before.unsafe);
    });
  });
});</code></pre>
    <p>
      前後で 2 回読み直しているのは、<strong>カウンタがボタンを押すたびに積み上がる</strong>からです。
      いまの値だけを見て <code>atomic - unsafe</code> を取ると、
      2 回目以降は前回の取りこぼしまで足し込んでしまい、「50 件送ったのに 78 件取りこぼした」
      というおかしな表示になります。
    </p>
    <p>
      カウンタを増やす操作は <code>POST</code>、値を読むだけの操作は <code>GET</code> に分けています。
      GET は「何度呼んでも状態が変わらない」ものにしておくのが約束です
      （ブラウザや中継サーバが勝手に再実行・キャッシュすることがあるためです）。
      そのかわり <strong>GET の応答はキャッシュされうる</strong>ので、
      値を読み直す API には Servlet 側で
      <code>response.setHeader("Cache-Control", "no-store")</code> を付けています。
      これが無いと、送ったあとに読み直しても<strong>古い値が返ってきて</strong>、
      数が合わない原因がキャッシュなのか競合なのか分からなくなります。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {
        // このサンプル専用の API。カウンタを増やす (POST) / 読む (GET)
        var apiUrl = '${ctx}/samples/basic/servlet-lifecycle/api';
        var burstSize = 50;

        var $buttons = $('#burstButton, #reloadButton, #resetButton');
        var $status = $('#burstStatus');
        var $result = $('#burstResult');

        // JSON の中身を画面へ反映する
        function show(data) {
          $('#atomicValue').text(data.atomic);
          $('#unsafeValue').text(data.unsafe);
          $('#lastThread').text(data.thread);
          $('#lastInstance').text(data.instance);
        }

        // 1 回叩く : 状態を変えるので POST
        function hit() {
          return fetch(apiUrl, {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=hit'
          }).then(readJson);
        }

        // いまの値を読むだけ : 状態を変えないので GET
        function load() {
          return fetch(apiUrl, {headers: {'Accept': 'application/json'}}).then(readJson);
        }

        // fetch は 404 や 500 でも失敗しない (res.ok を自分で見る必要がある)
        function readJson(res) {
          if (!res.ok) {
            throw new Error('サーバが ' + res.status + ' を返しました');
          }
          return res.json();
        }

        function busy(isBusy) {
          $buttons.prop('disabled', isBusy);
        }

        // ------------------------------------------------ 同時に 50 回
        $('#burstButton').on('click', function () {
          busy(true);
          $result.addClass('d-none');
          $status.text(burstSize + ' 件のリクエストを同時に送っています…');

          // カウンタは 0 に戻さずに積み上がっていくので、
          // 「今回のぶん」だけを見たい。送る前の値を控えておきます
          load().then(function (before) {

            // ここで結果を待たずに配列へ溜めるのがポイント。まとめて飛ばす
            var requests = [];
            for (var i = 0; i < burstSize; i++) {
              requests.push(hit());
            }

            return Promise.all(requests).then(function (results) {
              // どのスレッド・どのインスタンスが応答したかを数える
              var threads = {};
              var instances = {};
              results.forEach(function (r) {
                threads[r.thread] = (threads[r.thread] || 0) + 1;
                instances[r.instance] = true;
              });
              var threadNames = Object.keys(threads).sort();
              var instanceNames = Object.keys(instances);

              // 全部終わったあとの確定値を GET で読み直す
              return load().then(function (after) {
                show(after);

                var atomicAdded = after.atomic - before.atomic;
                var unsafeAdded = after.unsafe - before.unsafe;
                var lost = atomicAdded - unsafeAdded;

                $('#sentCount').text(burstSize);
                $('#doneCount').text(results.length);
                $('#atomicAdded').text(atomicAdded);
                $('#unsafeAdded').text(unsafeAdded);
                $('#lostCount').text(lost);
                $('#threadCount').text(threadNames.length);
                $('#threadNames').text(threadNames.join(' / '));
                $('#instanceCount').text(instanceNames.length);
                $('#instanceNames').text(instanceNames.join(' / '));

                $('#burstVerdict')
                  .removeClass('alert-danger alert-warning')
                  .addClass(lost > 0 ? 'alert-danger' : 'alert-warning')
                  .html(lost > 0
                    ? '同じ回数だけ増やしたはずなのに、素の <code>int</code> のカウンタは <strong>'
                      + unsafeAdded + '</strong> しか増えていません（<strong>' + lost
                      + ' 件</strong>の取りこぼし）。<code>AtomicInteger</code> のほうは '
                      + atomicAdded + ' 増えています。'
                    : '今回はたまたま差が出ませんでした。競合は「重なったときだけ」起きます。'
                      + 'もう一度押してみてください（差が出ないことこそが、このバグの怖い所です）。');

                $result.removeClass('d-none');
                $status.text('完了しました。' + results.length + ' 件の応答を受け取りました。');
              });
            });
          }).catch(function (e) {
            $status.text('失敗しました: ' + e.message);
          }).then(function () {
            busy(false);
          });
        });

        // ------------------------------------------------ 読み直す / リセット
        $('#reloadButton').on('click', function () {
          busy(true);
          load().then(show).catch(function (e) {
            $status.text('失敗しました: ' + e.message);
          }).then(function () {
            busy(false);
          });
        });

        $('#resetButton').on('click', function () {
          busy(true);
          $result.addClass('d-none');
          fetch(apiUrl, {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=reset'
          }).then(readJson).then(function (data) {
            show(data);
            $status.text('カウンタを 0 に戻しました。');
          }).catch(function (e) {
            $status.text('失敗しました: ' + e.message);
          }).then(function () {
            busy(false);
          });
        });

        // 画面を開いたときに、いまの値を読み込んでおく
        load().then(show).catch(function () {
          $status.text('カウンタを読み込めませんでした。');
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:panel title="① インスタンスは 1 つ、スレッドは毎回ちがう"
             note="何度かリロードして、変わる値と変わらない値を見比べてください">
      <p>
        この画面と、下のカウンタ API は別々の Servlet です。
        どちらも<strong>アプリ全体で 1 インスタンス</strong>しかありません。
      </p>
      <div class="table-responsive">
        <table class="table table-sm table-bordered">
          <thead>
            <tr>
              <th class="w-25">&nbsp;</th>
              <th>この画面の Servlet<br><code>LifecycleServlet</code></th>
              <th>カウンタ API の Servlet<br><code>LifecycleCounterApiServlet</code></th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row"><code>loadOnStartup</code></th>
              <td>指定なし<span class="d-block text-muted small">最初のアクセスのときに init</span></td>
              <td><code>1</code><span class="d-block text-muted small">アプリの起動時に init</span></td>
            </tr>
            <tr>
              <th scope="row">init が呼ばれた時刻</th>
              <td><code>${fn:escapeXml(initAt)}</code></td>
              <td><code>${fn:escapeXml(apiInitAt)}</code></td>
            </tr>
            <tr>
              <th scope="row">init を処理したスレッド</th>
              <td><code>${fn:escapeXml(initThread)}</code></td>
              <td><code>${fn:escapeXml(apiInitThread)}</code></td>
            </tr>
            <tr>
              <th scope="row">インスタンスの識別子</th>
              <td><code>${fn:escapeXml(instanceId)}</code></td>
              <td><code>${fn:escapeXml(apiInstanceId)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-2">
          <tbody>
            <tr>
              <th scope="row" class="w-25">いまのリクエストを処理したスレッド</th>
              <td>
                <code>${fn:escapeXml(currentThread)}</code>
                <span class="d-block text-muted small mt-1">
                  リロードするたびに変わります。Tomcat がスレッドプールから 1 本借りてきた名前です。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">この Servlet が画面を返した回数</th>
              <td>
                <strong>${displayCount}</strong> 回
                <span class="d-block text-muted small mt-1">
                  インスタンス変数 (<code>AtomicInteger</code>) に貯めています。
                  別のブラウザから開いても、同じ数が増えていきます。
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mb-0">
        識別子と init の時刻は<strong>何度リロードしても変わりません</strong>。
        変わるのはスレッド名と回数だけ ── これが「1 インスタンスを全リクエストで共有している」という意味です。
      </p>
    </t:panel>

    <t:panel title="② 2 つのカウンタを同時に叩いてみる"
             note="どちらも同じ Servlet のフィールド。違うのは増やし方だけです">
      <div class="row">
        <div class="col-md-6 mb-3">
          <div class="card h-100 border-success">
            <div class="card-body text-center">
              <div class="text-muted small">スレッドセーフなカウンタ</div>
              <div class="display-4 text-success" id="atomicValue">-</div>
              <code class="small">atomicCount.incrementAndGet()</code>
            </div>
          </div>
        </div>
        <div class="col-md-6 mb-3">
          <div class="card h-100 border-danger">
            <div class="card-body text-center">
              <div class="text-muted small">スレッドセーフでないカウンタ</div>
              <div class="display-4 text-danger" id="unsafeValue">-</div>
              <code class="small">unsafeCount = current + 1</code>
            </div>
          </div>
        </div>
      </div>

      <button type="button" class="btn btn-primary" id="burstButton">同時に 50 回アクセスする</button>
      <button type="button" class="btn btn-outline-secondary ml-2" id="reloadButton">いまの値を読み直す</button>
      <button type="button" class="btn btn-outline-danger ml-2" id="resetButton">リセット</button>

      <p class="text-muted small mt-2 mb-3" id="burstStatus">
        ボタンを押すと、<code>/samples/basic/servlet-lifecycle/api</code> へ
        <code>fetch</code> を 50 本まとめて投げます。
      </p>

      <div id="burstResult" class="d-none">
        <div id="burstVerdict" class="alert mb-3"></div>
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-0">
            <tbody>
              <tr>
                <th scope="row" class="w-50">送ったリクエスト</th>
                <td><span id="sentCount">-</span> 件</td>
              </tr>
              <tr>
                <th scope="row">応答が返ってきた数</th>
                <td><span id="doneCount">-</span> 件</td>
              </tr>
              <tr>
                <th scope="row"><code>AtomicInteger</code> が増えた数（今回のぶん）</th>
                <td><span id="atomicAdded">-</span></td>
              </tr>
              <tr>
                <th scope="row">素の <code>int</code> が増えた数（今回のぶん）</th>
                <td><span id="unsafeAdded">-</span></td>
              </tr>
              <tr>
                <th scope="row">素の <code>int</code> が取りこぼした数</th>
                <td><span id="lostCount">-</span> 件</td>
              </tr>
              <tr>
                <th scope="row">処理に使われたスレッドの種類</th>
                <td>
                  <span id="threadCount">-</span> 種類
                  <span class="d-block text-muted small mt-1" id="threadNames"></span>
                </td>
              </tr>
              <tr>
                <th scope="row">応答した Servlet インスタンス</th>
                <td>
                  <span id="instanceCount">-</span> 個
                  <span class="d-block text-muted small mt-1" id="instanceNames"></span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <p class="text-muted small mt-3 mb-0">
        直前の応答を返したスレッド: <code id="lastThread">-</code> ／
        インスタンス: <code id="lastInstance">-</code><br>
        スレッドは何種類も出てくるのに、インスタンスは最後までひとつだけです。
      </p>
    </t:panel>

    <t:panel title="③ いま画面の裏で起きていること" note="init / service / destroy の流れ">
<pre class="code-snippet mb-2">［アプリの起動］
    └─ loadOnStartup を指定した Servlet だけ  new → init()   ← 1 回だけ

［最初のリクエスト］
    └─ 指定していない Servlet はここで        new → init()   ← 1 回だけ

［リクエストが来るたび］
    ├─ スレッド exec-1 ┐
    ├─ スレッド exec-2 ┼─→ 同じ 1 つのインスタンスの service() → doGet / doPost
    └─ スレッド exec-3 ┘
          ※ ローカル変数はスレッドごとに別物、フィールドは全員で共有

［アプリの停止・再配備］
    └─ destroy()                                            ← 1 回だけ
          ※ フィールドに貯めた値はここで消える</pre>
      <p class="mb-0">
        詳しい使い分けと、状態を持ちたくなったときの書き方は
        <strong>解説タブ</strong>にまとめています。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
