<%--
  【サンプル】インクリメンタルサーチ (入力するたびに検索)

  キーワード欄に文字を打つたびに JSON API を呼び、候補を出します。
  見どころは「投げすぎない (debounce)」と「古い応答で新しい結果を上書きしない」の 2 つです。

  AjaxSearchServlet が次の値をセットします。
    apiPath          … 候補を返す API の URL
    debounceMillis   … 入力が止まってから検索するまでの待ち時間
    minKeywordLength … 検索を始める最低文字数
    suggestLimit     … 候補として返す件数の上限
    categories       … 絞り込み用のカテゴリ一覧
    allCount         … 商品の総件数 (説明用)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="ajax-search">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>処理の流れ</h2>
    <ol>
      <li>キーワード欄に 1 文字打たれる（<code>input</code> イベント）</li>
      <li>
        すぐには検索せず、<strong>${debounceMillis} ms のタイマーを仕掛ける</strong>。
        その間にまた打たれたら、前のタイマーを取り消して掛け直す（debounce）
      </li>
      <li>
        入力が止まってタイマーが満了したら、<strong>前のリクエストを中断</strong>してから
        <code>fetch</code> で <code>/samples/ajax/ajax-search/api?q=...</code> を呼ぶ
      </li>
      <li>
        Servlet は一覧サンプルと同じ <code>ProductSearch</code> / <code>ProductDao</code> で検索し、
        <strong>上位 ${suggestLimit} 件</strong>と<strong>該当した総件数</strong>を JSON で返す
      </li>
      <li>
        画面は応答の<strong>通し番号</strong>を見て、古い応答なら捨てる。
        新しければ候補を描き直し、「◯ 件見つかりました」を出す
      </li>
      <li>↑ ↓ で候補を選び、Enter かクリックで確定して入力欄に商品名を入れる</li>
    </ol>

    <h2>1 文字ごとに投げない（debounce）</h2>
    <p>
      <code>input</code> イベントは打鍵のたびに発生します。
      そのまま検索すると「ボールペン」の 6 文字で 6 回リクエストが飛び、
      しかも<strong>使うのは最後の 1 回の結果だけ</strong>です。
      そこで「入力が止まったら投げる」という間合いを作ります。
    </p>
<pre><code class="language-javascript">var timerId = null;

input.addEventListener('input', function () {
  clearTimeout(timerId);              // 前に仕掛けたタイマーを取り消す
  timerId = setTimeout(function () {  // 入力が止まって ${debounceMillis} ms 後に動く
    search(input.value.trim());
  }, ${debounceMillis});
});</code></pre>
    <p>待ち時間は短すぎても長すぎても具合が悪くなります。目安は次のとおりです。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>待ち時間</th><th>使い心地</th><th>向いている場面</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>0 ms（毎回投げる）</td>
            <td>いちばん速い。ただし「abcde」で 5 回飛ぶ</td>
            <td>サーバに行かず、手元に持っている一覧を絞るだけのとき</td>
          </tr>
          <tr>
            <td>150 〜 200 ms</td>
            <td>待たされた感じはほぼ無い</td>
            <td>応答が速い API、候補が軽いとき</td>
          </tr>
          <tr>
            <td>300 ms 前後</td>
            <td>打ち終わってから出る。標準的</td>
            <td>たいていの検索欄（このサンプルもここ）</td>
          </tr>
          <tr>
            <td>500 ms 以上</td>
            <td>「反応が鈍い」と感じ始める</td>
            <td>重い検索。負荷をどうしても抑えたいとき</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      よく似たものに throttle（間引き）があります。
      <strong>debounce は「止まったら最後の 1 回だけ」</strong>、
      <strong>throttle は「一定間隔で少しずつ」</strong>です。
      検索候補で欲しいのは最後に打った内容に対する答えだけなので、debounce が向いています
      （スクロールに追従する処理のように、途中経過も要るものは throttle です）。
    </p>

    <h2>遅い応答が後から返ってくる（競合）</h2>
    <p>
      debounce を入れても、リクエストが 2 本以上飛ぶことはあります。
      そして <strong>HTTP の応答は送った順に返るとは限りません</strong>。
      たとえば「ペ」の検索が混み合って遅れ、あとから投げた「ペン」の結果が先に返ると、こうなります。
    </p>
<pre><code class="language-plaintext">時刻 →

「ペ」で検索   ●━━━━━━━━━━━━━━━━━━▶ 応答（7 件）   ← 遅れて到着
「ペン」で検索        ●━━━━━▶ 応答（3 件）
                             ↑ 一度は「ペン」の結果が出るが、
                               そのあと「ペ」の結果で上書きされてしまう</code></pre>
    <p>
      画面には「ペン」と表示されているのに候補は「ペ」のもの、という状態です。
      再現しにくく、原因も分かりにくい種類の不具合です。
      デモの「サーバをわざと遅くする」と「競合対策を切る」を両方入れて、
      <code>ペ</code> → <code>ン</code> とゆっくり打つと、この現象をその場で起こせます。
    </p>
    <p>対策は 2 つあり、<strong>両方入れておく</strong>のが確実です。</p>
<pre><code class="language-javascript">var controller = null;   // いま飛んでいるリクエストを中断するためのもの
var sentSeq = 0;         // 送った通し番号
var shownSeq = 0;        // 画面に出した応答の通し番号

function search(keyword) {
  if (controller) { controller.abort(); }   // ① 前のリクエストを中断する
  controller = new AbortController();
  var seq = ++sentSeq;                      // ② このリクエストに通し番号を振る

  fetch(url, {signal: controller.signal})
    .then(function (res) {
      // fetch は 404 でも 500 でも失敗にならない。自分で確かめる
      if (!res.ok) { throw new Error('サーバが ' + res.status + ' を返しました'); }
      return res.json();
    })
    .then(function (data) {
      if (seq &lt; shownSeq) { return; }       // ③ 古い応答なら捨てる
      shownSeq = seq;
      render(data);
    })
    .catch(function (e) {
      if (e.name === 'AbortError') { return; }   // ④ 中断は「失敗」ではない
      showError(e);
    });
}</code></pre>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>やり方</th><th>効くこと</th><th>限界</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>AbortController</code> で中断</td>
            <td>古い応答をそもそも受け取らない。無駄な通信と描画が減る</td>
            <td>
              中断が間に合わず応答が届くことはある。
              また<strong>サーバ側の処理は止まらない</strong>（負荷は減らない）
            </td>
          </tr>
          <tr>
            <td>通し番号で古い応答を捨てる</td>
            <td>届いてしまった古い応答を確実に無視できる</td>
            <td>通信そのものは流れる。中断ほど無駄は減らない</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <code>catch</code> で <code>AbortError</code> を分けるのを忘れないでください。
      中断は自分で行った正常な操作なので、
      これを拾わないと<strong>打鍵のたびに「検索できませんでした」が出ます</strong>。
    </p>

    <h2>空なら検索しない・最低文字数を決める</h2>
    <p>
      入力欄が空になったとき、<code>q=</code> で検索してはいけません。全件が該当します。
      このサンプルでは<strong>${minKeywordLength} 文字以上</strong>で検索を始め、
      それより短くなったら候補を閉じ、飛んでいるリクエストも中断しています。
    </p>
    <ul>
      <li><strong>日本語は 1 文字でも絞り込める</strong>ので 1 文字から始めてよい場面が多いです</li>
      <li>
        <strong>英数字が中心のデータなら 2 〜 3 文字</strong>にします。
        「a」で検索されると、ほぼ全件が該当してしまいます
      </li>
      <li>
        <strong>同じ判定をサーバ側にも書く</strong>：画面の判断は信用しません。
        <code>/api?q=</code> は URL を打てば誰でも直接呼べます
      </li>
    </ul>
<pre><code class="language-java">// サーバ側。短すぎるなら DB を見ずに、空の結果を同じ形で返す
if (!isSearchable(keyword)) {
    Json.write(response, skipped(keyword, elapsedMillis(startedAt)));
    return;
}</code></pre>
    <p>
      文字数は <code>length()</code> ではなく符号位置で数えています。
      <code>length()</code> は UTF-16 の単位数なので、絵文字や一部の漢字が 2 文字と数えられ、
      画面に書いた「◯ 文字以上」と食い違います。
    </p>
    <p>
      整えたキーワードは、<strong>画面に返す値と、実際に検索する値の両方に使います</strong>。
      このサンプルの <code>ProductSearch</code> は一覧画面と共用していて、中では
      <code>trim()</code> で整えています。<code>trim()</code> は全角スペースを落とさないので、
      受け取ったままのリクエストを渡すと
      「<code>q</code> には『ペン』と答えているのに、検索したのは『（全角スペース）ペン』で 0 件」
      というねじれが起きます。共用している部品は書き換えず、
      <code>HttpServletRequestWrapper</code> で <code>q</code> の読み取りだけを差し替えています。
    </p>
<pre><code class="language-java">// 共有の ProductSearch には手を入れず、渡す値のほうを整える
ProductSearch search = ProductSearch.from(withKeyword(request, keyword));

static HttpServletRequest withKeyword(HttpServletRequest request, String keyword) {
    return new HttpServletRequestWrapper(request) {
        @Override
        public String getParameter(String name) {
            return "q".equals(name) ? keyword : super.getParameter(name);
        }
    };
}</code></pre>

    <h2>サーバ側の負荷と、LIKE 検索の限界</h2>
    <p>
      インクリメンタルサーチは<strong>利用者 1 人あたりの検索回数が桁違いに増える</strong>機能です。
      1 回の検索でこのサンプルは 2 本の SQL を投げています
      （該当件数を数える <code>COUNT(*)</code> と、候補を取り出す <code>SELECT</code>）。
      debounce と最低文字数は、見た目の話ではなく<strong>この回数を減らすための仕組み</strong>です。
    </p>
    <p>そして、キーワード検索に使っている <code>LIKE</code> には性能上の限界があります。</p>
<pre><code class="language-sql">-- 前方一致 : 「ペで始まる」なので、name の索引を先頭からたどれる (速い)
WHERE name LIKE 'ペ%';

-- 部分一致 : 先頭が決まらないので索引をたどれず、全行を見ることになる (遅い)
WHERE name LIKE '%ペ%';</code></pre>
    <p>
      このサンプルは 60 件しかないので一瞬で終わりますが、
      数十万件になると<strong>部分一致は目に見えて遅くなります</strong>。
      なお、上の「速い」は <code>name</code> に索引がある場合の話です。
      このサンプルの <code>products</code> テーブルには主キー以外の索引を作っていないので、
      前方一致に直してもやはり全行を見ます。
      件数が増えたときの選択肢は次のとおりです。
    </p>
    <ul>
      <li>
        <strong>前方一致で妥協する</strong>：
        「商品コードは前方一致、商品名は部分一致」のように、列ごとに決めるのが現実的です
      </li>
      <li>
        <strong>検索用の列を別に持つ</strong>：
        よみがな、記号を抜いた文字列、小文字に揃えた文字列などをあらかじめ入れておき、そちらを検索します
      </li>
      <li>
        <strong>全文検索の仕組みを使う</strong>：
        文章をあらかじめ語や n-gram（2 〜 3 文字ずつの断片）に切って索引を作っておく方式です。
        H2 の <code>FT_SEARCH</code> は語単位、PostgreSQL の <code>pg_trgm</code> は 3 文字単位、
        Elasticsearch は切り方そのものを選べる、というように仕組みは製品ごとに違います
      </li>
      <li>
        <strong>件数を数えるのをやめる</strong>：
        <code>COUNT(*)</code> も条件に合う行を全部数えるので、候補を取り出すのと同じだけ時間が掛かります。
        11 件取ってみて 11 件あったら「10 件以上」と出す、という手もあります
      </li>
    </ul>
    <p>
      なお<strong>返す件数の上限はサーバ側で決めます</strong>。
      画面から <code>size=50</code> と指定されても、この API は ${suggestLimit} 件に切り詰めます。
      件数を画面の言い値のままにすると、URL を書き換えるだけで全件を引き出せる口になります。
      そのかわり<strong>総件数は正直に返し</strong>、「◯ 件見つかりました（上位 ${suggestLimit} 件を表示）」と書けるようにしています。
    </p>

    <h2>候補の描画は textContent で</h2>
    <p>
      受け取った JSON を画面に出すとき、<code>innerHTML</code> を使うと
      文字列が HTML として解釈されます。<code>textContent</code> なら文字のまま入ります。
    </p>
<pre><code class="language-javascript">// ✕ 文字列が HTML として解釈される
option.innerHTML = item.name;

// ◯ 文字として入る (タグがあっても、そう見えるだけ)
option.textContent = item.name;</code></pre>
    <p>
      商品名は利用者がこの画面で入力した値ではありません。
      それでも <code>textContent</code> にするのは、<strong>データベースの中身も「いつか誰かが入れた値」</strong>
      だからです。別の管理画面から登録された商品名に
      <code>&lt;img src=x onerror=...&gt;</code> が紛れていれば、
      <code>innerHTML</code> で出した瞬間に動きます（蓄積型のクロスサイトスクリプティング）。
      「どこから来た文字列か」を一つひとつ追いかけるより、
      <strong>外から来た文字列は常に文字として入れる</strong>と決めてしまうほうが確実です。
    </p>
    <ul>
      <li>jQuery なら <code>.text()</code> が <code>textContent</code>、<code>.html()</code> が <code>innerHTML</code> です</li>
      <li>入力欄に入れる <code>input.value = item.name</code> は、値を文字列としてしか扱わないので安全です</li>
      <li>
        サーバ側は <code>common/Json.java</code> がエスケープします。
        文字列を自分で <code>"..." + name + "..."</code> と組み立てて JSON にしてはいけません
      </li>
    </ul>

    <h2>キーボード操作とアクセシビリティ</h2>
    <p>
      候補が出る入力欄は、マウスが使えないと何もできない部品になりがちです。
      最低限、次の操作はできるようにします。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>キー</th><th>動き</th><th>気をつけること</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><kbd>↓</kbd></td>
            <td>次の候補へ（末尾の次は先頭に戻る）</td>
            <td>ブラウザ既定のカーソル移動を <code>preventDefault()</code> で止める</td>
          </tr>
          <tr><td><kbd>↑</kbd></td><td>前の候補へ（先頭の前は末尾へ）</td><td>同上</td></tr>
          <tr>
            <td><kbd>Enter</kbd></td>
            <td>選択中の候補で確定する</td>
            <td>
              <strong>候補を選んでいるときだけ</strong>止める。
              未選択のときまで止めると、フォームの送信ができなくなる
            </td>
          </tr>
          <tr><td><kbd>Esc</kbd></td><td>候補を閉じる（入力はそのまま残す）</td><td>閉じるだけで、入力を消さない</td></tr>
          <tr><td><kbd>Tab</kbd></td><td>候補を閉じて次の項目へ</td><td>開いたまま裏に残さない</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      支援技術（スクリーンリーダーなど）には、見た目ではなく<strong>役割と状態</strong>で伝えます。
    </p>
<pre><code class="language-xml">&lt;input id="suggestInput" role="combobox" autocomplete="off"
       aria-autocomplete="list" aria-expanded="false"
       aria-controls="suggestMenu" aria-activedescendant=""&gt;

&lt;div id="suggestMenu" role="listbox"&gt;
  &lt;button type="button" role="option" id="suggestOption-0" aria-selected="false"&gt;...&lt;/button&gt;
&lt;/div&gt;</code></pre>
    <ul>
      <li>
        <strong>フォーカスは入力欄から動かさない</strong>：
        候補にフォーカスを移すと文字が打てなくなります。
        「いま選んでいる候補」は <code>aria-activedescendant</code> に id を入れて伝えます
      </li>
      <li>
        <strong>件数は <code>aria-live="polite"</code> の場所に出す</strong>：
        画面の変化は自動では読み上げられません。
        <code>polite</code> は「読んでいる途中を邪魔しない」指定です
      </li>
      <li>
        <strong><code>autocomplete="off"</code> を付ける</strong>：
        付けないと、ブラウザ自身の入力履歴が自前の候補に重なって出ます
      </li>
      <li>
        <strong>「選択中」を色だけで表さない</strong>：
        背景色は、読み上げには伝わりませんし、色の見え方には個人差もあります。
        このサンプルは Bootstrap の <code>active</code>（背景色）に加えて
        <code>aria-selected</code> も切り替えています
      </li>
    </ul>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>候補をクリックしても選べない</strong>：
        クリックより先に入力欄の <code>blur</code> が起きて候補が閉じ、<code>click</code> が届きません。
        候補側の <code>mousedown</code> で <code>preventDefault()</code> して、フォーカスを奪わないようにします。
      </li>
      <li>
        <strong>日本語入力の変換中にも検索が飛ぶ</strong>：
        IME で変換している最中も <code>input</code> イベントは発生します。
        debounce があれば実害は小さいのですが、確定前に検索したくない場合や、
        変換の <kbd>Enter</kbd> を候補の確定と取り違えたくない場合は
        <code>event.isComposing</code>（変換中かどうか）を見て抜けます。
      </li>
      <li>
        <strong><code>fetch</code> は 404 や 500 で失敗しない</strong>：
        通信できた時点で成功扱いです。<code>res.ok</code> を自分で確かめないと、
        エラーページの HTML を <code>res.json()</code> に渡して別のエラーになります。
      </li>
      <li>
        <strong>中断のたびにエラーが出る</strong>：
        <code>AbortController</code> で中断すると <code>catch</code> に <code>AbortError</code> が来ます。
        これは正常な流れなので、エラー表示から除きます。
      </li>
      <li>
        <strong>件数表示が候補の件数になっている</strong>：
        ${suggestLimit} 件しか返していないのに「${suggestLimit} 件見つかりました」と出すと、
        利用者は「これで全部」と受け取ります。総件数は別に返します。
      </li>
      <li>
        <strong>GET の応答がキャッシュされる</strong>：
        検索 API は GET なので、ブラウザや途中の機器にキャッシュされ得ます。
        更新が反映されないときは <code>Cache-Control: no-store</code> を疑います。
      </li>
      <li>
        <strong>中断したのにサーバのログが減らない</strong>：
        中断はブラウザ側の話で、受け取ったリクエストをサーバは最後まで処理します。
        サーバの負荷を減らすのは debounce と最低文字数の役目です。
      </li>
      <li>
        <strong>一覧画面と候補で結果がずれる</strong>：
        API 用に検索条件を書き直すと、片方だけ直したときにずれます。
        このサンプルは一覧画面とまったく同じ <code>ProductSearch</code> / <code>ProductDao</code> を呼んでいます。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {

        // ----------------------------------------------------------------
        // 設定は Java 側の定数を data-* で受け取る。
        // 画面に「300 ms 待ちます」と書いておきながら JS だけ 500 ms、を防ぐため
        // ----------------------------------------------------------------
        var $demo = $('#ajaxSearchDemo');
        var apiUrl = $demo.data('api');
        var debounceMillis = Number($demo.data('debounce'));
        var minLength = Number($demo.data('minLength'));

        var $input = $('#suggestInput');
        var $category = $('#suggestCategory');
        var $menu = $('#suggestMenu');
        var $status = $('#suggestStatus');
        var $spinner = $('#suggestSpinner');
        var $picked = $('#pickedResult');
        var menu = $menu.get(0);

        // 観察用のスイッチ (既定では 3 つとも「対策を入れた状態」)
        function useDebounce() { return !$('#optNoDebounce').prop('checked'); }
        function useGuard() { return !$('#optNoGuard').prop('checked'); }
        function useSlow() { return $('#optSlow').prop('checked'); }

        // ----------------------------------------------------------------
        // 状態
        // ----------------------------------------------------------------
        var timerId = null;      // debounce のタイマー
        var controller = null;   // いま飛んでいるリクエストを中断するためのもの
        var sentSeq = 0;         // 送ったリクエストの通し番号
        var shownSeq = 0;        // 画面に出した応答の通し番号
        var items = [];          // いま出している候補
        var activeIndex = -1;    // キーボードで選んでいる候補 (-1 は未選択)

        var counts = {typed: 0, sent: 0, shown: 0, aborted: 0, dropped: 0};

        // ----------------------------------------------------------------
        // 入力を受けて、検索を予約する
        // ----------------------------------------------------------------
        $input.on('input', function () {
          counts.typed++;
          renderCounts();
          schedule($input.val().trim(), false);
        });

        // カテゴリの変更は打鍵ではないので、待たずにすぐ検索する
        $category.on('change', function () {
          schedule($input.val().trim(), true);
        });

        function schedule(keyword, immediately) {
          clearTimer();

          // 空 (や短すぎる入力) では検索しない。飛んでいるリクエストも要らない
          if (keyword.length < minLength) {
            abort();
            close();
            setStatus(minLength + ' 文字以上入力すると検索します。', false);
            return;
          }
          if (immediately || !useDebounce()) {
            send(keyword);
            return;
          }
          // 打っている間は、このタイマーが何度も掛け直されて発火しない
          timerId = setTimeout(function () {
            timerId = null;
            send(keyword);
          }, debounceMillis);
        }

        function clearTimer() {
          if (timerId !== null) {
            clearTimeout(timerId);
            timerId = null;
          }
        }

        // ----------------------------------------------------------------
        // 検索する
        // ----------------------------------------------------------------
        function send(keyword) {
          if (useGuard()) {
            abort();   // ① 前のリクエストを中断する
          }

          var seq = ++sentSeq;   // ② このリクエストの通し番号
          var startedAt = Date.now();
          counts.sent++;
          renderCounts();
          setStatus('検索中…', true);

          var options = {headers: {'Accept': 'application/json'}};
          if (useGuard() && window.AbortController) {
            controller = new AbortController();
            options.signal = controller.signal;
          }

          fetch(buildUrl(keyword), options)
            .then(function (res) {
              // fetch は 404 でも 500 でも失敗にならないので、自分で確かめる
              if (!res.ok) {
                throw new Error('サーバが ' + res.status + ' を返しました');
              }
              return res.json();
            })
            .then(function (data) {
              var elapsed = Date.now() - startedAt;
              var stale = seq < shownSeq;   // 自分より新しい応答が、先に画面に出ている

              // ③ 古い応答は捨てる (中断が間に合わずに届くことがある)
              if (stale && useGuard()) {
                counts.dropped++;
                renderCounts();
                addLog(seq, keyword, elapsed, '捨てた（古い応答）', 'text-muted');
                return;
              }
              if (seq > shownSeq) {
                shownSeq = seq;
              }
              counts.shown++;
              renderCounts();
              addLog(seq, keyword, elapsed,
                  stale ? '古い応答で上書きした' : '表示した',
                  stale ? 'text-danger' : '');
              show(data);
            })
            .catch(function (e) {
              // ④ 中断は自分で行った正常な操作。エラーとして見せない
              if (e.name === 'AbortError') {
                counts.aborted++;
                renderCounts();
                addLog(seq, keyword, Date.now() - startedAt, '中断した', 'text-muted');
                return;
              }
              close();
              setStatus('検索できませんでした: ' + e.message, false);
            });
        }

        function buildUrl(keyword) {
          // パラメータは必ず encodeURIComponent を通す (& や # がそのまま入ると壊れる)
          var url = apiUrl + '?q=' + encodeURIComponent(keyword);
          var category = $category.val();
          if (category) {
            url += '&category=' + encodeURIComponent(category);
          }
          if (useSlow()) {
            url += '&slow=on';
          }
          return url;
        }

        function abort() {
          if (controller) {
            controller.abort();
            controller = null;
          }
        }

        // ----------------------------------------------------------------
        // 受け取った JSON を画面に出す
        // ----------------------------------------------------------------
        function show(data) {
          items = data.items || [];
          activeIndex = -1;

          if (!data.searched) {
            close();
            setStatus(data.minLength + ' 文字以上入力すると検索します。', false);
            return;
          }
          if (items.length === 0) {
            close();
            setStatus('「' + data.q + '」に一致する商品はありませんでした。', false);
            return;
          }

          render(items);
          open();

          // 出しているのは上位だけでも、件数は該当した全部を知らせる
          var text = data.total + ' 件見つかりました。';
          if (data.truncated) {
            text += '（上位 ' + data.limit + ' 件を表示しています）';
          }
          setStatus(text, false);
        }

        function render(list) {
          menu.textContent = '';   // 前の候補を消す

          list.forEach(function (item, index) {
            var option = document.createElement('button');
            option.type = 'button';
            // text-truncate : 幅に収まらない商品名は「…」で切る (横に溢れさせない)
            option.className = 'dropdown-item text-truncate';
            option.id = 'suggestOption-' + index;
            option.setAttribute('role', 'option');
            option.setAttribute('aria-selected', 'false');
            option.setAttribute('data-index', index);

            // ここが要点。innerHTML にすると、商品名が HTML として解釈される
            var name = document.createElement('span');
            name.textContent = item.name;

            var meta = document.createElement('span');
            meta.className = 'small text-muted ml-2';
            meta.setAttribute('data-meta', '');
            meta.textContent = item.category + ' / ' + yen(item.price)
                + (item.inStock ? '' : ' / 在庫切れ');

            option.appendChild(name);
            option.appendChild(meta);
            menu.appendChild(option);
          });
        }

        function setStatus(text, busy) {
          $status.text(text);   // jQuery の .text() は textContent と同じ
          $spinner.toggleClass('invisible', !busy);
        }

        function open() {
          $menu.addClass('show');
          $input.attr('aria-expanded', 'true');
        }

        function close() {
          $menu.removeClass('show');
          $input.attr('aria-expanded', 'false').removeAttr('aria-activedescendant');
          activeIndex = -1;
        }

        function isOpen() {
          return $menu.hasClass('show');
        }

        // ----------------------------------------------------------------
        // キーボード操作
        // ----------------------------------------------------------------
        $input.on('keydown', function (e) {
          // 日本語入力の変換中は、Enter も ↑ ↓ も IME のもの。横取りしない
          if (e.originalEvent && e.originalEvent.isComposing) {
            return;
          }
          if (e.key === 'Escape') {
            close();   // 閉じるだけ。入力した文字は消さない
            return;
          }
          if (e.key === 'Tab') {
            close();
            return;
          }
          if (!isOpen()) {
            // 閉じているときの ↓ は「さっきの候補をもう一度出す」
            if (e.key === 'ArrowDown' && items.length > 0) {
              e.preventDefault();
              open();
              moveActive(0);
            }
            return;
          }
          if (e.key === 'ArrowDown') {
            e.preventDefault();   // カーソルが行末へ飛ぶのを止める
            moveActive(activeIndex + 1);
          } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            moveActive(activeIndex - 1);
          } else if (e.key === 'Enter' && activeIndex >= 0) {
            // 候補を選んでいるときだけ止める。
            // 無条件に止めると、フォームの送信ができない入力欄になってしまう
            e.preventDefault();
            pick(activeIndex);
          }
        });

        function moveActive(index) {
          if (items.length === 0) {
            return;
          }
          if (index < 0) {
            index = items.length - 1;          // 先頭より上へ行ったら末尾へ
          } else if (index >= items.length) {
            index = 0;                         // 末尾より下へ行ったら先頭へ
          }
          activeIndex = index;

          $menu.children().each(function (i) {
            var selected = (i === index);
            $(this).toggleClass('active', selected)
                   .attr('aria-selected', selected ? 'true' : 'false');
            // 選択中の行は背景が青くなる。薄い灰色のままだと文字が読めなくなるので外す
            $(this).find('[data-meta]').toggleClass('text-muted', !selected);
          });

          // フォーカスは入力欄に置いたまま、選んでいる候補の id だけを伝える
          $input.attr('aria-activedescendant', 'suggestOption-' + index);
        }

        // ----------------------------------------------------------------
        // マウス操作
        // ----------------------------------------------------------------
        // クリックより先に入力欄の blur が起きると、候補が閉じて click が届かない。
        // mousedown を止めてフォーカスを奪わないようにする
        $menu.on('mousedown', function (e) {
          e.preventDefault();
        });

        $menu.on('click', '[role="option"]', function () {
          pick(Number(this.getAttribute('data-index')));
        });

        $input.on('blur', function () {
          close();
        });

        // ----------------------------------------------------------------
        // 候補を確定する
        // ----------------------------------------------------------------
        function pick(index) {
          var item = items[index];
          if (!item) {
            return;
          }
          clearTimer();   // 予約されていた検索を取り消す
          abort();        // 飛んでいる検索ももう要らない

          // value に入れた文字列は HTML として解釈されない
          $input.val(item.name);
          close();
          showPicked(item);
          setStatus('「' + item.name + '」を選びました。', false);
        }

        function showPicked(item) {
          // .text() は textContent。受け取った値をそのまま文字として入れる
          $('#pickedCode').text(item.code);
          $('#pickedName').text(item.name);
          $('#pickedCategory').text(item.category);
          $('#pickedPrice').text(yen(item.price));
          $('#pickedStock').text(item.inStock ? item.stock + ' 個' : '在庫切れ');
          $picked.removeClass('d-none');
        }

        function yen(price) {
          return '¥' + Number(price).toLocaleString('ja-JP');
        }

        // ----------------------------------------------------------------
        // 観察用の数え上げと記録
        // ----------------------------------------------------------------
        function renderCounts() {
          $('#countTyped').text(counts.typed);
          $('#countSent').text(counts.sent);
          $('#countShown').text(counts.shown);
          $('#countAborted').text(counts.aborted);
          $('#countDropped').text(counts.dropped);
        }

        function addLog(seq, keyword, elapsed, result, cssClass) {
          var log = document.getElementById('requestLog');
          var row = document.createElement('tr');
          if (cssClass) {
            row.className = cssClass;
          }
          ['#' + seq, keyword, elapsed + ' ms', result].forEach(function (value) {
            var cell = document.createElement('td');
            cell.textContent = value;   // キーワードは利用者の入力そのもの。必ず textContent で
            row.appendChild(cell);
          });

          log.insertBefore(row, log.firstChild);   // 新しいものを上に積む
          while (log.children.length > 8) {
            log.removeChild(log.lastChild);
          }
          $('#requestLogEmpty').addClass('d-none');
        }

        $('#resetCounts').on('click', function () {
          counts = {typed: 0, sent: 0, shown: 0, aborted: 0, dropped: 0};
          renderCounts();
          document.getElementById('requestLog').textContent = '';
          $('#requestLogEmpty').removeClass('d-none');
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ============================================================
         デモ本体
         ============================================================ --%>
    <t:panel title="入力するたびに検索する"
             note="打ち終わって ${debounceMillis} ms たつと検索します">
      <div id="ajaxSearchDemo"
           data-api="${ctx}${apiPath}"
           data-debounce="${debounceMillis}"
           data-min-length="${minKeywordLength}">

        <div class="form-row">
          <div class="form-group col-md-7 mb-2">
            <label for="suggestInput">キーワード</label>
            <%-- dropdown が position:relative、dropdown-menu が position:absolute。
                 show クラスを付け外しして候補を出し入れする --%>
            <div class="dropdown">
              <input type="text" class="form-control" id="suggestInput"
                     placeholder="例: ペン / P-0001 / 文房具"
                     autocomplete="off"
                     role="combobox" aria-autocomplete="list" aria-haspopup="listbox"
                     aria-expanded="false" aria-controls="suggestMenu">
              <div class="dropdown-menu w-100" id="suggestMenu" role="listbox"
                   aria-label="検索候補"></div>
            </div>
          </div>

          <div class="form-group col-md-5 mb-2">
            <label for="suggestCategory">カテゴリで絞る</label>
            <select class="form-control" id="suggestCategory">
              <option value="">すべて</option>
              <c:forEach var="category" items="${categories}">
                <option value="${fn:escapeXml(category)}">${fn:escapeXml(category)}</option>
              </c:forEach>
            </select>
          </div>
        </div>

        <%-- 通信中の表示と件数。aria-live があると、変化したときに読み上げられる --%>
        <div class="d-flex align-items-center">
          <span id="suggestSpinner" class="spinner-border spinner-border-sm text-primary mr-2 invisible"
                role="status" aria-hidden="true"></span>
          <span id="suggestStatus" class="small text-muted" aria-live="polite">
            ${minKeywordLength} 文字以上入力すると検索します。
          </span>
        </div>

        <%-- 確定した候補 (候補をクリック、または Enter で確定したとき) --%>
        <div id="pickedResult" class="alert alert-success mt-3 mb-0 d-none">
          <strong id="pickedName"></strong>
          <span class="d-block small mt-1">
            コード <code id="pickedCode"></code> ／
            カテゴリ <span id="pickedCategory"></span> ／
            <span id="pickedPrice"></span> ／
            在庫 <span id="pickedStock"></span>
          </span>
        </div>
      </div>

      <p class="text-muted small mt-3 mb-0">
        商品は全 ${allCount} 件です（<a href="${ctx}/samples/list/search-list">検索つき一覧画面</a>
        と同じデータを、同じ検索条件クラスで検索しています）。
        候補は上位 ${suggestLimit} 件まで。<kbd>↑</kbd> <kbd>↓</kbd> で選んで <kbd>Enter</kbd>、
        <kbd>Esc</kbd> で閉じます。
      </p>
    </t:panel>

    <%-- ============================================================
         観察用のスイッチと数え上げ
         ============================================================ --%>
    <t:panel title="動きを観察する" note="スイッチを切り替えて、同じ操作をもう一度してみてください">
      <div class="form-row">
        <div class="col-md-4 mb-2">
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="optNoDebounce">
            <label class="custom-control-label" for="optNoDebounce">
              debounce を切る
              <span class="d-block text-muted small">1 文字ごとにリクエストが飛びます</span>
            </label>
          </div>
        </div>
        <div class="col-md-4 mb-2">
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="optNoGuard">
            <label class="custom-control-label" for="optNoGuard">
              競合対策を切る
              <span class="d-block text-muted small">中断も、古い応答の破棄もしません</span>
            </label>
          </div>
        </div>
        <div class="col-md-4 mb-2">
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="optSlow">
            <label class="custom-control-label" for="optSlow">
              サーバをわざと遅くする
              <span class="d-block text-muted small">短いキーワードほど遅く返します</span>
            </label>
          </div>
        </div>
      </div>

      <div class="alert alert-secondary small mt-2">
        <strong>試しかた</strong>：「競合対策を切る」と「わざと遅くする」を両方入れて、
        <code>ペ</code> → <code>ン</code> とゆっくり打ってみてください。
        一度「ペン」の結果が出たあとに、遅れて返ってきた「ペ」の結果で上書きされます
        （記録の欄が<span class="text-danger">赤</span>になります）。
        スイッチを戻すと、同じ操作でも上書きされなくなります。
        <span class="d-block mt-1">
          なお「破棄（古い応答）」は<strong>中断が間に合わなかったときの保険</strong>です。
          中断が効いているあいだは「中断」だけが増え、ここは 0 のままになります。
          回線の状態によっては中断を指示したあとに応答が届くことがあり、そのときにここが増えます。
        </span>
      </div>

      <div class="form-row text-center">
        <div class="col mb-2">
          <div class="border rounded py-2">
            <span class="d-block h4 mb-0" id="countTyped">0</span>
            <span class="small text-muted">入力</span>
          </div>
        </div>
        <div class="col mb-2">
          <div class="border rounded py-2">
            <span class="d-block h4 mb-0" id="countSent">0</span>
            <span class="small text-muted">送信</span>
          </div>
        </div>
        <div class="col mb-2">
          <div class="border rounded py-2">
            <span class="d-block h4 mb-0" id="countShown">0</span>
            <span class="small text-muted">表示に使用</span>
          </div>
        </div>
        <div class="col mb-2">
          <div class="border rounded py-2">
            <span class="d-block h4 mb-0" id="countAborted">0</span>
            <span class="small text-muted">中断</span>
          </div>
        </div>
        <div class="col mb-2">
          <div class="border rounded py-2">
            <span class="d-block h4 mb-0" id="countDropped">0</span>
            <span class="small text-muted">破棄（古い応答）</span>
          </div>
        </div>
      </div>

      <div class="table-responsive mt-2">
        <table class="table table-sm table-bordered mb-1">
          <thead>
            <tr>
              <th class="w-25">通し番号</th>
              <th>キーワード</th>
              <th>応答まで</th>
              <th>結果</th>
            </tr>
          </thead>
          <tbody id="requestLog"></tbody>
        </table>
      </div>
      <p class="small text-muted mb-0" id="requestLogEmpty">
        上の入力欄に何か打つと、送ったリクエストが新しい順に並びます（最新 8 件）。
      </p>
      <button type="button" class="btn btn-outline-secondary btn-sm mt-2" id="resetCounts">
        数えた値と記録を消す
      </button>
    </t:panel>

    <%-- ============================================================
         API の中身を直接見てもらう
         ============================================================ --%>
    <t:panel title="API が返している JSON" note="GET なので、URL をブラウザに貼れば中身を見られます">
      <p class="mb-2">
        候補を返しているのは
        <code>${fn:escapeXml(apiPath)}</code> です。検索は状態を変えないので GET にしています。
      </p>
      <p class="mb-2">
        <a href="${ctx}${apiPath}?q=ペン" target="_blank" rel="noopener">
          <t:icon name="external" size="14" cssClass="mr-1" />?q=ペン を開く
        </a>
        <a class="ml-3" href="${ctx}${apiPath}?q=ペン&amp;category=文房具" target="_blank" rel="noopener">
          <t:icon name="external" size="14" cssClass="mr-1" />?q=ペン&amp;category=文房具 を開く
        </a>
        <a class="ml-3" href="${ctx}${apiPath}?q=" target="_blank" rel="noopener">
          <t:icon name="external" size="14" cssClass="mr-1" />?q=（空）を開く
        </a>
      </p>
<pre class="mb-0"><code class="language-javascript">{"q":"ペン","minLength":${minKeywordLength},"limit":${suggestLimit},"elapsedMillis":3,
 "searched":true,"total":3,"truncated":false,
 "items":[{"id":1,"code":"P-0001","name":"ボールペン (黒・0.5mm)",
           "category":"文房具","price":130,"stock":1,"inStock":true},
          ... ],
 "waitedMillis":0}</code></pre>
      <p class="text-muted small mt-2 mb-0">
        キーワードが短すぎて検索しなかったときも、<code>searched</code> を <code>false</code> にして
        <strong>同じ形</strong>で返します。形が場合によって変わると、
        受け取る JavaScript に「このときは items が無い」といった分岐が増えていきます。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
