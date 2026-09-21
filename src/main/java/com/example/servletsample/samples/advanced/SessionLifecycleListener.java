package com.example.servletsample.samples.advanced;

import javax.servlet.annotation.WebListener;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpSessionAttributeListener;
import javax.servlet.http.HttpSessionBindingEvent;
import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

/**
 * 【サンプル】セッションの作成・破棄と、セッションに置いた値の出し入れを捕まえるリスナー。
 *
 * <p>2 つのインタフェースを 1 つのクラスで実装しています
 * (1 つのクラスにまとめるか、別々にするかは好みの問題です)。</p>
 *
 * <ul>
 *   <li>{@link HttpSessionListener} … セッションが<b>できた / 消えた</b></li>
 *   <li>{@link HttpSessionAttributeListener} … セッションに値が<b>入った / 変わった / 消えた</b></li>
 * </ul>
 *
 * <h2>いつ呼ばれるか</h2>
 * <table border="1">
 *   <caption>呼ばれるタイミング</caption>
 *   <tr><th>メソッド</th><th>呼ばれるとき</th></tr>
 *   <tr><td>{@code sessionCreated}</td>
 *       <td>{@code request.getSession()} で新しいセッションが作られたとき</td></tr>
 *   <tr><td>{@code sessionDestroyed}</td>
 *       <td>{@code session.invalidate()} のとき、またはタイムアウトでコンテナが捨てたとき</td></tr>
 *   <tr><td>{@code attributeAdded} / {@code attributeReplaced} / {@code attributeRemoved}</td>
 *       <td>{@code setAttribute} / {@code removeAttribute} のとき
 *           (同じ名前に入れ直すと replaced、{@code invalidate} でも removed が呼ばれます)</td></tr>
 * </table>
 *
 * <p>セッションの数を数える、ログインしている人数を出す、切れたセッションの後始末をする、
 * といった用途に使います。</p>
 *
 * <h2>記録に「中身」を書かない</h2>
 * <p>このリスナーは<b>アプリ全体</b>に掛かるので、他のサンプル
 * (ログインや CSRF 対策) がセッションに置いた値も通ります。
 * そのため記録に残すのは名前と型だけにして、値そのものとセッション ID は伏せています。
 * ログや画面に認証情報をそのまま書かないのは、実際のアプリでも同じです。</p>
 */
@WebListener
public class SessionLifecycleListener implements HttpSessionListener, HttpSessionAttributeListener {

    /** 画面の記録に出す名前。 */
    static final String NAME = "SessionLifecycleListener";

    @Override
    public void sessionCreated(HttpSessionEvent event) {
        HttpSession session = event.getSession();
        ListenerEventLog.sessionCreated();
        ListenerEventLog.add(ListenerEvent.Kind.SESSION, NAME, "sessionCreated",
                "セッション " + mask(session.getId()) + " ができました"
                        + " (無操作で " + session.getMaxInactiveInterval() + " 秒で切れます)");
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent event) {
        ListenerEventLog.sessionDestroyed();
        ListenerEventLog.add(ListenerEvent.Kind.SESSION, NAME, "sessionDestroyed",
                "セッション " + mask(event.getSession().getId()) + " が消えました"
                        + " (invalidate かタイムアウト)");
    }

    @Override
    public void attributeAdded(HttpSessionBindingEvent event) {
        ListenerEventLog.add(ListenerEvent.Kind.ATTRIBUTE, NAME, "attributeAdded",
                "セッションに " + event.getName() + " が入りました" + typeOf(event.getValue()));
    }

    @Override
    public void attributeReplaced(HttpSessionBindingEvent event) {
        // event.getValue() は「置き換えられる前」の値です (新しい値ではありません)
        ListenerEventLog.add(ListenerEvent.Kind.ATTRIBUTE, NAME, "attributeReplaced",
                "セッションの " + event.getName() + " が入れ替わりました");
    }

    @Override
    public void attributeRemoved(HttpSessionBindingEvent event) {
        ListenerEventLog.add(ListenerEvent.Kind.ATTRIBUTE, NAME, "attributeRemoved",
                "セッションから " + event.getName() + " が消えました");
    }

    /**
     * セッション ID を伏せる (先頭だけ残す)。
     *
     * <p>セッション ID はログインの鍵そのものです。画面にもログにも、
     * そのままの形では出しません。</p>
     */
    static String mask(String sessionId) {
        if (sessionId == null || sessionId.length() <= 6) {
            return "******";
        }
        return sessionId.substring(0, 6) + "…";
    }

    /** 値の「型だけ」を返す。中身は書かない。 */
    static String typeOf(Object value) {
        return value == null ? "" : " (" + value.getClass().getSimpleName() + ")";
    }
}
