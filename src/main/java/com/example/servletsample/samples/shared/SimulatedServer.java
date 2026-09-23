package com.example.servletsample.samples.shared;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.URL;
import java.net.URLClassLoader;

import com.example.servletsample.shared.SequenceCounter;

/**
 * 【サンプル】「もう 1 台のサーバー」を 1 つの JVM の中で模擬する仕掛け。
 *
 * <p>複数サーバー構成でいちばん多い事故が「{@code static} が共有されていると思っていた」です。
 * それを口で説明するより見せたいので、
 * <b>同じ共通 JAR を別のクラスローダでもう一度読み込みます</b>。</p>
 *
 * <h2>なぜこれで「別のサーバー」になるのか</h2>
 * <p>Java のクラスの同一性は<b>「完全修飾名」だけでなく「どのクラスローダが読んだか」</b>
 * との組で決まります。同じ {@code SequenceCounter} でも、別のクラスローダが読めば
 * 別のクラスとして扱われ、{@code static} フィールドもそれぞれ別に確保されます。</p>
 *
 * <p>サーバーが 2 台あるときに起きているのは、まさにこれです
 * (そちらは JVM が 2 つなので、もっと徹底的に別物です)。</p>
 *
 * <h2>親クラスローダを null にしている理由</h2>
 * <p>{@code new URLClassLoader(urls, null)} と親を {@code null} にすると、
 * 親に委譲せず<b>自分で JAR から読み込みます</b>。
 * 親をアプリのクラスローダにしてしまうと、親が既に持っている
 * {@code SequenceCounter} が返ってきてしまい、別物になりません。</p>
 *
 * <p>その代わり、この方法で読めるのは {@code java.*} だけになります。だから
 * {@link SequenceCounter} は JDK 以外に依存しない作りにしてあります。</p>
 *
 * <h2>閉じ忘れに注意</h2>
 * <p>{@link URLClassLoader} は開いた JAR を掴んだままになるので、
 * <b>アプリの停止時に必ず閉じます</b> ({@link #close()})。
 * 閉じ忘れると、アプリを入れ替えても古いクラスローダがメモリに居座ります
 * (Tomcat のクラスローダリークと同じ話です)。
 * 呼び出し側は {@code SharedStateServlet.destroy()} で閉じています。</p>
 */
public final class SimulatedServer implements AutoCloseable {

    private final String name;
    private final URLClassLoader loader;
    private final Class<?> counterType;
    private final Method nextMethod;
    private final Method currentMethod;
    private final Method resetMethod;

    private SimulatedServer(String name, URLClassLoader loader, Class<?> counterType)
            throws NoSuchMethodException {
        this.name = name;
        this.loader = loader;
        this.counterType = counterType;
        this.nextMethod = counterType.getMethod("next");
        this.currentMethod = counterType.getMethod("current");
        this.resetMethod = counterType.getMethod("reset");
    }

    /**
     * 共通 JAR を読み直して「もう 1 台」を作る。
     *
     * @param name     画面に出す名前
     * @param sharedJar 共通 JAR の場所。{@link #sharedJarLocation()} で取れる
     */
    public static SimulatedServer of(String name, URL sharedJar) throws IOException, ReflectiveOperationException {
        URLClassLoader loader = new URLClassLoader(new URL[]{sharedJar}, null);
        try {
            Class<?> counterType = loader.loadClass(SequenceCounter.class.getName());
            return new SimulatedServer(name, loader, counterType);
        } catch (ReflectiveOperationException | RuntimeException e) {
            // 途中で失敗したらクラスローダを閉じてから投げ直す (握ったままにしない)
            loader.close();
            throw e;
        }
    }

    /**
     * 共通 JAR が置かれている場所を調べる。
     *
     * <p>Tomcat で動いていれば {@code .../WEB-INF/lib/servlet-sample-shared-1.0.0.jar} が返ります。
     * これがそのまま「共通処理は共有されているのではなく WAR に同梱されている」証拠になります。</p>
     *
     * @return 見つからなければ {@code null}
     */
    public static URL sharedJarLocation() {
        if (SequenceCounter.class.getProtectionDomain() == null
                || SequenceCounter.class.getProtectionDomain().getCodeSource() == null) {
            return null;
        }
        return SequenceCounter.class.getProtectionDomain().getCodeSource().getLocation();
    }

    /** 画面に出す名前。 */
    public String getName() {
        return name;
    }

    /** このサーバーが読み込んだクラスの、アプリ側のものとの同一性。常に false になる。 */
    public boolean isSameClassAsApp() {
        return counterType == SequenceCounter.class;
    }

    /** 読み込んだクラスローダの表示名。 */
    public String getClassLoaderName() {
        return loader.getClass().getSimpleName() + "@"
                + Integer.toHexString(System.identityHashCode(loader));
    }

    /** このサーバーで採番する。 */
    public int next() {
        return invoke(nextMethod);
    }

    /** このサーバーのいまの値。 */
    public int current() {
        return invoke(currentMethod);
    }

    /** このサーバーのカウンタを 0 に戻す。 */
    public void reset() {
        invoke(resetMethod);
    }

    private int invoke(Method method) {
        try {
            Object result = method.invoke(null);
            return result instanceof Integer ? (Integer) result : 0;
        } catch (IllegalAccessException | InvocationTargetException e) {
            // サンプルの都合で落ちても画面は出したいので、実行時例外に包んで上に投げる
            throw new IllegalStateException(
                    name + " の " + method.getName() + "() の呼び出しに失敗しました", e);
        }
    }

    @Override
    public void close() throws IOException {
        loader.close();
    }
}
