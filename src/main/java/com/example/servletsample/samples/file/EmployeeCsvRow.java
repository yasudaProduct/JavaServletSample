package com.example.servletsample.samples.file;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Pattern;

import com.example.servletsample.common.Validators;

/**
 * 社員 CSV の 1 行ぶんの値と、その入力チェック。
 *
 * <p>画面のフォームの入力チェック (「フォーム・入力」カテゴリの {@code LeaveRequestForm}) と
 * 考え方は同じです。違うのは次の 2 点だけです。</p>
 * <ul>
 *   <li>エラーを「項目」ではなく<b>「行番号 + 列」</b>で返す</li>
 *   <li>1 項目に 1 件ずつ、<b>行の中のエラーをすべて</b>返す (直す人が 1 回で全部分かるように)</li>
 * </ul>
 *
 * <table border="1">
 *   <caption>この CSV で行っているチェック</caption>
 *   <tr><th>種類</th><th>何を確かめるか</th><th>この CSV での例</th></tr>
 *   <tr><td>列数</td><td>値の数が見出しと同じか</td><td>7 列 (Importer が先に見る)</td></tr>
 *   <tr><td>必須</td><td>入力されているか</td><td>全項目</td></tr>
 *   <tr><td>文字種</td><td>使ってよい文字だけか</td><td>社員コード (半角英数) / フリガナ (全角カタカナ)</td></tr>
 *   <tr><td>桁数</td><td>長さが決まりどおりか</td><td>社員コード (6 文字ちょうど) / 氏名 (40 文字以内)</td></tr>
 *   <tr><td>形式</td><td>決まった形に読めるか</td><td>メールアドレス / 入社日 (実在する日付か)</td></tr>
 *   <tr><td>範囲</td><td>値が許した幅に収まるか</td><td>入社日 (1 年後まで)</td></tr>
 *   <tr><td>選択肢</td><td>決められた値のどれかか</td><td>雇用区分</td></tr>
 *   <tr><td>マスタ</td><td>マスタに実在するか</td><td>部署コード</td></tr>
 *   <tr><td>重複</td><td>ファイルの中で同じキーが無いか</td><td>社員コード (Importer が見る)</td></tr>
 * </table>
 *
 * <p>1 つの列の中では「必須 → 文字種 → 桁数 → 形式 → 範囲 / マスタ」の順に見て、
 * <b>最初に引っかかったところで止めます</b>。空の値に「6 文字で」と言っても仕方がないためです。</p>
 *
 * <p>値は CSV に書かれていた<b>文字列のまま</b>持ちます。
 * 型に変換するのは、チェックを通ったあとの {@link #toEmployee(LocalDateTime)} です。</p>
 */
public final class EmployeeCsvRow {

    /** 社員コードの桁数 (固定長)。 */
    public static final int CODE_LENGTH = 6;

    /** 氏名の上限 (文字数)。 */
    public static final int NAME_MAX_LENGTH = 40;

    /** フリガナの上限 (文字数)。 */
    public static final int KANA_MAX_LENGTH = 40;

    /** メールアドレスの上限 (文字数)。 */
    public static final int EMAIL_MAX_LENGTH = 100;

    /** 入社日として受け付ける未来の上限 (年)。 */
    public static final int HIRE_DATE_MAX_YEARS_AHEAD = 1;

    /**
     * 部署マスタ (コード → 名前)。
     *
     * <p>実務では DB のマスタテーブルを引きます。
     * 行ごとに SQL を投げると 1 万行で 1 万回の問い合わせになるので、
     * <b>取り込みの最初に 1 回だけ全件読んで</b> {@code Map} にしておくのが定番です。</p>
     */
    public static final Map<String, String> DEPARTMENTS;

    static {
        Map<String, String> departments = new LinkedHashMap<>();
        departments.put("D01", "総務部");
        departments.put("D02", "営業部");
        departments.put("D03", "開発部");
        departments.put("D04", "経理部");
        DEPARTMENTS = Collections.unmodifiableMap(departments);
    }

    /** 雇用区分の選択肢。 */
    public static final List<String> EMPLOYMENT_TYPES = List.of("正社員", "契約社員", "パート");

    /**
     * メールアドレスの形。
     *
     * <p>「@ の前後に半角の文字があり、@ のあとにドットを含む」程度に留めています。
     * 規格 (RFC 5322) を完全に満たす正規表現は現実的ではなく、
     * 形が正しくても届くかどうかは送ってみるまで分かりません。
     * 入力チェックで弾くのは<b>明らかな打ち間違い</b>だけにします。</p>
     */
    private static final Pattern EMAIL =
            Pattern.compile("^[0-9A-Za-z._%+-]+@[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)+$");

    /**
     * Excel が書き出す日付の形 ({@code 2026/4/1})。
     *
     * <p>CSV を Excel で開いて保存し直すと、{@code 2026-04-01} が
     * <b>{@code 2026/4/1} に書き換わります</b> (Excel が日付として読み、自分の書式で書き戻すため)。
     * 利用者は何もしていないつもりなので、こちらの形も受け付けます。</p>
     */
    private static final DateTimeFormatter SLASH_DATE =
            DateTimeFormatter.ofPattern("uuuu/M/d").withResolverStyle(ResolverStyle.STRICT);

    /** CSV の列 (見出しの並び順)。 */
    public enum Column {

        CODE("社員コード", "必須 / 半角英数字 / " + CODE_LENGTH + " 文字 / ファイルの中で重複しない",
                "E10001"),
        NAME("氏名", "必須 / " + NAME_MAX_LENGTH + " 文字以内", "山田 太郎"),
        KANA("フリガナ", "必須 / 全角カタカナ / " + KANA_MAX_LENGTH + " 文字以内", "ヤマダ タロウ"),
        EMAIL("メールアドレス", "必須 / " + EMAIL_MAX_LENGTH + " 文字以内 / メールアドレスの形",
                "taro.yamada@example.com"),
        DEPARTMENT("部署コード", "必須 / 部署マスタにあるコード", "D02"),
        EMPLOYMENT_TYPE("雇用区分", "必須 / 正社員・契約社員・パートのどれか", "正社員"),
        HIRE_DATE("入社日", "必須 / 2026-04-01 か 2026/4/1 の形 / 実在する日付 / "
                + HIRE_DATE_MAX_YEARS_AHEAD + " 年後まで", "2026-04-01");

        private final String label;
        private final String rule;
        private final String example;

        Column(String label, String rule, String example) {
            this.label = label;
            this.rule = rule;
            this.example = example;
        }

        /** 見出しに書く名前。 */
        public String getLabel() {
            return label;
        }

        /** チェックの内容 (画面の説明用)。 */
        public String getRule() {
            return rule;
        }

        /** 値の例 (画面の説明用)。 */
        public String getExample() {
            return example;
        }

        /** 見出しの一覧 (左から順に)。 */
        public static List<String> labels() {
            List<String> labels = new ArrayList<>();
            for (Column column : values()) {
                labels.add(column.label);
            }
            return labels;
        }
    }

    private final int lineNumber;
    private final String code;
    private final String name;
    private final String kana;
    private final String email;
    private final String department;
    private final String employmentType;
    private final String hireDate;

    private EmployeeCsvRow(int lineNumber, List<String> values) {
        this.lineNumber = lineNumber;
        // 前後の空白 (全角スペースを含む) は落としてから確かめる。
        // Excel で整えた CSV には、セルの見た目を揃えるための空白が紛れ込みがちです
        this.code = Validators.strip(values.get(Column.CODE.ordinal()));
        this.name = Validators.strip(values.get(Column.NAME.ordinal()));
        this.kana = Validators.strip(values.get(Column.KANA.ordinal()));
        this.email = Validators.strip(values.get(Column.EMAIL.ordinal()));
        this.department = Validators.strip(values.get(Column.DEPARTMENT.ordinal()));
        this.employmentType = Validators.strip(values.get(Column.EMPLOYMENT_TYPE.ordinal()));
        this.hireDate = Validators.strip(values.get(Column.HIRE_DATE.ordinal()));
    }

    /**
     * CSV の 1 行から組み立てる。
     *
     * <p>値の数が列の数と同じであることは、呼び出し側 ({@link CsvImporter}) が先に確かめます。
     * 数が違う行は、どの値がどの列なのか決められないので、ここまで来させません。</p>
     *
     * @throws IllegalArgumentException 値の数が列の数と違うとき
     */
    public static EmployeeCsvRow of(int lineNumber, List<String> values) {
        if (values.size() != Column.values().length) {
            throw new IllegalArgumentException("値の数が列の数と違います: " + values.size());
        }
        return new EmployeeCsvRow(lineNumber, values);
    }

    /**
     * この行の値を確かめて、見つかったエラーをすべて返す (無ければ空)。
     *
     * @param today 「今日」として扱う日 (呼び出し側が {@code LocalDate.now()} を渡す)
     */
    public List<CsvImportError> validate(LocalDate today) {
        List<CsvImportError> errors = new ArrayList<>();
        validateCode(errors);
        validateName(errors);
        validateKana(errors);
        validateEmail(errors);
        validateDepartment(errors);
        validateEmploymentType(errors);
        validateHireDate(errors, today);
        return errors;
    }

    /** 社員コード : 必須 → 文字種 → 桁数。 */
    private void validateCode(List<CsvImportError> errors) {
        if (Validators.isBlank(code)) {
            errors.add(error(Column.CODE, "必須", code, "社員コードが空です。"));
        } else if (!Validators.isHalfWidthAlphanumeric(code)) {
            errors.add(error(Column.CODE, "文字種", code,
                    "社員コードは半角の英数字で書いてください。(例: E10001)"));
        } else if (!Validators.isLengthExactly(code, CODE_LENGTH)) {
            errors.add(error(Column.CODE, "桁数", code,
                    "社員コードは " + CODE_LENGTH + " 文字で書いてください。(いまは "
                    + Validators.length(code) + " 文字)"));
        }
    }

    /** 氏名 : 必須 → 桁数。 */
    private void validateName(List<CsvImportError> errors) {
        if (Validators.isBlank(name)) {
            errors.add(error(Column.NAME, "必須", name, "氏名が空です。"));
        } else if (!Validators.isLengthAtMost(name, NAME_MAX_LENGTH)) {
            errors.add(error(Column.NAME, "桁数", name,
                    "氏名は " + NAME_MAX_LENGTH + " 文字以内で書いてください。(いまは "
                    + Validators.length(name) + " 文字)"));
        }
    }

    /** フリガナ : 必須 → 文字種 → 桁数。 */
    private void validateKana(List<CsvImportError> errors) {
        if (Validators.isBlank(kana)) {
            errors.add(error(Column.KANA, "必須", kana, "フリガナが空です。"));
        } else if (!Validators.isFullWidthKatakana(kana)) {
            // ひらがな・漢字・半角カタカナ (ｼﾐｽﾞ) はここで弾かれる
            errors.add(error(Column.KANA, "文字種", kana,
                    "フリガナは全角カタカナで書いてください。(例: ヤマダ タロウ)"));
        } else if (!Validators.isLengthAtMost(kana, KANA_MAX_LENGTH)) {
            errors.add(error(Column.KANA, "桁数", kana,
                    "フリガナは " + KANA_MAX_LENGTH + " 文字以内で書いてください。(いまは "
                    + Validators.length(kana) + " 文字)"));
        }
    }

    /** メールアドレス : 必須 → 桁数 → 形式。 */
    private void validateEmail(List<CsvImportError> errors) {
        if (Validators.isBlank(email)) {
            errors.add(error(Column.EMAIL, "必須", email, "メールアドレスが空です。"));
        } else if (!Validators.isLengthAtMost(email, EMAIL_MAX_LENGTH)) {
            errors.add(error(Column.EMAIL, "桁数", email,
                    "メールアドレスは " + EMAIL_MAX_LENGTH + " 文字以内で書いてください。"));
        } else if (!EMAIL.matcher(email).matches()) {
            errors.add(error(Column.EMAIL, "形式", email,
                    "メールアドレスの形になっていません。(例: taro.yamada@example.com)"));
        }
    }

    /** 部署コード : 必須 → マスタ。 */
    private void validateDepartment(List<CsvImportError> errors) {
        if (Validators.isBlank(department)) {
            errors.add(error(Column.DEPARTMENT, "必須", department, "部署コードが空です。"));
        } else if (!DEPARTMENTS.containsKey(department)) {
            // 形は正しくても、そんな部署は無い。ここだけはマスタを見ないと判断できない
            errors.add(error(Column.DEPARTMENT, "マスタ", department,
                    "部署コード " + department + " は部署マスタにありません。("
                    + String.join(" / ", DEPARTMENTS.keySet()) + " のどれか)"));
        }
    }

    /** 雇用区分 : 必須 → 選択肢。 */
    private void validateEmploymentType(List<CsvImportError> errors) {
        if (Validators.isBlank(employmentType)) {
            errors.add(error(Column.EMPLOYMENT_TYPE, "必須", employmentType, "雇用区分が空です。"));
        } else if (!EMPLOYMENT_TYPES.contains(employmentType)) {
            errors.add(error(Column.EMPLOYMENT_TYPE, "選択肢", employmentType,
                    "雇用区分は " + String.join("・", EMPLOYMENT_TYPES) + " のどれかを書いてください。"));
        }
    }

    /** 入社日 : 必須 → 形式 (実在する日付か) → 範囲。 */
    private void validateHireDate(List<CsvImportError> errors, LocalDate today) {
        if (Validators.isBlank(hireDate)) {
            errors.add(error(Column.HIRE_DATE, "必須", hireDate, "入社日が空です。"));
            return;
        }
        Optional<LocalDate> parsed = parseDate(hireDate);
        if (parsed.isEmpty()) {
            // 2026-02-30 のような「形は合っているが存在しない日」もここで弾かれる
            errors.add(error(Column.HIRE_DATE, "形式", hireDate,
                    "入社日は 2026-04-01 か 2026/4/1 の形で、実在する日付を書いてください。"));
            return;
        }
        LocalDate limit = today.plusYears(HIRE_DATE_MAX_YEARS_AHEAD);
        if (parsed.get().isAfter(limit)) {
            // 2062 と 2026 の打ち間違いのような、形は正しいがありえない値
            errors.add(error(Column.HIRE_DATE, "範囲", hireDate,
                    "入社日は " + Validators.formatDate(limit) + " までの日付を書いてください。"));
        }
    }

    /** {@code 2026-04-01} と {@code 2026/4/1} の両方を読む。読めなければ空。 */
    static Optional<LocalDate> parseDate(String value) {
        Optional<LocalDate> iso = Validators.toDate(value);
        if (iso.isPresent()) {
            return iso;
        }
        try {
            return Optional.of(LocalDate.parse(Validators.strip(value), SLASH_DATE));
        } catch (DateTimeParseException e) {
            return Optional.empty();
        }
    }

    private CsvImportError error(Column column, String kind, String value, String message) {
        return new CsvImportError(lineNumber, column.getLabel(), kind, value, message);
    }

    /**
     * 登録するための値に変換する。
     *
     * <p>{@link #validate(LocalDate)} でエラーが無かった行にだけ呼びます。</p>
     *
     * @param now 登録日時として記録する時刻
     */
    public ImportedEmployee toEmployee(LocalDateTime now) {
        LocalDate date = parseDate(hireDate)
                .orElseThrow(() -> new IllegalStateException("入力チェックを通っていない行です: " + lineNumber));
        return new ImportedEmployee(code, name, kana, email, department, employmentType, date, now);
    }

    /** 行番号 (見出しを 1 行目として数える)。 */
    public int getLineNumber() {
        return lineNumber;
    }

    /** 社員コード (前後の空白は落としたもの)。 */
    public String getCode() {
        return code;
    }
}
