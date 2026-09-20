<%--
  【サンプル】国際化 (多言語表示)

  I18nServlet が次の値をセットします。
    selectedLang     … 画面で選ばれた言語 ("" はブラウザ設定に従う)
    locale           … 今回使うロケール (java.util.Locale)
    acceptLanguage   … ブラウザが送ってきた Accept-Language ヘッダ
    browserLocales   … 上を優先度順に並べたもの
    bundleLocale     … 実際に読み込まれた properties のロケール
    jvmDefaultLocale … JVM の既定ロケール
    sampleLocales    … 見比べ用のロケール一覧
    now / amount / quantity / orderCount / userName … 書式化して見せる値
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="sampleUrl" value="${ctx}/samples/advanced/i18n" />
<%--
  このページで使うロケールを決める。ここから下の fmt タグはすべてこの設定に従います。
  書かなかった場合、JSTL はブラウザの Accept-Language を見て自動で選びます。
--%>
<fmt:setLocale value="${locale}" />
<%-- messages*.properties を読み込んで msg という名前で使えるようにする --%>
<fmt:setBundle basename="messages" var="msg" />
<t:sample sampleId="i18n">

  <jsp:attribute name="explanation">
    <h2>やることは 2 つだけ</h2>
    <ol>
      <li>画面に出す文字を JSP から追い出し、言語ごとの <code>.properties</code> にまとめる</li>
      <li>「今回はどの言語で出すか」（ロケール）を決めて、それに合うファイルを選ぶ</li>
    </ol>
    <p>
      文字を外に出しておく利点は、多言語化だけではありません。
      「文言を直したいだけなのに JSP を触る」ことがなくなり、
      同じ言い回しを 1 か所で管理できます。
    </p>

    <h2>ファイルの置き場所と名前</h2>
<pre><code class="language-plaintext">src/main/resources/
├── messages.properties      ← 言語を付けない「最後の受け皿」
├── messages_ja.properties   ← 日本語
└── messages_en.properties   ← 英語

（ビルドすると WEB-INF/classes/ に入ります）</code></pre>
<pre><code class="language-ini">page.title=注文フォーム
label.amount=金額
message.welcome=ようこそ、{0} さん。</code></pre>

    <h3>探す順番</h3>
    <p>
      <code>ja_JP</code> を頼んだときに <code>ResourceBundle</code> が探す順番です。
    </p>
    <ol>
      <li><code>messages_ja_JP.properties</code></li>
      <li><code>messages_ja.properties</code></li>
      <li><strong><code>JVM の既定ロケール</code>の 1・2</strong>（見落としやすい落とし穴）</li>
      <li><code>messages.properties</code></li>
    </ol>
    <p>
      3 番目が曲者です。用意していない言語を頼むと、
      <strong>サーバの既定ロケール次第で表示が変わります</strong>。
      開発機（日本語）では日本語が出るのに、本番（英語ロケール）では英語になる、
      という食い違いはこれが原因です。下の「③ 同じ値がロケールごとにどう見えるか」の <code>fr_FR</code> の行で確かめられます。
    </p>

    <h3>文字コード</h3>
    <p>
      Java 9 以降、<code>.properties</code> は <strong>UTF-8</strong> として読まれます。
      日本語をそのまま書けます。Java 8 以前は ISO-8859-1 だったため、
      <code>native2ascii</code> で <code>こん</code> のように変換する必要がありました。
      古い記事を読むときは、そこが違う点だと思ってください。
    </p>
    <p>
      もう 1 か所、文字コードで引っかかりやすいのが
      <code>response.setLocale(...)</code> です。
      「この応答は何語か」を伝えるためのメソッドですが、
      <strong>その言語で普通に使われる文字コードまで勝手に選ぶ</strong>ことがあります
      （Tomcat の既定では <code>ja</code> なら Shift_JIS、<code>fr</code> なら ISO-8859-1）。
      呼んだあとに UTF-8 を明示して打ち消しておくのが確実です。
    </p>
<pre><code class="language-java">response.setLocale(locale);
response.setCharacterEncoding("UTF-8");   // ← setLocale が選んだ文字コードを打ち消す</code></pre>

    <h2>JSP での使い方（JSTL の fmt タグ）</h2>
<pre><code class="language-xml">&lt;%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %&gt;

&lt;fmt:setLocale value="${'${locale}'}" /&gt;
&lt;fmt:setBundle basename="messages" var="msg" /&gt;

&lt;fmt:message key="label.amount" bundle="${'${msg}'}" /&gt;

&lt;%-- {0} に値を差し込む --%&gt;
&lt;fmt:message key="message.welcome" bundle="${'${msg}'}"&gt;
  &lt;fmt:param value="${'${userName}'}" /&gt;
&lt;/fmt:message&gt;</code></pre>
    <p>
      <code>web.xml</code> に次の 1 行を書いておくと、
      <code>&lt;fmt:setBundle&gt;</code> を省いて <code>&lt;fmt:message key="..." /&gt;</code> だけで書けます。
    </p>
<pre><code class="language-xml">&lt;context-param&gt;
  &lt;param-name&gt;javax.servlet.jsp.jstl.fmt.localizationContext&lt;/param-name&gt;
  &lt;param-value&gt;messages&lt;/param-value&gt;
&lt;/context-param&gt;</code></pre>

    <h2>日付と数値は「値のまま」渡して、見た目は fmt に任せる</h2>
    <p>
      国が変わると、桁区切りも小数点も日付の並びも変わります。
      <code>2026/09/20</code> と書いてしまうと、それはもう日本専用の画面です。
    </p>
<pre><code class="language-xml">&lt;fmt:formatDate   value="${'${now}'}"      type="both" dateStyle="long" timeStyle="short" /&gt;
&lt;fmt:formatNumber value="${'${amount}'}"   type="currency" /&gt;
&lt;fmt:formatNumber value="${'${quantity}'}" type="number" maxFractionDigits="1" /&gt;</code></pre>
    <p>
      Servlet 側は <code>request.setAttribute("amount", 12345)</code> のように
      <strong>数値のまま</strong>渡します。文字列に直すのは最後の 1 回だけにする、が原則です。
    </p>

    <h3>言語だけでなく国も指定する</h3>
    <p>
      <code>Locale.JAPAN</code>（<code>ja_JP</code>）のように国まで指定しているのは、
      <strong>通貨や日付の書式が国で決まる</strong>ためです。
      <code>new Locale("en")</code> のように言語だけだと、
      ドルなのかポンドなのかが決まらず、通貨記号が出せません。
    </p>

    <h2>ロケールの決め方</h2>
    <p>優先順位は次のようにします（上ほど強い）。</p>
    <ol>
      <li><strong>利用者マスタに登録された言語</strong>（ログイン機能があるなら）</li>
      <li><strong>画面で選ばれた言語</strong>（セッションに覚えておく）</li>
      <li><strong>ブラウザの設定</strong>（<code>Accept-Language</code> ヘッダ）</li>
      <li>アプリの既定</li>
    </ol>
<pre><code class="language-java">// ブラウザの設定を読む。ヘッダが無ければコンテナの既定が返る
Locale locale = request.getLocale();

// 優先度順にすべて読む
Enumeration&lt;Locale&gt; locales = request.getLocales();</code></pre>
    <p>
      画面から受け取った言語コードを、<strong>そのまま <code>new Locale(...)</code> に渡してはいけません</strong>。
      用意してある言語だけを通す（ホワイトリスト）形にします。
    </p>

    <h2>文字だけでは終わらない</h2>
    <ul>
      <li><strong>タイムゾーン</strong> … 「いつ」を出すときは必ず付いて回ります。
          <code>&lt;fmt:timeZone&gt;</code> で切り替えられます</li>
      <li><strong>並び替え</strong> … 五十音順とアルファベット順は違います
          （<code>java.text.Collator</code>）</li>
      <li><strong>文字数と桁数</strong> … 訳すと文字数が倍になることがあります。
          固定幅のボタンに収まらなくなります</li>
      <li><strong>単数形と複数形</strong> … 英語は 1 件と 2 件で語尾が変わります。
          日本語しか考えずに「{0} 件」と作ると、英語で破綻します</li>
      <li><strong>右から左に書く言語</strong>（アラビア語など）… 画面の左右も反転します</li>
    </ul>
  </jsp:attribute>

  <jsp:body>

    <t:panel title="① 表示する言語を切り替える"
             note="選んだ言語はセッションに覚えておきます">
      <div class="btn-group mb-3" role="group" aria-label="言語の選択">
        <a class="btn ${selectedLang eq '' ? 'btn-primary' : 'btn-outline-primary'}"
           href="${sampleUrl}?lang=">ブラウザの設定に従う</a>
        <a class="btn ${selectedLang eq 'ja' ? 'btn-primary' : 'btn-outline-primary'}"
           href="${sampleUrl}?lang=ja">日本語</a>
        <a class="btn ${selectedLang eq 'en' ? 'btn-primary' : 'btn-outline-primary'}"
           href="${sampleUrl}?lang=en">English</a>
        <a class="btn ${selectedLang eq 'fr' ? 'btn-primary' : 'btn-outline-primary'}"
           href="${sampleUrl}?lang=fr">Français</a>
      </div>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0 doc-table">
          <tbody>
            <tr>
              <th scope="row">今回使うロケール</th>
              <td><code>${fn:escapeXml(locale)}</code></td>
            </tr>
            <tr>
              <th scope="row">実際に読み込まれた properties</th>
              <td>
                <c:choose>
                  <c:when test="${empty bundleLocale}">
                    <span class="text-danger">見つかりませんでした</span>
                  </c:when>
                  <c:when test="${empty bundleLocale.language}">
                    <code>messages.properties</code>
                    <span class="badge badge-secondary ml-1">言語指定なし</span>
                  </c:when>
                  <c:otherwise>
                    <code>messages_${fn:escapeXml(bundleLocale)}.properties</code>
                  </c:otherwise>
                </c:choose>
              </td>
            </tr>
            <tr>
              <th scope="row">ブラウザが送ってきた Accept-Language</th>
              <td>
                <c:choose>
                  <c:when test="${empty acceptLanguage}"><span class="text-muted">（送られていません）</span></c:when>
                  <c:otherwise><code>${fn:escapeXml(acceptLanguage)}</code></c:otherwise>
                </c:choose>
              </td>
            </tr>
            <tr>
              <th scope="row">request.getLocales()（優先度順）</th>
              <td>
                <c:forEach var="tag" items="${browserLocales}" varStatus="s">
                  <code>${fn:escapeXml(tag)}</code><c:if test="${not s.last}">, </c:if>
                </c:forEach>
              </td>
            </tr>
            <tr>
              <th scope="row">JVM の既定ロケール</th>
              <td><code>${fn:escapeXml(jvmDefaultLocale)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="② properties のメッセージを出す"
             note="画面には key だけを書き、文言はファイル側に置きます">
      <div class="border rounded p-3 mb-3 bg-white">
        <h3 class="h5"><fmt:message key="page.title" bundle="${msg}" /></h3>
        <p class="text-muted"><fmt:message key="page.lead" bundle="${msg}" /></p>

        <p>
          <%-- {0} に値を差し込む。文章の組み立てを properties 側に任せるのが要点 --%>
          <fmt:message key="message.welcome" bundle="${msg}">
            <fmt:param value="${userName}" />
          </fmt:message>
          <fmt:message key="message.orders" bundle="${msg}">
            <fmt:param value="${orderCount}" />
          </fmt:message>
        </p>

        <dl class="row mb-0">
          <dt class="col-sm-3"><fmt:message key="label.name" bundle="${msg}" /></dt>
          <dd class="col-sm-9">${fn:escapeXml(userName)}</dd>
          <dt class="col-sm-3"><fmt:message key="label.orderDate" bundle="${msg}" /></dt>
          <dd class="col-sm-9"><fmt:formatDate value="${now}" dateStyle="long" /></dd>
          <dt class="col-sm-3"><fmt:message key="label.amount" bundle="${msg}" /></dt>
          <dd class="col-sm-9"><fmt:formatNumber value="${amount}" type="currency" /></dd>
          <dt class="col-sm-3"><fmt:message key="label.quantity" bundle="${msg}" /></dt>
          <dd class="col-sm-9"><fmt:formatNumber value="${quantity}" type="number" maxFractionDigits="1" /></dd>
        </dl>
      </div>
      <p class="mb-0 text-muted small">
        key が properties に無いと <code>???key???</code> と表示されます。
        画面には出ても例外にはならないので、
        <strong>言語を足したときの入れ忘れは自分では気付けません</strong>。
        key の一覧を突き合わせるテストを書いておくと安全です。
      </p>
    </t:panel>

    <t:panel title="③ 同じ値がロケールごとにどう見えるか"
             note="桁区切り・小数点・日付の並び・通貨記号がすべて変わります">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr>
              <th>ロケール</th>
              <th>ボタンの文言</th>
              <th>日付</th>
              <th>金額 (12345)</th>
              <th>数量 (1234.5)</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="loc" items="${sampleLocales}">
              <%-- ループの中でロケールを切り替える。以降の fmt タグがこの設定に従う --%>
              <fmt:setLocale value="${loc}" />
              <fmt:setBundle basename="messages" var="rowMsg" />
              <tr>
                <td><code>${fn:escapeXml(loc)}</code></td>
                <td><fmt:message key="button.submit" bundle="${rowMsg}" /></td>
                <td><fmt:formatDate value="${now}" dateStyle="medium" /></td>
                <td><fmt:formatNumber value="${amount}" type="currency" /></td>
                <td><fmt:formatNumber value="${quantity}" type="number" maxFractionDigits="1" /></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <%-- 切り替えたままにすると、このあとの表示が最後のロケールになってしまう --%>
      <fmt:setLocale value="${locale}" />
      <fmt:setBundle basename="messages" var="msg" />
      <hr>
      <p class="mb-0 text-muted small">
        <code>fr_FR</code> の行だけ文言が日本語や英語になっているのは、
        <code>messages_fr.properties</code> を用意していないからです
        （数値や日付の書式は Java が持っているので、properties が無くても切り替わります）。
      </p>
    </t:panel>

    <t:panel title="④ タイムゾーン"
             note="「いつ」を出すときは、言語とは別にタイムゾーンが付いて回ります">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0 doc-table">
          <tbody>
            <tr>
              <th scope="row">サーバの既定（Asia/Tokyo）</th>
              <td><fmt:formatDate value="${now}" type="both" dateStyle="medium" timeStyle="long" /></td>
            </tr>
            <tr>
              <th scope="row">UTC</th>
              <td>
                <fmt:timeZone value="UTC">
                  <fmt:formatDate value="${now}" type="both" dateStyle="medium" timeStyle="long" />
                </fmt:timeZone>
              </td>
            </tr>
            <tr>
              <th scope="row">America/New_York</th>
              <td>
                <fmt:timeZone value="America/New_York">
                  <fmt:formatDate value="${now}" type="both" dateStyle="medium" timeStyle="long" />
                </fmt:timeZone>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <hr>
      <p class="mb-0 text-muted small">
        同じ一瞬を指していても、どのタイムゾーンで見るかで日付そのものが変わります。
        保存するときは UTC（または <code>java.time.Instant</code>）で持ち、
        画面に出すときだけ利用者のタイムゾーンに直すのが確実です。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
