# syntax=docker/dockerfile:1

# =====================================================================
# build stage : Maven で WAR (展開形式) をビルドする
# =====================================================================
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build

# 共通ライブラリ (shared/) を先にビルドしてローカルリポジトリへ入れる。
# アプリ側の pom.xml がこれに依存しているため、順番を逆にすると解決できない。
# (これは制約ではなく、複数サーバー構成の現場と同じ順番です。
#  共通ライブラリを先にリリースし、アプリはその版を参照する)
COPY shared/pom.xml ./shared/pom.xml
COPY shared/src ./shared/src
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -q -f shared/pom.xml install

# 依存関係の解決だけ先に行い、Docker のレイヤキャッシュを効かせる
COPY pom.xml ./
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -q dependency:go-offline

# サンプル「共通処理を JAR に切り出す」のソースコードタブに出すビルド設定。
# pom.xml の <webResources> がこれらを参照しているため、COPY しないと
# 「basedir /build/.settings does not exist」でビルドが失敗します
# (maven-war-plugin は webResources の directory が無いとエラーになります)。
# 追加・変更するときは pom.xml の <webResources> と .dockerignore も合わせてください。
COPY build.xml .classpath ./
COPY .settings ./.settings

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -q clean package -DskipTests

# =====================================================================
# runtime stage : Tomcat 9 (Servlet 4.0 / JSP 2.3)
# =====================================================================
FROM tomcat:9.0-jdk17-temurin

# 同梱のサンプルアプリ (manager / examples など) は削除する
RUN rm -rf /usr/local/tomcat/webapps/*

# ROOT コンテキスト (= http://localhost:8080/) として配置
COPY --from=build /build/target/ROOT/ /usr/local/tomcat/webapps/ROOT/

ENV TZ=Asia/Tokyo \
    CATALINA_OPTS="-Dfile.encoding=UTF-8 -Duser.language=ja -Duser.country=JP" \
    JPDA_TRANSPORT=dt_socket \
    JPDA_ADDRESS=*:8000

# 8080 : HTTP / 8000 : リモートデバッグ (JPDA)
EXPOSE 8080 8000

# jpda 付きで起動し、VS Code からアタッチできるようにする
CMD ["catalina.sh", "jpda", "run"]
