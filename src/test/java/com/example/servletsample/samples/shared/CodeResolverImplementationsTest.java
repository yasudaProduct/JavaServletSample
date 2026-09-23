package com.example.servletsample.samples.shared;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import com.example.servletsample.shared.CodeResolver;
import com.example.servletsample.shared.ResolverRegistry;

/**
 * アプリ側に置いた {@link CodeResolver} の実装のテスト。
 *
 * <p>「社員コードは E + 4 桁」という<b>業務の決めごと</b>がアプリ側にあることを、
 * テストの置き場所でも示しています。共通ライブラリ側のテスト
 * ({@code shared/src/test/java}) には、この手の判定は 1 つも出てきません。</p>
 */
class CodeResolverImplementationsTest {

    @Nested
    @DisplayName("社員コード")
    class Employee {

        private final EmployeeCodeResolver resolver = new EmployeeCodeResolver();

        @Test
        @DisplayName("E + 4 桁だけを受け付ける")
        void acceptsForm() {
            assertTrue(resolver.accepts("E1001"));
            assertFalse(resolver.accepts("E100"));
            assertFalse(resolver.accepts("E10011"));
            assertFalse(resolver.accepts("P001"));
            assertFalse(resolver.accepts(null));
        }

        @Test
        @DisplayName("マスタにあるコードは氏名を返す")
        void resolvesRegistered() {
            assertEquals("山田 太郎", resolver.resolve("E1001"));
        }

        @Test
        @DisplayName("形は合っていてもマスタに無ければ null")
        void unknownCode() {
            assertNull(resolver.resolve("E9999"));
        }

        @Test
        @DisplayName("形が違えば引き当てない")
        void wrongForm() {
            assertNull(resolver.resolve("P001"));
        }
    }

    @Nested
    @DisplayName("商品コード")
    class Product {

        private final ProductCodeResolver resolver = new ProductCodeResolver();

        @Test
        @DisplayName("P + 3 桁だけを受け付ける")
        void acceptsForm() {
            assertTrue(resolver.accepts("P001"));
            assertFalse(resolver.accepts("P0011"));
            assertFalse(resolver.accepts("E1001"));
        }

        @Test
        @DisplayName("マスタにあるコードは商品名を返す")
        void resolvesRegistered() {
            assertEquals("A4 コピー用紙 (500 枚)", resolver.resolve("P001"));
        }

        @Test
        @DisplayName("形は合っていてもマスタに無ければ null")
        void unknownCode() {
            assertNull(resolver.resolve("P999"));
        }
    }

    @Nested
    @DisplayName("ServiceLoader での登録")
    class Registration {

        @Test
        @DisplayName("META-INF/services から 2 件の実装が見つかる")
        void findsImplementations() {
            List<CodeResolver> resolvers = ResolverRegistry.all();
            assertEquals(2, resolvers.size(),
                    "META-INF/services の登録ファイルが WEB-INF/classes に入っていない可能性があります");
        }

        @Test
        @DisplayName("名前で探せる")
        void findsByName() {
            assertTrue(ResolverRegistry.byName("社員コード").isPresent());
            assertTrue(ResolverRegistry.byName("商品コード").isPresent());
            assertTrue(ResolverRegistry.byName("存在しない").isEmpty());
        }

        @Test
        @DisplayName("コードの形から実装が選ばれる")
        void choosesByForm() {
            assertEquals("社員コード", ResolverRegistry.forCode("E1001").orElseThrow().name());
            assertEquals("商品コード", ResolverRegistry.forCode("P001").orElseThrow().name());
            assertTrue(ResolverRegistry.forCode("X999").isEmpty());
        }

        @Test
        @DisplayName("全角や空白付きでも、共通側が表記を揃えてから選ぶ")
        void normalizesBeforeChoosing() {
            assertEquals("社員コード",
                    ResolverRegistry.forCode("  Ｅ１００１  ").orElseThrow().name());
        }

        @Test
        @DisplayName("空の入力では実装が選ばれない")
        void emptyInput() {
            assertTrue(ResolverRegistry.forCode(null).isEmpty());
            assertTrue(ResolverRegistry.forCode("   ").isEmpty());
        }
    }
}
