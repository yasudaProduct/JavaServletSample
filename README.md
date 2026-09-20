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
├── docker/tomcat/               開発用（Maven でビルド → Tomcat 9 に配置）
├── docker/cloudflare/           本番用（Cloudflare Containers 向け）
├── pom.xml                      Maven の設定
├── Makefile                     よく使うコマンド
├── wrangler.jsonc               Cloudflare の設定（デプロイ先）
├── worker/index.ts              Cloudflare Worker（コンテナへの入口）
├── .github/workflows/           GitHub Actions（main への push でデプロイ）
├── docs/                        追加ドキュメント
├── .vscode/                     VS Code の設定・デバッグ構成
└── src/
    ├── main/
    │   ├── java/com/example/servletsample/
    │   │   ├── catalog/         サンプル一覧（目次）の仕組みと定義
    │   │   ├── common/          共通処理（BaseServlet / ソース読み込み / DB 接続）
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
| DB | H2 Database 2.2（組み込み・メモリ上で動作。別途 DB サーバは不要） |
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

## 7. デプロイ

`main` ブランチに push すると、GitHub Actions が **Cloudflare** へ自動でデプロイします。

Cloudflare の Workers は Java を実行できないため、Tomcat は
**Cloudflare Containers**（コンテナ実行環境）の上でそのまま動かし、
Worker はリクエストを転送する入口として置いています。

```
ブラウザ → Cloudflare Worker → Cloudflare Container（Tomcat 9 + このアプリ）
```

```
push (main)
  ├─ テスト     mvn verify + Worker の型チェック
  └─ デプロイ   Docker イメージをビルドして Cloudflare へ反映
```

初回だけ Cloudflare のプラン加入・API トークン作成・GitHub Secrets の登録が必要です。
**手順と費用の目安は [docs/DEPLOY.md](docs/DEPLOY.md)** にまとめてあります。

---

## 8. 困ったとき

| 症状 | 対処 |
| --- | --- |
| `port is already allocated` | 8080 番が使用中です。`docker-compose.yml` の `ports` を `"8081:8080"` などに変更してください |
| JSP を直しても反映されない | Tomcat は数秒間隔で更新を見ています。数秒待って再読み込み。それでも変わらなければ `docker compose restart tomcat` |
| Java を直しても反映されない | Java はビルドが必要です。`docker compose up -d --build` |
| 画面が真っ白 / 500 エラー | `docker compose logs -f tomcat` にスタックトレースが出ます。Java を変更した直後なら `docker compose up -d --build` で再ビルドしてください（JSP だけ新しく Java が古いと、画面の途中で止まることがあります） |
| 文字化けする | ファイルを UTF-8 で保存しているか確認してください（`.editorconfig` で UTF-8 に統一しています） |

---

## 9. 収録サンプル

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

現在は以下の 16 件が入っています。サンプルはこれから追加していきます。

| カテゴリ | サンプル | 内容 |
| --- | --- | --- |
| 基本 | **Hello World** | Servlet で値を用意して JSP へ転送する基本の流れ |
| 基本 | **リクエストパラメータの受け取り方** | `getParameter` / `getParameterValues` / `getParameterMap`、null と空文字の違い、チェックボックスの落とし穴 |
| 基本 | **forward と redirect の違い** | 同じ処理を両方で実行し、URL・スコープ・履歴・再読み込みの違いを比較 |
| 基本 | **スコープ** | request / session / application に値を入れて、いつまで残り誰に見えるかを確かめる |
| 基本 | **Servlet のライフサイクルとスレッド** | 1 インスタンスに複数スレッドが入る。同時アクセスでカウンタがずれる様子を体験 |
| 基本 | **EL と JSTL の基本** | 書いた EL とその結果を並べて確認。エスケープあり / なしの違いも比較 |
| 画面デザイン | **Bootstrap 4 の基本パーツ** | グリッド・ボタン・カード・テーブル・フォーム |
| 画面デザイン | **モーダルの出し方 6 パターン** | 確認モーダル、処理後の完了モーダル、画面遷移後のモーダル、確認 → 登録 → 完了 → 遷移、モーダルの入力・検索結果を元画面へ渡す |
| フォーム・入力 | **入力チェック（サーバ側）** | 必須・形式・範囲・相関チェック。エラー表示と入力値の保持 |
| フォーム・入力 | **入力チェック（フォーカスアウト時）** | blur でその場でチェック。JavaScript を通さずに送るとサーバ側で弾かれることも確認できる |
| 一覧・検索 | **検索つき一覧画面** | 絞り込み・並び替え・ページング（SQL の `LIMIT` / `OFFSET`） |
| ファイル | **アップロード・ダウンロード・削除** | ファイルを DB の `BLOB` 列に保存し、一覧から取得・削除する |
| 非同期通信 | **非同期通信の基本** | `fetch` で JSON を取得。ローディング表示、404 / 500 / 通信失敗の扱い |
| 非同期通信 | **インクリメンタルサーチ** | 入力のたびに検索。debounce と AbortController で投げすぎ・古い応答を防ぐ |
| 非同期通信 | **Ajax でフォームを送信する** | 画面遷移せずに送信し、項目ごとのエラーを JSON で受け取る。二重送信の防止 |
| 非同期通信 | **処理の進捗をポーリングで取得する** | 1 秒おきに進捗を問い合わせて進捗バーに反映。終了条件と止め方 |

### データベースについて

「一覧・検索」「ファイル」「インクリメンタルサーチ」のサンプルは **H2 Database** を使っています。
アプリの中でメモリ上に動かす組み込みデータベースなので、
`docker compose up` だけで動き、別途 DB サーバを用意する必要はありません。

- 接続の入口は `common/Database.java`（`jdbc:h2:mem:servlet-sample`）
- テーブルの作成とサンプルデータの投入は、それぞれのサンプルの DAO が行います
- **アプリを再起動すると保存したデータは消えます**（サンプル用の割り切りです）
