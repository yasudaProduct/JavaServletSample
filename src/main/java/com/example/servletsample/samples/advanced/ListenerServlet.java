package com.example.servletsample.samples.advanced;

import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】リスナーで起動・終了・セッションを捕まえる。
 *
 * <p>この Servlet 自体はリスナーを呼び出しません。<b>呼ぶのはコンテナ</b>です。
 * ここでやっているのは、リスナーが書き留めた記録 ({@link ListenerEventLog}) を
 * 画面に渡すことと、記録が増える操作 (セッションに値を入れる・消す・破棄する) を
 * 受け付けることだけです。</p>
 *
 * <pre>{@code
 * アプリ起動      → AppLifecycleListener#contextInitialized
 * 初めての表示    → SessionLifecycleListener#sessionCreated
 * 値を入れる      → SessionLifecycleListener#attributeAdded
 * 破棄する        → attributeRemoved × n → sessionDestroyed
 * アプリ停止      → AppLifecycleListener#contextDestroyed   (画面には出ません)
 * }</pre>
 *
 * <p>セッションに入れる値には {@value #DEMO_PREFIX} を付けています。
 * 他のサンプル (ログインなど) がセッションに置いた値を、
 * この画面から上書きしてしまわないようにするためです。</p>
 */
@WebServlet(name = "listenerSample", urlPatterns = {"/samples/advanced/listener"})
public class ListenerServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/advanced/listener.jsp";

    /** このサンプルの URL。 */
    static final String PATH = "/samples/advanced/listener";

    /** この画面から入れる属性に付ける名前の先頭。 */
    static final String DEMO_PREFIX = "demo.";

    /** 属性名の長さの上限。 */
    static final int MAX_NAME_LENGTH = 20;

    /** 値の長さの上限。 */
    static final int MAX_VALUE_LENGTH = 30;

    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm:ss");

    private static final DateTimeFormatter DATE_TIME_FORMAT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Flash.consume(request);

        // getSession() は「無ければ作る」。
        // この画面を初めて開いたときは、ここでセッションが作られ、
        // その瞬間に SessionLifecycleListener#sessionCreated が呼ばれます。
        HttpSession session = request.getSession();

        LocalDateTime startedAt = ListenerEventLog.getStartedAt();
        request.setAttribute("startedAt", startedAt == null ? "-" : DATE_TIME_FORMAT.format(startedAt));
        request.setAttribute("uptimeSeconds", ListenerEventLog.getUptimeSeconds());
        request.setAttribute("createdSessions", ListenerEventLog.getCreatedSessions());
        request.setAttribute("activeSessions", ListenerEventLog.getActiveSessions());
        request.setAttribute("serverInfo", getServletContext().getServerInfo());

        request.setAttribute("sessionId", SessionLifecycleListener.mask(session.getId()));
        request.setAttribute("sessionCreatedAt", format(session.getCreationTime()));
        request.setAttribute("sessionAccessedAt", format(session.getLastAccessedTime()));
        request.setAttribute("sessionTimeout", session.getMaxInactiveInterval());
        request.setAttribute("sessionAttributes", demoAttributes(session));

        request.setAttribute("events", ListenerEventLog.recent());
        request.setAttribute("maxEvents", ListenerEventLog.MAX_EVENTS);

        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        HttpSession session = request.getSession();

        if ("clear".equals(action)) {
            ListenerEventLog.clearEvents();
            Flash.set(request, "info", "記録を消しました",
                    "ここから先の呼び出しだけが並びます。");

        } else if ("invalidate".equals(action)) {
            // 破棄すると、入っていた値の数だけ attributeRemoved が呼ばれ、
            // 最後に sessionDestroyed が呼ばれます
            session.invalidate();

            // このあとの Flash.set は request.getSession() を呼びます。
            // 破棄したばかりなので「無ければ作る」が働き、ここで新しいセッションが
            // 1 つ生まれます (記録にも sessionCreated が出ます)。
            Flash.set(request, "success", "セッションを破棄しました",
                    "attributeRemoved → sessionDestroyed の順に呼ばれます。"
                            + "このメッセージを渡すため、直後に新しいセッションが 1 つ作られます。");

        } else if ("remove".equals(action)) {
            String name = Validators.strip(request.getParameter("name"));
            session.removeAttribute(DEMO_PREFIX + name);
            Flash.set(request, "info", "値を消しました",
                    DEMO_PREFIX + name + " をセッションから消しました。");

        } else {
            String error = putAttribute(request, session);
            if (error != null) {
                // 入力の誤りはリダイレクトせず、そのまま画面に戻す
                request.setAttribute("formError", error);
                request.setAttribute("inputName", request.getParameter("name"));
                request.setAttribute("inputValue", request.getParameter("value"));
                doGet(request, response);
                return;
            }
        }

        // PRG。再読み込みでもう一度同じ操作が走らないようにする
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /**
     * セッションに値を入れる。
     *
     * @return 入力に問題があればメッセージ。入れられたら {@code null}
     */
    private String putAttribute(HttpServletRequest request, HttpSession session) {
        String name = Validators.strip(request.getParameter("name"));
        String value = Validators.strip(request.getParameter("value"));

        String error = validate(name, value);
        if (error != null) {
            return error;
        }

        // 同じ名前に入れ直すと attributeAdded ではなく attributeReplaced が呼ばれます
        session.setAttribute(DEMO_PREFIX + name, value);
        Flash.set(request, "success", "値を入れました",
                DEMO_PREFIX + name + " をセッションに入れました。");
        return null;
    }

    /**
     * 属性名と値を確かめる。
     *
     * @return 問題があればメッセージ。無ければ {@code null}
     */
    static String validate(String name, String value) {
        if (Validators.isBlank(name)) {
            return "名前を入力してください。";
        }
        if (!Validators.isHalfWidthAlphanumeric(name)) {
            return "名前は半角英数字で入力してください。";
        }
        if (!Validators.isLengthAtMost(name, MAX_NAME_LENGTH)) {
            return "名前は " + MAX_NAME_LENGTH + " 文字以内で入力してください。";
        }
        if (Validators.isBlank(value)) {
            return "値を入力してください。";
        }
        if (!Validators.isLengthAtMost(value, MAX_VALUE_LENGTH)) {
            return "値は " + MAX_VALUE_LENGTH + " 文字以内で入力してください。";
        }
        return null;
    }

    /**
     * この画面から入れた属性だけを名前順に返す。
     *
     * <p>他のサンプルが置いた値 ({@code loginUser} など) は画面に出しません。</p>
     */
    static List<String> demoAttributes(HttpSession session) {
        List<String> names = new ArrayList<>();
        Enumeration<String> all = session.getAttributeNames();
        while (all.hasMoreElements()) {
            String name = all.nextElement();
            if (name.startsWith(DEMO_PREFIX)) {
                names.add(name);
            }
        }
        Collections.sort(names);
        return names;
    }

    /** エポックミリ秒を {@code HH:mm:ss} にする。 */
    private static String format(long epochMillis) {
        LocalDateTime time = LocalDateTime.ofInstant(Instant.ofEpochMilli(epochMillis), ZoneId.systemDefault());
        return TIME_FORMAT.format(time);
    }
}
