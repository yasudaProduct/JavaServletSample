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
        String binaryName = type.getName();
        int nested = binaryName.indexOf('$');
        if (nested >= 0) {
            binaryName = binaryName.substring(0, nested);
        }
        String path = JAVA_ROOT + "/" + binaryName.replace('.', '/') + ".java";
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
