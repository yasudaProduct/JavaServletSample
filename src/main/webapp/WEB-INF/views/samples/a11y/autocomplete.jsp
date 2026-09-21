<%--
  【サンプル】自動入力（autocomplete）と、余計なお節介を切る

  Servlet を使わない、JSP だけのサンプルです。
  ブラウザ / OS が持っている住所・氏名・パスワードを入力欄へ流し込めるようにする指定と、
  iOS の自動大文字化・自動修正を止める指定をまとめています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="autocomplete">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>自動入力は「楽になる機能」ではなく「使えるかどうか」の話</h2>
    <p>
      住所や氏名の自動入力は、慣れた人には「あると便利」程度のものです。
      しかし、手が震える人・片手しか使えない人・長い文字列を覚えていられない人にとっては、
      <strong>自動入力が効くかどうかで、その画面を自力で終えられるかが決まります</strong>。
    </p>
    <p>
      WCAG 2.1 では <strong>達成基準 1.3.5「入力目的の特定」（レベル AA）</strong>として、
      利用者自身の情報を入力する欄には <code>autocomplete</code> を付けることが求められています。
      公的機関のサイトや、その基準に合わせる社内システムでは必須項目になります。
    </p>

    <h2>ブラウザは <code>name</code> ではなく <code>autocomplete</code> を見る</h2>
    <p>
      <code>name="zipcode"</code> や <code>id="address1"</code> のような命名からブラウザが推測することもありますが、
      当たるかどうかは運次第です。<strong>決められた語（トークン）を <code>autocomplete</code> に書くのが唯一確実な方法</strong>です。
      トークンは仕様で決まっているので、自由な単語は使えません。
    </p>

    <h2>日本の住所フォームで使うトークン</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 34%;">トークン</th><th>入る値</th></tr>
        </thead>
        <tbody>
          <tr><td><code>name</code></td><td>氏名（1 欄にまとめる場合）</td></tr>
          <tr><td><code>family-name</code> / <code>given-name</code></td><td>姓 / 名（欄を分ける場合）</td></tr>
          <tr><td><code>postal-code</code></td><td>郵便番号</td></tr>
          <tr><td><code>address-level1</code></td><td>都道府県</td></tr>
          <tr><td><code>address-level2</code></td><td>市区町村</td></tr>
          <tr><td><code>address-line1</code> / <code>address-line2</code></td><td>町名・番地 / 建物名・部屋番号</td></tr>
          <tr><td><code>tel</code></td><td>電話番号（1 欄にまとめる場合）</td></tr>
          <tr><td><code>email</code></td><td>メールアドレス</td></tr>
          <tr><td><code>organization</code></td><td>会社名</td></tr>
          <tr><td><code>bday</code></td><td>生年月日（<code>type="date"</code> と組み合わせます）</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      <strong>ふりがなのトークンはありません。</strong>
      「セイ」「メイ」の欄は自動入力の対象外なので、<code>autocomplete</code> は付けず、
      代わりに郵便番号からの住所自動入力など別の手段で手間を減らします。
    </p>
    <p>
      配送先と請求先のように<strong>同じ種類の住所が 2 つある</strong>ときは、
      <code>autocomplete="shipping postal-code"</code> / <code>autocomplete="billing postal-code"</code>
      のように前に付けて区別します。それ以外のグループ分けは
      <code>autocomplete="section-office postal-code"</code> のように <code>section-</code> を使います。
    </p>

    <h2>ログイン画面で付けるもの</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 34%;">トークン</th><th>意味</th></tr>
        </thead>
        <tbody>
          <tr><td><code>username</code></td><td>ログイン ID。パスワードとセットで記憶されます</td></tr>
          <tr><td><code>current-password</code></td><td>今のパスワード（ログイン画面）</td></tr>
          <tr>
            <td><code>new-password</code></td>
            <td>
              新しいパスワード（新規登録・変更画面）。
              これを書くとパスワード管理ソフトが<strong>強いパスワードを生成して提案</strong>し、
              保存まで面倒を見てくれます。確認用の欄にも同じものを付けます
            </td>
          </tr>
          <tr>
            <td><code>one-time-code</code></td>
            <td>
              SMS やメールで届くワンタイムコード。
              <strong>届いたコードをキーボードの上に候補として出してくれます</strong>（iOS / Android）。
              二要素認証の画面では効果が大きい指定です
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      このサイトのログインサンプル（<a href="${ctx}/samples/session/login">ログインとログアウト</a>）でも
      <code>username</code> / <code>current-password</code> を指定しています。
    </p>

    <h2><code>autocomplete="off"</code> を書いてよい場面</h2>
    <p>
      <code>off</code> は「ブラウザに覚えさせない」指定ですが、乱用すると自動入力を丸ごと殺してしまいます。
    </p>
    <ul>
      <li>
        <strong>書いてよい</strong>：検索キーワード欄、サジェストを自前で出す欄、
        ワンタイムトークンや検算用のコードなど、<strong>前回の値が出てくると邪魔になる欄</strong>。
        このサイトでは <code>samples/ajax/ajax-search.jsp</code> の検索欄が該当します。
      </li>
      <li>
        <strong>書いてはいけない</strong>：パスワード欄。
        「セキュリティのため」と書かれることがありますが、
        <strong>主要なブラウザはパスワード欄の <code>off</code> を無視します</strong>し、
        パスワード管理ソフトの利用を妨げて、かえって弱いパスワードの使い回しを招きます。
      </li>
      <li>
        <strong>書いてはいけない</strong>：住所・氏名・電話番号の欄。
        WCAG 1.3.5 に反します。
      </li>
    </ul>

    <h2>iOS の「勝手に直す」を止める 3 つの属性</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 34%;">属性</th><th>効果</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>autocapitalize="off"</code></td>
            <td>
              先頭の文字を自動で大文字にするのを止めます。
              社員コード <code>a1234</code> が <code>A1234</code> になって「該当なし」になる事故を防げます
            </td>
          </tr>
          <tr>
            <td><code>autocorrect="off"</code></td>
            <td>
              スペル修正を止めます。型番や略語が勝手に別の単語へ置き換わるのを防げます
              （Safari 独自の属性ですが、他のブラウザは無視するだけなので害はありません）
            </td>
          </tr>
          <tr>
            <td><code>spellcheck="false"</code></td>
            <td>
              赤い波線を出さなくします。コードや型番の欄では意味の無い指摘しか出ないので消します
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <strong>付ける欄</strong>：社員コード、伝票番号、型番、ログイン ID など「決まった形の文字列」。<br>
      <strong>付けない欄</strong>：氏名、住所、備考など「日本語の文章」。こちらは変換の補助が働いた方が楽です。
    </p>

    <h2>確かめ方</h2>
    <ul>
      <li>
        自動入力の候補が出るかどうかは、<strong>ブラウザに住所やパスワードが登録されているか</strong>で変わります。
        何も登録されていない環境では、正しく書いても候補は出ません。
      </li>
      <li>
        Chrome なら「設定 &gt; 自動入力とパスワード &gt; 住所やその他の情報」に 1 件登録してから試します。
      </li>
      <li>
        自動大文字化の確認は iOS の実機が必要です（PC のブラウザでは起きません）。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <div class="alert alert-info" role="alert">
      このページのフォームは<strong>送信されません</strong>。
      入力欄をタップ（クリック）したときに、ブラウザが候補を出すかどうかを見てください。
      候補が出るかは、ブラウザに住所やパスワードが登録されているかによります。
    </div>

    <t:panel title="住所フォームに autocomplete を付ける" note="1 欄タップするだけで、残りがまとめて埋まります">
      <form onsubmit="return false;" autocomplete="on">
        <div class="form-row">
          <div class="form-group col-md-6">
            <label for="acName">氏名</label>
            <input type="text" class="form-control" id="acName" name="name" autocomplete="name">
            <span class="a11y-attr">autocomplete="name"</span>
          </div>
          <div class="form-group col-md-6">
            <label for="acKana">氏名（カナ）</label>
            <input type="text" class="form-control" id="acKana" name="kana">
            <span class="a11y-attr">（ふりがなに対応するトークンは無いので付けません）</span>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group col-md-4">
            <label for="acZip">郵便番号</label>
            <input type="text" class="form-control" id="acZip" name="zip"
                   inputmode="numeric" maxlength="7" autocomplete="postal-code">
            <span class="a11y-attr">autocomplete="postal-code"</span>
          </div>
          <div class="form-group col-md-4">
            <label for="acPref">都道府県</label>
            <input type="text" class="form-control" id="acPref" name="pref" autocomplete="address-level1">
            <span class="a11y-attr">autocomplete="address-level1"</span>
          </div>
          <div class="form-group col-md-4">
            <label for="acCity">市区町村</label>
            <input type="text" class="form-control" id="acCity" name="city" autocomplete="address-level2">
            <span class="a11y-attr">autocomplete="address-level2"</span>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group col-md-6">
            <label for="acAddr1">町名・番地</label>
            <input type="text" class="form-control" id="acAddr1" name="addr1" autocomplete="address-line1">
            <span class="a11y-attr">autocomplete="address-line1"</span>
          </div>
          <div class="form-group col-md-6">
            <label for="acAddr2">建物名・部屋番号</label>
            <input type="text" class="form-control" id="acAddr2" name="addr2" autocomplete="address-line2">
            <span class="a11y-attr">autocomplete="address-line2"</span>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group col-md-6 mb-md-0">
            <label for="acTel">電話番号</label>
            <input type="tel" class="form-control" id="acTel" name="tel" autocomplete="tel">
            <span class="a11y-attr">type="tel" autocomplete="tel"</span>
          </div>
          <div class="form-group col-md-6 mb-0">
            <label for="acMail">メールアドレス</label>
            <input type="email" class="form-control" id="acMail" name="mail" autocomplete="email">
            <span class="a11y-attr">type="email" autocomplete="email"</span>
          </div>
        </div>
      </form>
    </t:panel>

    <t:panel title="配送先と請求先のように、同じ種類の住所が 2 つあるとき">
      <form onsubmit="return false;">
        <div class="form-row">
          <div class="form-group col-md-6">
            <fieldset class="mb-0">
              <legend class="col-form-label pt-0" style="font-size: 1rem;">配送先</legend>
              <label for="shipZip">郵便番号</label>
              <input type="text" class="form-control" id="shipZip" name="shipZip"
                     inputmode="numeric" maxlength="7" autocomplete="shipping postal-code">
              <span class="a11y-attr">autocomplete="shipping postal-code"</span>
            </fieldset>
          </div>
          <div class="form-group col-md-6 mb-0">
            <fieldset class="mb-0">
              <legend class="col-form-label pt-0" style="font-size: 1rem;">請求先</legend>
              <label for="billZip">郵便番号</label>
              <input type="text" class="form-control" id="billZip" name="billZip"
                     inputmode="numeric" maxlength="7" autocomplete="billing postal-code">
              <span class="a11y-attr">autocomplete="billing postal-code"</span>
            </fieldset>
          </div>
        </div>
      </form>
    </t:panel>

    <t:panel title="ログイン・パスワード変更・ワンタイムコード">
      <div class="row">
        <div class="col-md-4 mb-3 mb-md-0">
          <form onsubmit="return false;">
            <p class="font-weight-bold small mb-2">ログイン画面</p>
            <div class="form-group">
              <label for="pwUser">ログイン ID</label>
              <input type="text" class="form-control" id="pwUser" name="loginId"
                     autocomplete="username" autocapitalize="off" autocorrect="off" spellcheck="false">
              <span class="a11y-attr">autocomplete="username"</span>
            </div>
            <div class="form-group mb-0">
              <label for="pwCurrent">パスワード</label>
              <input type="password" class="form-control" id="pwCurrent" name="password"
                     autocomplete="current-password">
              <span class="a11y-attr">autocomplete="current-password"</span>
            </div>
          </form>
        </div>

        <div class="col-md-4 mb-3 mb-md-0">
          <form onsubmit="return false;">
            <p class="font-weight-bold small mb-2">パスワード変更画面</p>
            <div class="form-group">
              <label for="pwNew">新しいパスワード</label>
              <input type="password" class="form-control" id="pwNew" name="newPassword"
                     autocomplete="new-password">
              <span class="a11y-attr">autocomplete="new-password"</span>
            </div>
            <div class="form-group mb-0">
              <label for="pwConfirm">新しいパスワード（確認）</label>
              <input type="password" class="form-control" id="pwConfirm" name="confirmPassword"
                     autocomplete="new-password">
              <span class="a11y-attr">autocomplete="new-password"（確認欄にも同じものを付けます）</span>
            </div>
          </form>
        </div>

        <div class="col-md-4">
          <form onsubmit="return false;">
            <p class="font-weight-bold small mb-2">二要素認証の画面</p>
            <div class="form-group mb-0">
              <label for="pwOtp">SMS に届いた 6 桁のコード</label>
              <input type="text" class="form-control" id="pwOtp" name="otp"
                     inputmode="numeric" maxlength="6"
                     autocomplete="one-time-code" enterkeyhint="send">
              <span class="a11y-attr">autocomplete="one-time-code" inputmode="numeric"</span>
            </div>
            <p class="small text-muted mt-2 mb-0">
              スマートフォンなら、SMS が届いた瞬間にキーボードの上へコードが候補として出ます。
            </p>
          </form>
        </div>
      </div>
    </t:panel>

    <t:panel title="勝手に大文字にされるのを止める"
             note="iPhone で 2 つの欄に小文字の a1234 と打ってみてください">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：指定なし</span>
            <label for="capBad">社員コード</label>
            <input type="text" class="form-control" id="capBad" maxlength="5" placeholder="a1234">
            <span class="a11y-attr">（属性なし）</span>
            <p class="small mt-2 mb-0">
              iOS では先頭が大文字になり、<code>A1234</code> として送信されます。
              マスタに <code>a1234</code> しか無ければ「該当なし」になります。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：自動処理を切る</span>
            <label for="capGood">社員コード</label>
            <input type="text" class="form-control" id="capGood" maxlength="5" placeholder="a1234"
                   autocapitalize="off" autocorrect="off" spellcheck="false">
            <span class="a11y-attr">autocapitalize="off" autocorrect="off" spellcheck="false"</span>
            <p class="small mt-2 mb-0">
              打った通りの <code>a1234</code> が送信されます。
              なお、サーバ側でも大文字小文字を揃えておくと、他の入口からの登録にも耐えられます。
            </p>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="autocomplete=&quot;off&quot; を付けてよいのはどこか">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th style="width: 30%;">欄</th>
              <th style="width: 14%;">off にする</th>
              <th>理由</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>検索キーワード</td>
              <td class="text-success font-weight-bold">○</td>
              <td>前回の検索語が候補として出ると、サジェストと二重になって邪魔になります</td>
            </tr>
            <tr>
              <td>ワンタイムトークン・確認コードを手で写す欄</td>
              <td class="text-success font-weight-bold">○</td>
              <td>毎回違う値なので、過去の値に意味がありません</td>
            </tr>
            <tr>
              <td>パスワード</td>
              <td class="text-danger font-weight-bold">×</td>
              <td>ブラウザに無視されるうえ、パスワード管理ソフトの利用を妨げます</td>
            </tr>
            <tr>
              <td>氏名・住所・電話番号・メール</td>
              <td class="text-danger font-weight-bold">×</td>
              <td>WCAG 1.3.5「入力目的の特定」に反します</td>
            </tr>
            <tr>
              <td>クレジットカード番号</td>
              <td class="text-danger font-weight-bold">×</td>
              <td>打ち間違いが致命的な欄ほど、自動入力の価値が高くなります</td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>
  </jsp:body>
</t:sample>
