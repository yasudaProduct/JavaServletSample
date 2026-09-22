<%--
  【サンプル】自分の画面をチェックする手順

  Servlet を使わない、JSP だけのサンプルです。
  デモの中身はチェックリストそのもので、
  チェックした件数を role="status" で知らせる作りにしてあります。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="a11y-check">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>道具より先に、手でできることがある</h2>
    <p>
      アクセシビリティの点検というと専用ツールを思い浮かべますが、
      <strong>実務で見つかる問題の多くは、キーボードと拡大とグレースケールで見つかります</strong>。
      しかも 1 画面あたり 5 分もかかりません。
    </p>
    <p>
      自動チェックツールで機械的に判定できるのは、
      <strong>問題全体の 3〜4 割程度</strong>と言われています。
      「<code>alt</code> が無い」は機械で分かっても、
      「<code>alt</code> の内容が間違っている」は人にしか分かりません。
      <strong>自動チェックは足切り、本番は手で確かめる</strong>、という順番になります。
    </p>

    <h2>手順 1：キーボードだけで一周する（2 分）</h2>
    <p>
      マウスから手を離し、<kbd>Tab</kbd> だけで画面の端から端まで移動します。
    </p>
    <ul>
      <li>すべての操作にたどり着けるか（送信、削除、モーダル、表の並び替え）</li>
      <li>今どこにいるかが常に見えているか</li>
      <li>順番が、見た目の並びと合っているか</li>
      <li>フォーカスが画面の外や、隠れている要素に迷い込まないか</li>
      <li>モーダルを閉じたら、開いたボタンに戻るか</li>
    </ul>
    <p>
      macOS の Safari は、標準設定では Tab がリンクで止まりません。
      「設定 &gt; 詳細 &gt; Tab キーを押したときに Web ページ上の各項目を強調表示」を先に有効にします。
      詳しくは <a href="${ctx}/samples/a11y/keyboard-operation">マウスを使わずに操作する</a> にあります。
    </p>

    <h2>手順 2：拡大する（1 分）</h2>
    <ul>
      <li>
        <kbd>Ctrl</kbd> + <kbd>+</kbd>（Mac は <kbd>Command</kbd> + <kbd>+</kbd>）で
        <strong>200%</strong> にして、内容と機能が失われないか
      </li>
      <li>
        開発者ツールで<strong>幅 320px</strong> にして、横スクロールせずに読めるか
      </li>
      <li>入力欄や固定高さの箱から、文字がはみ出して切れていないか</li>
    </ul>

    <h2>手順 3：色を抜く（30 秒）</h2>
    <p>
      開発者ツールのレンダリング設定で <code>grayscale</code> のエミュレーションを掛けるか、
      スクリーンショットをグレースケールに変換します。
      <strong>それでも状態・必須・エラー・グラフの系列が区別できるか</strong>を見ます。
      <a href="${ctx}/samples/a11y/visual-design">色・コントラスト・拡大・動き</a> のデモで試せます。
    </p>

    <h2>手順 4：自動チェックを掛ける（1 分）</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 26%;">道具</th><th>使い方と、見つかるもの</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Lighthouse</strong></td>
            <td>
              Chrome の開発者ツールに最初から入っています。
              「Lighthouse」タブ &gt; Accessibility にチェック &gt; 実行。
              点数より、出てきた項目の中身を読みます
            </td>
          </tr>
          <tr>
            <td><strong>axe DevTools</strong></td>
            <td>
              ブラウザの拡張機能。Lighthouse より detailed で、
              <strong>直し方まで表示されます</strong>。無料版で十分実用になります
            </td>
          </tr>
          <tr>
            <td><strong>W3C Markup Validation</strong></td>
            <td>
              HTML 自体の検証。<strong><code>id</code> の重複</strong>や、
              閉じ忘れによる入れ子の崩れが見つかります。
              これらは読み上げの挙動を直接壊します
            </td>
          </tr>
          <tr>
            <td><strong>開発者ツールのコントラスト比</strong></td>
            <td>
              要素を選び、<code>color</code> の色見本をクリックすると
              比と AA / AAA の合否が出ます
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <strong>開発環境は <code>localhost</code> なので、外部のオンライン検証サービスには掛けられません。</strong>
      ブラウザ拡張の axe DevTools なら、そのまま使えます。
    </p>

    <h2>手順 5：読み上げを聞く（5 分）</h2>
    <p>
      全部を覚える必要はありません。<strong>起動・停止と、次へ進むキー</strong>だけ知っていれば、
      自分の画面がどう読まれるかは確かめられます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 22%;">環境</th><th>起動と基本操作</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Windows<br>ナレーター</strong></td>
            <td>
              <kbd>Ctrl</kbd> + <kbd>Windows</kbd> + <kbd>Enter</kbd> で起動・停止。
              <kbd>CapsLock</kbd> + <kbd>→</kbd> で次の要素へ。
              <strong>OS に最初から入っている</strong>ので、まずこれで十分です
            </td>
          </tr>
          <tr>
            <td><strong>Windows<br>NVDA</strong></td>
            <td>
              無料で、日本では実利用者が多いソフトです。
              実際の利用者に近い確認をしたいときに入れます
            </td>
          </tr>
          <tr>
            <td><strong>macOS / iOS<br>VoiceOver</strong></td>
            <td>
              Mac は <kbd>Command</kbd> + <kbd>F5</kbd>。
              iPhone は「設定 &gt; アクセシビリティ &gt; VoiceOver」、
              または<strong>サイドボタン 3 回押し</strong>に割り当てておくと切り替えが楽です
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      聞くときの観点は 3 つだけです。
    </p>
    <ol>
      <li><strong>入力欄で、項目名が読まれるか</strong></li>
      <li><strong>ボタンで、何のボタンか読まれるか</strong>（「ボタン」だけになっていないか）</li>
      <li><strong>送信したあと、結果が読まれるか</strong></li>
    </ol>

    <h2>どの基準に合わせるか</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 26%;">名前</th><th>位置づけ</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>WCAG 2.1 / 2.2</strong></td>
            <td>
              W3C が作っている国際的なガイドライン。
              A（最低限）/ AA / AAA の 3 段階があり、<strong>実務の目標は AA</strong> です
            </td>
          </tr>
          <tr>
            <td><strong>JIS X 8341-3:2016</strong></td>
            <td>
              日本産業規格。<strong>WCAG 2.0 と技術的に同一</strong>の内容です。
              公共調達の仕様書で名前が出てきます
            </td>
          </tr>
          <tr>
            <td><strong>障害者差別解消法</strong></td>
            <td>
              2024 年 4 月から、民間事業者にも<strong>合理的配慮の提供が義務</strong>になりました。
              Web についても「環境の整備」として対応が求められます
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>新しく画面を作るときの順番</h2>
    <p>
      最後にまとめて直すのはいちばん高くつきます。作りながら次の順で押さえます。
    </p>
    <ol>
      <li>
        <strong>正しい要素を使う</strong>：ボタンは <code>&lt;button&gt;</code>、
        移動は <code>&lt;a&gt;</code>、表は <code>&lt;table&gt;</code> +
        <code>&lt;th scope&gt;</code>、見出しは <code>&lt;h1&gt;</code> から順に。
        <strong>ここで 7 割が片付きます</strong>
      </li>
      <li>
        <strong>入力欄にラベルと属性を付ける</strong>：<code>&lt;label for&gt;</code>、
        <code>autocomplete</code>、<code>inputmode</code>
      </li>
      <li><strong>エラーと完了の伝え方を決める</strong>：エラーサマリとフォーカス移動</li>
      <li><strong>色とコントラストを確かめる</strong></li>
      <li><strong>キーボードで一周する</strong></li>
    </ol>
    <p>
      <strong>ARIA（<code>role</code> や <code>aria-*</code>）は、
      標準の HTML で表せないときの最後の手段です。</strong>
      「ARIA を使わない方が、間違った ARIA を使うよりよい」というのが
      W3C の書いている原則です。<code>&lt;div role="button"&gt;</code> と書くくらいなら、
      <code>&lt;button&gt;</code> と書きます。
    </p>

    <h2>このカテゴリのサンプル</h2>
    <ul>
      <li><a href="${ctx}/samples/a11y/mobile-keyboard">スマホで開くキーボードを切り替える</a></li>
      <li><a href="${ctx}/samples/a11y/autocomplete">自動入力（autocomplete）と、余計なお節介を切る</a></li>
      <li><a href="${ctx}/samples/a11y/form-labels">ラベルの付け方と入力欄のグループ化</a></li>
      <li><a href="${ctx}/samples/a11y/error-summary">エラーの伝え方（エラーサマリとフォーカス移動）</a></li>
      <li><a href="${ctx}/samples/a11y/keyboard-operation">マウスを使わずに操作する</a></li>
      <li><a href="${ctx}/samples/a11y/live-region">画面の変化を読み上げで知らせる</a></li>
      <li><a href="${ctx}/samples/a11y/accessible-table">表を読み上げと相性よく作る</a></li>
      <li><a href="${ctx}/samples/a11y/alt-text">画像とアイコンの代替テキスト</a></li>
      <li><a href="${ctx}/samples/a11y/visual-design">色・コントラスト・拡大・動きへの配慮</a></li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // チェックした件数を数えて role="status" で知らせます。
      // (このチェックリスト自体が、fieldset と ライブリージョンの実例になっています)
      (function () {
        'use strict';

        var list = document.getElementById('checkList');
        var status = document.getElementById('checkStatus');
        var reset = document.getElementById('checkReset');
        if (!list || !status) {
          return;
        }

        var boxes = list.querySelectorAll('input[type="checkbox"]');

        function update() {
          var done = 0;
          Array.prototype.forEach.call(boxes, function (box) {
            if (box.checked) {
              done += 1;
            }
          });

          // 同じ文字列だと読み上げられないので、終わったときは文言を変えます
          status.textContent = done === boxes.length
            ? 'すべて確認しました。' + boxes.length + ' 件すべて完了です。'
            : boxes.length + ' 件中 ' + done + ' 件を確認しました。';
        }

        Array.prototype.forEach.call(boxes, function (box) {
          box.addEventListener('change', update);
        });

        if (reset) {
          reset.addEventListener('click', function () {
            Array.prototype.forEach.call(boxes, function (box) {
              box.checked = false;
            });
            update();
          });
        }

        update();
      })();
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <div class="alert alert-info" role="alert">
      このチェックリストは、<strong>自分が作った画面をそのまま点検する</strong>ために使えます。
      上から順にやって 10 分ほどです。チェックの状態は保存されません。
    </div>

    <t:panel title="画面を 1 つ点検するチェックリスト"
             note="チェックした件数は role=&quot;status&quot; で読み上げられます">

      <div id="checkList">

        <fieldset class="mb-4">
          <legend class="col-form-label pt-0 pb-2" style="font-size: 1rem;">
            1. キーボードだけで一周する（マウスから手を離す）
          </legend>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckKey1">
            <label class="custom-control-label" for="ckKey1">
              すべての操作に Tab でたどり着ける（送信・削除・モーダル・並び替え）
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckKey2">
            <label class="custom-control-label" for="ckKey2">
              今どこにフォーカスがあるか、常に目で見て分かる
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckKey3">
            <label class="custom-control-label" for="ckKey3">
              Tab の順番が、画面の見た目の並びと合っている
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-0">
            <input type="checkbox" class="custom-control-input" id="ckKey4">
            <label class="custom-control-label" for="ckKey4">
              モーダルを閉じたあと、開いたボタンにフォーカスが戻る
            </label>
          </div>
        </fieldset>

        <fieldset class="mb-4">
          <legend class="col-form-label pt-0 pb-2" style="font-size: 1rem;">
            2. 拡大する
          </legend>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckZoom1">
            <label class="custom-control-label" for="ckZoom1">
              200% に拡大しても、内容と操作が失われない
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-0">
            <input type="checkbox" class="custom-control-input" id="ckZoom2">
            <label class="custom-control-label" for="ckZoom2">
              幅 320px でも、横スクロールせずに読める
            </label>
          </div>
        </fieldset>

        <fieldset class="mb-4">
          <legend class="col-form-label pt-0 pb-2" style="font-size: 1rem;">
            3. 色を抜く
          </legend>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckColor1">
            <label class="custom-control-label" for="ckColor1">
              グレースケールにしても、状態・必須・エラーが区別できる
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-0">
            <input type="checkbox" class="custom-control-input" id="ckColor2">
            <label class="custom-control-label" for="ckColor2">
              文字のコントラスト比が 4.5 : 1 以上ある（開発者ツールで確認）
            </label>
          </div>
        </fieldset>

        <fieldset class="mb-4">
          <legend class="col-form-label pt-0 pb-2" style="font-size: 1rem;">
            4. フォームを確かめる
          </legend>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckForm1">
            <label class="custom-control-label" for="ckForm1">
              すべての入力欄に <code>&lt;label for&gt;</code> が付いている
              （ラベルの文字をクリックしてフォーカスが入るか）
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckForm2">
            <label class="custom-control-label" for="ckForm2">
              氏名・住所・電話・メールの欄に <code>autocomplete</code> が付いている
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckForm3">
            <label class="custom-control-label" for="ckForm3">
              数字を入れる欄に <code>inputmode</code> が付いている（スマホで確認）
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-0">
            <input type="checkbox" class="custom-control-input" id="ckForm4">
            <label class="custom-control-label" for="ckForm4">
              エラー時に、画面の先頭にエラーの一覧が出てフォーカスが移る
            </label>
          </div>
        </fieldset>

        <fieldset class="mb-4">
          <legend class="col-form-label pt-0 pb-2" style="font-size: 1rem;">
            5. 自動チェックを掛ける
          </legend>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckTool1">
            <label class="custom-control-label" for="ckTool1">
              Lighthouse または axe DevTools を実行し、出た項目を読んだ
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-0">
            <input type="checkbox" class="custom-control-input" id="ckTool2">
            <label class="custom-control-label" for="ckTool2">
              <code>id</code> の重複が無い（HTML の検証、または開発者ツールで確認）
            </label>
          </div>
        </fieldset>

        <fieldset class="mb-0">
          <legend class="col-form-label pt-0 pb-2" style="font-size: 1rem;">
            6. 読み上げを聞く
          </legend>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckSr1">
            <label class="custom-control-label" for="ckSr1">
              入力欄で、項目名が読まれる
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="ckSr2">
            <label class="custom-control-label" for="ckSr2">
              ボタンで、何のボタンかが読まれる（「ボタン」だけになっていない）
            </label>
          </div>
          <div class="custom-control custom-checkbox mb-0">
            <input type="checkbox" class="custom-control-input" id="ckSr3">
            <label class="custom-control-label" for="ckSr3">
              送信したあと、結果（成功・エラー）が読まれる
            </label>
          </div>
        </fieldset>
      </div>

      <hr>

      <p class="mb-2">
        <strong id="checkStatus" role="status">17 件中 0 件を確認しました。</strong>
      </p>
      <button type="button" class="btn btn-outline-secondary btn-sm" id="checkReset">
        チェックを全部外す
      </button>
    </t:panel>

    <t:panel title="この 1 画面で、最低限そろえる属性">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <caption class="sr-only">画面の部品ごとに付ける属性の早見表</caption>
          <thead class="thead-light">
            <tr>
              <th scope="col" style="min-width: 10rem;">部品</th>
              <th scope="col" style="min-width: 18rem;">付けるもの</th>
              <th scope="col" style="min-width: 12rem;">詳しくは</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">入力欄</th>
              <td><code>&lt;label for&gt;</code>、<code>autocomplete</code>、<code>inputmode</code></td>
              <td><a href="${ctx}/samples/a11y/mobile-keyboard">スマホのキーボード</a></td>
            </tr>
            <tr>
              <th scope="row">選択肢（ラジオ・チェック）</th>
              <td><code>&lt;fieldset&gt;</code> + <code>&lt;legend&gt;</code></td>
              <td><a href="${ctx}/samples/a11y/form-labels">ラベルの付け方</a></td>
            </tr>
            <tr>
              <th scope="row">エラー</th>
              <td>先頭にエラーサマリ、<code>tabindex="-1"</code> + <code>focus()</code>、<code>aria-invalid</code></td>
              <td><a href="${ctx}/samples/a11y/error-summary">エラーの伝え方</a></td>
            </tr>
            <tr>
              <th scope="row">ボタン</th>
              <td><code>&lt;button type="button"&gt;</code>（<code>&lt;div onclick&gt;</code> にしない）</td>
              <td><a href="${ctx}/samples/a11y/keyboard-operation">キーボード操作</a></td>
            </tr>
            <tr>
              <th scope="row">アイコンだけのボタン</th>
              <td><code>aria-label</code>（アイコンは <code>aria-hidden="true"</code>）</td>
              <td><a href="${ctx}/samples/a11y/alt-text">代替テキスト</a></td>
            </tr>
            <tr>
              <th scope="row">一覧表</th>
              <td><code>&lt;caption&gt;</code>、<code>&lt;th scope&gt;</code>、<code>.table-responsive</code></td>
              <td><a href="${ctx}/samples/a11y/accessible-table">表の作り方</a></td>
            </tr>
            <tr>
              <th scope="row">Ajax で変わる場所</th>
              <td><code>role="status"</code>（空の箱を先に置く）</td>
              <td><a href="${ctx}/samples/a11y/live-region">画面の変化を知らせる</a></td>
            </tr>
            <tr>
              <th scope="row">画像</th>
              <td><code>alt</code>（装飾は <code>alt=""</code>）</td>
              <td><a href="${ctx}/samples/a11y/alt-text">代替テキスト</a></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>
  </jsp:body>
</t:sample>
