package com.example.servletsample.shared;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@link SequenceCounter} のテスト。
 *
 * <p><b>1 台構成では正しく動く</b>ことを確かめています。これが厄介なところです。
 * テストは通り、開発中も動き、本番でも 1 台なら動きます。
 * 2 台に増やした日から番号が重複し始めます。</p>
 *
 * <p>つまり<b>「単体テストが通ること」は、複数サーバー構成で動く保証にはなりません</b>。
 * 状態を持つ処理は、テストではなく<b>置き場所</b>で担保します
 * (実演は samples/shared/shared-state のサンプル)。</p>
 */
class SequenceCounterTest {

    @BeforeEach
    void reset() {
        // static を持つクラスのテストは、前のテストの値を引きずります。
        // これもまた「状態を持つものは扱いが面倒」という話の一部です。
        SequenceCounter.reset();
    }

    @Test
    @DisplayName("1 から順に発行する")
    void issuesInOrder() {
        assertEquals(1, SequenceCounter.next());
        assertEquals(2, SequenceCounter.next());
        assertEquals(3, SequenceCounter.next());
    }

    @Test
    @DisplayName("current は発行せずに現在値を返す")
    void currentDoesNotIssue() {
        SequenceCounter.next();
        assertEquals(1, SequenceCounter.current());
        assertEquals(1, SequenceCounter.current());
    }

    @Test
    @DisplayName("reset で 0 に戻る")
    void resets() {
        SequenceCounter.next();
        SequenceCounter.reset();
        assertEquals(0, SequenceCounter.current());
        assertEquals(1, SequenceCounter.next());
    }
}
