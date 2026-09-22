<%--
  【座学メモ】業務 Web のセキュリティ全体像
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="security-overview">

  <h2>攻撃名を覚える前に</h2>
  <p>
    脆弱性の名前は毎年増えますが、業務 Web で実際に踏むものは数が限られています。
    しかもその大半は、次の 2 つを守れば起きません。
  </p>
  <div class="topic-callout">
    <p class="topic-callout__title">原則はこの 2 つだけ</p>
    <ol class="mb-0">
      <li><strong>境界の外から来た値を、そのまま信じない</strong></li>
      <li><strong>外へ出すときは、出す場所の文法に合わせて加工する</strong></li>
    </ol>
  </div>
  <p>
    1 が「入口」、2 が「出口」の話です。
    そして多くの事故は、<strong>入口で頑張って出口を忘れる</strong>ことで起きます。
  </p>

  <h2>「境界の外」はどこまでか</h2>
  <p>
    入力欄だけではありません。<strong>ブラウザから届くものは全部</strong>です。
    画面で制限したつもりでも、ブラウザを通さずに直接送れます。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 16rem;">これも外から来る</th><th>見落とす理由</th></tr></thead>
      <tbody>
        <tr><td>hidden の値</td><td>画面に出ないので「変えられない」と思ってしまう</td></tr>
        <tr><td>プルダウンの選択肢</td><td>選択肢しか選べないのは画面の都合でしかない</td></tr>
        <tr><td>disabled / readonly の項目</td><td>同上。送信されないだけで、手で送れる</td></tr>
        <tr><td>URL のパラメータ、パスの一部</td><td><code>?id=1042</code> を <code>1043</code> に書き換えられる</td></tr>
        <tr><td>Cookie、リクエストヘッダ</td><td>ブラウザが付けるものだと思い込みやすい</td></tr>
        <tr><td>アップロードしたファイル名・種別</td><td>自己申告なので、いくらでも詐称できる</td></tr>
        <tr><td>JavaScript でのチェック結果</td><td>止めているのは手元のブラウザだけ</td></tr>
      </tbody>
    </table>
  </div>
  <p>
    JavaScript のチェックを外すと何が通ってしまうかは、
    「フォーム・入力 &gt; 入力チェック（フォーカスアウト時）」で実際に試せます。
    <strong>画面側のチェックは親切のためで、守りではありません。</strong>
  </p>

  <h2>出口ごとに加工の仕方が違う</h2>
  <p>
    同じ値でも、HTML に出すのか SQL に混ぜるのかで、危ない文字が変わります。
    「危険な文字を入口で消す」方式がうまくいかないのはこのためです。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 9rem;">出す先</th><th>やること</th><th>起きること</th></tr></thead>
      <tbody>
        <tr>
          <td>HTML</td>
          <td>エスケープする。JSP なら <code>c:out</code> / <code>fn:escapeXml</code>。
              EL にそのまま書かない</td>
          <td><strong>XSS</strong>。入力欄に script を入れられ、他人のブラウザで動く</td>
        </tr>
        <tr>
          <td>SQL</td>
          <td>文字列連結をやめ、<code>PreparedStatement</code> の <code>?</code> で渡す</td>
          <td><strong>SQL インジェクション</strong>。認証を素通りされる、全件抜かれる</td>
        </tr>
        <tr>
          <td>HTTP ヘッダ</td>
          <td>改行を含む値を入れない</td>
          <td>ヘッダを偽装される（<strong>ヘッダインジェクション</strong>）</td>
        </tr>
        <tr>
          <td>ファイルパス</td>
          <td>受け取った名前をパスに使わない。ID で引いて自分で決める</td>
          <td><code>../../etc/passwd</code> のような<strong>ディレクトリトラバーサル</strong></td>
        </tr>
        <tr>
          <td>CSV</td>
          <td>先頭が <code>=</code> <code>+</code> <code>-</code> <code>@</code> の値を無害化する</td>
          <td>Excel で開いたときに式として実行される（<strong>CSV インジェクション</strong>）</td>
        </tr>
        <tr>
          <td>リダイレクト先</td>
          <td>外部 URL を受け付けない。自サイト内のパスだけ許可する</td>
          <td><strong>オープンリダイレクト</strong>。偽サイトへ誘導される</td>
        </tr>
      </tbody>
    </table>
  </div>
  <p>
    CSV とリダイレクトは、それぞれ「ファイル &gt; CSV ダウンロード」
    「セッション・認証 &gt; フィルタで未ログインを弾く」で具体的に扱っています。
  </p>

  <h2>認証と認可は別のもの</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 9rem;"></th><th>問い</th><th>失敗時</th></tr></thead>
      <tbody>
        <tr><th scope="row">認証</th><td>あなたは誰か</td><td><strong>401</strong>（ログインすれば通るかもしれない）</td></tr>
        <tr><th scope="row">認可</th><td>それをしてよいか</td><td><strong>403</strong>（ログインし直しても通らない）</td></tr>
      </tbody>
    </table>
  </div>
  <p>
    そして<strong>実際に多いのは認可漏れのほう</strong>です。
    ログインは作り込むのに、「その人のデータか」の確認を忘れます。
  </p>
<pre><code class="language-java">// 悪い: ログインしていれば、他人の注文でも表示できてしまう
Order order = orderDao.findById(request.getParameter("orderId"));

// 良い: 「自分のものか」まで条件に入れる
Order order = orderDao.findByIdAndUser(orderId, loginUser.getId());
if (order == null) { 403 または 404; }</code></pre>
  <p>
    URL の数字を 1 つ増やすだけで他人のデータが見えた、という事故はこの形で起きます。
    <strong>一覧に出していない = 見えない、ではありません。</strong>
    画面の入口ごとではなく、<strong>データを取る場所で</strong>絞るのが確実です。
  </p>

  <h2>依頼が本物かを確かめる（CSRF）</h2>
  <p>
    ログイン済みのブラウザは、どこのページから送られた依頼でも Cookie を付けて送ります。
    つまりサーバから見ると、<strong>罠のページから送られた更新依頼も、正規の画面からの依頼も同じ形</strong>です。
  </p>
  <p>
    対策は「自分の画面から来たことの証明」を 1 つ足すこと。
    画面を出すときにトークンを埋め、受け取ったときに照合します。
    <code>SameSite</code> Cookie も効きますが、
    ブラウザ任せなので<strong>サーバ側のトークンと併用</strong>するのが基本です。
    トークンあり・なし・でたらめの 3 通りを送り比べるサンプルがあります。
  </p>

  <h2>パスワードの扱い</h2>
  <ul>
    <li><strong>平文で保存しない。</strong>暗号化でもなくハッシュ（元に戻せない）にする</li>
    <li>ハッシュは<strong>パスワード用のもの</strong>を使う（bcrypt / PBKDF2 / Argon2）。
        MD5 や SHA-256 はここでは速すぎて向かない</li>
    <li>利用者ごとに異なる<strong>ソルト</strong>を混ぜる（同じパスワードでも別の値になる）</li>
    <li><strong>ログイン失敗時に「ID が違う」「パスワードが違う」を区別しない。</strong>
        区別すると、存在する ID の一覧を作られる</li>
    <li>ログイン成功時に<strong>セッション ID を振り直す</strong>（セッション固定攻撃）</li>
  </ul>

  <h2>アップロードを受け取るとき</h2>
  <ul>
    <li>拡張子と <code>Content-Type</code> は<strong>自己申告</strong>。信じない</li>
    <li>送られてきたファイル名をそのまま保存名に使わない（<code>../</code> と日本語の両方で事故る）</li>
    <li>公開ディレクトリに置かない。置くなら<strong>実行されない場所</strong>へ</li>
    <li>サイズ上限と件数上限を必ず決める（決めないと、それだけで停止させられる）</li>
    <li>返すときは <code>Content-Disposition: attachment</code> を付け、ブラウザ内で開かせない</li>
  </ul>

  <h2>秘密を置く場所</h2>
  <p>
    DB のパスワードや API キーを<strong>ソースコードに書かない</strong>。
    リポジトリに入った時点で、削除しても履歴に残ります。
    環境変数か、サーバ側の設定（JNDI など）から読みます。
    この話は「<a href="${ctx}/topics/beyond-localhost">localhost と本番の違い</a>」で詳しく扱います。
  </p>

  <h2>自分が書いていない部分も穴になる</h2>
  <p>
    使っているライブラリの脆弱性は、自分のコードと同じだけ危険です。
    <code>pom.xml</code> に書いた依存は、書いた日のまま固まります。
  </p>
  <ul>
    <li>依存の一覧とバージョンを把握しておく（<code>mvn dependency:tree</code>）</li>
    <li>脆弱性の通知を受け取る仕組みを入れる（GitHub の Dependabot など）</li>
    <li>上げられない事情があるなら、<strong>その判断を記録しておく</strong></li>
  </ul>

  <h2>最低限の確認表</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 22rem;">確認</th><th>関係する事故</th></tr></thead>
      <tbody>
        <tr><td>画面に出す値をエスケープしているか</td><td>XSS</td></tr>
        <tr><td>SQL を文字列連結していないか</td><td>SQL インジェクション</td></tr>
        <tr><td>更新は POST で受け、トークンを照合しているか</td><td>CSRF</td></tr>
        <tr><td>取得・更新で「自分のデータか」を条件に入れているか</td><td>認可漏れ</td></tr>
        <tr><td>JavaScript のチェックと同じ検証をサーバ側にも書いたか</td><td>入力検証の迂回</td></tr>
        <tr><td>ログイン成功時にセッション ID を振り直しているか</td><td>セッション固定</td></tr>
        <tr><td>Cookie に HttpOnly / Secure / SameSite を付けたか</td><td>セッション奪取</td></tr>
        <tr><td>パスワードをハッシュで保存しているか</td><td>漏洩時の被害拡大</td></tr>
        <tr><td>エラー画面にスタックトレースが出ていないか</td><td>内部構造の漏洩</td></tr>
        <tr><td>接続情報やキーがソースに書かれていないか</td><td>資格情報の漏洩</td></tr>
      </tbody>
    </table>
  </div>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li>入口で信じない、出口で加工する。加工の仕方は<strong>出す先で決まる</strong></li>
      <li>画面側のチェックは守りにならない。同じ検証をサーバ側にも書く</li>
      <li>認証より<strong>認可漏れ</strong>のほうが起きやすい。データを取る場所で絞る</li>
      <li>秘密はコードに書かない。ライブラリも自分のコードのうち</li>
    </ul>
  </div>

</t:topic>
