package com.example.servletsample.shared;

import java.security.CodeSource;
import java.security.ProtectionDomain;

/**
 * 「このクラスは、どのファイルから読み込まれたか」を表す。
 *
 * <p>複数サーバー構成の話で一番誤解されるのが
 * <b>「共通 JAR は共有されている」</b>という思い込みです。
 * 実際には共有されておらず、<b>それぞれの WAR の中にコピーが入っている</b>だけです。
 * それを目で確かめられるようにするのがこのクラスです。</p>
 *
 * <h2>仕組み</h2>
 * <p>{@link Class#getProtectionDomain()} → {@link CodeSource} で
 * 「そのクラスの出どころ (JAR やディレクトリの URL)」が分かります。
 * あわせて {@link Class#getClassLoader()} を見ると、
 * <b>誰が読み込んだか</b>が分かります。Tomcat では</p>
 * <ul>
 *   <li>アプリの中のクラス … アプリごとのクラスローダ ({@code ParallelWebappClassLoader})</li>
 *   <li>Tomcat 自身のクラス … 共有のクラスローダ</li>
 * </ul>
 * <p>と分かれており、これがそのまま「どこまでが共有されるか」の境界になります。</p>
 */
public final class ClassOrigin {

    /** 読み込み元の種類。 */
    public enum Place {

        /** WAR の {@code WEB-INF/lib} に同梱された JAR から。 */
        BUNDLED_JAR("WAR 同梱の JAR", "WEB-INF/lib/ の JAR。WAR ごとにコピーが入る"),

        /** WAR の {@code WEB-INF/classes} から (アプリ本体)。 */
        WEBAPP_CLASSES("アプリ本体", "WEB-INF/classes/。そのアプリだけのもの"),

        /** Tomcat 側 (共有クラスローダ、または JDK)。 */
        CONTAINER("Tomcat / JDK 側", "アプリの外。全アプリで共有される"),

        /** 判定できなかった。 */
        UNKNOWN("不明", "読み込み元を取得できなかった");

        private final String label;
        private final String description;

        Place(String label, String description) {
            this.label = label;
            this.description = description;
        }

        public String getLabel() {
            return label;
        }

        public String getDescription() {
            return description;
        }
    }

    private final String className;
    private final String simpleName;
    private final String codeSource;
    private final String classLoader;
    private final Place place;

    private ClassOrigin(String className, String simpleName, String codeSource,
            String classLoader, Place place) {
        this.className = className;
        this.simpleName = simpleName;
        this.codeSource = codeSource;
        this.classLoader = classLoader;
        this.place = place;
    }

    /** そのクラスの読み込み元を調べる。 */
    public static ClassOrigin of(Class<?> type) {
        String codeSource = readCodeSource(type);
        return new ClassOrigin(
                type.getName(),
                type.getSimpleName(),
                codeSource,
                readClassLoader(type),
                judge(codeSource, type.getClassLoader()));
    }

    /**
     * 出どころの URL を読む。
     *
     * <p>JDK の中のクラス ({@code java.lang.String} など) は
     * {@code getProtectionDomain()} が {@code CodeSource} を持たないため、
     * {@code null} が返ります。落ちないように受け止めています。</p>
     */
    private static String readCodeSource(Class<?> type) {
        try {
            ProtectionDomain domain = type.getProtectionDomain();
            if (domain == null) {
                return null;
            }
            CodeSource source = domain.getCodeSource();
            if (source == null || source.getLocation() == null) {
                return null;
            }
            return source.getLocation().toString();
        } catch (SecurityException e) {
            // セキュリティマネージャが有効な環境では読めないことがある
            return null;
        }
    }

    /**
     * 読み込んだクラスローダの名前を読む。
     *
     * <p>{@code null} が返るのは<b>ブートストラップクラスローダ</b>が読んだ場合で、
     * {@code java.*} のクラスがこれに当たります。</p>
     */
    private static String readClassLoader(Class<?> type) {
        ClassLoader loader = type.getClassLoader();
        if (loader == null) {
            return "ブートストラップ (JDK 本体)";
        }
        return loader.getClass().getSimpleName() + "@"
                + Integer.toHexString(System.identityHashCode(loader));
    }

    private static Place judge(String codeSource, ClassLoader loader) {
        if (codeSource == null) {
            return loader == null ? Place.CONTAINER : Place.UNKNOWN;
        }
        if (codeSource.contains("/WEB-INF/lib/")) {
            return Place.BUNDLED_JAR;
        }
        if (codeSource.contains("/WEB-INF/classes")) {
            return Place.WEBAPP_CLASSES;
        }
        return Place.CONTAINER;
    }

    /** 完全修飾クラス名。 */
    public String getClassName() {
        return className;
    }

    /** パッケージを除いたクラス名。 */
    public String getSimpleName() {
        return simpleName;
    }

    /** 読み込み元の URL。取得できなければ {@code null}。 */
    public String getCodeSource() {
        return codeSource;
    }

    /**
     * 読み込み元の短い表示名 (画面に出すとき URL は長すぎるため)。
     *
     * <p>サーバー上の絶対パスをそのまま画面に出さないよう、
     * {@code WEB-INF/} 以降か、ファイル名だけに切り詰めます。</p>
     */
    public String getCodeSourceName() {
        if (codeSource == null) {
            return "(取得できません)";
        }
        // WAR の中なら WEB-INF/ から先だけ見せる (絶対パスを画面に出さない)
        int webInf = codeSource.indexOf("/WEB-INF/");
        if (webInf >= 0) {
            return codeSource.substring(webInf + 1);
        }
        // ディレクトリ (末尾が /) なら、最後のフォルダ名だけ
        String path = codeSource.endsWith("/")
                ? codeSource.substring(0, codeSource.length() - 1)
                : codeSource;
        int lastSlash = path.lastIndexOf('/');
        String name = lastSlash < 0 ? path : path.substring(lastSlash + 1);
        return codeSource.endsWith("/") ? name + "/" : name;
    }

    /** 読み込んだクラスローダ。 */
    public String getClassLoader() {
        return classLoader;
    }

    /** 読み込み元の種類。 */
    public Place getPlace() {
        return place;
    }
}
