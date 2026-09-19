<%--
  【サンプル】モーダル (ダイアログ) の出し方 4 パターン

    ① ボタンを押したら開く                      … HTML と JavaScript だけで完結
    ② 処理のあとに完了モーダル                  … forward で戻ってきたときに開く
    ③ 画面遷移のあとにモーダル                  … リダイレクト先で開く (PRG パターン)
    ④ 確認 → 登録 → 完了モーダル → 画面遷移    … 知らせてから次の画面へ送る

  ② 〜 ④ は ModalDialogServlet が値をセットします。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="modal-dialog">

  <jsp:attribute name="explanation">
    <h2>4 つのパターンの使い分け</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>パターン</th><th>開くきっかけ</th><th>URL</th><th>向いている場面</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>① ボタンで開く</td>
            <td><code>data-toggle="modal"</code></td>
            <td>変わらない</td>
            <td>確認・注意書き・入力フォームなど、サーバに行く前の確認</td>
          </tr>
          <tr>
            <td>② 処理後の完了モーダル</td>
            <td>forward したページで JavaScript が開く</td>
            <td>POST したまま</td>
            <td>入力エラーで同じ画面に戻す場合（入力値をそのまま残せる）</td>
          </tr>
          <tr>
            <td>③ 画面遷移後のモーダル</td>
            <td>リダイレクト先で JavaScript が開く</td>
            <td>GET に変わる</td>
            <td>登録・更新・削除の完了通知（実務ではこれが基本）</td>
          </tr>
          <tr>
            <td>④ 確認 → 登録 → 完了モーダル → 画面遷移</td>
            <td>③ と同じ。閉じたときに次の画面へ移動する</td>
            <td>GET に変わり、さらに移動先へ</td>
            <td>登録したら一覧や詳細へ送る、入力の締めくくり</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h2>① ボタンを押したら開く</h2>
    <p>
      Bootstrap のモーダルは、<strong>開くボタン</strong>と<strong>中身</strong>の 2 つで出来ています。
      ボタンの <code>data-target</code> と、モーダル側の <code>id</code> を合わせるだけです。
      JavaScript を自分で書く必要はありません。
    </p>
<pre><code class="language-xml">&lt;!-- 開くボタン --&gt;
&lt;button type="button" data-toggle="modal" data-target="#confirmModal"&gt;削除する&lt;/button&gt;

&lt;!-- 中身 (画面のどこに置いてもよい) --&gt;
&lt;div class="modal fade" id="confirmModal" tabindex="-1" role="dialog"&gt;
  ...
&lt;/div&gt;</code></pre>

    <h2>② 処理のあとに完了モーダルを出す (forward)</h2>
    <p>
      Servlet が <code>request.setAttribute("resultTitle", ...)</code> で結果を入れて
      同じ JSP へ <code>forward</code> します。JSP 側は「結果が入っていればモーダルを書き出す」だけです。
      あとは読み込み後に JavaScript で開きます。
    </p>
<pre><code class="language-xml">&lt;c:if test="${'${not empty resultTitle}'}"&gt;
  &lt;div class="modal fade" id="resultModal" data-modal-autoshow&gt; ... &lt;/div&gt;
&lt;/c:if&gt;</code></pre>
    <p>
      注意点は <strong>URL が POST のまま</strong>だということです。
      完了モーダルを閉じたあとに再読み込みすると、ブラウザが「再送信しますか？」と聞いてきて、
      同じ処理が 2 回実行されてしまうおそれがあります。
    </p>

    <h2>③ 画面遷移のあとにモーダルを出す (PRG パターン)</h2>
    <p>
      登録・削除のあとは <strong>POST → リダイレクト → GET</strong> の流れにするのが定番です
      （Post / Redirect / Get の頭文字で PRG パターンと呼びます）。
      再読み込みしても GET が繰り返されるだけなので、二重登録が起きません。
    </p>
    <p>
      ただしリダイレクトすると別のリクエストになるため、<code>request.setAttribute</code> の値は消えます。
      そこで<strong>セッションにメッセージを預けて、次の 1 回だけ取り出して消す</strong>という受け渡しをします
      （フラッシュメッセージ）。この処理は <code>common/Flash.java</code> にまとめてあります。
    </p>
<pre><code class="language-java">// POST 側 : メッセージを預けてからリダイレクト
Flash.set(request, "success", "登録が完了しました", "受付番号は ... です。");
response.sendRedirect(request.getContextPath() + "/samples/design/modal-dialog");

// GET 側 : 取り出して request スコープへ移す (セッションからは消える)
Flash.consume(request);</code></pre>
    <p>
      一覧画面へ戻してから完了モーダルを出す、といった<strong>別の画面へ遷移させる場合</strong>も同じ方法で書けます。
      リダイレクト先を変えるだけです。このサンプル集では
      <a href="${ctx}/samples/file/file-upload">ファイルのアップロード</a> がこの形になっています。
      「完了を見せてから次の画面へ送りたい」場合は、続く ④ のように書きます。
    </p>

    <h2>④ 確認 → 登録 → 完了モーダル → 画面遷移</h2>
    <p>
      入力画面の締めくくりでよくある流れです。①（押したら確認）と ③（PRG で完了通知）を
      つなげ、最後に<strong>次の画面へ送る</strong>ところまでを 1 本にしています。
    </p>
<pre><code class="language-plaintext">［登録する］
   └→ 確認モーダル「よろしいですか？」
         └→ POST  (登録処理)
               └→ リダイレクト
                     └→ 完了モーダル「登録しました」
                           └→ 閉じる → 受付一覧へ移動</code></pre>

    <h3>移動先もフラッシュメッセージに預ける</h3>
    <p>
      ③ と違うのは、メッセージと一緒に<strong>移動先の URL</strong> も預けている点だけです。
      画面側は「移動先が入っていれば、閉じたときにそこへ行く」と書いておきます。
    </p>
<pre><code class="language-java">Flash.set(request, "success", "登録が完了しました",
        name + " さんを受付番号 " + receiptNumber + " で登録しました。",
        request.getContextPath() + "/samples/design/modal-dialog/entries");  // ← 移動先
response.sendRedirect(request.getContextPath() + "/samples/design/modal-dialog");</code></pre>

    <h3>閉じ方に関わらず移動させる</h3>
    <p>
      OK ボタンだけにリンクを張ると、<code>×</code> や <code>Esc</code> で閉じた人が
      その場に取り残されます。Bootstrap の <code>hidden.bs.modal</code>
      （閉じ終わったときに発生するイベント）を拾って、どの閉じ方でも移動するようにします。
    </p>
<pre><code class="language-javascript">$('[data-modal-next]').on('hidden.bs.modal', function () {
  window.location.href = $(this).data('modal-next');
});</code></pre>
    <p>
      OK ボタン自体は <code>&lt;a href="..."&gt;</code> にしてあります。
      JavaScript が動かない環境でも、リンクとしてなら移動できるためです。
    </p>

    <h3>なぜ「完了モーダル → 画面遷移」の順にするのか</h3>
    <ul>
      <li>
        <strong>先に遷移してしまうと結果が伝わりにくい</strong>：
        登録したのに何も出ないまま一覧が表示されると、成功したのか分かりません。
        受付番号のような「持ち帰ってほしい情報」がある場合はとくに困ります。
      </li>
      <li>
        <strong>それでも処理自体は先に終わらせる</strong>：
        モーダルを閉じたときに登録するのではなく、<strong>確認モーダルで実行した時点</strong>で
        登録まで終わらせます。閉じる操作を待つと、ブラウザを閉じられたときに登録されません。
      </li>
      <li>
        <strong>移動先は画面ではなくサーバが決める</strong>：
        「登録したら一覧へ」という業務の流れはサーバ側の判断なので、
        遷移先も Servlet が渡すようにしておくと、あとから変えるのが楽になります。
      </li>
    </ul>

    <h2>モーダルを開く JavaScript</h2>
    <p>
      サーバから渡された結果があるときだけ開きたいので、モーダルに目印
      (<code>data-modal-autoshow</code>) を付けておき、画面の読み込み後にまとめて開いています。
    </p>
<pre><code class="language-javascript">$(function () {
  $('[data-modal-autoshow]').modal('show');
});</code></pre>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>モーダルが開かない</strong>：
        jQuery → Bootstrap の順に読み込めているか、<code>data-target</code> と <code>id</code> が
        一致しているかを確認します（<code>#</code> の付け忘れが多いです）。
      </li>
      <li>
        <strong>モーダルの中のフォームが送信されない</strong>：
        モーダルの中に <code>&lt;form&gt;</code> を置くか、モーダルの外のフォームを
        <code>form="フォームのid"</code> 属性で指すかのどちらかにします。
        <code>&lt;form&gt;</code> の入れ子は無効です。
      </li>
      <li>
        <strong>閉じたあとにもう一度出てしまう</strong>：
        フラッシュメッセージを取り出したあとにセッションから消していないと、次の画面にも出続けます。
      </li>
      <li>
        <strong>移動先の URL を画面から受け取らない</strong>：
        <code>?next=...</code> のように<strong>利用者から</strong>渡された URL へそのまま移動すると、
        外部サイトへ飛ばされる踏み台になります（オープンリダイレクト）。
        ④ の移動先はサーバ側で決め打ちしています。
      </li>
      <li>
        <strong>表示する文字はエスケープする</strong>：
        サーバから渡した文字列をそのまま出すと HTML として解釈されます
        （<code>fn:escapeXml</code> を通します）。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // サーバ側の処理結果として書き出されたモーダルを開く (② 〜 ④ で使用)
      $(function () {
        $('[data-modal-autoshow]').modal('show');
      });

      // ④ 完了モーダルを閉じたら、預かっていた画面へ移動する
      //    (OK ボタンはリンクにしてあるので、× や Esc で閉じた場合の受け皿)
      $(function () {
        $('[data-modal-next]').on('hidden.bs.modal', function () {
          window.location.href = $(this).data('modal-next');
        });
      });

      // ① の「はい」を押したときの表示切り替え (この画面の中だけで完結する処理)
      $(function () {
        $('#confirmYes').on('click', function () {
          $('#confirmModal').modal('hide');
          $('#confirmResult').removeClass('d-none');
        });
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ============================================================
         ① ボタンを押したらモーダルを開く (サーバとのやり取りなし)
         ============================================================ --%>
    <t:panel title="① ボタンを押したらモーダルを開く" note="HTML と data 属性だけで動きます">
      <p>
        <code>data-toggle="modal"</code> と <code>data-target="#id"</code> を付けたボタンを押すと、
        同じ <code>id</code> のモーダルが開きます。JavaScript を書く必要はありません。
      </p>

      <button type="button" class="btn btn-outline-primary" data-toggle="modal" data-target="#infoModal">
        お知らせを表示
      </button>
      <button type="button" class="btn btn-outline-danger ml-2" data-toggle="modal" data-target="#confirmModal">
        削除の確認
      </button>

      <div id="confirmResult" class="alert alert-secondary mt-3 mb-0 d-none">
        「はい」が押されました（この画面の中だけで処理しています）。
      </div>
    </t:panel>

    <%-- ============================================================
         ② 処理のあとに完了モーダルを出す (forward)
         ============================================================ --%>
    <t:panel title="② 処理のあとに完了モーダルを出す" note="POST → forward : URL は変わりません">
      <p>
        送信すると Servlet が受付番号を作り、<strong>同じ画面へ forward</strong> して完了モーダルを開きます。
        アドレスバーは POST したときの URL のままです。
      </p>
      <form action="${ctx}/samples/design/modal-dialog" method="post" class="form-inline">
        <input type="hidden" name="action" value="forward">
        <label class="mr-2" for="forwardName">お名前</label>
        <input type="text" class="form-control mr-2" id="forwardName" name="name"
               placeholder="例: 山田太郎" size="20" maxlength="20">
        <button type="submit" class="btn btn-primary">送信する</button>
      </form>
    </t:panel>

    <%-- ============================================================
         ③ 画面遷移のあとにモーダルを出す (PRG パターン)
         ============================================================ --%>
    <t:panel title="③ 画面遷移のあとにモーダルを出す" note="POST → リダイレクト → GET : 再読み込みしても安全">
      <p>
        送信すると Servlet がメッセージをセッションに預けてリダイレクトし、
        <strong>移動した先</strong>で完了モーダルを開きます。
        完了後に再読み込みしても、登録が繰り返されることはありません。
      </p>
      <form action="${ctx}/samples/design/modal-dialog" method="post" class="form-inline">
        <input type="hidden" name="action" value="redirect">
        <label class="mr-2" for="redirectName">お名前</label>
        <input type="text" class="form-control mr-2" id="redirectName" name="name"
               placeholder="例: 山田太郎" size="20" maxlength="20">
        <button type="submit" class="btn btn-primary">送信する</button>
      </form>
    </t:panel>

    <%-- ============================================================
         ④ 確認モーダル → 登録 → 完了モーダル → 画面遷移
         ============================================================ --%>
    <t:panel title="④ 確認 → 登録 → 完了モーダル → 画面遷移"
             note="実務でよくある一連の流れ">
      <p>
        登録ボタンで<strong>確認モーダル</strong>を出し、実行したら登録して
        <strong>完了モーダル</strong>で知らせ、閉じたら<strong>受付一覧へ移動</strong>します。
        ①（確認）と ③（PRG）を組み合わせた形です。
      </p>
      <form id="registerForm" action="${ctx}/samples/design/modal-dialog" method="post" class="form-inline">
        <input type="hidden" name="action" value="move">
        <label class="mr-2" for="moveName">お名前</label>
        <input type="text" class="form-control mr-2" id="moveName" name="name"
               placeholder="例: 山田太郎" size="20" maxlength="20">
        <button type="button" class="btn btn-success" data-toggle="modal" data-target="#registerModal">
          登録する
        </button>
      </form>
      <p class="text-muted small mt-3 mb-0">
        登録した内容は
        <a href="${ctx}/samples/design/modal-dialog/entries">受付一覧</a>
        （セッションに保存。見えるのは自分の分だけです）で確認できます。
      </p>
    </t:panel>

    <%-- ============================================================
         モーダルの中身
         ============================================================ --%>

    <%-- ① お知らせ (閉じるだけ) --%>
    <div class="modal fade" id="infoModal" tabindex="-1" role="dialog"
         aria-labelledby="infoModalTitle" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="infoModalTitle">お知らせ</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <p class="mb-0">
              これは <code>data-toggle="modal"</code> だけで開いたモーダルです。
              サーバへのリクエストは発生していません。
            </p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">閉じる</button>
          </div>
        </div>
      </div>
    </div>

    <%-- ① 確認 (はい / いいえ) --%>
    <div class="modal fade" id="confirmModal" tabindex="-1" role="dialog"
         aria-labelledby="confirmModalTitle" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="confirmModalTitle">削除の確認</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <p class="mb-0">このデータを削除します。よろしいですか？</p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">いいえ</button>
            <button type="button" class="btn btn-danger" id="confirmYes">はい</button>
          </div>
        </div>
      </div>
    </div>

    <%-- ④ 登録の確認 (押すと外にあるフォームを送信する) --%>
    <div class="modal fade" id="registerModal" tabindex="-1" role="dialog"
         aria-labelledby="registerModalTitle" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="registerModalTitle">登録の確認</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <p class="mb-0">入力した内容で登録します。よろしいですか？</p>
            <p class="text-muted small mt-2 mb-0">登録すると受付一覧へ移動します。</p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">キャンセル</button>
            <%-- form 属性を使うと、モーダルの外にあるフォームを送信できる --%>
            <button type="submit" class="btn btn-success" form="registerForm">登録する</button>
          </div>
        </div>
      </div>
    </div>

    <%-- ② forward で戻ってきたときだけ書き出される完了モーダル --%>
    <c:if test="${not empty resultTitle}">
      <div class="modal fade" id="resultModal" tabindex="-1" role="dialog"
           aria-labelledby="resultModalTitle" aria-hidden="true" data-modal-autoshow>
        <div class="modal-dialog modal-dialog-centered" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="resultModalTitle">
                <t:icon name="check-circle" cssClass="text-success mr-2" />${fn:escapeXml(resultTitle)}
              </h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p class="mb-0">${fn:escapeXml(resultText)}</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-primary" data-dismiss="modal">OK</button>
            </div>
          </div>
        </div>
      </div>
    </c:if>

    <%-- ③ / ④ リダイレクト後にフラッシュメッセージがあるときだけ書き出される完了モーダル。
         ④ では移動先 (flash.nextUrl) も預かっているので、閉じたらその画面へ移動する。 --%>
    <c:if test="${not empty flash}">
      <div class="modal fade" id="flashModal" tabindex="-1" role="dialog"
           aria-labelledby="flashModalTitle" aria-hidden="true" data-modal-autoshow
           <c:if test="${not empty flash.nextUrl}">data-modal-next="${fn:escapeXml(flash.nextUrl)}"</c:if>>
        <div class="modal-dialog modal-dialog-centered" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="flashModalTitle">
                <t:icon name="check-circle" cssClass="text-${flash.variant} mr-2" />${fn:escapeXml(flash.title)}
              </h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p class="mb-0">${fn:escapeXml(flash.text)}</p>
              <c:choose>
                <c:when test="${not empty flash.nextUrl}">
                  <p class="text-muted small mt-3 mb-0">
                    閉じる操作（OK・×・Esc）のどれでも受付一覧へ移動します。
                  </p>
                </c:when>
                <c:otherwise>
                  <p class="text-muted small mt-3 mb-0">
                    アドレスバーの URL が <code>POST</code> から <code>GET</code> に変わっていること、
                    このまま再読み込みしても「再送信しますか？」と聞かれないことを確認してみてください。
                  </p>
                </c:otherwise>
              </c:choose>
            </div>
            <div class="modal-footer">
              <c:choose>
                <c:when test="${not empty flash.nextUrl}">
                  <%-- JavaScript が動かない環境でも移動できるよう、OK はリンクにしておく --%>
                  <a class="btn btn-${flash.variant}" href="${fn:escapeXml(flash.nextUrl)}">
                    OK（受付一覧へ）
                  </a>
                </c:when>
                <c:otherwise>
                  <button type="button" class="btn btn-${flash.variant}" data-dismiss="modal">OK</button>
                </c:otherwise>
              </c:choose>
            </div>
          </div>
        </div>
      </div>
    </c:if>
  </jsp:body>
</t:sample>
