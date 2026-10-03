package com.example.servletsample.samples.file;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/**
 * 社員 CSV の 1 行の入力チェック ({@link EmployeeCsvRow}) のテスト。
 *
 * <p>「今日」は固定の日付を渡します。{@code LocalDate.now()} を使うと、
 * 入社日の範囲チェックの結果がテストを流した日によって変わってしまうためです。</p>
 */
class EmployeeCsvRowTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 10, 2);

    /** 正しい 1 行。テストではここから 1 列だけ変えて使う。 */
    private static final List<String> VALID = List.of(
            "E10001", "山田 太郎", "ヤマダ タロウ", "taro.yamada@example.com", "D02", "正社員", "2026-04-01");

    @Test
    @DisplayName("正しい行はエラーが無く、登録用の値に変換できる")
    void validRowHasNoErrors() {
        EmployeeCsvRow row = EmployeeCsvRow.of(2, VALID);

        assertEquals(List.of(), row.validate(TODAY));

        ImportedEmployee employee = row.toEmployee(LocalDateTime.of(2026, 10, 2, 9, 0));
        assertEquals("E10001", employee.getCode());
        assertEquals(LocalDate.of(2026, 4, 1), employee.getHireDate());
        assertEquals("営業部", employee.getDepartmentName());
    }

    @Test
    @DisplayName("前後の空白 (全角スペースを含む) は落としてから確かめる")
    void stripsValues() {
        List<String> values = new ArrayList<>(VALID);
        values.set(0, "　E10001 ");
        EmployeeCsvRow row = EmployeeCsvRow.of(2, values);

        assertEquals(List.of(), row.validate(TODAY));
        assertEquals("E10001", row.getCode());
    }

    @ParameterizedTest(name = "{0} = [{1}] → {2}")
    @CsvSource(delimiter = '|', value = {
        // 列         | 値                         | 種類
        "社員コード     | ''                         | 必須",
        "社員コード     | E-1001                     | 文字種",
        "社員コード     | Ｅ10001                    | 文字種",
        "社員コード     | E1002                      | 桁数",
        "社員コード     | E100001                    | 桁数",
        "氏名          | ''                         | 必須",
        "フリガナ       | ''                         | 必須",
        "フリガナ       | はやし だいすけ              | 文字種",
        "フリガナ       | ｼﾐｽﾞ ｱｲ                    | 文字種",
        "メールアドレス  | ''                         | 必須",
        "メールアドレス  | ai.shimizu@example         | 形式",
        "メールアドレス  | ai.shimizu.example.com     | 形式",
        "部署コード     | ''                         | 必須",
        "部署コード     | D99                        | マスタ",
        "雇用区分       | ''                         | 必須",
        "雇用区分       | アルバイト                   | 選択肢",
        "入社日        | ''                         | 必須",
        "入社日        | 2026-02-30                 | 形式",
        "入社日        | 2026年4月1日                | 形式",
        "入社日        | 2026-4-1                   | 形式",
        "入社日        | 2062-04-01                 | 範囲",
    })
    @DisplayName("列ごとのチェック")
    void detectsError(String column, String value, String kind) {
        List<CsvImportError> errors = validateWith(column, value);

        assertEquals(1, errors.size(), errors.toString());
        CsvImportError error = errors.get(0);
        assertEquals(5, error.getLineNumber());
        assertEquals(column, error.getColumn());
        assertEquals(kind, error.getKind());
        assertEquals(value, error.getValue());
        assertFalse(error.getMessage().isEmpty());
    }

    @Nested
    @DisplayName("桁数")
    class Length {

        @Test
        @DisplayName("氏名は 40 文字までなら通り、41 文字で引っかかる")
        void nameLength() {
            assertEquals(List.of(), validateWith("氏名", "あ".repeat(EmployeeCsvRow.NAME_MAX_LENGTH)));
            assertEquals("桁数", validateWith("氏名", "あ".repeat(EmployeeCsvRow.NAME_MAX_LENGTH + 1))
                    .get(0).getKind());
        }

        @Test
        @DisplayName("文字数は人が数えたとおりに数える (絵文字も 1 文字)")
        void countsCodePoints() {
            String name = "😀".repeat(EmployeeCsvRow.NAME_MAX_LENGTH);
            assertEquals(List.of(), validateWith("氏名", name));
        }
    }

    @Nested
    @DisplayName("入社日")
    class HireDate {

        @Test
        @DisplayName("Excel が書き出す 2026/4/1 の形も受け付ける")
        void acceptsSlashFormat() {
            assertEquals(List.of(), validateWith("入社日", "2026/4/15"));
            assertEquals(List.of(), validateWith("入社日", "2026/04/15"));
            assertEquals(LocalDate.of(2026, 4, 15), EmployeeCsvRow.parseDate("2026/4/15").orElseThrow());
        }

        @Test
        @DisplayName("1 年後の日付までは通り、その翌日で引っかかる")
        void upperLimit() {
            assertEquals(List.of(), validateWith("入社日", "2027-10-02"));
            assertEquals("範囲", validateWith("入社日", "2027-10-03").get(0).getKind());
        }

        @Test
        @DisplayName("/ 区切りでも、存在しない日付は弾く")
        void rejectsNonexistentSlashDate() {
            assertEquals("形式", validateWith("入社日", "2026/2/30").get(0).getKind());
        }
    }

    @Test
    @DisplayName("1 つの行の中のエラーは、列ごとに 1 件ずつ全部返す")
    void returnsAllErrorsInRow() {
        EmployeeCsvRow row = EmployeeCsvRow.of(15, List.of("E10015", "", "", "", "", "", ""));

        List<CsvImportError> errors = row.validate(TODAY);

        assertEquals(6, errors.size(), errors.toString());
        assertTrue(errors.stream().allMatch(e -> e.getKind().equals("必須")));
        assertTrue(errors.stream().allMatch(e -> e.getLineNumber() == 15));
    }

    @Test
    @DisplayName("ログ用の表し方には入力値を含めない")
    void logTextHasNoValue() {
        CsvImportError error = validateWith("メールアドレス", "ai.shimizu@example").get(0);

        assertEquals("メールアドレス:形式", error.toLogText());
        assertFalse(error.toString().contains("ai.shimizu"), error.toString());
    }

    @Test
    @DisplayName("画面に出す入力値は 40 文字で省略する")
    void shortensLongValue() {
        CsvImportError error = new CsvImportError(2, "氏名", "桁数", "あ".repeat(50), "長すぎます");

        assertEquals("あ".repeat(CsvImportError.MAX_VALUE_LENGTH) + "…", error.getValue());
    }

    @Test
    @DisplayName("値の数が列の数と違う行からは組み立てない")
    void rejectsWrongColumnCount() {
        assertThrows(IllegalArgumentException.class, () -> EmployeeCsvRow.of(2, List.of("E10001")));
    }

    @Test
    @DisplayName("見出しは列の定義の順に並ぶ")
    void labelsAreInColumnOrder() {
        assertEquals(List.of("社員コード", "氏名", "フリガナ", "メールアドレス", "部署コード", "雇用区分", "入社日"),
                EmployeeCsvRow.Column.labels());
    }

    /** 正しい行の 1 列だけを差し替えて、5 行目として確かめる。 */
    private static List<CsvImportError> validateWith(String column, String value) {
        List<String> values = new ArrayList<>(VALID);
        values.set(EmployeeCsvRow.Column.labels().indexOf(column), value);
        return EmployeeCsvRow.of(5, values).validate(TODAY);
    }
}
