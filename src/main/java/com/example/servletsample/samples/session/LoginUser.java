package com.example.servletsample.samples.session;

import java.io.Serializable;

/**
 * ログイン中の利用者。セッションに入れて持ち回ります。
 *
 * <p>JSP からは {@code ${loginUser.name}} のように参照できます。</p>
 *
 * <h2>セッションに入れてよいもの / いけないもの</h2>
 * <table border="1">
 *   <caption>判断の目安</caption>
 *   <tr><th>入れてよい</th><th>入れてはいけない</th></tr>
 *   <tr><td>利用者を識別する ID、表示名、役割</td><td><b>パスワード</b> (ハッシュも含む)</td></tr>
 *   <tr><td>画面の出し分けに使う程度の少量の値</td><td>検索結果の一覧まるごと (メモリを食う)</td></tr>
 *   <tr><td>いつログインしたか</td><td>すぐ古くなる情報 (残高、在庫数)</td></tr>
 * </table>
 *
 * <p>セッションの中身は<b>サーバのメモリ</b>に置かれます。
 * 1 人あたり 100 KB 使う作りにすると、同時に 1,000 人で 100 MB です。
 * 入れるのは ID 程度にして、実データは都度取りに行くのが原則です。</p>
 *
 * <h2>Serializable にしておく</h2>
 * <p>サーバを再起動するときにセッションをファイルへ退避する構成や、
 * 複数台でセッションを共有する構成では、直列化できないオブジェクトがあると落ちます。
 * <b>変更できない (イミュータブルな) オブジェクトにしてある</b>のも意図的で、
 * 複数のスレッドから同時に読まれても壊れません。</p>
 */
public final class LoginUser implements Serializable {

    private static final long serialVersionUID = 1L;

    /** セッションに入れるときの属性名。 */
    public static final String SESSION_KEY = "loginUser";

    private final String loginId;
    private final String name;
    private final Role role;

    LoginUser(String loginId, String name, Role role) {
        this.loginId = loginId;
        this.name = name;
        this.role = role;
    }

    /** ログイン ID。 */
    public String getLoginId() {
        return loginId;
    }

    /** 画面に表示する氏名。 */
    public String getName() {
        return name;
    }

    /** 役割。 */
    public Role getRole() {
        return role;
    }

    /** 管理者かどうか (JSP から {@code ${loginUser.admin}} で参照できる)。 */
    public boolean isAdmin() {
        return role.isAdmin();
    }

    @Override
    public String toString() {
        return loginId + " (" + role + ")";
    }
}
