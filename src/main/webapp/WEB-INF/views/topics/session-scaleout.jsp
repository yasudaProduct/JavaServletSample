<%--
  【座学メモ】セッションはどこにあるか（サーバが 2 台になった日）
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:topic topicId="session-scaleout">

  <h2>セッションの正体</h2>
  <p>
    HTTP には「前回の続き」という考え方がありません。
    1 回のやり取りが終われば、サーバは相手を忘れます。
    それでもログイン状態が続くのは、次の仕掛けがあるからです。
  </p>
<pre class="topic-figure">1 回目  ブラウザ ──────────────→ サーバ
        （何も持っていない）        セッションを作る（メモリ上に Map を 1 つ）
                 ←────────────  Set-Cookie: JSESSIONID=8A3F...

2 回目  ブラウザ ──────────────→ サーバ
        Cookie: JSESSIONID=8A3F...   その ID の Map を探して取り出す
                                      → 「ログイン済み」が入っている</pre>
  <p>
    Cookie で往復しているのは<strong>引換券（ID）だけ</strong>です。
    中身はサーバのメモリの中にあります。ここが全ての出発点になります。
  </p>
  <p>
    実際の出し入れは「基本 &gt; スコープ」で、引換券の発行そのものは「基本 &gt; Cookie の基本」で見られます。
  </p>

  <h2>サーバが 2 台になった日</h2>
  <p>
    アクセスが増えたのでサーバを 2 台にして、前にロードバランサを置きました。
    その日から、問い合わせが増えます。
  </p>
  <p><strong>「ときどき勝手にログアウトする」「入力したはずの内容が消える」</strong></p>
<pre class="topic-figure">        ┌─ ログイン →[ サーバA ]  セッション 8A3F を持っている
ブラウザ ┤
        └─ 次の画面 →[ サーバB ]  8A3F ？ 知らない → 未ログイン扱い</pre>
  <p>
    セッションは<strong>作られたサーバのメモリにしかない</strong>ので、
    振り分け先が変わると消えたように見えます。
    再現しようとしても、手元は 1 台なので絶対に起きません。これが厄介なところです。
  </p>
  <p>
    同じことは 1 台でも起きます。<strong>アプリを再起動・再配備すればメモリは消える</strong>ので、
    リリースのたびに全員がログアウトします。
  </p>

  <h2>対処は 4 つ</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead>
        <tr><th style="width: 13rem;">やり方</th><th>仕組み</th><th>弱点</th></tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>スティッキーセッション</strong></td>
          <td>ロードバランサが「この人は A」と覚えて、同じサーバに送り続ける</td>
          <td>そのサーバが落ちたら、そこの全員が消える。
              台数を増やしても偏る。再配備でも消える</td>
        </tr>
        <tr>
          <td><strong>レプリケーション</strong></td>
          <td>サーバ同士でセッションを複製し合う</td>
          <td>台数が増えるほど複製の負荷が増える。
              入れる値は <code>Serializable</code> でなければならない</td>
        </tr>
        <tr class="table-success">
          <td><strong>外部に置く</strong></td>
          <td>Redis などの共有ストアに保存し、どのサーバからも同じものを見る</td>
          <td>その置き場所が止まると全滅するので、そちらの冗長化が要る</td>
        </tr>
        <tr>
          <td><strong>そもそも持たない</strong></td>
          <td>ログイン状態を署名付きトークン（JWT など）にしてブラウザ側に持たせる</td>
          <td>渡したトークンを<strong>途中で取り消せない</strong>。
              権限変更や強制ログアウトの設計が別途要る</td>
        </tr>
      </tbody>
    </table>
  </div>
  <p>
    業務システムでは 1 → 3 の順に移っていくことが多く、
    4 は「ブラウザ以外からも使う API」を作るときに出てきます。
    どれを選ぶかは運用の話なので、<strong>アプリを書く側は
    「セッションに何を入れるか」だけ気をつければ足ります</strong>。
  </p>

  <h2>セッションに入れてよいもの・よくないもの</h2>
  <div class="table-responsive">
    <table class="table table-sm table-bordered doc-table">
      <thead><tr><th style="width: 10rem;"></th><th>中身</th><th>理由</th></tr></thead>
      <tbody>
        <tr>
          <td class="text-success">入れてよい</td>
          <td>ユーザ ID、表示名、権限、CSRF トークン、入力途中の画面 1 つ分</td>
          <td>小さく、消えても作り直せる</td>
        </tr>
        <tr>
          <td class="text-danger">避ける</td>
          <td>検索結果の全件、アップロードしたファイルの中身、DB から読んだ大きなオブジェクト</td>
          <td>人数 × サイズだけメモリを食う。1 人 1MB でも 1000 人で 1GB</td>
        </tr>
        <tr>
          <td class="text-danger">避ける</td>
          <td><code>Connection</code>、ストリーム、スレッド</td>
          <td>複製も保存もできない。閉じ忘れが必ず起きる</td>
        </tr>
      </tbody>
    </table>
  </div>
  <div class="topic-callout topic-callout--warn">
    <p class="topic-callout__title">セッションは自然には消えない</p>
    <p class="mb-0">
      ログアウトせずにブラウザを閉じた人のセッションは、
      <strong>タイムアウト（既定 30 分）まで残り続けます</strong>。
      サーバから見れば「まだ居るかもしれない人」だからです。
      大きな値を入れていると、これがそのままメモリ使用量になります。
      使い終わったら <code>removeAttribute</code>、
      ログアウト時は <code>invalidate()</code>。
    </p>
  </div>

  <h2>引換券そのものを守る</h2>
  <p>
    中身がサーバにあっても、ID を盗まれれば成りすませます。最低限これだけは押さえます。
  </p>
  <ul>
    <li><strong><code>HttpOnly</code></strong> … JavaScript から読めなくする。XSS の被害を限定する</li>
    <li><strong><code>Secure</code></strong> … HTTPS のときだけ送る</li>
    <li><strong><code>SameSite</code></strong> … 他サイトからの送信を制限する（CSRF 対策の下支え）</li>
    <li><strong>ログイン成功時に ID を振り直す</strong> …
        攻撃者が用意した ID のまま使わせない（セッション固定攻撃）。
        <code>request.changeSessionId()</code> を呼ぶ</li>
  </ul>
  <p>
    このサイトでは <code>web.xml</code> の <code>cookie-config</code> で <code>HttpOnly</code> を有効にしています。
    振り直しは「セッション・認証 &gt; ログインとログアウト」で実際にやっています。
  </p>

  <h2>URL にセッション ID が出るとき</h2>
  <p>
    <code>;jsessionid=...</code> が URL に付いているのを見たことがあるかもしれません。
    Cookie が使えないブラウザ向けの代替手段（URL 書き換え）です。
  </p>
  <p>
    今は<strong>使わないのが原則</strong>です。URL は履歴・ログ・共有リンク・Referer に残るため、
    そこに引換券が乗ると漏れます。
    <code>web.xml</code> で <code>&lt;tracking-mode&gt;COOKIE&lt;/tracking-mode&gt;</code> と明示すれば止められます。
  </p>

  <div class="topic-callout">
    <p class="topic-callout__title">覚えておくこと</p>
    <ul class="mb-0">
      <li>Cookie で往復しているのは ID だけ。中身はサーバのメモリ</li>
      <li>だから「サーバが増える」「再起動する」と消える。1 台の手元では絶対に再現しない</li>
      <li>入れるのは小さくて作り直せるものだけ。人数を掛け算して考える</li>
      <li>ログイン時に ID を振り直す。これは 1 行で済む</li>
    </ul>
  </div>

</t:topic>
