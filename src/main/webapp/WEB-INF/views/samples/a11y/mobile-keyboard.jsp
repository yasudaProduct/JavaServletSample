<%--
  【サンプル】スマホで開くキーボードを切り替える

  Servlet を使わない、JSP だけのサンプルです。
  入力欄に付ける属性 (type / inputmode / enterkeyhint) だけで
  スマートフォンのソフトウェアキーボードが変わることを確かめます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="mobile-keyboard">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>なぜ気にするのか</h2>
    <p>
      業務システムをスマートフォンから使う場面は珍しくなくなりました。
      電話番号の欄でフルキーボードが出てくると、数字を打つのにキーボードの切り替えが 1 回余分に要ります。
      1 画面に 10 項目あれば 10 回です。<strong>属性を 1 つ足すだけで消せる手間</strong>なので、
      入力欄を作るときにまとめて付けてしまうのが楽です。
    </p>
    <p>
      これは「目が見えない人のための対応」ではなく、
      <strong>手が不自由な人・急いでいる人・電車で片手で操作している人すべてに効く</strong>改善です。
      アクセシビリティの多くはこの種の「誰にとっても楽になる」調整でできています。
    </p>

    <h2><code>type</code> と <code>inputmode</code> の違い</h2>
    <p>
      どちらもキーボードに影響しますが、役割が違います。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 22%;">属性</th><th>役割</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>type</code></td>
            <td>
              その欄が<strong>何であるか</strong>を決めます。キーボードだけでなく、
              ブラウザの検証（<code>type="email"</code> なら送信時に形式チェック）、
              値の扱い（<code>type="number"</code> は数値として扱う）、
              専用 UI（<code>type="date"</code> はカレンダー）まで変わります。
            </td>
          </tr>
          <tr>
            <td><code>inputmode</code></td>
            <td>
              <strong>キーボードの見た目だけ</strong>を指定します。値の扱いも検証も変わりません。
              「文字列として受け取りたいが、数字キーボードを出したい」ときに使います。
            </td>
          </tr>
          <tr>
            <td><code>enterkeyhint</code></td>
            <td>
              キーボードの <strong>Enter キーの表示</strong>を変えます。
              「検索」「次へ」「送信」など、押した後に何が起きるかを先に伝えられます。
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>業務でよく使う組み合わせ</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th style="width: 20%;">項目</th><th>書き方</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>電話番号</td>
            <td><code>type="tel" autocomplete="tel"</code><br>
              <code>type="tel"</code> だけで数字キーボードになります（ハイフンも打てます）。</td>
          </tr>
          <tr>
            <td>郵便番号</td>
            <td><code>type="text" inputmode="numeric" maxlength="7" autocomplete="postal-code"</code><br>
              先頭の <code>0</code> を落としたくないので <code>type="number"</code> は使いません。</td>
          </tr>
          <tr>
            <td>社員コード・伝票番号</td>
            <td><code>type="text" inputmode="numeric" maxlength="5"</code><br>
              桁数が決まっている「数字の並び」は数値ではなく文字列です。</td>
          </tr>
          <tr>
            <td>数量</td>
            <td><code>type="text" inputmode="numeric"</code><br>
              計算に使う値でも、受け取ってから <code>Validators.toInt</code> で変換する方が扱いやすいです。</td>
          </tr>
          <tr>
            <td>金額・単価（小数あり）</td>
            <td><code>type="text" inputmode="decimal"</code></td>
          </tr>
          <tr>
            <td>メールアドレス</td>
            <td><code>type="email" autocomplete="email"</code></td>
          </tr>
          <tr>
            <td>検索キーワード</td>
            <td><code>type="search" enterkeyhint="search"</code></td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2><code>type="number"</code> を業務システムで使わない理由</h2>
    <p>
      数字を入れる欄なのだから <code>type="number"</code> が正しそうに見えますが、
      業務システムで使うと次の問題が出ます。デモタブの比較で実際に確かめられます。
    </p>
    <ol>
      <li>
        <strong><code>maxlength</code> が効きません。</strong>
        桁数制限は <code>min</code> / <code>max</code> で書く必要があり、
        「7 桁ちょうど」のような指定がしにくくなります。
      </li>
      <li>
        <strong>先頭の <code>0</code> が消えます。</strong>
        郵便番号 <code>0600042</code> や社員コード <code>00123</code> が壊れます。
      </li>
      <li>
        <strong>数字以外を入れると値が空文字になります。</strong>
        ブラウザが「数値として読めない」と判断した瞬間、
        JavaScript から読む <code>value</code> もサーバに届く値も空になり、
        <strong>利用者には文字が見えているのに、サーバでは未入力</strong>という食い違いが起きます。
        入力チェックのエラーメッセージが「未入力です」になってしまい、原因が分かりません。
      </li>
      <li>
        <strong>スピナー（上下の矢印）で誤操作が起きます。</strong>
        欄にフォーカスがある状態でマウスホイールを回すと、値が勝手に増減するブラウザがあります。
      </li>
      <li>
        <strong>全角数字を受け付けません。</strong>
        日本語入力のまま「１２３」と打つと、そのまま消えるか空になります。
        文字列で受け取っておけば、サーバ側で半角に直す・エラーとして返す、を選べます。
      </li>
    </ol>
    <p>
      <strong>結論</strong>：数量・金額のように「増減させたい数値」だけ <code>type="number"</code>、
      それ以外の「数字の並び」は <code>type="text" inputmode="numeric"</code> にします。
    </p>

    <h2>iOS で勝手に拡大されるのを防ぐ</h2>
    <p>
      iOS の Safari は、<strong>文字サイズが 16px 未満の入力欄</strong>にフォーカスすると、
      読みやすくするために画面を自動で拡大します。拡大されたままレイアウトが崩れて見えるので、
      入力欄の <code>font-size</code> は <strong>16px 以上</strong>にしておきます。
    </p>
    <p>
      <code>&lt;meta name="viewport" content="... user-scalable=no"&gt;</code> を書けば拡大は止まりますが、
      <strong>利用者が自分で拡大することまで禁止してしまう</strong>ため、使ってはいけません。
      文字サイズで解決します。
    </p>

    <h2>確かめ方</h2>
    <ul>
      <li>
        <strong>実機が一番確実です。</strong>
        開発環境は <code>http://localhost:8080/</code> なので、同じネットワークにいるスマートフォンから
        PC の IP アドレスで開けば、この画面をそのまま触れます。
      </li>
      <li>
        PC のブラウザでは<strong>キーボードの見た目は変わりません</strong>
        （ソフトウェアキーボードが無いため）。開発者ツールのスマホ表示でも変わりません。
      </li>
      <li>
        キーボードの出方は <strong>OS と IME によって違います</strong>。
        「この属性なら必ずこの配列」とまでは決まっていないので、
        主要な端末で確認して、指定は「希望を伝えるもの」と考えておきます。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // type="number" と type="text" で、実際にサーバへ送られる値がどう違うかを表示します。
      // (input.value は、そのままフォーム送信される値と同じものです)
      (function () {
        'use strict';

        function watch(inputId, outputId) {
          var input = document.getElementById(inputId);
          var output = document.getElementById(outputId);
          if (!input || !output) {
            return;
          }
          input.addEventListener('input', function () {
            // 受け取った文字列は textContent で入れます (innerHTML に入れると XSS になります)
            if (input.value === '') {
              output.textContent = '（空文字）';
              output.classList.add('text-danger');
            } else {
              output.textContent = '"' + input.value + '"（' + input.value.length + ' 文字）';
              output.classList.remove('text-danger');
            }
          });
        }

        watch('numBad', 'numBadValue');
        watch('numGood', 'numGoodValue');
      })();
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <div class="alert alert-info" role="alert">
      <strong>スマートフォンで開いてください。</strong>
      このページの本題はソフトウェアキーボードの見た目なので、PC では変化が分かりません。
      各欄の下に、実際に付いている属性を書いてあります。
    </div>

    <t:panel title="入力欄ごとにキーボードを変える" note="欄をタップして、出てくるキーボードを見比べてください">
      <form onsubmit="return false;">
        <div class="form-row">
          <div class="form-group col-md-6">
            <label for="kbTel">電話番号</label>
            <input type="tel" class="form-control" id="kbTel" name="tel"
                   autocomplete="tel" placeholder="0312345678">
            <span class="a11y-attr">type="tel" autocomplete="tel"</span>
          </div>

          <div class="form-group col-md-6">
            <label for="kbZip">郵便番号（ハイフン無し 7 桁）</label>
            <input type="text" class="form-control" id="kbZip" name="zip"
                   inputmode="numeric" maxlength="7" autocomplete="postal-code" placeholder="0600042">
            <span class="a11y-attr">type="text" inputmode="numeric" maxlength="7" autocomplete="postal-code"</span>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group col-md-6">
            <label for="kbQty">数量</label>
            <input type="text" class="form-control" id="kbQty" name="qty"
                   inputmode="numeric" maxlength="4" placeholder="10">
            <span class="a11y-attr">type="text" inputmode="numeric"</span>
          </div>

          <div class="form-group col-md-6">
            <label for="kbPrice">単価（小数あり）</label>
            <input type="text" class="form-control" id="kbPrice" name="price"
                   inputmode="decimal" placeholder="1980.50">
            <span class="a11y-attr">type="text" inputmode="decimal" … 小数点キーが出ます</span>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group col-md-6">
            <label for="kbMail">メールアドレス</label>
            <input type="email" class="form-control" id="kbMail" name="mail"
                   autocomplete="email" placeholder="taro@example.com">
            <span class="a11y-attr">type="email" autocomplete="email" … @ と . のキーが出ます</span>
          </div>

          <div class="form-group col-md-6">
            <label for="kbUrl">社内システムの URL</label>
            <input type="url" class="form-control" id="kbUrl" name="url"
                   inputmode="url" placeholder="https://example.com">
            <span class="a11y-attr">type="url" inputmode="url" … / と .com のキーが出ます</span>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group col-md-6 mb-md-0">
            <label for="kbSearch">取引先を検索</label>
            <input type="search" class="form-control" id="kbSearch" name="q"
                   enterkeyhint="search" placeholder="株式会社…">
            <span class="a11y-attr">type="search" enterkeyhint="search" … Enter が「検索」になります</span>
          </div>

          <div class="form-group col-md-6 mb-0">
            <label for="kbDate">希望日</label>
            <input type="date" class="form-control" id="kbDate" name="date">
            <span class="a11y-attr">type="date" … キーボードではなく日付の選択画面が出ます</span>
          </div>
        </div>
      </form>
    </t:panel>

    <t:panel title="Enter キーの文字を変える（enterkeyhint）"
             note="フォームの途中の欄は「次へ」、最後の欄は「送信」にすると迷いません">
      <form onsubmit="return false;">
        <div class="form-row">
          <div class="form-group col-md-4">
            <label for="ekNext">氏名（次の欄がある）</label>
            <input type="text" class="form-control" id="ekNext" enterkeyhint="next">
            <span class="a11y-attr">enterkeyhint="next"</span>
          </div>
          <div class="form-group col-md-4">
            <label for="ekSearch">キーワード</label>
            <input type="search" class="form-control" id="ekSearch" enterkeyhint="search">
            <span class="a11y-attr">enterkeyhint="search"</span>
          </div>
          <div class="form-group col-md-4 mb-0">
            <label for="ekSend">備考（最後の欄）</label>
            <input type="text" class="form-control" id="ekSend" enterkeyhint="send">
            <span class="a11y-attr">enterkeyhint="send"</span>
          </div>
        </div>
      </form>
      <p class="mb-0 text-muted small">
        指定できるのは <code>enter</code> / <code>done</code> / <code>go</code> / <code>next</code> /
        <code>previous</code> / <code>search</code> / <code>send</code> の 7 つです。
      </p>
    </t:panel>

    <t:panel title="type=&quot;number&quot; の落とし穴"
             note="両方の欄に「00123」「abc」「１２３」を打ち込んで、下の表示を見比べてください">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：type="number"</span>
            <label for="numBad">社員コード（5 桁）</label>
            <input type="number" class="form-control" id="numBad" maxlength="5">
            <span class="a11y-attr">type="number" maxlength="5"（この maxlength は効きません）</span>
            <p class="mt-3 mb-1 small">
              サーバに届く値：
              <code id="numBadValue" class="a11y-attr d-inline">（未入力）</code>
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：type="text" + inputmode="numeric"</span>
            <label for="numGood">社員コード（5 桁）</label>
            <input type="text" class="form-control" id="numGood" inputmode="numeric" maxlength="5">
            <span class="a11y-attr">type="text" inputmode="numeric" maxlength="5"</span>
            <p class="mt-3 mb-1 small">
              サーバに届く値：
              <code id="numGoodValue" class="a11y-attr d-inline">（未入力）</code>
            </p>
          </div>
        </div>
      </div>
      <ul class="mb-0 small">
        <li><code>00123</code> … 左は先頭の 0 が消えます。右はそのまま残ります。</li>
        <li><code>abc</code> や <code>１２３</code>（全角）… 左は<strong>画面に文字が見えていても値が空</strong>になります。</li>
        <li>6 桁以上 … 左は <code>maxlength</code> が効かず、いくらでも入ります。</li>
        <li>左の欄にフォーカスした状態でマウスホイールを回すと、値が勝手に増減します。</li>
      </ul>
    </t:panel>

    <t:panel title="iOS で勝手に拡大されないようにする"
             note="iPhone の Safari で 2 つの欄を順にタップしてみてください">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：14px（タップすると画面が拡大されます）</span>
            <label for="zoomBad">担当者名</label>
            <input type="text" class="form-control" id="zoomBad" style="font-size: 14px;">
            <span class="a11y-attr">font-size: 14px</span>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：16px（拡大されません）</span>
            <label for="zoomGood">担当者名</label>
            <input type="text" class="form-control" id="zoomGood" style="font-size: 16px;">
            <span class="a11y-attr">font-size: 16px</span>
          </div>
        </div>
      </div>
      <p class="mb-0 small text-muted">
        Bootstrap 4 の <code>.form-control</code> は <code>font-size: 1rem</code>（＝16px）なので、
        既定のままなら問題ありません。<code>.form-control-sm</code> や独自 CSS で小さくしたときだけ注意します。
      </p>
    </t:panel>

    <t:panel title="inputmode で指定できる値">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th style="width: 8rem;">値</th>
              <th>出るキーボード</th>
              <th style="width: 30%;">使いどころ</th>
            </tr>
          </thead>
          <tbody>
            <tr><td><code>text</code></td><td>標準（既定値）</td><td>ふつうの文字入力</td></tr>
            <tr><td><code>numeric</code></td><td>数字のみ</td><td>郵便番号、社員コード、数量</td></tr>
            <tr><td><code>decimal</code></td><td>数字＋小数点</td><td>金額、単価、重量</td></tr>
            <tr><td><code>tel</code></td><td>電話のダイヤルパッド（<code>*</code> <code>#</code> 付き）</td><td>電話番号、内線番号</td></tr>
            <tr><td><code>email</code></td><td>標準＋<code>@</code></td><td>メールアドレス</td></tr>
            <tr><td><code>url</code></td><td>標準＋<code>/</code> <code>.com</code></td><td>URL</td></tr>
            <tr><td><code>search</code></td><td>標準（Enter が「検索」）</td><td>検索欄</td></tr>
            <tr><td><code>none</code></td><td>キーボードを出さない</td><td>自前の入力パッドを画面に置くとき</td></tr>
          </tbody>
        </table>
      </div>
    </t:panel>
  </jsp:body>

</t:sample>
