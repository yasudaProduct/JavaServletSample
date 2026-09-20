<%--
  【サンプル】EL と JSTL の基本

  JspBasicsServlet が「EL が扱える型」をひととおりリクエストスコープに入れ、
  この JSP が EL (${...}) と JSTL タグだけで表示を組み立てます。

    書いた EL │ その結果   … を左右に並べた表で見比べられるようにしています。

  画面の上にある入力欄 (在庫数 / ニックネーム / 比較用の文字列) を変えると、
  下の表の結果がその場で変わります。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="demoUrl" value="${ctx}/samples/basic/jsp-basics" />
<t:sample sampleId="jsp-basics">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>処理の流れ</h2>
    <ol>
      <li>ブラウザが <code>/samples/basic/jsp-basics</code> をリクエストする</li>
      <li><code>JspBasicsServlet#doGet</code> が、表示に使う値
        （文字列・数値・真偽値・Bean・Map・List）をリクエストスコープに入れる</li>
      <li>JSP へ <code>forward</code> する</li>
      <li>JSP は <strong>EL と JSTL だけ</strong>で HTML を組み立てる
        （Java のコードは 1 行も書きません）</li>
    </ol>
    <p>
      Servlet は「材料を並べる」、JSP は「並べ方を決める」という分担です。
      この分担ができていると、画面の見た目を直すときに Java を触らずに済みます。
    </p>

    <h2>EL（Expression Language）とは</h2>
    <p>
      <code>${'${member.name}'}</code> のように書くと、スコープから
      <code>member</code> を探して <code>getName()</code> の結果を出力します。
      探す順番は <strong>page → request → session → application</strong> で、
      最初に見つかったものが使われます。
      どのスコープか明示したいときは <code>${'${requestScope.member}'}</code> のように書きます。
    </p>
    <p>
      プロパティ名は<strong>フィールド名ではなく getter 名</strong>から決まります。
      <code>getJoinedOnText()</code> なら <code>${'${member.joinedOnText}'}</code>、
      boolean の <code>isSale()</code> なら <code>${'${item.sale}'}</code> です。
      getter が無いプロパティを書くと <code>PropertyNotFoundException</code> になります。
    </p>

    <h3>スクリプトレット（<code>&lt;% %&gt;</code>）を使わない理由</h3>
    <p>
      JSP には Java をそのまま書ける記法（スクリプトレット）がありますが、
      いまは使わないのが一般的です。
    </p>
    <ul>
      <li>
        <strong>画面と処理が混ざる</strong>：
        HTML の途中に <code>if</code> や <code>for</code> が挟まると、
        どこがタグの開始でどこが終わりなのか追えなくなります。
      </li>
      <li>
        <strong>エスケープを忘れる</strong>：
        <code>&lt;%= value %&gt;</code> はそのまま HTML として出力されます。
        EL + <code>c:out</code> なら既定でエスケープされます。
      </li>
      <li>
        <strong>null で落ちる</strong>：
        <code>&lt;%= user.getName() %&gt;</code> は <code>user</code> が null なら
        <code>NullPointerException</code> ですが、EL は空文字になるだけです。
      </li>
      <li>
        <strong>テストできない</strong>：
        JSP の中のロジックは単体テストが書けません。
        判定は Servlet 側（または Bean のメソッド）に置きます。
      </li>
    </ul>
    <p class="text-muted">
      とはいえ、既存の画面を直すときには読めないと困ります。
      スクリプトレットを含む記法そのもの（何がどこへ変換されるのか）は
      <a href="${ctx}/samples/basic/jsp-syntax">JSP の記法</a>のサンプルで扱っています。
    </p>

    <h2>taglib 宣言と JSTL の使い分け</h2>
    <p>
      JSTL は用途ごとにライブラリが分かれていて、
      <strong>使うものだけ</strong>をページの先頭で宣言します。
      prefix（<code>c</code> / <code>fmt</code> / <code>fn</code>）は慣習的な名前で、
      変えることもできますが、揃えておいたほうが読みやすくなります。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>宣言</th><th>prefix</th><th>役割</th><th>代表的なもの</th></tr>
        </thead>
        <tbody>
          <tr>
            <td><code>.../jstl/core</code></td>
            <td><code>c</code></td>
            <td>分岐・繰り返し・変数・出力</td>
            <td><code>c:forEach</code> <code>c:if</code> <code>c:choose</code>
                <code>c:set</code> <code>c:out</code> <code>c:url</code></td>
          </tr>
          <tr>
            <td><code>.../jstl/fmt</code></td>
            <td><code>fmt</code></td>
            <td>数値・日付の書式、国際化</td>
            <td><code>fmt:formatNumber</code> <code>fmt:formatDate</code>
                <code>fmt:setLocale</code></td>
          </tr>
          <tr>
            <td><code>.../jstl/functions</code></td>
            <td><code>fn</code></td>
            <td><strong>EL の中で呼ぶ関数</strong>（タグではありません）</td>
            <td><code>fn:length</code> <code>fn:escapeXml</code>
                <code>fn:split</code> <code>fn:join</code></td>
          </tr>
        </tbody>
      </table>
    </div>
<pre><code class="language-xml">&lt;%@ taglib prefix="c"   uri="http://java.sun.com/jsp/jstl/core" %&gt;
&lt;%@ taglib prefix="fn"  uri="http://java.sun.com/jsp/jstl/functions" %&gt;
&lt;%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %&gt;</code></pre>
    <p>
      <code>c</code> と <code>fmt</code> は<strong>タグ</strong>、
      <code>fn</code> は<strong>EL の中で使う関数</strong>、という違いが要点です。
      <code>&lt;fn:length&gt;</code> という書き方はできません
      （<code>${'${fn:length(items)}'}</code> と書きます）。
    </p>

    <h2>EL は null に強い</h2>
    <p>
      EL は「値が無い」ことを例外ではなく<strong>空文字</strong>として扱います。
      画面の表示で落ちないのは、この性質のおかげです。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>書いたもの</th><th>EL の結果</th><th>Java で同じことをすると</th></tr></thead>
        <tbody>
          <tr>
            <td><code>${'${missingValue}'}</code>（存在しない変数）</td>
            <td>null → 空文字で出力</td>
            <td>コンパイルエラー</td>
          </tr>
          <tr>
            <td><code>${'${missingValue.name}'}</code></td>
            <td>null（<strong>例外にならない</strong>）</td>
            <td><code>NullPointerException</code></td>
          </tr>
          <tr>
            <td><code>${'${member.email}'}</code>（getter が null を返す）</td>
            <td>空文字で出力</td>
            <td>出力自体は "null" という文字列になる</td>
          </tr>
          <tr>
            <td><code>${'${nullValue + 1}'}</code></td>
            <td>1（null は 0 として扱われる）</td>
            <td><code>NullPointerException</code></td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      ただし<strong>メソッド呼び出しは別</strong>です。
      <code>${'${missingValue.name.length()}'}</code> のように null に対してメソッドを呼ぶと
      例外になります。プロパティを「たどる」のは安全、「呼ぶ」のは危険、と覚えておくと安全です。
    </p>

    <h2>empty 演算子</h2>
    <p>
      <code>empty</code> は <strong>null・空文字・空のコレクション（配列 / Map / List）</strong>を
      すべて「空」と判定します。3 つを別々に書き分けなくてよいので、画面側の条件がとても短くなります。
    </p>
<pre><code class="language-xml">&lt;%-- この 1 つで「未入力」「未設定」「0 件」をまとめて拾える --%&gt;
&lt;c:if test="${'${empty nickname}'}"&gt;未設定です&lt;/c:if&gt;

&lt;%-- 否定は not を前に付ける --%&gt;
&lt;c:if test="${'${not empty items}'}"&gt;${'${fn:length(items)}'} 件&lt;/c:if&gt;</code></pre>
    <p>
      注意したいのは <strong>0 と false は「空」ではない</strong>ことです。
      <code>${'${empty 0}'}</code> は false になります。
      「未入力なら」と「0 なら」は別の条件なので、<code>empty</code> だけで済ませないようにします。
    </p>
    <p>
      なお <code>empty</code> は<strong>EL の予約語</strong>です。
      Bean に <code>isEmpty()</code> があっても <code>${'${page.empty}'}</code> とは書けません
      （パースエラーになります）。<code>${'${empty page.items}'}</code> のように書きます。
      予約語はほかに
      <code>and or not eq ne lt gt le ge true false null instanceof div mod</code> があります。
    </p>

    <h2>c:forEach と varStatus</h2>
    <p>
      <code>items</code> に List・配列・Map を渡すと、1 件ずつ <code>var</code> に入って繰り返します。
      <code>varStatus</code> を付けると「いま何番目か」を取れます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>プロパティ</th><th>意味</th><th>よく使う場面</th></tr></thead>
        <tbody>
          <tr><td><code>index</code></td><td>0 から数えた位置</td><td>配列の添字、CSS の偶数 / 奇数</td></tr>
          <tr><td><code>count</code></td><td>1 から数えた番号</td><td>画面に出す「№」</td></tr>
          <tr><td><code>first</code></td><td>最初なら true</td><td>見出し行の出し分け</td></tr>
          <tr><td><code>last</code></td><td>最後なら true</td><td><strong>区切り文字を最後だけ出さない</strong></td></tr>
          <tr><td><code>current</code></td><td>いまの要素そのもの</td><td><code>var</code> と同じもの</td></tr>
        </tbody>
      </table>
    </div>
<pre><code class="language-xml">&lt;c:forEach var="skill" items="${'${member.skills}'}" varStatus="st"&gt;
  ${'${fn:escapeXml(skill)}'}&lt;c:if test="${'${not st.last}'}"&gt; / &lt;/c:if&gt;
&lt;/c:forEach&gt;</code></pre>
    <p>
      <code>items</code> を書かずに <code>begin</code> / <code>end</code> / <code>step</code> だけを
      指定すると、単純な数値の繰り返しになります（<code>for (int i = 1; i &lt;= 5; i++)</code> と同じ）。
    </p>

    <h2>c:if と c:choose</h2>
    <p>
      <code>c:if</code> に <strong>else はありません</strong>。
      2 つ以上に分けたいときは <code>c:choose</code> を使います。
    </p>
<pre><code class="language-xml">&lt;c:choose&gt;
  &lt;c:when test="${'${stock eq 0}'}"&gt;品切れ&lt;/c:when&gt;
  &lt;c:when test="${'${stock le 5}'}"&gt;残りわずか&lt;/c:when&gt;
  &lt;c:otherwise&gt;在庫あり&lt;/c:otherwise&gt;
&lt;/c:choose&gt;</code></pre>
    <p>
      上から順に評価され、<strong>最初に true になった 1 つだけ</strong>が出力されます。
      並び順を逆にすると（<code>le 5</code> を先に書くと）0 のときも「残りわずか」になってしまうので、
      <strong>条件は狭いものから順に</strong>並べます。
    </p>
    <p>
      文字を 2 つに出し分けるだけなら、三項演算子のほうが短く書けます：
      <code>${"${stock gt 0 ? '在庫あり' : '品切れ'}"}</code>。
      タグの属性値の中でも使えるのが利点です（<code>class="${"${st.first ? 'font-weight-bold' : ''}"}"</code> など）。
    </p>

    <h2>c:set と c:remove</h2>
    <p>
      同じ式を何度も書くときや、計算結果に名前を付けたいときに使います。
      <code>scope</code> を省略すると <strong>page スコープ</strong>（そのページを組み立てている間だけ）です。
    </p>
<pre><code class="language-xml">&lt;%-- value 属性で指定する --%&gt;
&lt;c:set var="taxRate" value="0.10" /&gt;

&lt;%-- 本文で指定する（HTML を含む長い文字列はこちらが読みやすい） --%&gt;
&lt;c:set var="greeting"&gt;こんにちは、${'${fn:escapeXml(member.name)}'} さん&lt;/c:set&gt;

&lt;%-- 明示的に消す --%&gt;
&lt;c:remove var="taxRate" /&gt;</code></pre>
    <p>
      <code>c:set</code> は「表示のための一時変数」に留めるのがこつです。
      業務的な計算（税込金額の丸め方など）を JSP に書いてしまうと、
      同じ計算が別の画面にも散らばってテストできなくなります。
    </p>

    <h2>fn: の関数</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>関数</th><th>すること</th><th>注意</th></tr></thead>
        <tbody>
          <tr>
            <td><code>fn:length(x)</code></td>
            <td>文字数、またはコレクションの件数</td>
            <td>null を渡すと 0（落ちません）</td>
          </tr>
          <tr>
            <td><code>fn:contains(a, b)</code></td>
            <td>含まれているか</td>
            <td>大文字小文字を無視するなら <code>fn:containsIgnoreCase</code></td>
          </tr>
          <tr>
            <td><code>fn:toUpperCase(s)</code></td>
            <td>大文字にする</td>
            <td>かな・漢字は変わりません。<strong>全角の英字（ａ→Ａ）は大文字になります</strong></td>
          </tr>
          <tr>
            <td><code>fn:substring(s, 開始, 終了)</code></td>
            <td>切り出す</td>
            <td>終了位置は<strong>含みません</strong>。範囲外でも例外にならず空文字</td>
          </tr>
          <tr>
            <td><code>fn:split(s, 区切り)</code></td>
            <td>文字列 → 配列</td>
            <td>区切り文字は<strong>1 文字ずつ</strong>として扱われます</td>
          </tr>
          <tr>
            <td><code>fn:join(配列, 区切り)</code></td>
            <td>配列 → 文字列</td>
            <td>List は渡せません（配列だけ）</td>
          </tr>
          <tr>
            <td><code>fn:escapeXml(s)</code></td>
            <td><code>&lt;</code> <code>&gt;</code> <code>&amp;</code> <code>"</code> <code>'</code> を実体参照
                （<code>&amp;lt; &amp;gt; &amp;amp; &amp;#034; &amp;#039;</code>）に置き換える</td>
            <td>画面に出す文字列はこれを通します。
                引用符は <code>&amp;quot;</code> ではなく数値参照の <code>&amp;#034;</code> になります</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      <code>fn:split</code> の区切りは正規表現ではなく <code>StringTokenizer</code> と同じ扱いで、
      渡した文字列に<strong>含まれるどの 1 文字でも</strong>区切りになります。
      <code>fn:split(s, ", ")</code> は「カンマまたは空白」で切れてしまうので、
      区切りには 1 文字だけを渡すのが安全です。
    </p>

    <h2>fmt:formatNumber と日付</h2>
    <p>
      3 桁区切りや通貨の表記は <code>fmt:formatNumber</code> に任せます。
      自分で文字列を組み立てるより短く、表記も揃います。
    </p>
<pre><code class="language-xml">&lt;fmt:formatNumber value="${'${amount}'}" /&gt;                        &lt;%-- 1,234,567 --%&gt;
&lt;fmt:formatNumber value="${'${amount}'}" type="currency" /&gt;        &lt;%-- ￥1,234,567 --%&gt;
&lt;fmt:formatNumber value="${'${rate}'}"   type="percent" /&gt;         &lt;%-- 18% --%&gt;
&lt;fmt:formatNumber value="${'${rate}'}"   type="percent" maxFractionDigits="1" /&gt;</code></pre>
    <p>
      通貨記号や区切り方は<strong>ロケールで変わります</strong>。既定ではブラウザが送ってくる
      <code>Accept-Language</code> に従うため、見る人によって <code>$</code> になったり
      <code>￥</code> になったりします。表記を固定したいときは
      <code>&lt;fmt:setLocale value="ja_JP" /&gt;</code> をページの先頭で指定します
      （このサンプルもそうしています）。
    </p>
    <p>
      <code>type="percent"</code> は<strong>値を 100 倍</strong>します。
      「18.5%」を出したいなら渡すのは <code>0.185</code> で、
      <code>18.5</code> を渡すと「1,850%」になってしまいます。
      ただし<strong>既定では小数点以下を出しません</strong>。
      <code>0.185</code> をそのまま出すと「18%」までしか表示されないので、
      小数を見せたいときは <code>maxFractionDigits</code> が要ります。
    </p>
    <p>
      丸め方にも癖があります。<code>fmt:formatNumber</code> は内部で
      <code>NumberFormat</code> を使っていて、既定の丸めは<strong>四捨五入ではなく
      「偶数への丸め」（HALF_EVEN）</strong>です。
      そのため <code>0.185</code> を小数点以下なしのパーセントにすると
      「19%」ではなく<strong>「18%」</strong>になります
      （上のデモで確かめられます）。金額のように丸め方が決まっているものは、
      Java 側で <code>BigDecimal</code> を使って丸めてから渡します。
    </p>

    <h3>fmt:formatDate は LocalDate では動きません</h3>
    <p>
      <code>fmt:formatDate</code> が受け取れるのは <code>java.util.Date</code> と
      <code>java.util.Calendar</code> だけです。JSTL 1.2 は Java 8 より前の仕様なので、
      <code>LocalDate</code> / <code>LocalDateTime</code> を渡すと、
      タグに値を渡す手前の型変換で
      <code>javax.el.ELException: Cannot convert [2021-04-01] of type
      [class java.time.LocalDate] to [class java.util.Date]</code>
      になり、画面は 500 エラーになります
      （Tomcat では <code>JasperException</code> に包まれて表示されます）。
    </p>
<pre><code class="language-xml">&lt;%-- これは動きません (member.joinedOn は LocalDate) --%&gt;
&lt;fmt:formatDate value="${'${member.joinedOn}'}" pattern="yyyy/MM/dd" /&gt;</code></pre>
<pre><code class="language-java">// Java 側で整形して、画面には文字列を渡す
public String getJoinedOnText() {
    return joinedOn.format(DateTimeFormatter.ofPattern("yyyy年M月d日"));
}</code></pre>
    <p>
      <code>${'${member.joinedOnText}'}</code> と書けば済みます。
      書式を Java 側に置くと単体テストも書けるので、このサンプル集ではこの形に統一しています。
    </p>

    <h2>XSS とエスケープ</h2>
    <p>
      利用者が入力した文字列をそのまま出力すると、
      <code>&lt;script&gt;</code> のようなタグが HTML として解釈されます。
      これがクロスサイトスクリプティング（XSS）です。
      画面に出す直前にエスケープすれば防げます。
    </p>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead><tr><th>書き方</th><th>エスケープ</th><th>使いどころ</th></tr></thead>
        <tbody>
          <tr>
            <td><code>${'${fn:escapeXml(value)}'}</code></td>
            <td>する</td>
            <td>いちばん短い。このサンプル集の既定</td>
          </tr>
          <tr>
            <td><code>&lt;c:out value="${'${value}'}" /&gt;</code></td>
            <td>する（<strong><code>escapeXml</code> の既定が true</strong>）</td>
            <td><code>default</code> 属性で代替文字も出せる</td>
          </tr>
          <tr>
            <td><code>&lt;c:out value="${'${value}'}" escapeXml="false" /&gt;</code></td>
            <td>しない</td>
            <td>サーバ側で作った HTML を出すときだけ</td>
          </tr>
          <tr>
            <td><code>${'${value}'}</code></td>
            <td><strong>しない</strong></td>
            <td>数値・真偽値など、危険な文字が入りえないものだけ</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      素の <code>${'${value}'}</code> がエスケープしないのは、EL が「出力」ではなく
      「値の評価」の仕組みだからです。<strong>文字列を出すときは必ず一手間かける</strong>と
      決めておくのが、いちばん事故が少ない運用です。
    </p>
    <p>
      なお <code>fn:escapeXml</code> が守ってくれるのは<strong>HTML の本文</strong>です。
      <code>&lt;a href="${'${url}'}"&gt;</code> や <code>&lt;script&gt;</code> の中に値を埋めるときは、
      エスケープの種類が違います（URL なら <code>c:url</code>、
      JavaScript へ渡すなら <code>data-</code> 属性に入れて JavaScript 側で読むのが安全です）。
    </p>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>EL が <code>${'${...}'}</code> のまま画面に出る</strong>：
        古い <code>web.xml</code>（Servlet 2.3 以前の DTD）だと EL が無効になります。
        このサイトは Servlet 4.0 の <code>web.xml</code> なので有効です。
        1 ページだけ無効にしたいときは <code>&lt;%@ page isELIgnored="true" %&gt;</code>、
        <strong>タグファイル（<code>.tag</code>）では <code>&lt;%@ tag isELIgnored="true" %&gt;</code></strong>
        です。タグファイルに <code>&lt;%@ page %&gt;</code> と書くと翻訳エラーになります。
      </li>
      <li>
        <strong>解説に EL の書き方そのものを載せたい</strong>：
        普通に書くと評価されてしまいます。
        <strong>EL の文字列リテラル</strong>にすると、中身は評価されずそのまま表示できます
        （このページの「書いた EL」の列は、すべてこの書き方です）。
<pre><code class="language-xml">&lt;%-- 画面に ${'${member.name}'} と出したいとき --%&gt;
&lt;code&gt;$&#123;'$&#123;member.name&#125;'&#125;&lt;/code&gt;</code></pre>
        式の中に <code>'</code> がある場合（<code>${"${settings['page-size']}"}</code> など）は、
        外側を <code>"</code> にします。
      </li>
      <li>
        <strong><code>${'${settings.page-size}'}</code> が動かない</strong>：
        ドット記法が使えるのは Java の識別子として正しい名前だけです。
        <code>-</code> は引き算に見えてしまうため、
        <code>${"${settings['page-size']}"}</code> と角括弧で書きます。
        キーが変数に入っているとき（<code>${"${settings[key]}"}</code>）も角括弧です。
      </li>
      <li>
        <strong>小数の計算結果がおかしい</strong>：
        EL の除算と小数を含む計算は <code>double</code> になります。
        <code>${'${0.1 + 0.2}'}</code> は <code>0.30000000000000004</code> です。
        金額の計算は Java 側（<code>BigDecimal</code>）で済ませ、
        JSP では表示の整形だけを行います。
      </li>
      <li>
        <strong><code>c:forEach</code> の中で合計を出したい</strong>：
        <code>c:set</code> で足し込むこともできますが、読みづらく間違いやすくなります。
        合計は Servlet か Bean 側で計算し、JSP には結果だけ渡します。
      </li>
      <li>
        <strong><code>c:if</code> に else が無い</strong>：
        反対の条件をもう 1 つ書くと、条件を直すときに片方だけ直して食い違います。
        2 つ以上に分かれるなら <code>c:choose</code> を使います。
      </li>
      <li>
        <strong><code>&lt;jsp:attribute&gt;</code> の直前に JSP コメントを書くとエラー</strong>：
        <code>&lt;jsp:body&gt;</code> も同じです。コメントは要素の<strong>内側</strong>に書きます。
      </li>
      <li>
        <strong><code>fn:join</code> に List を渡してエラー</strong>：
        <code>fn:join</code> の引数は <code>String[]</code> です。
        List をつなぎたいときは <code>c:forEach</code> と
        <code>${'${not st.last}'}</code> で区切り文字を書きます。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <%-- 通貨やパーセントの表記はロケールで変わるので、このページは日本語表記に固定する。
         先頭に置くと、以降の fmt: タグすべてに効く --%>
    <fmt:setLocale value="ja_JP" />

    <%-- ============================================================
         値を変えて試す (GET なので条件が URL に残る)
         ============================================================ --%>
    <t:panel title="値を変えて試す" note="下の表の結果がその場で変わります">
      <form action="${demoUrl}" method="get" class="form-row align-items-end">
        <div class="form-group col-md-3 mb-2">
          <label for="stockInput">在庫数 <code>stock</code></label>
          <input type="number" class="form-control" id="stockInput" name="stock"
                 min="0" max="999" value="${stock}">
          <small class="form-text text-muted">0 / 3 / 12 で表示が変わります</small>
        </div>
        <div class="form-group col-md-4 mb-2">
          <label for="nicknameInput">ニックネーム <code>nickname</code></label>
          <input type="text" class="form-control" id="nicknameInput" name="nickname"
                 maxlength="30" value="${fn:escapeXml(nickname)}">
          <small class="form-text text-muted">空にすると <code>empty</code> が true になります</small>
        </div>
        <div class="form-group col-md-3 mb-2">
          <label for="textSelect">エスケープ比較用の文字列</label>
          <select class="form-control" id="textSelect" name="text">
            <c:forEach var="preset" items="${textPresets}">
              <option value="${fn:escapeXml(preset.key)}"
                      ${preset.key eq textKey ? 'selected' : ''}>${fn:escapeXml(preset.value)}</option>
            </c:forEach>
          </select>
          <small class="form-text text-muted">サーバへ送るのはキーだけです</small>
        </div>
        <div class="form-group col-md-2 mb-2">
          <button type="submit" class="btn btn-primary btn-block">反映する</button>
        </div>
      </form>
      <p class="text-muted small mb-0">
        <a href="${demoUrl}">初期値に戻す</a>
        ｜ 値は Servlet 側で範囲を丸めているので、<code>?stock=abc</code> や
        <code>?stock=-1</code> を直接打ち込んでも画面は落ちません。
      </p>
    </t:panel>

    <%-- ============================================================
         Servlet が用意した値
         ============================================================ --%>
    <t:panel title="Servlet が用意した値" note="この 1 リクエストの間だけ有効なリクエストスコープ">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-25">名前</th><th class="w-25">型</th><th>いまの値</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>sampleCode</code></td><td>String</td>
              <td><code>${fn:escapeXml(sampleCode)}</code></td>
            </tr>
            <tr>
              <td><code>tagCsv</code></td><td>String</td>
              <td><code>${fn:escapeXml(tagCsv)}</code></td>
            </tr>
            <tr>
              <td><code>price</code> / <code>quantity</code></td><td>int</td>
              <td><code>${price}</code> / <code>${quantity}</code></td>
            </tr>
            <tr>
              <td><code>amount</code></td><td>long</td><td><code>${amount}</code></td>
            </tr>
            <tr>
              <td><code>rate</code></td><td>double</td><td><code>${rate}</code></td>
            </tr>
            <tr>
              <td><code>premium</code></td><td>boolean</td><td><code>${premium}</code></td>
            </tr>
            <tr>
              <td><code>member</code></td><td>Bean（Member）</td>
              <td>
                <code>${fn:escapeXml(member)}</code>
                <span class="d-block text-muted small mt-1">
                  Bean をそのまま出力すると <code>toString()</code> が呼ばれます。
                  ふだんは <code>${'${member.name}'}</code> のようにプロパティを指定します。
                </span>
              </td>
            </tr>
            <tr>
              <td><code>settings</code></td><td>Map&lt;String, String&gt;</td>
              <td><code>${fn:escapeXml(settings)}</code></td>
            </tr>
            <tr>
              <td><code>items</code></td><td>List&lt;Item&gt;</td>
              <td><code>${fn:length(items)}</code> 件</td>
            </tr>
            <tr>
              <td><code>emptyItems</code></td><td>List（空）</td>
              <td><code>${fn:length(emptyItems)}</code> 件</td>
            </tr>
            <tr class="table-light">
              <td><code>stock</code> / <code>nickname</code> / <code>textKey</code></td>
              <td>画面から</td>
              <td>
                <code>${stock}</code> /
                <code>${empty nickname ? '(空文字)' : fn:escapeXml(nickname)}</code> /
                <code>${fn:escapeXml(textKey)}</code>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <%-- ============================================================
         EL: プロパティ / Map / List
         ============================================================ --%>
    <t:panel title="EL の書き方 ① プロパティ・Map・List"
             note="左が書いた EL、右がその結果">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書いた EL</th><th>結果</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>${'${member.name}'}</code></td>
              <td>${fn:escapeXml(member.name)}
                <span class="d-block text-muted small">getName() が呼ばれます</span></td>
            </tr>
            <tr>
              <td><code>${'${member.department}'}</code></td>
              <td>${fn:escapeXml(member.department)}</td>
            </tr>
            <tr>
              <td><code>${'${member.age}'}</code></td>
              <td>${member.age}</td>
            </tr>
            <tr>
              <td><code>${'${member.joinedOnText}'}</code></td>
              <td>${fn:escapeXml(member.joinedOnText)}
                <span class="d-block text-muted small">
                  日付の書式は Java 側で済ませています（<code>fmt:formatDate</code> は
                  <code>LocalDate</code> を扱えません）
                </span></td>
            </tr>
            <tr>
              <td><code>${'${member.email}'}</code></td>
              <td>「${fn:escapeXml(member.email)}」
                <span class="d-block text-muted small">
                  getter が null を返しても例外になりません（空文字）
                </span></td>
            </tr>
            <tr>
              <td><code>${'${member.skills}'}</code></td>
              <td>${fn:escapeXml(member.skills)}
                <span class="d-block text-muted small">List をそのまま出すと toString() の形になります</span></td>
            </tr>
            <tr>
              <td><code>${'${settings.theme}'}</code></td>
              <td>${fn:escapeXml(settings.theme)}
                <span class="d-block text-muted small">Map はキー名をプロパティのように書けます</span></td>
            </tr>
            <tr>
              <td><code>${"${settings['page-size']}"}</code></td>
              <td>${fn:escapeXml(settings['page-size'])}
                <span class="d-block text-muted small">
                  キーに <code>-</code> が入っているとドット記法は使えません（引き算に見えるため）
                </span></td>
            </tr>
            <tr>
              <td><code>${'${settings.accentColor}'}</code></td>
              <td>「${fn:escapeXml(settings.accentColor)}」
                <span class="d-block text-muted small">値が null のキー。空文字になります</span></td>
            </tr>
            <tr>
              <td><code>${'${items[0].name}'}</code></td>
              <td>${fn:escapeXml(items[0].name)}
                <span class="d-block text-muted small">List の添字は 0 から</span></td>
            </tr>
            <tr>
              <td><code>${"${items[3]['code']}"}</code></td>
              <td>${fn:escapeXml(items[3]['code'])}
                <span class="d-block text-muted small">Bean のプロパティも角括弧で書けます</span></td>
            </tr>
            <tr>
              <td><code>${'${items[0].sale}'}</code></td>
              <td>${items[0].sale}
                <span class="d-block text-muted small">boolean の getter は <code>isSale()</code></span></td>
            </tr>
            <tr>
              <td><code>${'${param.stock}'}</code></td>
              <td>${fn:escapeXml(param.stock)}
                <span class="d-block text-muted small">
                  リクエストパラメータは <code>param</code> から直接読めます（未指定なら空）
                </span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <%-- ============================================================
         EL: 算術・比較・論理
         ============================================================ --%>
    <t:panel title="EL の書き方 ② 算術・比較・論理"
             note="price = ${price} / quantity = ${quantity} / premium = ${premium}">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書いた EL</th><th>結果</th></tr>
          </thead>
          <tbody>
            <tr><td><code>${'${price + 100}'}</code></td><td>${price + 100}</td></tr>
            <tr><td><code>${'${price * quantity}'}</code></td><td>${price * quantity}</td></tr>
            <tr>
              <td><code>${'${10 / 4}'}</code> / <code>${'${10 div 4}'}</code></td>
              <td>${10 / 4} / ${10 div 4}
                <span class="d-block text-muted small">
                  除算は常に小数になります（整数どうしでも切り捨てられません）
                </span></td>
            </tr>
            <tr>
              <td><code>${'${10 mod 3}'}</code></td>
              <td>${10 mod 3}
                <span class="d-block text-muted small"><code>%</code> と書いても同じです</span></td>
            </tr>
            <tr>
              <td><code>${'${0.1 + 0.2}'}</code></td>
              <td>${0.1 + 0.2}
                <span class="d-block text-muted small">
                  小数を含む計算は double になるため誤差が出ます。金額は Java 側で計算します
                </span></td>
            </tr>
            <tr>
              <td><code>${"${'10' + 5}"}</code></td>
              <td>${'10' + 5}
                <span class="d-block text-muted small">
                  数字の文字列は自動で数値になります（文字列の連結にはなりません）
                </span></td>
            </tr>
            <tr>
              <td><code>${'${price gt 1000}'}</code></td>
              <td>${price gt 1000}
                <span class="d-block text-muted small">
                  <code>gt</code> は <code>&gt;</code> と同じ。
                  <code>lt le ge eq ne</code> も使えます
                </span></td>
            </tr>
            <tr>
              <td><code>${'${member.age le 30}'}</code></td>
              <td>${member.age le 30}</td>
            </tr>
            <tr>
              <td><code>${"${settings.theme eq 'light'}"}</code></td>
              <td>${settings.theme eq 'light'}
                <span class="d-block text-muted small">
                  文字列の比較も <code>eq</code>（Java の <code>equals</code> にあたります）
                </span></td>
            </tr>
            <tr>
              <td><code>${'${premium and stock gt 0}'}</code></td>
              <td>${premium and stock gt 0}
                <span class="d-block text-muted small">
                  <code>and or not</code>。記号で書くなら <code>&amp;&amp; || !</code>
                </span></td>
            </tr>
            <tr>
              <td><code>${'${not premium}'}</code></td>
              <td>${not premium}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <%-- ============================================================
         EL: empty と三項演算子 (null に強い)
         ============================================================ --%>
    <t:panel title="EL の書き方 ③ empty 演算子と三項演算子"
             note="nickname を空にして送ると結果が変わります">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書いた EL</th><th>結果</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>${'${empty nickname}'}</code></td>
              <td><span class="badge badge-${empty nickname ? 'warning' : 'secondary'}">${empty nickname}</span>
                <span class="d-block text-muted small">
                  いまの nickname は「${fn:escapeXml(nickname)}」です
                </span></td>
            </tr>
            <tr>
              <td><code>${'${empty member.email}'}</code></td>
              <td>${empty member.email}
                <span class="d-block text-muted small">null → true</span></td>
            </tr>
            <tr>
              <td><code>${'${empty emptyItems}'}</code></td>
              <td>${empty emptyItems}
                <span class="d-block text-muted small">0 件のコレクション → true</span></td>
            </tr>
            <tr>
              <td><code>${'${empty items}'}</code></td>
              <td>${empty items}
                <span class="d-block text-muted small">4 件入っている → false</span></td>
            </tr>
            <tr>
              <td><code>${'${empty missingValue}'}</code></td>
              <td>${empty missingValue}
                <span class="d-block text-muted small">存在しない変数 → true</span></td>
            </tr>
            <tr>
              <td><code>${'${empty 0}'}</code></td>
              <td>${empty 0}
                <span class="d-block text-muted small">
                  <strong>0 や false は「空」ではありません</strong>
                </span></td>
            </tr>
            <tr>
              <td><code>${'${missingValue.name}'}</code></td>
              <td>「${fn:escapeXml(missingValue.name)}」
                <span class="d-block text-muted small">
                  null のプロパティをたどっても例外になりません（Java なら NullPointerException）
                </span></td>
            </tr>
            <tr>
              <td><code>${"${empty nickname ? '(未設定)' : fn:escapeXml(nickname)}"}</code></td>
              <td>${empty nickname ? '(未設定)' : fn:escapeXml(nickname)}
                <span class="d-block text-muted small">
                  「無ければ代わりの文字」は三項演算子が手軽です
                </span></td>
            </tr>
            <tr>
              <td><code>${"${stock gt 0 ? '在庫あり' : '品切れ'}"}</code></td>
              <td>${stock gt 0 ? '在庫あり' : '品切れ'}</td>
            </tr>
            <tr>
              <td><code>&lt;c:out value="${'${missingValue}'}" default="(未設定)" /&gt;</code></td>
              <td><c:out value="${missingValue}" default="(未設定)" />
                <span class="d-block text-muted small">
                  <code>c:out</code> の <code>default</code> は<strong>値が null のとき</strong>に使われます。
                  空文字も同じに扱いたいなら <code>empty</code> と三項演算子のほうが確実です
                </span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <%-- ============================================================
         c:forEach
         ============================================================ --%>
    <t:panel title="c:forEach で繰り返す" note="varStatus で「いま何番目か」を取れます">
      <div class="table-responsive">
        <table class="table table-sm table-bordered">
          <thead>
            <tr>
              <th>index</th><th>count</th><th>first</th><th>last</th>
              <th>コード</th><th>商品名</th><th class="text-right">価格</th><th>セール</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="item" items="${items}" varStatus="st">
              <tr class="${st.first ? 'table-light' : ''}">
                <td>${st.index}</td>
                <td>${st.count}</td>
                <td>${st.first}</td>
                <td>${st.last}</td>
                <td><code>${fn:escapeXml(item.code)}</code></td>
                <td>${fn:escapeXml(item.name)}</td>
                <td class="text-right"><fmt:formatNumber value="${item.price}" /> 円</td>
                <td>
                  <%-- 繰り返しの中の分岐。true のときだけ出す --%>
                  <c:if test="${item.sale}">
                    <span class="badge badge-danger">セール</span>
                  </c:if>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <p class="text-muted small">
        1 行目だけ背景色が違うのは、<code>&lt;tr class="${"${st.first ? 'table-light' : ''}"}"&gt;</code>
        と書いているためです。<code>varStatus</code> は属性値の中でも使えます。
      </p>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書いたタグ</th><th>結果</th></tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <code>&lt;c:forEach var="skill" items="${'${member.skills}'}" varStatus="st"&gt;</code><br>
                <code>&nbsp;&nbsp;${'${fn:escapeXml(skill)}'}&lt;c:if test="${'${not st.last}'}"&gt; / &lt;/c:if&gt;</code><br>
                <code>&lt;/c:forEach&gt;</code>
              </td>
              <td>
                <c:forEach var="skill" items="${member.skills}" varStatus="st">${fn:escapeXml(skill)}<c:if test="${not st.last}"> / </c:if></c:forEach>
                <span class="d-block text-muted small mt-1">
                  <strong>最後の 1 件だけ区切り文字を出さない</strong>のが <code>last</code> の定番の使い道です
                </span>
              </td>
            </tr>
            <tr>
              <td><code>&lt;c:forEach var="i" begin="1" end="5"&gt;[${'${i}'}]&lt;/c:forEach&gt;</code></td>
              <td>
                <c:forEach var="i" begin="1" end="5">[${i}]</c:forEach>
                <span class="d-block text-muted small mt-1">
                  <code>items</code> を書かなければ、ただの数値の繰り返しになります
                </span>
              </td>
            </tr>
            <tr>
              <td><code>&lt;c:forEach var="i" begin="0" end="10" step="5"&gt;[${'${i}'}]&lt;/c:forEach&gt;</code></td>
              <td><c:forEach var="i" begin="0" end="10" step="5">[${i}]</c:forEach></td>
            </tr>
            <tr>
              <td>
                <code>&lt;c:forEach var="e" items="${'${settings}'}"&gt;</code><br>
                <code>&nbsp;&nbsp;${'${e.key}'} = ${'${e.value}'}</code><br>
                <code>&lt;/c:forEach&gt;</code>
              </td>
              <td>
                <ul class="list-unstyled mb-0">
                  <c:forEach var="e" items="${settings}">
                    <li>
                      <code>${fn:escapeXml(e.key)}</code> =
                      ${empty e.value ? '(未設定)' : fn:escapeXml(e.value)}
                    </li>
                  </c:forEach>
                </ul>
                <span class="d-block text-muted small mt-1">
                  Map を回すと <code>key</code> と <code>value</code> が取れます
                  （LinkedHashMap なので入れた順のままです）
                </span>
              </td>
            </tr>
            <tr>
              <td><code>&lt;c:forEach items="${'${emptyItems}'}"&gt;</code>（0 件のとき）</td>
              <td>
                <c:forEach var="e" items="${emptyItems}">${fn:escapeXml(e)}</c:forEach>
                <span class="text-muted">（何も出力されません）</span>
                <span class="d-block text-muted small mt-1">
                  「0 件です」と出したいときは <code>&lt;c:if test="${'${empty emptyItems}'}"&gt;</code> を別に書きます
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <%-- ============================================================
         c:if / c:choose
         ============================================================ --%>
    <t:panel title="c:if と c:choose で分岐する"
             note="在庫数 stock = ${stock} を変えると結果が変わります">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書いたタグ</th><th>結果</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>&lt;c:if test="${'${stock eq 0}'}"&gt;品切れ&lt;/c:if&gt;</code></td>
              <td>
                <c:if test="${stock eq 0}"><span class="badge badge-danger">品切れ</span></c:if>
                <c:if test="${stock ne 0}"><span class="text-muted">（条件が false なので何も出ません）</span></c:if>
                <span class="d-block text-muted small mt-1">
                  <code>c:if</code> に else はありません
                </span>
              </td>
            </tr>
            <tr>
              <td>
                <code>&lt;c:choose&gt;</code><br>
                <code>&nbsp;&nbsp;&lt;c:when test="${'${stock eq 0}'}"&gt;品切れ&lt;/c:when&gt;</code><br>
                <code>&nbsp;&nbsp;&lt;c:when test="${'${stock le 5}'}"&gt;残りわずか&lt;/c:when&gt;</code><br>
                <code>&nbsp;&nbsp;&lt;c:otherwise&gt;在庫あり&lt;/c:otherwise&gt;</code><br>
                <code>&lt;/c:choose&gt;</code>
              </td>
              <td>
                <c:choose>
                  <c:when test="${stock eq 0}">
                    <span class="badge badge-danger">品切れ</span>
                  </c:when>
                  <c:when test="${stock le 5}">
                    <span class="badge badge-warning">残りわずか（あと ${stock} 個）</span>
                  </c:when>
                  <c:otherwise>
                    <span class="badge badge-success">在庫あり（${stock} 個）</span>
                  </c:otherwise>
                </c:choose>
                <span class="d-block text-muted small mt-1">
                  上から順に見て、<strong>最初に true になった 1 つだけ</strong>が出力されます。
                  条件は狭いものから並べます
                </span>
              </td>
            </tr>
            <tr>
              <td><code>&lt;c:if test="${'${not empty nickname and premium}'}"&gt;</code></td>
              <td>
                <c:choose>
                  <c:when test="${not empty nickname and premium}">条件を満たしています</c:when>
                  <c:otherwise><span class="text-muted">条件を満たしていません</span></c:otherwise>
                </c:choose>
                <span class="d-block text-muted small mt-1">
                  条件は <code>and</code> / <code>or</code> でつなげます
                </span>
              </td>
            </tr>
            <tr>
              <td><code>class="${"${stock eq 0 ? 'text-danger' : 'text-success'}"}"</code></td>
              <td>
                <span class="${stock eq 0 ? 'text-danger' : 'text-success'}">
                  在庫: ${stock} 個
                </span>
                <span class="d-block text-muted small mt-1">
                  属性値の中では三項演算子が便利です（タグでは書けません）
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <%-- ============================================================
         c:set / c:remove
         ============================================================ --%>
    <t:panel title="c:set で変数を作り、c:remove で消す"
             note="scope を省略すると page スコープ（このページを組み立てている間だけ）">
      <%-- 表の途中でも c:set / c:remove は書けます (出力は何も出ません) --%>
      <c:set var="taxRate" value="0.10" />
      <c:set var="taxIncluded" value="${price * (1 + taxRate)}" />
      <c:set var="greeting">こんにちは、${fn:escapeXml(member.name)} さん</c:set>
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書いたタグ / EL</th><th>結果</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>&lt;c:set var="taxRate" value="0.10" /&gt;</code> → <code>${'${taxRate}'}</code></td>
              <td>${taxRate}</td>
            </tr>
            <tr>
              <td><code>&lt;c:set var="taxIncluded" value="${'${price * (1 + taxRate)}'}" /&gt;</code></td>
              <td>${taxIncluded}
                <span class="d-block text-muted small">
                  文字列 "0.10" は計算のときに数値へ変換されます。
                  小数が混ざると結果は <code>double</code> になるので、
                  整数どうしの計算のつもりでも末尾に <code>.0</code> が付きます
                  （組み合わせによっては上の <code>${'${0.1 + 0.2}'}</code> のような誤差も出ます）
                </span></td>
            </tr>
            <tr>
              <td><code>&lt;fmt:formatNumber value="${'${taxIncluded}'}" maxFractionDigits="0" /&gt;</code></td>
              <td><fmt:formatNumber value="${taxIncluded}" maxFractionDigits="0" /> 円
                <span class="d-block text-muted small">表示のときに丸めれば見た目は整います</span></td>
            </tr>
            <tr>
              <td>
                <code>&lt;c:set var="greeting"&gt;こんにちは、${'${fn:escapeXml(member.name)}'} さん&lt;/c:set&gt;</code>
              </td>
              <td>${greeting}
                <span class="d-block text-muted small">
                  本文で書くと、長い文字列や HTML を含むものが読みやすくなります
                </span></td>
            </tr>
            <tr>
              <td><code>&lt;c:remove var="taxRate" /&gt;</code> のあとの <code>${'${empty taxRate}'}</code></td>
              <td>
                <c:remove var="taxRate" />
                ${empty taxRate}
                <span class="d-block text-muted small">
                  消えたので true。<code>c:set</code> で <code>value=""</code> を入れるのとは別です
                  （こちらは変数ごと無くなります）
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <%-- ============================================================
         fn: の関数
         ============================================================ --%>
    <t:panel title="fn: の関数で文字列を扱う"
             note="sampleCode = &quot;${sampleCode}&quot; / tagCsv = &quot;${tagCsv}&quot;">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書いた EL</th><th>結果</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>${'${fn:length(sampleCode)}'}</code></td>
              <td>${fn:length(sampleCode)}
                <span class="d-block text-muted small">文字列なら文字数</span></td>
            </tr>
            <tr>
              <td><code>${'${fn:length(items)}'}</code></td>
              <td>${fn:length(items)}
                <span class="d-block text-muted small">コレクションなら件数</span></td>
            </tr>
            <tr>
              <td><code>${'${fn:length(member.email)}'}</code></td>
              <td>${fn:length(member.email)}
                <span class="d-block text-muted small">null を渡しても 0（落ちません）</span></td>
            </tr>
            <tr>
              <td><code>${"${fn:contains(sampleCode, 'basics')}"}</code></td>
              <td>${fn:contains(sampleCode, 'basics')}</td>
            </tr>
            <tr>
              <td><code>${"${fn:containsIgnoreCase(sampleCode, 'JSP')}"}</code></td>
              <td>${fn:containsIgnoreCase(sampleCode, 'JSP')}
                <span class="d-block text-muted small">
                  <code>fn:contains</code> は大文字小文字を区別します
                </span></td>
            </tr>
            <tr>
              <td><code>${'${fn:toUpperCase(sampleCode)}'}</code></td>
              <td>${fn:escapeXml(fn:toUpperCase(sampleCode))}</td>
            </tr>
            <tr>
              <td><code>${'${fn:substring(sampleCode, 0, 3)}'}</code></td>
              <td>${fn:escapeXml(fn:substring(sampleCode, 0, 3))}
                <span class="d-block text-muted small">
                  終了位置は含みません。範囲外を指定しても例外にならず空文字です
                </span></td>
            </tr>
            <tr>
              <td><code>${"${fn:join(fn:split(tagCsv, ','), ' / ')}"}</code></td>
              <td>${fn:escapeXml(fn:join(fn:split(tagCsv, ','), ' / '))}
                <span class="d-block text-muted small">
                  <code>fn:split</code> の戻り値は配列なので、そのまま <code>fn:join</code> に渡せます
                </span></td>
            </tr>
            <tr>
              <td>
                <code>&lt;c:forEach var="tag" items="${"${fn:split(tagCsv, ',')}"}"&gt;</code>
              </td>
              <td>
                <c:forEach var="tag" items="${fn:split(tagCsv, ',')}">
                  <span class="badge badge-secondary">${fn:escapeXml(tag)}</span>
                </c:forEach>
                <span class="d-block text-muted small mt-1">
                  分割した配列は <code>c:forEach</code> にそのまま渡せます
                </span>
              </td>
            </tr>
            <tr>
              <td><code>${"${fn:replace(tagCsv, ',', ' + ')}"}</code></td>
              <td>${fn:escapeXml(fn:replace(tagCsv, ',', ' + '))}</td>
            </tr>
            <tr>
              <td><code>${"${fn:trim('  余白つき  ')}"}</code></td>
              <td>「${fn:escapeXml(fn:trim('  余白つき  '))}」</td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <%-- ============================================================
         fmt:formatNumber
         ============================================================ --%>
    <t:panel title="fmt:formatNumber で数値を整形する"
             note="amount = ${amount} / rate = ${rate}（表記は ja_JP に固定しています）">
      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書いたタグ</th><th>結果</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><code>&lt;fmt:formatNumber value="${'${amount}'}" /&gt;</code></td>
              <td><fmt:formatNumber value="${amount}" />
                <span class="d-block text-muted small">既定で 3 桁区切りになります</span></td>
            </tr>
            <tr>
              <td><code>&lt;fmt:formatNumber value="${'${amount}'}" groupingUsed="false" /&gt;</code></td>
              <td><fmt:formatNumber value="${amount}" groupingUsed="false" />
                <span class="d-block text-muted small">区切りを外したいときはこちら</span></td>
            </tr>
            <tr>
              <td><code>&lt;fmt:formatNumber value="${'${amount}'}" type="currency" /&gt;</code></td>
              <td><fmt:formatNumber value="${amount}" type="currency" />
                <span class="d-block text-muted small">
                  通貨記号はロケールで変わります（<code>fmt:setLocale</code> で固定できます）
                </span></td>
            </tr>
            <tr>
              <td><code>&lt;fmt:formatNumber value="${'${rate}'}" type="percent" /&gt;</code></td>
              <td><fmt:formatNumber value="${rate}" type="percent" />
                <span class="d-block text-muted small">
                  <strong>値は 100 倍されます</strong>。既定では小数点以下を出しません
                </span></td>
            </tr>
            <tr>
              <td>
                <code>&lt;fmt:formatNumber value="${'${rate}'}" type="percent" maxFractionDigits="1" /&gt;</code>
              </td>
              <td><fmt:formatNumber value="${rate}" type="percent" maxFractionDigits="1" /></td>
            </tr>
            <tr>
              <td><code>&lt;fmt:formatNumber value="${'${price}'}" pattern="#,##0.00" /&gt;</code></td>
              <td><fmt:formatNumber value="${price}" pattern="#,##0.00" />
                <span class="d-block text-muted small">
                  細かく決めたいときは <code>pattern</code>（<code>DecimalFormat</code> と同じ書式）
                </span></td>
            </tr>
            <tr>
              <td>
                <code>&lt;fmt:formatNumber value="${'${amount}'}" var="amountText" /&gt;</code> →
                <code>${'${amountText}'}</code>
              </td>
              <td>
                <fmt:formatNumber value="${amount}" var="amountText" />
                ${amountText} 円
                <span class="d-block text-muted small">
                  <code>var</code> を付けるとその場には出力せず、変数に入ります
                  （属性値の中で使いたいときに便利です）
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <%-- ============================================================
         エスケープあり / なしの比較
         ============================================================ --%>
    <t:panel title="エスケープあり / なしを見比べる"
             note="上の選択欄で文字列を切り替えられます">
      <p>
        いま選んでいる文字列は、Java の中では次のようになっています
        （これ自体もエスケープして表示しています）。
      </p>
      <pre class="mb-3"><code class="language-plaintext">${fn:escapeXml(sampleText)}</code></pre>

      <div class="table-responsive">
        <table class="table table-sm table-bordered mb-0">
          <thead>
            <tr><th class="w-50">書いたもの</th><th>画面に出るもの</th></tr>
          </thead>
          <tbody>
            <tr class="table-success">
              <td><code>${'${fn:escapeXml(sampleText)}'}</code></td>
              <td>${fn:escapeXml(sampleText)}
                <span class="d-block text-muted small mt-1">
                  <strong>安全</strong>：タグが文字として表示されます
                </span></td>
            </tr>
            <tr class="table-success">
              <td><code>&lt;c:out value="${'${sampleText}'}" /&gt;</code></td>
              <td><c:out value="${sampleText}" />
                <span class="d-block text-muted small mt-1">
                  <strong>安全</strong>：<code>c:out</code> の <code>escapeXml</code> は
                  <strong>既定が true</strong> なので、何も書かなくてもエスケープされます
                </span></td>
            </tr>
            <tr class="table-danger">
              <td><code>${'${sampleText}'}</code></td>
              <td>${sampleText}
                <span class="d-block text-muted small mt-1">
                  <strong>危険</strong>：HTML として解釈され、太字や色が変わります。
                  ここに <code>&lt;script&gt;</code> が入っていたら実行されます
                </span></td>
            </tr>
            <tr class="table-danger">
              <td><code>&lt;c:out value="${'${sampleText}'}" escapeXml="false" /&gt;</code></td>
              <td><c:out value="${sampleText}" escapeXml="false" />
                <span class="d-block text-muted small mt-1">
                  <strong>危険</strong>：上と同じです。<code>escapeXml="false"</code> は
                  サーバ側で組み立てた HTML を出すときだけに使います
                </span></td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="alert alert-warning mt-3 mb-0">
        <strong>この比較では、利用者が入力した文字列を使っていません。</strong>
        入力欄の内容をそのまま（エスケープせずに）表示すると、
        このサンプル自体がクロスサイトスクリプティングの穴になります。
        そのため選択肢の<strong>キーだけ</strong>を受け取り、
        実際に表示する文字列は <code>JspBasicsServlet</code> が持っているもの
        （太字や色が変わるだけの無害なもの）から選んでいます。
      </div>
    </t:panel>
  </jsp:body>
</t:sample>
