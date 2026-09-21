<%--
  【サンプル】リスナーで起動・終了・セッションを捕まえる

  ListenerServlet が次の値をセットします。
    startedAt / uptimeSeconds        … アプリが起動した時刻と、そこからの経過
    createdSessions / activeSessions … 起動してから作られたセッション数と、いま生きている数
    serverInfo                       … Servlet コンテナの名前
    sessionId / sessionCreatedAt / sessionAccessedAt / sessionTimeout / sessionAttributes
                                     … いまのセッションの様子
    events / maxEvents               … リスナーが書き留めた記録 (新しい順)
    flash / formError                … 操作の結果と入力の誤り

  記録を作っているのは AppLifecycleListener と SessionLifecycleListener です。
  どちらもこの画面からは呼んでいません。呼ぶのはコンテナです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="listener">

  <jsp:attribute name="explanation">
    <h2>リスナーは「節目」で呼ばれる</h2>
    <p>
      Servlet は<strong>リクエストが来たとき</strong>に呼ばれます。
      では「アプリが起動したとき」「セッションが切れたとき」に何かしたい場合はどうするか。
      そのための入口がリスナー（Listener）です。
      作るのは<strong>インタフェースを実装したクラス 1 つ</strong>で、
      呼ぶのはこちらではなく<strong>コンテナ（Tomcat）</strong>です。
    </p>
<pre><code class="language-java">@WebListener
public class AppLifecycleListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent event) {
        // アプリが起動したとき（最初のリクエストが来る前）に 1 回だけ
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        // アプリが止まるとき（最後のリクエストが終わったあと）に 1 回だけ
    }
}</code></pre>

    <h2>主なリスナー</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>インタフェース</th><th>捕まえられる節目</th><th>使いどころ</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>ServletContextListener</code></td>
            <td>アプリの起動・停止</td>
            <td>設定の読み込み、接続プールやスレッドプールの用意と後始末</td>
          </tr>
          <tr>
            <td><code>ServletContextAttributeListener</code></td>
            <td>application スコープの値の出し入れ</td>
            <td>共有データの変更を追いたいとき</td>
          </tr>
          <tr>
            <td><code>HttpSessionListener</code></td>
            <td>セッションの作成・破棄</td>
            <td>同時利用者数を数える、セッションの後始末</td>
          </tr>
          <tr>
            <td><code>HttpSessionAttributeListener</code></td>
            <td>session スコープの値の出し入れ</td>
            <td>ログイン・ログアウトの記録</td>
          </tr>
          <tr>
            <td><code>ServletRequestListener</code></td>
            <td>リクエストの開始・終了</td>
            <td>MDC（ログの付帯情報）の出し入れ。<strong>全リクエストで動きます</strong></td>
          </tr>
          <tr>
            <td><code>HttpSessionBindingListener</code></td>
            <td>自分がセッションに入れられた／外されたとき</td>
            <td>リスナー登録は不要。<strong>値を入れる側のクラス</strong>に実装します</td>
          </tr>
          <tr>
            <td><code>AsyncListener</code></td>
            <td>非同期処理の完了・時間切れ・エラー</td>
            <td>「時間のかかる処理を非同期で動かす」のサンプルで使っています</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>登録の仕方 : @WebListener と web.xml</h2>
    <p>
      どちらでも動きます。違いが出るのは<strong>呼ばれる順番</strong>です。
      <code>web.xml</code> に書いた場合は上から順、<code>@WebListener</code> の場合はコンテナ任せになります。
      「A が用意した値を B が使う」のように順番が意味を持つときは <code>web.xml</code> に書きます。
    </p>
<pre><code class="language-xml">&lt;listener&gt;
  &lt;listener-class&gt;com.example.servletsample.samples.advanced.AppLifecycleListener&lt;/listener-class&gt;
&lt;/listener&gt;</code></pre>
    <p>
      このサンプルは順番を問わないので <code>@WebListener</code> にしています。
      同じ理由で、このサイトの <code>common/CatalogInitializer</code>（サンプル一覧の読み込み）と
      <code>common/DatabaseInitializer</code>（組み込み DB の準備）も <code>@WebListener</code> です。
    </p>

    <h2>起動と停止の順番</h2>
<pre><code class="language-plaintext">起動 : contextInitialized → （リクエストが来る）→ Servlet の init → doGet / doPost
停止 : Servlet の destroy → contextDestroyed</code></pre>
    <p>
      <code>contextInitialized</code> は<strong>最初のリクエストより前</strong>に終わっています。
      「1 人目のアクセスだけ遅い」「起動はできたのに設定ミスに気付けない」を避けたい処理は、
      Servlet の <code>init()</code> ではなくこちらに置きます。
    </p>
    <p>
      <code>contextInitialized</code> で例外を投げると、<strong>アプリは起動しません</strong>。
      これは事故ではなく安全装置です。設定が読めていない状態で動き始めるより、
      起動時に止まってログに出た方が早く気付けます。
    </p>

    <h2>後始末を書かないとメモリが残る</h2>
    <p>
      起動時に作ったスレッドや接続は、<code>contextDestroyed</code> で必ず閉じます。
      閉じないままアプリを入れ替えると、古いクラスローダごとメモリに残り続けます。
      Tomcat のログに出る次の警告がその合図です。
    </p>
<pre><code class="language-plaintext">The web application [ROOT] appears to have started a thread named [...]
but has failed to stop it. This is very likely to create a memory leak.</code></pre>
    <p>
      このサイトでは <code>AsyncWorkerPool</code>（非同期サンプルのスレッドプール）と
      <code>DatabaseInitializer</code>（JDBC ドライバの登録解除）がこの後始末をしています。
    </p>

    <h2>sessionDestroyed はすぐには呼ばれない</h2>
    <p>
      ブラウザを閉じてもサーバには何も伝わりません。セッションが消えるのは、
      最後のアクセスから <code>&lt;session-timeout&gt;</code> の時間が過ぎたあと、
      コンテナが気付いたときです（Tomcat は数分おきに見回ります）。
      <code>session.invalidate()</code> を呼んだときだけ、その場で消えます。
    </p>
    <ul>
      <li>「いま何人が見ているか」を厳密に出すことはできません。あくまで目安です</li>
      <li>サーバを複数台に分けると、数えられるのは<strong>自分のサーバの分だけ</strong>です</li>
      <li>数えるだけのつもりでセッションの参照を貯めると、そのままメモリリークになります</li>
    </ul>

    <h2>リスナーに重い処理を書かない</h2>
    <p>
      <code>ServletRequestListener</code> と <code>HttpSessionAttributeListener</code> は
      <strong>アプリ全体</strong>で動きます。ここで DB を引いたり外部に問い合わせたりすると、
      すべての画面がその分だけ遅くなります。このサンプルも、記録しているのは
      メモリ上の小さなリストへの追記だけです。
    </p>
  </jsp:attribute>

  <jsp:body>

    <c:if test="${not empty flash}">
      <div class="alert alert-${flash.variant}">
        <strong>${fn:escapeXml(flash.title)}</strong> ${fn:escapeXml(flash.text)}
      </div>
    </c:if>

    <t:panel title="① アプリの起動（ServletContextListener）"
             note="AppLifecycleListener#contextInitialized が記録した内容です">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-3">
          <tbody>
            <tr>
              <th style="width: 14rem;">起動した時刻</th>
              <td><code>${fn:escapeXml(startedAt)}</code></td>
            </tr>
            <tr>
              <th>起動からの経過</th>
              <td>${uptimeSeconds} 秒</td>
            </tr>
            <tr>
              <th>Servlet コンテナ</th>
              <td><code>${fn:escapeXml(serverInfo)}</code></td>
            </tr>
            <tr>
              <th>作られたセッションの数</th>
              <td>${createdSessions} 個（起動してから合計）</td>
            </tr>
            <tr>
              <th>いま生きているセッション</th>
              <td>${activeSessions} 個</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mb-0 text-muted small">
        アプリを再起動すると、この表の値も下の記録も最初からやり直しになります。
        停止時の <code>contextDestroyed</code> は<strong>この画面には出せません</strong>。
        アプリが止まるところなので、記録を読みに来るリクエストがもう来ないためです
        （<code>docker compose logs -f tomcat</code> には出ます）。
      </p>
    </t:panel>

    <t:panel title="② セッションを動かしてみる（HttpSessionListener / HttpSessionAttributeListener）"
             note="操作するたびに、下の記録が増えます">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-3">
          <tbody>
            <tr>
              <th style="width: 14rem;">セッション ID</th>
              <td>
                <code>${fn:escapeXml(sessionId)}</code>
                <span class="text-muted small">（先頭だけ表示しています）</span>
              </td>
            </tr>
            <tr>
              <th>作られた時刻</th>
              <td><code>${fn:escapeXml(sessionCreatedAt)}</code></td>
            </tr>
            <tr>
              <th>前回のアクセス</th>
              <td><code>${fn:escapeXml(sessionAccessedAt)}</code></td>
            </tr>
            <tr>
              <th>無操作で切れるまで</th>
              <td>${sessionTimeout} 秒（<code>web.xml</code> の <code>&lt;session-timeout&gt;</code>）</td>
            </tr>
          </tbody>
        </table>
      </div>

      <c:if test="${not empty formError}">
        <div class="alert alert-danger">${fn:escapeXml(formError)}</div>
      </c:if>

      <form method="post" action="${ctx}/samples/advanced/listener" class="form-row align-items-end mb-3">
        <div class="form-group col-sm-4">
          <label for="attrName">名前（半角英数字）</label>
          <input type="text" class="form-control" id="attrName" name="name"
                 value="${fn:escapeXml(inputName)}" placeholder="color" maxlength="20">
          <small class="form-text text-muted"><code>demo.</code> を付けて入れます</small>
        </div>
        <div class="form-group col-sm-4">
          <label for="attrValue">値</label>
          <input type="text" class="form-control" id="attrValue" name="value"
                 value="${fn:escapeXml(inputValue)}" placeholder="blue" maxlength="30">
        </div>
        <div class="form-group col-sm-4">
          <button type="submit" class="btn btn-primary btn-block">セッションに入れる</button>
        </div>
      </form>

      <h3 class="h6">いま入っている値（この画面から入れた分だけ）</h3>
      <c:choose>
        <c:when test="${empty sessionAttributes}">
          <p class="text-muted">まだ何も入っていません。</p>
        </c:when>
        <c:otherwise>
          <ul class="list-group mb-3">
            <c:forEach var="name" items="${sessionAttributes}">
              <li class="list-group-item d-flex justify-content-between align-items-center">
                <code>${fn:escapeXml(name)}</code>
                <form method="post" action="${ctx}/samples/advanced/listener" class="m-0">
                  <input type="hidden" name="action" value="remove">
                  <input type="hidden" name="name"
                         value="${fn:escapeXml(fn:substringAfter(name, 'demo.'))}">
                  <button type="submit" class="btn btn-sm btn-outline-secondary">消す</button>
                </form>
              </li>
            </c:forEach>
          </ul>
        </c:otherwise>
      </c:choose>

      <form method="post" action="${ctx}/samples/advanced/listener" class="mb-0">
        <input type="hidden" name="action" value="invalidate">
        <button type="submit" class="btn btn-outline-danger">セッションを破棄する（invalidate）</button>
        <span class="text-muted small ml-2">
          入っている値の数だけ <code>attributeRemoved</code> が呼ばれ、最後に
          <code>sessionDestroyed</code> が呼ばれます
        </span>
      </form>
    </t:panel>

    <t:panel title="③ リスナーが書き留めた記録"
             note="新しいものが上。直近 ${maxEvents} 件だけ残します">
      <div class="d-flex justify-content-between align-items-center mb-2">
        <p class="text-muted small mb-0">
          同じ名前にもう一度入れると <code>attributeAdded</code> ではなく
          <code>attributeReplaced</code> になります。
          画面上部のメッセージもセッション経由で渡しているため、
          <code>servletSample.flash</code> の出入りが記録に混ざります。
        </p>
        <form method="post" action="${ctx}/samples/advanced/listener" class="m-0 ml-3">
          <input type="hidden" name="action" value="clear">
          <button type="submit" class="btn btn-sm btn-outline-secondary">記録を消す</button>
        </form>
      </div>

      <c:choose>
        <c:when test="${empty events}">
          <div class="alert alert-warning mb-0">
            記録がありません。リスナーが登録されているか確認してください
            （<code>@WebListener</code> または <code>web.xml</code> の <code>&lt;listener&gt;</code>）。
          </div>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <thead>
                <tr>
                  <th style="width: 3rem;">#</th>
                  <th style="width: 7rem;">時刻</th>
                  <th style="width: 6rem;">区分</th>
                  <th style="width: 15rem;">呼ばれたメソッド</th>
                  <th>内容</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="event" items="${events}">
                  <tr>
                    <td>${event.seq}</td>
                    <td><code>${fn:escapeXml(event.time)}</code></td>
                    <td>
                      <span class="badge badge-${event.kind.variant}">
                        ${fn:escapeXml(event.kind.label)}
                      </span>
                    </td>
                    <td><code>${fn:escapeXml(event.method)}</code></td>
                    <td>${fn:escapeXml(event.message)}</td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <t:panel title="④ 他のサンプルを開いてから戻ってくる"
             note="リスナーはアプリ全体に掛かっています">
      <p class="mb-0">
        別のタブで
        <a href="${ctx}/samples/session/login">ログインとログアウト</a> や
        <a href="${ctx}/samples/session/csrf">CSRF 対策</a> を操作してからこの画面を再読み込みすると、
        そちらがセッションに置いた値（<code>loginUser</code> や <code>csrfToken</code>）の出入りも
        記録に並びます。<strong>リスナーは自分のサンプルの中だけを見ているわけではありません。</strong>
        値そのものとセッション ID を記録に書いていないのは、ここに認証情報が流れてくるからです。
      </p>
    </t:panel>

  </jsp:body>
</t:sample>
