package com.example.servletsample.samples.list;

import java.util.OptionalInt;
import java.util.regex.Pattern;

import javax.servlet.http.HttpServletRequest;

import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.common.Validators;

/**
 * 取引先マスタの入力値。
 *
 * <p>登録と更新で同じクラスを使います。違いは {@code id} と {@code version} の有無だけです。</p>
 *
 * <h2>一意性のチェックは 2 段構え</h2>
 * <p>取引先コードの重複は、<b>アプリでも確かめ、データベースにも制約を置きます</b>。</p>
 *
 * <table border="1">
 *   <caption>それぞれの役割</caption>
 *   <tr><th></th><th>アプリでの確認</th><th>データベースの UNIQUE 制約</th></tr>
 *   <tr><td>目的</td><td>利用者に分かりやすく伝える</td><td>何があってもデータを壊さない</td></tr>
 *   <tr><td>同時実行</td><td><b>すり抜ける</b> (確認と登録の間に割り込める)</td><td>確実に防げる</td></tr>
 *   <tr><td>メッセージ</td><td>項目のそばに出せる</td><td>そのままでは利用者に見せられない</td></tr>
 * </table>
 *
 * <p>アプリだけだと同時登録をすり抜け、データベースだけだと
 * 「制約違反です」としか言えません。両方あって初めて、
 * <b>ふだんは親切に、いざというときは確実に</b>なります。</p>
 */
public final class CustomerForm {

    private static final Pattern CODE = Pattern.compile("^[A-Z]{1,3}-[0-9]{3,4}$");

    private static final Pattern EMAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    /** 取引先名の上限。 */
    static final int NAME_MAX_LENGTH = 60;

    /** 担当者名の上限。 */
    static final int CONTACT_MAX_LENGTH = 30;

    private final String id;
    private final String code;
    private final String name;
    private final String contact;
    private final String email;
    private final String version;

    private CustomerForm(String id, String code, String name,
                         String contact, String email, String version) {
        this.id = id;
        this.code = code;
        this.name = name;
        this.contact = contact;
        this.email = email;
        this.version = version;
    }

    /** リクエストパラメータから組み立てる。 */
    public static CustomerForm from(HttpServletRequest request) {
        return new CustomerForm(
                Validators.strip(request.getParameter("id")),
                Validators.strip(request.getParameter("code")),
                Validators.strip(request.getParameter("name")),
                Validators.strip(request.getParameter("contact")),
                Validators.strip(request.getParameter("email")),
                Validators.strip(request.getParameter("version")));
    }

    /** 既存の取引先から組み立てる (編集画面の初期表示)。 */
    public static CustomerForm of(Customer customer) {
        return new CustomerForm(
                String.valueOf(customer.getId()),
                customer.getCode(),
                customer.getName(),
                customer.getContact(),
                customer.getEmail(),
                String.valueOf(customer.getVersion()));
    }

    /** 空のフォーム (登録画面の初期表示)。 */
    public static CustomerForm empty() {
        return new CustomerForm("", "", "", "", "", "");
    }

    /** 入力チェック。 */
    public ValidationErrors validate() {
        ValidationErrors errors = new ValidationErrors();

        // ---------------- 取引先コード : 必須 → 形式
        if (Validators.isBlank(code)) {
            errors.add("code", "取引先コードを入力してください。");
        } else if (!CODE.matcher(code).matches()) {
            errors.add("code", "取引先コードは「AB-123」の形式で入力してください。");
        }

        // ---------------- 取引先名 : 必須 → 桁数
        if (Validators.isBlank(name)) {
            errors.add("name", "取引先名を入力してください。");
        } else if (!Validators.isLengthAtMost(name, NAME_MAX_LENGTH)) {
            errors.add("name", "取引先名は " + NAME_MAX_LENGTH + " 文字以内で入力してください。");
        }

        // ---------------- 担当者 : 必須 → 桁数
        if (Validators.isBlank(contact)) {
            errors.add("contact", "担当者を入力してください。");
        } else if (!Validators.isLengthAtMost(contact, CONTACT_MAX_LENGTH)) {
            errors.add("contact", "担当者は " + CONTACT_MAX_LENGTH + " 文字以内で入力してください。");
        }

        // ---------------- メールアドレス : 必須 → 形式
        if (Validators.isBlank(email)) {
            errors.add("email", "メールアドレスを入力してください。");
        } else if (!EMAIL.matcher(email).matches()) {
            errors.add("email", "メールアドレスの形式が正しくありません。");
        }

        return errors;
    }

    /** ID (新規登録なら空)。 */
    public String getId() {
        return id;
    }

    /** 取引先コード。 */
    public String getCode() {
        return code;
    }

    /** 取引先名。 */
    public String getName() {
        return name;
    }

    /** 担当者。 */
    public String getContact() {
        return contact;
    }

    /** メールアドレス。 */
    public String getEmail() {
        return email;
    }

    /** 画面から戻ってきた version。 */
    public String getVersion() {
        return version;
    }

    /** ID の数値。新規登録なら 0。 */
    public long getIdValue() {
        return Validators.toInt(id).orElse(0);
    }

    /** version の数値。読めなければ -1 (一致しないので競合として扱われる)。 */
    public int getVersionValue() {
        OptionalInt value = Validators.toInt(version);
        return value.isPresent() ? value.getAsInt() : -1;
    }

    /** 更新かどうか (ID があれば更新)。 */
    public boolean isUpdate() {
        return getIdValue() > 0;
    }

    @Override
    public String toString() {
        return "CustomerForm{id=" + id + ", code=" + code + ", version=" + version + "}";
    }
}
