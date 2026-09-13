package com.example.servletsample.catalog;

import java.util.ArrayList;
import java.util.List;

import com.example.servletsample.samples.basic.HelloWorldServlet;

/**
 * ★ サンプルを追加する場所 ★
 *
 * <p>サンプルを 1 つ増やすときにやることは 2 つだけです。</p>
 * <ol>
 *   <li>{@code src/main/webapp/WEB-INF/views/samples/{カテゴリ}/{ID}.jsp} を作る</li>
 *   <li>このクラスの {@link #define()} に定義を 1 つ足す</li>
 * </ol>
 *
 * <p>Servlet が必要なサンプル (画面から POST を受けるなど) は
 * {@code com.example.servletsample.samples} 配下に {@code @WebServlet("/samples/{カテゴリ}/{ID}")}
 * で作れば、そちらが優先して呼ばれます。Servlet が無いサンプルは
 * {@link com.example.servletsample.web.SampleDispatcherServlet} が JSP へ転送します。</p>
 *
 * <p>詳しい手順とテンプレートはリポジトリの {@code docs/ADD_SAMPLE.md} にあります。</p>
 */
final class SampleDefinitions {

    private SampleDefinitions() {
    }

    static List<Sample> define() {
        List<Sample> samples = new ArrayList<>();

        // ------------------------------------------------------------------
        // 基本
        // ------------------------------------------------------------------
        samples.add(Sample.builder("hello-world", Category.BASIC)
                .title("Hello World (Servlet → JSP)")
                .summary("Servlet でデータを用意して JSP へ転送する、Web アプリのもっとも基本的な流れ。")
                .tags("Servlet", "JSP", "forward", "リクエストスコープ")
                .source(HelloWorldServlet.class)
                .build());

        // ------------------------------------------------------------------
        // 画面デザイン
        // ------------------------------------------------------------------
        samples.add(Sample.builder("bootstrap-basics", Category.DESIGN)
                .title("Bootstrap 4 の基本パーツ")
                .summary("グリッド、ボタン、カード、テーブル、アラートなど、画面作成で使う部品の一覧。")
                .tags("Bootstrap4", "グリッド", "カード", "ボタン", "CSS")
                .build());

        // ------------------------------------------------------------------
        // ここから下は「これから作るサンプル」の登録例です。
        // 状態を PLANNED にしておくと、一覧にグレー表示され、リンクは張られません。
        // 実際に作るときは status(...) を外して JSP を用意してください。
        // ------------------------------------------------------------------
        samples.add(Sample.builder("input-validation", Category.FORM)
                .title("入力チェック（バリデーション）")
                .summary("必須・桁数・形式のチェックとエラーメッセージの表示。")
                .status(SampleStatus.PLANNED)
                .tags("フォーム", "バリデーション", "POST")
                .build());

        samples.add(Sample.builder("pagination", Category.LIST)
                .title("一覧のページング")
                .summary("件数の多い一覧をページ送りで表示する。")
                .status(SampleStatus.PLANNED)
                .tags("一覧", "ページング", "JSTL")
                .build());

        return samples;
    }
}
