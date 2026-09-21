package com.example.servletsample.samples.form;

import java.io.Serializable;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.OptionalInt;
import java.util.regex.Pattern;

import javax.servlet.http.HttpServletRequest;

import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.common.Validators;

/**
 * セミナー申込フォームの入力値。
 *
 * <p>「入力 → 確認 → 完了」の 3 画面を行き来するので、
 * <b>{@link Serializable} にしてあります</b>。
 * セッションに預けて持ち回る方式を選べるようにするためです
 * (サーバを再起動したときにセッションをファイルへ退避する構成や、
 * 複数台でセッションを共有する構成では、直列化できないと落ちます)。</p>
 *
 * <h2>値は「入力されたまま」持つ</h2>
 * <p>数値や日付もいったん {@code String} で持っています。
 * 「30 歳」と入力されるべき欄に「さんじゅう」と入れられることがあるからです。
 * <b>型に変換できることを確かめるのが、そもそも入力チェックの仕事</b>なので、
 * 受け取った時点で変換してしまうと、変換に失敗したときに
 * 「何が入力されたか」を画面に戻せなくなります。</p>
 */
public final class SeminarForm implements Serializable {

    private static final long serialVersionUID = 1L;

    /** メールアドレスの簡易チェック。厳密な検証は実際に送ってみるしかありません。 */
    private static final Pattern EMAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    /** 氏名の上限。 */
    static final int NAME_MAX_LENGTH = 50;

    /** 会社名の上限。 */
    static final int COMPANY_MAX_LENGTH = 60;

    /** 備考の上限。 */
    static final int NOTE_MAX_LENGTH = 200;

    /** 申し込める人数の下限。 */
    static final int HEADCOUNT_MIN = 1;

    /** 申し込める人数の上限。 */
    static final int HEADCOUNT_MAX = 10;

    /** 選べる参加日 (実際には開催日マスタから取ります)。 */
    private static final List<String> AVAILABLE_DATES =
            List.of("2026-10-15", "2026-10-22", "2026-11-05");

    private final String name;
    private final String company;
    private final String email;
    private final String attendDate;
    private final String headcount;
    private final String note;

    private SeminarForm(String name, String company, String email,
                        String attendDate, String headcount, String note) {
        this.name = name;
        this.company = company;
        this.email = email;
        this.attendDate = attendDate;
        this.headcount = headcount;
        this.note = note;
    }

    /** リクエストパラメータから組み立てる。 */
    public static SeminarForm from(HttpServletRequest request) {
        return new SeminarForm(
                Validators.strip(request.getParameter("name")),
                Validators.strip(request.getParameter("company")),
                Validators.strip(request.getParameter("email")),
                Validators.strip(request.getParameter("attendDate")),
                Validators.strip(request.getParameter("headcount")),
                // 改行コードはブラウザや OS で変わるので \n にそろえる
                Validators.normalizeNewlines(request.getParameter("note")));
    }

    /** 空のフォーム (初期表示用)。 */
    public static SeminarForm empty() {
        return new SeminarForm("", "", "", "", "", "");
    }

    /** 選べる参加日。 */
    public static List<String> availableDates() {
        return AVAILABLE_DATES;
    }

    /**
     * 入力チェック。
     *
     * <p><b>確認画面へ進むときと、登録を確定するときの両方で呼びます。</b>
     * 確認画面の隠し項目は利用者が書き換えられるので、
     * 「確認画面を通ったから正しいはず」は成り立ちません。</p>
     */
    public ValidationErrors validate() {
        ValidationErrors errors = new ValidationErrors();

        // ---------------- 氏名 : 必須 → 桁数
        if (Validators.isBlank(name)) {
            errors.add("name", "氏名を入力してください。");
        } else if (!Validators.isLengthAtMost(name, NAME_MAX_LENGTH)) {
            errors.add("name", "氏名は " + NAME_MAX_LENGTH + " 文字以内で入力してください。");
        }

        // ---------------- 会社名 : 任意 → 桁数だけ
        if (Validators.isPresent(company) && !Validators.isLengthAtMost(company, COMPANY_MAX_LENGTH)) {
            errors.add("company", "会社名は " + COMPANY_MAX_LENGTH + " 文字以内で入力してください。");
        }

        // ---------------- メールアドレス : 必須 → 形式
        if (Validators.isBlank(email)) {
            errors.add("email", "メールアドレスを入力してください。");
        } else if (!EMAIL.matcher(email).matches()) {
            errors.add("email", "メールアドレスの形式が正しくありません。");
        }

        // ---------------- 参加日 : 必須 → 日付として読めるか → 選択肢にあるか
        if (Validators.isBlank(attendDate)) {
            errors.add("attendDate", "参加日を選んでください。");
        } else if (Validators.toDate(attendDate).isEmpty()) {
            errors.add("attendDate", "参加日の形式が正しくありません。");
        } else if (!AVAILABLE_DATES.contains(attendDate)) {
            // 画面のプルダウンに無い値が送られてきた = 画面を通していない。
            // 「選択肢から選ばせたから安全」は成り立ちません
            errors.add("attendDate", "選べない参加日です。");
        }

        // ---------------- 人数 : 必須 → 数値 → 範囲
        if (Validators.isBlank(headcount)) {
            errors.add("headcount", "人数を入力してください。");
        } else {
            OptionalInt value = Validators.toInt(headcount);
            if (value.isEmpty()) {
                errors.add("headcount", "人数は半角数字で入力してください。");
            } else if (value.getAsInt() < HEADCOUNT_MIN || value.getAsInt() > HEADCOUNT_MAX) {
                errors.add("headcount", "人数は " + HEADCOUNT_MIN + " 〜 " + HEADCOUNT_MAX
                        + " の範囲で入力してください。");
            }
        }

        // ---------------- 備考 : 任意 → 桁数
        if (Validators.isPresent(note) && !Validators.isLengthAtMost(note, NOTE_MAX_LENGTH)) {
            errors.add("note", "備考は " + NOTE_MAX_LENGTH + " 文字以内で入力してください。");
        }

        return errors;
    }

    /** 氏名。 */
    public String getName() {
        return name;
    }

    /** 会社名。 */
    public String getCompany() {
        return company;
    }

    /** メールアドレス。 */
    public String getEmail() {
        return email;
    }

    /** 参加日 (入力されたままの文字列)。 */
    public String getAttendDate() {
        return attendDate;
    }

    /** 人数 (入力されたままの文字列)。 */
    public String getHeadcount() {
        return headcount;
    }

    /** 備考。 */
    public String getNote() {
        return note;
    }

    /**
     * 確認画面に出す参加日。
     *
     * <p>検証を通っている前提で、画面に出す形に整えます
     * ({@code 2026-10-15} → {@code 2026/10/15})。</p>
     */
    public String getAttendDateText() {
        Optional<LocalDate> date = Validators.toDate(attendDate);
        return date.map(value -> value.getYear() + "/"
                        + String.format("%02d", value.getMonthValue()) + "/"
                        + String.format("%02d", value.getDayOfMonth()))
                .orElse(attendDate);
    }

    /** 人数 (数値)。検証を通っていない場合は 0。 */
    public int getHeadcountValue() {
        return Validators.toInt(headcount).orElse(0);
    }

    @Override
    public String toString() {
        return "SeminarForm{name=" + name + ", email=" + email
                + ", attendDate=" + attendDate + ", headcount=" + headcount + "}";
    }
}
