<%--
  【サンプル】Cookie の基本

  CookieServlet が次の値をセットします。
    cookies    … ブラウザが送ってきた Cookie の一覧 (Cookies.View)
    sessionId  … いまのセッション ID
    pathAll    … サイト全体に送り返してもらうときの Path
    pathSample … この画面だけに送り返してもらうときの Path

  発行と削除は POST で受け、リダイレクトしてから結果を出しています (PRG)。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/basic/cookie" />
<t:sample sampleId="cookie">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>Cookie は「ブラウザに預けるメモ」</h2>
    <p>
      HTTP はリクエストごとに独立していて、前回のことを覚えていません。
      そこでサーバは、覚えておいてほしい値を<strong>ブラウザに預けます</strong>。
      預かったブラウザは、同じサイトへのリクエストのたびにそれを自動で送り返します。
    </p>

<pre><code class="language-plaintext">サーバ → ブラウザ
  Set-Cookie: sample_memo=hello; Max-Age=3600; Path=/; HttpOnly

ブラウザ → サーバ（次のリクエストから、毎回自動で）
  Cookie: sample_memo=hello</code></pre>

    <p>
      <strong>送り返されるのは名前と値だけ</strong>です。
      <code>Max-Age</code> や <code>Path</code> や <code>HttpOnly</code> は
      「ブラウザへの指示」なので、サーバには戻ってきません。
      そのため <code>request.getCookies()</code> で取れる
      <code>Cookie</code> オブジェクトの <code>getMaxAge()</code> や
      <code>getPath()</code> は、意味のある値になりません。
    </p>

    <h2>属性</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 10rem;">属性</th>
            <th>意味</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>Max-Age</code><br><code>Expires</code></td>
            <td>
              いつまで預かるか。<code>setMaxAge(秒)</code> で指定します。
              <strong><code>-1</code>（既定）はブラウザを閉じるまで</strong>、
              <strong><code>0</code> はすぐ削除</strong>です
            </td>
          </tr>
          <tr>
            <td><code>Path</code></td>
            <td>
              どの URL のときに送り返すか。<code>/</code> ならサイト全体、
              <code>/samples/basic/cookie</code> ならその配下だけです。
              <strong>指定しないと「いまの URL のひとつ上の階層」になります</strong>
              （思ったところに送られない原因の定番）
            </td>
          </tr>
          <tr>
            <td><code>Domain</code></td>
            <td>
              どのホストに送り返すか。指定しなければ<strong>発行したホストだけ</strong>。
              <code>example.com</code> と書くとサブドメインにも送られます
            </td>
          </tr>
          <tr>
            <td><code>HttpOnly</code></td>
            <td>
              JavaScript（<code>document.cookie</code>）から読めなくします。
              <strong>XSS で盗まれるのを防ぐ最後の砦</strong>なので、
              セッション ID には必ず付けます
            </td>
          </tr>
          <tr>
            <td><code>Secure</code></td>
            <td>HTTPS のときだけ保存・送信します。http で開くと保存されません</td>
          </tr>
          <tr>
            <td><code>SameSite</code></td>
            <td>
              他のサイトからの遷移で送り返すかどうか。
              <code>Lax</code>（既定に近い）/ <code>Strict</code> / <code>None</code>。
              <strong>CSRF 対策の土台</strong>になりますが、これだけに頼らず
              トークンと併用します（「セッション・認証 &gt; CSRF 対策」を参照）
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <p class="text-muted small">
      <code>SameSite</code> は Servlet 4.0 の <code>Cookie</code> クラスには
      設定するメソッドがありません。Tomcat では <code>context.xml</code> の
      <code>CookieProcessor</code> でまとめて指定するか、
      <code>Set-Cookie</code> ヘッダを自分で組み立てます。
    </p>

    <h2>更新と削除は「上書き」</h2>
    <p>
      Cookie を消す専用の命令はありません。
      <strong>同じ名前・同じ Path で、有効期限 0 のものを送る</strong>だけです。
    </p>
<pre><code class="language-java">Cookie deleted = new Cookie("sample_memo", "");
deleted.setMaxAge(0);
deleted.setPath("/");        // ← 発行したときと同じ Path でないと消えない
response.addCookie(deleted);</code></pre>
    <p>
      <strong>「消したはずなのに残っている」のは、たいてい Path 違い</strong>です。
      ブラウザは Path を教えてくれないので、心当たりのあるパスすべてに送ることになります。
      このサンプルの削除ボタンも、2 つのパスの両方に送っています。
    </p>

    <h2>セッションとの関係</h2>
    <p>
      <code>HttpSession</code> も土台は Cookie です。値そのものはサーバが持ち、
      <strong>引換券だけ</strong>を <code>JSESSIONID</code> という Cookie で渡しています。
      このサイトでは <code>web.xml</code> で次のように指定しています。
    </p>
<pre><code class="language-xml">&lt;session-config&gt;
  &lt;session-timeout&gt;30&lt;/session-timeout&gt;
  &lt;cookie-config&gt;
    &lt;http-only&gt;true&lt;/http-only&gt;      &lt;!-- JavaScript から読ませない --&gt;
  &lt;/cookie-config&gt;
  &lt;tracking-mode&gt;COOKIE&lt;/tracking-mode&gt;  &lt;!-- URL に ;jsessionid= を付けない --&gt;
&lt;/session-config&gt;</code></pre>

    <h2>入れてよいもの・いけないもの</h2>
    <ul>
      <li>
        <strong>権限や金額を入れない。</strong>
        Cookie の値は利用者が自由に書き換えられます。
        <code>role=admin</code> のような値を信用してはいけません。
        判断に使う値はサーバ側（セッションや DB）に置き、Cookie には引換券だけを入れます
      </li>
      <li>
        <strong>個人情報を入れない。</strong>
        端末に平文で残り、他のタブや拡張機能からも触れ得ます
      </li>
      <li>
        <strong>大きくしない。</strong>
        1 つあたり 4KB 程度、1 ドメインあたりの個数にも上限があります。
        しかも<strong>該当する URL へのリクエストすべてに毎回付いてきます</strong>
        （画像や CSS の取得にも）
      </li>
      <li>
        <strong>値は URL エンコードする。</strong>
        <code>;</code> や空白、日本語はそのままでは入れられません
      </li>
    </ul>

    <h2>JSP から読む</h2>
<pre><code class="language-xml">${'${cookie.JSESSIONID.value}'}      &lt;%-- 名前で 1 件 --%&gt;
&lt;c:forEach var="entry" items="${'${cookie}'}"&gt;${'${entry.key}'}&lt;/c:forEach&gt;</code></pre>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      $(function () {
        // document.cookie は「JavaScript から見える Cookie」だけを返します。
        // HttpOnly を付けたものはここに出てきません
        $('#readByScript').on('click', function () {
          var raw = document.cookie;
          $('#scriptResult').text(raw === '' ? '(JavaScript からは 1 つも見えません)' : raw);
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>
    <t:resultModal message="${flash}" />

    <t:panel title="ブラウザが送ってきた Cookie" note="この画面を開くリクエストに付いてきたもの">
      <c:choose>
        <c:when test="${empty cookies}">
          <p class="text-muted mb-0">1 つも届いていません（<code>getCookies()</code> は <code>null</code> でした）。</p>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <thead>
                <tr>
                  <th style="width: 14rem;">名前</th>
                  <th style="width: 14rem;">値（そのまま）</th>
                  <th>値（URL デコード後）</th>
                  <th style="width: 6rem;">&nbsp;</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="entry" items="${cookies}">
                  <tr class="${entry.sessionCookie ? 'table-info' : ''}">
                    <td>
                      <code>${fn:escapeXml(entry.name)}</code>
                      <c:if test="${entry.sessionCookie}">
                        <span class="badge badge-info ml-1">セッション</span>
                      </c:if>
                    </td>
                    <td class="small"><code>${fn:escapeXml(entry.rawValue)}</code></td>
                    <td class="small"><code>${fn:escapeXml(entry.value)}</code></td>
                    <td>
                      <c:if test="${entry.sample}">
                        <form action="${sampleUrl}" method="post" class="mb-0">
                          <input type="hidden" name="action" value="delete">
                          <input type="hidden" name="name" value="${fn:escapeXml(entry.name)}">
                          <button type="submit" class="btn btn-sm btn-outline-danger">削除</button>
                        </form>
                      </c:if>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <form action="${sampleUrl}" method="post" class="mt-3 mb-0">
            <input type="hidden" name="action" value="deleteAll">
            <button type="submit" class="btn btn-sm btn-outline-secondary">
              このサンプルで作った Cookie をまとめて削除
            </button>
          </form>
        </c:otherwise>
      </c:choose>
      <p class="text-muted small mt-3 mb-0">
        届くのは<strong>名前と値だけ</strong>です。有効期限もパスも送られてこないため、
        サーバからは「いつまで預かっているのか」を知る手段がありません。
      </p>
    </t:panel>

    <t:panel title="Cookie を発行する" note="名前には sample_ が必ず付きます（JSESSIONID を上書きさせないため）">
      <form action="${sampleUrl}" method="post">
        <input type="hidden" name="action" value="add">

        <div class="form-row align-items-end">
          <div class="form-group col-md-3">
            <label for="nameInput">名前</label>
            <div class="input-group">
              <div class="input-group-prepend">
                <span class="input-group-text">sample_</span>
              </div>
              <input type="text" class="form-control" id="nameInput" name="name" value="memo">
            </div>
          </div>
          <div class="form-group col-md-3">
            <label for="valueInput">値</label>
            <input type="text" class="form-control" id="valueInput" name="value"
                   value="こんにちは; 世界">
          </div>
          <div class="form-group col-md-3">
            <label for="maxAgeSelect">有効期限（Max-Age）</label>
            <select class="form-control" id="maxAgeSelect" name="maxAge">
              <option value="-1">-1 : ブラウザを閉じるまで</option>
              <option value="60">60 : 60 秒</option>
              <option value="3600">3600 : 1 時間</option>
              <option value="86400">86400 : 1 日</option>
              <option value="0">0 : すぐ削除</option>
            </select>
          </div>
          <div class="form-group col-md-3">
            <label for="pathSelect">Path</label>
            <select class="form-control" id="pathSelect" name="path">
              <option value="all">${fn:escapeXml(pathAll)} : サイト全体</option>
              <option value="sample">${fn:escapeXml(pathSample)} : この画面だけ</option>
            </select>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group col-md-12">
            <div class="form-check form-check-inline">
              <input class="form-check-input" type="checkbox" id="httpOnlyCheck" name="httpOnly" checked>
              <label class="form-check-label" for="httpOnlyCheck">
                <code>HttpOnly</code>（JavaScript から読ませない）
              </label>
            </div>
            <div class="form-check form-check-inline ml-3">
              <input class="form-check-input" type="checkbox" id="secureCheck" name="secure">
              <label class="form-check-label" for="secureCheck">
                <code>Secure</code>（HTTPS のときだけ）
              </label>
            </div>
          </div>
        </div>

        <button type="submit" class="btn btn-primary">発行する</button>
      </form>

      <p class="text-muted small mt-3 mb-0">
        値に <code>;</code> や日本語を入れても大丈夫です。サーバ側で URL エンコードしてから
        預けているので、上の一覧では「そのまま」と「デコード後」の両方が見られます。<br>
        <code>Path</code> を「この画面だけ」にすると、他のページを開いたときには送られてきません
        （サイトのトップに移動してから戻ってくると分かります）。<br>
        <code>Secure</code> を付けると、<strong>http で開いている間は保存されません</strong>。
        発行しても一覧に出てこないのが正しい動きです。
      </p>
    </t:panel>

    <t:panel title="JavaScript から見えるか" note="HttpOnly の効き目を確かめます">
      <button type="button" class="btn btn-outline-primary mb-3" id="readByScript">
        document.cookie を読む
      </button>
      <pre class="code-snippet mb-0" id="scriptResult">ボタンを押すと、JavaScript から見える Cookie が出ます。</pre>
      <p class="text-muted small mt-3 mb-0">
        <code>HttpOnly</code> を付けて発行したものと、<code>JSESSIONID</code> は出てきません。
        付けずに発行したものは出てきます。
        <strong>XSS でスクリプトを差し込まれても、HttpOnly なら値を盗めない</strong>ということです。
      </p>
    </t:panel>

    <t:panel title="セッション ID の引換券">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" style="width: 18rem;"><code>session.getId()</code></th>
              <td><code>${fn:escapeXml(sessionId)}</code></td>
            </tr>
            <tr>
              <th scope="row"><code>${'${cookie.JSESSIONID.value}'}</code></th>
              <td><code>${empty cookie.JSESSIONID ? '(まだ届いていません)' : fn:escapeXml(cookie.JSESSIONID.value)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        同じ値です。サーバはセッションの中身を自分で持ち、ブラウザには<strong>この引換券だけ</strong>を
        預けています。だからこそ、この値が盗まれるとなりすましができてしまいます
        （<code>HttpOnly</code> が必須な理由です）。
        初回アクセスの直後は、まだブラウザが受け取っていないので下の行が空になります。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
