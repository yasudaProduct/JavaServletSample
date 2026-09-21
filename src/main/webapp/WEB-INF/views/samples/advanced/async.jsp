<%--
  【サンプル】時間のかかる処理を非同期で動かす

  AsyncServlet が次の値をセットします。
    apiPath        … 呼び出す API の URL (/samples/advanced/async/api)
    pageThread     … この画面を組み立てたスレッドの名前
    poolSize       … 非同期の仕事を回すスレッドの本数
    queueCapacity  … 順番待ちに並べられる件数
    defaultMillis / maxMillis … 待ち時間の既定値と上限

  API 側 (AsyncApiServlet) は mode=sync / mode=async で動きを変えます。
  どちらも「指定されたミリ秒だけ待って JSON を返す」だけで、違うのは待つスレッドです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="async">

  <jsp:attribute name="explanation">
    <h2>スレッドは「待っている間」も 1 本ふさがっている</h2>
    <p>
      Servlet は、リクエストごとにコンテナのスレッドを 1 本借りて動きます。
      外部 API の応答を 3 秒待つ処理なら、その 3 秒のあいだスレッドは
      <strong>何もしていないのに他のリクエストを処理できません</strong>。
      Tomcat の既定は 200 本（<code>maxThreads</code>）なので、
      3 秒待つ処理に 200 人が同時に来ると、201 人目は順番待ちになります。
      CPU は空いているのに、です。
    </p>
    <p>
      <code>AsyncContext</code> を使うと、<strong>応答を返すのを後回しにして
      コンテナのスレッドを先に返す</strong>ことができます。
      待つのは自分で用意したスレッドです。
    </p>
<pre><code class="language-java">@WebServlet(urlPatterns = "/samples/advanced/async/api", asyncSupported = true)   // ← 必須
public class AsyncApiServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response) {

        AsyncContext asyncContext = request.startAsync();   // 応答を後回しにする
        asyncContext.setTimeout(10_000);                    // 0 なら無制限
        asyncContext.addListener(new AsyncJobListener(...)); // 時間切れ・エラーの面倒を見る

        pool.execute(() -&gt; {                                // 待つのは別のスレッド
            String result = 重い処理();
            response.getWriter().write(result);
            asyncContext.complete();                        // ← 呼び忘れるとつながりっぱなし
        });
        // ここで doGet は終わる。でもレスポンスはまだ閉じていない
    }
}</code></pre>

    <h2>complete() と dispatch() の違い</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th></th><th>やること</th><th>使いどころ</th></tr></thead>
        <tbody>
          <tr>
            <td><code>complete()</code></td>
            <td>その場で応答を閉じる</td>
            <td>JSON を返す API。このサンプルもこちら</td>
          </tr>
          <tr>
            <td><code>dispatch("/WEB-INF/views/....jsp")</code></td>
            <td>コンテナのスレッドに戻して、続きを JSP に描かせる</td>
            <td>HTML の画面を返したいとき</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      JSP は非同期のスレッドから直接は描けません。画面を返したいときは
      <code>dispatch()</code> で戻してから <code>forward</code> します。
    </p>

    <h2>約束ごと</h2>
    <ul>
      <li>
        <strong><code>asyncSupported = true</code> を付ける</strong> …
        付け忘れると <code>startAsync()</code> で <code>IllegalStateException</code> です。
        その URL に掛かる<strong>フィルタにも</strong>必要です
        （<code>@WebFilter(asyncSupported = true)</code> /
        <code>&lt;async-supported&gt;true&lt;/async-supported&gt;</code>）
      </li>
      <li>
        <strong><code>startAsync()</code> のあと、元のスレッドで <code>response</code> を触らない</strong> …
        別のスレッドと同時に書くことになります
      </li>
      <li>
        <strong>必ず <code>complete()</code> か <code>dispatch()</code> で終わらせる</strong> …
        呼び忘れると、そのリクエストは時間切れまで開いたままです
      </li>
      <li>
        <strong><code>ThreadLocal</code> は引き継がれない</strong> …
        ログインしている人の情報やトランザクションをスレッドに紐付けていると、
        別のスレッドからは見えません。必要な値は渡してから投げます
      </li>
      <li>
        <strong>自分のスレッドプールには上限を付ける</strong> …
        無制限に増やすと、混雑したときにサーバごと倒れます
      </li>
    </ul>

    <h2>時間切れの面倒は自分で見る</h2>
    <p>
      <code>setTimeout</code> の時間までに <code>complete()</code> されないと、
      コンテナは <code>AsyncListener#onTimeout</code> を呼びます。
      ここで何もしないと、コンテナがエラー（500）で打ち切ります。
      「時間切れです」と分かる応答にしたいなら、自分で書いて <code>complete()</code> まで呼びます。
    </p>
    <p>
      このとき注意したいのが<strong>二重に応答しないこと</strong>です。
      時間切れの直後に、遅れてきた仕事が応答を書こうとすることがあります。
      サンプルでは <code>AtomicBoolean</code> の
      <code>compareAndSet</code> で「先に着いた方だけが書く」ようにしています。
    </p>
    <p>
      時間切れの判定は<strong>きっかりその時刻に来るわけではありません</strong>。
      コンテナは一定の間隔で見回っているだけなので（Tomcat は約 1 秒ごと）、
      実際に打ち切られるのは指定した時間の少しあとになります。
      「1.5 秒で切る」と書いても、応答が返るのは 2 秒近くになることがあります。
    </p>
    <p>
      そして、<strong>時間切れは仕事を止めません</strong>。
      利用者への応答が終わるだけで、スレッドプールの中では動き続けます。
      本当に止めたいなら <code>Future#cancel</code> や割り込みの処理が別に必要です。
    </p>

    <h2>非同期にしても仕事は減らない</h2>
    <p>
      デモ ③ で確かめられるところです。スレッド ${poolSize} 本のプールに 6 本の仕事を投げると、
      3 本目以降は<strong>順番待ち</strong>になります。
      コンテナのスレッドは空きますが、仕事の総量は変わりません。待つ場所が移っただけです。
    </p>
    <p>非同期が効くのは、次のような「待っているだけ」の時間が長い処理です。</p>
    <ul>
      <li>外部 API・別システムの応答待ち</li>
      <li>ロングポーリング、Server-Sent Events のような「つなぎっぱなし」の通信</li>
      <li>アップロードやダウンロードの、通信そのものが遅い相手</li>
    </ul>
    <p>逆に、次の場合は非同期にしても速くなりません。</p>
    <ul>
      <li>CPU を使い切る計算（待っているのではなく働いています）</li>
      <li>
        DB のコネクションプールが本当の上限になっている処理
        （コンテナのスレッドを空けても、コネクション待ちに変わるだけです）
      </li>
      <li>数ミリ秒で終わる処理（<code>AsyncContext</code> の手間の方が高くつきます）</li>
    </ul>

    <h2>関連する仕組み</h2>
    <ul>
      <li>
        <code>ReadListener</code> / <code>WriteListener</code>（Servlet 3.1）…
        入出力そのものを待たない書き方。スレッドを手放す範囲をさらに広げられます
      </li>
      <li>
        WebSocket / Server-Sent Events …
        サーバから送り続けたいときは、非同期 Servlet よりこちらが向いています
      </li>
      <li>
        <code>AsyncListener</code> はリスナーの仲間です。
        登録・呼ばれ方の考え方は
        <a href="${ctx}/samples/advanced/listener">リスナーで起動・終了・セッションを捕まえる</a>
        と同じです
      </li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // API を呼んで、結果を表に 1 行ずつ足していく
      (function () {
        'use strict';
        var demo = document.getElementById('asyncDemo');
        if (!demo) {
          return;
        }
        var apiPath = demo.dataset.apiPath;
        var tbody = document.getElementById('asyncResults');
        var status = document.getElementById('asyncStatus');
        var empty = document.getElementById('asyncEmpty');

        /** API を 1 本呼ぶ。ブラウザ側で測った時間も一緒に返す。 */
        function call(params) {
          var query = Object.keys(params).map(function (key) {
            return encodeURIComponent(key) + '=' + encodeURIComponent(params[key]);
          }).join('&');

          var started = window.performance.now();
          return fetch(apiPath + '?' + query)
            .then(function (res) {
              return res.json().then(function (json) {
                return {
                  httpStatus: res.status,
                  json: json,
                  browserMillis: Math.round(window.performance.now() - started)
                };
              });
            });
        }

        function cell(row, text, isCode) {
          var td = document.createElement('td');
          if (isCode) {
            var code = document.createElement('code');
            // 受け取った文字列は textContent で入れる（innerHTML に入れると XSS になる）
            code.textContent = text;
            td.appendChild(code);
          } else {
            td.textContent = text;
          }
          row.appendChild(td);
          return td;
        }

        function addRow(result) {
          var json = result.json;
          var row = document.createElement('tr');

          cell(row, json.label || '-');

          var mode = document.createElement('td');
          var badge = document.createElement('span');
          badge.className = 'badge badge-' + (json.mode === 'async' ? 'primary' : 'secondary');
          badge.textContent = json.mode === 'async' ? '非同期' : '同期';
          mode.appendChild(badge);
          if (json.timedOut) {
            var timeout = document.createElement('span');
            timeout.className = 'badge badge-danger ml-1';
            timeout.textContent = '時間切れ';
            mode.appendChild(timeout);
          }
          row.appendChild(mode);

          cell(row, result.httpStatus);
          cell(row, json.servletThread || '-', true);
          cell(row, json.workerThread || '-', true);
          cell(row, json.waitedMillis === undefined ? '-' : json.waitedMillis + ' ms');
          cell(row, json.totalMillis === undefined ? '-' : json.totalMillis + ' ms');
          cell(row, result.browserMillis + ' ms');
          cell(row, json.message || '');

          tbody.appendChild(row);
          empty.hidden = true;
        }

        function selectedMillis() {
          return document.getElementById('workMillis').value;
        }

        function run(params) {
          status.textContent = '呼び出しています... ' + JSON.stringify(params);
          return call(params)
            .then(addRow)
            .then(function () {
              status.textContent = '完了しました。';
            })
            .catch(function (e) {
              status.textContent = 'うまくいきませんでした: ' + e.message;
            });
        }

        document.getElementById('runSync').addEventListener('click', function () {
          run({ mode: 'sync', millis: selectedMillis(), label: '同期 1 本' });
        });

        document.getElementById('runAsync').addEventListener('click', function () {
          run({ mode: 'async', millis: selectedMillis(), label: '非同期 1 本' });
        });

        document.getElementById('runTimeout').addEventListener('click', function () {
          // 仕事は 4 秒、制限時間は 1.5 秒。onTimeout が先に応答する
          run({ mode: 'async', millis: 4000, timeout: 1500, label: '制限時間 1.5 秒' });
        });

        document.getElementById('runBurst').addEventListener('click', function () {
          var mode = document.querySelector('input[name="burstMode"]:checked').value;
          var millis = selectedMillis();
          status.textContent = mode === 'async' ? '非同期で 6 本まとめて投げています...'
                                                : '同期で 6 本まとめて投げています...';

          var calls = [];
          for (var i = 1; i <= 6; i++) {
            calls.push(call({ mode: mode, millis: millis, label: '6 本同時 #' + i }));
          }
          // 投げた順に表へ並べたいので、全部そろってから描く
          Promise.all(calls)
            .then(function (results) {
              results.forEach(addRow);
              status.textContent = '6 本とも終わりました。';
            })
            .catch(function (e) {
              status.textContent = 'うまくいきませんでした: ' + e.message;
            });
        });

        document.getElementById('clearResults').addEventListener('click', function () {
          tbody.innerHTML = '';
          empty.hidden = false;
          status.textContent = '表を消しました。';
        });
      })();
    </script>
  </jsp:attribute>

  <jsp:body>

    <t:panel title="この画面を出したスレッド"
             note="下のデモで出てくるスレッド名と見比べてください">
      <p class="mb-0">
        いまの HTML を組み立てたのは <code>${fn:escapeXml(pageThread)}</code> です。
        <code>http-nio-...-exec-</code> で始まるのがコンテナのスレッド、
        <code>async-worker-</code> で始まるのがこのサンプルが用意したスレッドです。
        用意しているのは <strong>${poolSize} 本</strong>で、
        順番待ちに並べられるのは <strong>${queueCapacity} 件</strong>までです。
      </p>
    </t:panel>

    <div id="asyncDemo" data-api-path="${fn:escapeXml(apiPath)}">

      <t:panel title="① 同期と非同期を 1 本ずつ"
               note="やっている仕事は同じです。違うのは「誰が待つか」だけ">
        <div class="form-row align-items-end mb-3">
          <div class="form-group col-sm-4">
            <label for="workMillis">待つ時間</label>
            <select class="form-control" id="workMillis">
              <option value="500">0.5 秒</option>
              <option value="1000">1 秒</option>
              <option value="2000" selected>2 秒</option>
              <option value="4000">4 秒</option>
            </select>
          </div>
          <div class="form-group col-sm-8">
            <button type="button" class="btn btn-outline-secondary mr-2" id="runSync">
              同期で 1 本（mode=sync）
            </button>
            <button type="button" class="btn btn-outline-primary" id="runAsync">
              非同期で 1 本（mode=async）
            </button>
          </div>
        </div>
        <p class="mb-0 text-muted small">
          ブラウザから見える時間はどちらもほぼ同じです。
          <strong>非同期にしても、その 1 本が速くなるわけではありません。</strong>
          違いは結果の表の「Servlet スレッド」と「仕事をしたスレッド」に出ます。
        </p>
      </t:panel>

      <t:panel title="② 制限時間を過ぎたとき（onTimeout）"
               note="仕事は 4 秒、制限時間は 1.5 秒">
        <button type="button" class="btn btn-outline-danger mb-3" id="runTimeout">
          時間切れを起こす（millis=4000 &amp; timeout=1500）
        </button>
        <p class="mb-0 text-muted small">
          <code>AsyncListener#onTimeout</code> が <code>503</code> で応答します。
          ここで何もしなければ、コンテナがエラー（500）で打ち切っていました。
          実際に返ってくるのは 1.5 秒<strong>の少しあと</strong>です
          （コンテナが時間切れを見回る間隔は 1 秒ほどあります）。
          なお<strong>仕事そのものは止まりません</strong>。
          応答を返したあとも、スレッドプールの中では残りの 2.5 秒が動き続けています。
        </p>
      </t:panel>

      <t:panel title="③ 同時に 6 本投げる"
               note="非同期にしても、仕事の総量は減りません">
        <div class="form-row align-items-end mb-3">
          <div class="form-group col-sm-5">
            <div class="form-check">
              <input class="form-check-input" type="radio" name="burstMode" id="burstAsync"
                     value="async" checked>
              <label class="form-check-label" for="burstAsync">
                非同期で 6 本（スレッド ${poolSize} 本のプールに投げる）
              </label>
            </div>
            <div class="form-check">
              <input class="form-check-input" type="radio" name="burstMode" id="burstSync"
                     value="sync">
              <label class="form-check-label" for="burstSync">
                同期で 6 本（コンテナのスレッドが直接処理する）
              </label>
            </div>
          </div>
          <div class="form-group col-sm-7">
            <button type="button" class="btn btn-outline-primary" id="runBurst">
              まとめて 6 本投げる
            </button>
          </div>
        </div>
        <p class="mb-0 text-muted small">
          非同期を選ぶと、3 本目以降の「順番待ち」が伸びていきます
          （スレッドは ${poolSize} 本しかないためです）。
          同期を選ぶと、コンテナのスレッド（既定で 200 本）が同時に処理するので
          待ち時間はほぼ出ませんが、そのあいだ<strong>他の画面のためのスレッドが減っています</strong>。
          どちらが良いかではなく、<strong>どこに上限を置くか</strong>の違いです。
        </p>
      </t:panel>

      <t:panel title="結果" note="新しいものが下に追加されます">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <p class="text-muted small mb-0" id="asyncStatus" aria-live="polite">
            まだ呼び出していません。
          </p>
          <button type="button" class="btn btn-sm btn-outline-secondary ml-3" id="clearResults">
            表を消す
          </button>
        </div>
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-0">
            <thead>
              <tr>
                <th style="width: 8rem;">見出し</th>
                <th style="width: 7rem;">方式</th>
                <th style="width: 4rem;">状態</th>
                <th style="width: 12rem;">Servlet スレッド</th>
                <th style="width: 10rem;">仕事をしたスレッド</th>
                <th style="width: 6rem;">順番待ち</th>
                <th style="width: 6rem;">サーバ全体</th>
                <th style="width: 6rem;">ブラウザ</th>
                <th>内容</th>
              </tr>
            </thead>
            <tbody id="asyncResults"></tbody>
          </table>
          <p class="text-muted small mt-2 mb-0" id="asyncEmpty">
            ボタンを押すと、ここに 1 行ずつ増えます。
          </p>
        </div>
      </t:panel>
    </div>

    <t:panel title="ブラウザ側の上限にも注意"
             note="サーバだけの話ではありません">
      <p class="mb-0">
        ブラウザは同じサーバへ同時につなげる本数を制限しています（多くは 6 本前後）。
        6 本まとめて投げるデモがちょうどその境目で、
        これ以上増やすと<strong>ブラウザ側で順番待ちが起きます</strong>。
        開発者ツール（F12）のネットワークタブで、各リクエストの
        「待機（Stalled / Queueing）」の時間を見ると分かります。
        サーバを非同期にしても、この上限は変わりません。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
