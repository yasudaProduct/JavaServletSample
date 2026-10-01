package com.example.servletsample.samples.file;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Collectors;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** フォルダに置いた PDF を探す {@link PdfFolder} のテスト。 */
class PdfFolderTest {

    @TempDir
    Path root;

    /** PDF を置くフォルダ (root/pdf)。root 直下には「外にあるファイル」を置く。 */
    private Path directory;

    private PdfFolder folder;

    @BeforeEach
    void setUp() throws IOException {
        directory = Files.createDirectory(root.resolve("pdf"));
        write(directory.resolve("b.pdf"), "%PDF-b");
        write(directory.resolve("a.pdf"), "%PDF-a");
        write(directory.resolve("memo.txt"), "PDF ではない");
        write(Files.createDirectory(directory.resolve("sub")).resolve("c.pdf"), "%PDF-c");
        write(root.resolve("secret.pdf"), "%PDF-外にある");

        folder = new PdfFolder(directory);
    }

    @Test
    @DisplayName("一覧には直下の PDF だけが名前順に並ぶ")
    void listsPdfFilesInOrder() {
        List<String> names = folder.list().stream()
                .map(PdfFolder.Entry::getName)
                .collect(Collectors.toList());

        assertEquals(List.of("a.pdf", "b.pdf"), names);
        assertEquals(6, folder.list().get(0).getSize());
    }

    @Test
    @DisplayName("名前を指定すると、フォルダの中の PDF が見つかる")
    void findsPdfByName() {
        assertEquals(directory.resolve("a.pdf").toAbsolutePath().normalize(),
                folder.find("a.pdf").orElseThrow());
    }

    @Test
    @DisplayName("../ でフォルダの外を指しても見つからない (実在する PDF でも)")
    void rejectsPathTraversal() {
        assertTrue(Files.exists(root.resolve("secret.pdf")), "前提 : 外に PDF が実在する");

        assertFalse(folder.find("../secret.pdf").isPresent());
        assertFalse(folder.find("sub/../../secret.pdf").isPresent());
        assertFalse(folder.find("..\\secret.pdf").isPresent());
    }

    @Test
    @DisplayName("絶対パスを渡されても見つからない")
    void rejectsAbsolutePath() {
        assertFalse(folder.find(root.resolve("secret.pdf").toAbsolutePath().toString()).isPresent());
    }

    @Test
    @DisplayName("サブフォルダの PDF は見つからない (直下だけ)")
    void rejectsSubdirectory() {
        assertFalse(folder.find("sub/c.pdf").isPresent());
    }

    @Test
    @DisplayName("PDF 以外・存在しない名前・空・ヌル文字入りは見つからない")
    void rejectsOtherNames() {
        assertFalse(folder.find("memo.txt").isPresent(), "PDF 以外");
        assertFalse(folder.find("none.pdf").isPresent(), "存在しない");
        assertFalse(folder.find("sub").isPresent(), "フォルダ");
        assertFalse(folder.find("").isPresent(), "空");
        assertFalse(folder.find(null).isPresent(), "null");
        assertFalse(folder.find("a\u0000.pdf").isPresent(), "ヌル文字");
    }

    @Test
    @DisplayName("拡張子の大文字・小文字は区別しない")
    void acceptsUpperCaseExtension() throws IOException {
        write(directory.resolve("UPPER.PDF"), "%PDF-upper");
        assertTrue(folder.find("UPPER.PDF").isPresent());
    }

    @Test
    @DisplayName("フォルダが無ければ一覧は空になる")
    void listsNothingWhenDirectoryIsMissing() {
        assertTrue(new PdfFolder(root.resolve("missing")).list().isEmpty());
    }

    @Test
    @DisplayName("アプリに同梱した /WEB-INF/pdf の PDF が実在し、中身が PDF である")
    void bundledPdfFilesArePdf() throws IOException {
        PdfFolder bundled = new PdfFolder(Paths.get("src", "main", "webapp", "WEB-INF", "pdf"));
        List<PdfFolder.Entry> entries = bundled.list();

        assertFalse(entries.isEmpty(), "サンプルの PDF がありません");
        for (PdfFolder.Entry entry : entries) {
            Path file = bundled.find(entry.getName()).orElseThrow();
            try (InputStream in = Files.newInputStream(file)) {
                assertEquals("%PDF-", new String(in.readNBytes(5), StandardCharsets.US_ASCII),
                        "PDF の先頭の目印がありません: " + file);
            }
        }
    }

    private static void write(Path path, String content) throws IOException {
        Files.write(path, content.getBytes(StandardCharsets.UTF_8));
    }
}
