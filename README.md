# Java Servlet サンプル集

JSP / Servlet / Bootstrap 4 で作る Web システムのサンプル集です。
Web でよくある画面や機能を「実際に動く状態」で 1 つずつ置き、ブラウザで動作を確認しながら
そのままソースコードを読めるようにしたサイトです。

- **デモ** … 実際に動く画面
- **ソースコード** … その画面を動かしている JSP / Servlet（行番号・コピーボタン付き）
- **解説** … つまずきやすい所のメモ

開発環境は Docker（Tomcat 9）、コードは VS Code で開く前提で構成しています。

---

## 1. 動かす

必要なもの: **Docker** のみ（Java や Maven はコンテナの中で使うため、ローカルに無くても動きます）

```bash
git clone https://github.com/yasudaProduct/JavaServletSample.git
cd JavaServletSample

docker compose up --build
```

ブラウザで <http://localhost:8080/> を開きます。

停止は `Ctrl + C`、またはバックグラウンド起動している場合は `docker compose down` です。

```bash
docker compose up -d --build   # バックグラウンドで起動
docker compose logs -f tomcat  # ログを見る
docker compose down            # 停止
```

`make` が使える環境なら `make up` / `make down` / `make logs` でも同じことができます（`make help` で一覧）。

---

## 2. 開発の流れ

| 変更したファイル | 反映のしかた |
| --- | --- |
| JSP（`WEB-INF/views`, `WEB-INF/tags`） | **保存してブラウザを再読み込みするだけ**（数秒で反映） |
| CSS / JavaScript（`assets`） | **保存してブラウザを再読み込みするだけ** |
| Java（`src/main/java`） | `docker compose up -d --build` で再ビルド |

ホスト側のソースをコンテナにマウントしているため、画面まわりの修正は再ビルド無しで確認できます
（マウントの内容は `docker-compose.yml` を参照）。

### VS Code

推奨拡張機能は `.vscode/extensions.json` に入れてあります。VS Code でフォルダを開くと
インストールを促されます（Java 拡張パック、JSP、XML、Docker、EditorConfig）。

- コード補完を効かせたい場合は、ローカルにも **JDK 17 以上** を入れてください（実行自体は Docker 側で行います）
- `Ctrl + Shift + B` で「Docker: 起動（ビルド込み）」タスクが動きます
- **デバッグ**: コンテナは JPDA ポート 8000 を開けた状態で起動しています。
  ブレークポイントを置いて `F5`（`Tomcat にアタッチ (Docker:8000)`）でステップ実行できます

---

## 3. ディレクトリ構成

```
JavaServletSample/
├── docker-compose.yml           起動設定（ポート・マウント）
├── docker/tomcat/Dockerfile     Maven でビルド → Tomcat 9 に配置
├── pom.xml                      Maven の設定
├── Makefile                     よく使うコマンド
├── docs/                        追加ドキュメント
├── .vscode/                     VS Code の設定・デバッグ構成
└── src/
    ├── main/
    │   ├── java/com/example/servletsample/
    │   │   ├── catalog/         サンプル一覧（目次）の仕組みと定義
    │   │   ├── common/          共通処理（BaseServlet / ソース読み込み）
    │   │   ├── web/             サイト自体の画面（トップ・カテゴリ・検索）
    │   │   ├── web/tag/         独自タグ（ソースコード表示）
    │   │   └── samples/         各サンプルの Servlet
    │   └── webapp/
    │       ├── WEB-INF/
    │       │   ├── views/       画面の JSP（samples/ 配下がサンプル本体）
    │       │   ├── tags/        共通レイアウト（layout / sample / icon …）
    │       │   ├── tlds/        独自タグの定義
    │       │   └── web.xml      アプリ全体の設定
    │       ├── assets/          CSS / JS / Bootstrap（CDN ではなく同梱）
    │       └── META-INF/context.xml
    └── test/java/               カタログの整合性テスト
```

### 画面の作り

- JSP はすべて `/WEB-INF/views/` に置き、ブラウザから直接開けないようにしています。
  画面を出すのは Servlet の役割で、Servlet が値を用意して JSP へ forward します。
- 共通のヘッダー・サイドバー・フッターは `WEB-INF/tags/layout.tag` にまとめています。
  各ページは `<t:layout>` で囲むだけで同じ見た目になります。
- サンプルページは `<t:sample>` で囲むと「デモ / ソースコード / 解説」のタブが自動で作られます。
  表示するソースコードは Java の定義（`SampleDefinitions`）から取得します。

---

## 4. サンプルを追加する

1. `src/main/webapp/WEB-INF/views/samples/{カテゴリ}/{ID}.jsp` を作る
2. `src/main/java/com/example/servletsample/catalog/SampleDefinitions.java` に 1 件追加する
3. （必要なら）`@WebServlet("/samples/{カテゴリ}/{ID}")` で Servlet を作る

Servlet が無いサンプルは `SampleDispatcherServlet` が JSP へ転送するため、**JSP 1 枚と定義 1 行**だけで増やせます。

詳しい手順とテンプレートは **[docs/ADD_SAMPLE.md](docs/ADD_SAMPLE.md)** にあります。

---

## 5. 技術構成

| 項目 | 内容 |
| --- | --- |
| 言語 | Java 17 |
| サーバ | Apache Tomcat 9（Docker） |
| API | Servlet 4.0 / JSP 2.3 / JSTL 1.2（`javax.*` 名前空間） |
| 画面 | Bootstrap 4.6、jQuery 3.7（slim）、highlight.js 11 |
| ビルド | Maven（WAR） |
| テスト | JUnit 5 |

Bootstrap などのフロントエンド資産は `src/main/webapp/assets/vendor/` に同梱しています。
インターネットに繋がらない環境でもそのまま動きます。

> **Tomcat 9（`javax.*`）を選んでいる理由**
> 世の中の JSP / Servlet の解説やコードの多くが `javax.servlet` 前提で書かれており、
> 学習・参照用のサンプル集としては合わせた方が読み替えが不要なためです。
> Tomcat 10 以降（`jakarta.servlet`）へ移行する場合は
> [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#jakarta-ee-tomcat-10-以降-へ移行する場合) を参照してください。

---

## 6. Maven コマンド

ローカルに JDK / Maven がある場合:

```bash
mvn clean package   # WAR をビルド（target/ROOT.war と target/ROOT/）
mvn test            # カタログの整合性テスト
```

ローカルに入れたくない場合は Docker 上の Maven を使えます:

```bash
docker compose run --rm maven -B clean package
docker compose run --rm maven -B test
```

`mvn test` では「登録したサンプルの JSP が実在するか」「ID が重複していないか」を検査します。
サンプルを追加したら流しておくと、登録漏れにすぐ気付けます。

---

## 7. 困ったとき

| 症状 | 対処 |
| --- | --- |
| `port is already allocated` | 8080 番が使用中です。`docker-compose.yml` の `ports` を `"8081:8080"` などに変更してください |
| JSP を直しても反映されない | Tomcat は数秒間隔で更新を見ています。数秒待って再読み込み。それでも変わらなければ `docker compose restart tomcat` |
| Java を直しても反映されない | Java はビルドが必要です。`docker compose up -d --build` |
| 画面が真っ白 / 500 エラー | `docker compose logs -f tomcat` にスタックトレースが出ます |
| 文字化けする | ファイルを UTF-8 で保存しているか確認してください（`.editorconfig` で UTF-8 に統一しています） |

---

## 8. 収録サンプル

| カテゴリ | 内容 |
| --- | --- |
| 基本 | Servlet と JSP の基本的な流れ |
| 画面デザイン | Bootstrap 4 を使った画面の組み立て |
| フォーム・入力 | 入力・検証・確認画面といった入力まわり |
| 一覧・検索 | 一覧表示、検索、ページング、ソート |
| セッション・認証 | ログイン、スコープ、権限チェック |
| ファイル | アップロード、ダウンロード、CSV / PDF 出力 |
| 非同期通信 | Ajax、JSON API との連携 |
| 応用・その他 | フィルタ、エラー処理、国際化など |

現在は基盤の動作確認用に、以下の 2 件が入っています。サンプルはこれから追加していきます。

- **基本 / Hello World** … Servlet で値を用意して JSP へ転送する基本の流れ（Servlet あり）
- **画面デザイン / Bootstrap 4 の基本パーツ** … グリッド・ボタン・カード・テーブル・フォーム（JSP のみ）
