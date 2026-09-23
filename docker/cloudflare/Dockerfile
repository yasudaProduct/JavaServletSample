# syntax=docker/dockerfile:1
# check=skip=FromPlatformFlagConstDisallowed


# =====================================================================
# Cloudflare Containers 用の本番イメージ
#
# 開発用 (docker/tomcat/Dockerfile) との違い:
#   - リモートデバッグ (JPDA) を無効にしている
#   - コンテナのメモリに合わせて JVM のヒープ上限を設定している
#   - context.xml を本番用 (reloadable="false") に差し替えている
#   - 実行イメージを linux/amd64 に固定している
#     (Cloudflare Containers は linux/amd64 のイメージしか動きません)
#
# ビルドコンテキストはリポジトリのルートです (wrangler.jsonc の
# image_build_context で指定)。COPY のパスはルートからの相対になります。
# =====================================================================

# ---------------------------------------------------------------------
# build stage : Maven で WAR (展開形式) をビルドする
#
# $BUILDPLATFORM = ビルドを実行しているマシン自身のアーキテクチャ。
# 出来上がるのは Java のバイトコードで実行側の CPU に依存しないため、
# ここだけはネイティブで動かしてビルドを速くしています。
# (Apple Silicon の Mac でもエミュレーション無しでビルドできます)
# ---------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build

# 共通ライブラリ (shared/) を先にビルドしてローカルリポジトリへ入れる
COPY shared/pom.xml ./shared/pom.xml
COPY shared/src ./shared/src
RUN mvn -B -q --no-transfer-progress -f shared/pom.xml install

# 依存関係の解決だけ先に行い、Docker のレイヤキャッシュを効かせる
COPY pom.xml ./
RUN mvn -B -q --no-transfer-progress dependency:go-offline

# テストは GitHub Actions 側で実行済みのためここではスキップする
COPY src ./src
RUN mvn -B -q --no-transfer-progress clean package -DskipTests

# ---------------------------------------------------------------------
# runtime stage : Tomcat 9 (Servlet 4.0 / JSP 2.3)
# ---------------------------------------------------------------------
FROM --platform=linux/amd64 tomcat:9.0-jdk17-temurin

# 同梱のサンプルアプリ (manager / examples など) は削除する
RUN rm -rf /usr/local/tomcat/webapps/*

# ROOT コンテキスト (= サイトのルート /) として配置
COPY --from=build /build/target/ROOT/ /usr/local/tomcat/webapps/ROOT/

# 開発用の context.xml (reloadable="true") を本番用に差し替える
COPY docker/cloudflare/context.xml /usr/local/tomcat/webapps/ROOT/META-INF/context.xml

# MaxRAMPercentage : コンテナに割り当てたメモリの何 % までヒープに使うか。
#   残りは Metaspace やスレッドスタックが使うので 100% にはしないこと。
#   インスタンスサイズを変えてもそのまま追従します。
ENV TZ=Asia/Tokyo \
    CATALINA_OPTS="-Dfile.encoding=UTF-8 -Duser.language=ja -Duser.country=JP -XX:MaxRAMPercentage=60.0 -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8080

CMD ["catalina.sh", "run"]
