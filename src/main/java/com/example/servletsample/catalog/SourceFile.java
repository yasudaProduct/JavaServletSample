package com.example.servletsample.catalog;

import java.util.Objects;

/**
 * サンプルページに表示するソースファイル 1 件。
 *
 * <p>パスは ServletContext からの相対パス (例: {@code /WEB-INF/views/samples/basic/hello-world.jsp})
 * で保持します。実際の読み込みは
 * {@link com.example.servletsample.common.SourceLoader} が行います。</p>
 */
public final class SourceFile {

    /** Java のソースを WAR に取り込んでいる場所 (pom.xml の maven-war-plugin 参照)。 */
    public static final String JAVA_ROOT = "/WEB-INF/sources/java";

    /**
     * 共通ライブラリ (shared プロジェクト) のソースを取り込んでいる場所。
     *
     * <p>アプリ本体と分けているのは、<b>別プロジェクトであることを明示するため</b>です。
     * WAR の中でも {@code WEB-INF/classes} ではなく
     * {@code WEB-INF/lib/servlet-sample-shared-x.y.z.jar} に入っているので、
     * ソースの置き場所も分けています。</p>
     */
    public static final String SHARED_ROOT = "/WEB-INF/sources/shared";

    /** テストコード (src/test/java) を WAR に取り込んでいる場所。 */
    public static final String JAVA_TEST_ROOT = "/WEB-INF/sources/test";

    /**
     * ビルド設定 (pom.xml / build.xml / Eclipse の設定) を取り込んでいる場所。
     *
     * <p>「共通処理を JAR に切り出す」のサンプルで、Eclipse / Ant / Maven の 3 つが
     * 同じことをどう書いているかを画面に並べるために使います。
     * リポジトリのルート付近に散っているファイルをここに集めています。</p>
     */
    public static final String BUILD_ROOT = "/WEB-INF/sources/build";

    private final String path;
    private final String label;
    private final String language;

    private SourceFile(String path, String label, String language) {
        this.path = Objects.requireNonNull(path, "path");
        this.label = (label == null || label.isEmpty()) ? fileNameOf(path) : label;
        this.language = language;
    }

    /**
     * Java のクラスからソースファイルを指定する。
     * <p>{@code SourceFile.of(HelloWorldServlet.class)} のように書けるので、
     * クラス名を変更してもカタログ側の修正漏れが起きません。</p>
     */
    public static SourceFile of(Class<?> type) {
        return javaSource(JAVA_ROOT, type);
    }

    /**
     * 共通ライブラリ (shared プロジェクト) のクラスからソースファイルを指定する。
     * <p>{@code SourceFile.shared(SharedLibrary.class)} のように書きます。</p>
     */
    public static SourceFile shared(Class<?> type) {
        return javaSource(SHARED_ROOT, type);
    }

    private static SourceFile javaSource(String root, Class<?> type) {
        String binaryName = type.getName();
        int nested = binaryName.indexOf('$');
        if (nested >= 0) {
            binaryName = binaryName.substring(0, nested);
        }
        String path = root + "/" + binaryName.replace('.', '/') + ".java";
        return new SourceFile(path, null, "java");
    }

    /**
     * テストコード (src/test/java) を完全修飾クラス名で指定する。
     *
     * <p>テストクラスは本体のクラスパスに載っていない (コンパイル対象が別) ため、
     * {@link #of(Class)} のようにクラスリテラルでは書けません。文字列で指定しますが、
     * 綴りを間違えると画面に出ないだけで気付きにくいので、
     * {@code SampleCatalogTest} がファイルの実在を検査しています。</p>
     *
     * <pre>{@code SourceFile.test("com.example.servletsample.samples.test.OrderPricingTest")}</pre>
     */
    public static SourceFile test(String binaryName) {
        String path = JAVA_TEST_ROOT + "/" + binaryName.replace('.', '/') + ".java";
        return new SourceFile(path, null, "java");
    }

    /** JSP / タグファイルを指定する。 */
    public static SourceFile jsp(String path) {
        // highlight.js に jsp 用の定義は無いので xml として色付けする
        return new SourceFile(path, null, "xml");
    }

    /** CSS を指定する。 */
    public static SourceFile css(String path) {
        return new SourceFile(path, null, "css");
    }

    /** JavaScript を指定する。 */
    public static SourceFile js(String path) {
        return new SourceFile(path, null, "javascript");
    }

    /** 任意のファイルを言語を指定して追加する。 */
    public static SourceFile of(String path, String label, String language) {
        return new SourceFile(path, label, language);
    }

    /** ServletContext からの相対パス。 */
    public String getPath() {
        return path;
    }

    /** タブなどに表示するファイル名。 */
    public String getLabel() {
        return label;
    }

    /** highlight.js に渡す言語名。 */
    public String getLanguage() {
        return language;
    }

    private static String fileNameOf(String path) {
        int index = path.lastIndexOf('/');
        return index < 0 ? path : path.substring(index + 1);
    }

    @Override
    public String toString() {
        return label + " (" + path + ")";
    }
}
