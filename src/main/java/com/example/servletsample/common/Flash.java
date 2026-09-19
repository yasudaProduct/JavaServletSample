package com.example.servletsample.common;

import java.io.Serializable;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * リダイレクトをまたいでメッセージを 1 回だけ渡す仕組み (フラッシュメッセージ)。
 *
 * <p>登録や削除のあとは、二重送信を防ぐために
 * <b>POST → リダイレクト → GET</b> (PRG パターン) にするのが定番です。
 * ただしリダイレクトすると別のリクエストになるため、
 * {@code request.setAttribute} で入れた値は消えてしまいます。</p>
 *
 * <p>そこで「セッションに入れて、次の 1 回の表示で取り出して消す」という受け渡しをします。
 * 取り出したあとにセッションから消すので、画面を再読み込みしても二度は出ません。</p>
 *
 * <pre>{@code
 * // 登録処理のあと (POST 側)
 * Flash.set(request, "success", "登録しました", "受付番号は A-001 です。");
 * response.sendRedirect(request.getContextPath() + "/samples/design/modal-dialog");
 *
 * // 表示側 (GET 側)
 * Flash.consume(request);   // request スコープの "flash" に移す
 * }</pre>
 *
 * <p>JSP からは {@code ${flash.title}} のように参照できます。</p>
 */
public final class Flash {

    /** セッションに置くときのキー。 */
    private static final String SESSION_KEY = "servletSample.flash";

    /** JSP から参照するときの request スコープ属性名。 */
    public static final String ATTRIBUTE_NAME = "flash";

    private Flash() {
    }

    /**
     * メッセージを保存する (リダイレクトの前に呼ぶ)。
     *
     * @param variant Bootstrap の色 (success / danger / warning / info)
     * @param title   見出し
     * @param text    本文
     */
    public static void set(HttpServletRequest request, String variant, String title, String text) {
        set(request, variant, title, text, null);
    }

    /**
     * 「知らせたあとに移動させたい画面」付きでメッセージを保存する。
     *
     * <p>完了モーダルを閉じたら一覧画面へ送る、といった流れで使います。
     * 移動先は画面側 (JSP / {@code resultModal.tag}) が使うので、
     * 指定しなければこれまで通りその場にとどまります。</p>
     *
     * @param nextUrl 完了を知らせたあとに移動させる URL (不要なら null)
     */
    public static void set(HttpServletRequest request, String variant, String title, String text,
                           String nextUrl) {
        request.getSession().setAttribute(SESSION_KEY, new Message(variant, title, text, nextUrl));
    }

    /**
     * メッセージを取り出して request スコープへ移す (リダイレクト後の表示側で呼ぶ)。
     *
     * <p>セッションからは削除するので、同じメッセージが次の画面に残りません。</p>
     */
    public static void consume(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return;
        }
        Object message = session.getAttribute(SESSION_KEY);
        if (message != null) {
            session.removeAttribute(SESSION_KEY);
            request.setAttribute(ATTRIBUTE_NAME, message);
        }
    }

    /** 画面に出すメッセージ 1 件分。 */
    public static final class Message implements Serializable {

        private static final long serialVersionUID = 1L;

        private final String variant;
        private final String title;
        private final String text;
        private final String nextUrl;

        Message(String variant, String title, String text, String nextUrl) {
            this.variant = variant;
            this.title = title;
            this.text = text;
            this.nextUrl = nextUrl == null ? "" : nextUrl;
        }

        /** Bootstrap の色 (success / danger / warning / info)。 */
        public String getVariant() {
            return variant;
        }

        /** 見出し。 */
        public String getTitle() {
            return title;
        }

        /** 本文。 */
        public String getText() {
            return text;
        }

        /** 知らせたあとに移動させる画面の URL。移動しない場合は空文字。 */
        public String getNextUrl() {
            return nextUrl;
        }
    }
}
