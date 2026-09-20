package com.example.servletsample.samples.ajax;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】処理の進捗をポーリングで取得する。
 *
 * <p>この Servlet が受け持つのは<b>画面を 1 枚表示するところまで</b>です。
 * 進捗のやり取りは、画面の JavaScript と
 * {@link AjaxPollingApiServlet} ({@code /samples/ajax/ajax-polling/api}) の間で行われます。</p>
 *
 * <pre>{@code
 * ［画面を開く］ ブラウザ ──GET /samples/ajax/ajax-polling──→ この Servlet ──forward──→ JSP
 *
 * ［開始］      JavaScript ──POST .../api (action=start)──→ AjaxPollingApiServlet
 *                                                          セッションに開始時刻を置く
 * ［1 秒おき］  JavaScript ──GET .../api──→ AjaxPollingApiServlet
 *                         ←── {"percent":37,...} ──
 *                         進捗バーを描き直す。100% になったら setInterval を止める
 * }</pre>
 *
 * <h2>画面を開き直しても続きから見られるようにする</h2>
 * <p>進捗はセッション (サーバ側) が持っているので、
 * 集計の途中でブラウザを再読み込みしても状態は消えていません。
 * ここでその状態を読み出して JSP へ渡し、画面が
 * 「実行中なら、開いた直後からポーリングを再開する」ようにしています。</p>
 *
 * <p>進捗を画面の JavaScript の変数だけで持つ作りにすると、
 * 再読み込みした瞬間に「何も実行していない画面」に戻ります。
 * サーバが状態を持っているかどうかの差が、いちばん分かりやすく出る場面です。</p>
 */
@WebServlet(name = "ajaxPolling", urlPatterns = {"/samples/ajax/ajax-polling"})
public class AjaxPollingServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/ajax/ajax-polling.jsp";

    /** 画面が最初に使うポーリングの間隔 (ミリ秒)。 */
    private static final int DEFAULT_INTERVAL_MILLIS = 1000;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 画面を出すだけなので、セッションが無ければ作りません (getSession(false))。
        // 何気なく getSession() と書くと、ページを見ただけで全員分のセッションが作られます。
        // セッションはメモリを使い、タイムアウトまで残り続けるので、
        // 「必要になったときに作る」のが基本です (このサンプルでは開始ボタンを押したときです)
        HttpSession session = request.getSession(false);

        long now = System.currentTimeMillis();
        AjaxPollingApiServlet.Job job = AjaxPollingApiServlet.findJob(session);

        if (job == null) {
            // 実行中の集計は無い
            request.setAttribute("resumeState", "idle");
            request.setAttribute("resumePercent", 0);
            request.setAttribute("resumeElapsedSeconds", 0);
            request.setAttribute("resumeStartedAt", "");
            request.setAttribute("resumeMessage", "「集計を開始」を押してください。");
            request.setAttribute("resumeResultCount", 0);
        } else {
            int percent = AjaxPollingApiServlet.percentOf(now - job.getStartedAtMillis());
            boolean done = percent >= 100;

            request.setAttribute("resumeState", done ? "done" : "running");
            request.setAttribute("resumePercent", percent);
            request.setAttribute("resumeElapsedSeconds",
                    AjaxPollingApiServlet.elapsedSecondsOf(now - job.getStartedAtMillis()));
            request.setAttribute("resumeStartedAt", job.getStartedAtText());
            request.setAttribute("resumeMessage", AjaxPollingApiServlet.messageOf(percent));
            request.setAttribute("resumeResultCount",
                    done ? AjaxPollingApiServlet.resultCountOf(job.getStartedAtMillis()) : 0);
        }

        // これまでに API を叩いた回数 (画面を開き直しても、サーバ側の数は続いています)
        request.setAttribute("serverPollCount", AjaxPollingApiServlet.pollCount(session));

        // API の URL と擬似処理の長さ。画面と Servlet で食い違わないよう 1 か所から渡します
        request.setAttribute("apiPath", AjaxPollingApiServlet.PATH);
        request.setAttribute("totalSeconds", AjaxPollingApiServlet.TOTAL_SECONDS);
        request.setAttribute("defaultIntervalMillis", DEFAULT_INTERVAL_MILLIS);

        forward(request, response, VIEW);
    }
}
