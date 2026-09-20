<%--
  【サンプル】リクエストパラメータの受け取り方

  画面から送られてきた値を Servlet で受け取る方法を、3 つのメソッドで見比べます。
    getParameter       … 1 つの値 (String。無ければ null)
    getParameterValues … 同じ名前で複数送られた値 (String[])
    getParameterMap    … 届いたものすべて (Map<String, String[]>)

  RequestParameterServlet が次の値をセットします。
    paramRows        … フォームの項目ごとの受け取り結果 (ParameterRow)
    mapRows          … getParameterMap の中身
    sizeResult       … 表示件数を数値に変換した結果 (NumberResult)
    newsletterChecked… hidden 併用チェックボックスの判定結果
    submitted / requestMethod / queryStringText / contentTypeText / encodingText
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="demoUrl" value="${ctx}/samples/basic/request-parameter" />
<%-- チェックボックスの再表示用。前後を区切り文字で挟んでおくと ",java," で部分一致を判定できる --%>
<c:set var="checkedInterests" value=",${fn:join(paramValues.interests, ',')}," />
<t:sample sampleId="request-parameter">

  <jsp:attribute name="explanation">
    <h2>値を受け取る 3 つのメソッド</h2>
    <p>
      画面から送られてきた値（リクエストパラメータ）を読む入り口は、次の 3 つだけです。
      どれも戻り値は <strong>文字列</strong>で、型変換と内容の検査はこちら側の仕事になります。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>メソッド</th><th>戻り値</th><th>無いとき</th><th>使いどころ</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>getParameter(name)</code></td>
            <td><code>String</code></td>
            <td><code>null</code></td>
            <td>ふつうの入力項目。値が複数あっても<strong>先頭の 1 つ</strong>しか返りません</td>
          </tr>
          <tr>
            <td><code>getParameterValues(name)</code></td>
            <td><code>String[]</code></td>
            <td><code>null</code>（空配列ではない）</td>
            <td>チェックボックスなど、同じ名前で複数送られる項目</td>
          </tr>
          <tr>
            <td><code>getParameterMap()</code></td>
            <td><code>Map&lt;String, String[]&gt;</code></td>
            <td>空の Map</td>
            <td>「実際に何が届いたのか」の確認。デバッグで役に立ちます</td>
          </tr>
        </tbody>
      </table>
    </div>
<pre><code class="language-java">// ① 1 つの値を取る : 戻り値は必ず String。パラメータが無ければ null
String keyword = request.getParameter("keyword");

// ② 同じ名前で複数送られる値を取る : 戻り値は String[]。無ければ null (空配列ではない)
String[] interests = request.getParameterValues("interests");

// ③ 届いたものを全部見る : 戻り値は変更できない Map
Map&lt;String, String[]&gt; all = request.getParameterMap();</code></pre>

    <h2>処理の流れ</h2>
    <ol>
      <li>画面のフォームを送信する（GET ならクエリ文字列、POST ならリクエスト本文に載る）</li>
      <li><code>@WebServlet</code> で URL を割り当てた Servlet の
        <code>doGet</code> / <code>doPost</code> が呼ばれる</li>
      <li><code>getParameter</code> などで値を取り出し、<strong>null 検査と型変換</strong>を行う</li>
      <li>画面に出す形に詰め替えて <code>request.setAttribute</code> する</li>
      <li>JSP へ <code>forward</code> し、<code>${'${...}'}</code> で表示する</li>
    </ol>
    <p>
      このサンプルでは 3 のところで
      <code>ParameterRow</code>（1 項目分の受け取り結果）という小さなクラスに詰め替えています。
      「受け取った生の値」と「画面に出す形」を分けておくと、
      <code>null</code> と空文字の区別のような細かい話を JSP に持ち込まずに済みます。
    </p>

    <h2>「届いていない（null）」と「空文字」は別もの</h2>
    <p>
      入力欄を空のまま送信した場合、パラメータ自体は送られてきて
      <strong>中身が空文字（長さ 0 の文字列）</strong>になります。
      一方、入力欄がそもそも無かった・チェックされなかった場合は
      <strong>パラメータ自体が届かず <code>null</code></strong> になります。
      この 2 つを取り違えると <code>NullPointerException</code> の原因になります。
    </p>
<pre><code class="language-java">String name = request.getParameter("name");

if (name == null) {
    // 入力欄が無かった / 未チェック / URL に書かれていない
} else if (name.isEmpty()) {
    // 入力欄はあったが、空のまま送信された
}

// 実務では、この 2 つをまとめて「未入力」として扱うことがほとんどです
boolean blank = (name == null || name.trim().isEmpty());</code></pre>
    <p>
      先に <code>name.equals("")</code> と書いてしまうと、届かなかったときに落ちます。
      <code>"".equals(name)</code> のように<strong>定数を左に置く</strong>か、
      上のように <code>null</code> を先に判定します。
      全角スペースも消したい場合は <code>trim()</code> ではなく
      <code>strip()</code>（Java 11 以降）を使います。
    </p>

    <h2>チェックボックスは、未チェックだと何も送られてこない</h2>
    <p>
      チェックされていないチェックボックスは、<strong>パラメータそのものが送信されません</strong>。
      「チェックを外した」という情報は届かないので、
      更新画面などで「外したのに元のままになる」という不具合になりがちです。
    </p>
    <p>
      対策は、<strong>同じ名前の hidden を手前に置く</strong>方法です。
      チェックされていれば 2 つ、されていなければ 1 つ届くので、
      「届いたかどうか」ではなく「最後の値が何か」で判定できます。
    </p>
<pre><code class="language-xml">&lt;!-- 順番が大事 : hidden を先に、チェックボックスを後に置く --&gt;
&lt;input type="hidden"   name="newsletter" value="off"&gt;
&lt;input type="checkbox" name="newsletter" value="on"&gt;</code></pre>
<pre><code class="language-java">String[] values = request.getParameterValues("newsletter");
// チェックあり : ["off", "on"]  /  チェックなし : ["off"]
boolean checked = values != null &amp;&amp; "on".equals(values[values.length - 1]);

// getParameter("newsletter") は先頭の "off" を返すので、この書き方では使えません</code></pre>
    <p>
      hidden を別名（<code>newsletterSent=1</code> など）にして
      「フォームが送信されたこと」だけを伝える方法もあります。
      このサンプルの GET フォームでは、そちらの形で
      <code>form=get</code> という hidden を使っています
      （最初の表示と「空欄のまま検索した」を見分けるためです）。
    </p>

    <h2>複数の値は getParameterValues で受け取る</h2>
    <p>
      チェックボックスを複数選んだときや、同じ名前の入力欄が並んでいるときは、
      同じ名前で複数の値が届きます。<code>getParameter</code> では
      <strong>先頭の 1 つ</strong>しか取れません。
    </p>
<pre><code class="language-plaintext">?interests=java&amp;interests=db&amp;interests=infra

getParameter("interests")       → "java"                   ← 先頭だけ
getParameterValues("interests") → ["java", "db", "infra"]  ← 全部</code></pre>
    <p>
      戻り値は「無いときは空配列」ではなく <strong><code>null</code></strong> です。
      そのまま <code>for</code> で回すと落ちるので、
      受け取った直後に空のリストへ置き換えておくと後ろが書きやすくなります。
    </p>
<pre><code class="language-java">String[] raw = request.getParameterValues("interests");
List&lt;String&gt; interests = (raw == null) ? List.of() : List.of(raw);</code></pre>
    <p>
      値は利用者が自由に送れるので、<strong>想定した値だけを通す</strong>検査も必要です
      （画面に出していない値でも、URL を書き換えれば送れてしまいます）。
    </p>

    <h2>届いたものを全部見る（getParameterMap）</h2>
    <p>
      「送っているはずの値が取れない」というときは、名前を指定して探す前に
      <code>getParameterMap()</code> で<strong>実際に届いたもの</strong>を見ると早く解決します。
      名前の打ち間違いや、<code>name</code> 属性の書き忘れがすぐ分かります。
    </p>
<pre><code class="language-java">for (Map.Entry&lt;String, String[]&gt; entry : request.getParameterMap().entrySet()) {
    System.out.println(entry.getKey() + " = " + Arrays.toString(entry.getValue()));
}</code></pre>
    <p>
      返ってくる Map は<strong>変更できません</strong>。
      <code>put</code> や <code>remove</code> を呼ぶと
      <code>UnsupportedOperationException</code> になります。
      加工したい場合は <code>new LinkedHashMap&lt;&gt;(request.getParameterMap())</code> のように
      コピーしてから扱います。
    </p>

    <h2>数値への変換は、必ず例外対策をする</h2>
    <p>
      <code>?size=10</code> のつもりでも、利用者は <code>?size=abc</code> でも
      <code>?size=-1</code> でも <code>?size=99999999999999</code> でも送れます。
      <code>Integer.parseInt</code> は変換できないと
      <code>NumberFormatException</code>（実行時例外）を投げるので、
      <strong>受け取ったその場で受け止めて</strong>、後ろの処理には正しい値だけを渡します。
    </p>
<pre><code class="language-java">int size = 10;                           // 既定値を先に決めておく
String raw = request.getParameter("size");

if (raw != null &amp;&amp; !raw.trim().isEmpty()) {
    try {
        size = Integer.parseInt(raw.trim());   // " 10" は失敗するので trim しておく
    } catch (NumberFormatException e) {
        size = 10;                             // 数字以外が送られてきた
    }
}
size = Math.min(Math.max(size, 1), 100);       // 範囲も決めておく</code></pre>
    <p>次のものはすべて <code>NumberFormatException</code> になります。</p>
    <ul>
      <li>数字以外（<code>abc</code>、<code>1,000</code>、<code>10 件</code>）</li>
      <li>小数（<code>1.5</code>）… <code>Integer.parseInt</code> は小数点を受け付けません</li>
      <li><code>int</code> に収まらない桁数（<code>2147483648</code> 以上）… 桁あふれも例外です</li>
      <li>前後に空白の付いた <code>" 10"</code> … だから先に <code>trim()</code> しておきます</li>
    </ul>
    <p>
      逆に、<strong>意外と通ってしまうもの</strong>もあります。
      全角数字の <code>１０</code> は、<code>Integer.parseInt</code> が <strong>10 として受け取ります</strong>
      （内部で使われている <code>Character.digit</code> が、全角数字も数字とみなすためです）。
      <code>+10</code> も 10 になります。
      「変換できた＝業務的に正しい値」ではないので、
      <strong>範囲の検査は変換とは別に必ず行います</strong>。
      画面に出し直すときも、送られてきた文字列ではなく<strong>変換後の値</strong>を表示すると、
      全角のまま残って混乱する、ということが起きません。
    </p>
    <p>
      なお <code>null</code> を渡した場合も <code>NumberFormatException</code> です
      （<code>NullPointerException</code> ではありません）。
      <code>try</code> の中に入れてしまえばどちらも拾えますが、
      「未入力」と「数字でない」は利用者に見せるメッセージが変わるので、
      分けて判定しておくと親切です。
    </p>

    <h2>GET と POST の違い</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th></th><th>GET</th><th>POST</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>値の載る場所</td>
            <td>URL のクエリ文字列（<code>?a=1&amp;b=2</code>）</td>
            <td>リクエスト本文</td>
          </tr>
          <tr>
            <td>URL に残るか</td>
            <td>残る（アクセスログ・履歴にも残る）</td>
            <td>残らない</td>
          </tr>
          <tr>
            <td>長さの上限</td>
            <td>実質あり（サーバ・ブラウザ次第。数千文字で切られることがある）</td>
            <td>実質なし（サーバ設定次第。ファイルも送れる）</td>
          </tr>
          <tr>
            <td>再読み込み</td>
            <td>そのまま取り直すだけ</td>
            <td>「再送信しますか？」が出る（二重登録の原因）</td>
          </tr>
          <tr>
            <td>ブックマーク・共有</td>
            <td>できる</td>
            <td>できない</td>
          </tr>
          <tr>
            <td>向いている用途</td>
            <td>検索・一覧・絞り込みなど<strong>読むだけ</strong>の処理</td>
            <td>登録・更新・削除など<strong>状態を変える</strong>処理</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      パスワードや個人情報を GET で送ると、URL としてブラウザの履歴・
      サーバのアクセスログ・<code>Referer</code> ヘッダに残ります。
      こうした値は POST で送ります。
    </p>
    <p>
      登録処理を POST で受けたあとは、そのまま画面を返さずに
      <strong>リダイレクトしてから GET で表示し直す</strong>のが定番です（PRG パターン）。
      再読み込みによる二重登録を防げます。詳しくは
      <a href="${ctx}/samples/design/modal-dialog">モーダルの出し方</a>のサンプルで扱っています。
    </p>

    <h2>文字化けと文字コードの設定</h2>
    <p>
      受け取った日本語が文字化けするときは、<strong>どのバイト列をどの文字コードとして読むか</strong>の
      設定が合っていません。Servlet 4.0 以降は <code>web.xml</code> に 1 行書くだけで済みます。
    </p>
<pre><code class="language-xml">&lt;!-- web.xml : POST 本文をこの文字コードとして読む --&gt;
&lt;request-character-encoding&gt;UTF-8&lt;/request-character-encoding&gt;
&lt;response-character-encoding&gt;UTF-8&lt;/response-character-encoding&gt;</code></pre>
    <p>この設定が無いコンテナでは、自分で指定します。</p>
<pre><code class="language-java">// 値を 1 つでも読む前に呼ぶこと (読んだあとでは手遅れ)
request.setCharacterEncoding("UTF-8");
String name = request.getParameter("name");</code></pre>
    <ul>
      <li>
        <strong>呼ぶ順番が肝心</strong>：<code>getParameter</code> を 1 回でも呼ぶと、
        その時点で本文の解析が済んでしまい、あとから
        <code>setCharacterEncoding</code> を呼んでも効きません。
        毎回書くのが面倒であれば、フィルタか <code>web.xml</code> の設定にまとめます。
      </li>
      <li>
        <strong>GET は別の設定で決まる</strong>：クエリ文字列の文字コードは
        <code>setCharacterEncoding</code> では変わらず、コンテナ側の設定
        （Tomcat なら <code>URIEncoding</code>）に従います。
        Tomcat 8.5 / 9 は既定で UTF-8 ですが、それより前のバージョンでは
        <code>ISO-8859-1</code> が既定でした。古い環境を引き継ぐときは確認しておくと安全です。
      </li>
      <li>
        <strong>画面側も揃える</strong>：JSP の <code>contentType="text/html; charset=UTF-8"</code> と
        ファイル自体の保存文字コードが違っていても化けます。
      </li>
    </ul>

    <h2>JSP からは EL で直接取れる</h2>
    <p>
      表示するだけなら Servlet を通さず、EL の暗黙オブジェクトで取り出せます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>EL</th><th>同じことをする Java</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>${'${param.keyword}'}</code></td>
            <td><code>request.getParameter("keyword")</code></td>
          </tr>
          <tr>
            <td><code>${'${paramValues.interests}'}</code></td>
            <td><code>request.getParameterValues("interests")</code></td>
          </tr>
          <tr>
            <td><code>${'${paramValues.interests[0]}'}</code></td>
            <td><code>request.getParameterValues("interests")[0]</code></td>
          </tr>
          <tr>
            <td><code>${'${fn:length(paramValues.interests)}'}</code></td>
            <td><code>values == null ? 0 : values.length</code></td>
          </tr>
        </tbody>
      </table>
    </div>
    <ul>
      <li>
        <strong>EL は落ちません</strong>：届いていない名前を書いても例外にならず、
        何も表示されないだけです。安全ですが、名前を間違えても気づきにくいということでもあります。
      </li>
      <li>
        <strong>EL では null と空文字を区別できません</strong>：
        <code>${'${empty param.name}'}</code> はどちらの場合も <code>true</code> です。
        区別が必要な処理は Java 側で書きます。
      </li>
      <li>
        <strong>EL は自動でエスケープしません</strong>：
        入力値をそのまま出すとスクリプトを埋め込まれます（XSS）。
        <code>${'${fn:escapeXml(param.name)}'}</code> か <code>&lt;c:out&gt;</code> を通します。
      </li>
      <li>
        <strong>入力欄の再表示</strong>：送信し直したときに値を残すには、
        <code>value="${'${fn:escapeXml(param.keyword)}'}"</code> のように書きます。
        チェックボックスは、いったん区切り文字で挟んだ文字列にしてから部分一致で調べると簡単です。
        ただし、値そのものに区切り文字（下の例では <code>,</code>）が入りうる場合は
        誤判定するので、区切り文字は値に出てこない文字を選びます。
<pre><code class="language-xml">&lt;c:set var="checked" value=",${'${fn:join(paramValues.interests, \',\')}'}," /&gt;
&lt;input type="checkbox" name="interests" value="java"
       ${'${fn:contains(checked, \',java,\') ? \'checked\' : \'\'}'}&gt;</code></pre>
      </li>
    </ul>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong><code>name</code> 属性の書き忘れ</strong>：
        送信されるのは <code>id</code> ではなく <code>name</code> です。
        <code>id</code> だけ書いた入力欄は、値が入っていても一切送られません。
        「取れない」と思ったら <code>getParameterMap()</code> を出してみてください。
      </li>
      <li>
        <strong><code>disabled</code> にした欄は送られない</strong>：
        画面上はグレーで値が見えていても送信されません。
        値は送りたいが編集させたくない場合は <code>readonly</code> を使います。
      </li>
      <li>
        <strong>ラジオボタンは 1 つも選ばなければ <code>null</code></strong>：
        既定で 1 つ <code>checked</code> にしておくか、未選択を受け止める作りにします。
      </li>
      <li>
        <strong>セレクトの「選択なし」は空文字</strong>：
        <code>&lt;option value=""&gt;選択してください&lt;/option&gt;</code> を選ぶと、
        <code>null</code> ではなく空文字が届きます。
      </li>
      <li>
        <strong>送信ボタンの値も送られる</strong>：
        <code>&lt;button name="action" value="delete"&gt;</code> のように書けば、
        押されたボタンを <code>getParameter("action")</code> で判別できます
        （押されなかったボタンの値は送られません）。
      </li>
      <li>
        <strong>ファイル送信のフォームでは <code>getParameter</code> が使えない</strong>：
        <code>enctype="multipart/form-data"</code> のフォームは形式が違うため、
        <code>@MultipartConfig</code> と <code>getPart</code> で受け取ります
        （<a href="${ctx}/samples/file/file-upload">ファイルのアップロード</a>のサンプル）。
      </li>
      <li>
        <strong>hidden の値も利用者が書き換えられる</strong>：
        画面に出していない値でも、開発者ツールや URL 経由で自由に変更できます。
        金額・権限・ID のような重要な値は、hidden の値をそのまま信用せず、
        サーバ側で持っている情報と突き合わせます。
      </li>
      <li>
        <strong>同じ URL で GET と POST の両方を受ける</strong>：
        メソッドごとに <code>doGet</code> / <code>doPost</code> が呼び分けられます。
        フォームを <code>method="post"</code> で送るのに <code>doPost</code> を実装していないと、
        <code>HttpServlet</code> の既定の動きで
        <strong>405 Method Not Allowed</strong> が返ります
        （処理を <code>doGet</code> の側に書いてしまったときに起きがちです）。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <%-- ============================================================
         ① GET のフォーム (値は URL のクエリ文字列に載る)
         ============================================================ --%>
    <t:panel title="① GET で送ってみる" note='method="get" : 値が URL に残ります'>
      <form action="${demoUrl}" method="get" class="form-row align-items-end">
        <%-- 「送信された」という事実を伝えるための hidden。
             これが無いと、最初の表示と「空欄のまま検索した」を区別できない --%>
        <input type="hidden" name="form" value="get">

        <div class="form-group col-md-5 mb-2">
          <label for="keyword">キーワード</label>
          <input type="text" class="form-control" id="keyword" name="keyword"
                 value="${fn:escapeXml(param.keyword)}" placeholder="例: 検索する文字列">
        </div>

        <div class="form-group col-md-3 mb-2">
          <label for="size">表示件数</label>
          <%-- わざと type="text" にしてあります。数値以外を送ったときの動きを見るためです --%>
          <input type="text" class="form-control" id="size" name="size"
                 value="${fn:escapeXml(param.size)}" placeholder="例: 20">
        </div>

        <div class="form-group col-md-4 mb-2">
          <button type="submit" class="btn btn-primary">
            <t:icon name="search" cssClass="mr-1" />GET で送信
          </button>
          <a class="btn btn-link" href="${demoUrl}">クリア</a>
        </div>
      </form>
      <p class="text-muted small mb-0">
        送信するとアドレスバーが
        <code>?form=get&amp;keyword=...&amp;size=...</code> になります。
        そのまま URL を書き換えて送り直すこともできます
        （利用者は<strong>何でも送れる</strong>、ということでもあります）。
      </p>
    </t:panel>

    <%-- ============================================================
         ② POST のフォーム (いろいろな入力部品を一通り)
         ============================================================ --%>
    <t:panel title="② POST で送ってみる" note='method="post" : 値はリクエスト本文に載ります'>
      <form action="${demoUrl}" method="post">
        <input type="hidden" name="form" value="post">

        <div class="form-group">
          <label for="name">氏名（テキスト）</label>
          <input type="text" class="form-control" id="name" name="name"
                 value="${fn:escapeXml(param.name)}" placeholder="例: 山田太郎" maxlength="40">
          <small class="form-text text-muted">
            空のまま送ると「空文字」が届きます（<code>null</code> ではありません）。
          </small>
        </div>

        <div class="form-group">
          <span class="d-block mb-1">性別（ラジオボタン）</span>
          <%-- あえて既定の checked を付けていません。未選択だとパラメータ自体が届きません --%>
          <div class="custom-control custom-radio custom-control-inline">
            <input type="radio" class="custom-control-input" id="genderMale" name="gender" value="male"
                   ${param.gender eq 'male' ? 'checked' : ''}>
            <label class="custom-control-label" for="genderMale">男性</label>
          </div>
          <div class="custom-control custom-radio custom-control-inline">
            <input type="radio" class="custom-control-input" id="genderFemale" name="gender" value="female"
                   ${param.gender eq 'female' ? 'checked' : ''}>
            <label class="custom-control-label" for="genderFemale">女性</label>
          </div>
          <div class="custom-control custom-radio custom-control-inline">
            <input type="radio" class="custom-control-input" id="genderOther" name="gender" value="other"
                   ${param.gender eq 'other' ? 'checked' : ''}>
            <label class="custom-control-label" for="genderOther">回答しない</label>
          </div>
          <small class="form-text text-muted">
            1 つも選ばずに送ると <code>gender</code> は届きません（<code>null</code>）。
          </small>
        </div>

        <div class="form-group">
          <span class="d-block mb-1">興味のある分野（チェックボックス・複数選択）</span>
          <div class="custom-control custom-checkbox custom-control-inline">
            <input type="checkbox" class="custom-control-input" id="interestJava" name="interests" value="java"
                   ${fn:contains(checkedInterests, ',java,') ? 'checked' : ''}>
            <label class="custom-control-label" for="interestJava">Java</label>
          </div>
          <div class="custom-control custom-checkbox custom-control-inline">
            <input type="checkbox" class="custom-control-input" id="interestDb" name="interests" value="db"
                   ${fn:contains(checkedInterests, ',db,') ? 'checked' : ''}>
            <label class="custom-control-label" for="interestDb">データベース</label>
          </div>
          <div class="custom-control custom-checkbox custom-control-inline">
            <input type="checkbox" class="custom-control-input" id="interestDesign" name="interests" value="design"
                   ${fn:contains(checkedInterests, ',design,') ? 'checked' : ''}>
            <label class="custom-control-label" for="interestDesign">画面デザイン</label>
          </div>
          <div class="custom-control custom-checkbox custom-control-inline">
            <input type="checkbox" class="custom-control-input" id="interestInfra" name="interests" value="infra"
                   ${fn:contains(checkedInterests, ',infra,') ? 'checked' : ''}>
            <label class="custom-control-label" for="interestInfra">インフラ</label>
          </div>
          <small class="form-text text-muted">
            同じ名前で複数届きます。<code>getParameterValues</code> でなければ全部は取れません。
          </small>
        </div>

        <div class="form-group">
          <label for="pref">都道府県（セレクト）</label>
          <c:set var="prefs" value="北海道,東京都,愛知県,大阪府,福岡県" />
          <select class="form-control" id="pref" name="pref">
            <option value="">選択してください</option>
            <c:forEach var="pref" items="${fn:split(prefs, ',')}">
              <option value="${fn:escapeXml(pref)}"
                      ${param.pref eq pref ? 'selected' : ''}>${fn:escapeXml(pref)}</option>
            </c:forEach>
          </select>
          <small class="form-text text-muted">
            「選択してください」のまま送ると、<code>null</code> ではなく<strong>空文字</strong>が届きます。
          </small>
        </div>

        <div class="form-group">
          <label for="memo">自由記述（テキストエリア）</label>
          <textarea class="form-control" id="memo" name="memo" rows="3"
                    placeholder="改行を入れて送ってみてください">${fn:escapeXml(param.memo)}</textarea>
        </div>

        <div class="form-group">
          <%-- hidden を先に置くと、チェックを外したことも伝わる (値は ["off"] だけ届く) --%>
          <input type="hidden" name="newsletter" value="off">
          <div class="custom-control custom-checkbox">
            <input type="checkbox" class="custom-control-input" id="newsletter" name="newsletter" value="on"
                   ${newsletterChecked ? 'checked' : ''}>
            <label class="custom-control-label" for="newsletter">メール配信を希望する（hidden 併用）</label>
          </div>
          <small class="form-text text-muted">
            チェックあり → <code>["off", "on"]</code> ／ チェックなし → <code>["off"]</code>。
            <code>getParameter</code> はどちらでも先頭の <code>"off"</code> を返します。
          </small>
        </div>

        <button type="submit" class="btn btn-primary">
          <t:icon name="check-circle" cssClass="mr-1" />POST で送信
        </button>
        <a class="btn btn-link" href="${demoUrl}">クリア</a>
      </form>
    </t:panel>

    <%-- ============================================================
         受け取った値の表示
         ============================================================ --%>
    <c:if test="${not submitted}">
      <div class="alert alert-info">
        まだフォームから送信されていません。上の ① か ② から送信すると、
        受け取った値がここから下に表示されます。
      </div>
    </c:if>

    <t:panel title="③ このリクエストの情報" note="GET と POST で何が違うかを見てください">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <tbody>
            <tr>
              <th scope="row" class="w-25">HTTP メソッド</th>
              <td><code>${fn:escapeXml(requestMethod)}</code></td>
            </tr>
            <tr>
              <th scope="row">クエリ文字列<br><span class="small text-muted font-weight-normal">getQueryString()</span></th>
              <td>
                <code>${empty queryStringText ? 'null（本文で送られたか、何も送られていない）'
                        : fn:escapeXml(queryStringText)}</code>
                <span class="d-block text-muted small mt-1">
                  forward したあとの JSP から <code>getQueryString()</code> を呼ぶと
                  転送先（JSP）のものが返るため、Servlet 側で取っておいた値です。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">Content-Type<br><span class="small text-muted font-weight-normal">getContentType()</span></th>
              <td>
                <code>${empty contentTypeText ? 'null（GET には本文が無い）'
                        : fn:escapeXml(contentTypeText)}</code>
                <span class="d-block text-muted small mt-1">
                  POST のときは <code>application/x-www-form-urlencoded</code> です。
                  ファイル送信のフォームだと <code>multipart/form-data</code> になり、
                  <code>getParameter</code> では受け取れません。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">文字コード<br><span class="small text-muted font-weight-normal">getCharacterEncoding()</span></th>
              <td>
                <code>${empty encodingText ? 'null' : fn:escapeXml(encodingText)}</code>
                <span class="d-block text-muted small mt-1">
                  <code>web.xml</code> の
                  <code>&lt;request-character-encoding&gt;UTF-8&lt;/request-character-encoding&gt;</code>
                  で設定しています。
                </span>
              </td>
            </tr>
            <tr>
              <th scope="row">送信元のフォーム<br><span class="small text-muted font-weight-normal">hidden の form</span></th>
              <td><code>${empty formName ? 'null（まだ送信されていない）' : fn:escapeXml(formName)}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="④ getParameter と getParameterValues"
             note="${requestMethod} で受け取った項目を並べています">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th scope="col">パラメータ名</th>
              <th scope="col">入力欄</th>
              <th scope="col">getParameter</th>
              <th scope="col">状態</th>
              <th scope="col" class="text-right">文字数</th>
              <th scope="col">getParameterValues</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="row" items="${paramRows}">
              <tr>
                <td><code>${fn:escapeXml(row.name)}</code></td>
                <td class="small text-muted">${fn:escapeXml(row.label)}</td>
                <td><code>${fn:escapeXml(row.valueText)}</code></td>
                <td><span class="badge badge-${row.stateVariant}">${fn:escapeXml(row.state)}</span></td>
                <td class="text-right">${row.length lt 0 ? '-' : row.length}</td>
                <td>
                  <code>${fn:escapeXml(row.valuesText)}</code>
                  <c:if test="${row.multiple}">
                    <span class="badge badge-info ml-1">${row.valueCount} 件</span>
                  </c:if>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <ul class="text-muted small mt-3 mb-0">
        <li><span class="badge badge-secondary">届いていない</span>
          … パラメータ自体が送られていない状態です。<code>getParameter</code> は <code>null</code> を返します。</li>
        <li><span class="badge badge-warning">空文字</span>
          … 入力欄はあったが空のまま送信された状態です。長さ 0 の文字列が届いています。</li>
        <c:if test="${formName eq 'post'}">
          <li>
            <code>newsletter</code> の行を見ると、チェックした場合でも
            <code>getParameter</code> が <code>"off"</code>（先頭の hidden）を返すことが分かります。
            最後の値で判定した結果は
            <strong>${newsletterChecked ? '希望する' : '希望しない'}</strong> です。
          </li>
        </c:if>
        <c:if test="${formName ne 'post'}">
          <li>
            チェックボックスの行（<code>interests</code> / <code>newsletter</code>）は
            ② の POST フォームから送信すると表示されます。
          </li>
        </c:if>
      </ul>
    </t:panel>

    <t:panel title="⑤ getParameterMap（実際に届いたものすべて）"
             note="名前を知らなくても中身を確認できます">
      <c:choose>
        <c:when test="${empty mapRows}">
          <p class="text-muted mb-0">
            パラメータは 1 件も届いていません（<code>getParameterMap()</code> は空の Map を返します。
            <code>null</code> ではありません）。
          </p>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-bordered mb-0">
              <thead class="thead-light">
                <tr>
                  <th scope="col">キー（パラメータ名）</th>
                  <th scope="col" class="text-right">値の数</th>
                  <th scope="col">値（String[]）</th>
                  <th scope="col">先頭の値<br><span class="small text-muted font-weight-normal">= getParameter の結果</span></th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="row" items="${mapRows}">
                  <tr>
                    <td><code>${fn:escapeXml(row.name)}</code></td>
                    <td class="text-right">${row.valueCount}</td>
                    <td><code>${fn:escapeXml(row.valuesText)}</code></td>
                    <td><code>${fn:escapeXml(row.valueText)}</code></td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <p class="text-muted small mt-3 mb-0">
            <strong>${fn:length(mapRows)}</strong> 件のパラメータが届きました。
            この一覧に名前が無ければ、<code>name</code> 属性の書き忘れか、
            <code>disabled</code> になっている入力欄です。
          </p>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <t:panel title="⑥ 数値への変換（Integer.parseInt）"
             note="何を送られても落ちないようにします">
      <div class="table-responsive">
        <table class="table table-sm table-bordered">
          <tbody>
            <tr>
              <th scope="row" class="w-25">受け取った文字列</th>
              <td><code>${fn:escapeXml(sizeResult.rawText)}</code></td>
            </tr>
            <tr>
              <th scope="row">実際に使う値</th>
              <td><code>${sizeResult.value}</code></td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="alert alert-${sizeResult.variant} mb-3">
        ${fn:escapeXml(sizeResult.message)}
      </div>
      <p class="mb-1">
        URL を直接書き換えても落ちないことを確かめてみてください。
        全角数字がそのまま通ってしまうことも、ここで確認できます。
      </p>
      <p class="mb-0">
        <a class="btn btn-sm btn-outline-secondary mr-1"
           href="${demoUrl}?form=get&amp;size=20">size=20</a>
        <a class="btn btn-sm btn-outline-secondary mr-1"
           href="${demoUrl}?form=get&amp;size=abc">size=abc</a>
        <a class="btn btn-sm btn-outline-secondary mr-1"
           href="${demoUrl}?form=get&amp;size=１０">size=１０（全角。通ってしまう）</a>
        <a class="btn btn-sm btn-outline-secondary mr-1"
           href="${demoUrl}?form=get&amp;size=-5">size=-5</a>
        <a class="btn btn-sm btn-outline-secondary mr-1"
           href="${demoUrl}?form=get&amp;size=9999999999">size=9999999999</a>
        <a class="btn btn-sm btn-outline-secondary"
           href="${demoUrl}?form=get&amp;size=">size=（空）</a>
      </p>
    </t:panel>

    <t:panel title="⑦ EL の param / paramValues でも同じ値が取れる"
             note="Servlet を通さず JSP から直接読む書き方">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th scope="col" class="w-25">EL の式</th>
              <th scope="col">結果</th>
              <th scope="col">対応する Java</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><code>${'${param.keyword}'}</code></td>
              <td><code>${empty param.keyword ? '（空で表示される）' : fn:escapeXml(param.keyword)}</code></td>
              <td class="small text-muted"><code>getParameter("keyword")</code></td>
            </tr>
            <tr>
              <td><code>${'${empty param.keyword}'}</code></td>
              <td><code>${empty param.keyword}</code></td>
              <td class="small text-muted">
                届いていないときも空文字のときも <code>true</code>。この 2 つは EL では区別できません
              </td>
            </tr>
            <tr>
              <td><code>${'${param.interests}'}</code></td>
              <td><code>${empty param.interests ? '（空で表示される）' : fn:escapeXml(param.interests)}</code></td>
              <td class="small text-muted">
                <code>getParameter("interests")</code>。複数選んでも<strong>先頭だけ</strong>です
              </td>
            </tr>
            <tr>
              <td><code>${'${fn:length(paramValues.interests)}'}</code></td>
              <td><code>${fn:length(paramValues.interests)}</code></td>
              <td class="small text-muted">
                <code>getParameterValues("interests").length</code>。
                届いていなくても 0 になり、落ちません
              </td>
            </tr>
            <tr>
              <td><code>${'${fn:join(paramValues.interests, " / ")}'}</code></td>
              <td>
                <code>${empty paramValues.interests ? '（空で表示される）'
                        : fn:escapeXml(fn:join(paramValues.interests, ' / '))}</code>
              </td>
              <td class="small text-muted">配列を区切り文字でつないで表示する定番の書き方</td>
            </tr>
            <tr>
              <td><code>${'${paramValues.interests[0]}'}</code></td>
              <td>
                <code>${empty paramValues.interests ? '（空で表示される）'
                        : fn:escapeXml(paramValues.interests[0])}</code>
              </td>
              <td class="small text-muted">
                添字で取り出せます。存在しない添字でも EL は例外になりません
              </td>
            </tr>
            <tr>
              <td><code>${'${param.gender}'}</code></td>
              <td><code>${empty param.gender ? '（空で表示される）' : fn:escapeXml(param.gender)}</code></td>
              <td class="small text-muted">ラジオボタン。未選択なら届きません</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        表示するだけなら EL で十分ですが、<strong>値を検査したり型を変換したりする処理は
        Servlet 側</strong>に置きます。JSP に条件分岐が増えるほど読みにくくなるためです。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
