<%--
  【サンプル】色・コントラスト・拡大・動きへの配慮

  Servlet を使わない、JSP だけのサンプルです。
  コントラスト比の数値は sRGB の相対輝度から計算した実測値を書いています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="visual-design">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>これは「一部の人のため」の話ではない</h2>
    <p>
      日本人男性のおよそ 20 人に 1 人（約 5%）は、色の見え方が多数派と異なります。
      40 代を過ぎると水晶体が黄色くなり、薄い色の区別が付きにくくなります。
      屋外で画面を見れば誰でもコントラストが足りなくなり、
      安い外部ディスプレイでは薄い灰色がほとんど見えません。
    </p>
    <p>
      <strong>コントラストと「色以外の手がかり」は、環境の悪さに対する保険</strong>でもあります。
    </p>

    <h2>コントラスト比の基準</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 30%;">対象</th><th>必要な比（レベル AA）</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>通常の文字</td>
            <td><strong>4.5 : 1</strong> 以上（達成基準 1.4.3）</td>
          </tr>
          <tr>
            <td>大きな文字<br>（24px 以上、または太字 18.66px 以上）</td>
            <td><strong>3 : 1</strong> 以上</td>
          </tr>
          <tr>
            <td>
              部品の輪郭・状態<br>（入力欄の枠線、チェックの印、フォーカスの枠、グラフの線）
            </td>
            <td><strong>3 : 1</strong> 以上（達成基準 1.4.11）</td>
          </tr>
          <tr>
            <td>装飾・無効状態の部品・ロゴ</td>
            <td>基準の対象外</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      比は 1:1（同じ色）から 21:1（白と黒）までの値です。
      <strong>ブラウザの開発者ツールで測れます</strong>：要素を選んで
      <code>color</code> の横の色見本をクリックすると、
      コントラスト比と AA / AAA の合否が出ます。
    </p>

    <h2>Bootstrap 4 の既定色は、そのままでは足りないものがある</h2>
    <p>
      デモタブに実測値を並べてあります。注意が要るのは次の 3 つです。
    </p>
    <ul>
      <li>
        <strong><code>.btn-primary</code>（<code>#007bff</code> + 白文字）は 3.98 : 1</strong>。
        通常サイズの文字に必要な 4.5 : 1 に届きません。
        <code>#0069d9</code>（5.22 : 1）や <code>#0062cc</code>（5.80 : 1）まで暗くすると満たせます
      </li>
      <li>
        <strong><code>.btn-success</code>（<code>#28a745</code> + 白文字）は 3.13 : 1</strong>、
        <strong><code>.btn-info</code>（<code>#17a2b8</code> + 白文字）は 3.04 : 1</strong>。
        どちらも足りません
      </li>
      <li>
        <strong><code>.text-muted</code>（<code>#6c757d</code>）は 4.69 : 1</strong> で辛うじて足ります。
        これより薄い灰色（<code>#adb5bd</code> は 2.07 : 1）を本文に使ってはいけません
      </li>
    </ul>
    <p>
      逆に <code>.btn-warning</code> は<strong>黒い文字</strong>（<code>#212529</code>）なので 9.46 : 1 あります。
      「白文字にした方がきれい」と変えると 1.63 : 1 になり、ほぼ読めなくなります。
    </p>
    <p>
      サイト全体で直すなら、<code>app.css</code> の <code>:root</code> に置いた変数を書き換えます。
      このサイトの <code>--site-accent</code>（<code>#2b5fd9</code>）は 5.61 : 1 です。
    </p>

    <h2>色だけで情報を伝えない（達成基準 1.4.1）</h2>
    <p>
      「必須項目は赤字です」「エラー行は赤、警告行は黄色です」という画面は、
      色が見えない人には<strong>すべて同じに見えます</strong>。
      色は<strong>補助</strong>として使い、<strong>文字・記号・形</strong>のどれかを必ず添えます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 34%;">✗ 色だけ</th><th>✓ 色 ＋ もう 1 つ</th></tr>
        </thead>
        <tbody>
          <tr><td>必須項目を赤字にする</td><td>ラベルに「（必須）」と書く</td></tr>
          <tr><td>エラー欄の枠を赤くする</td><td>枠＋「エラー：」の文字＋メッセージ</td></tr>
          <tr><td>ステータスを色の丸で示す</td><td>丸＋「承認済み」「差し戻し」の文字</td></tr>
          <tr><td>グラフを色だけで区別する</td><td>線の種類（実線・破線）を変える、直接ラベルを置く</td></tr>
          <tr><td>リンクを色だけで示す</td><td>下線を付ける（本文中のリンクは特に）</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      <strong>確かめ方</strong>：画面のスクリーンショットをグレースケールに変換して、
      まだ区別が付くかを見ます。付かなければ、色だけに頼っています。
    </p>

    <h2>拡大しても壊れないようにする</h2>
    <ul>
      <li>
        <strong>達成基準 1.4.4「テキストのサイズ変更」（AA）</strong>：
        文字を 200% にしても、内容と機能が失われないこと
      </li>
      <li>
        <strong>達成基準 1.4.10「リフロー」（AA）</strong>：
        幅 320px 相当（＝ 1280px を 400% 拡大した状態）でも、
        <strong>横スクロールせずに読めること</strong>
      </li>
      <li>
        <strong>達成基準 1.4.12「テキストの間隔」（AA）</strong>：
        行間を 1.5 倍、文字間隔を 0.12em にしても、文字が欠けたり重なったりしないこと
      </li>
    </ul>
    <p>
      守るための書き方は難しくありません。
    </p>
    <ul>
      <li>
        <strong>高さを固定しない。</strong>
        <code>height: 40px</code> と書いた箱は、文字が大きくなるとはみ出します。
        <code>min-height</code> と <code>padding</code> で組みます
      </li>
      <li>
        <strong>文字サイズは <code>rem</code> で。</strong>
        <code>px</code> で書くと、ブラウザの文字サイズ設定が効かないことがあります
      </li>
      <li>
        <strong><code>overflow: hidden</code> で文字を切らない。</strong>
        拡大したときに、そこだけ読めなくなります
      </li>
      <li>
        <strong><code>user-scalable=no</code> / <code>maximum-scale=1</code> を書かない。</strong>
        拡大そのものを禁止してしまいます。
        このサイトの <code>layout.tag</code> も
        <code>width=device-width, initial-scale=1</code> だけにしています
      </li>
    </ul>

    <h2>動きを減らす（<code>prefers-reduced-motion</code>）</h2>
    <p>
      前庭障害のある人にとって、視差効果や大きく動くアニメーションは
      <strong>めまいや吐き気の原因</strong>になります。
      OS には「動きを減らす」設定があり、CSS からその状態を読めます。
    </p>
    <pre><code class="language-css">@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: .01ms !important;
    transition-duration: .01ms !important;
  }
}</code></pre>
    <ul>
      <li>Windows … 設定 &gt; アクセシビリティ &gt; 視覚効果 &gt; アニメーション効果</li>
      <li>macOS / iOS … システム設定（設定）&gt; アクセシビリティ &gt; 動作 &gt; 視差効果を減らす</li>
    </ul>
    <p>
      また、<strong>5 秒以上自動で動き続けるもの</strong>（カルーセル、自動スクロール）には、
      止めるボタンを付けることが求められています（達成基準 2.2.2）。
      <strong>1 秒間に 3 回以上光るもの</strong>は、発作を誘発する恐れがあるため作ってはいけません（2.3.1）。
    </p>

    <h2>ダークモード（<code>prefers-color-scheme</code>）</h2>
    <p>
      必須ではありませんが、対応するなら<strong>ダークモードでもコントラスト比を測り直します</strong>。
      明るい背景で 4.5 : 1 あった色が、暗い背景では足りなくなることがよくあります。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // 画面をグレースケールにして、「色だけに頼っていないか」を確かめます。
      (function () {
        'use strict';

        var toggle = document.getElementById('grayscaleToggle');
        var area = document.getElementById('colorOnlyArea');
        if (!toggle || !area) {
          return;
        }

        toggle.addEventListener('click', function () {
          var on = area.style.filter === 'grayscale(1)';
          area.style.filter = on ? '' : 'grayscale(1)';
          toggle.textContent = on ? 'グレースケールにする' : '色を戻す';
          toggle.setAttribute('aria-pressed', on ? 'false' : 'true');
        });
      })();
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="Bootstrap 4 の既定色を測ってみる"
             note="sRGB の相対輝度から計算した実測値です">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <caption class="sr-only">Bootstrap 4 の既定色のコントラスト比</caption>
          <thead class="thead-light">
            <tr>
              <th scope="col" style="min-width: 11rem;">見本</th>
              <th scope="col" style="min-width: 12rem;">色</th>
              <th scope="col" style="min-width: 6rem;">比</th>
              <th scope="col" style="min-width: 10rem;">通常文字（4.5:1）</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row"><span class="btn btn-primary btn-sm">.btn-primary</span></th>
              <td><code>#007bff</code> に白文字</td>
              <td>3.98 : 1</td>
              <td class="text-danger font-weight-bold">✗ 足りない</td>
            </tr>
            <tr>
              <th scope="row">
                <span class="btn btn-sm text-white" style="background-color: #0062cc;">暗くした primary</span>
              </th>
              <td><code>#0062cc</code> に白文字</td>
              <td>5.80 : 1</td>
              <td class="text-success font-weight-bold">✓ 満たす</td>
            </tr>
            <tr>
              <th scope="row"><span class="btn btn-success btn-sm">.btn-success</span></th>
              <td><code>#28a745</code> に白文字</td>
              <td>3.13 : 1</td>
              <td class="text-danger font-weight-bold">✗ 足りない</td>
            </tr>
            <tr>
              <th scope="row"><span class="btn btn-info btn-sm">.btn-info</span></th>
              <td><code>#17a2b8</code> に白文字</td>
              <td>3.04 : 1</td>
              <td class="text-danger font-weight-bold">✗ 足りない</td>
            </tr>
            <tr>
              <th scope="row"><span class="btn btn-warning btn-sm">.btn-warning</span></th>
              <td><code>#ffc107</code> に<strong>黒文字</strong></td>
              <td>9.46 : 1</td>
              <td class="text-success font-weight-bold">✓ 満たす</td>
            </tr>
            <tr>
              <th scope="row">
                <span class="btn btn-sm text-white" style="background-color: #ffc107;">白文字にすると</span>
              </th>
              <td><code>#ffc107</code> に白文字</td>
              <td>1.63 : 1</td>
              <td class="text-danger font-weight-bold">✗ ほぼ読めない</td>
            </tr>
            <tr>
              <th scope="row"><span class="text-muted">.text-muted の文章</span></th>
              <td><code>#6c757d</code> / 白背景</td>
              <td>4.69 : 1</td>
              <td class="text-success font-weight-bold">✓ 満たす（余裕は無い）</td>
            </tr>
            <tr>
              <th scope="row"><span style="color: #adb5bd;">薄い灰色の文章</span></th>
              <td><code>#adb5bd</code> / 白背景</td>
              <td>2.07 : 1</td>
              <td class="text-danger font-weight-bold">✗ 本文に使わない</td>
            </tr>
            <tr>
              <th scope="row"><span style="color: #2b5fd9;">このサイトのリンク色</span></th>
              <td><code>#2b5fd9</code> / 白背景</td>
              <td>5.61 : 1</td>
              <td class="text-success font-weight-bold">✓ 満たす</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="small text-muted mt-3 mb-0">
        <strong>ボタンの文字は通常 16px</strong> なので、大きな文字の例外（3 : 1）は使えません。
        <code>.btn-lg</code>（20px）でも 24px には届かないため、やはり 4.5 : 1 が必要です。
      </p>
    </t:panel>

    <t:panel title="色だけに頼っていないか、グレースケールで確かめる"
             note="ボタンを押すと、この枠の中だけ色が抜けます">
      <p>
        <button type="button" class="btn btn-secondary" id="grayscaleToggle" aria-pressed="false">
          グレースケールにする
        </button>
      </p>

      <div id="colorOnlyArea">
        <div class="a11y-compare">
          <div>
            <div class="a11y-case a11y-case--bad">
              <span class="a11y-case__label">✗ 悪い例：色だけで状態を示す</span>
              <ul class="list-unstyled mb-0">
                <li class="mb-2">
                  <span class="badge badge-pill badge-success">&nbsp;</span>
                  9 月分 交通費
                </li>
                <li class="mb-2">
                  <span class="badge badge-pill badge-warning">&nbsp;</span>
                  9 月分 備品購入
                </li>
                <li class="mb-0">
                  <span class="badge badge-pill badge-danger">&nbsp;</span>
                  9 月分 出張旅費
                </li>
              </ul>
              <p class="small mt-3 mb-0">
                色を抜くと、<strong>3 つとも同じ</strong>に見えます。
              </p>
            </div>
          </div>
          <div>
            <div class="a11y-case a11y-case--good">
              <span class="a11y-case__label">✓ 良い例：色 ＋ 文字</span>
              <ul class="list-unstyled mb-0">
                <li class="mb-2">
                  <span class="badge badge-success">承認済み</span>
                  9 月分 交通費
                </li>
                <li class="mb-2">
                  <span class="badge badge-warning">確認中</span>
                  9 月分 備品購入
                </li>
                <li class="mb-0">
                  <span class="badge badge-danger">差し戻し</span>
                  9 月分 出張旅費
                </li>
              </ul>
              <p class="small mt-3 mb-0">
                色を抜いても読めます。<strong>色は「速く見つけるための補助」</strong>です。
              </p>
            </div>
          </div>
        </div>

        <div class="a11y-compare">
          <div>
            <div class="a11y-case a11y-case--bad">
              <span class="a11y-case__label">✗ 悪い例：本文中のリンクが色だけ</span>
              <p class="mb-0">
                申請の手順は
                <a href="#" style="text-decoration: none;">就業規則</a>
                を確認してください。
              </p>
              <p class="small mt-3 mb-0">
                色を抜くと、どこがリンクなのか分かりません。
              </p>
            </div>
          </div>
          <div>
            <div class="a11y-case a11y-case--good">
              <span class="a11y-case__label">✓ 良い例：下線を付ける</span>
              <p class="mb-0">
                申請の手順は
                <a href="#">就業規則</a>
                を確認してください。
              </p>
              <p class="small mt-3 mb-0">
                下線があれば、色が分からなくてもリンクだと伝わります。
              </p>
            </div>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="拡大しても壊れないか"
             note="ブラウザの拡大（Ctrl と + / Command と +）を 200% にして見比べてください">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：高さを固定して、はみ出しを隠した</span>
            <div style="height: 2.5rem; overflow: hidden; border: 1px solid #ced4da;
                        border-radius: 4px; padding: .375rem .75rem;">
              承認者が不在の場合は、代理承認者に依頼してください。
            </div>
            <p class="small mt-3 mb-0">
              拡大すると文章が枠に収まらなくなり、<code>overflow: hidden</code> で
              <strong>読めない部分が出ます</strong>。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：最小の高さと余白で組む</span>
            <div style="min-height: 2.5rem; border: 1px solid #ced4da;
                        border-radius: 4px; padding: .375rem .75rem;">
              承認者が不在の場合は、代理承認者に依頼してください。
            </div>
            <p class="small mt-3 mb-0">
              文字が増えれば枠も伸びます。拡大しても内容は失われません。
            </p>
          </div>
        </div>
      </div>
      <ul class="small text-muted mb-0">
        <li>スマートフォンでの確認は、幅 320px（iPhone SE 相当）に合わせるのが目安です</li>
        <li>
          このページの表も <code>.table-responsive</code> で囲んであるので、
          拡大すると横スクロールに切り替わります
        </li>
      </ul>
    </t:panel>

    <t:panel title="動きを減らす設定に従う（prefers-reduced-motion）"
             note="OS の「動きを減らす」設定を切り替えて、この画面を再読み込みしてみてください">
      <div class="d-flex align-items-center" style="min-height: 4rem;">
        <div class="a11y-motion" aria-hidden="true"></div>
      </div>
      <p class="small text-muted a11y-motion-state mb-2"></p>
      <span class="a11y-attr">
        @media (prefers-reduced-motion: reduce) { .a11y-motion { animation: none; } }
      </span>
      <p class="small text-muted mt-3 mb-0">
        四角には <code>aria-hidden="true"</code> を付けています。
        <strong>意味を持たない動きは、読み上げにとっては雑音</strong>だからです。
      </p>
    </t:panel>

    <t:panel title="無効なボタンは、コントラストの基準の対象外">
      <p class="mb-2">
        <button type="button" class="btn btn-primary" disabled>保存（無効）</button>
        <button type="button" class="btn btn-primary ml-2">保存</button>
      </p>
      <p class="small text-muted mb-0">
        <code>disabled</code> の部品はコントラスト比の対象外です。
        ただし<strong>「押せない理由」が分からないと困る</strong>ので、
        近くに文字で理由を書くか、ボタンは押せるままにして
        押したときにエラーを出す方が親切なことも多いです。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
