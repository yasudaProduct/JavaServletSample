# Java Servlet サンプル集 : よく使うコマンド集
# (make が使えない環境では README に載っている docker compose コマンドを直接実行してください)

.DEFAULT_GOAL := help

help: ## コマンド一覧を表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## 起動する (http://localhost:8080/)
	docker compose up -d --build

down: ## 停止する
	docker compose down

restart: ## 再起動する (Java を修正したとき)
	docker compose up -d --build

logs: ## Tomcat のログを追う
	docker compose logs -f tomcat

shell: ## コンテナに入る
	docker compose exec tomcat bash

shared: ## 共通ライブラリ (shared/) をビルドしてローカルリポジトリへ入れる
	mvn -B -f shared/pom.xml install

build: shared ## ホストの Maven でビルドする
	mvn -B clean package

test: shared ## ホストの Maven でテストする
	mvn -B test

ant: ## Ant でビルドする (Eclipse 同梱の Ant でも同じことができる)
	ant clean war

dbuild: ## Docker 上の Maven でビルドする (ローカルに JDK/Maven が無い場合)
	docker compose run --rm maven -B clean package

clean: ## ビルド成果物とコンテナを削除する
	mvn -B clean || true
	mvn -B -f shared/pom.xml clean || true
	ant clean || true
	docker compose down -v

# ---- Cloudflare へのデプロイ ----
# 通常は main への push で GitHub Actions が自動実行します (docs/DEPLOY.md)

deploy: ## Cloudflare へデプロイする (要 Docker / wrangler login)
	npx wrangler deploy

cf-dev: ## Cloudflare の構成でローカル起動する (要 Docker)
	npx wrangler dev

cf-logs: ## 本番の Worker のログを追う
	npx wrangler tail

.PHONY: help up down restart logs shell shared build test ant dbuild clean deploy cf-dev cf-logs
