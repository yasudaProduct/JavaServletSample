package com.example.servletsample.samples.ajax;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.samples.list.ProductDao;

/**
 * 【サンプル】インクリメンタルサーチ (入力するたびに検索) の画面側。
 *
 * <p>この Servlet がするのは<b>画面を出すことだけ</b>です。
 * 候補そのものは {@link AjaxSearchApiServlet} が JSON で返し、画面の JavaScript が呼びます。
 * 「最初の 1 枚の HTML を返す Servlet」と「あとから呼ばれる API」を分けるのが、
 * 非同期通信を使う画面の基本の形です。</p>
 *
 * <h2>画面へ渡している値 (request スコープ)</h2>
 * <ul>
 *   <li>{@code apiPath} … 候補を返す API の URL。画面に URL を直接書かないで済ませるため</li>
 *   <li>{@code debounceMillis} … 入力が止まってから検索するまでの待ち時間</li>
 *   <li>{@code minKeywordLength} … 検索を始める最低文字数</li>
 *   <li>{@code suggestLimit} … 候補として返す件数の上限</li>
 *   <li>{@code categories} / {@code allCount} … カテゴリの選択肢と、データの総件数 (説明用)</li>
 * </ul>
 *
 * <p>待ち時間や上限のような<b>数値を Java 側に置いて画面へ渡している</b>のには理由があります。
 * 画面の説明文 (「300 ms 待ってから検索します」) と、JavaScript が実際に使う値が別々に書かれていると、
 * 片方だけ直したときに嘘の説明が残るからです。
 * 同じことを {@code samples/form/RealtimeValidationServlet} でも行っています。</p>
 *
 * <p>URL は完全一致 ({@code /samples/ajax/ajax-search}) で割り当てているので、
 * 前方一致の {@code /samples/*} より優先してこの Servlet が呼ばれます。</p>
 */
@WebServlet(name = "ajaxSearch", urlPatterns = {AjaxSearchServlet.PATH})
public class AjaxSearchServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** このサンプルの URL。 */
    public static final String PATH = "/samples/ajax/ajax-search";

    /**
     * 候補を返す API の URL。
     *
     * <p>サンプル本体の URL の下にぶら下げています。
     * {@code static final} の文字列どうしの連結はコンパイル時に決まる定数なので、
     * {@link AjaxSearchApiServlet} の {@code @WebServlet} にそのまま書けます。</p>
     */
    public static final String API_PATH = PATH + "/api";

    /**
     * 入力が止まってから検索を始めるまでの待ち時間 (ミリ秒)。
     *
     * <p>打っている間じゅうリクエストを投げないための間合いです。
     * 短すぎると打鍵のたびに飛び、長すぎると「反応が鈍い」と感じられます。
     * 200 〜 400 ms あたりが目安で、このサンプルでは 300 ms にしています。</p>
     */
    public static final int DEBOUNCE_MILLIS = 300;

    private static final String VIEW = "/WEB-INF/views/samples/ajax/ajax-search.jsp";

    /**
     * 一覧・検索サンプルと同じ DAO。
     *
     * <p>コンストラクタの中でテーブルの用意まで済ませてくれるので、
     * この画面を最初に開いた場合でも商品データが揃った状態になります。</p>
     */
    private final ProductDao dao = new ProductDao();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("apiPath", API_PATH);
        request.setAttribute("debounceMillis", DEBOUNCE_MILLIS);
        request.setAttribute("minKeywordLength", AjaxSearchApiServlet.MIN_KEYWORD_LENGTH);
        request.setAttribute("suggestLimit", AjaxSearchApiServlet.SUGGEST_LIMIT);

        // 絞り込み用のカテゴリと、データの総件数 (画面の説明に使う)
        request.setAttribute("categories", dao.findCategories());
        request.setAttribute("allCount", dao.countAll());

        forward(request, response, VIEW);
    }
}
