<%--
  【サンプル】スコープ (request / session / application)

  ScopeServlet が次の値をセットします。
    requestEntries / sessionEntries / applicationEntries … 各スコープに入れた値の一覧
    sessionId / sessionCreatedText / ...                  … セッションの情報
    noticeVariant / noticeTitle / noticeText              … 画面上部のお知らせ

  「同じ名前と値でも、どこに置いたかで残り方と見える範囲が変わる」ことを
  実際に入れて・開き直して・消して確かめるサンプルです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="scopeUrl" value="${ctx}/samples/basic/scope" />
<c:set var="selectedScope" value="${empty inputScope ? 'request' : inputScope}" />
<%--
  scope を書かない <c:set> は page スコープに入ります。
  page スコープはこの JSP を 1 ページ組み立てている間だけの入れ物なので、
  ?withPage=1 を外して開き直すと消えます (探索順のデモで使っています)。
--%>
<c:if test="${param.withPage eq '1'}">
  <c:set var="scopeDemoValue" value="page スコープに入れた値" />
</c:if>
<t:sample sampleId="scope">

  <jsp:attribute name="explanation">
    <h2>スコープは「値の置き場所」</h2>
    <p>
      Servlet から JSP へ値を渡すときに使う <code>setAttribute</code> は、
      <strong>どこに置くか</strong>を選べます。置き場所のことをスコープと呼び、
      選んだスコープによって「いつまで残るか」と「誰に見えるか」が決まります。
      機能の違いではなく<strong>寿命と共有範囲の違い</strong>だと考えると分かりやすいです。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr>
            <th>スコープ</th>
            <th>入れ方（Java）</th>
            <th>生きている間</th>
            <th>見える範囲</th>
            <th>向いているもの</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>page</code></td>
            <td><code>pageContext.setAttribute(...)</code><br>JSP の <code>&lt;c:set&gt;</code>（scope 省略時）</td>
            <td>その JSP を 1 ページ組み立てている間</td>
            <td>その JSP の中だけ</td>
            <td>画面を組み立てる途中の一時変数（合計値、整形した文字列）</td>
          </tr>
          <tr>
            <td><code>request</code></td>
            <td><code>request.setAttribute(...)</code></td>
            <td>1 回のリクエストの間（<code>forward</code> 先を含む）</td>
            <td>そのリクエストを処理している間だけ</td>
            <td>Servlet から JSP へ渡す表示用のデータ、エラーメッセージ</td>
          </tr>
          <tr>
            <td><code>session</code></td>
            <td><code>request.getSession().setAttribute(...)</code></td>
            <td>そのブラウザのセッションが続く間（このサイトは 30 分）</td>
            <td>同じブラウザからのリクエスト全部</td>
            <td>ログイン中の利用者、入力途中のカート、ウィザードの途中経過</td>
          </tr>
          <tr>
            <td><code>application</code></td>
            <td><code>getServletContext().setAttribute(...)</code></td>
            <td>アプリが動いている間ずっと</td>
            <td><strong>そのアプリを見ている全員</strong></td>
            <td>起動時に読む設定値、滅多に変わらないマスタのキャッシュ</td>
          </tr>
        </tbody>
      </table>
    </div>

    <p>
      上から下へ行くほど<strong>寿命が長く、共有範囲が広く</strong>なります。
      迷ったら<strong>いちばん短いスコープから選ぶ</strong>のが原則です。
      長いスコープに置いた値は、消し忘れるとサーバのメモリに残り続け、
      別の利用者や別の画面に思わぬ形で影響します。
    </p>

    <h2>このサンプルの処理の流れ</h2>
    <ol>
      <li>画面でスコープ・名前・値を選んで POST する</li>
      <li><code>ScopeServlet#doPost</code> が値を検査する（名前の文字種、文字数、application の件数）</li>
      <li>
        選ばれたスコープに <code>setAttribute</code> する。属性名は
        <code>scopeSample.entry.〜</code> という接頭辞つきにする
      </li>
      <li>
        session / application に入れた場合はリダイレクトして GET に戻る（PRG パターン）。<br>
        <strong>request に入れた場合だけは forward</strong> する
        — リダイレクトすると別のリクエストになり、入れた値がその場で消えてしまうため
      </li>
      <li>
        表示側は 3 つのスコープから接頭辞つきの属性を集めて表に並べる
      </li>
    </ol>

    <h2>request スコープ（1 リクエストの間）</h2>
    <p>
      いちばんよく使うスコープです。Servlet が取ってきたデータを JSP に渡すのはこれです。
      <code>forward</code> はサーバの中で処理を渡すだけなので、同じリクエストが続いており、
      転送先の JSP からも値が見えます。
    </p>
<pre><code class="language-java">// Servlet 側
request.setAttribute("products", products);
request.getRequestDispatcher("/WEB-INF/views/list.jsp").forward(request, response);</code></pre>
<pre><code class="language-xml">&lt;%-- JSP 側 --%&gt;
&lt;c:forEach var="p" items="${'${products}'}"&gt; ... &lt;/c:forEach&gt;</code></pre>
    <p>
      逆に <code>sendRedirect</code> は「この URL をもう一度取りに行って」とブラウザに返すため、
      次は<strong>別のリクエスト</strong>になります。request スコープに入れた値は届きません。
      リダイレクトをまたいで値を渡したいときは、URL のクエリ文字列に載せるか、
      セッションに 1 回だけ預ける（フラッシュメッセージ。<code>common/Flash.java</code>）かのどちらかです。
    </p>

    <h2>session スコープ（そのブラウザの間）</h2>
    <p>
      HTTP は 1 回のやり取りごとに関係が切れる（ステートレスな）約束事なので、
      サーバは「さっきの人」を自力では覚えていません。
      そこでサーバは <code>JSESSIONID</code> という<strong>整理券</strong>を Cookie でブラウザに渡し、
      次のリクエストで持ってきた整理券から、サーバのメモリにある値を引き当てます。
      これが session スコープです。
    </p>
<pre><code class="language-java">// 無ければ新しく作る
HttpSession session = request.getSession();
session.setAttribute("loginUser", user);

// 「あれば使う、無ければ作らない」。ログイン判定などはこちらを使う
HttpSession current = request.getSession(false);
if (current == null || current.getAttribute("loginUser") == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
}</code></pre>

    <h3>セッションはサーバのメモリを使う</h3>
    <p>
      セッションの中身は<strong>サーバ側</strong>に置かれます。
      1 人あたり 100 KB 使う作りにすると、同時に 1,000 人が使うだけで 100 MB です。
      しかも利用者が「終わりました」と言ってくれることはまれなので、
      タイムアウトするまでは残り続けます。
    </p>
    <ul>
      <li>検索結果の一覧をまるごと入れない（ページを開き直すたびに増えていきます）</li>
      <li>入れるのは <code>id</code> や検索条件だけにして、実データは都度 DB から取る</li>
      <li>使い終わった値は <code>removeAttribute</code> で明示的に消す</li>
      <li>
        入れるオブジェクトは <code>Serializable</code> にしておく
        — サーバを再起動したときにセッションをファイルへ退避する構成や、
        複数台構成でセッションを共有する構成では、直列化できないと落ちます
      </li>
    </ul>

    <h2>セッションタイムアウトと invalidate</h2>
    <p>
      セッションは「最後にアクセスしてから何分操作が無かったか」で切れます。
      このサイトでは <code>web.xml</code> で 30 分にしています。
    </p>
<pre><code class="language-xml">&lt;session-config&gt;
  &lt;session-timeout&gt;30&lt;/session-timeout&gt;   &lt;!-- 分 --&gt;
  &lt;cookie-config&gt;
    &lt;http-only&gt;true&lt;/http-only&gt;            &lt;!-- JavaScript から Cookie を読めなくする --&gt;
  &lt;/cookie-config&gt;
&lt;/session-config&gt;</code></pre>
<pre><code class="language-java">// 特定のセッションだけ短くする (秒で指定する。-1 で無期限)
session.setMaxInactiveInterval(10 * 60);

// ログアウト : セッションごと捨てる
session.invalidate();</code></pre>
    <p>
      ログアウトで <code>removeAttribute("loginUser")</code> だけを呼ぶ実装をときどき見かけますが、
      それではカートや検索条件など<strong>他の値が残ります</strong>。
      ログアウトは <code>invalidate()</code> でセッションごと捨てるのが基本です。
    </p>
    <p>
      逆に<strong>ログインに成功した直後</strong>は、いったん <code>invalidate()</code> して
      入れ直す（または <code>request.changeSessionId()</code> を呼ぶ）ようにします。
      ログイン前に攻撃者が用意したセッション ID をそのまま使い続けると、
      ログイン後の状態を乗っ取られてしまうためです（セッション固定攻撃）。
    </p>
    <p>
      なお <code>invalidate()</code> の直後に <code>getSession()</code> を呼ぶと、
      <strong>新しいセッションが作られて ID が変わります</strong>。
      このサンプルで「セッションを破棄」したあとにセッション ID が変わっているのは、
      完了メッセージをセッションに預けているためです。
    </p>

    <h2>application スコープ（全員で 1 つ）</h2>
    <p>
      <code>ServletContext</code> はアプリに 1 つだけあるオブジェクトです。
      ここに入れた値は、<strong>アクセスしている全員が同じものを見ます</strong>。
      利用者ごとの情報を置く場所ではありません（他人に見えてしまいます）。
    </p>
    <ul>
      <li>向いているもの … 起動時に読み込む設定値、めったに変わらないマスタのキャッシュ、全体の集計カウンタ</li>
      <li>向かないもの … ログイン中の利用者、入力途中のデータ、利用者ごとの検索条件</li>
    </ul>

    <h3>全スレッドで共有される = スレッドセーフに書く</h3>
    <p>
      Servlet は<strong>1 つのインスタンスを全リクエストで使い回し</strong>、
      リクエストごとに別のスレッドで <code>doGet</code> / <code>doPost</code> が動きます。
      application スコープの値も同時に読み書きされるため、普通の <code>HashMap</code> を置いて
      複数スレッドから更新すると、入れたはずの値が消えたり、書き換えの途中の状態が見えたりします
      （Java 7 以前では、書き込みが重なった拍子に取り出しが終わらなくなる不具合もありました）。
      しかもこの手の不具合は、同時アクセスが増えたときにだけ、再現しない形で出ます。
    </p>
<pre><code class="language-java">// ① スレッドセーフな入れ物を置く (入れ物は入れ替えず、中身を更新する)
context.setAttribute("codeCache", new ConcurrentHashMap&lt;String, String&gt;());

// ② 数えるだけなら AtomicLong / AtomicInteger
AtomicLong counter = (AtomicLong) context.getAttribute("viewCount");
counter.incrementAndGet();

// ③ 「読んでから書く」が 1 まとまりでないと困る処理は同期化する
//    ServletContext は全スレッドから見える唯一のオブジェクトなので鍵に使えます
synchronized (context) {
    if (context.getAttribute(key) == null &amp;&amp; count(context) &gt;= MAX) {
        return false;          // 上限に達していたら入れない
    }
    context.setAttribute(key, value);
}</code></pre>
    <p>
      同じ理由で、<strong>Servlet のフィールド（インスタンス変数）に状態を持たせてはいけません</strong>。
      インスタンスは 1 つしかないので、それは実質 application スコープと同じであり、
      しかも見えにくい分だけ危険です。リクエストごとの値はローカル変数か request スコープに置きます。
    </p>

    <h2>page スコープ（その JSP の中だけ）</h2>
    <p>
      JSP の中で使う一時変数です。<code>&lt;c:set&gt;</code> で <code>scope</code> を書かなければ page スコープになります。
    </p>
<pre><code class="language-xml">&lt;c:set var="ctx" value="${'${pageContext.request.contextPath}'}" /&gt;          &lt;%-- page --%&gt;
&lt;c:set var="keyword" value="${'${param.q}'}" scope="request" /&gt;              &lt;%-- request --%&gt;</code></pre>
    <p>
      page スコープはその JSP 1 枚のものなので、<code>&lt;jsp:include&gt;</code> した先や
      タグファイルの中には引き継がれません（引き継ぎたいときは request スコープか、タグの属性で渡します）。
    </p>
    <p>
      紛らわしいのですが、下のデモ ③ では <code>&lt;t:sample&gt;</code> の内側にいるのに page スコープが見えています。
      これは <code>&lt;jsp:body&gt;</code> に書いた部分が<strong>タグファイルの中身ではなく、呼び出し側の JSP に書いた本文</strong>だからです。
      置かれているのは呼び出し側の page スコープのままなので、タグファイル自身が
      <code>&lt;c:set&gt;</code> した値とは別物です。
    </p>

    <h2>EL からの読み方と、スコープを省略したときの探索順</h2>
    <p>
      JSP からは、スコープ名を付けた暗黙オブジェクトで読み分けられます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>書き方</th><th>意味</th></tr></thead>
        <tbody>
          <tr><td><code>${'${pageScope.foo}'}</code></td><td>page スコープの <code>foo</code></td></tr>
          <tr><td><code>${'${requestScope.foo}'}</code></td><td>request スコープの <code>foo</code></td></tr>
          <tr><td><code>${'${sessionScope.foo}'}</code></td><td>session スコープの <code>foo</code></td></tr>
          <tr><td><code>${'${applicationScope.foo}'}</code></td><td>application スコープの <code>foo</code></td></tr>
          <tr><td><code>${'${foo}'}</code></td><td>スコープを省略した書き方（下記の順に探す）</td></tr>
          <tr>
            <td><code>${'${param.foo}'}</code></td>
            <td>
              スコープではなく<strong>リクエストパラメータ</strong>（<code>?foo=...</code> や入力欄）。
              名前が同じでも別物です
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      スコープを省略すると、<strong>page → request → session → application</strong> の順に探し、
      最初に見つかったものを返します。どこにも無ければ（例外ではなく）空文字として表示されます。
    </p>
    <p>
      つまり<strong>狭いスコープが広いスコープを隠します</strong>。
      「セッションに入れたはずの値が出てこない」というときは、
      同じ名前が request スコープに入っていないかを疑ってください。
      デモの ③ で実際に確かめられます。
    </p>
    <p>
      属性名に <code>.</code> が含まれる場合は、ドットをプロパティの参照だと解釈されてしまうため、
      角かっこで名前を丸ごと指定します。
    </p>
<pre><code class="language-xml">${'${requestScope[\'scopeSample.entry.memo\']}'}      &lt;%-- ○ --%&gt;
${'${requestScope.scopeSample.entry.memo}'}          &lt;%-- × 取り出せない --%&gt;</code></pre>
    <p>
      なお EL から<strong>書き込む</strong>ことはできません。値を入れるのは Servlet か
      <code>&lt;c:set scope="session" ...&gt;</code> の役目です。
    </p>

    <h2>どこに置くか迷ったら</h2>
    <ul>
      <li>その画面を作るためだけの値 → <strong>request</strong>（まずはここを検討します）</li>
      <li>画面をまたいで覚えておく必要がある利用者ごとの値 → <strong>session</strong>（最小限だけ）</li>
      <li>全員に共通で、めったに変わらない値 → <strong>application</strong>（スレッドセーフに）</li>
      <li>消えたら困る値 → <strong>どのスコープでもなく DB</strong>（スコープは再起動で消えます）</li>
    </ul>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>リダイレクトしたら値が消えた</strong>：
        request スコープは 1 リクエストのものです。<code>sendRedirect</code> をはさむと別のリクエストになります。
        このサンプルで request への格納だけ forward しているのは、
        リダイレクトすると何も確かめられなくなるからです。
      </li>
      <li>
        <strong>セッションに入れたのに別のブラウザで見えない</strong>：
        それが正しい動きです。session は Cookie の <code>JSESSIONID</code> で引き当てるので、
        別のブラウザ（やシークレットウィンドウ）は別のセッションになります。
        Cookie を拒否する設定だと、リクエストのたびに新しいセッションになります。
      </li>
      <li>
        <strong>同じ人が複数のタブで開くと壊れる</strong>：
        タブが違っても Cookie は同じなので<strong>セッションは 1 つ</strong>です。
        「入力途中の 1 件」をセッションに置くと、2 つのタブで上書きし合います。
        画面ごとに分けたいなら、キーに画面の識別子を含めるか、hidden で持ち回ります。
      </li>
      <li>
        <strong><code>invalidate()</code> したセッションを使ってしまう</strong>：
        破棄したあとに <code>getAttribute</code> などを呼ぶと <code>IllegalStateException</code> になります。
        破棄したあとに使いたいときは、改めて <code>request.getSession()</code> で作り直します
        （ID は変わります）。
      </li>
      <li>
        <strong>タイムアウト後に <code>NullPointerException</code></strong>：
        <code>request.getSession(false)</code> は、セッションが切れていると <code>null</code> を返します。
        戻り値をそのまま使わず、<code>null</code> のときはログイン画面へ送るなどの分岐を必ず書きます。
      </li>
      <li>
        <strong>application に利用者ごとの情報を入れてしまう</strong>：
        「ログイン中のユーザ」を <code>ServletContext</code> に入れると、
        <strong>あとからログインした人で全員分が上書き</strong>されます。
        このサンプルの application の表に、自分が入れていない値が並んでいるのがその証拠です。
      </li>
      <li>
        <strong>属性名がぶつかる</strong>：
        <code>"user"</code> や <code>"list"</code> のような一般的な名前は、
        他の画面やライブラリと衝突します。とくに application は 1 つしかないので、
        このサンプルのように接頭辞を付けておくと安全です。
      </li>
      <li>
        <strong>スコープに入れたまま消し忘れる</strong>：
        session / application は<strong>自動では減りません</strong>。
        入れる件数や大きさに上限を決めておくと、後から困りません
        （このサンプルは application を <code>10</code> 件・値 <code>50</code> 文字までにしています）。
      </li>
      <li>
        <strong>再起動したら全部消えた</strong>：
        スコープはサーバのメモリ（または退避先）にあるだけで、保存領域ではありません。
        残す必要があるものは DB やファイルに書きます。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // 消す操作は取り消せないので、送信前に確認する
      // (data-confirm 属性にメッセージを書いておき、submit をまとめて拾う)
      $(function () {
        $('form[data-confirm]').on('submit', function () {
          return window.confirm($(this).data('confirm'));
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ============================================================
         画面上部のお知らせ
         forward で戻ってきたとき : Servlet が request スコープに入れた値
         リダイレクトで戻ってきたとき : Flash (セッション) から移し替えた値
         ============================================================ --%>
    <c:if test="${not empty noticeText}">
      <div class="alert alert-${noticeVariant}" role="alert">
        <strong>${fn:escapeXml(noticeTitle)}</strong><br>
        ${fn:escapeXml(noticeText)}
      </div>
    </c:if>

    <%-- ============================================================
         ① 値を入れる
         ============================================================ --%>
    <t:panel title="① 3 つのスコープに値を入れてみる"
             note="同じ名前と値でも、入れる場所で残り方が変わります">
      <form action="${scopeUrl}" method="post">
        <div class="form-group mb-2">
          <span class="d-block mb-1">どのスコープに入れますか？</span>
          <div class="custom-control custom-radio custom-control-inline">
            <input type="radio" class="custom-control-input" id="scopeRequest" name="scope" value="request"
                   ${selectedScope eq 'request' ? 'checked' : ''}>
            <label class="custom-control-label" for="scopeRequest">
              request <span class="text-muted small">（この画面だけ）</span>
            </label>
          </div>
          <div class="custom-control custom-radio custom-control-inline">
            <input type="radio" class="custom-control-input" id="scopeSession" name="scope" value="session"
                   ${selectedScope eq 'session' ? 'checked' : ''}>
            <label class="custom-control-label" for="scopeSession">
              session <span class="text-muted small">（このブラウザだけ）</span>
            </label>
          </div>
          <div class="custom-control custom-radio custom-control-inline">
            <input type="radio" class="custom-control-input" id="scopeApplication" name="scope" value="application"
                   ${selectedScope eq 'application' ? 'checked' : ''}>
            <label class="custom-control-label" for="scopeApplication">
              application <span class="text-danger small">（全員に見えます）</span>
            </label>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group col-md-4">
            <label for="entryName">名前（属性名）</label>
            <input type="text" class="form-control" id="entryName" name="name"
                   value="${fn:escapeXml(inputName)}" maxlength="${nameMaxLength}" placeholder="例: memo">
            <small class="form-text text-muted">
              半角英数字・ハイフン・アンダースコアで ${nameMaxLength} 文字まで。
              実際には <code>scopeSample.entry.</code> を付けた名前で入れています。
            </small>
          </div>
          <div class="form-group col-md-8">
            <label for="entryValue">値</label>
            <input type="text" class="form-control" id="entryValue" name="value"
                   value="${fn:escapeXml(inputValue)}" maxlength="${valueMaxLength}"
                   placeholder="例: あとで消す">
            <small class="form-text text-muted">${valueMaxLength} 文字まで。</small>
          </div>
        </div>

        <button type="submit" class="btn btn-primary">入れる</button>
      </form>

      <div class="alert alert-warning small mt-3 mb-0">
        <strong>application は全利用者で共有されます。</strong>
        入れた値は<strong>このサイトを見ている人全員に見えます</strong>。
        個人情報や見られて困る言葉は入れないでください。
        （公開デモなので ${appMaxEntries} 件・${valueMaxLength} 文字までに制限しています）
      </div>
    </t:panel>

    <%-- ============================================================
         ② いまの中身
         ============================================================ --%>
    <t:panel title="② いまの各スコープの中身"
             note="このサンプルが入れた scopeSample.entry.〜 だけを並べています">

      <h6 class="mt-1">
        request スコープ
        <span class="badge badge-secondary">この画面を組み立てた 1 リクエストの間だけ</span>
      </h6>
      <c:choose>
        <c:when test="${empty requestEntries}">
          <p class="text-muted small">（空です。request に値を入れると、その直後の表示にだけ現れます）</p>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered">
              <thead>
                <tr><th class="w-25">名前</th><th>値</th><th class="w-50">JSP での取り出し方</th></tr>
              </thead>
              <tbody>
                <c:forEach var="entry" items="${requestEntries}">
                  <tr>
                    <td><code>${fn:escapeXml(entry.name)}</code></td>
                    <td>${fn:escapeXml(entry.value)}</td>
                    <td><code class="small">${fn:escapeXml(entry.el)}</code></td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>

      <h6 class="mt-4">
        session スコープ
        <span class="badge badge-info">このブラウザの間（${sessionTimeoutMinutes} 分で時間切れ）</span>
      </h6>
      <c:choose>
        <c:when test="${empty sessionEntries}">
          <p class="text-muted small">（空です）</p>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered">
              <thead>
                <tr><th class="w-25">名前</th><th>値</th><th class="w-50">JSP での取り出し方</th></tr>
              </thead>
              <tbody>
                <c:forEach var="entry" items="${sessionEntries}">
                  <tr>
                    <td><code>${fn:escapeXml(entry.name)}</code></td>
                    <td>${fn:escapeXml(entry.value)}</td>
                    <td><code class="small">${fn:escapeXml(entry.el)}</code></td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>

      <h6 class="mt-4">
        application スコープ
        <span class="badge badge-danger">アプリが動いている間ずっと・全員で共有</span>
      </h6>
      <c:choose>
        <c:when test="${empty applicationEntries}">
          <p class="text-muted small">（空です）</p>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered">
              <thead>
                <tr><th class="w-25">名前</th><th>値</th><th class="w-50">JSP での取り出し方</th></tr>
              </thead>
              <tbody>
                <c:forEach var="entry" items="${applicationEntries}">
                  <tr>
                    <td><code>${fn:escapeXml(entry.name)}</code></td>
                    <td>${fn:escapeXml(entry.value)}</td>
                    <td><code class="small">${fn:escapeXml(entry.el)}</code></td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <p class="text-muted small">
            自分が入れた覚えのない行が並んでいるかもしれません。
            それが「全員で 1 つを共有している」ということです（いま ${fn:length(applicationEntries)} 件 / ${appMaxEntries} 件）。
          </p>
        </c:otherwise>
      </c:choose>

      <hr>
      <a class="btn btn-outline-secondary" href="${scopeUrl}">もう一度開く（GET し直す）</a>
      <p class="text-muted small mt-2 mb-0">
        押すと新しいリクエストになるので、<strong>request の行だけが消えます</strong>。
        session と application はそのまま残ります。
      </p>
    </t:panel>

    <%-- ============================================================
         ③ 探索順 (同じ名前を複数のスコープに入れる)
         ============================================================ --%>
    <t:panel title="③ 同じ名前を複数のスコープに入れたら？"
             note="EL でスコープを省略したときに、どれが選ばれるかを見ます">
      <p>
        <code>scopeDemoValue</code> という同じ名前で、いくつかのスコープに値を入れてみてください。
        いちばん下の行が「スコープを省略した <code>${'${scopeDemoValue}'}</code>」の結果です。
      </p>

      <div class="mb-3">
        <form class="d-inline-block mr-1 mb-1" action="${scopeUrl}" method="post">
          <input type="hidden" name="action" value="put-demo">
          <input type="hidden" name="scope" value="request">
          <button type="submit" class="btn btn-sm btn-outline-primary">request に入れる</button>
        </form>
        <form class="d-inline-block mr-1 mb-1" action="${scopeUrl}" method="post">
          <input type="hidden" name="action" value="put-demo">
          <input type="hidden" name="scope" value="session">
          <button type="submit" class="btn btn-sm btn-outline-primary">session に入れる</button>
        </form>
        <form class="d-inline-block mr-1 mb-1" action="${scopeUrl}" method="post">
          <input type="hidden" name="action" value="put-demo">
          <input type="hidden" name="scope" value="application">
          <button type="submit" class="btn btn-sm btn-outline-primary">application に入れる</button>
        </form>
        <a class="btn btn-sm btn-outline-primary mr-1 mb-1" href="${scopeUrl}?withPage=1">page に入れる</a>
        <form class="d-inline-block mb-1" action="${scopeUrl}" method="post">
          <input type="hidden" name="action" value="clear-demo">
          <button type="submit" class="btn btn-sm btn-outline-secondary">session / application から消す</button>
        </form>
      </div>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書き方</th><th>表示される値</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>${'${pageScope.scopeDemoValue}'}</code></td>
              <td>
                <c:choose>
                  <c:when test="${empty pageScope.scopeDemoValue}"><span class="text-muted">（未設定）</span></c:when>
                  <c:otherwise>${fn:escapeXml(pageScope.scopeDemoValue)}</c:otherwise>
                </c:choose>
              </td>
            </tr>
            <tr>
              <td><code>${'${requestScope.scopeDemoValue}'}</code></td>
              <td>
                <c:choose>
                  <c:when test="${empty requestScope.scopeDemoValue}"><span class="text-muted">（未設定）</span></c:when>
                  <c:otherwise>${fn:escapeXml(requestScope.scopeDemoValue)}</c:otherwise>
                </c:choose>
              </td>
            </tr>
            <tr>
              <td><code>${'${sessionScope.scopeDemoValue}'}</code></td>
              <td>
                <c:choose>
                  <c:when test="${empty sessionScope.scopeDemoValue}"><span class="text-muted">（未設定）</span></c:when>
                  <c:otherwise>${fn:escapeXml(sessionScope.scopeDemoValue)}</c:otherwise>
                </c:choose>
              </td>
            </tr>
            <tr>
              <td><code>${'${applicationScope.scopeDemoValue}'}</code></td>
              <td>
                <c:choose>
                  <c:when test="${empty applicationScope.scopeDemoValue}"><span class="text-muted">（未設定）</span></c:when>
                  <c:otherwise>${fn:escapeXml(applicationScope.scopeDemoValue)}</c:otherwise>
                </c:choose>
              </td>
            </tr>
            <tr class="table-primary">
              <td><code>${'${scopeDemoValue}'}</code><span class="d-block text-muted small">スコープを省略した書き方</span></td>
              <td>
                <c:choose>
                  <c:when test="${empty scopeDemoValue}"><span class="text-muted">（どこにもありません）</span></c:when>
                  <c:otherwise><strong>${fn:escapeXml(scopeDemoValue)}</strong></c:otherwise>
                </c:choose>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-2 mb-0">
        探す順番は <strong>page → request → session → application</strong> です。
        「page に入れる」は <code>?withPage=1</code> を付けて開き直しているだけなので、
        リンクを押さずに開き直すと消えます（page スコープはその 1 回の表示だけの入れ物です）。
      </p>
    </t:panel>

    <%-- ============================================================
         ④ セッションの情報と、消す操作
         ============================================================ --%>
    <t:panel title="④ セッションの情報" note="いま使っているセッションの様子">
      <div class="table-responsive">
        <table class="table table-sm table-bordered">
          <tbody>
            <tr>
              <th scope="row" class="w-25">セッション ID</th>
              <td>
                <code>${fn:escapeXml(sessionId)}</code>
                <span class="d-block text-muted small mt-1">
                  Cookie の <code>JSESSIONID</code> と同じ値です。
                  なりすましに使われるため、全体は表示していません
                  （実際の画面にも出さないでください）。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">この表示で作られたセッションか</th>
              <td>${sessionNew ? 'はい（いま作られました）' : 'いいえ（前からあるものです）'}</td>
            </tr>
            <tr>
              <th scope="row">作られた時刻</th>
              <td><code>${fn:escapeXml(sessionCreatedText)}</code></td>
            </tr>
            <tr>
              <th scope="row">最終アクセス時刻</th>
              <td>
                <code>${fn:escapeXml(sessionLastAccessedText)}</code>
                <span class="d-block text-muted small mt-1">
                  <code>getLastAccessedTime()</code> が返すのは<strong>1 つ前のリクエスト</strong>の時刻です
                  （いま表示しているリクエストの時刻ではありません）。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">タイムアウト</th>
              <td>
                ${sessionTimeoutMinutes} 分（<code>web.xml</code> の
                <code>&lt;session-timeout&gt;</code> で決めています）
                <span class="d-block text-muted small mt-1">
                  このまま操作しなければ <code>${fn:escapeXml(sessionExpiresText)}</code> ごろに切れます。
                  切れたあとに開くと、新しいセッションになって session の行が空になります。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">この画面を開いた回数</th>
              <td>
                あなた: <strong>${sessionViewCount}</strong> 回（session スコープで数えています）<br>
                全員: <strong>${applicationViewCount}</strong> 回（application スコープの
                <code>AtomicLong</code> で数えています）
                <span class="d-block text-muted small mt-1">
                  同じ数え方でも、置き場所を変えるだけで「自分の回数」と「全員の回数」に変わります。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">サーバの現在時刻</th>
              <td><code>${fn:escapeXml(nowText)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>

      <form class="d-inline-block mr-2" action="${scopeUrl}" method="post"
            data-confirm="セッションを破棄します。session スコープの値は消えます。よろしいですか？">
        <input type="hidden" name="action" value="invalidate">
        <button type="submit" class="btn btn-outline-danger">
          セッションを破棄する（invalidate）
        </button>
      </form>
      <form class="d-inline-block" action="${scopeUrl}" method="post"
            data-confirm="application スコープの値を全部消します。ほかの利用者にも影響します。よろしいですか？">
        <input type="hidden" name="action" value="clear-application">
        <button type="submit" class="btn btn-outline-warning">
          application の値を全部消す
        </button>
      </form>

      <p class="text-muted small mt-3 mb-0">
        「セッションを破棄する」を押すと session の行が消え、セッション ID も変わります
        （完了メッセージを預けるために、すぐ新しいセッションが作られるためです）。
        application の値はサーバに残ったままであることも確かめてみてください。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
