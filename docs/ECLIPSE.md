# Eclipse で開く / Ant でビルドする

Docker と Maven を使わず、**Eclipse とそれに同梱されている Ant だけ**でこのサンプル集を
ビルド・実行するための手順です。Maven 側（`pom.xml`）はそのまま残っているので、
どちらを使っても構いません。作られる WAR の中身は同じです。

依存ライブラリは `lib/` にコミットしてあるため、**ネットワークは不要**です。

## 目次

- [用意するもの](#用意するもの)
- [インポートする](#インポートする)
- [Ant でビルドする](#ant-でビルドする)
- [Eclipse の Tomcat で動かす](#eclipse-の-tomcat-で動かす)
- [「ソースコード」タブを表示する](#ソースコードタブを表示する)
- [ライブラリを追加・更新する](#ライブラリを追加更新する)
- [Maven との使い分け](#maven-との使い分け)
- [つまずいたとき](#つまずいたとき)

---

## 用意するもの

| | 備考 |
| --- | --- |
| **Eclipse IDE for Enterprise Java and Web Developers** | WTP が必要です。`for Java Developers` 版では動的 Web プロジェクトを扱えません |
| **JDK 17 以上** | `pom.xml` / `build.xml` の `release=17` に合わせています |
| **Tomcat 9** | Eclipse に「サーバー」として登録します（`jakarta.*` の Tomcat 10 以降は不可。理由は [DEVELOPMENT.md](DEVELOPMENT.md#jakarta-ee-tomcat-10-以降-へ移行する場合)） |
| Ant | **Eclipse 同梱のものでよい**（別途インストール不要） |

---

## インポートする

1. **ファイル → インポート → 一般 → 既存プロジェクトをワークスペースへ**
2. 「ルート・ディレクトリ」にこのリポジトリのフォルダを指定 → **完了**
   - ⚠️ **「プロジェクトをワークスペースにコピー」はチェックしない**。コピーすると Git 管理から外れます
3. `JavaServletSample` という名前で、動的 Web プロジェクトとして開きます

新規作成ではなくインポートなのは、**設定済みのプロジェクトファイルをコミットしてある**ためです。
自分で「動的 Web プロジェクトを新規作成」すると、下の表の設定を手で入れ直すことになります。

| 項目 | 設定値 | 実体 |
| --- | --- | --- |
| ソース・フォルダ | `src/main/java` / `src/main/resources` / `src/test/java` | `.classpath` |
| 出力先 | `build/classes`（テストは `build/test-classes`） | `.classpath` |
| ビルド・パス | `lib/provided` と `lib/runtime` の jar、JUnit 5 | `.classpath` |
| ファセット | `jst.web 4.0` / `java 17` | `.settings/org.eclipse.wst.common.project.facet.core.xml` |
| 文字コード | **プロジェクト全体 UTF-8** | `.settings/org.eclipse.core.resources.prefs` |
| デプロイメント・アセンブリー | 下記 | `.settings/org.eclipse.wst.common.component` |

### デプロイメント・アセンブリー（何が WAR のどこに入るか）

| ソース | WAR の中の位置 |
| --- | --- |
| `/src/main/webapp` | `/`（`WEB-INF/web.xml`, `views`, `tags`, `tlds`, `assets`, `META-INF/context.xml`） |
| `/src/main/java` | `/WEB-INF/classes`（コンパイル結果） |
| `/src/main/resources` | `/WEB-INF/classes`（`messages*.properties`） |
| `/lib/runtime` | `/WEB-INF/lib`（JSTL / H2） |

> **ビルド・パスとデプロイメント・アセンブリーは別物です。**
> 前者は「コンパイルが通るか」、後者は「WAR に入るか」を決めます。
> 前者だけ設定して後者を忘れると、Eclipse 上では赤線が消えるのに実行時に
> `NoClassDefFoundError` で落ちます。Eclipse WTP で一番多い詰まりどころなので、
> 両方あらかじめ入れてあります。

---

## Ant でビルドする

`build.xml` を右クリック → **実行 → Ant ビルド...** でターゲットを選べます
（`実行 → Ant ビルド` は既定ターゲットの `war` をそのまま実行します）。

| ターゲット | すること | 出力 |
| --- | --- | --- |
| `war`（既定） | WAR を作る | `dist/ROOT.war` |
| `explode` | Tomcat の `webapps/` に置ける展開形式を組み立てる | `build/ant/ROOT/` |
| `compile` | 本体をコンパイルする | `build/ant/classes/` |
| `test` | JUnit 5 を実行する（646 件） | コンソール |
| `sources-for-ide` | 「ソースコード」タブ用に `.java` を配置する | `src/main/webapp/WEB-INF/sources/java/` |
| `clean` | 上記すべてを消す | — |
| `all` | `clean` → `test` → `war` | `dist/ROOT.war` |

コマンドラインからも同じです。

```bash
ant            # = ant war
ant test
ant clean war
```

`build/ant/ROOT/` をそのまま Tomcat の `webapps/` に置けば動きます（WAR に固める必要はありません）。

### provided と runtime を分けている理由

`lib/` は 3 つに分かれています。ここを混ぜると事故ります。

| フォルダ | 中身 | WAR に入るか |
| --- | --- | --- |
| `lib/provided/` | `javax.servlet-api` / `javax.servlet.jsp-api` | **入れない**（Tomcat が持っている） |
| `lib/runtime/` | `jstl` / `h2` | 入れる（`WEB-INF/lib`） |
| `lib/test/` | `junit-platform-console-standalone` | 入れない（テスト実行用） |

`servlet-api` を `WEB-INF/lib` に入れると Tomcat が持っているものと二重になり、
起動時に `offending class: javax/servlet/Servlet.class` で落ちます。
Maven の `provided` スコープに相当するものが Ant には無いので、フォルダで分けています。

---

## Eclipse の Tomcat で動かす

1. **ウィンドウ → 設定 → サーバー → ランタイム環境 → 追加** で Tomcat 9 を登録
2. プロジェクト右クリック → **実行 → サーバーで実行**
3. ブラウザで **`http://localhost:8080/ROOT/`** が開きます

`http://localhost:8080/`（サブパス無し）にしたい場合は、
**プロジェクト → プロパティ → Web プロジェクトの設定** でコンテキストルートを `/` に変えてください。
このアプリは `request.getContextPath()` を使ってリンクを組み立てているので、どちらでも動きます。

> 初回だけ、先に **`ant sources-for-ide`** を実行してください（次の節）。

---

## 「ソースコード」タブを表示する

このサイトは「動いている画面」と「そのソースコード」を並べて見せるため、
`.java` ファイルそのものを `WEB-INF/sources/java` に置いて実行時に読んでいます
（[DEVELOPMENT.md](DEVELOPMENT.md#ソースコードを画面に表示している仕組み) の `SourceLoader`）。

その配置は、使うルートによって担当が違います。

| ルート | 担当 |
| --- | --- |
| Docker | `docker-compose.yml` のマウント |
| Maven | `pom.xml` の `webResources` |
| Ant（`explode` / `war`） | `build.xml` の `explode` ターゲット ④ |
| **Eclipse の「サーバーで実行」** | **担当なし → `ant sources-for-ide` を実行する** |

Eclipse の「サーバーで実行」は Ant を通らないため、ここだけ手当てが必要です。
画面自体は動きますが、実行しないと「ソースコード」タブが空になります。

```bash
ant sources-for-ide
```

`src/main/webapp/WEB-INF/sources/java/` にコピーが置かれます。
ここは既にデプロイメント・アセンブリーでルートに割り当てられているので、追加設定は不要です。
コピー先は `.gitignore` 済みなのでコミットされません。

### Ant ビルダーとして登録する（自動化したい場合）

毎回手で実行したくない場合は、Eclipse のビルドに組み込めます。

1. プロジェクト右クリック → **プロパティ → ビルダー → 新規 → Ant ビルド**
2. 「メイン」タブ → ビルド・ファイル: `${workspace_loc:/JavaServletSample/build.xml}`
3. 「リフレッシュ」タブ → **「ビルド完了時にリソースを更新」**を有効にし、
   `src/main/webapp/WEB-INF/sources` を指定
4. 「ターゲット」タブ → **手動ビルド**と**自動ビルド**の両方に `sources-for-ide` を指定
5. 「ビルダー」一覧で、`Java ビルダー` より**後ろ**に並べる

この設定は `.externalToolBuilders/` に保存されます。ワークスペースのパスが埋め込まれて
環境依存になりやすいため、リポジトリにはコミットしていません。

---

## ライブラリを追加・更新する

1. jar を役割に応じて `lib/provided` / `lib/runtime` / `lib/test` のどれかに置く
2. **`.classpath` に 1 行足す**（`lib/runtime` はデプロイメント・アセンブリーがフォルダごと
   見ているので、そちら側の変更は不要）

   ```xml
   <classpathentry kind="lib" path="lib/runtime/追加した.jar"/>
   ```

3. **`pom.xml` にも同じバージョンで足す**。Maven 側と Ant 側でライブラリが食い違うと、
   「Docker では動くのに Eclipse では動かない」が起きます

jar は Maven Central から取れます。ネットワークが使える環境なら、次のコマンドで
`pom.xml` の内容から `lib/` を作り直せます。

```bash
mvn dependency:copy-dependencies -DincludeScope=provided -DoutputDirectory=lib/provided
mvn dependency:copy-dependencies -DincludeScope=runtime  -DoutputDirectory=lib/runtime
mvn dependency:copy -Dartifact=org.junit.platform:junit-platform-console-standalone:1.10.2 \
    -DoutputDirectory=lib/test
```

---

## Maven との使い分け

| | Maven | Ant / Eclipse |
| --- | --- | --- |
| Docker（`docker compose up`） | **こちらを使う** | — |
| GitHub Actions（デプロイ） | **こちらを使う** | — |
| Eclipse だけで完結させたい | — | **こちらを使う** |
| ネットワーク | 初回に必要 | 不要 |
| 展開形式の出力 | `target/ROOT/` | `build/ant/ROOT/` |
| WAR | `target/ROOT.war` | `dist/ROOT.war` |

**両者は同じ内容の WAR を作ります。** ファイル構成（375 ファイル）、テスト件数（646 件）、
バイトコードのバージョン（Java 17）が一致することを確認済みです。
どちらか片方だけを使っても構いません。

片方だけ直して片方を放置すると食い違うので、`pom.xml` を触ったら `build.xml` と `.classpath`、
`build.xml` を触ったら `pom.xml` も見てください。対応関係は次のとおりです。

| `pom.xml` | `build.xml` |
| --- | --- |
| `<maven.compiler.release>17` | `<property name="java.release" value="17"/>` |
| `<finalName>ROOT</finalName>` | `<property name="app.name" value="ROOT"/>` |
| `<dependency>` の `provided` スコープ | `lib/provided/` |
| `<dependency>` の `compile` スコープ | `lib/runtime/` |
| `<webResources>` → `WEB-INF/sources/java` | `explode` ターゲット ④ |

---

## つまずいたとき

| 症状 | 原因 | 対処 |
| --- | --- | --- |
| 実行時に `NoClassDefFoundError` / `ClassNotFoundException` | ビルド・パスにはあるが**デプロイメント・アセンブリーに無い** | プロパティ → デプロイメント・アセンブリー を確認。jar は `lib/runtime` に置く |
| 起動時に `offending class: javax/servlet/Servlet.class` | `servlet-api` が WAR に入っている | デプロイメント・アセンブリーに `lib/provided` を足さない |
| 「ソースコード」タブが空 | `WEB-INF/sources/java` が無い | `ant sources-for-ide` を実行 |
| Java のソース中の日本語が化ける | プロジェクトの文字コードが UTF-8 になっていない（Windows の既定は MS932） | `.settings/org.eclipse.core.resources.prefs` があるか確認。プロパティ → リソース で UTF-8 になっているか見る |
| Ant コンソールの日本語だけ化ける | コンソール側の文字コード | 実行構成 → 共通 → コンソール・エンコード を UTF-8 にする（ビルド結果には影響しません） |
| 「不明なネーチャー」と言われる | WTP の無い Eclipse | `Eclipse IDE for Enterprise Java and Web Developers` を使う |
| 「ターゲット・ランタイムが定義されていません」 | Tomcat を登録していない | 設定 → サーバー → ランタイム環境 で Tomcat 9 を追加 |
| `javac` が「リリース 17 はサポートされていません」 | JDK が 17 未満 | JDK 17 以上を入れ、設定 → Java → インストール済みの JRE に追加 |
| `build/classes` と `build/ant/classes` の違いが分からない | 前者が Eclipse、後者が Ant の出力 | わざと分けています。同じ場所に出すと互いの出力を消し合います |
