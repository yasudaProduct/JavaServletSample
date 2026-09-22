<%--
  【座学メモ】どこに何を書くか（Servlet / Service / DAO）
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="layering">

  <h2>全部 Servlet に書いても動く</h2>
  <p>
    これは事実です。だから最初はそう書きます。問題は、そのあと起きることのほうです。
  </p>
<pre><code class="language-java">protected void doPost(HttpServletRequest req, HttpServletResponse res) {
    String name  = req.getParameter("name");            // 画面から受け取る
    if (name == null || name.isEmpty()) { ... }         // 入力チェック
    try (Connection con = Database.getConnection()) {   // DB につなぐ
        PreparedStatement ps = con.prepareStatement(    // SQL を書く
            "INSERT INTO customer (name, ...) VALUES (?, ...)");
        ...
        if (残高 &lt; 金額) { ... }                        // 業務ルール
        con.commit();
    }
    req.setAttribute("message", "登録しました");         // 画面に返す
    forward(req, res, "/WEB-INF/views/…");
}</code></pre>
  <p>
    1 画面なら読めます。20 画面になると、次のことが起きます。
  </p>
  <ul>
    <li>同じ業務ルールが<strong>画面の数だけコピーされる</strong>。1 つ直しても他が残る</li>
    <li>「この計算、どこでやっていたか」を探すのに、全 Servlet を grep することになる</li>
    <li>バッチや API から同じ処理をしたいのに、<code>HttpServletRequest</code> が無いので呼べない</li>
    <li>テストを書こうとすると、テストのためにサーブレットコンテナが要る</li>
  </ul>

  <h2>分ける基準は「何が変わったら直すか」</h2>
  <p>
    層に分ける目的は、きれいに見せることではありません。
    <strong>変更の理由ごとにファイルを分けておく</strong>ことです。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead>
        <tr><th style="width: 9rem;">層</th><th>持つ責任</th><th>これが変わったら直る</th></tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Servlet</strong><br><span class="text-muted small">画面の窓口</span></td>
          <td>パラメータを受け取り、形を整え、呼び、結果を画面に渡す。
              forward か redirect かを決める</td>
          <td>画面の作り、URL、遷移の順番</td>
        </tr>
        <tr>
          <td><strong>Service</strong><br><span class="text-muted small">業務の手順</span></td>
          <td>業務ルールの判断、複数の DAO をまとめた 1 つの仕事、
              <strong>トランザクションの範囲</strong></td>
          <td>業務のきまり（締め日、上限額、割引率）</td>
        </tr>
        <tr>
          <td><strong>DAO</strong><br><span class="text-muted small">DB の出入口</span></td>
          <td>SQL を書く。行をオブジェクトに詰める</td>
          <td>テーブル定義、DB 製品</td>
        </tr>
        <tr>
          <td><strong>DTO / Entity</strong><br><span class="text-muted small">運ぶ箱</span></td>
          <td>値を持つだけ</td>
          <td>扱う項目</td>
        </tr>
      </tbody>
    </table>
  </div>

  <h2>依存は一方通行にする</h2>
<pre class="topic-figure">Servlet ──→ Service ──→ DAO ──→ DB
   ↑                             ↑
   HttpServletRequest を          SQL を知っているのは
   知っているのはここだけ           ここだけ</pre>
  <div class="topic-callout">
    <p class="topic-callout__title">この 2 つを守るだけで、ほとんどの効果が出ます</p>
    <ul class="mb-0">
      <li><strong>Service と DAO は <code>HttpServletRequest</code> / <code>HttpSession</code> を受け取らない</strong>。
          必要な値だけを引数でもらう。
          こうしておくと、そのままバッチからも API からも呼べて、テストも書ける</li>
      <li><strong>SQL は DAO の外に出さない</strong>。
          Servlet に SQL が 1 行でもあると、テーブルを変えたときの影響範囲が読めなくなる</li>
    </ul>
  </div>
  <p>
    逆向き（DAO が Servlet を呼ぶ、Service が画面のことを知っている）が現れたら、
    そこは設計が崩れ始めた合図です。
  </p>

  <h2>トランザクションの範囲は Service で決める</h2>
  <p>
    これが層を分ける実務上の最大の理由です。
    「在庫を減らして、注文を作って、履歴を書く」は<strong>まとめて成功か、まとめて失敗</strong>でなければいけません。
  </p>
<pre><code class="language-java">// DAO ごとに commit していると、途中で失敗したときに前半だけ残る
public void order(int itemId, int count) {
    try (Connection con = Database.getConnection()) {
        con.setAutoCommit(false);          // ← 範囲の開始はここ (Service)
        try {
            stockDao.decrease(con, itemId, count);
            orderDao.insert(con, ...);
            historyDao.insert(con, ...);
            con.commit();                  // ← 全部うまくいってから確定
        } catch (RuntimeException e) {
            con.rollback();
            throw e;
        }
    }
}</code></pre>
  <p>
    ポイントは <strong><code>Connection</code> を DAO に渡している</strong>ところです。
    DAO がそれぞれ勝手に接続を取ると、別のトランザクションになってしまい、まとめられません。
    実際の挙動は「応用・その他 &gt; トランザクション」で、
    rollback させた場合と、使わずに途中で失敗させた場合を並べて確認できます。
  </p>

  <h2>Servlet に残ってよいもの・残ってはいけないもの</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 10rem;"></th><th>例</th></tr></thead>
      <tbody>
        <tr>
          <td class="text-success">残してよい</td>
          <td>パラメータの取り出し、文字列から数値への変換、必須チェックなど<strong>形式の検証</strong>、
              スコープへの詰め込み、forward / redirect の選択、エラー画面の出し分け</td>
        </tr>
        <tr>
          <td class="text-danger">出す</td>
          <td>SQL、金額や日数の計算、権限の判断、外部システムの呼び出し、
              <strong>「残高が足りるか」のような業務判断</strong></td>
        </tr>
      </tbody>
    </table>
  </div>
  <p>
    入力チェックは 2 種類に分けると迷いません。
    <strong>形式の検証（数字か、桁数は足りるか）は画面側の都合</strong>なので Servlet 寄り、
    <strong>存在チェックや相関チェック（その社員コードは実在するか、開始日 &lt; 終了日か）は業務の都合</strong>なので Service 寄りです。
    「フォーム・入力 &gt; 入力チェックの種類」で種類ごとに並べています。
  </p>

  <h2>分けすぎの見分け方</h2>
  <p>
    層は増やせばよいものではありません。次の形が出てきたら、そこは分けすぎです。
  </p>
  <ul>
    <li><strong>右から左に渡すだけのクラス</strong>。
        Service が DAO のメソッドを 1 つ呼んで返すだけなら、その Service は判断を持っていない</li>
    <li><strong>同じ項目の入れ物が 3 つある</strong>。
        Form → DTO → Entity と詰め替えるだけのコードが処理の大半を占めるなら、減らす</li>
    <li><strong>1 か所直すのに 5 ファイル開く</strong>。
        項目を 1 つ足すたびに全層を触るなら、分け方が変更の形に合っていない</li>
  </ul>
  <p>
    このサイトのサンプルも、必要なところだけ分けています。
    「一覧・検索 &gt; マスタメンテナンス」は Servlet / Form / DAO / Entity の 4 つですが、
    業務判断がほとんど無いので Service は置いていません。
    <strong>迷ったら、業務ルールが出てきた時点で Service を作る</strong>くらいで足ります。
  </p>

  <h2>名前の付け方で揉めないために</h2>
  <p>
    Service / Logic / Manager、DAO / Repository / Mapper。どれも同じものを指します。
    大事なのは呼び方ではなく、<strong>プロジェクトの中で 1 つに決まっていること</strong>です。
    途中から混ざると、探す場所が増えるぶんだけ損をします。
  </p>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li>分ける理由は見た目ではなく、<strong>変更の理由ごとにまとめる</strong>ため</li>
      <li>Service / DAO に <code>HttpServletRequest</code> を持ち込まない</li>
      <li>トランザクションの範囲を決めるのは Service。DAO は渡された接続を使う</li>
      <li>右から左に渡すだけの層は、作らないほうがよい</li>
    </ul>
  </div>

</t:topic>
