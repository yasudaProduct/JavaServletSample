package com.example.servletsample.shared;

import java.util.concurrent.atomic.AtomicInteger;

/**
 * <b>共通 JAR に置いてはいけないものの見本</b>。番号を 1 つずつ増やすだけのカウンタです。
 *
 * <p>1 台構成では正しく動きます。{@link AtomicInteger} なのでスレッドセーフですし、
 * 同時アクセスで番号が重複することもありません。
 * <b>サーバーが 1 台である限りは</b>何の問題もありません。</p>
 *
 * <h2>2 台にすると壊れる</h2>
 * <p>サーバーが 2 台になると JVM も 2 つになります。
 * このクラスは<b>それぞれの JVM に別々に読み込まれ、{@code static} も別々に存在します</b>。
 * 同じ JAR を配っても、同じ版を使っても、状態は 1 つになりません。</p>
 *
 * <pre>
 *   サーバー A : 1, 2, 3 ...
 *   サーバー B : 1, 2, 3 ...   ← 同じ番号が発行される
 * </pre>
 *
 * <p>「受付番号」「伝票番号」をこの形で作っていると、
 * 2 台構成にした日から番号が重複し始めます。しかも
 * <b>ロードバランサの振り分け次第で再現しない</b>ため、原因を掴みにくい類の事故です。</p>
 *
 * <h2>正しい置き場所</h2>
 * <p>採番は DB に寄せます。シーケンス、{@code IDENTITY}、または採番テーブルです。
 * 2 台から同時に来ても 1 つの連番になるのは、そこが 1 箇所だからです。
 * 実際に並べて比べられるようにしたのが
 * {@code samples/shared/SharedStateServlet} のサンプルです。</p>
 *
 * <h2>このクラスが java.* にしか依存していない理由</h2>
 * <p>サンプルでは「2 台あると static が別になる」ことを 1 台の Tomcat で見せるため、
 * このクラスを {@link java.net.URLClassLoader} で<b>もう一度読み込みます</b>。
 * そのとき親クラスローダを {@code null} にするので、
 * 読めるのは {@code java.*} だけです。ここに {@code javax.servlet} などを
 * 参照するコードを足すと、その実演が動かなくなります。</p>
 */
public final class SequenceCounter {

    /** アプリ全体で 1 つ……のつもりのカウンタ。JVM ごとに 1 つになる。 */
    private static final AtomicInteger COUNTER = new AtomicInteger();

    private SequenceCounter() {
    }

    /** 次の番号を発行する。 */
    public static int next() {
        return COUNTER.incrementAndGet();
    }

    /** いまの値を見る (発行はしない)。 */
    public static int current() {
        return COUNTER.get();
    }

    /** 0 に戻す (サンプルを繰り返し試せるようにするため)。 */
    public static void reset() {
        COUNTER.set(0);
    }
}
