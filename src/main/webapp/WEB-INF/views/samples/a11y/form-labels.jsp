<%--
  【サンプル】ラベルの付け方と入力欄のグループ化

  Servlet を使わない、JSP だけのサンプルです。
  label / fieldset / legend / aria-describedby という、
  フォームの「骨組み」にあたる部分だけを扱います。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="form-labels">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>ラベルが結び付いていないと何が起きるか</h2>
    <p>
      入力欄の左や上に文字が置いてあれば、目で見ている人には「その欄の名前」だと分かります。
      しかし <strong>HTML としては、ただ近くにある文字</strong>でしかありません。
      スクリーンリーダーは入力欄にたどり着いたとき「編集テキスト」としか読まず、
      何を入れる欄なのかを伝えられません。
    </p>
    <p>
      結び付けておくと、次の 3 つが同時に手に入ります。
    </p>
    <ol>
      <li><strong>読み上げられる</strong>：欄にフォーカスすると項目名が読まれます</li>
      <li><strong>タップ範囲が広がる</strong>：ラベルの文字をタップしても欄にフォーカスが入ります</li>
      <li><strong>チェックボックスが押しやすくなる</strong>：小さな四角だけでなく、文字でも切り替えられます</li>
    </ol>
    <p>
      2 と 3 は目が見える人にも効きます。とくにスマートフォンでは、
      <strong>ラベルを結び付けるだけでチェックボックスの押しやすさが大きく変わります</strong>。
    </p>

    <h2>結び付け方は 3 通り</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 28%;">書き方</th><th>使いどころ</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>&lt;label for="id"&gt;</code></td>
            <td>
              <strong>基本はこれ</strong>です。<code>for</code> に入力欄の <code>id</code> を書きます。
              レイアウトの都合でラベルと欄が離れていても結び付きます
            </td>
          </tr>
          <tr>
            <td><code>&lt;label&gt;</code> で囲む</td>
            <td>
              <code>id</code> を考えなくてよいのが利点です。
              ただし <code>for</code> が無いと他から参照できないので、併用が安全です
            </td>
          </tr>
          <tr>
            <td><code>aria-label="…"</code></td>
            <td>
              <strong>ラベルを画面に出す場所が無いときだけ</strong>使います
              （検索欄の虫眼鏡ボタンなど）。目に見えるラベルが置けるなら <code>&lt;label&gt;</code> が優先です
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <code>id</code> は<strong>ページの中で重複してはいけません</strong>。
      一覧の各行にフォームを置くような画面では、<code>id="qty-${'${row.id}'}"</code> のように
      キーを混ぜて作ります。重複すると、ラベルをタップしても先頭の欄にフォーカスが飛びます。
    </p>

    <h2><code>placeholder</code> をラベル代わりにしない</h2>
    <p>
      欄の中に薄い文字で「氏名」と出すデザインはよく見かけますが、次の問題があります。
    </p>
    <ul>
      <li><strong>入力し始めると消えます。</strong> 何の欄だったか確かめる手段が無くなります</li>
      <li><strong>見直しができません。</strong> 入力後の画面を見返しても、項目名が残っていません</li>
      <li><strong>薄い色なのでコントラストが足りません。</strong> 既定の灰色は WCAG の基準を満たさないことが多いです</li>
      <li><strong>読み上げの扱いがブラウザごとに違います。</strong> 読む場合も読まない場合もあります</li>
      <li><strong>自動翻訳されないことがあります。</strong></li>
    </ul>
    <p>
      <code>placeholder</code> は<strong>入力例</strong>（<code>0600042</code>、<code>taro@example.com</code>）に使い、
      項目名は必ず <code>&lt;label&gt;</code> で出します。
    </p>

    <h2>ラジオ・チェックボックスは <code>fieldset</code> でまとめる</h2>
    <p>
      「勤務地」に対して「本社 / 支社 / 在宅」の 3 択があるとき、
      それぞれの <code>&lt;label&gt;</code> は「本社」「支社」「在宅」です。
      <strong>「勤務地」という見出しを結び付ける相手がいません</strong>。
    </p>
    <p>
      そこで <code>&lt;fieldset&gt;</code> で囲み、先頭に <code>&lt;legend&gt;</code> を置きます。
      スクリーンリーダーは「勤務地、本社、ラジオボタン、3 個中 1 個目」のように、
      <strong>グループ名と、全体で何個あるか</strong>まで読んでくれます。
    </p>
    <p>
      <code>&lt;legend&gt;</code> は <code>&lt;fieldset&gt;</code> の<strong>最初の子要素</strong>でなければ効きません。
      Bootstrap 4 では、見た目を他の項目名と揃えるために
      <code>&lt;legend class="col-form-label pt-0"&gt;</code> と書くことが多いです。
    </p>

    <h2>補足の文章は <code>aria-describedby</code> で結び付ける</h2>
    <p>
      「半角数字 7 桁で入力してください」のような注記は、欄の下に置いても自動では読まれません。
      注記に <code>id</code> を付け、入力欄から <code>aria-describedby</code> で指すと、
      <strong>ラベルを読んだ後に続けて読まれます</strong>。
    </p>
    <ul>
      <li><code>aria-labelledby</code> … その要素の<strong>名前</strong>（ラベル）を別の要素から取る</li>
      <li><code>aria-describedby</code> … 名前はそのままで、<strong>補足説明</strong>を足す</li>
    </ul>
    <p>
      エラーメッセージも <code>aria-describedby</code> で結び付けます。
      その書き方は <a href="${ctx}/samples/a11y/error-summary">エラーの伝え方</a> にまとめています。
    </p>

    <h2>必須の示し方</h2>
    <p>
      赤い <code>*</code> だけで必須を示すと、色が見えない人・記号の意味を知らない人に伝わりません。
    </p>
    <ul>
      <li><strong>ラベルに文字で書きます</strong>（「氏名（必須）」）。読み上げでもそのまま伝わります</li>
      <li>
        <code>required</code> を付けると、ブラウザが送信前に止めてくれます。
        読み上げでも「必須」と伝わるので、<code>aria-required="true"</code> を別に書く必要はありません
        （<code>required</code> が使えない自作部品のときだけ <code>aria-required</code> を使います）
      </li>
      <li>
        <strong>サーバ側のチェックは必ず別に書きます。</strong>
        <code>required</code> は開発者ツールで外せますし、JavaScript を切れば効きません
        （<a href="${ctx}/samples/form/input-validation">入力チェック（サーバ側）</a>）
      </li>
      <li>
        必須が大半を占める画面では、逆に「（任意）」を付ける方が画面が静かになります。
        どちらにしても、<strong>画面の先頭にどちらの方式か書いておきます</strong>
      </li>
    </ul>

    <h2>タップできる大きさ</h2>
    <p>
      WCAG 2.2 の達成基準 2.5.8「ターゲットのサイズ（最小）」（レベル AA）は <strong>24 × 24 px 以上</strong>、
      2.5.5「ターゲットのサイズ」（レベル AAA）は <strong>44 × 44 px 以上</strong>を求めています。
      Apple も Google も、実務上の目安として <strong>44 px 前後</strong>を推奨しています。
    </p>
    <p>
      Bootstrap 4 の <code>.btn</code> は約 38 px なので、
      指で押す前提の画面では <code>.btn-lg</code> にするか、上下の余白を足して調整します。
      <strong>ラベルを結び付けておけば、チェックボックスは文字の分だけ押せる範囲が広がります。</strong>
    </p>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="ラベルが結び付いているかを確かめる"
             note="「氏名」という文字をクリックしてください。結び付いていれば欄にフォーカスが入ります">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：ただ近くに置いただけ</span>
            <div class="form-group mb-0">
              <span class="d-block mb-1">氏名</span>
              <input type="text" class="form-control">
            </div>
            <p class="small mt-2 mb-0">
              文字をクリックしても何も起きません。読み上げでも「編集テキスト」としか読まれません。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：label for と id で結ぶ</span>
            <div class="form-group mb-0">
              <label for="lblName">氏名</label>
              <input type="text" class="form-control" id="lblName">
            </div>
            <p class="small mt-2 mb-0">
              文字をクリックすると欄にフォーカスが入ります。読み上げでも「氏名、編集テキスト」と読まれます。
            </p>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="placeholder はラベルの代わりにならない"
             note="左の欄に何か打ち込むと、項目名が消えます">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：placeholder だけ</span>
            <div class="form-group mb-0">
              <input type="text" class="form-control" placeholder="メールアドレス">
            </div>
            <p class="small mt-2 mb-0">
              入力を始めた瞬間に「メールアドレス」が消えます。
              あとから画面を見直しても、何の欄か分かりません。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：ラベル＋入力例</span>
            <div class="form-group mb-0">
              <label for="lblMail">メールアドレス</label>
              <input type="email" class="form-control" id="lblMail"
                     placeholder="taro@example.com" autocomplete="email">
            </div>
            <p class="small mt-2 mb-0">
              項目名は残したまま、<code>placeholder</code> は<strong>入力例</strong>として使います。
            </p>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="チェックボックスは、ラベルを結ぶだけで押しやすくなる"
             note="スマートフォンで試すと違いがよく分かります">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：四角しか押せない</span>
            <div class="mb-0">
              <input type="checkbox" id="chkBad" style="vertical-align: middle;">
              <span style="vertical-align: middle;">利用規約に同意する</span>
            </div>
            <p class="small mt-3 mb-0">
              押せるのは 13px 角ほどの四角だけです。指では外しやすく、押し直しが増えます。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：文字も押せる</span>
            <div class="custom-control custom-checkbox mb-0">
              <input type="checkbox" class="custom-control-input" id="chkGood">
              <label class="custom-control-label" for="chkGood">利用規約に同意する</label>
            </div>
            <p class="small mt-3 mb-0">
              文字をタップしても切り替わります。
              Bootstrap 4 の <code>custom-control</code> は、この形を前提に作られています。
            </p>
          </div>
        </div>
      </div>

      <hr>

      <p class="mb-2 small font-weight-bold">押せる大きさの目安</p>
      <p class="mb-0">
        <span class="a11y-tap a11y-tap--small">24</span>
        <span class="ml-2 mr-3 small text-muted">24 × 24 px（WCAG 2.2 AA の最小）</span>
        <span class="a11y-tap a11y-tap--ok">44</span>
        <span class="ml-2 small text-muted">44 × 44 px（実務上の推奨）</span>
      </p>
    </t:panel>

    <t:panel title="選択肢は fieldset でまとめる"
             note="スクリーンリーダーで「勤務地、本社、ラジオボタン、3 個中 1 個目」と読ませるための書き方です">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：見出しを置いただけ</span>
            <p class="mb-2">勤務地</p>
            <div class="custom-control custom-radio">
              <input type="radio" class="custom-control-input" id="wbBad1" name="workplaceBad">
              <label class="custom-control-label" for="wbBad1">本社</label>
            </div>
            <div class="custom-control custom-radio">
              <input type="radio" class="custom-control-input" id="wbBad2" name="workplaceBad">
              <label class="custom-control-label" for="wbBad2">支社</label>
            </div>
            <div class="custom-control custom-radio">
              <input type="radio" class="custom-control-input" id="wbBad3" name="workplaceBad">
              <label class="custom-control-label" for="wbBad3">在宅</label>
            </div>
            <p class="small mt-3 mb-0">
              「本社、ラジオボタン」としか読まれず、<strong>何を選んでいるのか</strong>が分かりません。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：fieldset + legend</span>
            <fieldset class="mb-0">
              <legend class="col-form-label pt-0 pb-2" style="font-size: 1rem;">勤務地</legend>
              <div class="custom-control custom-radio">
                <input type="radio" class="custom-control-input" id="wbGood1" name="workplaceGood">
                <label class="custom-control-label" for="wbGood1">本社</label>
              </div>
              <div class="custom-control custom-radio">
                <input type="radio" class="custom-control-input" id="wbGood2" name="workplaceGood">
                <label class="custom-control-label" for="wbGood2">支社</label>
              </div>
              <div class="custom-control custom-radio">
                <input type="radio" class="custom-control-input" id="wbGood3" name="workplaceGood">
                <label class="custom-control-label" for="wbGood3">在宅</label>
              </div>
            </fieldset>
            <p class="small mt-3 mb-0">
              グループ名と「3 個中 1 個目」まで読まれます。
              <code>&lt;legend&gt;</code> は <code>&lt;fieldset&gt;</code> の最初の子に置きます。
            </p>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="補足説明を結び付ける（aria-describedby）"
             note="欄にフォーカスすると、ラベルに続けて注記も読まれます">
      <form onsubmit="return false;">
        <div class="form-row">
          <div class="form-group col-md-6">
            <label for="descZip">郵便番号（必須）</label>
            <input type="text" class="form-control" id="descZip" name="zip"
                   inputmode="numeric" maxlength="7" autocomplete="postal-code"
                   required aria-describedby="descZipHelp" placeholder="0600042">
            <small id="descZipHelp" class="form-text text-muted">
              ハイフン無しの半角数字 7 桁で入力してください。
            </small>
            <span class="a11y-attr">aria-describedby="descZipHelp" required</span>
          </div>

          <div class="form-group col-md-6 mb-0">
            <label for="descPass">新しいパスワード（必須）</label>
            <input type="password" class="form-control" id="descPass" name="password"
                   autocomplete="new-password" required aria-describedby="descPassHelp">
            <small id="descPassHelp" class="form-text text-muted">
              8 文字以上で、英字と数字を混ぜてください。
            </small>
            <span class="a11y-attr">aria-describedby="descPassHelp" autocomplete="new-password"</span>
          </div>
        </div>
      </form>
      <p class="mb-0 small text-muted">
        注記が複数あるときは <code>aria-describedby="idA idB"</code> と半角スペースで並べます
        （読まれる順番も書いた順です）。
      </p>
    </t:panel>

    <t:panel title="必須を色と記号だけで示さない">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：赤い * だけ</span>
            <div class="form-group mb-0">
              <label for="reqBad">部署名 <span class="text-danger">*</span></label>
              <input type="text" class="form-control" id="reqBad">
            </div>
            <p class="small mt-2 mb-0">
              色が見えなければただの <code>*</code>、読み上げでは「部署名 アスタリスク」です。
              <code>*</code> が必須を意味することは、どこにも書かれていません。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：文字で書く＋required</span>
            <div class="form-group mb-0">
              <label for="reqGood">部署名（必須）</label>
              <input type="text" class="form-control" id="reqGood" required>
            </div>
            <p class="small mt-2 mb-0">
              「部署名 必須 編集テキスト 必要」と読まれます。
              <code>required</code> があるので、ブラウザも送信前に止めてくれます。
            </p>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="ラベルを画面に出せないとき（aria-label）"
             note="ヘッダーの検索欄がこの形です">
      <form class="form-inline" onsubmit="return false;">
        <input type="search" class="form-control mr-2" id="alSearch"
               aria-label="サンプルを検索" placeholder="キーワード" enterkeyhint="search">
        <button type="submit" class="btn btn-primary">検索</button>
      </form>
      <span class="a11y-attr">aria-label="サンプルを検索"（画面には出ないが、読み上げでは項目名になる）</span>
      <p class="mt-3 mb-0 small text-muted">
        デザイン上どうしてもラベルを置けないときの最後の手段です。
        <strong><code>placeholder</code> だけで済ませず、<code>aria-label</code> は必ず付けます。</strong>
        なお、ボタンのように<strong>見える文字がある</strong>ものに <code>aria-label</code> を足すと、
        見える文字と読まれる文字が食い違って、音声で操作している人が指示を伝えられなくなります。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
