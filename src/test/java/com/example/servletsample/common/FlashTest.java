package com.example.servletsample.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * リダイレクトをまたぐメッセージ ({@link Flash}) のテスト。
 *
 * <p>「1 回表示したら消える」ことがこの仕組みの肝なので、そこを重点的に確かめます。</p>
 */
class FlashTest {

    @Test
    @DisplayName("預けたメッセージを次の表示で受け取れる")
    void passesMessageToNextRequest() {
        FakeRequest post = new FakeRequest();
        Flash.set(post.request, "success", "登録が完了しました", "受付番号は A-0001 です。");

        // リダイレクト後 : リクエストは別物だが、セッションは引き継がれる
        FakeRequest get = post.nextRequestInSameSession();
        Flash.consume(get.request);

        Flash.Message message = (Flash.Message) get.attributes.get(Flash.ATTRIBUTE_NAME);
        assertNotNull(message, "request スコープに移されていません");
        assertEquals("success", message.getVariant());
        assertEquals("登録が完了しました", message.getTitle());
        assertEquals("受付番号は A-0001 です。", message.getText());
        assertEquals("", message.getNextUrl(), "移動先を指定していなければ空文字");
    }

    @Test
    @DisplayName("一度受け取ったら消える（再読み込みしても出ない）")
    void consumesOnlyOnce() {
        FakeRequest post = new FakeRequest();
        Flash.set(post.request, "success", "登録が完了しました", "受付番号は A-0001 です。");

        FakeRequest first = post.nextRequestInSameSession();
        Flash.consume(first.request);
        assertNotNull(first.attributes.get(Flash.ATTRIBUTE_NAME));

        FakeRequest second = post.nextRequestInSameSession();
        Flash.consume(second.request);
        assertNull(second.attributes.get(Flash.ATTRIBUTE_NAME), "2 回目は出てはいけません");
    }

    @Test
    @DisplayName("移動先を預けると一緒に受け取れる")
    void carriesNextUrl() {
        FakeRequest post = new FakeRequest();
        Flash.set(post.request, "success", "登録が完了しました", "受付番号は A-0001 です。",
                "/samples/design/modal-dialog/entries");

        FakeRequest get = post.nextRequestInSameSession();
        Flash.consume(get.request);

        Flash.Message message = (Flash.Message) get.attributes.get(Flash.ATTRIBUTE_NAME);
        assertEquals("/samples/design/modal-dialog/entries", message.getNextUrl());
    }

    @Test
    @DisplayName("メッセージが無いときは何も起きない")
    void doesNothingWithoutMessage() {
        FakeRequest request = new FakeRequest();
        Flash.consume(request.request);
        assertTrue(request.attributes.isEmpty());
    }

    // ------------------------------------------------------------------
    // テスト用の最小限の HttpServletRequest / HttpSession
    // (モックライブラリを足さずに済ませるため、動的プロキシで必要なメソッドだけ実装する)
    // ------------------------------------------------------------------
    private static final class FakeRequest {

        private final Map<String, Object> session;
        private final Map<String, Object> attributes = new HashMap<>();
        private final HttpServletRequest request;

        FakeRequest() {
            this(new HashMap<>());
        }

        private FakeRequest(Map<String, Object> session) {
            this.session = session;
            this.request = proxy(HttpServletRequest.class, (target, method, args) -> {
                switch (method.getName()) {
                    case "getSession":
                        // getSession(false) でもセッションはある前提にする
                        return sessionProxy();
                    case "setAttribute":
                        attributes.put((String) args[0], args[1]);
                        return null;
                    case "getAttribute":
                        return attributes.get((String) args[0]);
                    default:
                        return null;
                }
            });
        }

        /** リダイレクト後の「別のリクエスト」。セッションだけを引き継ぐ。 */
        FakeRequest nextRequestInSameSession() {
            return new FakeRequest(session);
        }

        private HttpSession sessionProxy() {
            return proxy(HttpSession.class, (target, method, args) -> {
                switch (method.getName()) {
                    case "setAttribute":
                        session.put((String) args[0], args[1]);
                        return null;
                    case "getAttribute":
                        return session.get((String) args[0]);
                    case "removeAttribute":
                        session.remove((String) args[0]);
                        return null;
                    default:
                        return null;
                }
            });
        }

        @SuppressWarnings("unchecked")
        private static <T> T proxy(Class<T> type, InvocationHandler handler) {
            return (T) Proxy.newProxyInstance(FlashTest.class.getClassLoader(),
                    new Class<?>[]{type}, handler);
        }
    }
}
