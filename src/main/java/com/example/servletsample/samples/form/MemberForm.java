package com.example.servletsample.samples.form;

import java.util.regex.Pattern;

import javax.servlet.http.HttpServletRequest;

import com.example.servletsample.common.ValidationErrors;

/**
 * 会員登録フォームの入力値と、その入力チェック。
 *
 * <p>このクラスは <b>ほぼ純粋な Java</b> です。Servlet API を使っているのは
 * {@link #from(HttpServletRequest)} で画面からの値を受け取るところだけで、
 * {@link #validate()} は文字列を見ているだけです。こう分けておくと、
 * <b>Tomcat を起動しなくても入力チェックのテストが書けます</b>
 * ({@code src/test/java/.../MemberFormTest.java})。</p>
 *
 * <h2>チェックの順番</h2>
 * <p>1 つの項目については <b>必須 → 形式 → 範囲</b> の順に見て、
 * どれかに引っかかったらその項目はそこで打ち切ります。
 * 「未入力です」と「0 から 120 の範囲です」を同時に出しても混乱するだけだからです。
 * 項目をまたぐチェック (パスワードの一致) は、
 * それぞれの項目が妥当だと分かってから最後に行います。</p>
 *
 * <h2>前後の空白の扱い</h2>
 * <p>氏名・メールアドレス・年齢・郵便番号は受け取った時点で前後の空白を落とします。
 * 空白だけの入力を「入力あり」と判定してしまうと、空欄の氏名が登録できてしまうためです。
 * 落とすのに使うのは {@code trim()} ではなく {@code strip()} です
 * ({@code trim()} は U+0020 以下しか削らないため、<b>全角スペースが残ります</b>)。</p>
 *
 * <p>一方で <b>パスワードは削りません</b>。空白もパスワードに使える文字なので、
 * 勝手に削ると「登録したパスワードでログインできない」という事故になります。</p>
 */
public final class MemberForm {

    /**
     * メールアドレスの形式。
     *
     * <p>「@ の前後に空白でない文字があり、後ろ側にドットがある」程度しか見ていません。
     * RFC に忠実な正規表現は実用にならないほど複雑なうえ、厳しくすると
     * 実在するアドレスを弾いてしまいます。<b>本当に届くかどうかは確認メールでしか分かりません</b>。
     * ここでの目的は打ち間違い (「@ を入れ忘れた」など) に気づいてもらうことです。</p>
     */
    private static final Pattern EMAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    /** 年齢として受け付ける形。全角数字や {@code 1e3} を弾くために、先に形を見る。 */
    private static final Pattern INTEGER = Pattern.compile("^-?[0-9]+$");

    /** 郵便番号の形 (ハイフンあり・なしの両方を許す)。 */
    private static final Pattern ZIP_CODE = Pattern.compile("^[0-9]{7}$|^[0-9]{3}-[0-9]{4}$");

    /** パスワードに英字が含まれているか。 */
    private static final Pattern HAS_LETTER = Pattern.compile("[A-Za-z]");

    /** パスワードに数字が含まれているか。 */
    private static final Pattern HAS_DIGIT = Pattern.compile("[0-9]");

    /** 氏名の上限 (文字数)。 */
    static final int NAME_MAX_LENGTH = 50;

    /** 年齢の下限。 */
    static final int AGE_MIN = 0;

    /** 年齢の上限。 */
    static final int AGE_MAX = 120;

    /** パスワードの最低の長さ。 */
    static final int PASSWORD_MIN_LENGTH = 8;

    private final String name;
    private final String email;
    private final String age;
    private final String zipCode;
    private final String password;
    private final String passwordConfirm;
    private final boolean agreed;

    private MemberForm(String name, String email, String age, String zipCode,
                       String password, String passwordConfirm, boolean agreed) {
        this.name = name;
        this.email = email;
        this.age = age;
        this.zipCode = zipCode;
        this.password = password;
        this.passwordConfirm = passwordConfirm;
        this.agreed = agreed;
    }

    /**
     * リクエストパラメータから組み立てる (POST を受けたときに呼ぶ)。
     *
     * <p>チェックはここではしません。<b>受け取る</b>ことと<b>確かめる</b>ことを分けておくと、
     * 確かめる側 ({@link #validate()}) をリクエスト無しでテストできます。</p>
     *
     * <p>チェックボックスは、チェックが付いていないと<b>パラメータ自体が送られてきません</b>。
     * そのため値ではなく「パラメータが有るか無いか」で判定します。</p>
     */
    public static MemberForm from(HttpServletRequest request) {
        return new MemberForm(
                strip(request.getParameter("name")),
                strip(request.getParameter("email")),
                strip(request.getParameter("age")),
                strip(request.getParameter("zipCode")),
                // パスワードは前後の空白も意味のある文字なので削らない
                nullToEmpty(request.getParameter("password")),
                nullToEmpty(request.getParameter("passwordConfirm")),
                request.getParameter("agree") != null);
    }

    /** 値を直接指定して組み立てる (テストと、初期表示用の空のフォームで使う)。 */
    public static MemberForm of(String name, String email, String age, String zipCode,
                                String password, String passwordConfirm, boolean agreed) {
        return new MemberForm(strip(name), strip(email), strip(age), strip(zipCode),
                nullToEmpty(password), nullToEmpty(passwordConfirm), agreed);
    }

    /** 何も入力されていないフォーム (初期表示用)。 */
    public static MemberForm empty() {
        return new MemberForm("", "", "", "", "", "", false);
    }

    /**
     * 入力内容を確かめて、見つかったエラーを返す。
     *
     * <p>1 つの項目につきメッセージは 1 つだけです
     * ({@link ValidationErrors} が同じ項目の 2 件目を捨てます)。</p>
     */
    public ValidationErrors validate() {
        ValidationErrors errors = new ValidationErrors();

        validateName(errors);
        validateEmail(errors);
        validateAge(errors);
        validateZipCode(errors);
        validatePassword(errors);
        validatePasswordConfirm(errors);
        validateAgreement(errors);

        return errors;
    }

    /** 氏名 : 必須 → 長さ。 */
    private void validateName(ValidationErrors errors) {
        if (name.isEmpty()) {
            // strip 済みなので、空白 (全角スペースを含む) だけの入力もここに来る
            errors.add("name", "氏名を入力してください。");
            return;
        }
        int length = lengthOf(name);
        if (length > NAME_MAX_LENGTH) {
            errors.add("name", "氏名は " + NAME_MAX_LENGTH + " 文字以内で入力してください。"
                    + "(現在 " + length + " 文字)");
        }
    }

    /** メールアドレス : 必須 → 形式。 */
    private void validateEmail(ValidationErrors errors) {
        if (email.isEmpty()) {
            errors.add("email", "メールアドレスを入力してください。");
            return;
        }
        if (!EMAIL.matcher(email).matches()) {
            errors.add("email", "メールアドレスの形式が正しくありません。"
                    + "@ を含む形で入力してください。(例: taro@example.com)");
        }
    }

    /** 年齢 : 任意 → 形式 → 範囲。 */
    private void validateAge(ValidationErrors errors) {
        if (age.isEmpty()) {
            // 任意の項目なので、未入力はエラーにしない
            return;
        }
        if (!INTEGER.matcher(age).matches()) {
            // 全角数字の「２０」も、Integer.parseInt は通してしまう。
            // そのまま登録すると画面と DB で見た目が揃わないため、形の段階で弾く。
            errors.add("age", "年齢は半角数字で入力してください。(例: 30)");
            return;
        }
        int value;
        try {
            value = Integer.parseInt(age);
        } catch (NumberFormatException e) {
            // 数字だけでも 20 桁並べば int には収まらない。範囲外として扱う
            errors.add("age", "年齢は " + AGE_MIN + " から " + AGE_MAX + " の範囲で入力してください。");
            return;
        }
        if (value < AGE_MIN || value > AGE_MAX) {
            errors.add("age", "年齢は " + AGE_MIN + " から " + AGE_MAX + " の範囲で入力してください。");
        }
    }

    /** 郵便番号 : 任意 → 形式。 */
    private void validateZipCode(ValidationErrors errors) {
        if (zipCode.isEmpty()) {
            return;
        }
        if (!ZIP_CODE.matcher(zipCode).matches()) {
            errors.add("zipCode", "郵便番号は 7 桁の数字で入力してください。"
                    + "(例: 1234567 または 123-4567)");
        }
    }

    /** パスワード : 必須 → 長さ → 文字の種類。 */
    private void validatePassword(ValidationErrors errors) {
        if (password.isEmpty()) {
            errors.add("password", "パスワードを入力してください。");
            return;
        }
        if (password.length() < PASSWORD_MIN_LENGTH) {
            errors.add("password", "パスワードは " + PASSWORD_MIN_LENGTH + " 文字以上で入力してください。");
            return;
        }
        if (!HAS_LETTER.matcher(password).find() || !HAS_DIGIT.matcher(password).find()) {
            errors.add("password", "パスワードには英字と数字を両方含めてください。");
        }
    }

    /**
     * パスワード (確認) : パスワードとの相関チェック。
     *
     * <p>パスワード側がすでにエラーなら何も言いません。
     * 「8 文字以上にしてください」と「一致しません」が同時に出ると、
     * どちらを直せばよいのか分からなくなるためです。</p>
     */
    private void validatePasswordConfirm(ValidationErrors errors) {
        if (errors.has("password")) {
            return;
        }
        if (passwordConfirm.isEmpty()) {
            errors.add("passwordConfirm", "確認のため、パスワードをもう一度入力してください。");
            return;
        }
        if (!password.equals(passwordConfirm)) {
            errors.add("passwordConfirm", "パスワードが一致しません。もう一度入力してください。");
        }
    }

    /** 利用規約への同意 : 必須。 */
    private void validateAgreement(ValidationErrors errors) {
        if (!agreed) {
            errors.add("agree", "利用規約に同意していただく必要があります。");
        }
    }

    /** 氏名 (画面に戻すときに使う)。 */
    public String getName() {
        return name;
    }

    /** メールアドレス (画面に戻すときに使う)。 */
    public String getEmail() {
        return email;
    }

    /** 年齢。数値ではなく<b>入力された文字列のまま</b>持っています (下の解説を参照)。 */
    public String getAge() {
        return age;
    }

    /** 郵便番号 (入力されたまま。ハイフンの有無は問わない)。 */
    public String getZipCode() {
        return zipCode;
    }

    /**
     * 利用規約に同意したか。
     *
     * <p>JSP からは {@code ${form.agreed}} で参照できます。</p>
     */
    public boolean isAgreed() {
        return agreed;
    }

    /**
     * 年齢を数値で取り出す。未入力・チェックを通っていない値なら {@code -1}。
     *
     * <p>入力値そのものは文字列で持っておき、<b>チェックを通った後で</b>数値にします。
     * 先に数値にしてしまうと、エラーで画面に戻したときに
     * 「利用者が打った通りの文字列」を出し直せません
     * (たとえば {@code 007} が {@code 7} になってしまいます)。</p>
     */
    public int getAgeValue() {
        if (age.isEmpty() || !INTEGER.matcher(age).matches()) {
            return -1;
        }
        try {
            return Integer.parseInt(age);
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    /** 郵便番号からハイフンを取り除いた 7 桁。未入力なら空文字。 */
    public String getZipCodeDigits() {
        return zipCode.replace("-", "");
    }

    /**
     * 文字数を数える。
     *
     * <p>{@code String.length()} は UTF-16 の単位数を返すため、
     * 絵文字や一部の漢字 (𠮟 など) が 2 文字と数えられます。
     * 「50 文字以内」と書いた以上、人が数えた文字数と合わせておくのが親切です。</p>
     */
    private static int lengthOf(String value) {
        return value.codePointCount(0, value.length());
    }

    /**
     * 前後の空白を落とす。未送信 (null) は空文字として扱う。
     *
     * <p>{@code trim()} ではなく {@code strip()} (Java 11 以降) を使っています。
     * {@code trim()} が削るのは U+0020 以下の文字だけなので、
     * <b>全角スペースだけを入力されると「空白だけなのに入力あり」</b>になってしまいます。
     * {@code strip()} は Unicode の空白判定 ({@code Character.isWhitespace}) を使うため、
     * 全角スペースも落とせます。</p>
     */
    private static String strip(String value) {
        return value == null ? "" : value.strip();
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    /** ログや画面に出しても困らない形。<b>パスワードは含めません</b>。 */
    @Override
    public String toString() {
        return "MemberForm{name='" + name + "', email='" + email + "', age='" + age
                + "', zipCode='" + zipCode + "', agreed=" + agreed + "}";
    }
}
