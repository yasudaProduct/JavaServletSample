package com.example.servletsample.samples.advanced;

import java.io.IOException;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;

/**
 * 【サンプル】非同期通信 (Ajax) の呼び先で起きた例外の返し方。
 *
 * <p>画面を返す Servlet と違い、<b>JSON API で例外をそのまま外へ投げてはいけません</b>。
 * コンテナは {@code web.xml} の {@code <error-page>} にしたがって
 * <b>HTML のエラーページ</b>を返してしまうため、
 * {@code response.json()} を待っていた画面側は
 * 「Unexpected token &lt;」のような、原因と関係のない例外で止まります。</p>
 *
 * <pre>{@code
 * ［そのまま投げた場合］
 *   fetch → 例外 → コンテナ → 500 + <!DOCTYPE html>...   ← JSON を期待している画面には読めない
 *
 * ［JSON に変換した場合］
 *   fetch → 例外 → catch → 500 + {"ok":false,"message":"..."}   ← 画面がメッセージを出せる
 * }</pre>
 *
 * <p>API の入口で受け止めて<b>形の決まった JSON</b>に変換するのが定石です。
 * 実務では、API 用の Servlet の共通の親クラスやフィルタに置いて、
 * 個々の API が書き忘れても必ず通るようにします。</p>
 *
 * <h2>受け付けるパラメータ</h2>
 * <table border="1">
 *   <caption>クエリパラメータ</caption>
 *   <tr><th>{@code mode}</th><th>返すもの</th></tr>
 *   <tr><td>{@code ok} (既定)</td><td>200 + 正常な JSON</td></tr>
 *   <tr><td>{@code json}</td><td>500 + エラーを表す JSON (受け止めて変換した場合)</td></tr>
 *   <tr><td>{@code html}</td><td>例外をそのまま投げる → HTML のエラーページが返る</td></tr>
 *   <tr><td>{@code business}</td><td>400 + 業務エラーを表す JSON</td></tr>
 * </table>
 */
@WebServlet(name = "errorHandlingApi", urlPatterns = {"/samples/advanced/error-handling/api"})
public class ErrorHandlingApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** この API の URL (画面へ渡して fetch 先にする)。 */
    static final String PATH = "/samples/advanced/error-handling/api";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String mode = request.getParameter("mode");
        response.setHeader("Cache-Control", "no-store");

        if ("html".equals(mode)) {
            // 【悪い例】 受け止めずに外へ投げる。
            // コンテナが HTML のエラーページを返すので、画面側の res.json() が失敗する
            loadReport();
            return;
        }

        try {
            if ("json".equals(mode)) {
                loadReport();                     // ここで例外が飛ぶ
            }
            if ("business".equals(mode)) {
                throw new ApplicationException("E-3001", "対象の期間に締め処理が行われていません。");
            }
            Json.write(response, Json.object()
                    .put("ok", true)
                    .put("message", "集計が完了しました。")
                    .put("total", 12345));

        } catch (ApplicationException e) {
            // 業務エラー : 利用者が対処できるので、メッセージをそのまま画面へ渡してよい。
            // ステータスは「送られてきた内容が処理できない」という意味の 400 系にする
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            Json.write(response, Json.object()
                    .put("ok", false)
                    .put("code", e.getCode())
                    .put("message", e.getMessage()));

        } catch (RuntimeException e) {
            // システムエラー : 原因はログに出し、画面へは当たり障りのない文言だけを返す。
            // 例外のメッセージやスタックトレースをそのまま返すと、
            // DB のホスト名やテーブル名を外部に教えることになります
            getServletContext().log("API でエラーが発生しました: " + PATH, e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Json.write(response, Json.object()
                    .put("ok", false)
                    .put("code", "E-9999")
                    .put("message", "処理中に問題が発生しました。時間をおいて再度お試しください。"));
        }
    }

    /**
     * 集計処理 (デモ用)。必ず失敗します。
     *
     * <p>下位で起きた例外を握りつぶさず、原因として引き渡しているところが要点です。</p>
     */
    private static void loadReport() {
        throw new IllegalStateException("集計用のテーブルを読み込めませんでした",
                new SQLException("connection refused: report-db:5432"));
    }
}
