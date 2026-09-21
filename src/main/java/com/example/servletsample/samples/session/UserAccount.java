package com.example.servletsample.samples.session;

/**
 * 利用者マスタの 1 件。
 *
 * <p>{@link LoginUser} (セッションに入れる情報) とは別のクラスにしています。
 * こちらは<b>パスワードのハッシュを持っている</b>ので、
 * そのままセッションへ入れたり画面へ渡したりしてはいけません。</p>
 *
 * <pre>{@code
 * UserAccount (マスタ / ハッシュを持つ)
 *     │  ログインに成功したときだけ
 *     ↓
 * LoginUser   (セッション / 見せてよい情報だけ)
 * }</pre>
 *
 * <p>「持っている情報が違うなら、クラスも分ける」。
 * 1 つのクラスを使い回すと、うっかり画面までパスワードが届きます。</p>
 */
public final class UserAccount {

    private final String loginId;
    private final String name;
    private final Role role;
    private final String passwordHash;

    UserAccount(String loginId, String name, Role role, String passwordHash) {
        this.loginId = loginId;
        this.name = name;
        this.role = role;
        this.passwordHash = passwordHash;
    }

    /** ログイン ID。 */
    public String getLoginId() {
        return loginId;
    }

    /** 氏名。 */
    public String getName() {
        return name;
    }

    /** 役割。 */
    public Role getRole() {
        return role;
    }

    /**
     * 保存されているパスワードのハッシュ。
     *
     * <p>照合のためだけに使います。画面へ渡さないでください。</p>
     */
    String getPasswordHash() {
        return passwordHash;
    }

    /** ハッシュの概要 (方式と反復回数。解説表示用で、ハッシュそのものではありません)。 */
    public String getPasswordHashSummary() {
        return PasswordHash.describe(passwordHash);
    }

    /** セッションに入れる形に変換する。 */
    LoginUser toLoginUser() {
        return new LoginUser(loginId, name, role);
    }
}
