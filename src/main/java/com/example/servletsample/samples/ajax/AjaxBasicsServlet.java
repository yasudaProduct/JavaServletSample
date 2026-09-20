package com.example.servletsample.samples.ajax;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】非同期通信の基本 (fetch で JSON を取得)。
 *
 * <p>この Servlet が受け持つのは<b>最初の 1 回の画面表示だけ</b>です。
 * ボタンを押したあとのやり取りは、画面の JavaScript と
 * {@link AjaxBasicsApiServlet} ({@code /samples/ajax/ajax-basics/api}) の間で行われます。</p>
 *
 * <pre>{@code
 * ［画面を開く］   ブラウザ ──GET /samples/ajax/ajax-basics──→ この Servlet ──forward──→ JSP
 *                          ←──────── HTML 1 枚 ────────
 *
 * ［ボタンを押す］ JavaScript ──GET .../ajax-basics/api──→ AjaxBasicsApiServlet
 *                            ←──────── JSON ────────
 *                  ※ ブラウザは画面を捨てない。JavaScript が画面の一部だけを書き換える
 * }</pre>
 *
 * <p>画面には「ページを開いた時刻」を埋め込んで渡しています。
 * これは<b>この Servlet が動いた時刻</b>なので、ボタンを何度押しても変わりません。
 * 一方、API から受け取る時刻は押すたびに新しくなります。
 * 2 つを並べておくと「画面そのものは読み込み直されていない」ことが一目で分かります。</p>
 *
 * <p>公開中のサンプル件数も同じ狙いで渡しています。
 * ページを開いた時点の値 (ここで渡す値) と、API が返す値を見比べるためのものです。</p>
 */
@WebServlet(name = "ajaxBasics", urlPatterns = {"/samples/ajax/ajax-basics"})
public class AjaxBasicsServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/ajax/ajax-basics.jsp";

    /**
     * 画面と API で共通に使う時刻の書式。
     *
     * <p>{@link DateTimeFormatter} は<b>変更できないオブジェクト (イミュータブル) なので、
     * 複数のスレッドから同時に使っても安全</b>です。だから {@code static final} で持てます。</p>
     *
     * <p>古いコードでよく見る {@code SimpleDateFormat} はこの逆で、スレッドセーフではありません。
     * Servlet のフィールドに {@code static final SimpleDateFormat} を置くのは典型的な事故のもとで、
     * アクセスが重なったときだけ日付が壊れたり例外が出たりします
     * (Servlet のインスタンスは 1 つで、そこへ複数のスレッドが同時に入ってくるためです)。</p>
     */
    static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * 画面を表示する。
     *
     * <p>状態を何も変えないので GET です。</p>
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 「このページの HTML が作られた時刻」。以降どれだけボタンを押しても、この値は変わらない
        request.setAttribute("openedAt", LocalDateTime.now().format(TIME_FORMAT));

        // ページを開いた時点の公開サンプル件数 (API が返す値と見比べるために渡す)
        request.setAttribute("pageSampleCount", catalog().getTotalCount());

        // API の URL。JSP 側でも組み立てられるが、画面と Servlet で食い違わないよう 1 か所から渡す
        request.setAttribute("apiPath", AjaxBasicsApiServlet.PATH);

        forward(request, response, VIEW);
    }
}
