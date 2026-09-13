# サンプルの追加手順

サンプル 1 件を追加するのに必要なのは、基本的に **JSP 1 枚** と **定義 1 件** です。

```
1. JSP を作る          src/main/webapp/WEB-INF/views/samples/{カテゴリ}/{ID}.jsp
2. カタログに登録する    src/main/java/com/example/servletsample/catalog/SampleDefinitions.java
3. （必要なら）Servlet   src/main/java/com/example/servletsample/samples/{カテゴリ}/{名前}Servlet.java
```

URL と JSP の場所は ID とカテゴリから自動的に決まります。

| | 決まり |
| --- | --- |
| URL | `/samples/{カテゴリID}/{サンプルID}` |
| JSP | `/WEB-INF/views/samples/{カテゴリID}/{サンプルID}.jsp` |

---

## パターン A: JSP だけのサンプル

画面を見せるだけ（フォームの送信先が無い、表示のみ）のサンプルです。
`SampleDispatcherServlet` が URL から JSP を探して転送するので、Java を書く必要はありません。

### 1. JSP を作る

`src/main/webapp/WEB-INF/views/samples/design/card-layout.jsp`

```jsp
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="card-layout">

  <jsp:attribute name="explanation">
    <h2>ポイント</h2>
    <ul>
      <li>解説をここに書きます（省略すると「解説」タブ自体が出ません）</li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <t:panel title="デモ">
      ここに動かしたい HTML を書きます。
    </t:panel>
  </jsp:body>
</t:sample>
```

> **注意**: `<jsp:attribute>` や `<jsp:body>` の**直前**に JSP コメント（`<%-- --%>`）を書くとエラーになります。
> コメントは要素の内側に書いてください。

### 2. カタログに登録する

`SampleDefinitions.define()` に追加します。

```java
samples.add(Sample.builder("card-layout", Category.DESIGN)
        .title("カードを並べる一覧レイアウト")
        .summary("一覧をカード形式で並べる画面の作り方。")
        .tags("Bootstrap4", "カード", "一覧")
        .build());
```

これだけで、トップページ・サイドバー・カテゴリ一覧・検索に反映されます。
表示するソースコードには JSP 自身が自動で追加されます。

---

## パターン B: Servlet があるサンプル

入力を受け取る、DB の代わりのデータを組み立てる、といった処理が必要な場合です。

### 1. Servlet を作る

`src/main/java/com/example/servletsample/samples/form/InputValidationServlet.java`

```java
package com.example.servletsample.samples.form;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/** 【サンプル】入力チェック */
@WebServlet(name = "inputValidation", urlPatterns = {"/samples/form/input-validation"})
public class InputValidationServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        forward(request, response, "/WEB-INF/views/samples/form/input-validation.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // 入力を受け取って検証する処理
        doGet(request, response);
    }
}
```

**URL は完全一致で指定してください。** Servlet 仕様では完全一致のマッピングが
前方一致（`/samples/*`）より優先されるため、こちらが呼ばれます。

### 2. JSP を作る

パターン A と同じです（`sampleId` は登録する ID に合わせます）。

### 3. カタログに登録する（ソースも一緒に表示する）

```java
samples.add(Sample.builder("input-validation", Category.FORM)
        .title("入力チェック（バリデーション）")
        .summary("必須・桁数・形式のチェックとエラーメッセージの表示。")
        .tags("フォーム", "バリデーション", "POST")
        .source(InputValidationServlet.class)   // ← Servlet のソースも表示する
        .build());
```

`.source(クラス)` を書いた順にソースコードのタブへ並びます（JSP は自動で末尾に追加）。

---

## 使える部品

### レイアウト用タグ（`/WEB-INF/tags`）

| タグ | 用途 |
| --- | --- |
| `<t:layout title="...">` | サイト共通の枠（ヘッダー・サイドバー・フッター） |
| `<t:sample sampleId="...">` | サンプルページの枠（デモ / ソース / 解説タブ、前後リンク） |
| `<t:panel title="..." note="...">` | サンプルの中の見出し付きの箱 |
| `<t:sampleCard sample="${s}">` | 一覧用のカード |
| `<t:icon name="house" size="16">` | アイコン（Bootstrap Icons をインラインで保持） |

`<t:icon>` で使える名前: `house` `journal-code` `palette` `input-cursor-text` `table`
`shield-lock` `file-earmark-arrow-up` `arrow-repeat` `gear` `search` `github`
`chevron-right` `code-slash` `grid` `lightbulb` `check-circle` `list` `external`

### ソースコード表示タグ

```jsp
<%@ taglib prefix="site" uri="http://example.com/jsp/servlet-sample" %>

<site:source path="/WEB-INF/views/samples/basic/hello-world.jsp" language="xml" />
```

`<t:sample>` を使っていれば自動で表示されるので、通常は直接書く必要はありません。

---

## 追加のオプション

```java
Sample.builder("sample-id", Category.LIST)
        .title("タイトル")
        .summary("一覧に出る説明")
        .status(SampleStatus.PLANNED)          // 準備中（グレー表示・リンク無し）
        .tags("タグ1", "タグ2")                 // 検索対象になる
        .source(FooServlet.class)              // Java のソースを表示
        .source(SourceFile.css("/WEB-INF/..."))// 任意のファイルを表示
        .path("/samples/list/custom-url")      // URL を既定から変える
        .viewPath("/WEB-INF/views/other.jsp")  // JSP の場所を既定から変える
        .build();
```

`SampleStatus` は 3 種類あります。

| 値 | 表示 | リンク |
| --- | --- | --- |
| `READY`（既定） | 公開中 | あり |
| `WIP` | 作成中 | あり |
| `PLANNED` | 準備中 | なし（一覧にグレー表示のみ） |

「これから作るサンプル」を先に `PLANNED` で登録しておくと、サイト上に予定として並びます。

---

## カテゴリを増やす

`src/main/java/com/example/servletsample/catalog/Category.java` に 1 行足します。

```java
REPORT("report", "帳票", "PDF / Excel 出力", "file-earmark-arrow-up"),
```

引数は順に「URL に使う ID」「表示名」「説明」「アイコン名」です。
定義順がそのままサイドバーとトップページの並び順になります。

---

## 確認

```bash
mvn test                        # 登録内容の整合性をチェック
docker compose up -d --build    # 起動して画面を確認
```

`mvn test` では次を検査しています。

- サンプル ID / URL が重複していないか
- 公開中のサンプルに対応する JSP が実在するか
- 表示するソースが 1 件以上あるか
- 準備中のサンプルが検索結果に出ていないか
