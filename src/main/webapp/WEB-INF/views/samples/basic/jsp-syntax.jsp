<%--
  【サンプル】JSP の記法（ディレクティブ / スクリプトレット / アクション）

  JSP に書ける「<% %> の仲間」を一通り並べて、何がどこへ変換されるのかを確かめる画面です。

  この JSP 自体には Servlet がありません (SampleDispatcherServlet が転送します)。
  スクリプトレットを動かす部分だけは別ファイルに分けて <jsp:include> で呼んでいます
  (タグファイルの本文は既定で scriptless なので、<t:panel> の中には <% %> を書けません)。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="site" uri="http://example.com/jsp/servlet-sample" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="samplePath" value="${ctx}/samples/basic/jsp-syntax" />
<t:sample sampleId="jsp-syntax">

  <jsp:attribute name="explanation">
    <h2>JSP は Servlet に変換されてから動きます</h2>
    <p>
      JSP は HTML のように見えますが、実行されるのは <strong>Java のクラス</strong>です。
      初めてアクセスされたとき、Tomcat は次の順で処理します。
    </p>
<pre><code class="language-plaintext">jsp-syntax.jsp
  ↓ ① 翻訳 (translation)   … Jasper が Java のソースを生成する
jsp_syntax_jsp.java
  ↓ ② コンパイル
jsp_syntax_jsp.class      … HttpJspBase (= HttpServlet) を継承した Servlet
  ↓ ③ 実行
_jspService(request, response) が呼ばれ、out.write(...) で HTML を書き出す</code></pre>
    <p>
      記法ごとの違いは、<strong>「変換後の Java のどこに置かれるか」</strong>だと考えると
      すっきりします。ここを押さえると、あとの決まりはほとんど理由が説明できます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>記法</th><th>呼び名</th><th>変換後のどこへ行くか</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>&lt;%@ ... %&gt;</code></td><td>ディレクティブ</td>
            <td>翻訳そのものへの指示（出力にはならない）</td>
          </tr>
          <tr>
            <td><code>&lt;%! ... %&gt;</code></td><td>宣言</td>
            <td>クラスの<strong>メンバー</strong>（フィールド・メソッド）</td>
          </tr>
          <tr>
            <td><code>&lt;% ... %&gt;</code></td><td>スクリプトレット</td>
            <td><code>_jspService</code> メソッドの<strong>中身</strong></td>
          </tr>
          <tr>
            <td><code>&lt;%= ... %&gt;</code></td><td>式</td>
            <td><code>out.print(...)</code> の引数</td>
          </tr>
          <tr>
            <td><code>&lt;%-- ... --%&gt;</code></td><td>JSP コメント</td>
            <td>どこにも行かない（翻訳の時点で消える）</td>
          </tr>
          <tr>
            <td><code>&lt;jsp:xxx /&gt;</code></td><td>アクション</td>
            <td>決められた処理の呼び出し（実行時）</td>
          </tr>
          <tr>
            <td><code>${'${...}'}</code></td><td>EL</td>
            <td>EL の評価 → <code>out.write(...)</code></td>
          </tr>
          <tr>
            <td>HTML などの地の文</td><td>テンプレートテキスト</td>
            <td><code>out.write("...")</code> にそのまま入る</td>
          </tr>
        </tbody>
      </table>
    </div>

    <h3>変換後のイメージ</h3>
<pre><code class="language-xml">&lt;%! private int count = 0; %&gt;
&lt;p&gt;&lt;% int x = 1 + 2; %&gt;答えは &lt;%= x %&gt; です&lt;/p&gt;</code></pre>
<pre><code class="language-java">public final class jsp_syntax_jsp extends org.apache.jasper.runtime.HttpJspBase {

    private int count = 0;                       // ← 宣言 : メンバーになる

    public void _jspService(HttpServletRequest request, HttpServletResponse response) {
        JspWriter out = pageContext.getOut();
        out.write("&lt;p&gt;");
        int x = 1 + 2;                           // ← スクリプトレット : メソッドの中身
        out.write("答えは ");
        out.print(x);                            // ← 式 : print の引数
        out.write(" です&lt;/p&gt;");
    }
}</code></pre>
    <p>
      「式の末尾に <code>;</code> を書くとエラーになる」のも、これで分かります。
      <code>out.print(x;)</code> という Java にはならないからです。
    </p>

    <h2>ディレクティブ <code>&lt;%@ %&gt;</code></h2>
    <p>3 種類あります。どれも<strong>翻訳への指示</strong>で、それ自体は何も出力しません。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>書き方</th><th>意味</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>&lt;%@ page ... %&gt;</code></td>
            <td>このページ自体の設定（文字コード、import、エラーページなど）</td>
          </tr>
          <tr>
            <td><code>&lt;%@ include file="..." %&gt;</code></td>
            <td>別ファイルの中身を<strong>翻訳前に</strong>貼り付ける（静的インクルード）</td>
          </tr>
          <tr>
            <td><code>&lt;%@ taglib prefix="c" uri="..." %&gt;</code></td>
            <td>タグライブラリ（JSTL や自作タグ）を使えるようにする</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p><code>page</code> ディレクティブでよく使う属性です。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>属性</th><th>役割</th><th>注意</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>contentType</code></td>
            <td>ブラウザへ<strong>出す</strong>ときの種類と文字コード</td>
            <td>既定は <code>text/html; charset=ISO-8859-1</code>。日本語なら必ず指定します</td>
          </tr>
          <tr>
            <td><code>pageEncoding</code></td>
            <td>この JSP ファイル自体を<strong>読む</strong>ときの文字コード</td>
            <td>「出す」側とは別物です。ファイルを UTF-8 で保存したなら UTF-8</td>
          </tr>
          <tr>
            <td><code>import</code></td>
            <td>スクリプトレットで使うクラスの import</td>
            <td>EL / JSTL だけで書くなら不要です</td>
          </tr>
          <tr>
            <td><code>session="false"</code></td>
            <td>セッションを作らない</td>
            <td>暗黙オブジェクト <code>session</code> が使えなくなります</td>
          </tr>
          <tr>
            <td><code>errorPage</code> / <code>isErrorPage</code></td>
            <td>例外が起きたときの遷移先 / 自分がその遷移先であること</td>
            <td><code>isErrorPage="true"</code> のページだけ <code>exception</code> を使えます</td>
          </tr>
          <tr>
            <td><code>trimDirectiveWhitespaces</code></td>
            <td>ディレクティブの行に残る改行を出力しない</td>
            <td>このサンプル集では <code>web.xml</code> で全ページに効かせています</td>
          </tr>
          <tr>
            <td><code>isELIgnored="true"</code></td>
            <td><code>${'${...}'}</code> を EL として解釈しない</td>
            <td>「EL が文字のまま出てしまう」ときの原因の 1 つです</td>
          </tr>
          <tr>
            <td><code>buffer</code></td>
            <td>出力をためておく大きさ</td>
            <td>あふれると送信が始まり、あとからリダイレクトできなくなります</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p class="text-muted">
      <code>page</code> ディレクティブは <strong>1 ページに何回書いても構いません</strong>
      （<code>import</code> を複数行に分けるのは普通の書き方です）。
      ただし同じ属性を違う値で 2 回書くとエラーになります（<code>import</code> は例外）。
    </p>

    <h2>静的インクルードと動的インクルード</h2>
    <p>「別のファイルを取り込む」書き方は 2 つあり、<strong>取り込む時点が違います</strong>。</p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr>
            <th></th>
            <th><code>&lt;%@ include file="..." %&gt;</code></th>
            <th><code>&lt;jsp:include page="..." /&gt;</code></th>
          </tr>
        </thead>
        <tbody>
          <tr><th scope="row">呼び名</th><td>静的インクルード</td><td>動的インクルード</td></tr>
          <tr>
            <th scope="row">取り込む時点</th>
            <td>翻訳前（ファイルを合体させる）</td>
            <td>実行時（別の Servlet を呼び出す）</td>
          </tr>
          <tr>
            <th scope="row">変数・メソッド</th>
            <td><strong>共有される</strong>（同じファイルになるため）</td>
            <td>共有されない（別のページとして動く）</td>
          </tr>
          <tr>
            <th scope="row">値の渡し方</th>
            <td>変数をそのまま使う</td>
            <td><code>&lt;jsp:param&gt;</code> か リクエストスコープ</td>
          </tr>
          <tr>
            <th scope="row">ページ番号（行番号）</th>
            <td>合体後の番号になる（エラーの行が読みにくい）</td>
            <td>ファイルごとにそのまま</td>
          </tr>
          <tr>
            <th scope="row">向いている用途</th>
            <td>定数の宣言、共通の taglib 宣言</td>
            <td>ヘッダー・フッター・部品の画面</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      静的インクルードは<strong>同じ変数を 2 回宣言してしまう</strong>事故が起きがちです
      （同じ断片を 2 回取り込むと、変数宣言も 2 回コピーされてコンパイルエラーになります）。
      迷ったら動的インクルードのほうが安全です。
    </p>

    <h2>アクション <code>&lt;jsp:xxx&gt;</code></h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>アクション</th><th>何をするか</th></tr>
        </thead>
        <tbody>
          <tr><td><code>&lt;jsp:include page="..." /&gt;</code></td><td>実行時に別ページを呼んで、その出力をここへ差し込む</td></tr>
          <tr><td><code>&lt;jsp:param name="..." value="..." /&gt;</code></td><td>include / forward のときにパラメータを足す</td></tr>
          <tr><td><code>&lt;jsp:forward page="..." /&gt;</code></td><td>別のページへ処理を渡す（ここまでの出力は捨てられる）</td></tr>
          <tr><td><code>&lt;jsp:useBean id="..." class="..." /&gt;</code></td><td>Bean を探し、無ければ作ってスコープに入れる</td></tr>
          <tr><td><code>&lt;jsp:setProperty ... /&gt;</code></td><td>Bean のプロパティに値を入れる（リクエストパラメータから自動でも入れられる）</td></tr>
          <tr><td><code>&lt;jsp:getProperty ... /&gt;</code></td><td>Bean のプロパティを書き出す（<strong>エスケープされません</strong>）</td></tr>
          <tr><td><code>&lt;jsp:text&gt;...&lt;/jsp:text&gt;</code></td><td>中身をそのまま地の文として出す</td></tr>
          <tr><td><code>&lt;jsp:attribute&gt;</code> / <code>&lt;jsp:body&gt;</code></td><td>タグに渡す値を、属性ではなく要素として書く</td></tr>
          <tr><td><code>&lt;jsp:doBody&gt;</code> / <code>&lt;jsp:invoke&gt;</code></td><td>タグファイルの中で、渡された本文やフラグメントを実行する</td></tr>
        </tbody>
      </table>
    </div>
    <p>
      このサンプル集の画面も <code>&lt;jsp:attribute name="explanation"&gt;</code> と
      <code>&lt;jsp:body&gt;</code> でできています。
      タグに「長い HTML」を渡したいとき、属性の文字列では書けないためです。
    </p>
    <p class="text-muted">
      <strong>注意</strong>：<code>&lt;jsp:attribute&gt;</code> や <code>&lt;jsp:body&gt;</code> の
      <strong>直前に JSP コメント（<code>&lt;%-- --%&gt;</code>）を書くとエラーになります</strong>。
      「標準アクションの本文には、ほかの要素を混ぜられない」という決まりのためです。
      コメントは要素の内側に書いてください。
    </p>

    <h2><code>&lt;jsp:useBean&gt;</code> と今どきの書き方</h2>
    <p>
      <code>&lt;jsp:useBean&gt;</code> は、JSP だけで画面を作っていた時代の仕組みです。
      いまは <strong>Servlet で値を用意して JSP は表示に徹する</strong>形が普通ですが、
      古い画面では今でもよく見かけます。
    </p>
<pre><code class="language-xml">&lt;jsp:useBean id="order" class="com.example.OrderBean" scope="page" /&gt;
&lt;jsp:setProperty name="order" property="*" /&gt;
&lt;jsp:getProperty name="order" property="summary" /&gt;</code></pre>
    <p>これは、次の Java とほぼ同じ意味です。</p>
<pre><code class="language-java">OrderBean order = (OrderBean) pageContext.getAttribute("order");
if (order == null) {
    order = new OrderBean();                       // 引数なしのコンストラクタが要る
    pageContext.setAttribute("order", order);
}
// property="*" : 名前が一致するリクエストパラメータを setter へ流し込む
order.setProductCode(request.getParameter("productCode"));
...
out.print(order.getSummary());                     // ← エスケープしない</code></pre>
    <p>覚えておきたい癖が 3 つあります。</p>
    <ul>
      <li>
        <strong><code>property="*"</code> は空文字のパラメータを無視します</strong>：
        「空にして送ったのに前の値が残る」のはこのためです
      </li>
      <li>
        <strong>型変換は自動、ただし失敗すると例外</strong>：
        プロパティが <code>int</code> なら文字列から自動で変換されますが、
        <code>?qty=abc</code> のような値が来ると<strong>入力エラーではなく 500 エラー</strong>になります。
        画面から来る値は文字列で受け取り、変換は自分で行うほうが安全です
      </li>
      <li>
        <strong>boolean は <code>"true"</code> のときだけ true</strong>：
        チェックボックスの既定値 <code>"on"</code> は <code>Boolean.valueOf("on")</code> なので
        false になります。<code>value="true"</code> と書いておきます
      </li>
    </ul>
    <p>
      そして <code>&lt;jsp:getProperty&gt;</code> は<strong>エスケープしません</strong>。
      利用者が入力した文字列を出すと、そのままクロスサイトスクリプティングの穴になります。
      出すなら <code>${"${fn:escapeXml(order.productCode)}"}</code> のように通してください。
    </p>

    <h2>スクリプトレットは「読めれば十分」</h2>
    <p>
      新しく書く画面では、<strong>スクリプトレットを使わず EL と JSTL で書きます</strong>。
      それでもこのサンプルで記法を扱うのは、<strong>保守で必ず出会うから</strong>です。
      読めないと直せません。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>昔ながらの書き方</th><th>いまの書き方</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>&lt;%= request.getAttribute("name") %&gt;</code></td>
            <td><code>${"${fn:escapeXml(name)}"}</code></td>
          </tr>
          <tr>
            <td><code>&lt;% for (Item i : items) { %&gt; ... &lt;% } %&gt;</code></td>
            <td><code>&lt;c:forEach var="i" items="${'${items}'}"&gt; ... &lt;/c:forEach&gt;</code></td>
          </tr>
          <tr>
            <td><code>&lt;% if (flag) { %&gt; ... &lt;% } %&gt;</code></td>
            <td><code>&lt;c:if test="${'${flag}'}"&gt; ... &lt;/c:if&gt;</code></td>
          </tr>
          <tr>
            <td><code>&lt;% String s = ...; %&gt;</code></td>
            <td><code>&lt;c:set var="s" value="..." /&gt;</code></td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>理由は、好みではなく実務的なものです。</p>
    <ul>
      <li>
        <strong>エスケープを忘れやすい</strong>：<code>&lt;%= %&gt;</code> は素通しです。
        EL でも同じですが、JSTL の <code>fn:escapeXml</code> / <code>c:out</code> を
        習慣にできます
      </li>
      <li>
        <strong>例外が画面の途中で起きる</strong>：出力が始まったあとに落ちると、
        中途半端な HTML の続きにエラーページが出ます
      </li>
      <li>
        <strong>中かっこの対応が崩れる</strong>：HTML を挟んだ <code>for</code> や <code>if</code> は、
        閉じ忘れても見た目では気づけません
      </li>
      <li>
        <strong>宣言はインスタンス変数になる</strong>：Servlet は 1 インスタンスなので、
        知らないうちに利用者間で値を共有してしまいます
        （<a href="${ctx}/samples/basic/servlet-lifecycle">ライフサイクルのサンプル</a>）
      </li>
      <li>
        <strong>テストできない</strong>：JSP に書いた処理は、画面を開くまで動かせません
      </li>
    </ul>
    <p class="text-muted">
      なお、スクリプトレットを<strong>禁止する設定</strong>もあります。
      <code>web.xml</code> の <code>&lt;scripting-invalid&gt;true&lt;/scripting-invalid&gt;</code> です
      （このサンプル集では記法を見せるために <code>false</code> のままにしています）。
    </p>

    <h2>コメントは 3 種類あります</h2>
<pre><code class="language-xml">&lt;%-- JSP コメント : ブラウザには届かない --%&gt;
&lt;!-- HTML コメント : ブラウザまで届く（ページのソースに出る） --&gt;
&lt;% // Java のコメント : 生成された Java の中だけに残る %&gt;</code></pre>
    <p>
      うっかり <code>&lt;!-- --&gt;</code> で「作業中のメモ」を囲むと、
      <strong>そのまま利用者に見えます</strong>。
      しかも HTML コメントの中の EL は<strong>実行されます</strong>。
      <code>&lt;!-- ${'${user.password}'} --&gt;</code> と書けば、
      画面には出ませんがソースには出てしまいます。
    </p>

    <h2>暗黙オブジェクト</h2>
    <p>
      スクリプトレットの中では、宣言していない変数をいくつか使えます。
      翻訳のときに Jasper が用意してくれるもので、暗黙オブジェクトと呼びます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead class="thead-light">
          <tr><th>名前</th><th>型</th><th>EL からの書き方</th></tr>
        </thead>
        <tbody>
          <tr><td><code>request</code></td><td>HttpServletRequest</td><td><code>${'${pageContext.request}'}</code> / <code>${'${param.x}'}</code></td></tr>
          <tr><td><code>response</code></td><td>HttpServletResponse</td><td><code>${'${pageContext.response}'}</code></td></tr>
          <tr><td><code>out</code></td><td>JspWriter</td><td>（EL では地の文がそのまま出力）</td></tr>
          <tr><td><code>session</code></td><td>HttpSession</td><td><code>${'${sessionScope.x}'}</code></td></tr>
          <tr><td><code>application</code></td><td>ServletContext</td><td><code>${'${applicationScope.x}'}</code> / <code>${'${initParam.x}'}</code></td></tr>
          <tr><td><code>pageContext</code></td><td>PageContext</td><td><code>${'${pageContext.request.contextPath}'}</code></td></tr>
          <tr><td><code>config</code></td><td>ServletConfig</td><td>—</td></tr>
          <tr><td><code>page</code></td><td>this（この JSP 自身）</td><td>—</td></tr>
          <tr><td><code>exception</code></td><td>Throwable</td><td><code>${'${pageContext.exception}'}</code>（<code>isErrorPage="true"</code> のページのみ）</td></tr>
        </tbody>
      </table>
    </div>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>式の末尾に <code>;</code> を書く</strong>：
        <code>&lt;%= x; %&gt;</code> はエラーです。式であって文ではありません。
      </li>
      <li>
        <strong>スクリプトレットの変数を別のブロックから使えない</strong>：
        <code>&lt;jsp:attribute&gt;</code> の中と <code>&lt;jsp:body&gt;</code> の中では、
        生成されるメソッドが別なので変数を共有できません。
      </li>
      <li>
        <strong>タグファイルの本文にスクリプトレットが書けない</strong>：
        タグファイルの <code>body-content</code> は既定で <code>scriptless</code> です。
        この画面が「スクリプトレットの部分だけ別ファイル」にしているのはこのためです。
      </li>
      <li>
        <strong>取り込んだ断片だけ文字化けする</strong>：
        <code>web.xml</code> の <code>&lt;page-encoding&gt;</code> は
        <code>&lt;url-pattern&gt;</code>（このサンプル集では <code>*.jsp</code>）に
        一致したファイルにしか効きません。取り込む側の <code>pageEncoding</code> も
        引き継がれないため、<code>.jspf</code> は既定の <code>ISO-8859-1</code> として読まれ、
        <strong>その部分だけ文字化けします</strong>。
        断片ファイルの先頭に <code>&lt;%@ page pageEncoding="UTF-8" %&gt;</code> を
        書いておくのが確実です
        （<code>web.xml</code> に <code>*.jspf</code> の
        <code>&lt;jsp-property-group&gt;</code> を足す手もありますが、
        そうすると <code>.jspf</code> が「1 枚の JSP」として扱われ、
        事前コンパイルでコンパイルエラーになります）。
      </li>
      <li>
        <strong><code>&lt;%@ include %&gt;</code> を直しても反映されない</strong>：
        取り込む側が再翻訳されないと変わりません。反映されないときは
        取り込む側を保存し直すか、Tomcat を再起動します。
      </li>
      <li>
        <strong>EL が文字のまま出る</strong>：
        <code>isELIgnored="true"</code> になっている、<code>web.xml</code> の
        バージョンが古い（2.3 以前）、<code>\&#36;{...}</code> のように
        <code>\</code> でエスケープしている、のいずれかです。
      </li>
      <li>
        <strong>出力に <code>${'${'}</code> をそのまま書きたい</strong>：
        <code>\&#36;{1 + 2}</code> のように <code>\</code> を前に付けるか、
        EL の文字列として <code>${'${"${1 + 2}"}'}</code> と書きます
        （どちらも <code>${'${1 + 2}'}</code> と表示されます）。
      </li>
      <li>
        <strong><code>out.write</code> と <code>response.getWriter()</code> を混ぜる</strong>：
        JSP の <code>out</code> はバッファを通るので、混ぜると<strong>出力の順番が入れ替わります</strong>。
      </li>
      <li>
        <strong>出力が始まったあとにリダイレクトする</strong>：
        バッファ（このサンプル集では 64kb）を超えて送信が始まると、
        <code>sendRedirect</code> は <code>IllegalStateException</code> になります。
      </li>
      <li>
        <strong>タグの間に改行や空白が入って崩れる</strong>：
        ディレクティブの改行は <code>trimDirectiveWhitespaces</code> で消せます。
        JSON を返す JSP を書くと、この空白が原因で壊れます
        （そもそも JSON は Servlet から返しましょう）。
      </li>
      <li>
        <strong><code>contentType</code> と <code>pageEncoding</code> を取り違える</strong>：
        前者は「出すとき」、後者は「ファイルを読むとき」の文字コードです。
      </li>
    </ul>

    <h2>XML 形式の JSP（参考）</h2>
    <p>
      JSP には、すべてを XML として書く形式（JSP ドキュメント、拡張子 <code>.jspx</code>）もあります。
      ツールで扱いやすい代わりに冗長なので、あまり見かけません。
    </p>
<pre><code class="language-xml">&lt;jsp:root xmlns:jsp="http://java.sun.com/JSP/Page" version="2.1"&gt;
  &lt;jsp:directive.page contentType="text/html; charset=UTF-8" /&gt;
  &lt;jsp:scriptlet&gt;int x = 1;&lt;/jsp:scriptlet&gt;
  &lt;jsp:expression&gt;x&lt;/jsp:expression&gt;
&lt;/jsp:root&gt;</code></pre>

    <h2>関連するサンプル</h2>
    <ul>
      <li><a href="${ctx}/samples/basic/jsp-basics">EL と JSTL の基本</a> … いま書くならこちらの書き方です</li>
      <li><a href="${ctx}/samples/basic/hello-world">Hello World</a> … Servlet で用意して JSP で表示する流れ</li>
      <li><a href="${ctx}/samples/basic/servlet-lifecycle">Servlet のライフサイクルとスレッド</a> … 宣言がインスタンス変数になる話の続き</li>
      <li><a href="${ctx}/samples/basic/forward-redirect">forward と redirect の違い</a> … <code>&lt;jsp:forward&gt;</code> の実体</li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <t:panel title="記法の早見表" note="この画面の中で実際に使っている記法です">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th scope="col">記法</th>
              <th scope="col">呼び名</th>
              <th scope="col">例</th>
              <th scope="col">出力</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><code>&lt;%@ %&gt;</code></td>
              <td>ディレクティブ</td>
              <td><code>&lt;%@ page contentType="text/html; charset=UTF-8" %&gt;</code></td>
              <td>なし（翻訳への指示）</td>
            </tr>
            <tr>
              <td><code>&lt;%! %&gt;</code></td>
              <td>宣言</td>
              <td><code>&lt;%! private int count = 0; %&gt;</code></td>
              <td>なし（クラスのメンバーになる）</td>
            </tr>
            <tr>
              <td><code>&lt;% %&gt;</code></td>
              <td>スクリプトレット</td>
              <td><code>&lt;% int x = 1 + 2; %&gt;</code></td>
              <td>なし（メソッドの中身になる）</td>
            </tr>
            <tr>
              <td><code>&lt;%= %&gt;</code></td>
              <td>式</td>
              <td><code>&lt;%= 1 + 2 %&gt;</code></td>
              <td><code>3</code></td>
            </tr>
            <tr>
              <td><code>&lt;%-- --%&gt;</code></td>
              <td>JSP コメント</td>
              <td><code>&lt;%-- メモ --%&gt;</code></td>
              <td>なし（ブラウザにも届かない）</td>
            </tr>
            <tr>
              <td><code>&lt;jsp:xxx&gt;</code></td>
              <td>アクション</td>
              <td><code>&lt;jsp:include page="foo.jsp" /&gt;</code></td>
              <td>呼んだページの出力</td>
            </tr>
            <tr>
              <td><code>${'${...}'}</code></td>
              <td>EL</td>
              <td><code>${'${1 + 2}'}</code></td>
              <td>${1 + 2}</td>
            </tr>
            <tr>
              <td><code>\&#36;{...}</code></td>
              <td>EL の打ち消し</td>
              <td><code>\&#36;{1 + 2}</code></td>
              <td>${'${1 + 2}'}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="宣言・スクリプトレット・式を動かす"
             note="この枠の中身は jsp-syntax-scripting.jsp が出力しています">
      <jsp:include page="jsp-syntax-scripting.jsp" />
      <p class="text-muted small mt-3 mb-0">
        タグファイル（<code>/WEB-INF/tags/*.tag</code>）の本文は既定で
        <code>body-content="scriptless"</code> です。そのため
        <code>&lt;t:panel&gt;</code> の中に直接 <code>&lt;% %&gt;</code> は書けません
        （書くと翻訳エラーになります）。
        ここでは動的インクルードで「別の JSP」として呼ぶことで、昔ながらの記法を動かしています。
      </p>
    </t:panel>

    <t:panel title="動的インクルードと jsp:param"
             note="別のページを呼び出して、その出力をここへ差し込みます">
      <c:set var="sharedNote" value="呼び出し側が request スコープに置いた値" scope="request" />
      <jsp:include page="jsp-syntax-included.jsp">
        <jsp:param name="label" value="こんにちは" />
      </jsp:include>
      <div class="mt-3">
<pre class="code-snippet mb-0"><code class="language-xml">&lt;c:set var="sharedNote" value="..." scope="request" /&gt;
&lt;jsp:include page="jsp-syntax-included.jsp"&gt;
  &lt;jsp:param name="label" value="こんにちは" /&gt;
&lt;/jsp:include&gt;</code></pre>
      </div>
      <p class="text-muted small mt-3 mb-0">
        <code>&lt;jsp:param&gt;</code> で足したパラメータは、
        <strong>呼ばれている間だけ</strong> <code>${'${param.label}'}</code> で読めます。
        呼び出しが終われば元のパラメータに戻ります。
      </p>
    </t:panel>

    <t:panel title="jsp:useBean で画面の値をまとめて受け取る"
             note="Servlet を作らず、JSP だけで組み立てる昔ながらの書き方です">

      <jsp:useBean id="order" class="com.example.servletsample.samples.basic.OrderBean"
                   scope="page" />
      <%-- property="*" : 名前が一致するリクエストパラメータを setter へ流し込む --%>
      <jsp:setProperty name="order" property="*" />
      <%-- 画面の項目名 (qty) とプロパティ名 (quantity) が違うときは、対応を明示する --%>
      <jsp:setProperty name="order" property="quantity" param="qty" />
      <%-- 画面から来ない値は value で直接入れる --%>
      <jsp:setProperty name="order" property="channel" value="Web 画面" />

      <form action="${samplePath}" method="get" class="mb-3">
        <div class="form-row">
          <div class="form-group col-md-5">
            <label for="productCode">商品</label>
            <select class="form-control" id="productCode" name="productCode">
              <option value="">-- 選んでください --</option>
              <c:forEach var="product" items="${order.products}">
                <option value="${fn:escapeXml(product.key)}"
                        ${order.productCode eq product.key ? 'selected' : ''}>
                  ${fn:escapeXml(product.value)}
                </option>
              </c:forEach>
            </select>
          </div>
          <div class="form-group col-md-3">
            <label for="qty">数量（項目名は <code>qty</code>）</label>
            <input type="text" class="form-control" id="qty" name="qty"
                   value="${fn:escapeXml(order.quantity)}" placeholder="例: 3">
          </div>
          <div class="form-group col-md-4">
            <span class="d-inline-block mb-2">お急ぎ便</span>
            <div class="custom-control custom-checkbox">
              <input type="checkbox" class="custom-control-input" id="express"
                     name="express" value="true" ${order.express ? 'checked' : ''}>
              <label class="custom-control-label" for="express">
                <code>value="true"</code> にしています
              </label>
            </div>
          </div>
        </div>
        <button type="submit" class="btn btn-primary btn-sm">
          <t:icon name="arrow-repeat" size="14" cssClass="mr-1" />この内容で表示する
        </button>
        <a class="btn btn-link btn-sm" href="${samplePath}">クリア</a>
      </form>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr><th scope="col">書いたもの</th><th scope="col">結果</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>&lt;jsp:getProperty name="order" property="summary" /&gt;</code></td>
              <td><jsp:getProperty name="order" property="summary" /></td>
            </tr>
            <tr>
              <td><code>${"${fn:escapeXml(order.productCode)}"}</code></td>
              <td><code>${empty order.productCode ? '(空)' : fn:escapeXml(order.productCode)}</code></td>
            </tr>
            <tr>
              <td><code>${"${order.quantity}"}</code>（文字列のまま）</td>
              <td><code>${empty order.quantity ? '(空)' : fn:escapeXml(order.quantity)}</code></td>
            </tr>
            <tr>
              <td><code>${"${order.quantityValue}"}</code>（自分で変換した値）</td>
              <td>${order.quantityValue}</td>
            </tr>
            <tr>
              <td><code>${"${order.express}"}</code>（boolean）</td>
              <td>${order.express}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <p class="text-muted small mt-3 mb-0">
        数量に <code>abc</code> と入れても画面は落ちません。
        <code>OrderBean</code> が数量を<strong>文字列で受け取り、変換を自分で行っている</strong>ためです。
        ここを <code>int</code> のプロパティにすると、<code>&lt;jsp:setProperty&gt;</code> の
        自動変換が失敗して 500 エラーになります。
      </p>
    </t:panel>

    <t:panel title="コメントはどこまで届くか"
             note="左が書いたもの、下がブラウザに届いたものです">
      <site:source path="/WEB-INF/views/samples/basic/jsp-syntax-comments.jsp"
                   label="jsp-syntax-comments.jsp（書いたもの）" language="xml" />

      <p class="mb-1"><strong>ブラウザに届いた HTML</strong></p>
      <c:import var="commentOutput" url="/WEB-INF/views/samples/basic/jsp-syntax-comments.jsp" />
<pre class="code-snippet mb-0"><code class="language-xml">${fn:escapeXml(fn:trim(commentOutput))}</code></pre>

      <p class="text-muted small mt-3 mb-0">
        JSP コメント（①③）は消えていますが、HTML コメント（②④）は残っています。
        しかも ④ の <code>${'${1 + 1}'}</code> は<strong>計算された結果</strong>で出ています。
        コメントアウトのつもりで <code>&lt;!-- --&gt;</code> で囲むと、
        中の EL は動きますし、中身も利用者に見えます。
      </p>
    </t:panel>

    <t:panel title="EL から見た暗黙オブジェクト" note="スクリプトレットを書かなくても、たいていのものは取れます">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead class="thead-light">
            <tr><th scope="col">書いたもの</th><th scope="col">結果</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>${"${pageContext.request.method}"}</code></td>
              <td>${pageContext.request.method}</td>
            </tr>
            <tr>
              <td><code>${"${pageContext.request.requestURI}"}</code></td>
              <td><code>${fn:escapeXml(pageContext.request.requestURI)}</code></td>
            </tr>
            <tr>
              <td><code>${"${requestScope['javax.servlet.forward.request_uri']}"}</code></td>
              <td><code>${fn:escapeXml(requestScope['javax.servlet.forward.request_uri'])}</code>
                （ブラウザのアドレス欄）</td>
            </tr>
            <tr>
              <td><code>${"${pageContext.request.contextPath}"}</code></td>
              <td><code>${empty ctx ? '(ルート)' : fn:escapeXml(ctx)}</code></td>
            </tr>
            <tr>
              <td><code>${"${header['User-Agent']}"}</code></td>
              <td class="text-break"><small>${fn:escapeXml(header['User-Agent'])}</small></td>
            </tr>
            <tr>
              <td><code>${"${initParam.siteTitle}"}</code>（web.xml の context-param）</td>
              <td>${fn:escapeXml(initParam.siteTitle)}</td>
            </tr>
            <tr>
              <td><code>${"${pageContext.servletContext.serverInfo}"}</code></td>
              <td>${fn:escapeXml(pageContext.servletContext.serverInfo)}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="text-muted small mt-3 mb-0">
        <code>requestURI</code> がブラウザのアドレス欄と違うことに気づいたでしょうか。
        この画面は <code>SampleDispatcherServlet</code> から <strong>forward</strong> されて
        表示されているためです。forward するとリクエストのパスは転送先（JSP のパス）に差し替わり、
        元の URL は <code>javax.servlet.forward.request_uri</code> に残ります。
        <code>&lt;jsp:include&gt;</code> のときは逆で、<code>requestURI</code> は呼び出し側のまま、
        取り込まれた側のパスが <code>javax.servlet.include.servlet_path</code> に入ります。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
