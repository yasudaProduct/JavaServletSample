<%--
  【サンプル】ログインとログアウト

  LoginServlet が次の値をセットします。
    accounts      … デモ用の利用者マスタ
    loginError    … 失敗したときのメッセージ
    inputLoginId  … 入力されたログイン ID（入力し直し用。パスワードは戻さない）
    next          … ログイン後に戻る画面（安全と判断できたものだけ）
    flash         … ログイン / ログアウトの完了メッセージ

  セッションには LoginUser が "loginUser" という名前で入るので、
  EL からは ${loginUser} で参照できます（page → request → session → application の順に探されます）。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="loginUrl" value="${ctx}/samples/session/login" />
<c:set var="logoutUrl" value="${ctx}/samples/session/login/logout" />
<c:set var="sessionIdBefore" value="${sessionScope['loginSample.sessionIdBefore']}" />
<c:set var="loggedInAt" value="${sessionScope['loginSample.loggedInAt']}" />
<t:sample sampleId="login">

  <jsp:attribute name="explanation">
    <h2>ログインの仕組みは「印を置いて、次に確かめる」だけ</h2>
    <p>
      HTTP は 1 回のやり取りごとに関係が切れる（ステートレスな）約束事なので、
      サーバは「さっきの人」を自力では覚えていません。
      そこでサーバは <code>JSESSIONID</code> という<strong>整理券</strong>を Cookie で渡し、
      その整理券にひもづくサーバ側の入れ物（セッション）に
      「この人はログイン済み」という印を置きます。
    </p>
<pre><code class="language-plaintext">① POST /login          ID とパスワードを送る
② 照合する              マスタのハッシュと突き合わせる
③ セッション ID を振り直す  ← セッション固定攻撃への対策
④ セッションに印を置く     session.setAttribute("loginUser", user)
⑤ リダイレクト           PRG。再読み込みで再ログインされないように</code></pre>
    <p>
      以降のリクエストでは、セッションに印があるかどうかを見るだけです。
      それを画面ごとに書くと漏れるので、<strong>フィルタにまとめます</strong>
      （次のサンプル「フィルタで未ログインを弾く」）。
    </p>

    <h2>パスワードの保存</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>保存の仕方</th><th>評価</th><th>理由</th></tr></thead>
        <tbody>
          <tr>
            <td>平文のまま</td>
            <td><span class="badge badge-danger">論外</span></td>
            <td>DB を覗かれた時点で全員分が漏れます</td>
          </tr>
          <tr>
            <td>暗号化する</td>
            <td><span class="badge badge-danger">駄目</span></td>
            <td>鍵があれば戻せます。鍵も一緒に盗まれます</td>
          </tr>
          <tr>
            <td>ただの SHA-256</td>
            <td><span class="badge badge-warning">不足</span></td>
            <td>速すぎて総当たりが効きます。同じパスワードが同じ値になります</td>
          </tr>
          <tr>
            <td>ソルト＋反復つきのハッシュ</td>
            <td><span class="badge badge-success">これ</span></td>
            <td>PBKDF2 / bcrypt / scrypt / Argon2</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>必要な工夫は 3 つです。</p>
    <ul>
      <li>
        <strong>ソルト</strong> … 利用者ごとに違うランダムな値を混ぜる。
        同じパスワードの人が同じハッシュにならなくなり、
        あらかじめ計算した対応表（レインボーテーブル）が効かなくなります
      </li>
      <li>
        <strong>反復</strong> … 何万回も繰り返して<strong>わざと遅くする</strong>。
        正規の利用者は 1 回だけなので気にならず、総当たりを狙う側だけが困ります
      </li>
      <li>
        <strong>一定時間での比較</strong> … <code>equals</code> で 1 文字ずつ早期に打ち切ると、
        応答時間の差から「何文字目まで合っているか」が漏れます
        （<code>MessageDigest.isEqual</code> を使います）
      </li>
    </ul>
    <p>
      このサンプルは JDK だけで完結させるため <strong>PBKDF2</strong> を使っています。
      実務では <strong>bcrypt / Argon2</strong> が推奨されます
      （計算にメモリも使うので、GPU での総当たりに強い）。
    </p>

    <h2>セッション固定攻撃と、ID の振り直し</h2>
    <p>
      攻撃者があらかじめ用意したセッション ID を利用者に使わせ、
      その利用者がログインしたあとに<strong>同じ ID で入り込む</strong>攻撃があります。
    </p>
<pre><code class="language-plaintext">［対策しない場合］
  攻撃者 : 自分が知っている JSESSIONID=ABC を利用者に使わせる
  利用者 : そのままログイン           → ABC が「ログイン済み」になる
  攻撃者 : JSESSIONID=ABC でアクセス  → 利用者になりすませてしまう

［対策する場合］
  利用者 : ログイン成功 → ID を ABC から XYZ へ振り直す
  攻撃者 : ABC でアクセス            → もう誰でもない</code></pre>
<pre><code class="language-java">// Servlet 3.1 以降。入れてあった値は残る
request.changeSessionId();

// 昔ながらのやり方。値は消えるので、必要なら自分で移し替える
session.invalidate();
session = request.getSession(true);</code></pre>

    <h2>ログアウトは POST で、セッションごと捨てる</h2>
    <p>
      ログアウトを GET で受けると、攻撃者のページに次の 1 行を置くだけで
      <strong>勝手にログアウトさせられます</strong>。
    </p>
<pre><code class="language-xml">&lt;img src="https://example.com/logout" width="1" height="1"&gt;</code></pre>
    <p>
      実害はログアウトだけとはいえ、<strong>状態を変える処理を GET で受けない</strong>という
      原則そのものは、退会・削除・送金でも同じです。
      このサンプルの <code>LogoutServlet</code> は <code>doPost</code> しか実装していないので、
      GET で開くと 405 が返ります。
    </p>
<pre><code class="language-java">// ログアウト : セッションごと捨てる
session.invalidate();

// 【不十分】 これだけではカートや検索条件が残る
session.removeAttribute("loginUser");</code></pre>

    <h2>失敗したときに何を伝えるか</h2>
    <p>
      「ID が存在しません」と「パスワードが違います」を<strong>区別して伝えてはいけません</strong>。
      攻撃者に「この ID は実在する」と教えることになります（アカウント列挙）。
      どちらの場合も同じ文言を返します。
    </p>
    <p>
      応答時間にも気を配ります。ID が無いときだけ照合をせずにすぐ返すと、
      <strong>速さの違いから ID の実在が分かります</strong>。
      このサンプルでは、ID が見つからない場合もダミーのハッシュと照合して時間をそろえています。
    </p>

    <h2>あわせてやること</h2>
    <ul>
      <li>
        <strong>試行回数の制限</strong> …
        同じ ID・同じ IP からの連続失敗で待ち時間を入れる、一定回数でロックする
      </li>
      <li>
        <strong>Cookie の属性</strong> …
        <code>HttpOnly</code>（JavaScript から読めなくする）、
        <code>Secure</code>（HTTPS のときだけ送る）、
        <code>SameSite</code>（別サイトからの送信を抑える）。
        このサイトは <code>web.xml</code> で <code>HttpOnly</code> を有効にしています
      </li>
      <li>
        <strong>HTTPS で通す</strong> …
        平文の HTTP ではパスワードも整理券も通信経路で読めます
      </li>
      <li>
        <strong>パスワードをログに出さない</strong> …
        「デバッグのつもりで出した 1 行」がいちばん漏れます
      </li>
    </ul>

    <h2>JSP は既定でセッションを作る</h2>
    <p>
      この画面は <code>${'${pageContext.session.id}'}</code> でセッション ID を表示していますが、
      そもそも JSP は <code>&lt;%@ page session="true" %&gt;</code> が既定なので、
      <strong>開いただけでセッションが作られます</strong>。
      ログイン不要な画面まで作られるのが気になる場合は、明示的に止められます。
    </p>
<pre><code class="language-xml">&lt;%@ page session="false" %&gt;</code></pre>
  </jsp:attribute>

  <jsp:body>

    <t:resultModal message="${flash}" />

    <c:choose>
      <%-- ============================ ログイン中 ============================ --%>
      <c:when test="${not empty loginUser}">
        <t:panel title="① ログイン中です" note="セッションに LoginUser が入っています">
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0 doc-table">
              <tbody>
                <tr>
                  <th scope="row">氏名</th>
                  <td>${fn:escapeXml(loginUser.name)}</td>
                </tr>
                <tr>
                  <th scope="row">ログイン ID</th>
                  <td><code>${fn:escapeXml(loginUser.loginId)}</code></td>
                </tr>
                <tr>
                  <th scope="row">役割</th>
                  <td>
                    <span class="badge badge-${loginUser.role.variant}">
                      ${fn:escapeXml(loginUser.role.label)}
                    </span>
                  </td>
                </tr>
                <tr>
                  <th scope="row">ログイン時刻</th>
                  <td>${fn:escapeXml(loggedInAt)}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <hr>
          <p class="mb-0">
            この状態で
            <a href="${ctx}/samples/session/auth-filter">フィルタで未ログインを弾く</a>
            のサンプルを開くと、保護された画面に入れるようになります。
          </p>
        </t:panel>
      </c:when>

      <%-- ============================ 未ログイン ============================ --%>
      <c:otherwise>
        <t:panel title="① ログイン" note="下のデモ用アカウントで試せます">
          <c:if test="${not empty loginError}">
            <div class="alert alert-danger" role="alert">
              ${fn:escapeXml(loginError)}
            </div>
          </c:if>

          <form action="${loginUrl}" method="post" novalidate>
            <input type="hidden" name="next" value="${fn:escapeXml(next)}">

            <div class="form-group">
              <label for="loginId">ログイン ID</label>
              <input type="text" class="form-control ${not empty loginError ? 'is-invalid' : ''}"
                     id="loginId" name="loginId" autocomplete="username"
                     value="${fn:escapeXml(inputLoginId)}" placeholder="例: taro">
            </div>

            <div class="form-group">
              <label for="password">パスワード</label>
              <%-- 入力し直しでもパスワードは戻さない（画面や履歴に残さないため） --%>
              <input type="password" class="form-control ${not empty loginError ? 'is-invalid' : ''}"
                     id="password" name="password" autocomplete="current-password" value="">
              <small class="form-text text-muted">
                入力し直しのときも、パスワードは画面に戻しません。
              </small>
            </div>

            <button type="submit" class="btn btn-primary">ログイン</button>
          </form>
        </t:panel>
      </c:otherwise>
    </c:choose>

    <t:panel title="② デモ用のアカウント"
             note="実際のアプリでは、パスワードを画面に書くことは絶対にありません">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th>ログイン ID</th>
              <th>パスワード</th>
              <th>氏名</th>
              <th>役割</th>
              <th>保存されている値</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="account" items="${accounts}">
              <tr>
                <td><code>${fn:escapeXml(account.loginId)}</code></td>
                <td><code>${fn:escapeXml(account.rawPassword)}</code></td>
                <td>${fn:escapeXml(account.name)}</td>
                <td>
                  <span class="badge badge-${account.role.variant}">
                    ${fn:escapeXml(account.role.label)}
                  </span>
                </td>
                <td><code class="small">${fn:escapeXml(account.passwordHashSummary)}</code></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        「保存されている値」の欄はハッシュの<strong>概要</strong>です。
        方式と反復回数を値と一緒に保存しておくと、後から反復回数を増やしたくなったときに、
        古い値を読めなくならずに移行できます。
        同じパスワードでも、ソルトが違うので毎回違う値になります
        （アプリを再起動すると、この欄の値も変わります）。
      </p>
    </t:panel>

    <t:panel title="③ セッション ID の振り直し"
             note="ログインの前後で JSESSIONID が変わっていることを確かめます">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0 doc-table">
          <tbody>
            <tr>
              <th scope="row">いまのセッション ID</th>
              <td><code class="small">${fn:escapeXml(pageContext.session.id)}</code></td>
            </tr>
            <tr>
              <th scope="row">ログイン直前のセッション ID</th>
              <td>
                <c:choose>
                  <c:when test="${empty sessionIdBefore}">
                    <span class="text-muted">（まだログインしていません）</span>
                  </c:when>
                  <c:otherwise>
                    <code class="small">${fn:escapeXml(sessionIdBefore)}</code>
                  </c:otherwise>
                </c:choose>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <c:if test="${not empty sessionIdBefore}">
        <div class="alert alert-success mt-3 mb-0">
          2 つの ID が違っていれば、<code>request.changeSessionId()</code> が効いています。
          ログイン前に配られていた整理券は、もう誰のものでもありません。
        </div>
      </c:if>
      <hr>
      <p class="mb-0 text-muted small">
        ブラウザの開発者ツール（F12）の<strong>アプリケーション</strong>タブで
        <code>JSESSIONID</code> の Cookie を見ると、同じ値が入っています。
        <code>HttpOnly</code> が付いているので、JavaScript からは読めません。
      </p>
    </t:panel>

    <t:panel title="④ ログアウト" note="POST で受け、セッションごと捨てます">
      <c:choose>
        <c:when test="${empty loginUser}">
          <p class="text-muted mb-0">ログインすると、ここにログアウトのボタンが出ます。</p>
        </c:when>
        <c:otherwise>
          <form action="${logoutUrl}" method="post" class="d-inline">
            <button type="submit" class="btn btn-outline-danger">ログアウト</button>
          </form>
        </c:otherwise>
      </c:choose>

      <hr>
      <p class="mb-2">
        同じ URL を <strong>GET</strong> で開くとどうなるかも試せます。
      </p>
      <a class="btn btn-sm btn-outline-secondary" href="${logoutUrl}">
        GET でログアウトを試す（405 が返ります）
      </a>
      <p class="mt-3 mb-0 text-muted small">
        <code>LogoutServlet</code> は <code>doPost</code> しか実装していないため、
        <code>HttpServlet</code> の既定の動きで 405（Method Not Allowed）が返ります。
        405 のエラーページは
        <a href="${ctx}/samples/advanced/error-handling">エラー処理とエラーページ</a>
        のサンプルで用意したものです。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
