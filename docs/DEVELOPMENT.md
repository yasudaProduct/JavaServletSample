# 開発メモ

このサンプル集がどう動いているか、どこを触れば何が変わるかのメモです。

## 目次

- [起動の仕組み](#起動の仕組み)
- [ホットリロードの仕組み](#ホットリロードの仕組み)
- [リクエストの流れ](#リクエストの流れ)
- [ソースコードを画面に表示している仕組み](#ソースコードを画面に表示している仕組み)
- [組み込みデータベース](#組み込みデータベース)
- [リモートデバッグ](#リモートデバッグ)
- [Jakarta EE（Tomcat 10 以降）へ移行する場合](#jakarta-ee-tomcat-10-以降-へ移行する場合)

---

## 起動の仕組み

`docker compose up --build` で行われることは 2 段階です（`docker/tomcat/Dockerfile`）。

```
[build ステージ]  maven:3.9-eclipse-temurin-17
      mvn package  →  target/ROOT/（展開された WAR）

[runtime ステージ]  tomcat:9.0-jdk17-temurin
      target/ROOT/ を /usr/local/tomcat/webapps/ROOT/ へコピー
      catalina.sh jpda run で起動（8080 = HTTP / 8000 = デバッグ）
```

`ROOT` という名前で配置しているため、アプリは `http://localhost:8080/`（サブパス無し）で開きます。
Maven 側は `pom.xml` の `<finalName>ROOT</finalName>` で名前を合わせています。

Maven の依存解決は Docker のキャッシュマウント（`--mount=type=cache,target=/root/.m2`）を使うので、
2 回目以降のビルドはライブラリを再ダウンロードしません。

> Docker と Maven を使わず、Eclipse 同梱の Ant だけでビルドすることもできます
> （`ant war` → `dist/ROOT.war`）。手順は **[ECLIPSE.md](ECLIPSE.md)** にあります。
> 両者は同じ内容の WAR を作ります。

---

## ホットリロードの仕組み

`docker-compose.yml` で、ホストのディレクトリをコンテナ内の配置先に重ねています。

| ホスト | コンテナ |
| --- | --- |
| `src/main/webapp/WEB-INF/views` | `/usr/local/tomcat/webapps/ROOT/WEB-INF/views` |
| `src/main/webapp/WEB-INF/tags` | `/usr/local/tomcat/webapps/ROOT/WEB-INF/tags` |
| `src/main/webapp/assets` | `/usr/local/tomcat/webapps/ROOT/assets` |
| `src/main/java` | `/usr/local/tomcat/webapps/ROOT/WEB-INF/sources/java` |

JSP は Tomcat が更新を検知して自動で再コンパイルするため、**保存 → ブラウザ再読み込み**で反映されます
（Tomcat の既定では 4 秒間隔でチェック）。CSS / JS も同様です。

Java のクラスファイルはコンテナ内にビルド済みのものが入っているため、
Java を変更したときだけ `docker compose up -d --build` が必要です。

---

## リクエストの流れ

```
ブラウザ
   │
   ├─ /                          → HomeServlet        → /WEB-INF/views/home.jsp
   ├─ /categories/{id}           → CategoryServlet    → /WEB-INF/views/category.jsp
   ├─ /search?q=...              → SearchServlet      → /WEB-INF/views/search.jsp
   ├─ /about                     → AboutServlet       → /WEB-INF/views/about.jsp
   │
   ├─ /samples/basic/hello-world → HelloWorldServlet   → .../samples/basic/hello-world.jsp
   │                                （完全一致のマッピングが優先される）
   ├─ /samples/basic/request-parameter    → RequestParameterServlet
   ├─ /samples/basic/forward-redirect     → ForwardRedirectServlet
   ├─ /samples/basic/scope                → ScopeServlet
   ├─ /samples/basic/servlet-lifecycle    → LifecycleServlet
   ├─ /samples/basic/jsp-basics           → JspBasicsServlet
   ├─ /samples/design/modal-dialog        → ModalDialogServlet
   ├─ /samples/list/search-list           → ProductListServlet
   ├─ /samples/form/input-validation      → InputValidationServlet
   ├─ /samples/form/realtime-validation   → RealtimeValidationServlet
   ├─ /samples/file/file-upload           → FileUploadServlet
   ├─ /samples/file/file-upload/download  → FileDownloadServlet
   ├─ /samples/ajax/{ID}                  → 画面用の Servlet
   ├─ /samples/ajax/{ID}/api              → JSON を返す Servlet
   │
   └─ /samples/**                → SampleDispatcherServlet
                                    カタログから URL を探して JSP へ転送
```

JSP は共通レイアウトのタグを通して出力されます。

```
sample.jsp
   └─ <t:sample>          サンプルページの枠（タブ・ソース表示・前後リンク）
        └─ <t:layout>     サイト共通の枠（ヘッダー・サイドバー・フッター）
```

### トップページの URL マッピングについて

`HomeServlet` は `@WebServlet(urlPatterns = {""})` と、**空文字**でマッピングしています。
空文字は「コンテキストルートちょうど」を表す特別なパターンです。
`"/"` と書くと Tomcat の既定サーブレット（静的ファイルの配信担当）を置き換えてしまい、
CSS や画像が 404 になるため使いません。

---

## ソースコードを画面に表示している仕組み

サンプルページの「ソースコード」タブは、**実際に動いているファイルそのもの**を読んで表示しています。

1. `pom.xml` の maven-war-plugin で、`src/main/java/**/*.java` を WAR の
   `WEB-INF/sources/java/` に取り込む
2. `SampleDefinitions` でサンプルごとに表示したいファイルを登録する
3. `SourceTag`（`<site:source>`）が `ServletContext.getResourceAsStream()` で読み、
   エスケープして行番号付きで出力する
4. ブラウザ側で highlight.js が色付けする

開発中はホストの `src/main/java` をマウントしているので、Java を修正すると
（再ビルドしなくても）画面に表示されるソースは最新になります。

読み込み対象は `/WEB-INF/` 配下に限定し、`..` を含むパスは弾いています（`SourceLoader`）。

---

## 組み込みデータベース

「一覧・検索」と「ファイル」のサンプルは、**H2 Database** をアプリの中で動かしています
（`jdbc:h2:mem:servlet-sample`）。DB サーバを別に立てずに済ませるための構成です。

```
common/Database.java            接続の入口 (DriverManager.getConnection)
common/DatabaseInitializer.java 起動時にテーブルを用意し、停止時に DB を落とす
samples/list/ProductDao.java    products テーブルの作成 + サンプルデータ投入
samples/file/StoredFileDao.java uploaded_files テーブルの作成
```

- テーブルは `CREATE TABLE IF NOT EXISTS` で、**各サンプルの DAO が自分の分を作ります**。
  そのため JUnit から DAO を直接呼んでも（Tomcat を起動しなくても）そのまま動きます。
- 接続 URL の `DB_CLOSE_DELAY=-1` は「最後の接続を閉じても DB を消さない」指定です。
  これが無いと `close()` のたびにテーブルごと消えます。
- メモリ上で動かしているため、**アプリを再起動するとデータは消えます**。
- アプリの停止時には `SHUTDOWN` を実行し、`WEB-INF/lib` から読み込んだ JDBC ドライバの
  登録も解除しています（入れ替え時に「failed to unregister」の警告が出ないようにするため）。

実務ではコネクションを毎回作らず、`META-INF/context.xml` に書いた JNDI の `DataSource`
（コネクションプール）から借りるのが一般的です。ここでは JDBC の素の流れが見えるよう、
`DriverManager` を直接使っています。

---

## リモートデバッグ

コンテナは `catalina.sh jpda run` で起動しており、8000 番でデバッガの接続を待っています。

1. `docker compose up -d --build`
2. VS Code でブレークポイントを置く
3. 実行とデバッグから **「Tomcat にアタッチ (Docker:8000)」** を実行（`F5`）

`.vscode/launch.json` に設定済みです。IntelliJ IDEA など他の IDE でも
「リモート JVM デバッグ / localhost:8000」で接続できます。

---

## Jakarta EE（Tomcat 10 以降）へ移行する場合

このリポジトリは `javax.servlet`（Tomcat 9 系）で書かれています。
`jakarta.servlet`（Tomcat 10 以降）に変える場合は次の 4 箇所です。

1. **`pom.xml` の依存関係**

   ```xml
   <dependency>
     <groupId>jakarta.servlet</groupId>
     <artifactId>jakarta.servlet-api</artifactId>
     <version>6.0.0</version>
     <scope>provided</scope>
   </dependency>
   <dependency>
     <groupId>jakarta.servlet.jsp.jstl</groupId>
     <artifactId>jakarta.servlet.jsp.jstl-api</artifactId>
     <version>3.0.0</version>
   </dependency>
   <dependency>
     <groupId>org.glassfish.web</groupId>
     <artifactId>jakarta.servlet.jsp.jstl</artifactId>
     <version>3.0.1</version>
   </dependency>
   ```

2. **Java の import** … `javax.servlet.*` → `jakarta.servlet.*`

3. **JSP の taglib URI** … `http://java.sun.com/jsp/jstl/core` →
   `jakarta.tags.core`（functions は `jakarta.tags.functions`）

4. **`web.xml` / `.tld` の名前空間** … `http://xmlns.jcp.org/xml/ns/javaee` →
   `https://jakarta.ee/xml/ns/jakartaee`（`web-app` は version 6.0）

あわせて `docker/tomcat/Dockerfile` のベースイメージを `tomcat:10.1-jdk17-temurin` に変更します。
エラーページで使っている `javax.servlet.error.*` という属性名も `jakarta.servlet.error.*` になります。

---

## 参考

- [Apache Tomcat 9 ドキュメント](https://tomcat.apache.org/tomcat-9.0-doc/)
- [Jakarta Servlet 4.0 仕様](https://jakarta.ee/specifications/servlet/4.0/)
- [Bootstrap 4.6 ドキュメント](https://getbootstrap.com/docs/4.6/getting-started/introduction/)
