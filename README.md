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
    │   ├── resources/           メッセージの properties（ビルドで WEB-INF/classes へ）
    │   └── webapp/
    │       ├── WEB-INF/
    │       │   ├── views/       画面の JSP（samples/ 配下がサンプル本体、error/ がエラーページ）
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
| 一覧・検索 | 一覧・検索・ページング、マスタの登録・更新・削除 |
| セッション・認証 | ログイン、スコープ、権限チェック |
| ファイル | アップロード、ダウンロード、CSV / PDF 出力 |
| 非同期通信 | Ajax、JSON API との連携 |
| 応用・その他 | フィルタ、エラー処理、国際化など |

現在は以下の 37 件が入っています。サンプルはこれから追加していきます。

| カテゴリ | サンプル | 内容 |
| --- | --- | --- |
| 基本 | **Hello World** | Servlet で値を用意して JSP へ転送する基本の流れ |
| 基本 | **リクエストパラメータの受け取り方** | `getParameter` / `getParameterValues` / `getParameterMap`、null と空文字の違い、チェックボックスの落とし穴 |
| 基本 | **forward と redirect の違い** | 同じ処理を両方で実行し、URL・スコープ・履歴・再読み込みの違いを比較 |
| 基本 | **スコープ** | request / session / application に値を入れて、いつまで残り誰に見えるかを確かめる |
| 基本 | **Servlet のライフサイクルとスレッド** | 1 インスタンスに複数スレッドが入る。同時アクセスでカウンタがずれる様子を体験 |
| 基本 | **URL と Servlet の対応づけ** | 完全一致・前方一致・拡張子一致・既定のどれが選ばれるか。URL を入れると呼ばれる Servlet と `getServletPath` / `getPathInfo` を判定し、実際に叩いて答え合わせできる |
| 基本 | **文字コードと文字化け** | 化けるのは「文字」ではなくバイト列の読み方。化け方から原因を見分ける表、GET と POST の受け取りの違い、Shift_JIS で組み立てられたリンクからの復元 |
| 基本 | **リクエストとレスポンスの中身を見る** | 届いたリクエスト行とヘッダの一覧。ステータスコードを選んで返し、`setStatus` と `sendError` で本文が変わることを確かめる。`Content-Type` による見え方の違い、ヘッダに入力値を入れるときの注意 |
| 基本 | **Cookie の基本** | ブラウザに預けて毎回送り返してもらう。有効期限・Path・`HttpOnly` を切り替えて発行し、`document.cookie` から見えるかどうか、セッション ID の引換券との関係まで |
| 基本 | **EL と JSTL の基本** | 書いた EL とその結果を並べて確認。エスケープあり / なしの違いも比較 |
| 基本 | **JSP の記法** | ディレクティブ・宣言・スクリプトレット・式・アクションが変換後のどこへ行くか。インクルード 2 種類、`jsp:useBean`、コメントがブラウザまで届くかどうか |
| 基本 | **コンテキストパスと相対パス** | 配備先が変わると CSS と画像だけ 404 になる理由。「/ 始まり」「相対」「`${pageContext.request.contextPath}` 付き」が指す先を並べ、末尾スラッシュで基準が変わることまで確かめる |
| 基本 | **設定値の渡し方** | `context-param`（アプリ全体）と `init-param`（Servlet 1 つ）の違い。同じクラスを `web.xml` に 2 回登録して設定違いで動かし、設定値を `init()` で確かめる書き方まで |
| 画面デザイン | **Bootstrap 4 の基本パーツ** | グリッド・ボタン・カード・テーブル・フォーム |
| 画面デザイン | **モーダルの出し方 6 パターン** | 確認モーダル、処理後の完了モーダル、画面遷移後のモーダル、確認 → 登録 → 完了 → 遷移、モーダルの入力・検索結果を元画面へ渡す |
| フォーム・入力 | **入力チェック（サーバ側）** | 必須・形式・範囲・相関チェック。エラー表示と入力値の保持 |
| フォーム・入力 | **入力チェック（フォーカスアウト時）** | blur でその場でチェック。JavaScript を通さずに送るとサーバ側で弾かれることも確認できる |
| フォーム・入力 | **入力チェックの種類** | 必須・文字種・桁数・日付の実在・範囲・相関・選択肢・マスタ突き合わせを、休暇申請フォームで種類ごとに確かめる |
| フォーム・入力 | **入力 → 確認 → 完了（3 画面）** | 値の持ち回りを隠し項目とセッションで比較。確定時に検証をやり直す理由、ワンタイムトークンによる二重送信の防止 |
| 一覧・検索 | **検索つき一覧画面** | 絞り込み・並び替え・ページング（SQL の `LIMIT` / `OFFSET`） |
| 一覧・検索 | **マスタメンテナンス** | 一覧を起点に登録・編集・削除。表示は GET・更新は POST、削除の確認、一意性チェックの二段構え、PRG |
| 一覧・検索 | **更新の競合（楽観ロック）** | 2 人が同時に編集すると相手の変更が黙って消える。`version` 列で気付き、差分を並べて選ばせる。1 人でも再現可能 |
| ファイル | **アップロード・ダウンロード・削除** | ファイルを DB の `BLOB` 列に保存し、一覧から取得・削除する |
| ファイル | **CSV ダウンロード** | 「Excel で開いたら文字化け」の正体は BOM。文字コード・改行・エスケープを切り替えて見比べる。日本語ファイル名、CSV インジェクション対策 |
| 非同期通信 | **非同期通信の基本** | `fetch` で JSON を取得。ローディング表示、404 / 500 / 通信失敗の扱い |
| 非同期通信 | **インクリメンタルサーチ** | 入力のたびに検索。debounce と AbortController で投げすぎ・古い応答を防ぐ |
| 非同期通信 | **Ajax でフォームを送信する** | 画面遷移せずに送信し、項目ごとのエラーを JSON で受け取る。二重送信の防止 |
| 非同期通信 | **処理の進捗をポーリングで取得する** | 1 秒おきに進捗を問い合わせて進捗バーに反映。終了条件と止め方 |
| セッション・認証 | **ログインとログアウト** | セッションに「ログイン済み」の印を置く。パスワードのハッシュ化、ログイン成功時のセッション ID の振り直し、ログアウトを POST で受ける理由 |
| セッション・認証 | **フィルタで未ログインを弾く** | 認証は 401、権限不足は 403 と返し分ける。Ajax にリダイレクトを返してはいけない理由、オープンリダイレクト対策 |
| セッション・認証 | **CSRF 対策** | 罠のページから送られた依頼を見分ける。トークンあり / なし / でたらめを送り比べ、SameSite Cookie や二重送信防止との違いも整理 |
| 応用・その他 | **エラー処理とエラーページ** | 入力の誤り・業務上の都合・システムの異常の切り分け。`web.xml` でのエラーページの割り当て、JSP の `errorPage` 属性、非同期通信での返し方 |
| 応用・その他 | **フィルタで共通処理をはさむ** | 3 つのフィルタが呼ばれる順番を 1 往復ぶん記録して表示。`chain.doFilter` を呼ばずに止めるとどうなるか |
| 応用・その他 | **国際化（多言語表示）** | 文字を `properties` にまとめてロケールで切り替える。`Accept-Language`、探索順、日付・数値・通貨・タイムゾーンの書式 |
| 応用・その他 | **トランザクション** | 口座間の振替で commit と rollback。使わずに途中で失敗させると、出金だけが確定して合計が合わなくなる |
| 応用・その他 | **リスナー（Listener）** | アプリの起動・停止、セッションの作成・破棄、値の出し入れを捕まえる。呼ぶのはコンテナ。後始末を書かないとメモリが残る理由まで |
| 応用・その他 | **非同期処理（AsyncContext）** | コンテナのスレッドを先に返し、別のスレッドで応答する。同期と並べて実行、時間切れの返し方、同時に投げたときの順番待ち |

### エラーページについて

すべての画面に共通のエラーページを `src/main/webapp/WEB-INF/views/error/` に置き、
`web.xml` の `<error-page>` から呼び出しています。

| ファイル | 呼ばれるとき |
| --- | --- |
| `404.jsp` | ページが見つからないとき |
| `500.jsp` | 受け止められなかった例外、およびステータス 500 |
| `error.jsp` | 400 / 403 / 405（見出しだけをコードで切り替える共通ページ） |
| `application-error.jsp` | 業務例外（`ApplicationException`）のとき |

仕組みは「応用・その他 > エラー処理とエラーページ」のサンプルで解説しています。

### データベースについて

「一覧・検索」「ファイル」「インクリメンタルサーチ」「トランザクション」のサンプルは
**H2 Database** を使っています。
アプリの中でメモリ上に動かす組み込みデータベースなので、
`docker compose up` だけで動き、別途 DB サーバを用意する必要はありません。

- 接続の入口は `common/Database.java`（`jdbc:h2:mem:servlet-sample`）
- テーブルの作成とサンプルデータの投入は、それぞれのサンプルの DAO が行います
- **アプリを再起動すると保存したデータは消えます**（サンプル用の割り切りです）
