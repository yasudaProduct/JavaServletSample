<%--
  【座学メモ】「遅い」と言われたときに見るところ
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="performance-basics">

  <h2>まず「どこが」を決める</h2>
  <p>
    遅いと言われて、いきなりコードを読み始めると、たいてい外します。
    Web アプリの待ち時間は、ほとんどの場合<strong>次のどれか 1 つ</strong>に偏っています。
  </p>
<pre class="topic-figure">ブラウザ  ──①──  サーバ  ──②──  DB
   ③                  ④

① 通信・待ち行列    回線、リクエストの本数、順番待ち
② DB とのやり取り    SQL 1 本の遅さ × 発行回数      ← 業務アプリはここが大半
③ ブラウザ側        画像が大きい、JS が重い
④ Java の処理        件数の多いループ、巨大な文字列連結</pre>
  <p>
    開発環境ではデータが 10 件しか無いので、②はほぼ 0 秒です。
    本番で 100 万件になったときだけ牙をむきます。
    <strong>「手元では速いのに本番だけ遅い」は、ほぼ②です。</strong>
  </p>

  <h2>測らずに直さない</h2>
  <p>
    順番はいつも同じです。
  </p>
  <ol>
    <li><strong>再現する条件を絞る</strong>。全画面か、特定の画面か。全員か、特定の人か。
        いつからか、データ量が増えてからか</li>
    <li><strong>時間を分解する</strong>。ブラウザの開発者ツールで、
        待ち時間（サーバの処理）と転送時間を分ける。
        サーバ側はフィルタで処理時間をログに出す</li>
    <li><strong>SQL の回数と時間を見る</strong>。何本投げているか。1 本あたり何ミリ秒か</li>
    <li>そこで初めて直す。直したら<strong>同じ測り方で比べる</strong></li>
  </ol>
  <p>
    処理時間をログに残す形は「応用・その他 &gt; フィルタで共通処理をはさむ」にあります。
    遅い処理だけ WARN を出すようにしておくと、問い合わせが来る前に気付けます。
  </p>

  <h2>業務アプリの三点セット</h2>

  <h3>1. N+1 問題</h3>
  <p>
    一覧を出すのに、1 件ごとに追加の SQL を投げてしまう形です。
    10 件なら気付きませんが、1000 件で 1001 本になります。
  </p>
<pre><code class="language-java">// 悪い: 明細を 1 件ずつ取りに行く → 1 + N 本
List&lt;Order&gt; orders = orderDao.findAll();           // 1 本
for (Order o : orders) {
    o.setCustomer(customerDao.findById(o.getCustomerId()));  // N 本
}

// 良い: まとめて 1 本にする (JOIN、または IN でまとめて取る)
List&lt;Order&gt; orders = orderDao.findAllWithCustomer();</code></pre>
  <p>
    見つけ方は簡単で、<strong>SQL のログを出して本数を数える</strong>だけです。
    画面を 1 回開いて数十本以上出ていたら、まずこれを疑います。
  </p>

  <h3>2. 全件取ってから絞る</h3>
<pre><code class="language-java">// 悪い: 全件を Java に読み込んでから捨てる
List&lt;Product&gt; all = dao.findAll();
List&lt;Product&gt; result = all.stream()
        .filter(p -&gt; p.getCategory().equals(category))
        .collect(toList());

// 良い: 絞り込みも件数制限も SQL 側でやる
List&lt;Product&gt; result = dao.search(category, offset, limit);</code></pre>
  <p>
    通信量とメモリの両方を無駄にします。件数が増えると
    <code>OutOfMemoryError</code> になり、遅いどころか止まります。
    <strong>一覧画面には必ずページング</strong>を入れる、と決めておくと事故を防げます
    （「一覧・検索 &gt; 検索つき一覧画面」が <code>LIMIT</code> / <code>OFFSET</code> の形です）。
  </p>

  <h3>3. 索引（インデックス）が効いていない</h3>
  <p>
    SQL 1 本が遅いときの原因はたいていこれです。
    索引は「本の巻末索引」と同じで、無ければ全ページをめくります。
  </p>
  <ul>
    <li><strong>WHERE / JOIN / ORDER BY に出てくる列</strong>が候補</li>
    <li>列を加工すると効かなくなる。
        <code>WHERE SUBSTR(code,1,3) = '100'</code> や
        <code>WHERE date_format(...) = ...</code> は全件走査になる</li>
    <li><code>LIKE '%東京%'</code> のように<strong>前が曖昧</strong>だと効かない。
        <code>LIKE '東京%'</code> なら効く</li>
    <li>何でも付ければよいわけではない。更新のたびに索引も更新されるので、
        <strong>登録・更新が遅くなる</strong></li>
  </ul>
  <p>
    効いているかどうかは <code>EXPLAIN</code>（実行計画）で確認します。
    「全件走査（Seq Scan / Full Table Scan）」と出ていれば、そこが遅さの正体です。
  </p>

  <h2>往復の回数を減らす</h2>
  <p>
    1 回 5 ミリ秒の処理でも、200 回呼べば 1 秒です。
    速くするより<strong>呼ぶ回数を減らす</strong>ほうが効くことは多いです。
  </p>
  <ul>
    <li>ループの中で DB を呼ばない（= N+1 をやめる）</li>
    <li>ループの中で外部 API を呼ばない。まとめて送れる API があるならそちらを使う</li>
    <li>1 画面で Ajax を何本も投げていないか確認する。
        <strong>入力のたびに検索するなら debounce を入れる</strong>
        （「非同期通信 &gt; インクリメンタルサーチ」）</li>
    <li>一括更新は 1 件ずつではなくバッチ（<code>addBatch</code>）で送る</li>
  </ul>

  <h2>キャッシュは最後の手段</h2>
  <p>
    速くなるぶん、<strong>古い値が出る</strong>という新しい不具合が生まれます。
    入れるなら、次の順に検討します。
  </p>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 14rem;">対象</th><th>置き場所と注意</th></tr></thead>
      <tbody>
        <tr>
          <td>CSS・JS・画像</td>
          <td>一番効いて一番安全。長期キャッシュ + ファイル名にバージョンを入れる</td>
        </tr>
        <tr>
          <td>ほぼ変わらないマスタ<br>（都道府県、区分値）</td>
          <td><code>application</code> スコープに持つ。
              <strong>複数スレッドから読まれる</strong>ので、不変にするか同期する</td>
        </tr>
        <tr>
          <td>利用者ごとの一時データ</td>
          <td>セッション。ただし人数 × サイズでメモリを食う
              （→ <a href="${ctx}/topics/session-scaleout">セッションはどこにあるか</a>）</td>
        </tr>
        <tr>
          <td>更新のある業務データ</td>
          <td>安易に入れない。入れるなら「いつ消すか」を先に決める</td>
        </tr>
      </tbody>
    </table>
  </div>

  <h2>Java 側でありがちなもの</h2>
  <ul>
    <li>ループの中での <code>String</code> 連結 → <code>StringBuilder</code>。
        件数が多いときだけ効く</li>
    <li>巨大なファイルを <code>byte[]</code> に全部読む → ストリームで流す</li>
    <li>ログを毎行 DEBUG で出している → 本番ではレベルを上げる。
        文字列の組み立て自体が重い</li>
    <li>毎回 <code>new</code> している重いオブジェクト
        （<code>SimpleDateFormat</code> など）→ 使い回す。
        ただし<strong>スレッドセーフか確認してから</strong></li>
  </ul>

  <h2>遅いのか、詰まっているのか</h2>
  <p>
    1 人で開いても遅いなら、この記事の話です。
    <strong>人が増えたときだけ返ってこなくなるなら、別の問題</strong>で、
    スレッドや接続の上限が原因です。
    「<a href="${ctx}/topics/threads-and-pools">スレッドとプール</a>」を先に読んでください。
  </p>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li>手元で速く本番で遅いものは、ほぼ<strong>データ量</strong>の問題</li>
      <li>まず SQL の本数を数える。N+1 はそれだけで見つかる</li>
      <li>絞り込みと件数制限は SQL 側でやる。一覧には必ずページング</li>
      <li>キャッシュは最後。入れる前に「いつ消すか」を決める</li>
    </ul>
  </div>

</t:topic>
