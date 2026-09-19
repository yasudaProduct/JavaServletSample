package com.example.servletsample.catalog;

import java.util.ArrayList;
import java.util.List;

import com.example.servletsample.common.Database;
import com.example.servletsample.common.Flash;
import com.example.servletsample.samples.basic.HelloWorldServlet;
import com.example.servletsample.samples.design.ModalDialogEntriesServlet;
import com.example.servletsample.samples.design.ModalDialogServlet;
import com.example.servletsample.samples.design.ReceptionEntry;
import com.example.servletsample.samples.file.FileDownloadServlet;
import com.example.servletsample.samples.file.FileUploadServlet;
import com.example.servletsample.samples.file.StoredFile;
import com.example.servletsample.samples.file.StoredFileDao;
import com.example.servletsample.samples.list.Page;
import com.example.servletsample.samples.list.Product;
import com.example.servletsample.samples.list.ProductDao;
import com.example.servletsample.samples.list.ProductListServlet;
import com.example.servletsample.samples.list.ProductSearch;

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

        samples.add(Sample.builder("modal-dialog", Category.DESIGN)
                .title("モーダル（ダイアログ）の出し方 4 パターン")
                .summary("ボタンで開く確認モーダル、処理後の完了モーダル、画面遷移後に出すモーダル、"
                        + "そして「確認 → 登録 → 完了モーダル → 画面遷移」の一連の流れ。")
                .tags("Bootstrap4", "モーダル", "確認ダイアログ", "PRG", "フラッシュメッセージ",
                        "リダイレクト", "画面遷移")
                .source(ModalDialogServlet.class)
                .source(ModalDialogEntriesServlet.class)
                .source(ReceptionEntry.class)
                .source(Flash.class)
                .source(SourceFile.jsp("/WEB-INF/views/samples/design/modal-dialog-entries.jsp"))
                .build());

        // ------------------------------------------------------------------
        // 一覧・検索
        // ------------------------------------------------------------------
        samples.add(Sample.builder("search-list", Category.LIST)
                .title("検索つき一覧画面（ページング・並び替え）")
                .summary("キーワードとカテゴリで絞り込み、ページを送りながら見る一覧。SQL の LIMIT / OFFSET で必要な行だけを取り出します。")
                .tags("一覧", "検索", "ページング", "ソート", "SQL", "JDBC", "JSTL")
                .source(ProductListServlet.class)
                .source(ProductSearch.class)
                .source(ProductDao.class)
                .source(Page.class)
                .source(Product.class)
                .source(Database.class)
                .build());

        // ------------------------------------------------------------------
        // ファイル
        // ------------------------------------------------------------------
        samples.add(Sample.builder("file-upload", Category.FILE)
                .title("ファイルのアップロード・ダウンロード・削除（DB 保存）")
                .summary("選んだファイルをデータベースの BLOB 列に保存し、一覧からダウンロード・削除する。")
                .tags("ファイル", "アップロード", "ダウンロード", "multipart", "BLOB", "JDBC")
                .source(FileUploadServlet.class)
                .source(FileDownloadServlet.class)
                .source(StoredFileDao.class)
                .source(StoredFile.class)
                .source(SourceFile.jsp("/WEB-INF/tags/resultModal.tag"))
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

        return samples;
    }
}
