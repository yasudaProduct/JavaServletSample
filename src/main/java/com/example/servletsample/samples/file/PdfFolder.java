package com.example.servletsample.samples.file;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.InvalidPathException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import javax.servlet.ServletContext;

/**
 * サーバのフォルダに置いた PDF を探す。
 *
 * <p>「ファイルとして保存されている PDF」を表示するときに、いちばん気をつけるのは
 * <b>画面から受け取ったファイル名をそのままパスにつながない</b>ことです。</p>
 *
 * <pre>{@code
 * ?name=manual.pdf          → /WEB-INF/pdf/manual.pdf      (想定どおり)
 * ?name=../web.xml          → /WEB-INF/web.xml             (フォルダの外へ出られてしまう)
 * ?name=../../conf/tomcat-users.xml ...                     (サーバの設定まで読まれる)
 * }</pre>
 *
 * <p>これを防ぐため、{@link #find} では次の 2 つを確かめています。</p>
 * <ol>
 *   <li>{@code normalize()} で {@code ..} を解決したあとも、<b>決めたフォルダの直下</b>にあるか</li>
 *   <li>拡張子が {@code .pdf} か (PDF 以外のファイルは置いてあっても返さない)</li>
 * </ol>
 *
 * <p>このサンプルでは WAR に同梱した {@code /WEB-INF/pdf} を使っていますが、
 * 実務ではサーバ上の決まったフォルダ (例: {@code /var/app/pdf}) や共有ストレージを
 * 設定ファイルで指定することが多いはずです。その場合も {@link #PdfFolder(Path)} に
 * そのパスを渡せば同じように使えます。</p>
 */
public final class PdfFolder {

    /** WAR の中での置き場所。WEB-INF の下なので、URL を直接打ち込んでも開けない。 */
    public static final String LOCATION = "/WEB-INF/pdf";

    private final Path directory;

    public PdfFolder(Path directory) {
        // 比較できるように、絶対パスにして .. を解決した形で持っておく
        this.directory = directory.toAbsolutePath().normalize();
    }

    /**
     * アプリに同梱した {@value #LOCATION} を使う。
     *
     * <p>{@code getRealPath} は「URL 上のパス」を「ディスク上のパス」に変換します。
     * WAR を展開せずに動かしている場合は実際のフォルダが無いので {@code null} が返ります
     * (Tomcat の既定では展開されるので、このサンプルでは問題になりません)。</p>
     */
    public static PdfFolder of(ServletContext context) {
        String realPath = context.getRealPath(LOCATION);
        if (realPath == null) {
            throw new IllegalStateException(LOCATION + " の場所が分かりません (WAR が展開されていません)");
        }
        return new PdfFolder(Paths.get(realPath));
    }

    /** フォルダにある PDF の一覧 (名前順)。フォルダが無ければ空。 */
    public List<Entry> list() {
        if (!Files.isDirectory(directory)) {
            return List.of();
        }
        try (Stream<Path> paths = Files.list(directory)) {
            return paths
                    .filter(Files::isRegularFile)
                    .filter(path -> isPdfName(path.getFileName().toString()))
                    .sorted()
                    .map(Entry::of)
                    .collect(Collectors.toList());
        } catch (IOException e) {
            throw new UncheckedIOException("PDF の一覧を取得できませんでした: " + directory, e);
        }
    }

    /**
     * 画面から受け取った名前で PDF を探す。
     *
     * <p>フォルダの外を指す名前 ({@code ../web.xml} など)・サブフォルダ・PDF 以外・
     * 存在しないファイルは、すべて「見つからない」扱いにします。
     * 理由を細かく返さないのは、攻撃する側にヒントを与えないためです。</p>
     */
    public Optional<Path> find(String name) {
        if (name == null || !isPdfName(name)) {
            return Optional.empty();
        }
        Path file;
        try {
            // resolve でつないでから normalize で .. を解決する
            file = directory.resolve(name).normalize();
        } catch (InvalidPathException e) {
            return Optional.empty();   // ヌル文字など、パスとして成り立たない文字が入っていた
        }
        // 解決したあとの親フォルダが、決めたフォルダそのものか
        // (../ で外に出た・a/b.pdf でサブフォルダへ潜った・絶対パスを渡された、をまとめて弾く)
        if (!directory.equals(file.getParent())) {
            return Optional.empty();
        }
        return Files.isRegularFile(file) ? Optional.of(file) : Optional.empty();
    }

    private static boolean isPdfName(String name) {
        return name.toLowerCase(Locale.ROOT).endsWith(".pdf");
    }

    /** フォルダにある PDF 1 件分 (画面の一覧に出す情報)。 */
    public static final class Entry {

        private final String name;
        private final long size;

        Entry(String name, long size) {
            this.name = name;
            this.size = size;
        }

        static Entry of(Path path) {
            try {
                return new Entry(path.getFileName().toString(), Files.size(path));
            } catch (IOException e) {
                throw new UncheckedIOException("ファイルの大きさを取得できませんでした: " + path, e);
            }
        }

        /** ファイル名。例: {@code manual.pdf} */
        public String getName() {
            return name;
        }

        /** バイト数。 */
        public long getSize() {
            return size;
        }

        /** 画面に出すサイズ。例: {@code 35.5 KB} */
        public String getSizeText() {
            return StoredFile.formatSize(size);
        }
    }
}
