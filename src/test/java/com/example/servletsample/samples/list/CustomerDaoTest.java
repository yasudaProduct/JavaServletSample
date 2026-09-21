package com.example.servletsample.samples.list;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * 取引先マスタ ({@link CustomerDao}) のテスト。
 *
 * <p>組み込みデータベース (H2) をメモリ上で動かすため、
 * Tomcat を起動しなくてもそのまま実行できます。</p>
 *
 * <p>確かめたいのは<b>楽観ロックが本当に効いているか</b>です。
 * 「動いているつもりで、実は version を見ていなかった」は
 * 画面を触っているだけでは気付けません。</p>
 */
class CustomerDaoTest {

    private final CustomerDao dao = new CustomerDao();

    @BeforeEach
    void reset() {
        // 他のテストの影響を受けないよう、毎回初期状態に戻す
        dao.reset();
    }

    /** 1 件目の取引先。 */
    private Customer first() {
        return dao.findAll().get(0);
    }

    /** 画面から送られてきたことにして、フォームを組み立てる。 */
    private static CustomerForm form(Map<String, String> parameters) {
        HttpServletRequest request = (HttpServletRequest) Proxy.newProxyInstance(
                CustomerDaoTest.class.getClassLoader(),
                new Class<?>[] {HttpServletRequest.class},
                (proxy, method, args) -> {
                    if ("getParameter".equals(method.getName())) {
                        return parameters.get((String) args[0]);
                    }
                    return null;
                });
        return CustomerForm.from(request);
    }

    /** 既存の取引先を元に、一部だけ差し替えたフォームを作る。 */
    private static CustomerForm formOf(Customer customer, String key, String value) {
        Map<String, String> parameters = new HashMap<>();
        parameters.put("id", String.valueOf(customer.getId()));
        parameters.put("code", customer.getCode());
        parameters.put("name", customer.getName());
        parameters.put("contact", customer.getContact());
        parameters.put("email", customer.getEmail());
        parameters.put("version", String.valueOf(customer.getVersion()));
        parameters.put(key, value);
        return form(parameters);
    }

    @Test
    @DisplayName("初期データが入っている")
    void hasSeedData() {
        assertEquals(4, dao.findAll().size());
        assertEquals(1, first().getVersion(), "初期状態の version は 1");
    }

    @Nested
    @DisplayName("楽観ロック")
    class OptimisticLock {

        @Test
        @DisplayName("開いたときの version と一致すれば更新できる")
        void updatesWhenVersionMatches() {
            Customer before = first();

            int updated = dao.update(formOf(before, "name", "新しい会社名"));

            assertEquals(1, updated, "1 行更新できるはず");
            Customer after = dao.findById(before.getId()).orElseThrow();
            assertEquals("新しい会社名", after.getName());
            assertEquals(before.getVersion() + 1, after.getVersion(), "version が 1 つ進む");
        }

        @Test
        @DisplayName("誰かが先に更新していたら 0 件 (更新されない)")
        void rejectsStaleVersion() {
            Customer opened = first();

            // 別の人が先に更新した
            dao.simulateConcurrentUpdate(opened.getId());

            // こちらは画面を開いたときの version のまま送る
            int updated = dao.update(formOf(opened, "name", "あとから保存した名前"));

            assertEquals(0, updated, "競合しているので更新できないはず");

            Customer current = dao.findById(opened.getId()).orElseThrow();
            assertNotEquals("あとから保存した名前", current.getName(),
                    "相手の変更を上書きしてはいけない");
            assertEquals(opened.getVersion() + 1, current.getVersion(),
                    "version は相手の更新のぶんだけ進んでいる");
        }

        @Test
        @DisplayName("version が読めない値でも素通りしない")
        void rejectsBrokenVersion() {
            Customer opened = first();
            assertEquals(0, dao.update(formOf(opened, "version", "")));
            assertEquals(0, dao.update(formOf(opened, "version", "abc")));
        }

        @Test
        @DisplayName("2 回続けて更新すると、2 回目は競合する")
        void secondUpdateWithSameVersionFails() {
            Customer opened = first();

            assertEquals(1, dao.update(formOf(opened, "name", "1 回目")));
            // 同じ version をもう一度使う = 画面を開き直していない状態
            assertEquals(0, dao.update(formOf(opened, "name", "2 回目")));
        }
    }

    @Nested
    @DisplayName("削除")
    class Delete {

        @Test
        @DisplayName("version が一致すれば削除できる")
        void deletesWhenVersionMatches() {
            Customer target = first();

            assertEquals(1, dao.delete(target.getId(), target.getVersion()));
            assertTrue(dao.findById(target.getId()).isEmpty());
        }

        @Test
        @DisplayName("誰かが先に更新していたら削除しない")
        void rejectsStaleVersionOnDelete() {
            Customer target = first();
            dao.simulateConcurrentUpdate(target.getId());

            assertEquals(0, dao.delete(target.getId(), target.getVersion()));
            assertTrue(dao.findById(target.getId()).isPresent(), "消えていないはず");
        }

        @Test
        @DisplayName("存在しない ID なら 0 件")
        void deletingMissingRowReturnsZero() {
            assertEquals(0, dao.delete(999_999L, 1));
        }
    }

    @Nested
    @DisplayName("登録と一意性")
    class Insert {

        @Test
        @DisplayName("登録すると ID が採番され、version は 1 から始まる")
        void insertsWithVersionOne() {
            Map<String, String> parameters = new HashMap<>();
            parameters.put("code", "ZZ-999");
            parameters.put("name", "テスト商事");
            parameters.put("contact", "試験 太郎");
            parameters.put("email", "test@example.com");

            long id = dao.insert(form(parameters));

            assertTrue(id > 0, "ID が採番されるはず");
            Customer created = dao.findById(id).orElseThrow();
            assertEquals("ZZ-999", created.getCode());
            assertEquals(1, created.getVersion());
        }

        @Test
        @DisplayName("既に使われているコードは見つけられる")
        void detectsDuplicatedCode() {
            Customer existing = first();

            assertTrue(dao.existsCode(existing.getCode(), 0), "新規登録では重複とみなす");
            assertFalse(dao.existsCode(existing.getCode(), existing.getId()),
                    "自分自身は重複に数えない");
            assertFalse(dao.existsCode("ZZ-000", 0));
        }
    }
}
