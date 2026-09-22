<%--
  【サンプル】マウスを使わずに操作する

  Servlet を使わない、JSP だけのサンプルです。
  Tab キーだけで画面を一周できるか、という観点でまとめています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="keyboard-operation">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>キーボードだけで使えることが、なぜ土台なのか</h2>
    <p>
      スクリーンリーダー、音声入力、スイッチ（大きなボタン 1 つで操作する装置）、
      視線入力──支援技術のほとんどは、内部的には<strong>キーボード操作として画面を触ります</strong>。
      つまり<strong>キーボードで操作できない機能は、支援技術からも操作できません</strong>。
    </p>
    <p>
      腱鞘炎でマウスが使えない期間、ノートパソコンのタッチパッドが壊れたとき、
      入力作業に慣れて「マウスに手を伸ばす時間が惜しい」人──
      キーボード操作は、そうした日常的な場面でも使われます。
    </p>

    <h2>Tab で止まる要素・止まらない要素</h2>
    <p>
      ブラウザは<strong>操作できる要素</strong>だけを Tab の順番に入れます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 40%;">止まる（最初から）</th><th>止まらない</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>
              <code>&lt;a href="…"&gt;</code>、<code>&lt;button&gt;</code>、
              <code>&lt;input&gt;</code>、<code>&lt;select&gt;</code>、<code>&lt;textarea&gt;</code>、
              <code>&lt;summary&gt;</code>
            </td>
            <td>
              <code>&lt;div&gt;</code>、<code>&lt;span&gt;</code>、<code>&lt;p&gt;</code>、
              <code>&lt;a&gt;</code>（<code>href</code> なし）、
              <code>disabled</code> が付いた部品
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <strong><code>&lt;div onclick="…"&gt;</code> でボタンを作ると、ここから漏れます。</strong>
      Tab でたどり着けず、Enter でも Space でも反応せず、
      読み上げでも「ボタン」とは伝わりません。
      <strong><code>&lt;button type="button"&gt;</code> と書けば、全部ただで付いてきます。</strong>
    </p>

    <h2><code>&lt;button&gt;</code> と <code>&lt;a&gt;</code> の使い分け</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 24%;"></th><th><code>&lt;button&gt;</code></th><th><code>&lt;a href&gt;</code></th></tr>
        </thead>
        <tbody>
          <tr>
            <td>使うとき</td>
            <td>その場で<strong>何かが起きる</strong>（送信、開く、計算する）</td>
            <td><strong>移動する</strong>（別の画面、ページ内の別の場所）</td>
          </tr>
          <tr>
            <td>キー</td>
            <td>Enter と Space の<strong>両方</strong>で動く</td>
            <td>Enter だけ</td>
          </tr>
          <tr>
            <td>読み上げ</td>
            <td>「ボタン」</td>
            <td>「リンク」</td>
          </tr>
          <tr>
            <td>右クリック</td>
            <td>—</td>
            <td>「新しいタブで開く」が使える</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      見た目は CSS で揃えられます（Bootstrap なら <code>&lt;a class="btn"&gt;</code>）。
      <strong>見た目ではなく、押した後に何が起きるかで選びます。</strong>
      なお <code>&lt;form&gt;</code> の中の <code>&lt;button&gt;</code> は既定で
      <code>type="submit"</code> になるため、送信したくないボタンには
      必ず <code>type="button"</code> を書きます。
    </p>

    <h2><code>tabindex</code> の使い分け</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 22%;">値</th><th>意味と使いどころ</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>tabindex="0"</code></td>
            <td>
              Tab の順番に<strong>HTML に書いた位置で</strong>加えます。
              自作の部品（タブ、ツリー）を操作可能にするときに使います。
              まずは <code>&lt;button&gt;</code> で済まないかを考えます
            </td>
          </tr>
          <tr>
            <td><code>tabindex="-1"</code></td>
            <td>
              Tab では止まらないが、<strong>JavaScript の <code>focus()</code> でなら
              フォーカスできる</strong>状態にします。
              エラーサマリ、モーダル、「本文へスキップ」の飛び先に付けます
            </td>
          </tr>
          <tr>
            <td><code>tabindex="1"</code> 以上</td>
            <td>
              <strong>使いません。</strong>
              正の値を付けた要素が<strong>ページ内のどこにあっても先頭グループ</strong>に集まるため、
              1 か所に付けただけで画面全体の順番が壊れます
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>Tab の順番は HTML の順番</h2>
    <p>
      Tab は<strong>HTML に書いた順</strong>に進みます。見た目の位置ではありません。
      CSS（<code>float</code>、<code>order</code>、<code>position</code>、Bootstrap の
      <code>order-md-*</code>）で<strong>見た目だけ並べ替えると、
      見えている順序と Tab の順序がずれます</strong>。
    </p>
    <p>
      並べ替えたくなったら、まず HTML の順番そのものを直せないかを考えます。
    </p>

    <h2>フォーカスの枠を消さない</h2>
    <p>
      <code>outline: none;</code> は、キーボード利用者にとって
      <strong>マウスポインタを消すのと同じこと</strong>です。今どこにいるのか分からなくなります。
    </p>
    <p>
      「マウスで押したときに枠が出るのが気になる」という理由で消されることが多いので、
      その場合は <code>:focus-visible</code> を使います。
      <strong>ブラウザが「キーボード操作だ」と判断したときだけ</strong>枠を出す疑似クラスです。
    </p>
    <pre><code class="language-css">/* 既定の枠を自分の色に置き換える */
.btn:focus-visible {
  outline: 3px solid #2b5fd9;
  outline-offset: 2px;
}

/* 古いブラウザ向けに、:focus で出して :focus-visible でないときだけ消す */
.btn:focus:not(:focus-visible) {
  outline: none;
}</code></pre>
    <p>
      WCAG 2.2 の達成基準 2.4.11「フォーカスの外観」では、
      フォーカス表示の<strong>太さと色のコントラスト</strong>にも基準があります。
      細い点線では足りないことがあるので、<strong>2px 以上の実線</strong>にしておくと安全です。
    </p>

    <h2>「本文へスキップ」リンク</h2>
    <p>
      ヘッダーにリンクが 20 個あると、キーボード利用者は<strong>ページを開くたびに
      20 回 Tab を押してから</strong>本文にたどり着きます。
      画面が変わるたびに繰り返すので、かなりの負担です。
    </p>
    <p>
      そこで <code>&lt;body&gt;</code> の直後に、本文へのリンクを置きます。
      普段は見えず、<strong>Tab を 1 回押したときだけ現れます</strong>。
      このサイトでも入れてあるので、<strong>どの画面でも Tab を 1 回押せば左上に出てきます</strong>。
    </p>
    <pre><code class="language-xml">&lt;body&gt;
&lt;a class="sr-only sr-only-focusable skip-link" href="#main-content"&gt;本文へスキップ&lt;/a&gt;
  …
&lt;main id="main-content" tabindex="-1"&gt; … &lt;/main&gt;</code></pre>
    <ul>
      <li>
        <code>.sr-only</code>（Bootstrap 4）… 画面には出さないが読み上げの対象にする
      </li>
      <li>
        <code>.sr-only-focusable</code> … フォーカスが当たったときだけ見えるようにする。
        位置と色は <code>app.css</code> の <code>.skip-link</code> で足しています
      </li>
      <li>
        飛び先の <code>&lt;main&gt;</code> に <code>tabindex="-1"</code> が要ります。
        付けないと画面はスクロールしても<strong>フォーカスはヘッダーに残ったまま</strong>で、
        次の Tab がまたヘッダーの続きから始まってしまいます
      </li>
    </ul>

    <h2>モーダルを開いたときの決まりごと</h2>
    <ol>
      <li>開いたらモーダルの中へフォーカスを移す</li>
      <li>Tab がモーダルの外へ出ないようにする（フォーカストラップ）</li>
      <li>Esc で閉じられるようにする</li>
      <li><strong>閉じたら、開くのに使ったボタンへフォーカスを戻す</strong></li>
    </ol>
    <p>
      4 を忘れると、閉じた瞬間にフォーカスがページ先頭へ飛び、
      キーボード利用者は<strong>また最初から Tab を押し直す</strong>ことになります。
    </p>
    <p>
      Bootstrap 4 のモーダルは、この 4 つを自分でやってくれます。
      こちらで書くのは <code>role="dialog"</code>、<code>aria-modal="true"</code>、
      <code>aria-labelledby</code>（見出しの <code>id</code>）、<code>tabindex="-1"</code> だけです。
      <strong>自前でモーダルを作るときは、4 つとも自分で実装することになります</strong>ので、
      まず既存の部品で済ませられないかを考えます
      （<a href="${ctx}/samples/design/modal-dialog">モーダルの出し方 6 パターン</a>）。
    </p>

    <h2>チェックの仕方</h2>
    <p>
      <strong>マウスから手を離して、Tab だけで画面を一周します。</strong>
      特別な道具は要りません。次の 5 つが確かめられれば十分です。
    </p>
    <ol>
      <li>すべての操作（送信、削除、モーダルを開く、表の並び替え）にたどり着けるか</li>
      <li>今どこにフォーカスがあるか、<strong>常に見えているか</strong></li>
      <li>順番が画面の見た目と合っているか</li>
      <li>フォーカスが<strong>画面の外に消えない</strong>か（非表示の要素に入り込んでいないか）</li>
      <li>モーダルを閉じた後、元の場所に戻るか</li>
    </ol>
    <p>
      macOS の Safari では、標準設定のままだと Tab がリンクで止まりません。
      「設定 &gt; 詳細 &gt; Tab キーを押したときに Web ページ上の各項目を強調表示」を有効にしてから試します。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // 今どこにフォーカスがあるかを画面に出します (自分の画面を点検するための道具です)。
      (function () {
        'use strict';

        var output = document.getElementById('focusWatch');
        if (!output) {
          return;
        }

        function describe(element) {
          if (!element || element === document.body) {
            return '（どこにもありません）';
          }
          var text = element.tagName.toLowerCase();
          if (element.type) {
            text += '[type=' + element.type + ']';
          }
          if (element.id) {
            text += '#' + element.id;
          }
          var label = (element.textContent || element.value || '').trim();
          if (label) {
            text += ' … ' + label.substring(0, 24);
          }
          return text;
        }

        // focusin はバブリングするので、ページ全体をここで拾えます
        document.addEventListener('focusin', function (event) {
          // 受け取った文字列は textContent で入れます (innerHTML に入れると XSS になります)
          output.textContent = describe(event.target);
        });
      })();

      // 「div をボタンにした悪い例」が、クリックでは動くことを示します。
      (function () {
        'use strict';

        var fake = document.getElementById('fakeButton');
        var real = document.getElementById('realButton');
        var log = document.getElementById('buttonLog');
        if (!fake || !real || !log) {
          return;
        }

        function press(name) {
          log.textContent = name + ' が押されました（' + new Date().toLocaleTimeString() + '）';
        }

        fake.addEventListener('click', function () {
          press('div のボタン');
        });
        real.addEventListener('click', function () {
          press('button のボタン');
        });
      })();
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <div class="alert alert-info" role="alert">
      <strong>マウスから手を離してください。</strong>
      ここから下は <kbd>Tab</kbd>（戻るときは <kbd>Shift</kbd> + <kbd>Tab</kbd>）、
      <kbd>Enter</kbd>、<kbd>Space</kbd>、<kbd>Esc</kbd> だけで操作できます。
      できないものがあれば、それがこのページの「悪い例」です。
    </div>

    <t:panel title="今どこにフォーカスがあるか"
             note="Tab を押すたびに、フォーカスされている要素をここに出します">
      <p class="mb-2">
        現在のフォーカス：
        <code id="focusWatch" class="a11y-attr d-inline">（どこにもありません）</code>
      </p>
      <p class="mb-0 small text-muted">
        <kbd>Tab</kbd> を押し続けて、このページの操作を全部たどれるか試してください。
        <strong>止まってほしいのに飛ばされる要素</strong>があれば、それが問題です。
      </p>
    </t:panel>

    <t:panel title="div をボタンにすると、キーボードから使えなくなる"
             note="両方をマウスでクリックしてから、Tab でたどってみてください">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：&lt;div onclick&gt;</span>
            <div id="fakeButton" class="btn btn-danger">再計算する</div>
            <ul class="small mt-3 mb-0">
              <li>Tab でたどり着けません</li>
              <li>Enter でも Space でも動きません</li>
              <li>読み上げでは「再計算する」という<strong>ただの文字</strong>です</li>
            </ul>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：&lt;button type="button"&gt;</span>
            <button type="button" id="realButton" class="btn btn-success">再計算する</button>
            <ul class="small mt-3 mb-0">
              <li>Tab で止まります</li>
              <li>Enter でも Space でも動きます</li>
              <li>読み上げでは「再計算する、ボタン」と伝わります</li>
            </ul>
          </div>
        </div>
      </div>
      <p class="mb-0">
        押された結果：<code id="buttonLog" class="a11y-attr d-inline">（まだ押されていません）</code>
      </p>
    </t:panel>

    <t:panel title="フォーカスの枠を消さない"
             note="3 つのボタンを、マウスでクリックした場合と Tab で移動した場合で見比べてください">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：outline を消した</span>
            <button type="button" class="btn btn-outline-danger a11y-focus-none">枠が出ない</button>
            <p class="small mt-3 mb-0">
              Tab で来ても、ここにいることが分かりません。
              <code>outline: none;</code> だけを書くと、こうなります。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case">
            <span class="a11y-case__label">△ 既定のまま</span>
            <button type="button" class="btn btn-outline-secondary">ブラウザ既定</button>
            <p class="small mt-3 mb-0">
              消していないので問題はありません。
              ただし背景色によっては見づらいことがあります。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：:focus-visible</span>
            <button type="button" class="btn btn-outline-success a11y-focus-visible">
              キーボードのときだけ
            </button>
            <p class="small mt-3 mb-0">
              マウスでクリックしたときは出ず、<strong>Tab で来たときだけ</strong>太い枠が出ます。
            </p>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="Tab の順番は、見た目ではなく HTML の順番"
             note="Tab を押して、左から右に進むか確かめてください">
      <p class="font-weight-bold small mb-2">✗ 悪い例：CSS で見た目だけ並べ替えた</p>
      <div class="row a11y-taborder mb-3">
        <div class="col-4 order-3">
          <button type="button" class="btn btn-outline-danger btn-block">① 画面では 3 番目</button>
        </div>
        <div class="col-4 order-1">
          <button type="button" class="btn btn-outline-danger btn-block">② 画面では 1 番目</button>
        </div>
        <div class="col-4 order-2">
          <button type="button" class="btn btn-outline-danger btn-block">③ 画面では 2 番目</button>
        </div>
      </div>
      <p class="small text-muted">
        HTML には ①→②→③ の順に書いてありますが、<code>order-*</code> で見た目を入れ替えたため、
        Tab は<strong>画面の真ん中 → 右 → 左</strong>という順に飛びます。
      </p>

      <p class="font-weight-bold small mb-2 mt-4">✓ 良い例：HTML の順番と見た目を揃えた</p>
      <div class="row a11y-taborder mb-0">
        <div class="col-4">
          <button type="button" class="btn btn-outline-success btn-block">① 1 番目</button>
        </div>
        <div class="col-4">
          <button type="button" class="btn btn-outline-success btn-block">② 2 番目</button>
        </div>
        <div class="col-4">
          <button type="button" class="btn btn-outline-success btn-block">③ 3 番目</button>
        </div>
      </div>
    </t:panel>

    <t:panel title="本文へスキップ"
             note="この画面の一番上で Tab を 1 回押すと、左上に現れます">
      <p>
        このサイトの全画面に入っています。ページを開いた直後に <kbd>Tab</kbd> を 1 回押すと
        「本文へスキップ」が左上に出てきて、<kbd>Enter</kbd> で本文の先頭へ飛べます。
        ヘッダーのリンクを全部たどらなくて済みます。
      </p>
      <p class="mb-0">
        実装は <code>WEB-INF/tags/layout.tag</code> と <code>assets/css/app.css</code> にあります
        （ソースコードのタブで見られます）。
      </p>
    </t:panel>

    <t:panel title="モーダルを開いて、Esc で閉じてみる"
             note="閉じたあと、フォーカスが「開く」ボタンに戻ることを確認してください">
      <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#kbModal">
        確認ダイアログを開く
      </button>

      <div class="modal fade" id="kbModal" tabindex="-1" role="dialog"
           aria-modal="true" aria-labelledby="kbModalTitle" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="kbModalTitle">削除の確認</h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p class="mb-0">
                この中で <kbd>Tab</kbd> を押し続けてください。
                フォーカスはモーダルの外へ出ず、ぐるぐる回ります（フォーカストラップ）。
              </p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-dismiss="modal">キャンセル</button>
              <button type="button" class="btn btn-danger" data-dismiss="modal">削除する</button>
            </div>
          </div>
        </div>
      </div>

      <ul class="small mt-3 mb-0">
        <li>開くと、フォーカスがモーダルの中へ移ります</li>
        <li><kbd>Tab</kbd> はモーダルの中だけを回ります</li>
        <li><kbd>Esc</kbd> で閉じられます</li>
        <li>閉じると、<strong>「確認ダイアログを開く」ボタンにフォーカスが戻ります</strong></li>
      </ul>
    </t:panel>

    <t:panel title="リンクとボタンを使い分ける">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：移動なのにボタン</span>
            <button type="button" class="btn btn-outline-danger"
                    onclick="window.location.href='${ctx}/samples/a11y/form-labels';">
              ラベルのサンプルへ
            </button>
            <p class="small mt-3 mb-0">
              右クリックで「新しいタブで開く」ができません。
              リンク先が分からず、読み上げでも「ボタン」と伝わります。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：移動はリンク</span>
            <a class="btn btn-outline-success" href="${ctx}/samples/a11y/form-labels">
              ラベルのサンプルへ
            </a>
            <p class="small mt-3 mb-0">
              見た目はボタンのままで、中身はリンクです。
              新しいタブで開けて、読み上げでも「リンク」と伝わります。
            </p>
          </div>
        </div>
      </div>
    </t:panel>
  </jsp:body>
</t:sample>
