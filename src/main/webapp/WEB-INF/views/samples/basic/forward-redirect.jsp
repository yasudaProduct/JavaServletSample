<%--
  【サンプル】forward と redirect の違い

  同じ「注文を受け付ける」処理を、遷移のしかただけ変えて 2 通り試せます。

    forward  : POST → サーバの中で JSP へ処理を渡す   … URL は変わらない / スコープは残る
    redirect : POST → 302 を返し、ブラウザが改めて GET … URL が変わる   / スコープは消える

  ForwardRedirectServlet が POST を受け、遷移先の画面は
  forward-redirect-goal.jsp (t:layout で作った普通の画面) です。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="forward-redirect">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>一言でいうと</h2>
    <ul>
      <li>
        <strong>forward はサーバの中で処理を渡すだけ</strong>です。
        ブラウザから見ると「1 回リクエストしたら HTML が返ってきた」だけで、
        中で別の JSP に渡されたことは<strong>知りません</strong>。
      </li>
      <li>
        <strong>redirect はブラウザに再リクエストさせる</strong>仕組みです。
        サーバは「この URL をもう一度取りに行ってください」という返事
        (ステータス 302 と <code>Location</code> ヘッダ) だけを返し、
        画面を作るのは<strong>次のリクエスト</strong>です。
      </li>
    </ul>

<pre><code class="language-plaintext">■ forward (通信は 1 往復)
  ブラウザ ──POST /samples/basic/forward-redirect──▶ Servlet
                                                      │ サーバの中で処理を渡す
                                                      ▼
  ブラウザ ◀────────── HTML ──────────────────────── JSP
  アドレスバー : /samples/basic/forward-redirect のまま

■ redirect (通信は 2 往復)
  ブラウザ ──POST /samples/basic/forward-redirect──▶ Servlet
  ブラウザ ◀── 302 Location: .../forward-redirect/goal ──┘   ← ここで 1 回目が終わる
  ブラウザ ──GET  /samples/basic/forward-redirect/goal──▶ Servlet ─▶ JSP
  ブラウザ ◀────────── HTML ─────────────────────────────┘
  アドレスバー : /samples/basic/forward-redirect/goal に変わる</code></pre>

    <h2>処理の流れ</h2>
    <h3>forward 版</h3>
    <ol>
      <li>ブラウザが <code>/samples/basic/forward-redirect</code> へ POST する</li>
      <li><code>ForwardRedirectServlet#doPost</code> が受付番号を作る</li>
      <li><code>request.setAttribute("receiptNumber", ...)</code> でリクエストスコープに入れる</li>
      <li><code>forward</code> で <code>forward-redirect-goal.jsp</code> に処理を渡す</li>
      <li>JSP が <code>${'${receiptNumber}'}</code> を取り出して画面を作る（<strong>値は残っている</strong>）</li>
    </ol>
    <h3>redirect 版</h3>
    <ol>
      <li>ブラウザが <code>/samples/basic/forward-redirect</code> へ POST する（ここまで同じ）</li>
      <li>Servlet が受付番号を作り、同じように <code>setAttribute</code> する</li>
      <li><code>response.sendRedirect(...)</code> で 302 を返す。<strong>1 回目のリクエストはここで終わり</strong></li>
      <li>ブラウザが <code>/samples/basic/forward-redirect/goal</code> を GET する（<strong>別のリクエスト</strong>）</li>
      <li><code>ForwardRedirectGoalServlet#doGet</code> が同じ JSP へ forward する</li>
      <li>JSP から見ると <code>${'${receiptNumber}'}</code> は空。受付番号は <code>${'${param.receipt}'}</code> から取る</li>
    </ol>

    <h2>コードの違い</h2>
<pre><code class="language-java">// forward : 同じリクエストのまま、アプリの中の別の資源へ処理を渡す
request.setAttribute("receiptNumber", receiptNumber);
request.getRequestDispatcher("/WEB-INF/views/samples/basic/forward-redirect-goal.jsp")
       .forward(request, response);

// redirect : ブラウザに再リクエストさせる (302 + Location)
response.sendRedirect(request.getContextPath() + "/samples/basic/forward-redirect/goal");
return;   // ← 忘れずに</code></pre>
    <p>
      このサンプル集では <code>forward</code> を <code>common/BaseServlet.java</code> に
      まとめているので、Servlet からは <code>forward(request, response, "/WEB-INF/views/...")</code>
      と書いています。やっていることは上のコードと同じです。
    </p>

    <h2>URL・スコープ・履歴・再読み込み</h2>

    <h3>URL（アドレスバー）</h3>
    <p>
      forward はブラウザにとって「1 回のリクエスト」のままなので、
      アドレスバーは POST した URL から<strong>変わりません</strong>。
      画面の中身は遷移先の JSP なのに URL は入力画面のまま、というずれが起きます。
      redirect はブラウザが新しい URL を取りに行くので、アドレスバーは遷移先に変わります。
    </p>
    <p>
      なお forward したあとの <code>request.getRequestURI()</code> は<strong>転送先</strong>
      （<code>/WEB-INF/views/...jsp</code>）を返します。
      ブラウザが要求した元の URL は <code>javax.servlet.forward.request_uri</code> で取れます。
    </p>
<pre><code class="language-xml">&lt;%-- ブラウザが要求した URL。forward されていなければ getRequestURI() がそのまま元の URL --%&gt;
&lt;c:set var="forwardUri" value="${'${requestScope["javax.servlet.forward.request_uri"]}'}" /&gt;
&lt;c:set var="browserUri" value="${'${empty forwardUri ? pageContext.request.requestURI : forwardUri}'}" /&gt;
&lt;code&gt;${'${fn:escapeXml(browserUri)}'}&lt;/code&gt;</code></pre>

    <h3>リクエストスコープ</h3>
    <p>
      <code>request.setAttribute</code> で入れた値が生きているのは<strong>その 1 リクエストの間だけ</strong>です。
      forward は同じリクエストが続いているので値はそのまま届きますが、
      redirect は別のリクエストになるため<strong>きれいに消えます</strong>。
      引き継ぎたいときは次のどちらかを使います。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>渡し方</th><th>書き方</th><th>向いている値</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>クエリ文字列</td>
            <td><code>?receipt=R-0001</code>（<code>URLEncoder.encode</code> を通す）</td>
            <td>受付番号・ID など、URL に出てもよい短い値</td>
          </tr>
          <tr>
            <td>セッション</td>
            <td><code>common/Flash.java</code>（1 回表示したら消す）</td>
            <td>完了メッセージなど、URL に出したくない値</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      このサンプルの redirect 版はクエリ文字列を使っています。
      完了メッセージをセッション経由で渡す形は
      <a href="${ctx}/samples/design/modal-dialog">モーダルの出し方</a> にあります。
    </p>

    <h3>ブラウザの履歴と「戻る」</h3>
    <p>
      どちらでも「戻る」で行き着く先は、フォームを送信する前の入力画面です。
      違うのは<strong>履歴に何が残るか</strong>です。
    </p>
    <ul>
      <li>
        <strong>forward</strong>：ブラウザは転送に気付かないので、履歴に残るのは
        <strong>POST したときの URL</strong>（入力画面と同じ URL）です。
        完了画面のまま再読み込みしたり、「戻る」のあとに「進む」で戻ってきたりすると、
        ブラウザは POST をやり直そうとして再送信の確認を出します。
      </li>
      <li>
        <strong>redirect</strong>：302 を受け取ったブラウザは、POST の履歴を
        遷移先の <strong>GET で置き換えます</strong>。履歴に POST が残らないので、
        再読み込みしても「進む」で戻ってきても再送信の確認は出ません。
      </li>
    </ul>

    <h3>再読み込み（F5）</h3>
    <p>
      ここが実務でいちばん効いてきます。forward のままだと、完了画面の URL は
      <strong>POST した URL</strong>です。再読み込みするとブラウザは同じ POST を送ろうとし、
      「フォームを再送信しますか？」と聞いてきます。うっかり「はい」を押すと
      <strong>もう一度注文が入ります</strong>。
      redirect したあとは GET なので、何度再読み込みしても画面が作り直されるだけです。
    </p>

    <h2>PRG パターン（登録のあとは redirect）</h2>
    <p>
      そこで、<strong>状態を変える処理は「POST → Redirect → GET」の順にする</strong>のが定番です。
      頭文字をとって PRG パターンと呼びます。
    </p>
<pre><code class="language-plaintext">［登録する］ ──POST──▶ 登録処理 ──302──▶ ブラウザ ──GET──▶ 完了画面
                                                          （再読み込みしても GET が繰り返されるだけ）</code></pre>
    <ul>
      <li><strong>登録・更新・削除のあと</strong>は redirect。二重送信を防げます</li>
      <li>
        <strong>入力エラーで入力画面に戻すとき</strong>は forward。
        redirect すると入力値もエラーメッセージも消えてしまうので、
        同じリクエストのまま入力画面へ forward して、入力値をそのまま表示します
      </li>
      <li><strong>ただの表示（GET）</strong>はどちらでも構いませんが、Servlet → JSP は forward が普通です</li>
    </ul>

    <h2>sendRedirect のパスの組み立て方</h2>
    <p>
      <code>sendRedirect</code> に渡すパスは<strong>ブラウザが使う URL</strong>です。
      アプリの中のパス（<code>/WEB-INF/views/...</code>）ではないので、
      かならず <code>getContextPath()</code> から組み立てます。
    </p>
<pre><code class="language-java">// ○ コンテキストパスから組み立てる
response.sendRedirect(request.getContextPath() + "/samples/basic/forward-redirect/goal");

// × サーバのルート直下を指してしまう (/app/... で配備すると 404)
response.sendRedirect("/samples/basic/forward-redirect/goal");

// 値を載せるときは URL エンコードする (日本語や &amp; がそのままだと壊れる)
String url = request.getContextPath() + "/samples/basic/forward-redirect/goal"
        + "?receipt=" + URLEncoder.encode(receiptNumber, StandardCharsets.UTF_8)
        + "&amp;name=" + URLEncoder.encode(name, StandardCharsets.UTF_8);
response.sendRedirect(url);</code></pre>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>レスポンスを送信し始めたあとの forward / sendRedirect は
        <code>IllegalStateException</code></strong>：
        遷移できるのは、レスポンスが<strong>まだコミットされていない</strong>間だけです。
        少し書いただけならバッファに溜まっているだけなので、
        バッファを捨てて遷移できます（このリポジトリの JSP は <code>web.xml</code> で
        64kb、Servlet は Tomcat の既定で 8kb 程度）。
        バッファを超える量を書き出した、<code>response.flushBuffer()</code> を呼んだ、
        といったタイミングでブラウザへの送信が始まり、
        そこから先はヘッダを付け替えられないため例外になります。
<pre><code class="language-java">response.getWriter().println("処理中です");   // まだバッファの中。ここなら遷移できる
response.flushBuffer();                        // ← ここで送信が始まる (コミット)
response.sendRedirect(url);                    // IllegalStateException</code></pre>
        出力の多い JSP の途中で <code>&lt;jsp:forward&gt;</code> すると、
        それまでの HTML がバッファを超えていてこの例外が出ます。
        「画面に出すか、遷移するか」はどちらか一方に決めてください。
      </li>
      <li>
        <strong><code>sendRedirect</code> のあとに <code>return</code> を書き忘れる</strong>：
        <code>sendRedirect</code> はそこで処理を止めてくれません。
        後ろに書いた <code>forward</code> まで実行され、結局
        <code>IllegalStateException</code> になります。
        <code>forward</code> のあとも同じで、続けて書き込まないようにします。
      </li>
      <li>
        <strong>redirect したら値が消えた</strong>：
        <code>request.setAttribute</code> はリクエストをまたげません。
        「forward のつもりで redirect していた」「PRG にした途端エラーメッセージが出なくなった」
        はこれが原因です。クエリ文字列かセッションに載せ替えてください。
      </li>
      <li>
        <strong><code>/WEB-INF/</code> の JSP には redirect できない</strong>：
        <code>/WEB-INF/</code> 配下はブラウザから直接アクセスできない場所です。
        redirect はブラウザに取りに行かせるので 404 になります。
        JSP を直接指せるのは forward だけです。
      </li>
      <li>
        <strong><code>sendRedirect</code> が返すのは 302</strong>：
        「次は GET で取りに行く」と仕様で決まっているのは 303 See Other のほうで、
        302 は本来メソッドを変えないことになっています。
        実際のブラウザはどれも 302 でも GET に変えるので PRG は成立しますが、
        意図をはっきりさせたいときは <code>response.setStatus(303)</code> と
        <code>response.setHeader("Location", url)</code> を使います。
      </li>
      <li>
        <strong>遷移先を利用者から受け取らない</strong>：
        <code>?next=...</code> のように<strong>画面から渡された URL</strong> へそのまま
        <code>sendRedirect</code> すると、外部サイトへ誘導する踏み台になります
        （オープンリダイレクト）。遷移先はサーバ側で決めるか、
        許可する値を一覧で持っておきます。
      </li>
      <li>
        <strong>POST の文字化け</strong>：
        日本語を POST で受け取るときは、パラメータを読む<strong>前</strong>に
        <code>request.setCharacterEncoding("UTF-8")</code> を呼びます
        （このリポジトリでは <code>web.xml</code> の設定で済ませています）。
        クエリ文字列に日本語を載せるときは <code>URLEncoder</code> を通します。
      </li>
      <li>
        <strong>forward 先で <code>getRequestURI()</code> が違う値を返す</strong>：
        forward したあとは転送先（<code>/WEB-INF/views/...jsp</code>）が返ります。
        ログに「ブラウザが叩いた URL」を残したいときは
        <code>javax.servlet.forward.request_uri</code> を見てください。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:panel title="同じ処理を forward と redirect で実行する"
             note="どちらも POST で受け、受付番号をリクエストスコープに入れてから遷移します">
      <p>
        ボタンを押すと注文を受け付けて、遷移先の画面
        （<code>/samples/basic/forward-redirect/goal</code> と、forward 用の遷移先 JSP）へ進みます。
        受付処理の中身はまったく同じで、<strong>最後の 1 行だけ</strong>が違います。
      </p>

      <form action="${ctx}/samples/basic/forward-redirect" method="post" class="form-inline">
        <label class="mr-2" for="orderName">お名前</label>
        <input type="text" class="form-control mr-3" id="orderName" name="name"
               placeholder="例: 山田太郎" size="20" maxlength="20">
        <%-- 送信ボタンを 2 つ置き、押されたボタンの name=value で処理を分けている --%>
        <button type="submit" class="btn btn-primary mr-2" name="mode" value="forward">
          forward で受け付ける
        </button>
        <button type="submit" class="btn btn-outline-primary" name="mode" value="redirect">
          redirect で受け付ける
        </button>
      </form>

      <div class="alert alert-info mt-3 mb-0">
        <p class="mb-2"><strong>遷移先で見てほしいところ</strong></p>
        <ol class="mb-0 pl-4">
          <li><strong>アドレスバーの URL</strong> … forward は変わらない / redirect は <code>/goal</code> に変わる</li>
          <li><strong>リクエストスコープの受付番号</strong> … forward は残る / redirect は消える</li>
          <li><strong>再読み込み（F5）</strong> … forward は「再送信しますか？」が出る / redirect は何も聞かれない</li>
          <li><strong>「戻る」→「進む」</strong> … forward は再送信を聞かれる / redirect は何も聞かれない</li>
        </ol>
      </div>
    </t:panel>

    <t:panel title="forward と redirect の違い" note="遷移先の画面と見比べてください">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th scope="col" class="w-25">見るところ</th>
              <th scope="col">forward</th>
              <th scope="col">redirect</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">やっていること</th>
              <td>サーバの中で次の資源へ処理を渡す</td>
              <td>ブラウザに「この URL をもう一度取りに行って」と返す</td>
            </tr>
            <tr>
              <th scope="row">書き方</th>
              <td><code>request.getRequestDispatcher(パス).forward(req, res)</code></td>
              <td><code>response.sendRedirect(getContextPath() + パス)</code></td>
            </tr>
            <tr>
              <th scope="row">ブラウザとの通信</th>
              <td>1 往復（ブラウザは転送に気付かない）</td>
              <td>2 往復（302 応答 → 改めてリクエスト）</td>
            </tr>
            <tr>
              <th scope="row">アドレスバーの URL</th>
              <td>POST した URL のまま<br>
                <code>/samples/basic/forward-redirect</code></td>
              <td>遷移先の URL に変わる<br>
                <code>/samples/basic/forward-redirect/goal</code></td>
            </tr>
            <tr>
              <th scope="row">HTTP メソッド</th>
              <td>POST のまま</td>
              <td>GET になる</td>
            </tr>
            <tr class="table-warning">
              <th scope="row">リクエストスコープ<br>
                <code class="small">request.setAttribute</code></th>
              <td>そのまま引き継がれる</td>
              <td>消える（別のリクエストになるため）</td>
            </tr>
            <tr>
              <th scope="row">ブラウザの履歴に残るもの</th>
              <td>POST した URL（転送先は残らない）</td>
              <td>遷移先の GET（POST の履歴が置き換わる）</td>
            </tr>
            <tr>
              <th scope="row">再読み込み（F5）</th>
              <td>「再送信しますか？」が出る＝二重登録の危険</td>
              <td>GET が繰り返されるだけで安全</td>
            </tr>
            <tr>
              <th scope="row">遷移先に指定できるもの</th>
              <td>同じアプリの中だけ。<code>/WEB-INF/</code> の JSP も指せる</td>
              <td>ブラウザが開ける URL なら他サイトでも可。<br>
                <code>/WEB-INF/</code> は 404 になる</td>
            </tr>
            <tr>
              <th scope="row">向いている場面</th>
              <td>Servlet から JSP へ画面を渡す／<br>
                入力エラーで入力画面に戻す（入力値を残せる）</td>
              <td>登録・更新・削除のあと（PRG パターン）</td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="この画面自身も forward で表示されています"
             note="Servlet → JSP は forward。そのときリクエストの見え方がどうなるか">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" class="w-25">ブラウザが要求した URL</th>
              <td>
                <code>${fn:escapeXml(empty requestScope['javax.servlet.forward.request_uri']
                        ? pageContext.request.requestURI
                        : requestScope['javax.servlet.forward.request_uri'])}</code>
                <span class="d-block text-muted small mt-1">
                  forward されているときは <code>javax.servlet.forward.request_uri</code> に入っています。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">いま実行中の JSP</th>
              <td>
                <code>${fn:escapeXml(pageContext.request.requestURI)}</code>
                <span class="d-block text-muted small mt-1">
                  <code>getRequestURI()</code> は forward 先を返すので、上の URL とは違う値になります。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">HTTP メソッド</th>
              <td><code>${fn:escapeXml(pageContext.request.method)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>
  </jsp:body>
</t:sample>
