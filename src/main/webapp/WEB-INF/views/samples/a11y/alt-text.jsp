<%--
  【サンプル】画像とアイコンの代替テキスト

  Servlet を使わない、JSP だけのサンプルです。
  alt をどう書き分けるか、アイコンだけのボタンをどう扱うか、
  そして「画面には出さないが読み上げる文字」の作り方をまとめています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="alt-text">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2><code>alt</code> は「画像の説明」ではなく「画像の代わり」</h2>
    <p>
      <code>alt</code> を「その画像が何であるかの説明」と考えると書けなくなります。
      正しくは<strong>「その画像をそのまま文字に置き換えたら何と書くか」</strong>です。
      印刷した紙から画像だけを切り抜いたとして、<strong>そこに何と書けば同じ意味になるか</strong>、
      と考えると決まります。
    </p>
    <p>
      だから、画像の中に「送信」と書かれたボタン画像なら <code>alt="送信"</code> であり、
      <code>alt="送信ボタンの画像"</code> ではありません。
      読み上げソフトは <code>&lt;img&gt;</code> を見つけた時点で「画像」と言うので、
      <strong>「〜の画像」「〜の写真」「イメージ」は二重になります</strong>。
    </p>

    <h2>4 つに分けて考える</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead class="thead-light">
          <tr><th style="width: 26%;">画像の種類</th><th>書き方</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>① 意味のある画像</strong></td>
            <td>
              内容を文字にします。<br>
              <code>&lt;img src="chart.png" alt="4 月から 9 月まで、売上は毎月 5% ずつ増えています"&gt;</code>
            </td>
          </tr>
          <tr>
            <td><strong>② 装飾だけの画像</strong></td>
            <td>
              <code>alt=""</code> と<strong>空で書きます</strong>（属性ごと消すのではありません）。
              読み上げソフトはその画像を完全に無視します。
              <strong><code>alt</code> を書き忘れると、代わりにファイル名が読まれます</strong>
              （「アイ・エム・ジー・アンダーバー・ゼロ・ゼロ・イチ・ドット・ピー・エヌ・ジー」）
            </td>
          </tr>
          <tr>
            <td><strong>③ リンク／ボタンの中の画像</strong></td>
            <td>
              <strong>リンク先や動作</strong>を書きます。
              「会社ロゴ」ではなく <code>alt="トップページへ"</code> のように、
              押したら何が起きるかを書きます
            </td>
          </tr>
          <tr>
            <td><strong>④ 複雑な図・グラフ</strong></td>
            <td>
              <code>alt</code> には要約を書き、<strong>詳細は本文か表で提供します</strong>。
              数値のグラフは、同じ数値の表を近くに置くのがいちばん確実です
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>アイコンをどう扱うか</h2>
    <p>
      業務システムでいちばん多いのは、<strong>アイコンだけのボタン</strong>（🗑 削除、✎ 編集）です。
      アイコンはインライン SVG かアイコンフォントで置かれることが多く、
      <code>alt</code> が書けません。そこで次のようにします。
    </p>
    <pre><code class="language-xml">&lt;!-- ✗ 悪い例 : 読み上げでは「ボタン」としか言われない --&gt;
&lt;button type="button" class="btn"&gt;
  &lt;svg&gt; … &lt;/svg&gt;
&lt;/button&gt;

&lt;!-- ✓ 良い例 : ボタンに名前を付け、絵は読み上げから外す --&gt;
&lt;button type="button" class="btn" aria-label="この行を削除"&gt;
  &lt;svg aria-hidden="true" focusable="false"&gt; … &lt;/svg&gt;
&lt;/button&gt;</code></pre>
    <ul>
      <li>
        <code>aria-hidden="true"</code> … 絵そのものは読み上げの対象から外します
      </li>
      <li>
        <code>focusable="false"</code> … <strong>SVG 専用</strong>です。
        Internet Explorer や一部の環境では SVG が Tab で止まってしまうため、それを防ぎます
      </li>
      <li>
        <code>aria-label</code> … ボタン自体に名前を付けます。
        一覧の各行にある削除ボタンなら「削除」ではなく
        <strong>「株式会社あかつきを削除」</strong>のように対象まで書くと、
        音声だけで操作する人が区別できます
      </li>
    </ul>
    <p>
      <strong>文字が隣にあるアイコンには、名前を付けてはいけません。</strong>
      「<t:icon name="search" size="14" /> 検索」のようなボタンでアイコンにも名前を付けると、
      「検索 検索 ボタン」と二重に読まれます。この場合アイコンは
      <code>aria-hidden="true"</code> だけで十分です。
    </p>
    <p>
      このサイトの <code>&lt;t:icon&gt;</code> タグ（<code>WEB-INF/tags/icon.tag</code>）は、
      <strong>常に <code>aria-hidden="true" focusable="false"</code> を出力します</strong>。
      アイコンは飾りとして扱い、名前が要るときは<strong>呼び出す側のボタンに
      <code>aria-label</code> を書く</strong>、という役割分担にしています。
    </p>

    <h2>「画面には出さないが読み上げる文字」（<code>.sr-only</code>）</h2>
    <p>
      目で見れば分かるのに、音では伝わらない情報があります。
      たとえば「✓ / ✗」だけの列、「詳細」というリンクが 10 個並ぶ一覧、
      矢印だけのページ送りです。
    </p>
    <p>
      こうしたときは、Bootstrap 4 の <code>.sr-only</code> で
      <strong>読み上げ専用の文字</strong>を添えます。
    </p>
    <pre><code class="language-xml">&lt;a href="/customers/12"&gt;詳細&lt;span class="sr-only"&gt;（株式会社あかつき）&lt;/span&gt;&lt;/a&gt;</code></pre>
    <ul>
      <li>
        <strong><code>display: none</code> や <code>visibility: hidden</code> ではいけません。</strong>
        これらは読み上げソフトからも消えてしまい、意味がありません。
        <code>.sr-only</code> は「幅 1px にして画面の外へ追い出す」という書き方で、
        読み上げの対象には残します
      </li>
      <li>
        <code>font-size: 0</code> や <code>text-indent: -9999px</code> も、
        環境によって読まれなくなるので使いません
      </li>
      <li>
        <strong>使いすぎない。</strong>
        見えている情報と食い違うと、音声入力で「詳細をクリック」と言っても反応しない、
        といった問題が起きます
      </li>
    </ul>

    <h2>リンクの文字</h2>
    <p>
      スクリーンリーダーには<strong>「ページ内のリンクだけを一覧で読む」機能</strong>があります。
      そこに「こちら」「詳細」「もっと見る」が並ぶと、どれがどれだか分かりません。
    </p>
    <ul>
      <li>✗ 詳しくは<strong>こちら</strong> → ✓ <strong>就業規則（PDF）</strong>を見る</li>
      <li>✗ <strong>もっと見る</strong> → ✓ <strong>9 月の受注一覧</strong>をすべて見る</li>
      <li>
        どうしても文言を揃えたいときは、<code>.sr-only</code> で対象を足します
      </li>
      <li>
        新しいタブで開くリンク（<code>target="_blank"</code>）は、
        <strong>開く前にそう分かるように</strong>します。
        このサイトのフッターの GitHub リンクのように、外部リンクのアイコンを添えるか、
        <code>.sr-only</code> で「新しいタブで開きます」と書きます
      </li>
    </ul>

    <h2>画像の中の文字</h2>
    <p>
      文字を画像にすると、<strong>拡大するとぼやけ、文字色も変えられず、
      翻訳も検索もできません</strong>（WCAG 達成基準 1.4.5「文字画像」）。
      見出しやボタンの文字は、画像ではなく文字で作ります。
      ロゴだけは例外として認められています。
    </p>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <div class="alert alert-info" role="alert">
      このページの黄色い枠は、<strong>普段は画面に出ない <code>.sr-only</code> の中身</strong>を、
      確認用に見えるようにしたものです。実際の画面には出ません。
    </div>

    <t:panel title="装飾の画像と、意味のある画像">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：alt を書き忘れた</span>
            <p class="mb-2">
              <img src="${ctx}/assets/favicon.svg" width="40" height="40">
              <span class="ml-2">Java Servlet サンプル集</span>
            </p>
            <p class="small mb-0">
              読み上げでは<strong>ファイル名がそのまま</strong>読まれます
              （「ファビコン・ドット・エス・ブイ・ジー、画像」）。
              隣に同じ文字があるので、二重に聞かされることになります。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 良い例：装飾なので alt=""</span>
            <p class="mb-2">
              <img src="${ctx}/assets/favicon.svg" width="40" height="40" alt="">
              <span class="ml-2">Java Servlet サンプル集</span>
            </p>
            <p class="small mb-0">
              隣に文字があるので、画像は飾りです。<code>alt=""</code> と
              <strong>空で書く</strong>と、読み上げから完全に外れます。
            </p>
          </div>
        </div>
      </div>

      <hr>

      <p class="font-weight-bold small mb-2">③ リンクの中の画像は「リンク先」を書く</p>
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 見た目を説明している</span>
            <a href="${ctx}/">
              <img src="${ctx}/assets/favicon.svg" width="40" height="40" alt="青いロゴマーク">
            </a>
            <p class="small mt-2 mb-0">
              「青いロゴマーク、リンク」。押すとどこへ行くのか分かりません。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ 動作を書いている</span>
            <a href="${ctx}/">
              <img src="${ctx}/assets/favicon.svg" width="40" height="40" alt="トップページへ">
            </a>
            <p class="small mt-2 mb-0">
              「トップページへ、リンク」。押したら何が起きるかが分かります。
            </p>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="アイコンだけのボタンに名前を付ける"
             note="一覧の操作列でいちばんよく使う形です">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：名前が無い</span>
            <table class="table table-sm table-bordered bg-white mb-2">
              <caption class="sr-only">取引先の一覧（悪い例）</caption>
              <thead class="thead-light">
                <tr><th scope="col">取引先</th><th scope="col" style="width: 6rem;">操作</th></tr>
              </thead>
              <tbody>
                <tr>
                  <th scope="row">あかつき</th>
                  <td>
                    <button type="button" class="btn btn-sm btn-outline-secondary">
                      <t:icon name="gear" size="14" />
                    </button>
                  </td>
                </tr>
                <tr>
                  <th scope="row">みなみ商事</th>
                  <td>
                    <button type="button" class="btn btn-sm btn-outline-secondary">
                      <t:icon name="gear" size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
            <p class="small mb-0">
              どちらも「ボタン」としか読まれません。
              <strong>2 つのボタンを区別する方法がありません。</strong>
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good a11y-reveal">
            <span class="a11y-case__label">✓ 良い例：対象まで含めて名前を付ける</span>
            <table class="table table-sm table-bordered bg-white mb-2">
              <caption class="sr-only">取引先の一覧（良い例）</caption>
              <thead class="thead-light">
                <tr><th scope="col">取引先</th><th scope="col" style="width: 6rem;">操作</th></tr>
              </thead>
              <tbody>
                <tr>
                  <th scope="row">あかつき</th>
                  <td>
                    <button type="button" class="btn btn-sm btn-outline-secondary"
                            aria-label="株式会社あかつきの設定を開く">
                      <t:icon name="gear" size="14" />
                    </button>
                  </td>
                </tr>
                <tr>
                  <th scope="row">みなみ商事</th>
                  <td>
                    <button type="button" class="btn btn-sm btn-outline-secondary"
                            aria-label="みなみ商事株式会社の設定を開く">
                      <t:icon name="gear" size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
            <p class="small mb-0">
              「株式会社あかつきの設定を開く、ボタン」と読まれます。
              音声入力の人も、名前を言って押せます。
            </p>
          </div>
        </div>
      </div>

      <hr>

      <p class="font-weight-bold small mb-2">文字が隣にあるアイコンには、名前を付けない</p>
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 二重に読まれる</span>
            <button type="button" class="btn btn-primary" aria-label="検索">
              <t:icon name="search" size="14" cssClass="mr-1" />検索
            </button>
            <p class="small mt-3 mb-0">
              <code>aria-label</code> があると、見えている「検索」の文字は<strong>無視されます</strong>。
              同じ言葉なら無害ですが、食い違うと音声操作ができなくなります。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good">
            <span class="a11y-case__label">✓ アイコンは飾りのまま</span>
            <button type="button" class="btn btn-success">
              <t:icon name="search" size="14" cssClass="mr-1" />検索
            </button>
            <p class="small mt-3 mb-0">
              アイコンは <code>aria-hidden="true"</code>（<code>&lt;t:icon&gt;</code> が自動で付けます）、
              名前は<strong>見えている文字がそのまま</strong>使われます。
            </p>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="画面には出さず、読み上げにだけ足す（.sr-only）"
             note="黄色く見えている部分が .sr-only の中身です（実際の画面には出ません）">
      <div class="a11y-compare">
        <div>
          <div class="a11y-case a11y-case--bad">
            <span class="a11y-case__label">✗ 悪い例：「詳細」が並ぶ</span>
            <ul class="list-unstyled mb-2">
              <li>株式会社あかつき <a href="#">詳細</a></li>
              <li>みなみ商事株式会社 <a href="#">詳細</a></li>
              <li>有限会社きたやま <a href="#">詳細</a></li>
            </ul>
            <p class="small mb-0">
              リンクだけを一覧で読む機能を使うと「詳細、詳細、詳細」。
              どれを選べばよいか分かりません。
            </p>
          </div>
        </div>
        <div>
          <div class="a11y-case a11y-case--good a11y-reveal">
            <span class="a11y-case__label">✓ 良い例：対象を .sr-only で足す</span>
            <ul class="list-unstyled mb-2">
              <li>株式会社あかつき
                <a href="#">詳細<span class="sr-only">（株式会社あかつき）</span></a></li>
              <li>みなみ商事株式会社
                <a href="#">詳細<span class="sr-only">（みなみ商事株式会社）</span></a></li>
              <li>有限会社きたやま
                <a href="#">詳細<span class="sr-only">（有限会社きたやま）</span></a></li>
            </ul>
            <p class="small mb-0">
              画面の見た目は左とまったく同じで、
              読み上げだけ「詳細（株式会社あかつき）、リンク」になります。
            </p>
          </div>
        </div>
      </div>

      <hr>

      <p class="font-weight-bold small mb-2">記号だけの列にも文字を足す</p>
      <div class="table-responsive a11y-reveal">
        <table class="table table-sm table-bordered mb-0">
          <caption class="sr-only">承認状況の一覧</caption>
          <thead class="thead-light">
            <tr>
              <th scope="col">申請</th>
              <th scope="col" style="width: 8rem;">承認</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">9 月分 交通費</th>
              <td><span class="text-success" aria-hidden="true">✓</span><span class="sr-only">承認済み</span></td>
            </tr>
            <tr>
              <th scope="row">9 月分 備品購入</th>
              <td><span class="text-danger" aria-hidden="true">✗</span><span class="sr-only">差し戻し</span></td>
            </tr>
          </tbody>
        </table>
      </div>
      <span class="a11y-attr">
        記号は aria-hidden="true"、意味は .sr-only の文字で伝える（色だけにも頼らない）
      </span>
    </t:panel>

    <t:panel title="グラフや図は、同じ内容を文字でも用意する">
      <div class="row">
        <div class="col-md-5 mb-3 mb-md-0">
          <%--
            デモ用の簡易グラフ。
            svg 全体を aria-hidden="true" にして、隣の表を読んでもらいます。
          --%>
          <svg viewBox="0 0 200 120" width="100%" height="120" role="img"
               aria-labelledby="chartTitle" style="border: 1px solid #e4e9f0; border-radius: 8px;">
            <title id="chartTitle">上期の売上は 4 月の 2,600 千円から 9 月の 3,085 千円まで増加</title>
            <g fill="#2b5fd9">
              <rect x="14"  y="60" width="20" height="50" />
              <rect x="44"  y="48" width="20" height="62" />
              <rect x="74"  y="56" width="20" height="54" />
              <rect x="104" y="54" width="20" height="56" />
              <rect x="134" y="36" width="20" height="74" />
              <rect x="164" y="40" width="20" height="70" />
            </g>
            <line x1="8" y1="110" x2="192" y2="110" stroke="#adb5bd" stroke-width="1" />
          </svg>
          <span class="a11y-attr">role="img" + &lt;title&gt; を aria-labelledby で参照</span>
        </div>
        <div class="col-md-7">
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <caption class="mt-0 mb-2 p-0 text-body" style="caption-side: top;">
                上期の月別売上（千円）
              </caption>
              <thead class="thead-light">
                <tr>
                  <th scope="col">月</th><th scope="col">4</th><th scope="col">5</th>
                  <th scope="col">6</th><th scope="col">7</th>
                  <th scope="col">8</th><th scope="col">9</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <th scope="row">売上</th>
                  <td>2,600</td><td>2,890</td><td>2,665</td>
                  <td>2,690</td><td>3,122</td><td>3,085</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <ul class="small text-muted mt-3 mb-0">
        <li>
          インライン SVG を画像として扱うときは <code>role="img"</code> を付けます。
          付けないと、中の図形が 1 つずつ読まれることがあります
        </li>
        <li>
          名前は <code>&lt;title&gt;</code> に書き、<code>aria-labelledby</code> で指します
          （<code>&lt;title&gt;</code> だけでは読まないブラウザがあります）
        </li>
        <li>
          <strong>数値そのものは表で出します。</strong>
          グラフの <code>alt</code> に数値を全部書いても、聞いて覚えるのは現実的ではありません
        </li>
      </ul>
    </t:panel>
  </jsp:body>
</t:sample>
