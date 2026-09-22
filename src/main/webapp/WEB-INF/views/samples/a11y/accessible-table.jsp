<%--
  【サンプル】表（テーブル）を読み上げと相性よく作る

  Servlet を使わない、JSP だけのサンプルです。
  業務システムの主役である一覧表を、どう書けば音声でも追えるかをまとめています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="accessible-table">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>表は「読み上げると一列に潰れる」</h2>
    <p>
      表を目で見るときは、縦と横の位置から「この <code>1,200</code> は、
      A 社の 4 月の金額だな」と分かります。
      しかし読み上げは<strong>一次元</strong>です。設定を何もしないと、
      セルの中身が <code>A社 1200 1500 …</code> と延々と並ぶだけになります。
    </p>
    <p>
      そこで、<strong>どのセルが見出しなのかを HTML で明示します</strong>。
      すると読み上げソフトは、セルを読むときに
      「4 月、A 社、1,200」と<strong>見出しを添えて</strong>読んでくれます。
      矢印キーで上下左右に移動しても、行き先の見出しを読み続けてくれます。
    </p>

    <h2>付けるのは 3 つだけ</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 26%;">書くもの</th><th>役割</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>&lt;caption&gt;</code></td>
            <td>
              <strong>表の題名</strong>です。表の中で最初に読まれるので、
              利用者は中に入る前に「何の表か」が分かります。
              <code>&lt;table&gt;</code> の<strong>直後</strong>に書きます。
              見出し（<code>&lt;h2&gt;</code>）で代用しても、表と結び付きません
            </td>
          </tr>
          <tr>
            <td><code>&lt;th&gt;</code></td>
            <td>
              見出しセル。<code>&lt;td&gt;</code> に太字の CSS を当てたものは、
              <strong>見た目が同じでも見出しとしては扱われません</strong>
            </td>
          </tr>
          <tr>
            <td><code>scope</code></td>
            <td>
              その見出しが<strong>どちら向き</strong>かを示します。
              <code>scope="col"</code> は列（縦方向）の見出し、
              <code>scope="row"</code> は行（横方向）の見出しです
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      1 行目だけが見出しの単純な表なら <code>scope</code> は省いても推測されますが、
      <strong>行の見出し（左端の列）がある表では、書かないと正しく読まれません</strong>。
      迷ったら書く、で構いません。
    </p>

    <h2>書き方の型</h2>
    <pre><code class="language-xml">&lt;table class="table"&gt;
  &lt;caption&gt;取引先別の売上（2026 年度 上期）&lt;/caption&gt;
  &lt;thead&gt;
    &lt;tr&gt;
      &lt;th scope="col"&gt;取引先&lt;/th&gt;
      &lt;th scope="col"&gt;4 月&lt;/th&gt;
      &lt;th scope="col"&gt;5 月&lt;/th&gt;
    &lt;/tr&gt;
  &lt;/thead&gt;
  &lt;tbody&gt;
    &lt;tr&gt;
      &lt;th scope="row"&gt;株式会社あかつき&lt;/th&gt;
      &lt;td&gt;1,200&lt;/td&gt;
      &lt;td&gt;1,500&lt;/td&gt;
    &lt;/tr&gt;
  &lt;/tbody&gt;
&lt;/table&gt;</code></pre>
    <ul>
      <li>
        <strong>左端の列も <code>&lt;th scope="row"&gt;</code> にします。</strong>
        ここが <code>&lt;td&gt;</code> だと、どの取引先の数字なのかが読まれません
      </li>
      <li>
        <code>&lt;thead&gt;</code> / <code>&lt;tbody&gt;</code> / <code>&lt;tfoot&gt;</code> で
        区切っておくと、合計行が本体と区別されます
      </li>
      <li>
        <code>&lt;caption&gt;</code> を画面に出したくないときは
        <code>class="sr-only"</code> を付けます。消すのではなく<strong>隠す</strong>のが要点です
      </li>
    </ul>

    <h2>並び替えができる列には <code>aria-sort</code></h2>
    <p>
      列見出しをクリックすると並び替わる一覧では、
      <strong>今どの列で、どちら向きに並んでいるか</strong>を伝えます。
    </p>
    <pre><code class="language-xml">&lt;th scope="col" aria-sort="ascending"&gt;
  &lt;a href="?sort=name&amp;amp;order=desc"&gt;取引先名&lt;/a&gt;
&lt;/th&gt;</code></pre>
    <ul>
      <li><code>aria-sort="ascending"</code> … 昇順で並んでいる</li>
      <li><code>aria-sort="descending"</code> … 降順で並んでいる</li>
      <li><code>aria-sort="none"</code> … 並び替えできるが、今は並んでいない</li>
      <li>
        <strong>並んでいる列は 1 つだけ</strong>です。
        他の列に <code>ascending</code> を残さないよう注意します
      </li>
      <li>
        矢印（▲▼）で向きを示している場合、その記号には
        <code>aria-hidden="true"</code> を付けます。
        <code>aria-sort</code> と二重に読まれるためです
      </li>
    </ul>
    <p>
      このサイトの <a href="${ctx}/samples/list/search-list">検索つき一覧画面</a> が、
      リンクで並び替える形の実例です。
    </p>

    <h2>横に長い表をキーボードでも動かす</h2>
    <p>
      列が多い表は <code>&lt;div class="table-responsive"&gt;</code> で囲んで横スクロールにします。
      ところが、この枠は<strong>マウスやタッチが無いと動かせません</strong>。
      キーボードだけの利用者は、右側の列を見る手段がなくなります。
    </p>
    <pre><code class="language-xml">&lt;div class="table-responsive" role="region"
     aria-label="取引先別の売上（横にスクロールできます）" tabindex="0"&gt;
  &lt;table class="table"&gt; … &lt;/table&gt;
&lt;/div&gt;</code></pre>
    <ul>
      <li>
        <code>tabindex="0"</code> … Tab で枠に入れるようになり、
        <strong>矢印キーで横スクロールできます</strong>
      </li>
      <li>
        <code>role="region"</code> + <code>aria-label</code> …
        枠に入ったときに「何の表か」が読まれます。
        <strong><code>aria-label</code> の無い <code>role="region"</code> は意味がありません</strong>
      </li>
      <li>
        <strong>はみ出していないときは付けません。</strong>
        Tab で止まる場所が無意味に増えてしまいます
      </li>
    </ul>
    <p>
      このサイトでは <code>assets/js/app.js</code> が
      <strong>実際にはみ出している枠にだけ</strong>この 3 つを付けています
      （画面幅が変わると付け外しされます）。実装はこうなっています。
    </p>
    <pre><code class="language-javascript">function toggleScrollFocus(area, scrollable) {
  if (!scrollable) {
    // はみ出していないときは外す (Tab で止まる場所を無駄に増やさない)
    area.removeAttribute('tabindex');
    area.removeAttribute('role');
    area.removeAttribute('aria-label');
    return;
  }
  if (area.getAttribute('tabindex') === '0') {
    return;
  }
  var caption = area.querySelector('table &gt; caption');
  var title = caption ? caption.textContent.trim() : '';

  area.setAttribute('tabindex', '0');
  area.setAttribute('role', 'region');
  area.setAttribute('aria-label', title
    ? title + '（横にスクロールできます）'
    : '横にスクロールできる表');
}</code></pre>
    <p>
      枠の名前を <code>&lt;caption&gt;</code> から取っているので、
      <strong>表に <code>&lt;caption&gt;</code> を書いておけば、そのまま読み上げに使われます</strong>
      （<code>.sr-only</code> で隠してあっても構いません）。
    </p>

    <h2>やってはいけないこと</h2>
    <ul>
      <li>
        <strong>レイアウト目的で表を使わない。</strong>
        画面の配置を整えるために <code>&lt;table&gt;</code> を使うと、
        読み上げで「表、3 行 2 列」と案内されてしまいます。
        配置は Bootstrap のグリッド（<code>row</code> / <code>col-*</code>）で組みます
      </li>
      <li>
        <strong>セルの結合（<code>colspan</code> / <code>rowspan</code>）はできるだけ避ける。</strong>
        読み上げでの位置関係が一気に難しくなります。
        どうしても必要なら、見出しに <code>id</code> を振り、
        データセルから <code>headers="id1 id2"</code> で指します
      </li>
      <li>
        <strong>空のセルを空のままにしない。</strong>
        読み上げでは黙って飛ばされ、列がずれて聞こえます。
        「—」や「なし」を入れます（記号だけのときは
        <code>&lt;span class="sr-only"&gt;データなし&lt;/span&gt;</code> を添えます）
      </li>
      <li>
        <strong>表の外に説明を置いて終わりにしない。</strong>
        「※ 金額は千円単位」は <code>&lt;caption&gt;</code> に含めるか、
        単位を列見出しに書きます（「金額（千円）」）
      </li>
    </ul>

    <h2>スマートフォンでの一覧</h2>
    <p>
      列が 6 つも 7 つもある一覧は、横スクロールにしても実用的ではありません。
      狭い画面では<strong>表をやめてカードに切り替える</strong>方が読みやすくなります。
      その場合も、カードの中で「項目名：値」の組を崩さないようにします。
    </p>
    <p>
      このサイトの表は <code>.table-responsive</code> で囲む方針です。
      囲んでおけば、<code>app.js</code> が右端の影と
      「← 表は横にスクロールできます →」の案内を自動で付けます。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // 並び替えのデモ。aria-sort と矢印を、押されたボタンだけに付け替えます。
      (function () {
        'use strict';

        var table = document.getElementById('sortTable');
        if (!table) {
          return;
        }

        var headers = table.querySelectorAll('th[data-sort-key]');
        var status = document.getElementById('sortStatus');

        Array.prototype.forEach.call(headers, function (header) {
          var button = header.querySelector('button');
          if (!button) {
            return;
          }

          button.addEventListener('click', function () {
            var current = header.getAttribute('aria-sort');
            var next = current === 'ascending' ? 'descending' : 'ascending';

            // 並んでいる列は 1 つだけ。ほかの列は none に戻します
            Array.prototype.forEach.call(headers, function (other) {
              other.setAttribute('aria-sort', 'none');
              var mark = other.querySelector('[data-sort-mark]');
              if (mark) {
                mark.textContent = '';
              }
            });

            header.setAttribute('aria-sort', next);
            var mark = header.querySelector('[data-sort-mark]');
            if (mark) {
              // 記号は aria-hidden="true" なので、読み上げでは aria-sort だけが使われます
              mark.textContent = next === 'ascending' ? ' ▲' : ' ▼';
            }

            if (status) {
              status.textContent = header.getAttribute('data-sort-key')
                + ' で' + (next === 'ascending' ? '昇順' : '降順') + 'に並べ替えました。';
            }
          });
        });
      })();
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="見出しセルを明示する"
             note="見た目はほとんど同じですが、読み上げの結果はまったく違います">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：td を太字にしただけ</span>
            <table class="table table-sm table-bordered mb-0 bg-white">
              <tr>
                <td class="font-weight-bold">取引先</td>
                <td class="font-weight-bold">4 月</td>
                <td class="font-weight-bold">5 月</td>
              </tr>
              <tr>
                <td class="font-weight-bold">あかつき</td>
                <td>1,200</td>
                <td>1,500</td>
              </tr>
              <tr>
                <td class="font-weight-bold">みなみ商事</td>
                <td>980</td>
                <td>1,010</td>
              </tr>
            </table>
            <p class="small mt-3 mb-0">
              読み上げると「あかつき、1200、1500、みなみ商事、980…」。
              <strong>1500 が何月の数字なのか分かりません。</strong>
              題名も無いので、何の表かも分かりません。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：caption + th + scope</span>
            <table class="table table-sm table-bordered mb-0 bg-white">
              <caption class="mt-0 mb-2 p-0 text-body" style="caption-side: top;">
                取引先別の売上（千円）
              </caption>
              <thead class="thead-light">
                <tr>
                  <th scope="col">取引先</th>
                  <th scope="col">4 月</th>
                  <th scope="col">5 月</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <th scope="row">あかつき</th>
                  <td>1,200</td>
                  <td>1,500</td>
                </tr>
                <tr>
                  <th scope="row">みなみ商事</th>
                  <td>980</td>
                  <td>1,010</td>
                </tr>
              </tbody>
            </table>
            <p class="small mt-3 mb-0">
              読み上げると「取引先別の売上（千円）、表、3 行 3 列。
              <strong>5 月、あかつき、1500</strong>」。
              どのセルからでも、意味が分かります。
            </p>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="並び替えの状態を伝える（aria-sort）"
             note="列見出しのボタンを押すと、aria-sort が付け替わります">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0" id="sortTable">
          <caption class="sr-only">取引先の一覧（並び替えできます）</caption>
          <thead class="thead-light">
            <tr>
              <th scope="col" aria-sort="ascending" data-sort-key="取引先名">
                <button type="button" class="btn btn-link p-0 text-left">
                  取引先名<span data-sort-mark aria-hidden="true"> ▲</span>
                </button>
              </th>
              <th scope="col" aria-sort="none" data-sort-key="担当者">
                <button type="button" class="btn btn-link p-0 text-left">
                  担当者<span data-sort-mark aria-hidden="true"></span>
                </button>
              </th>
              <th scope="col" aria-sort="none" data-sort-key="今月の売上">
                <button type="button" class="btn btn-link p-0 text-left">
                  今月の売上（千円）<span data-sort-mark aria-hidden="true"></span>
                </button>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">株式会社あかつき</th>
              <td>山田 太郎</td>
              <td>1,500</td>
            </tr>
            <tr>
              <th scope="row">みなみ商事株式会社</th>
              <td>佐藤 花子</td>
              <td>1,010</td>
            </tr>
            <tr>
              <th scope="row">有限会社きたやま</th>
              <td>—<span class="sr-only">担当者は未設定です</span></td>
              <td>420</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-2 mb-0" id="sortStatus" role="status"></p>
      <span class="a11y-attr">
        並んでいる列だけ aria-sort="ascending" / "descending"、ほかは "none"。
        ▲▼ には aria-hidden="true"
      </span>
      <p class="small text-muted mt-3 mb-0">
        3 行目の担当者が空欄です。<strong>「—」を置いたうえで、
        <code>.sr-only</code> に「担当者は未設定です」と書いています。</strong>
        セルを空のままにすると、読み上げで黙って飛ばされ、列がずれて聞こえます。
      </p>
    </t:panel>

    <t:panel title="横に長い表を、キーボードでもスクロールする"
             note="Tab キーでこの表の枠に入ってから、左右の矢印キーを押してください">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0" style="min-width: 54rem;">
          <caption class="sr-only">月別の受注実績</caption>
          <thead class="thead-light">
            <tr>
              <th scope="col" style="min-width: 10rem;">取引先</th>
              <th scope="col" style="min-width: 6rem;">4 月</th>
              <th scope="col" style="min-width: 6rem;">5 月</th>
              <th scope="col" style="min-width: 6rem;">6 月</th>
              <th scope="col" style="min-width: 6rem;">7 月</th>
              <th scope="col" style="min-width: 6rem;">8 月</th>
              <th scope="col" style="min-width: 6rem;">9 月</th>
              <th scope="col" style="min-width: 8rem;">上期 合計</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">株式会社あかつき</th>
              <td>1,200</td><td>1,500</td><td>1,340</td>
              <td>1,180</td><td>1,620</td><td>1,410</td>
              <td>8,250</td>
            </tr>
            <tr>
              <th scope="row">みなみ商事株式会社</th>
              <td>980</td><td>1,010</td><td>870</td>
              <td>1,120</td><td>990</td><td>1,205</td>
              <td>6,175</td>
            </tr>
            <tr>
              <th scope="row">有限会社きたやま</th>
              <td>420</td><td>380</td><td>455</td>
              <td>390</td><td>512</td><td>470</td>
              <td>2,627</td>
            </tr>
          </tbody>
          <tfoot>
            <tr class="thead-light">
              <th scope="row">合計</th>
              <td>2,600</td><td>2,890</td><td>2,665</td>
              <td>2,690</td><td>3,122</td><td>3,085</td>
              <td>17,052</td>
            </tr>
          </tfoot>
        </table>
      </div>
      <span class="a11y-attr">
        app.js が、はみ出している枠にだけ tabindex="0" role="region" aria-label を付けます
      </span>
      <p class="small text-muted mt-3 mb-0">
        画面を広げて表がはみ出さなくなると、<strong>この 3 つの属性は自動で外れます</strong>。
        スクロールできない枠で Tab が止まっても、利用者には何もできることがないからです。
      </p>
    </t:panel>

    <t:panel title="レイアウトのために表を使わない">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：配置のための table</span>
            <table class="mb-0" style="width: 100%;">
              <tr>
                <td style="width: 30%;">受付番号</td>
                <td>A-0012</td>
              </tr>
              <tr>
                <td>受付日</td>
                <td>2026-09-21</td>
              </tr>
            </table>
            <p class="small mt-3 mb-0">
              読み上げで「表、2 行 2 列」と案内されます。
              データの表ではないので、利用者を混乱させます。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：dl（説明リスト）</span>
            <dl class="row mb-0">
              <dt class="col-4">受付番号</dt>
              <dd class="col-8 mb-1">A-0012</dd>
              <dt class="col-4">受付日</dt>
              <dd class="col-8 mb-0">2026-09-21</dd>
            </dl>
            <p class="small mt-3 mb-0">
              「項目名と値の組」を表す <code>&lt;dl&gt;</code> を使います。
              Bootstrap のグリッドで 2 列に並べられます。
            </p>
          </div>
        </div>
      </div>
      <p class="small text-muted mb-0">
        既存の表をすぐに直せないときは、<code>&lt;table role="presentation"&gt;</code> を付けると、
        読み上げ上は「ただの箱」として扱われます（あくまで応急処置です）。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
