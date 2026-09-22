<%--
  【サンプル】文字コードと文字化け

  CharacterEncodingServlet が次の値をセットします。
    requestEncoding / responseEncoding / contextRequestEncoding … いまの設定
    sent / sentHex                                              … 送られてきた日本語
    conversions                                                 … 化け方の一覧
    legacyLink / legacyAsRead / legacyRecovered                 … Shift_JIS のリンクのデモ

  化け方は実際のリクエストを壊さず、Java の中で「書いて読み直す」ことで再現しています。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/basic/character-encoding" />
<t:sample sampleId="character-encoding">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>文字化けは「文字」が壊れるのではない</h2>
    <p>
      文字はそのままの形で運ばれているわけではありません。いったん
      <strong>バイト列</strong>になって送られ、受け取った側がそれを文字に戻します。
      このとき<strong>書いたときと違う文字コードで読む</strong>と化けます。
      壊れているのは文字ではなく、<strong>読み方の取り決め</strong>です。
    </p>

<pre><code class="language-plaintext">"文字化け"  ──[UTF-8 で書く]──▶  E6 96 87 E5 AD 97 E5 8C 96 E3 81 91
                                          │
                                          ├─[UTF-8 で読む]──▶  文字化け      ← 元に戻る
                                          └─[Shift_JIS で読む]▶  譁・ｭ怜喧縺・  ← 化ける</code></pre>

    <p>
      だからこそ、化けた文字列を「直す」ことはできません。
      <strong>バイト列まで戻って読み直す</strong>か、そもそも同じ文字コードで揃えるかの
      どちらかになります。
    </p>

    <h2>化け方で原因が分かる</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 11rem;">見た目</th>
            <th>起きていること</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><code>譁・ｭ怜喧</code></td>
            <td>UTF-8 のバイト列を <strong>Shift_JIS 系で読んだ</strong>。日本語の Web でいちばん多い</td>
          </tr>
          <tr>
            <td><code>æ–‡å­—åŒ–ã</code></td>
            <td>UTF-8 のバイト列を <strong>ISO-8859-1（1 バイト = 1 文字）で読んだ</strong></td>
          </tr>
          <tr>
            <td><code>???</code></td>
            <td>
              <strong>書き出す側</strong>にその文字を表す手段が無かった。
              バイト列の時点で <code>?</code> になっているので、もう戻せません
            </td>
          </tr>
          <tr>
            <td><code>&#xFFFD;</code>（黒いひし形の ?）</td>
            <td>
              <strong>読む側</strong>が、そのバイトの並びを文字にできなかった。
              U+FFFD という「読めなかった印」です
            </td>
          </tr>
          <tr>
            <td>□（豆腐）</td>
            <td>
              <strong>文字化けではありません。</strong>
              文字としては正しく読めていて、その字を持つフォントが無いだけです
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>リクエスト側：本文とクエリ文字列は別もの</h2>
    <p>
      同じ「日本語を送る」でも、<strong>POST の本文</strong>と
      <strong>URL のクエリ文字列</strong>では読まれ方が違います。ここが混乱しやすいところです。
    </p>

    <div class="table-responsive">
      <table class="table table-sm table-bordered doc-table">
        <thead>
          <tr>
            <th style="width: 11rem;">どこ</th>
            <th>何で決まるか</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>POST の本文</td>
            <td>
              <code>request.setCharacterEncoding(...)</code>、または
              <code>web.xml</code> の <code>&lt;request-character-encoding&gt;</code>。
              <strong>指定しないと ISO-8859-1 として読まれます</strong>
            </td>
          </tr>
          <tr>
            <td>URL のクエリ文字列</td>
            <td>
              サーバの設定（Tomcat なら <code>server.xml</code> の
              <code>Connector</code> の <code>URIEncoding</code>）。
              Tomcat 8.0 以降は <strong>UTF-8 が既定</strong>です。
              <code>setCharacterEncoding</code> はここには効きません
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <p>そして、指定する<strong>順番</strong>に決まりがあります。</p>
<pre><code class="language-java">// ○ 読み始める前に指定する
request.setCharacterEncoding("UTF-8");
String name = request.getParameter("name");

// × これでは手遅れ（1 回目の getParameter で本文を読み切ってしまう）
String name = request.getParameter("name");
request.setCharacterEncoding("UTF-8");</code></pre>

    <p>
      Servlet 3.1 以前は、すべてのリクエストに掛かるフィルタを書くのが定番でした。
      Servlet 4.0（Tomcat 9）からは <code>web.xml</code> に 1 行書くだけで済みます。
      このアプリもその書き方にしています。
    </p>
<pre><code class="language-xml">&lt;request-character-encoding&gt;UTF-8&lt;/request-character-encoding&gt;
&lt;response-character-encoding&gt;UTF-8&lt;/response-character-encoding&gt;</code></pre>

    <p class="text-muted small">
      なお <code>&lt;form accept-charset="Shift_JIS"&gt;</code> は、いまのブラウザではほぼ効きません。
      ブラウザは<strong>その画面自身の文字コード</strong>（このサイトなら UTF-8）で送ります。
    </p>

    <h2>レスポンス側：名乗ってから書く</h2>
<pre><code class="language-java">// ○ 書き始める前に決める
response.setContentType("text/html; charset=UTF-8");
PrintWriter out = response.getWriter();

// × getWriter() のあとで変えても、文字コードはもう決まっている
PrintWriter out = response.getWriter();
response.setContentType("text/html; charset=UTF-8");</code></pre>

    <ul>
      <li>
        <strong>HTTP ヘッダが優先されます。</strong>
        HTML の <code>&lt;meta charset="UTF-8"&gt;</code> は、サーバが文字コードを名乗らなかったときの
        保険です。両方書いて食い違うと、ヘッダの方が勝ちます
      </li>
      <li>
        JSP では <code>&lt;%@ page contentType="text/html; charset=UTF-8"
        pageEncoding="UTF-8" %&gt;</code> の 2 つを書きます。
        <strong><code>pageEncoding</code> は「この JSP ファイル自身が何で保存されているか」</strong>、
        <code>contentType</code> は「何と名乗って返すか」で、意味が違います
      </li>
      <li>
        ファイルをダウンロードさせるときは、ファイル名の扱いも別に必要です
        （「ファイル &gt; CSV ダウンロード」を参照）
      </li>
    </ul>

    <h2>ファイル側：保存する文字コードを揃える</h2>
    <ul>
      <li><code>.java</code> … <code>pom.xml</code> の <code>project.build.sourceEncoding</code> を UTF-8 に</li>
      <li><code>.jsp</code> … <code>pageEncoding</code>（<code>web.xml</code> の <code>&lt;jsp-config&gt;</code> でまとめて指定できます）</li>
      <li><code>.properties</code> … Java 9 以降は UTF-8 として読まれます（8 以前は ISO-8859-1 でした）</li>
      <li>このリポジトリでは <code>.editorconfig</code> で UTF-8 に揃えています</li>
    </ul>

    <h2>化けたときに見る順番</h2>
    <ol>
      <li><strong>どこで化けたか</strong>を挟み撃ちする（ブラウザの表示 / サーバのログ / DB の中身）</li>
      <li><strong>バイト列を見る</strong>。<code>E3 81 82</code> なら UTF-8 の「あ」、<code>82 A0</code> なら Shift_JIS の「あ」</li>
      <li>化け方から<strong>読み手と書き手のどちらがずれているか</strong>を絞る（上の表）</li>
      <li>直すのは<strong>ずれている側 1 か所</strong>。両方いじると、直ったように見えて別の経路で化けます</li>
    </ol>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="いまの文字コード設定">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" style="width: 22rem;"><code>request.getCharacterEncoding()</code></th>
              <td>
                <code>${empty requestEncoding ? 'null' : fn:escapeXml(requestEncoding)}</code>
                <span class="d-block text-muted small mt-1">
                  リクエスト本文を読むときの文字コード。<code>web.xml</code> の
                  <code>&lt;request-character-encoding&gt;</code> で決めています
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row"><code>response.getCharacterEncoding()</code></th>
              <td><code>${fn:escapeXml(responseEncoding)}</code></td>
            </tr>
            <tr>
              <th scope="row"><code>ServletContext#getRequestCharacterEncoding()</code></th>
              <td><code>${empty contextRequestEncoding ? 'null' : fn:escapeXml(contextRequestEncoding)}</code></td>
            </tr>
            <tr>
              <th scope="row"><code>ServletContext#getResponseCharacterEncoding()</code></th>
              <td><code>${empty contextResponseEncoding ? 'null' : fn:escapeXml(contextResponseEncoding)}</code></td>
            </tr>
            <tr>
              <th scope="row">JVM の <code>file.encoding</code></th>
              <td>
                <code>${fn:escapeXml(fileEncoding)}</code>
                <span class="d-block text-muted small mt-1">
                  ファイルを読み書きするときに、文字コードを省略すると使われる値です。
                  省略せずに毎回指定するのが安全です
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="日本語を送ってみる" note="GET（クエリ文字列）と POST（本文）で受け取り方が変わらないかを確かめます">
      <form action="${sampleUrl}" method="get" class="form-inline mb-3">
        <label class="mr-2" for="sentInput">送る文字</label>
        <input type="text" class="form-control mr-2" id="sentInput" name="sent" size="24"
               value="${empty sent ? '日本語のテスト' : fn:escapeXml(sent)}">
        <button type="submit" class="btn btn-primary mr-2" formmethod="get">GET で送る</button>
        <button type="submit" class="btn btn-outline-primary" formmethod="post">POST で送る</button>
      </form>

      <c:choose>
        <c:when test="${empty sent}">
          <p class="text-muted mb-0">まだ送っていません。どちらかのボタンを押してください。</p>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <tbody>
                <tr>
                  <th scope="row" style="width: 16rem;">送り方</th>
                  <td>
                    <code>${fn:escapeXml(requestMethod)}</code>
                    <span class="text-muted small ml-2">
                      <c:choose>
                        <c:when test="${requestMethod eq 'POST'}">値はリクエスト本文に入っています</c:when>
                        <c:otherwise>値は URL のクエリ文字列に入っています</c:otherwise>
                      </c:choose>
                    </span>
                  </td>
                </tr>
                <tr>
                  <th scope="row">受け取った値</th>
                  <td><code>${fn:escapeXml(sent)}</code>（${sentLength} 文字）</td>
                </tr>
                <tr>
                  <th scope="row">UTF-8 でのバイト列</th>
                  <td><code class="small">${fn:escapeXml(sentHex)}</code></td>
                </tr>
                <tr>
                  <th scope="row"><code>getQueryString()</code></th>
                  <td>
                    <code class="small">${empty queryString ? 'null' : fn:escapeXml(queryString)}</code>
                    <span class="d-block text-muted small mt-1">
                      POST では <code>null</code> です。本文は <code>getParameter</code> から読みます
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <p class="text-muted small mt-3 mb-0">
            どちらで送っても同じに見えますが、読んでいる場所は別です。
            本文は <code>&lt;request-character-encoding&gt;</code>、クエリ文字列は
            Tomcat の <code>URIEncoding</code>（8.0 以降は UTF-8 が既定）で決まります。
          </p>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <t:panel title="化け方を再現する" note="実際のリクエストは壊さず、Java の中で「書いて読み直す」を再現しています">
      <form action="${sampleUrl}" method="get" class="form-inline mb-3">
        <label class="mr-2" for="textInput">元の文字</label>
        <input type="text" class="form-control mr-2" id="textInput" name="text" size="24"
               value="${fn:escapeXml(text)}">
        <button type="submit" class="btn btn-primary">化けさせる</button>
      </form>

      <p class="small text-muted">
        <code>${fn:escapeXml(text)}</code> を UTF-8 で書くと
        <code>${fn:escapeXml(textHex)}</code> です。これをどう読むかで結果が変わります。
      </p>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th style="width: 8rem;">書いた</th>
              <th style="width: 8rem;">読んだ</th>
              <th style="width: 12rem;">結果</th>
              <th>バイト列とひとこと</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="conversion" items="${conversions}">
              <tr class="${conversion.broken ? '' : 'table-success'}">
                <td><code>${fn:escapeXml(conversion.writtenAs)}</code></td>
                <td><code>${fn:escapeXml(conversion.readAs)}</code></td>
                <td><code>${fn:escapeXml(conversion.text)}</code></td>
                <td class="small">
                  <code>${fn:escapeXml(conversion.hex)}</code>
                  <span class="d-block text-muted mt-1">${fn:escapeXml(conversion.note)}</span>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        緑の行が「書いたときと同じ文字コードで読んだ」場合です。
        それ以外はすべて、元の文字には戻っていません。
      </p>
    </t:panel>

    <t:panel title="Shift_JIS で組み立てられたリンクが来たら"
             note="古いシステムからの遷移で実際に起きる文字化けです">
      <p class="small text-muted mb-3">
        下のリンクのクエリ文字列は <strong>Shift_JIS</strong> で組み立ててあります
        （UTF-8 なら <code>%E5%A3%B2</code> で始まるところが <code>%94%84</code> になっています）。
        Tomcat は既定で UTF-8 として読むので、<code>getParameter</code> では化けます。
      </p>

      <p class="mb-3">
        <a class="btn btn-sm btn-outline-primary" href="${fn:escapeXml(legacyLink)}">
          Shift_JIS のリンクで開く
        </a>
        <code class="small ml-2">${fn:escapeXml(legacyLink)}</code>
      </p>

      <c:if test="${not empty legacyAsRead}">
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-0">
            <tbody>
              <tr>
                <th scope="row" style="width: 22rem;"><code>getQueryString()</code>（生のまま）</th>
                <td><code class="small">${fn:escapeXml(queryString)}</code></td>
              </tr>
              <tr class="table-danger">
                <th scope="row"><code>getParameter("q")</code></th>
                <td>
                  <code>${fn:escapeXml(legacyAsRead)}</code>
                  <span class="d-block text-muted small mt-1">
                    UTF-8 として読まれたので化けています
                    （UTF-8 のバイト列にすると <code>${fn:escapeXml(legacyAsReadHex)}</code>）
                  </span>
                </td>
              </tr>
              <tr class="table-success">
                <th scope="row">生のクエリ文字列から読み直した値</th>
                <td>
                  <code>${fn:escapeXml(legacyRecovered)}</code>
                  <span class="d-block text-muted small mt-1">
                    <code>getQueryString()</code> を自分で分解し、
                    <code>URLDecoder.decode(値, "windows-31j")</code> で読み直しています
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <p class="small text-muted mt-3 mb-0">
          要点は<strong>「化けた文字列を直す」のではなく「バイト列まで戻ってやり直す」</strong>ことです。
          <code>new String(化けた文字列.getBytes("ISO-8859-1"), "UTF-8")</code> のような
          変換で直ることもありますが、途中で <code>?</code> や U+FFFD に潰れていると戻りません。
        </p>
      </c:if>
    </t:panel>
  </jsp:body>
</t:sample>
