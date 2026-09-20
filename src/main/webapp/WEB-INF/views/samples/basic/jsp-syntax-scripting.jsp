<%--
  【サンプル】JSP の記法 : 宣言 <%! %> / スクリプトレット <% %> / 式 <%= %> を実際に動かす部品

  この画面は jsp-syntax.jsp から <jsp:include> で呼ばれています。
  わざわざ別ファイルにしているのには理由があります。

    タグファイル (/WEB-INF/tags/*.tag) の本文は、既定で body-content="scriptless" です。
    そのため <t:sample> や <t:panel> の中には <% %> を書けません (翻訳エラーになります)。
    動的インクルードで呼ばれるページは「別の JSP」として翻訳されるので、
    こちらには昔ながらの記法を自由に書けます。

  中身は「読めるようになる」ための見本です。
  新しく書く画面では EL と JSTL を使ってください (理由は解説タブにあります)。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.time.LocalTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.List" %>

<%!
    /*
     * 宣言 : 生成された Servlet クラスの「フィールド」と「メソッド」になります。
     * _jspService メソッドの外側なので、インスタンス変数はリクエストをまたいで残ります。
     */

    /** このページが呼ばれた回数。アプリを再起動するまで増え続けます (わざと悪い例にしています)。 */
    private int renderCount = 0;

    /** 宣言では、このようにメソッドも定義できます。 */
    private String yen(int amount) {
        return String.format("%,d 円", amount);
    }
%>

<%
    // スクリプトレット : _jspService メソッドの中身になります。
    // ここで宣言した変数はローカル変数なので、リクエストごとに別物です。
    renderCount++;                       // ← インスタンス変数を書き換えている (下の注意書きを参照)

    List<String> names = Arrays.asList("ボールペン（黒）", "ノート A5", "クリアファイル 10 枚組");
    int[] prices = {120, 280, 450};

    int total = 0;
    for (int price : prices) {
        total += price;
    }

    String now = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
%>

<p class="mb-2">
  <%-- 式 : 値を 1 つ書き出します。文ではないので、末尾に ; を書くとエラーになります --%>
  いまの時刻は <strong><%= now %></strong> です。
  このページが読み込まれた回数は <strong><%= renderCount %></strong> 回目です。
</p>

<table class="table table-sm table-bordered">
  <thead class="thead-light">
    <tr><th scope="col">#</th><th scope="col">品名</th><th scope="col" class="text-right">単価</th></tr>
  </thead>
  <tbody>
    <%-- スクリプトレットは途中で切って HTML を挟めます (中かっこの対応に注意) --%>
    <% for (int i = 0; i < names.size(); i++) { %>
      <tr>
        <th scope="row"><%= i + 1 %></th>
        <td><%= names.get(i) %></td>
        <td class="text-right"><%= yen(prices[i]) %></td>
      </tr>
    <% } %>
    <tr>
      <th scope="row" colspan="2">合計</th>
      <td class="text-right"><strong><%= yen(total) %></strong></td>
    </tr>
  </tbody>
</table>

<h4 class="h6">暗黙オブジェクト（スクリプトレットから）</h4>
<div class="table-responsive">
  <table class="table table-sm table-bordered">
    <thead class="thead-light">
      <tr><th scope="col">書いたもの</th><th scope="col">結果</th></tr>
    </thead>
    <tbody>
      <tr>
        <td><code>&lt;%= request.getMethod() %&gt;</code></td>
        <td><%= request.getMethod() %></td>
      </tr>
      <tr>
        <td><code>&lt;%= request.getRequestURI() %&gt;</code></td>
        <td><%= request.getRequestURI() %></td>
      </tr>
      <tr>
        <td><code>&lt;%= application.getServerInfo() %&gt;</code></td>
        <td><%= application.getServerInfo() %></td>
      </tr>
      <tr>
        <td><code>&lt;%= out.getBufferSize() %&gt;</code></td>
        <td><%= out.getBufferSize() %> バイト</td>
      </tr>
      <tr>
        <td><code>&lt;%= pageContext.getServletContext().getContextPath() %&gt;</code></td>
        <td><code><%= pageContext.getServletContext().getContextPath() %></code>（空文字ならルート）</td>
      </tr>
    </tbody>
  </table>
</div>

<div class="alert alert-warning">
  <p class="mb-1"><strong>宣言 <code>&lt;%! %&gt;</code> はインスタンス変数になります</strong></p>
  <p class="mb-0">
    上の「読み込まれた回数」は <code>&lt;%! private int renderCount = 0; %&gt;</code> で宣言した変数です。
    Servlet はアプリ全体で 1 つしか作られないので、<strong>この値はすべての利用者で共有されます</strong>。
    同時にアクセスされれば数もずれます（<code>++</code> は不可分な操作ではありません）。
    リクエストごとの値は、スクリプトレットの中のローカル変数か、リクエストスコープに置いてください。
  </p>
</div>

<%-- 静的インクルード : 翻訳の前に、このファイルの中身をここへ貼り付けます --%>
<%@ include file="jsp-syntax-part.jspf" %>
