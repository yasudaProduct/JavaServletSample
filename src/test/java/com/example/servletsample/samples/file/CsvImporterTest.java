package com.example.servletsample.samples.file;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.apache.logging.log4j.CloseableThreadContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import com.example.servletsample.samples.file.CsvImportTemplateServlet.SampleFile;

/**
 * CSV 取り込み ({@link CsvImporter}) のテスト。
 *
 * <p>組み込みデータベース (H2) に実際に登録し、結果に加えて
 * <b>どんなログが出たか</b>も確かめます。ログはテスト用の設定
 * ({@code src/test/resources/log4j2-test.xml}) で動かし、
 * {@link ImportLogAppender} がメモリに取っておいた行を読んでいます。</p>
 *
 * <p>ログをテストするのは、ログも障害のときに頼る「機能」だからです。
 * とくに<b>個人情報がログに出ていないこと</b>は、画面を見ても分かりません。</p>
 */
class CsvImporterTest {

    private final ImportedEmployeeDao dao = new ImportedEmployeeDao();

    private final CsvImporter importer = new CsvImporter(dao);

    /** 直前の取り込み ID (ログを引くのに使う)。 */
    private String importId;

    @BeforeAll
    static void installLogAppender() {
        ImportLogAppender.install();
    }

    @BeforeEach
    @AfterEach
    void resetTable() {
        dao.reset();
    }

    @Nested
    @DisplayName("正常に取り込める")
    class Success {

        @Test
        @DisplayName("正常なデータ : 新しい社員は追加、登録済みの社員は上書きする")
        void importsValidFile() {
            CsvImportResult result = run("社員取込_正常.csv", SampleFile.VALID.toBytes(), StandardCharsets.UTF_8);

            assertTrue(result.isSuccess(), result.getMessage());
            assertEquals(5, result.getRowCount());
            assertEquals(4, result.getInsertedCount());
            assertEquals(1, result.getUpdatedCount());

            Map<String, ImportedEmployee> saved = employees();
            assertEquals(3 + 4, saved.size());
            assertEquals("D03", saved.get("E00003").getDepartmentCode(), "上書きされて開発部に異動している");
            assertEquals("Brown, Emily", saved.get("E10003").getName(), "カンマを含む値が 1 つの値として入る");
            assertEquals("2026-04-15", saved.get("E10002").getHireDate().toString(), "2026/4/15 の形も読める");
        }

        @Test
        @DisplayName("Shift_JIS のファイルは、Shift_JIS を選べば取り込める")
        void importsShiftJisFile() {
            CsvImportResult result = run("社員取込_ShiftJIS.csv", SampleFile.SJIS.toBytes(), CsvImporter.WINDOWS_31J);

            assertTrue(result.isSuccess(), result.getMessage());
            assertEquals("山田 太郎", employees().get("E10001").getName());
        }

        @Test
        @DisplayName("BOM 付きのファイルは、Shift_JIS を選んでいても UTF-8 として読む")
        void bomWinsOverSelection() {
            CsvImportResult result = run("社員取込_正常.csv", SampleFile.VALID.toBytes(), CsvImporter.WINDOWS_31J);

            assertTrue(result.isSuccess(), result.getMessage());
            assertTrue(logText().contains("BOM"), logText());
        }

        @Test
        @DisplayName("入力チェックを通った氏名は、絵文字だけの 40 文字でも DB に入る")
        void savesNameWithSurrogatePairs() {
            String name = "😀".repeat(EmployeeCsvRow.NAME_MAX_LENGTH);
            StringBuilder csv = header().append("E10001,").append(name)
                    .append(",ヤマダ タロウ,taro@example.com,D02,正社員,2026-04-01\r\n");

            CsvImportResult result = run("絵文字.csv", utf8(csv), StandardCharsets.UTF_8);

            assertTrue(result.isSuccess(), result.getMessage());
            assertEquals(name, employees().get("E10001").getName());
        }

        @Test
        @DisplayName("ログ : 開始と完了を INFO で、件数とかかった時間つきで出す")
        void logsStartAndFinish() {
            run("社員取込_正常.csv", SampleFile.VALID.toBytes(), StandardCharsets.UTF_8);

            List<ImportLogAppender.LogLine> lines = ImportLogAppender.linesOf(importId);
            assertTrue(lines.get(0).getText().contains("INFO"), lines.get(0).getText());
            assertTrue(lines.get(0).getText().contains("file=社員取込_正常.csv"), lines.get(0).getText());

            String last = lines.get(lines.size() - 1).getText();
            assertTrue(last.contains("取り込みが完了しました rows=5 inserted=4 updated=1"), last);
            assertTrue(last.contains("elapsed="), last);
        }
    }

    @Nested
    @DisplayName("入力エラー")
    class Invalid {

        @Test
        @DisplayName("エラーを含むデータ : 行番号・列・種類つきで全部返し、1 件も登録しない")
        void reportsAllErrorsAndSavesNothing() {
            CsvImportResult result = run("社員取込_エラーあり.csv", SampleFile.INVALID.toBytes(),
                    StandardCharsets.UTF_8);

            assertTrue(result.isInvalid(), result.getMessage());
            assertEquals(14, result.getRowCount(), "最後の空の行は数えない");
            assertEquals(3, employees().size(), "正しい行 (11 行目) も含めて 1 件も登録しない");

            List<String> found = result.getErrors().stream()
                    .map(e -> e.getLineNumber() + ":" + e.toLogText())
                    .collect(Collectors.toList());
            List<String> expected = List.of(
                    "2:社員コード:必須",
                    "3:社員コード:文字種",
                    "4:社員コード:桁数",
                    "5:フリガナ:文字種",
                    "6:フリガナ:文字種", "6:メールアドレス:形式",
                    "7:部署コード:マスタ", "7:雇用区分:選択肢",
                    "8:入社日:形式",
                    "9:入社日:形式",
                    "10:入社日:範囲",
                    "12:社員コード:重複",
                    "13:行:列数",
                    "14:氏名:桁数",
                    "15:氏名:必須", "15:フリガナ:必須", "15:メールアドレス:必須",
                    "15:部署コード:必須", "15:雇用区分:必須", "15:入社日:必須");
            assertEquals(expected, found);
            assertEquals(expected.size(), result.getErrorCount());
        }

        @Test
        @DisplayName("重複のメッセージには、先に出てきた行番号を書く")
        void duplicatePointsToFirstLine() {
            CsvImportResult result = run("社員取込_エラーあり.csv", SampleFile.INVALID.toBytes(),
                    StandardCharsets.UTF_8);

            CsvImportError duplicate = result.getErrors().stream()
                    .filter(e -> e.getKind().equals("重複")).findFirst().orElseThrow();
            assertTrue(duplicate.getMessage().contains("11 行目"), duplicate.getMessage());
        }

        @Test
        @DisplayName("ログ : WARN で件数を 1 行、DEBUG で位置を出す。入力値 (個人情報) は出さない")
        void logsWithoutPersonalData() {
            run("社員取込_エラーあり.csv", SampleFile.INVALID.toBytes(), StandardCharsets.UTF_8);

            String logs = logText();
            assertTrue(logs.contains("WARN"), logs);
            assertTrue(logs.contains("入力エラーがあるため取り込みませんでした rows=14 errorRows=13 errors=20"), logs);
            assertTrue(logs.contains("6 行目に入力エラー [フリガナ:文字種, メールアドレス:形式]"), logs);
            assertTrue(logs.contains("16 行目は空なので読み飛ばします"), logs);

            // 画面には出す値が、ログには 1 つも出ていない
            for (String value : List.of("ai.shimizu@example", "ｼﾐｽﾞ ｱｲ", "はやし だいすけ", "清水 愛",
                    "osamu.ishii@example.com", "2062-04-01")) {
                assertFalse(logs.contains(value), "ログに入力値が出ている: " + value);
            }
            assertFalse(logs.contains("ERROR"), "入力エラーで ERROR は出さない");
        }

        @Test
        @DisplayName("画面に出すエラーは上限まで。総数は別に持つ")
        void limitsErrorsShown() {
            StringBuilder csv = header();
            for (int i = 0; i < CsvImporter.MAX_ROWS; i++) {
                csv.append(",,,,,,2026-04-01\r\n");   // 1 行につき 6 件のエラー
            }
            CsvImportResult result = run("多すぎる.csv", utf8(csv), StandardCharsets.UTF_8);

            assertEquals(CsvImporter.MAX_ERRORS_SHOWN, result.getErrors().size());
            assertEquals(CsvImporter.MAX_ROWS * 6, result.getErrorCount());
            assertEquals(CsvImporter.MAX_ROWS * 6 - CsvImporter.MAX_ERRORS_SHOWN, result.getHiddenErrorCount());
            long debugLines = ImportLogAppender.linesOf(importId).stream()
                    .filter(line -> line.getText().contains("行目に入力エラー")).count();
            assertEquals(CsvImporter.MAX_ERROR_ROWS_LOGGED, debugLines, "ログに出す行数も上限まで");
        }
    }

    @Nested
    @DisplayName("ファイルごと差し戻す")
    class Rejected {

        @Test
        @DisplayName("Shift_JIS のファイルを UTF-8 のまま取り込むと、文字コードを選び直すよう伝える")
        void rejectsWrongEncoding() {
            CsvImportResult result = run("社員取込_ShiftJIS.csv", SampleFile.SJIS.toBytes(), StandardCharsets.UTF_8);

            assertTrue(result.isRejected());
            assertTrue(result.getMessage().contains("Shift_JIS を"), result.getMessage());
            assertTrue(logText().contains("reason=UTF-8 として読めない"), logText());
            assertEquals(3, employees().size());
        }

        @Test
        @DisplayName("見出しが違うファイルは受け付けない")
        void rejectsWrongHeader() {
            byte[] content = utf8(new StringBuilder("コード,名前\r\nE10001,山田 太郎\r\n"));

            CsvImportResult result = run("別のファイル.csv", content, StandardCharsets.UTF_8);

            assertTrue(result.isRejected());
            assertTrue(result.getMessage().contains("見出し"), result.getMessage());
        }

        @Test
        @DisplayName("\" の閉じ忘れは、行番号つきで知らせる")
        void rejectsBrokenQuote() {
            StringBuilder csv = header().append("E10001,\"山田 太郎,ヤマダ タロウ\r\n");

            CsvImportResult result = run("壊れた.csv", utf8(csv), StandardCharsets.UTF_8);

            assertTrue(result.isRejected());
            assertTrue(result.getMessage().startsWith("2 行目: "), result.getMessage());
        }

        @Test
        @DisplayName("テンプレート (見出しだけ) は「データ行が無い」")
        void rejectsHeaderOnly() {
            CsvImportResult result = run("社員取込_テンプレート.csv", SampleFile.TEMPLATE.toBytes(),
                    StandardCharsets.UTF_8);

            assertTrue(result.isRejected());
            assertTrue(result.getMessage().contains("取り込む行がありません"), result.getMessage());
        }

        @Test
        @DisplayName("空のファイル・拡張子違い・大きすぎるファイルは、中身を読む前に止める")
        void rejectsFile() {
            assertTrue(run("空.csv", new byte[0], StandardCharsets.UTF_8).isRejected());
            assertTrue(run("", SampleFile.VALID.toBytes(), StandardCharsets.UTF_8).isRejected());
            assertTrue(run("社員.xlsx", SampleFile.VALID.toBytes(), StandardCharsets.UTF_8).isRejected());
            assertTrue(run("大きい.csv", new byte[CsvImporter.MAX_FILE_SIZE + 1], StandardCharsets.UTF_8)
                    .isRejected());
        }

        @Test
        @DisplayName("1 回に取り込める行数を超えたら受け付けない")
        void rejectsTooManyRows() {
            CsvImportResult result = run("多い.csv", utf8(rows(20001, CsvImporter.MAX_ROWS + 1)),
                    StandardCharsets.UTF_8);

            assertTrue(result.isRejected());
            assertTrue(result.getMessage().contains(CsvImporter.MAX_ROWS + " 行まで"), result.getMessage());
        }

        @Test
        @DisplayName("登録できる社員の上限を超える取り込みは受け付けない")
        void rejectsOverCapacity() {
            assertTrue(run("1回目.csv", utf8(rows(20001, 100)), StandardCharsets.UTF_8).isSuccess());

            CsvImportResult result = run("2回目.csv", utf8(rows(30001, 100)), StandardCharsets.UTF_8);

            assertTrue(result.isRejected());
            assertEquals(3 + 100, employees().size());
        }
    }

    @Nested
    @DisplayName("システムの異常")
    class Failure {

        @Test
        @DisplayName("登録の途中で失敗したら全部取り消し、原因を添えた例外を投げる")
        void rollsBackAndThrows() {
            IllegalStateException e = assertThrows(IllegalStateException.class,
                    () -> run("社員取込_正常.csv", SampleFile.VALID.toBytes(), StandardCharsets.UTF_8, true));

            // 原因 (SQLException) が切れずに繋がっている
            assertInstanceOf(SQLException.class, e.getCause());
            assertTrue(e.getMessage().contains("5 件中 2 件を書いたところで失敗"), e.getMessage());

            // 途中まで書いた 2 件も残っていない (E00003 も上書きされていない)
            Map<String, ImportedEmployee> saved = employees();
            assertEquals(3, saved.size());
            assertEquals("D02", saved.get("E00003").getDepartmentCode());
        }
    }

    @Test
    @DisplayName("取り込み ID は IMP- と 16 進数 8 桁")
    void importIdFormat() {
        assertTrue(CsvImporter.newImportId().matches("IMP-[0-9A-F]{8}"));
    }

    @Test
    @DisplayName("ログのどの行にも取り込み ID が付く")
    void everyLineHasImportId() {
        run("社員取込_エラーあり.csv", SampleFile.INVALID.toBytes(), StandardCharsets.UTF_8);

        List<ImportLogAppender.LogLine> lines = ImportLogAppender.linesOf(importId);
        assertFalse(lines.isEmpty());
        assertTrue(lines.stream().allMatch(line -> line.getText().contains("[" + importId + "]")));
    }

    // ------------------------------------------------------------------ 補助

    private CsvImportResult run(String fileName, byte[] content, Charset charset) {
        return run(fileName, content, charset, false);
    }

    /** Servlet と同じく、ThreadContext に取り込み ID を入れて実行する。 */
    private CsvImportResult run(String fileName, byte[] content, Charset charset, boolean breakHalfway) {
        importId = CsvImporter.newImportId();
        try (CloseableThreadContext.Instance context =
                     CloseableThreadContext.put(CsvImporter.IMPORT_ID_KEY, importId)) {
            return importer.importCsv(importId, fileName, content, charset, breakHalfway);
        }
    }

    private String logText() {
        return ImportLogAppender.linesOf(importId).stream()
                .map(ImportLogAppender.LogLine::getText)
                .collect(Collectors.joining());
    }

    private Map<String, ImportedEmployee> employees() {
        return dao.findAll().stream().collect(Collectors.toMap(ImportedEmployee::getCode, Function.identity()));
    }

    private static StringBuilder header() {
        return new StringBuilder(String.join(",", EmployeeCsvRow.Column.labels())).append("\r\n");
    }

    /** 正しい行を count 行並べた CSV (社員コードは E{start} から連番)。 */
    private static StringBuilder rows(int start, int count) {
        StringBuilder csv = header();
        for (int i = 0; i < count; i++) {
            csv.append("E").append(start + i)
                    .append(",山田 太郎,ヤマダ タロウ,taro@example.com,D02,正社員,2026-04-01\r\n");
        }
        return csv;
    }

    private static byte[] utf8(StringBuilder csv) {
        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }
}
