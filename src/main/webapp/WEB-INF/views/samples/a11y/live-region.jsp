<%--
  【サンプル】画面の変化を読み上げで知らせる（aria-live）

  Servlet を使わない、JSP だけのサンプルです。
  Ajax や JavaScript で画面の一部だけを書き換えたとき、
  その変化を画面を見ていない人にどう伝えるかを扱います。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="live-region">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>画面の一部だけが変わったとき、気づけない人がいる</h2>
    <p>
      ページ全体を読み込み直す画面なら、読み上げソフトは新しいページを最初から読みます。
      ところが Ajax で<strong>一部だけ</strong>書き換えると、
      スクリーンリーダーは何も言いません。利用者から見ると「ボタンを押したのに無反応」です。
    </p>
    <p>
      よくある例：
    </p>
    <ul>
      <li>検索ボタンを押して件数が変わった → <strong>何件になったか分からない</strong></li>
      <li>「保存しました」のトーストが 3 秒出て消えた → <strong>出たことに気づかない</strong></li>
      <li>一覧の行を削除した → <strong>消えたのかどうか分からない</strong></li>
      <li>読み込み中のぐるぐるが回っている → <strong>待たされていることが分からない</strong></li>
    </ul>
    <p>
      これを解決するのが<strong>ライブリージョン</strong>です。
      「この場所の中身が変わったら読み上げてください」と印を付けておく仕組みで、
      <strong>目に見える変化は何も起きません</strong>。属性を足すだけです。
    </p>

    <h2>2 種類だけ覚えればよい</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr>
            <th style="width: 26%;">書き方</th>
            <th>読まれ方</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>
              <code>role="status"</code><br>
              （＝ <code>aria-live="polite"</code>）
            </td>
            <td>
              <strong>今読んでいる内容が終わってから</strong>読みます。
              検索件数、保存完了、入力の残り文字数など<strong>ほとんどはこちら</strong>です
            </td>
          </tr>
          <tr>
            <td>
              <code>role="alert"</code><br>
              （＝ <code>aria-live="assertive"</code>）
            </td>
            <td>
              <strong>今読んでいる内容を中断して</strong>読みます。
              セッション切れ、通信エラー、送信の失敗など
              <strong>その場で手を止めてほしいときだけ</strong>使います
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <code>role</code> を書けば <code>aria-live</code> は要りません（暗黙で付きます）。
      迷ったら <code>role="status"</code> にします。
      <strong><code>assertive</code> を多用すると、入力中に何度も割り込まれて操作できなくなります。</strong>
    </p>

    <h2>いちばん大事な決まり：先に空の箱を置いておく</h2>
    <p>
      ライブリージョンは、<strong>ページを読み込んだ時点で存在していなければ動きません</strong>。
      読み上げソフトは「監視する場所」を最初に登録するためです。
    </p>
    <pre><code class="language-xml">&lt;!-- ✗ 動かない : 中身ごと後から差し込む --&gt;
&lt;div id="result"&gt;&lt;/div&gt;
&lt;script&gt;
  result.innerHTML = '&lt;p role="status"&gt;12 件見つかりました&lt;/p&gt;';
&lt;/script&gt;

&lt;!-- ✓ 動く : 箱は最初から置いて、中身だけ入れ替える --&gt;
&lt;p id="searchStatus" role="status"&gt;&lt;/p&gt;
&lt;script&gt;
  searchStatus.textContent = '12 件見つかりました';
&lt;/script&gt;</code></pre>
    <p>
      空の <code>&lt;p&gt;</code> を置いておくだけなので、見た目には何も出ません。
      Ajax の結果を差し込む場所の<strong>すぐ近くに用意しておく</strong>のが定石です。
    </p>

    <h2>気をつけること</h2>
    <ul>
      <li>
        <strong>同じ文字列を入れても読まれません。</strong>
        「12 件」の次にまた「12 件」だと、変化が無いので黙ったままです。
        件数が同じでも知らせたいときは「検索しました（12 件）」のように
        文言を変えるか、一度空にしてから入れ直します
      </li>
      <li>
        <strong>読み上げは最後まで待たされます。</strong>
        長い文章を入れると、利用者はその間操作できません。1 文で簡潔に書きます
      </li>
      <li>
        <strong>ライブリージョンを複数置きすぎない。</strong>
        あちこちが同時にしゃべると、何が起きたのか分からなくなります。
        画面に 1〜2 か所が目安です
      </li>
      <li>
        <strong>表示も一緒にやります。</strong>
        ライブリージョンは読み上げのための仕組みで、目で見ている人には何も起きません。
        件数は画面にも文字で出します（<code>.sr-only</code> にするのは、
        <strong>目で見れば分かる情報を、音でも伝え直すとき</strong>だけです）
      </li>
      <li>
        <strong>ページ全体を読み込み直したときは効きません。</strong>
        フォーム送信後のエラー表示のような場面では、
        <code>focus()</code> でフォーカスを移す方が確実です
        （<a href="${ctx}/samples/a11y/error-summary">エラーの伝え方</a>）
      </li>
    </ul>

    <h2>進捗と「読み込み中」</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 30%;">属性</th><th>使い方</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>role="progressbar"</code></td>
            <td>
              <code>aria-valuenow</code>（現在値）、<code>aria-valuemin</code>、
              <code>aria-valuemax</code>、<code>aria-label</code> を一緒に付けます。
              値を変えるたびに <code>aria-valuenow</code> も更新します
            </td>
          </tr>
          <tr>
            <td><code>aria-busy="true"</code></td>
            <td>
              「この範囲はまだ組み立て中です」と伝えます。
              読み込みが終わったら <code>false</code> に戻します。
              途中経過を細切れに読まれるのを防げます
            </td>
          </tr>
          <tr>
            <td><code>aria-hidden="true"</code></td>
            <td>
              ぐるぐる回るアイコンなど、<strong>音では意味を持たない装飾</strong>に付けて、
              読み上げの対象から外します
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      進捗そのものより、<strong>「終わったこと」を伝える方が大事</strong>です。
      パーセントを逐一読み上げると邪魔になるので、
      開始と完了だけ <code>role="status"</code> で伝えるのが現実的です。
    </p>

    <h2>このサイトでの実例</h2>
    <ul>
      <li>
        <a href="${ctx}/samples/ajax/ajax-search">インクリメンタルサーチ</a> …
        検索結果の件数を <code>aria-live</code> で伝えています
      </li>
      <li>
        <a href="${ctx}/samples/ajax/ajax-polling">処理の進捗をポーリングで取得する</a> …
        進捗バーの更新
      </li>
      <li>
        <a href="${ctx}/samples/form/realtime-validation">入力チェック（フォーカスアウト時）</a> …
        入力中の割り込みを避けるため <code>polite</code> を使っています
      </li>
    </ul>

    <h2>確かめ方</h2>
    <p>
      読み上げソフトを入れなくても、<strong>デモタブの「読み上げの中身を見る」</strong>で、
      何が読まれるはずかを文字で確認できます。
      実際の読み上げを聞くなら、Windows なら
      <kbd>Ctrl</kbd> + <kbd>Windows</kbd> + <kbd>Enter</kbd> でナレーターを起動できます。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // ライブリージョンのデモ。
      // 実際の読み上げは目に見えないので、「読み上げの記録」にも同じ文言を残しています。
      (function () {
        'use strict';

        var log = document.getElementById('speechLog');

        /** 読み上げソフトが読むはずの内容を、目で見えるように記録します。 */
        function record(kind, text) {
          if (!log) {
            return;
          }
          var item = document.createElement('li');
          var badge = document.createElement('span');
          badge.className = 'badge ' + (kind === 'alert' ? 'badge-danger' : 'badge-info') + ' mr-2';
          badge.textContent = kind === 'alert' ? '割り込んで読む' : '順番が来たら読む';
          item.appendChild(badge);
          // 受け取った文字列は textContent で入れます (innerHTML に入れると XSS になります)
          item.appendChild(document.createTextNode(text));
          log.insertBefore(item, log.firstChild);

          while (log.children.length > 6) {
            log.removeChild(log.lastChild);
          }
        }

        // ---------------- ① 件数の更新 (role="status") ----------------
        var counts = [12, 3, 0, 148];
        var countIndex = 0;

        var searchButton = document.getElementById('searchButton');
        var searchStatus = document.getElementById('searchStatus');
        var searchList = document.getElementById('searchList');
        var searchStatusNone = document.getElementById('searchStatusNone');

        if (searchButton) {
          searchButton.addEventListener('click', function () {
            var count = counts[countIndex % counts.length];
            countIndex += 1;

            var text = count === 0
              ? '条件に一致する取引先はありませんでした。条件を変えて検索してください。'
              : count + ' 件の取引先が見つかりました。';

            // 箱は最初から置いてあるので、中身だけ入れ替えます
            searchStatus.textContent = text;
            searchList.textContent = count === 0 ? '（該当なし）' : '（ここに ' + count + ' 件の一覧が入ります）';

            // 比較用: aria-live を付けていない方。画面は変わりますが読み上げられません
            searchStatusNone.textContent = text;

            record('status', text);
          });
        }

        // ---------------- ② エラー (role="alert") ----------------
        var errorButton = document.getElementById('errorButton');
        var errorStatus = document.getElementById('errorStatus');

        if (errorButton) {
          errorButton.addEventListener('click', function () {
            var text = 'サーバに接続できませんでした。少し待ってから、もう一度お試しください。';
            errorStatus.textContent = text;
            errorStatus.classList.remove('d-none');
            record('alert', text);
          });
        }

        // ---------------- ③ 進捗 (role="progressbar" と aria-busy) ----------------
        var jobButton = document.getElementById('jobButton');
        var jobArea = document.getElementById('jobArea');
        var jobBar = document.getElementById('jobBar');
        var jobStatus = document.getElementById('jobStatus');
        var jobTimer = null;

        if (jobButton) {
          jobButton.addEventListener('click', function () {
            if (jobTimer) {
              return;
            }
            var percent = 0;

            jobButton.disabled = true;
            // 組み立て中は aria-busy="true" にして、途中経過が細切れに読まれるのを防ぎます
            jobArea.setAttribute('aria-busy', 'true');

            // 開始を伝えます (進捗の数字そのものは読み上げません)
            jobStatus.textContent = '集計を開始しました。しばらくお待ちください。';
            record('status', '集計を開始しました。しばらくお待ちください。');

            jobTimer = window.setInterval(function () {
              percent += 10;

              jobBar.style.width = percent + '%';
              jobBar.textContent = percent + '%';
              // 見た目の幅だけでなく、aria-valuenow も必ず一緒に更新します
              jobBar.setAttribute('aria-valuenow', String(percent));

              if (percent >= 100) {
                window.clearInterval(jobTimer);
                jobTimer = null;

                jobArea.setAttribute('aria-busy', 'false');
                jobButton.disabled = false;

                var done = '集計が終わりました。148 件を処理しました。';
                jobStatus.textContent = done;
                record('status', done);
              }
            }, 300);
          });
        }
      })();
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <div class="alert alert-info" role="alert">
      ライブリージョンは<strong>目には見えません</strong>。
      そこで、読み上げソフトが読むはずの内容を、一番下の「読み上げの記録」に文字で残しています。
      スクリーンリーダーを使える環境なら、そのまま聞き比べてみてください。
    </div>

    <t:panel title="① 件数が変わったことを伝える（role=&quot;status&quot;）"
             note="ボタンを押すたびに件数が変わります">
      <button type="button" class="btn btn-primary mb-3" id="searchButton">検索する</button>

      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：ただ書き換えるだけ</span>
            <p class="mb-0" id="searchStatusNone">（まだ検索していません）</p>
            <p class="small mt-3 mb-0">
              画面は変わりますが、読み上げソフトは<strong>何も言いません</strong>。
              ボタンを押した人には、成功したのか失敗したのかも分かりません。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：role="status" を付けた</span>
            <p class="mb-0" id="searchStatus" role="status">（まだ検索していません）</p>
            <p class="small mt-3 mb-0">
              中身が変わった瞬間に読み上げられます。
              <strong>目で見える表示はまったく同じ</strong>です。
            </p>
          </div>
        </div>
      </div>

      <div class="border rounded p-3 mt-1" id="searchList">（ここに一覧が入ります）</div>
      <span class="a11y-attr">&lt;p id="searchStatus" role="status"&gt;&lt;/p&gt; を、結果の一覧のすぐ上に置いています</span>
    </t:panel>

    <t:panel title="② 手を止めてほしいことを伝える（role=&quot;alert&quot;）"
             note="通信エラーやセッション切れなど、そのままでは作業が無駄になる場面だけで使います">
      <button type="button" class="btn btn-outline-danger mb-3" id="errorButton">
        通信エラーを起こす
      </button>
      <div class="alert alert-danger d-none mb-2" id="errorStatus" role="alert"></div>
      <span class="a11y-attr">role="alert"（= aria-live="assertive"）… 読み上げ中の内容に割り込みます</span>
      <p class="small text-muted mt-3 mb-0">
        入力中に割り込まれると操作できなくなるため、<strong>使う場面を絞ります</strong>。
        「保存しました」のような通知は <code>role="status"</code> です。
      </p>
    </t:panel>

    <t:panel title="③ 時間のかかる処理（progressbar と aria-busy）"
             note="パーセントは読み上げず、開始と完了だけを伝えます">
      <button type="button" class="btn btn-primary mb-3" id="jobButton">集計を開始する</button>

      <div id="jobArea" aria-busy="false">
        <div class="progress mb-2" style="height: 1.5rem;">
          <div class="progress-bar" id="jobBar" role="progressbar"
               style="width: 0%;" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"
               aria-label="集計の進捗">0%</div>
        </div>
        <p class="mb-0" id="jobStatus" role="status">（待機中）</p>
      </div>

      <span class="a11y-attr">
        role="progressbar" aria-valuenow / aria-valuemin / aria-valuemax / aria-label、
        囲みに aria-busy
      </span>
      <ul class="small text-muted mt-3 mb-0">
        <li>幅（<code>style="width"</code>）だけ変えて <code>aria-valuenow</code> を忘れると、読み上げでは 0% のままです</li>
        <li>処理中は <code>aria-busy="true"</code> にして、途中経過が細切れに読まれるのを防ぎます</li>
        <li>ボタンは処理中 <code>disabled</code> にして、二重に押されないようにします</li>
      </ul>
    </t:panel>

    <t:panel title="読み上げの記録"
             note="上のボタンを押すと、読み上げソフトが読むはずの内容がここに積まれます（新しいものが上）">
      <ul class="list-unstyled mb-0" id="speechLog">
        <li class="text-muted">（まだ何も起きていません）</li>
      </ul>
    </t:panel>

    <t:panel title="使い分けの早見表">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th style="width: 34%;">場面</th>
              <th style="width: 26%;">使うもの</th>
              <th>理由</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>検索の件数が変わった</td>
              <td><code>role="status"</code></td>
              <td>急ぎではないので、読み終わってからで十分です</td>
            </tr>
            <tr>
              <td>「保存しました」のトースト</td>
              <td><code>role="status"</code></td>
              <td>消える表示なので、音でも伝えないと気づけません</td>
            </tr>
            <tr>
              <td>入力チェックのエラー（フォーカスアウト時）</td>
              <td><code>role="status"</code></td>
              <td>入力の途中で割り込むと、かえって操作しづらくなります</td>
            </tr>
            <tr>
              <td>通信エラー・セッション切れ</td>
              <td><code>role="alert"</code></td>
              <td>そのまま続けても作業が無駄になるので、すぐ止めてもらいます</td>
            </tr>
            <tr>
              <td>フォーム送信後のエラー一覧（画面ごと再表示）</td>
              <td><code>focus()</code> を使う</td>
              <td>読み込み直後のライブリージョンは読まれないことがあります</td>
            </tr>
            <tr>
              <td>モーダルを開いた</td>
              <td>フォーカスを移す</td>
              <td>読み上げるだけでなく、操作の起点も移す必要があります</td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>
  </jsp:body>
</t:sample>
