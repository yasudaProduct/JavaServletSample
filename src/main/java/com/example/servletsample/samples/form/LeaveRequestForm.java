package com.example.servletsample.samples.form;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;

import javax.servlet.http.HttpServletRequest;

import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.common.Validators;

/**
 * 休暇申請フォームの入力値と、その入力チェック。
 *
 * <p>入力チェックには<b>いくつかの種類</b>があります。このクラスは、その種類を
 * ひととおり 1 つのフォームに詰め込んだものです。どの項目がどの種類に当たるかは
 * 各メソッドの見出しに書いてあります。</p>
 *
 * <table border="1">
 *   <caption>このフォームで行っているチェック</caption>
 *   <tr><th>種類</th><th>何を確かめるか</th><th>この画面での例</th></tr>
 *   <tr><td>必須</td><td>入力されているか</td><td>社員コード / フリガナ / 理由</td></tr>
 *   <tr><td>文字種</td><td>使ってよい文字だけか</td><td>社員コード (半角英数) / フリガナ (全角カタカナ)</td></tr>
 *   <tr><td>桁数</td><td>長さが決まりどおりか</td><td>社員コード (5 桁ちょうど) / 理由 (200 文字以内)</td></tr>
 *   <tr><td>形式</td><td>決まった形に読めるか</td><td>開始日 / 終了日 (uuuu-MM-dd で実在する日)</td></tr>
 *   <tr><td>範囲</td><td>値が許した幅に収まるか</td><td>開始日は今日以降・{@value #MAX_MONTHS_AHEAD} か月先まで</td></tr>
 *   <tr><td>相関</td><td>項目どうしの関係が成り立つか</td><td>開始日 ≦ 終了日 / 期間 {@value #MAX_PERIOD_DAYS} 日以内 / 引継ぎ先に自分を含めない</td></tr>
 *   <tr><td>選択 (単一)</td><td>用意した選択肢の値か</td><td>休暇の種類</td></tr>
 *   <tr><td>選択 (複数)</td><td>選んだ数が決まりどおりか</td><td>引継ぎ先 ({@value #MIN_BACKUPS} 〜 {@value #MAX_BACKUPS} 名)</td></tr>
 *   <tr><td>突き合わせ</td><td>マスタに実在するか</td><td>社員コード / 引継ぎ先</td></tr>
 * </table>
 *
 * <h2>基準日を引数で受け取る理由</h2>
 * <p>{@link #validate(LocalDate)} は「今日」を引数で受け取ります。
 * メソッドの中で {@code LocalDate.now()} を呼んでしまうと、
 * <b>テストが実行した日によって結果が変わってしまう</b>ためです
 * (「今日から 3 か月後」を固定の文字列でテストできなくなります)。
 * 呼び出し側の Servlet が {@code LocalDate.now()} を渡します。</p>
 *
 * <h2>受け取った値は文字列のまま持つ</h2>
 * <p>日付も数値も、<b>利用者が打った文字列のまま</b>保持します。
 * 先に {@code LocalDate} へ変換してしまうと、エラーで画面に戻したときに
 * 「打った通りの文字列」を出し直せません
 * (たとえば {@code 2026-02-30} が消えてしまい、何を直せばよいのか分からなくなります)。</p>
 */
public final class LeaveRequestForm {

    /** 社員コードの桁数 (固定長)。 */
    public static final int CODE_LENGTH = 5;

    /** フリガナの上限 (文字数)。 */
    public static final int KANA_MAX_LENGTH = 30;

    /** 理由の上限 (文字数)。 */
    public static final int REASON_MAX_LENGTH = 200;

    /** 続けて申請できる日数の上限。 */
    public static final int MAX_PERIOD_DAYS = 30;

    /** 引継ぎ先として選べる人数の下限。 */
    public static final int MIN_BACKUPS = 1;

    /** 引継ぎ先として選べる人数の上限。 */
    public static final int MAX_BACKUPS = 3;

    /** 何か月先まで申請できるか。 */
    public static final int MAX_MONTHS_AHEAD = 6;

    private final String employeeCode;
    private final String nameKana;
    private final String leaveType;
    private final String startDate;
    private final String endDate;
    private final List<String> backupCodes;
    private final String reason;

    private LeaveRequestForm(String employeeCode, String nameKana, String leaveType,
                             String startDate, String endDate, List<String> backupCodes,
                             String reason) {
        this.employeeCode = employeeCode;
        this.nameKana = nameKana;
        this.leaveType = leaveType;
        this.startDate = startDate;
        this.endDate = endDate;
        this.backupCodes = backupCodes;
        this.reason = reason;
    }

    /**
     * リクエストパラメータから組み立てる。
     *
     * <p>ここでは<b>受け取るだけ</b>で、良し悪しは判断しません。
     * 「受け取る」と「確かめる」を分けておくと、
     * 確かめる側をリクエスト無しでテストできます。</p>
     *
     * <p>チェックボックスは複数選べるので {@code getParameterValues} で受け取ります。
     * <b>1 つも選ばれていないと配列ではなく {@code null} が返る</b>ので、
     * そのまま {@code for} に渡すと {@link NullPointerException} になります。</p>
     */
    public static LeaveRequestForm from(HttpServletRequest request) {
        return of(request.getParameter("employeeCode"),
                request.getParameter("nameKana"),
                request.getParameter("leaveType"),
                request.getParameter("startDate"),
                request.getParameter("endDate"),
                request.getParameterValues("backupCodes"),
                request.getParameter("reason"));
    }

    /** 値を直接指定して組み立てる (テストと、初期表示用の空のフォームで使う)。 */
    public static LeaveRequestForm of(String employeeCode, String nameKana, String leaveType,
                                      String startDate, String endDate, String[] backupCodes,
                                      String reason) {
        return new LeaveRequestForm(
                Validators.strip(employeeCode),
                Validators.strip(nameKana),
                Validators.strip(leaveType),
                Validators.strip(startDate),
                Validators.strip(endDate),
                distinct(backupCodes),
                // 理由は前後の空白だけ落とし、途中の改行は残す (改行コードは \n に揃える)
                Validators.normalizeNewlines(Validators.strip(reason)));
    }

    /** 何も入力されていないフォーム (初期表示用)。 */
    public static LeaveRequestForm empty() {
        return of("", "", "", "", "", null, "");
    }

    /**
     * 入力内容を確かめて、見つかったエラーを返す。
     *
     * @param today 「今日」として扱う日 (呼び出し側が {@code LocalDate.now()} を渡す)
     */
    public ValidationErrors validate(LocalDate today) {
        ValidationErrors errors = new ValidationErrors();

        validateEmployeeCode(errors);
        validateNameKana(errors);
        validateLeaveType(errors);

        // 日付は「読めた値」を後ろの相関チェックでも使うので、結果を受け取っておく
        Optional<LocalDate> start = validateStartDate(errors, today);
        Optional<LocalDate> end = validateEndDate(errors, today);
        validatePeriod(errors, start, end);

        validateBackupCodes(errors);
        validateReason(errors);

        return errors;
    }

    /**
     * 社員コード : 必須 → 文字種 → 桁数 → マスタ突き合わせ。
     *
     * <p>並び順に意味があります。空文字に「5 桁で」と言っても仕方がありませんし、
     * 形の壊れた値でマスタを検索しても見つからないに決まっています。
     * <b>重いチェック (マスタ問い合わせ) を最後に置く</b>のは、
     * そこまでのチェックを通った値だけを調べれば済むからです。</p>
     */
    private void validateEmployeeCode(ValidationErrors errors) {
        if (Validators.isBlank(employeeCode)) {
            errors.add("employeeCode", "社員コードを入力してください。");
            return;
        }
        if (!Validators.isHalfWidthAlphanumeric(employeeCode)) {
            errors.add("employeeCode", "社員コードは半角の英数字で入力してください。(例: E1001)");
            return;
        }
        if (!Validators.isLengthExactly(employeeCode, CODE_LENGTH)) {
            errors.add("employeeCode", "社員コードは " + CODE_LENGTH + " 桁で入力してください。"
                    + "(現在 " + Validators.length(employeeCode) + " 桁)");
            return;
        }
        if (!EmployeeMaster.exists(employeeCode)) {
            // 形は正しいが、そんな社員はいない。ここだけはマスタを見ないと判断できない
            errors.add("employeeCode", "社員コード " + employeeCode + " は登録されていません。"
                    + "下の社員マスタから選んでください。");
        }
    }

    /** フリガナ : 必須 → 文字種 → 桁数。 */
    private void validateNameKana(ValidationErrors errors) {
        if (Validators.isBlank(nameKana)) {
            errors.add("nameKana", "フリガナを入力してください。");
            return;
        }
        if (!Validators.isFullWidthKatakana(nameKana)) {
            // ひらがな・漢字・半角カタカナ (ﾔﾏﾀﾞ) はここで弾かれる
            errors.add("nameKana", "フリガナは全角カタカナで入力してください。(例: ヤマダ タロウ)");
            return;
        }
        if (!Validators.isLengthAtMost(nameKana, KANA_MAX_LENGTH)) {
            errors.add("nameKana", "フリガナは " + KANA_MAX_LENGTH + " 文字以内で入力してください。"
                    + "(現在 " + Validators.length(nameKana) + " 文字)");
        }
    }

    /** 休暇の種類 : 選択必須 → 選択肢の妥当性 (ホワイトリスト)。 */
    private void validateLeaveType(ValidationErrors errors) {
        if (Validators.isBlank(leaveType)) {
            errors.add("leaveType", "休暇の種類を選んでください。");
            return;
        }
        if (LeaveType.findByCode(leaveType).isEmpty()) {
            // 画面に出していない値が送られてきた (選択肢の書き換え・直接 POST)
            errors.add("leaveType", "休暇の種類の値が正しくありません。選び直してください。");
        }
    }

    /** 開始日 : 必須 → 形式 (実在する日付か) → 範囲 (今日以降・半年先まで)。 */
    private Optional<LocalDate> validateStartDate(ValidationErrors errors, LocalDate today) {
        if (Validators.isBlank(startDate)) {
            errors.add("startDate", "開始日を入力してください。");
            return Optional.empty();
        }
        Optional<LocalDate> parsed = Validators.toDate(startDate);
        if (parsed.isEmpty()) {
            // 2026-02-30 のような「形は合っているが存在しない日」もここで弾かれる
            errors.add("startDate", "開始日は uuuu-MM-dd の形式で、実在する日付を入力してください。"
                    + "(例: " + Validators.formatDate(today) + ")");
            return Optional.empty();
        }
        LocalDate value = parsed.get();
        if (value.isBefore(today)) {
            errors.add("startDate", "開始日には今日 (" + Validators.formatDate(today) + ") 以降の日付を"
                    + "入力してください。");
            return Optional.empty();
        }
        LocalDate limit = today.plusMonths(MAX_MONTHS_AHEAD);
        if (value.isAfter(limit)) {
            errors.add("startDate", "開始日は " + MAX_MONTHS_AHEAD + " か月先 ("
                    + Validators.formatDate(limit) + ") までで入力してください。");
            return Optional.empty();
        }
        return parsed;
    }

    /** 終了日 : 必須 → 形式 (実在する日付か)。範囲は開始日との相関で見ます。 */
    private Optional<LocalDate> validateEndDate(ValidationErrors errors, LocalDate today) {
        if (Validators.isBlank(endDate)) {
            errors.add("endDate", "終了日を入力してください。");
            return Optional.empty();
        }
        Optional<LocalDate> parsed = Validators.toDate(endDate);
        if (parsed.isEmpty()) {
            errors.add("endDate", "終了日は uuuu-MM-dd の形式で、実在する日付を入力してください。"
                    + "(例: " + Validators.formatDate(today) + ")");
        }
        return parsed;
    }

    /**
     * 期間 : 相関チェック (開始日 ≦ 終了日 → 日数の上限)。
     *
     * <p>相関チェックは<b>関係する項目がすべて妥当だと分かってから</b>行います。
     * 開始日が読めていないのに「開始日より後にしてください」と言っても、
     * 利用者はどちらを直せばよいのか分かりません。</p>
     *
     * <p>メッセージを付けるのは<b>終了日の側だけ</b>にしています。
     * 両方を赤くすると「どちらが間違っているのか」が伝わらないためです。</p>
     */
    private void validatePeriod(ValidationErrors errors,
                                Optional<LocalDate> start, Optional<LocalDate> end) {
        if (start.isEmpty() || end.isEmpty()) {
            return;
        }
        if (end.get().isBefore(start.get())) {
            errors.add("endDate", "終了日は開始日 (" + Validators.formatDate(start.get())
                    + ") 以降の日付を入力してください。");
            return;
        }
        long days = ChronoUnit.DAYS.between(start.get(), end.get()) + 1;
        if (days > MAX_PERIOD_DAYS) {
            errors.add("endDate", "続けて申請できるのは " + MAX_PERIOD_DAYS + " 日までです。"
                    + "(今の指定は " + days + " 日間)");
        }
    }

    /** 引継ぎ先 : 個数 → マスタ突き合わせ → 相関 (自分自身は選べない)。 */
    private void validateBackupCodes(ValidationErrors errors) {
        if (backupCodes.size() < MIN_BACKUPS) {
            errors.add("backupCodes", "引継ぎ先を " + MIN_BACKUPS + " 名以上選んでください。");
            return;
        }
        if (backupCodes.size() > MAX_BACKUPS) {
            errors.add("backupCodes", "引継ぎ先は " + MAX_BACKUPS + " 名までです。"
                    + "(現在 " + backupCodes.size() + " 名)");
            return;
        }
        for (String code : backupCodes) {
            if (!EmployeeMaster.exists(code)) {
                errors.add("backupCodes", "引継ぎ先に登録されていない社員コード (" + code + ") が"
                        + "含まれています。選び直してください。");
                return;
            }
        }
        if (backupCodes.contains(employeeCode)) {
            // 申請者自身を引継ぎ先にはできない (2 つの項目を見ないと分からない = 相関チェック)
            errors.add("backupCodes", "引継ぎ先には申請者本人以外を選んでください。");
        }
    }

    /** 理由 : 必須 → 桁数。 */
    private void validateReason(ValidationErrors errors) {
        if (Validators.isBlank(reason)) {
            errors.add("reason", "理由を入力してください。");
            return;
        }
        if (!Validators.isLengthAtMost(reason, REASON_MAX_LENGTH)) {
            errors.add("reason", "理由は " + REASON_MAX_LENGTH + " 文字以内で入力してください。"
                    + "(現在 " + Validators.length(reason) + " 文字)");
        }
    }

    /** 社員コード (画面に戻すときに使う)。 */
    public String getEmployeeCode() {
        return employeeCode;
    }

    /** フリガナ。 */
    public String getNameKana() {
        return nameKana;
    }

    /** 休暇の種類のコード。 */
    public String getLeaveType() {
        return leaveType;
    }

    /** 休暇の種類の表示名 (完了メッセージで使う)。 */
    public String getLeaveTypeLabel() {
        return LeaveType.labelOf(leaveType);
    }

    /** 開始日 (入力された文字列のまま)。 */
    public String getStartDate() {
        return startDate;
    }

    /** 終了日 (入力された文字列のまま)。 */
    public String getEndDate() {
        return endDate;
    }

    /** 引継ぎ先の社員コード (重複は 1 件にまとめてある)。 */
    public List<String> getBackupCodes() {
        return backupCodes;
    }

    /**
     * その社員コードが引継ぎ先に選ばれているか。
     *
     * <p>エラーで画面に戻したときにチェックを付け直すために使います。
     * JSP からは EL のメソッド呼び出し (EL 3.0) で
     * {@code ${form.hasBackup(employee.code)}} と書けます。</p>
     */
    public boolean hasBackup(String code) {
        return backupCodes.contains(code);
    }

    /** 理由。 */
    public String getReason() {
        return reason;
    }

    /** 理由の文字数 (画面のカウンタの初期値に使う)。 */
    public int getReasonLength() {
        return Validators.length(reason);
    }

    /**
     * 申請日数。開始日・終了日が日付として読めないときや、前後が逆のときは {@code 0}。
     *
     * <p>両端を含めて数えます (4/1 〜 4/3 なら 3 日)。</p>
     */
    public int getDays() {
        Optional<LocalDate> start = Validators.toDate(startDate);
        Optional<LocalDate> end = Validators.toDate(endDate);
        if (start.isEmpty() || end.isEmpty() || end.get().isBefore(start.get())) {
            return 0;
        }
        return (int) ChronoUnit.DAYS.between(start.get(), end.get()) + 1;
    }

    /**
     * 選ばれた引継ぎ先を「氏名 (コード)」の並びにする (完了メッセージ用)。
     */
    public String getBackupNames() {
        List<String> names = new ArrayList<>();
        for (String code : backupCodes) {
            String name = EmployeeMaster.nameOf(code);
            names.add(name.isEmpty() ? code : name + " (" + code + ")");
        }
        return String.join("、", names);
    }

    /**
     * 同じ値を 1 つにまとめ、並び順は保ったまま一覧にする。
     *
     * <p>チェックボックスは普通は重複しませんが、直接 POST されれば
     * 同じ値を何度でも送れます。重複を残したまま数えると、
     * 「3 名まで」の判定を同じ人の 3 回送信ですり抜けられてしまいます。</p>
     */
    private static List<String> distinct(String[] values) {
        if (values == null) {
            // 1 つも選ばれていないと getParameterValues は null を返す
            return Collections.emptyList();
        }
        LinkedHashSet<String> unique = new LinkedHashSet<>();
        for (String value : values) {
            String stripped = Validators.strip(value);
            if (!stripped.isEmpty()) {
                unique.add(stripped);
            }
        }
        return Collections.unmodifiableList(new ArrayList<>(unique));
    }

    /** ログに出しても困らない形。 */
    @Override
    public String toString() {
        return "LeaveRequestForm{employeeCode='" + employeeCode + "', leaveType='" + leaveType
                + "', startDate='" + startDate + "', endDate='" + endDate
                + "', backupCodes=" + Arrays.toString(backupCodes.toArray()) + "}";
    }
}
