package com.example.servletsample.samples.ajax;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;
import com.example.servletsample.samples.list.Page;
import com.example.servletsample.samples.list.Product;
import com.example.servletsample.samples.list.ProductDao;
import com.example.servletsample.samples.list.ProductSearch;

/**
 * 【サンプル】インクリメンタルサーチの候補を返す JSON API。
 *
 * <p>画面の JavaScript が、入力のたびに (正確には入力が止まるたびに) 呼びます。
 * 検索する中身は<b>一覧・検索サンプルとまったく同じ</b>
 * {@link ProductSearch} と {@link ProductDao} です。
 * 「画面用の Servlet」と「API 用の Servlet」で検索の書き方を分けてしまうと、
 * 条件の解釈がずれて「一覧では出るのに候補には出ない」といった食い違いが起きます。</p>
 *
 * <h2>なぜ GET なのか</h2>
 * <p>検索は<b>状態を変えない読み取り</b>なので GET です。
 * URL をそのままブラウザに貼れば応答を目で確かめられますし、
 * {@code /samples/ajax/ajax-search/api?q=ペン} のようにログにも残ります。
 * 逆に「登録」「削除」を GET にしてはいけません
 * (先読みやクローラに叩かれるだけで実行されてしまいます)。</p>
 *
 * <h2>返す JSON の形</h2>
 * <pre>{@code
 * {"q":"ペン","minLength":1,"limit":10,"elapsedMillis":3,
 *  "searched":true,"total":3,"truncated":false,
 *  "items":[{"id":1,"code":"P-0001","name":"ボールペン (黒・0.5mm)",
 *            "category":"文房具","price":130,"stock":1,"inStock":true}],
 *  "waitedMillis":0}
 * }</pre>
 *
 * <p>キーワードが短すぎて検索しなかったときも、{@code searched} を {@code false} にして
 * <b>同じ形</b>で返します。形が場合によって変わると、受け取る JavaScript に
 * 「このときは items が無い」といった分岐が増えていきます。</p>
 *
 * <h2>件数の上限はサーバ側で決める</h2>
 * <p>候補として返すのは {@link #SUGGEST_LIMIT} 件までです。
 * 画面から {@code size=50} と指定されても、ここで切り詰めます。
 * 「何件返すか」を画面の言い値のままにすると、URL を書き換えるだけで
 * 全件を引き出せる口になってしまうためです。
 * そのかわり <b>該当した総件数 ({@code total}) は正直に返します</b>。
 * 「◯ 件見つかりました (上位 10 件を表示)」と書けるようにするためです。</p>
 *
 * <h2>中断されてもサーバは止まらない</h2>
 * <p>ブラウザ側で {@code AbortController} を使うと通信は打ち切られますが、
 * <b>サーバはそのリクエストの処理を最後まで続けます</b>
 * (途中で書き込もうとした時点で初めて例外になります)。
 * 中断は「届いた答えを使わない」ための仕組みであって、
 * サーバの負荷を減らすものではありません。負荷を減らすのは debounce と最低文字数の役目です。</p>
 */
@WebServlet(name = "ajaxSearchApi", urlPatterns = {AjaxSearchServlet.API_PATH})
public class AjaxSearchApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /**
     * 検索を始める最低文字数。
     *
     * <p>日本語は 1 文字でも意味のある絞り込みになるので 1 にしていますが、
     * 英数字が中心のデータなら 2 〜 3 文字にするのが普通です。
     * 「a」で検索されると、ほぼ全件が該当してしまいます。</p>
     */
    public static final int MIN_KEYWORD_LENGTH = 1;

    /** 候補として返す件数の上限。 */
    public static final int SUGGEST_LIMIT = 10;

    /** わざと遅くするときの基準時間 (ミリ秒)。 */
    private static final long SLOW_BASE_MILLIS = 1200L;

    /** わざと遅くするとき、1 文字につき短くする時間 (ミリ秒)。 */
    private static final long SLOW_STEP_MILLIS = 250L;

    /** わざと遅くするときの下限 (ミリ秒)。 */
    private static final long SLOW_MIN_MILLIS = 150L;

    private final ProductDao dao = new ProductDao();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        long startedAt = System.nanoTime();

        // 検索結果をブラウザや途中の機器にキャッシュさせない。
        // GET はキャッシュされてよいものとして扱われるため、明示しておく
        response.setHeader("Cache-Control", "no-store");

        String keyword = normalize(request.getParameter("q"));

        // ① 短すぎる (空を含む) なら DB を見ない。ここで止めるのがいちばん効く負荷対策
        if (!isSearchable(keyword)) {
            Json.write(response, skipped(keyword, elapsedMillis(startedAt)));
            return;
        }

        // ② デモ用。?slow=on のときだけ、わざと遅い応答にする
        long waited = sleepIfRequested(request, keyword);

        // ③ 検索条件の組み立ても検索も、一覧サンプルとまったく同じ道具を使う。
        //    q だけでなく category や stock もそのまま効く。
        //    ただし q は整えたものを渡す (理由は withKeyword のコメント)
        ProductSearch search = ProductSearch.from(withKeyword(request, keyword));
        Page<Product> page = dao.search(search);

        // ④ 画面に出すのは上限まで。総件数は page が持っているので減らない
        List<Product> shown = limit(page.getItems(), SUGGEST_LIMIT);

        Json.write(response, toJson(keyword, page, shown, waited, elapsedMillis(startedAt)));
    }

    /**
     * {@code q} だけを整えた値に差し替えたリクエストを返す。
     *
     * <p>{@link ProductSearch#from(HttpServletRequest)} は {@code q} を {@code trim()} で整えます。
     * {@code trim()} は全角スペースを落とさないので、素のリクエストをそのまま渡すと
     * <b>「整えたキーワードを画面に返しているのに、検索には整える前の値を使う」</b>という
     * ねじれが起きます。{@code ?q=(全角スペース)ペン} が
     * {@code {"q":"ペン", "total":0}} — 「ペン」で 0 件 — になってしまう、という具合です。</p>
     *
     * <p>{@link ProductSearch} は一覧サンプルのものなので書き換えません。
     * かわりに {@link HttpServletRequestWrapper} で {@code q} の読み取りだけを差し替えます。
     * 「渡す値を整えてから既存の部品に渡す」のは、
     * 共有している部品に手を入れずに済ませるときの定石です。</p>
     */
    static HttpServletRequest withKeyword(HttpServletRequest request, String keyword) {
        return new HttpServletRequestWrapper(request) {
            @Override
            public String getParameter(String name) {
                return "q".equals(name) ? keyword : super.getParameter(name);
            }
        };
    }

    // ------------------------------------------------------------------
    // ここから下は Servlet API に触れない部分 (そのままテストできる)
    // ------------------------------------------------------------------

    /**
     * 受け取ったキーワードを整える。
     *
     * <p>{@code trim()} ではなく {@code strip()} を使っています。
     * {@code trim()} は全角スペースを落とさないため、
     * 全角スペースだけを入力されたときに「入力あり」と判断してしまいます。</p>
     */
    static String normalize(String value) {
        return value == null ? "" : value.strip();
    }

    /**
     * 検索してよいキーワードか。
     *
     * <p>文字数は {@code length()} ではなく符号位置で数えます。
     * {@code length()} は UTF-16 の単位数なので、絵文字や一部の漢字が 2 文字と数えられ、
     * 画面に書いた「◯ 文字以上」と食い違います。</p>
     */
    static boolean isSearchable(String keyword) {
        return keyword.codePointCount(0, keyword.length()) >= MIN_KEYWORD_LENGTH;
    }

    /** 先頭から {@code max} 件までに切り詰める (それ以下ならそのまま)。 */
    static List<Product> limit(List<Product> products, int max) {
        return products.size() <= max ? products : new ArrayList<>(products.subList(0, max));
    }

    /**
     * わざと遅くするときの待ち時間。
     *
     * <p><b>キーワードが短いほど長く待たせます</b>。
     * 「ペ」→「ペン」と打った場合に、先に投げた「ペ」の応答が後から返るので、
     * 古い結果で新しい結果を上書きしてしまう競合を、画面で確実に再現できます。
     * (本物の遅延は運任せで、偶然に頼ると学習用のデモになりません。)</p>
     */
    static long delayMillisFor(String keyword) {
        long delay = SLOW_BASE_MILLIS - SLOW_STEP_MILLIS * keyword.codePointCount(0, keyword.length());
        return Math.max(SLOW_MIN_MILLIS, delay);
    }

    /**
     * 検索結果を JSON にする。
     *
     * <p>文字列のエスケープ ({@code "} や {@code \} や制御文字) は
     * {@link Json} が行います。商品名を組み立てた文字列に直接足し込んではいけません。</p>
     *
     * @param keyword  検索に使ったキーワード (画面にそのまま返す)
     * @param page     検索結果 (総件数はここから取る)
     * @param shown    実際に返す候補 (上限まで切り詰め済み)
     * @param waited   デモ用に待たせた時間
     * @param elapsed  サーバ側で掛かった時間
     */
    static Json.JsonObject toJson(String keyword, Page<Product> page, List<Product> shown,
                                  long waited, long elapsed) {
        Json.JsonArray items = Json.array();
        for (Product product : shown) {
            items.add(Json.object()
                    .put("id", product.getId())
                    .put("code", product.getCode())
                    .put("name", product.getName())
                    .put("category", product.getCategory())
                    .put("price", product.getPrice())
                    .put("stock", product.getStock())
                    .put("inStock", product.isInStock()));
        }
        return base(keyword, elapsed)
                .put("searched", true)
                .put("total", page.getTotalCount())
                .put("truncated", page.getTotalCount() > shown.size())
                .put("items", items)
                .put("waitedMillis", waited);
    }

    /** 検索しなかったときの JSON (形は検索したときと同じにそろえる)。 */
    static Json.JsonObject skipped(String keyword, long elapsed) {
        return base(keyword, elapsed)
                .put("searched", false)
                .put("total", 0)
                .put("truncated", false)
                .put("items", Json.array())
                .put("waitedMillis", 0);
    }

    /** どちらの場合にも入る共通の項目。 */
    private static Json.JsonObject base(String keyword, long elapsed) {
        return Json.object()
                .put("q", keyword)
                .put("minLength", MIN_KEYWORD_LENGTH)
                .put("limit", SUGGEST_LIMIT)
                .put("elapsedMillis", elapsed);
    }

    // ------------------------------------------------------------------
    // 内部処理
    // ------------------------------------------------------------------

    /**
     * {@code ?slow=on} が付いていれば、わざと待つ (デモ専用)。
     *
     * <p>{@code Thread.sleep} はコンテナのスレッドを 1 本占有します。
     * 実務のコードにこう書くことはありませんが、
     * 「遅い応答が後から返る」状況を手元で作るために入れています。</p>
     *
     * @return 実際に待った時間 (待たなければ 0)
     */
    private static long sleepIfRequested(HttpServletRequest request, String keyword) {
        if (request.getParameter("slow") == null) {
            return 0L;
        }
        long millis = delayMillisFor(keyword);
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            // 割り込まれたことを握りつぶさず、呼び出し元に伝わるよう印を戻しておく
            Thread.currentThread().interrupt();
        }
        return millis;
    }

    /** 開始からの経過時間 (ミリ秒)。 */
    private static long elapsedMillis(long startedAtNanos) {
        return (System.nanoTime() - startedAtNanos) / 1_000_000L;
    }
}
