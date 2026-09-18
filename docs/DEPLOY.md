# デプロイ（Cloudflare）

`main` ブランチに push すると、GitHub Actions が自動で Cloudflare にデプロイします。

このページは **最初の 1 回だけ必要な手作業**（アカウント登録・認証まわり）と、
その後の運用・調整のしかたをまとめたものです。

---

## 1. 仕組み

Cloudflare の Workers は JavaScript / WebAssembly を動かす環境で、**Java（JVM）は動きません**。
そのため、このサイトは **Cloudflare Containers** の上で Tomcat をそのまま動かし、
Worker はリクエストをコンテナに横流しするだけの入口として置いています。

```
ブラウザ
   │
   ▼
Cloudflare Worker            worker/index.ts
   │  （受け取ったリクエストをそのまま転送するだけ）
   ▼
Cloudflare Container         docker/cloudflare/Dockerfile
   └─ Tomcat 9 + ROOT（この Java アプリ）
```

つまり、ローカルの `docker compose up` とほぼ同じものが Cloudflare 上で動きます。
アプリ側（Java / JSP）の書き方を変える必要はありません。

| ファイル | 役割 |
| --- | --- |
| `.github/workflows/deploy.yml` | main への push でテスト → デプロイ |
| `wrangler.jsonc` | Worker とコンテナの設定（インスタンスサイズなど） |
| `worker/index.ts` | リクエストをコンテナへ転送する入口 |
| `docker/cloudflare/Dockerfile` | 本番用の Tomcat イメージ |
| `docker/cloudflare/context.xml` | 本番用の Tomcat コンテキスト設定 |

> 開発用の `docker/tomcat/Dockerfile` はそのまま残してあります。
> ローカルの `docker compose` の動きは今までどおりです。

---

## 2. 最初に 1 回だけ必要な手作業

ここだけは Cloudflare と GitHub の画面での操作が必要です。**所要 10 分ほど**です。

### 2-1. Cloudflare アカウントと Workers 有料プラン

Containers は **Workers Paid プラン（$5 / 月）が必須**です。無料プランでは使えません。

1. <https://dash.cloudflare.com/sign-up> でアカウントを作る（既にあれば不要）
2. 左メニュー **Compute (Workers)** → **Plans** から **Workers Paid** に加入する

### 2-2. Account ID を控える

1. Cloudflare ダッシュボード → **Compute (Workers)** を開く
2. 右側（または概要ページ）に出ている **Account ID** をコピーする

> ブラウザの URL `https://dash.cloudflare.com/<ここが Account ID>/...` からも読み取れます。

### 2-3. API トークンを作る

1. <https://dash.cloudflare.com/profile/api-tokens> を開く
2. **Create Token** → 一番下の **Create Custom Token** の **Get started**
3. 名前は `github-actions-java-servlet-sample` など分かるものにする
4. **Permissions** に次の 3 つを追加する

   | 種別 | 項目 | 権限 |
   | --- | --- | --- |
   | Account | Workers Scripts | Edit |
   | Account | Containers | Edit |
   | Account | Account Settings | Read |

5. **Account Resources** で自分のアカウントだけを選ぶ
6. **Continue to summary** → **Create Token**
7. 表示されたトークンをコピーする（**この画面を閉じると二度と表示されません**）

> `Containers: Edit` が無いと、Worker は更新できてもコンテナイメージの
> push で失敗します。3 つとも必要です。

### 2-4. GitHub に Secrets を登録する

リポジトリの **Settings** → **Secrets and variables** → **Actions** →
**New repository secret** で 2 つ登録します。

| Name | Value |
| --- | --- |
| `CLOUDFLARE_API_TOKEN` | 2-3 で作ったトークン |
| `CLOUDFLARE_ACCOUNT_ID` | 2-2 で控えた Account ID |

これで準備完了です。

---

## 3. デプロイする

### 自動（通常はこちら）

`main` ブランチに push すると `.github/workflows/deploy.yml` が動きます。

```
push → ① テスト（mvn verify + 型チェック）
     → ② デプロイ（Docker ビルド → Cloudflare へ反映）
```

テストが落ちた場合はデプロイされません。
進み方は GitHub の **Actions** タブで確認できます。

手動で流したいときは Actions タブ →
**Deploy** → **Run workflow** から実行できます。

### 手元から直接デプロイする（任意）

Docker が動いていれば、ローカルからも同じことができます。

```bash
npm install          # 最初の 1 回だけ
npx wrangler login   # ブラウザが開いて Cloudflare にログイン
npx wrangler deploy
```

### 公開 URL

初回デプロイが終わると、次の URL で公開されます。

```
https://java-servlet-sample.<アカウントのサブドメイン>.workers.dev
```

正確な URL は Actions のログ（ジョブのサマリー）と、
Cloudflare ダッシュボードの **Compute (Workers)** → `java-servlet-sample` に出ます。

> 初回デプロイはコンテナイメージを世界中に配る処理が入るため、
> 数分かかることがあります。2 回目以降は差分だけなので速くなります。

---

## 4. 独自ドメインを使う場合（任意）

ドメインを Cloudflare に移管（またはネームサーバーを Cloudflare に向ける）したうえで、
`wrangler.jsonc` に次を足して push します。

```jsonc
"routes": [
  { "pattern": "example.com", "custom_domain": true }
]
```

---

## 5. 動かし方の調整

いずれも `wrangler.jsonc` / `worker/index.ts` を編集して push するだけで反映されます。

### インスタンスサイズ（`wrangler.jsonc` の `instance_type`）

| 値 | vCPU | メモリ | ディスク | 備考 |
| --- | --- | --- | --- | --- |
| `lite` | 1/16 | 256 MiB | 2 GB | JVM には小さすぎる |
| `basic` | 1/4 | 1 GiB | 4 GB | **現在の設定**。実測で約 650 MiB 使用 |
| `standard-1` | 1/2 | 4 GiB | 8 GB | 起動が遅い / メモリが足りないときはこれ |

### スリープまでの時間（`worker/index.ts` の `sleepAfter`）

アクセスが無い状態が続くとコンテナは停止し、その間は課金されません。
現在は `15m`（15 分）にしています。

- **短くする** … 費用が下がる / 久しぶりのアクセスが遅くなる
- **長くする** … いつでも速い / 費用が上がる

停止状態からの最初のアクセスは、Tomcat の起動を待つため **10〜30 秒**かかります。
`worker/index.ts` では最大 60 秒まで待つようにしてあるので、
その間ブラウザは読み込み中のまま待ちます（エラーにはなりません）。

---

## 6. 費用の目安

Cloudflare Containers は **コンテナが起動している間だけ**課金されます
（停止中は 0 円）。

| 項目 | Workers Paid に含まれる分 | 超過分の単価 |
| --- | --- | --- |
| メモリ | 25 GiB-時 / 月 | $0.0000025 / GiB-秒 |
| CPU | 375 vCPU-分 / 月 | $0.000020 / vCPU-秒 |
| ディスク | 200 GB-時 / 月 | $0.00000007 / GB-秒 |

`basic`（1 GiB / 4 GB）で試算すると、おおよそ次のとおりです。

| 稼働時間 | 月額の目安（プラン料金 $5 込み） |
| --- | --- |
| 1 日 8 時間くらい | **$7 前後** |
| 24 時間つけっぱなし | **$12 前後** |

> 単価は 2026 年 9 月時点のものです。最新は
> [Containers の料金ページ](https://developers.cloudflare.com/containers/pricing/) を確認してください。
> 使いすぎが不安な場合は、Cloudflare ダッシュボードの **Notifications** で
> 課金アラートを設定しておくと安心です。

---

## 7. 困ったとき

| 症状 | 原因と対処 |
| --- | --- |
| Actions が `Authentication error` で落ちる | `CLOUDFLARE_API_TOKEN` の権限不足。2-3 の 3 つが揃っているか確認 |
| イメージの push で権限エラーになる | トークンに **Containers: Edit** が付いていない |
| `You must be on a Workers Paid plan` | 2-1 の有料プラン加入がまだ |
| 最初のアクセスだけ非常に遅い | コールドスタート。`sleepAfter` を長くするか `standard-1` に上げる |
| `Failed to start container` が出る | メモリ不足の可能性。`instance_type` を `standard-1` に上げる |
| 画面が 500 になる | `npx wrangler tail` でログを追う（ダッシュボードの Workers Logs でも見られる） |
| デプロイは成功したのに古い画面が出る | Containers はローリング更新のため反映に数分かかることがある |
| 初回デプロイ直後だけ 503 になる | コンテナの配置が終わっていない。`npx wrangler containers list` の STATE が `ready` になるまで数分待つ |

### ログを見る

```bash
npx wrangler tail
```

Cloudflare ダッシュボードの **Compute (Workers)** → `java-servlet-sample` →
**Logs** からも確認できます。

### 前のバージョンに戻す

```bash
npx wrangler versions list
npx wrangler rollback <バージョン ID>
```

---

## 8. 参考

- [Cloudflare Containers](https://developers.cloudflare.com/containers/)
- [Containers の料金](https://developers.cloudflare.com/containers/pricing/)
- [GitHub Actions からのデプロイ](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/)
- [wrangler.jsonc の設定項目](https://developers.cloudflare.com/workers/wrangler/configuration/)
- [API トークンの権限一覧](https://developers.cloudflare.com/fundamentals/api/reference/permissions/)
