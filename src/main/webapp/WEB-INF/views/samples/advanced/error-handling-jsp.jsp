<%--
  【サンプル】JSP の中で例外が起きたとき (その 1 : 例外を起こす側)

  page ディレクティブの errorPage 属性で、この JSP 専用のエラーページを指定できます。
  web.xml の <error-page> がアプリ全体の設定なのに対して、こちらは 1 ページだけの設定です。

  ・ページ単位で指定したいとき (この画面だけ専用の案内を出したい) に使います
  ・両方書いた場合は、ページ側の errorPage が優先されます

  このサンプルでは <t:layout> を使わず、素の HTML にしています。
  タグファイルの本文は scriptless (スクリプトレットを書けない) のため、
  例外をわざと起こすコードを本文へ直接書けないからです。

  ここで出力している HTML は、例外が起きた時点で「バッファごと捨てられる」ので、
  ブラウザには届きません。届くのは errorPage に指定した JSP が出力した HTML だけです。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
         errorPage="/WEB-INF/views/samples/advanced/error-handling-jsp-error.jsp" %>
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>集計結果</title>
</head>
<body>
  <h1>集計結果</h1>
  <p>ここまでの HTML は出力済みですが、下で例外が起きるので画面には届きません。</p>

  <%
    // 「画面を組み立てている途中で落ちる」典型例。
    // 一覧を回している最中に、想定していなかった値が 1 件混ざっていた、という状況です
    String[] amounts = {"1200", "980", "(未設定)", "450"};
    int total = 0;
    for (String amount : amounts) {
        total += Integer.parseInt(amount);   // "(未設定)" で NumberFormatException
    }
  %>

  <p>合計: <%= total %> 円</p>
</body>
</html>
