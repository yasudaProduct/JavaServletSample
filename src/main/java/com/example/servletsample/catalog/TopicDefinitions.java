package com.example.servletsample.catalog;

import java.util.ArrayList;
import java.util.List;

/**
 * ★ 座学メモを追加する場所 ★
 *
 * <p>座学メモは「動かして見せにくいが、知らないと後で詰まる話」を置くところです。
 * サンプルと違ってデモもソースコードも無いので、増やすときにやることは 2 つだけです。</p>
 * <ol>
 *   <li>{@code src/main/webapp/WEB-INF/views/topics/{ID}.jsp} を作る</li>
 *   <li>このクラスの {@link #define()} に定義を 1 つ足す</li>
 * </ol>
 *
 * <p>ページの枠 (見出し・パンくず・関連サンプル・前後リンク) は
 * {@code WEB-INF/tags/topic.tag} が作るので、JSP には本文だけ書きます。</p>
 *
 * <p>詳しい手順とテンプレートはリポジトリの {@code docs/ADD_SAMPLE.md} にあります。</p>
 */
final class TopicDefinitions {

    private TopicDefinitions() {
    }

    static List<Topic> define() {
        List<Topic> topics = new ArrayList<>();

        // ------------------------------------------------------------------
        // 動く仕組み
        // ------------------------------------------------------------------
        topics.add(Topic.builder("request-lifecycle", TopicGroup.MECHANISM)
                .title("リクエストが届いて返るまで")
                .summary("ブラウザのアドレスバーに URL を入れてから画面が出るまでに、どこを何が通るのか。"
                        + "障害が起きたとき「どこを見ればよいか」の地図になります。")
                .readingMinutes(8)
                .tags("HTTP", "TCP", "リバースプロキシ", "コネクタ", "スレッド", "障害切り分け")
                .relatedSamples("url-mapping", "request-response", "filter", "servlet-lifecycle")
                .build());

        topics.add(Topic.builder("servlet-container", TopicGroup.MECHANISM)
                .title("Servlet コンテナと WAR（Tomcat は何をしているのか）")
                .summary("自分で main メソッドを書いていないのに、なぜ Servlet が動くのか。"
                        + "WAR の中身、WEB-INF が公開されない理由、クラスローダ、配備と再読み込みまで。")
                .readingMinutes(9)
                .tags("Tomcat", "WAR", "WEB-INF", "クラスローダ", "web.xml", "デプロイ", "Maven")
                .relatedSamples("context-path", "servlet-config", "url-mapping", "listener")
                .build());

        topics.add(Topic.builder("threads-and-pools", TopicGroup.MECHANISM)
                .title("スレッドとプール（同時アクセスをさばく仕組み）")
                .summary("リクエスト 1 本にスレッド 1 本。その本数には上限があり、DB のコネクション数とも"
                        + "かみ合っていないと詰まります。「遅い」と「詰まる」は別の症状です。")
                .readingMinutes(9)
                .tags("スレッドプール", "maxThreads", "コネクションプール", "スレッドダンプ",
                        "タイムアウト", "性能")
                .relatedSamples("servlet-lifecycle", "scope", "async")
                .build());

        topics.add(Topic.builder("session-scaleout", TopicGroup.MECHANISM)
                .title("セッションはどこにあるか（サーバが 2 台になった日）")
                .summary("セッションはサーバのメモリの中にあります。サーバを増やした瞬間に"
                        + "「ときどきログアウトする」が始まる理由と、その 4 つの対処。")
                .readingMinutes(8)
                .tags("セッション", "スケールアウト", "ロードバランサ", "スティッキーセッション",
                        "レプリケーション", "ステートレス")
                .relatedSamples("scope", "login", "auth-filter")
                .build());

        // ------------------------------------------------------------------
        // 設計と作法
        // ------------------------------------------------------------------
        topics.add(Topic.builder("layering", TopicGroup.PRACTICE)
                .title("どこに何を書くか（Servlet / Service / DAO）")
                .summary("Servlet に全部書いても動きます。動くのに分けるのは、"
                        + "2 年後に直す人（たいてい自分）のためです。分ける基準と、分けすぎの見分け方。")
                .readingMinutes(9)
                .tags("設計", "レイヤ", "DAO", "サービス", "トランザクション境界", "責務分割", "テスト")
                .relatedSamples("crud", "transaction", "search-list")
                .build());

        topics.add(Topic.builder("exception-logging", TopicGroup.PRACTICE)
                .title("例外とログ（障害を追えるアプリにする）")
                .summary("「エラーが出ました」という電話から原因にたどり着けるかは、"
                        + "コードを書いた時点でほぼ決まっています。握りつぶさない、消さない、絞らない。")
                .readingMinutes(9)
                .tags("例外", "ログ", "スタックトレース", "ログレベル", "リクエストID",
                        "個人情報", "障害調査")
                .relatedSamples("error-handling", "filter", "transaction")
                .build());

        topics.add(Topic.builder("security-overview", TopicGroup.PRACTICE)
                .title("業務 Web のセキュリティ全体像")
                .summary("攻撃手法を覚えるより、「境界の外から来た値を信じない」「出す場所に合わせて加工する」"
                        + "の 2 つを守るほうが効きます。何がどこで効くのかを一枚にまとめます。")
                .readingMinutes(10)
                .tags("セキュリティ", "XSS", "SQLインジェクション", "CSRF", "認可", "入力検証",
                        "アップロード", "脆弱性")
                .relatedSamples("csrf", "login", "auth-filter", "file-upload", "input-validation")
                .build());

        topics.add(Topic.builder("performance-basics", TopicGroup.PRACTICE)
                .title("「遅い」と言われたときに見るところ")
                .summary("速くする前に、どこが遅いのかを決めます。件数が増えたときだけ牙をむく"
                        + "N+1・全件取得・索引なしの三点セットと、測らずに直さないための手順。")
                .readingMinutes(9)
                .tags("性能", "N+1", "インデックス", "ページング", "キャッシュ", "計測", "SQL")
                .relatedSamples("search-list", "ajax-search", "optimistic-lock")
                .build());

        // ------------------------------------------------------------------
        // 本番とこの先
        // ------------------------------------------------------------------
        topics.add(Topic.builder("beyond-localhost", TopicGroup.OPERATION)
                .title("localhost と本番の違い")
                .summary("HTTPS、リバースプロキシ、環境ごとの設定、消えるファイル、ずれる時刻。"
                        + "手元では絶対に再現しないのに、本番では必ず出会う話をまとめます。")
                .readingMinutes(10)
                .tags("HTTPS", "リバースプロキシ", "X-Forwarded-For", "Cookie", "環境変数",
                        "タイムゾーン", "デプロイ", "運用")
                .relatedSamples("cookie", "context-path", "i18n", "login")
                .build());

        topics.add(Topic.builder("jakarta-and-frameworks", TopicGroup.OPERATION)
                .title("javax から jakarta へ、そしてフレームワークへ")
                .summary("このサイトが javax.servlet なのはなぜか。jakarta.servlet との違いと移行、"
                        + "そして Spring MVC が結局 Servlet 1 個だという話。次に何を学ぶかの地図。")
                .readingMinutes(9)
                .tags("Jakarta EE", "javax", "jakarta", "Tomcat", "Spring", "DispatcherServlet",
                        "Spring Boot", "学習の進め方")
                .relatedSamples("hello-world", "url-mapping", "filter", "listener")
                .build());

        return topics;
    }
}
