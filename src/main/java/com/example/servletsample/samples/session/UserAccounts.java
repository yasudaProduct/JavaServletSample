package com.example.servletsample.samples.session;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * デモ用の利用者マスタ。
 *
 * <p>実際のアプリではデータベースの {@code users} テーブルにあたります。
 * ここではログインの流れに集中できるよう、メモリ上に固定で持っています。</p>
 *
 * <h2>ハッシュは起動時に 1 回だけ作る</h2>
 * <p>{@link PasswordHash#hash(String)} はわざと遅く作ってあるので、
 * 呼ぶたびに計算すると画面が重くなります。
 * {@code static} の初期化で 1 回だけ計算し、以降は使い回します。
 * 起動後は読むだけなので、複数のスレッドから同時に使っても安全です。</p>
 */
public final class UserAccounts {

    /** ログイン ID → 利用者 (照合に使う。ハッシュを持っている)。 */
    private static final Map<String, UserAccount> ACCOUNTS;

    /** 画面に出すデモ用の一覧 (試せるように平文のパスワードも持っている)。 */
    private static final List<DemoRow> DEMO_ROWS;

    static {
        Map<String, UserAccount> accounts = new LinkedHashMap<>();
        List<DemoRow> rows = new ArrayList<>();
        define(accounts, rows, "taro", "山田 太郎", Role.MEMBER, "password1");
        define(accounts, rows, "hanako", "鈴木 花子", Role.MEMBER, "password2");
        define(accounts, rows, "admin", "管理者", Role.ADMIN, "admin1234");
        ACCOUNTS = Collections.unmodifiableMap(accounts);
        DEMO_ROWS = Collections.unmodifiableList(rows);
    }

    private UserAccounts() {
    }

    private static void define(Map<String, UserAccount> accounts, List<DemoRow> rows,
                               String loginId, String name, Role role, String rawPassword) {
        // マスタに入れるのはハッシュだけ。平文はここから先へ持ち出さない
        UserAccount account = new UserAccount(loginId, name, role, PasswordHash.hash(rawPassword));
        accounts.put(loginId, account);
        rows.add(new DemoRow(account, rawPassword));
    }

    /** ログイン ID で探す。見つからなければ空。 */
    public static Optional<UserAccount> find(String loginId) {
        return loginId == null ? Optional.empty() : Optional.ofNullable(ACCOUNTS.get(loginId.strip()));
    }

    /**
     * 画面に出すデモ用アカウントの一覧。
     *
     * <p><b>このメソッドはサンプルのためだけにあります。</b>
     * 実際のアプリに「パスワードの平文を画面へ渡す口」を作ってはいけません。</p>
     */
    public static List<DemoRow> demoRows() {
        return DEMO_ROWS;
    }

    /**
     * ログイン ID とパスワードを照合する。
     *
     * <p>ポイントは<b>失敗の理由を呼び出し元に返さない</b>ことです。
     * 「ID が存在しない」と「パスワードが違う」を区別して伝えると、
     * 攻撃者に「この ID は実在する」と教えることになります
     * (アカウント列挙)。どちらの場合も同じ結果を返します。</p>
     *
     * @return 認証できた利用者。できなければ空
     */
    public static Optional<UserAccount> authenticate(String loginId, String rawPassword) {
        Optional<UserAccount> account = find(loginId);
        if (account.isEmpty()) {
            // ID が無い場合も、パスワードの照合と同じくらいの時間をかける。
            // 「すぐ返ってきた = その ID は存在しない」と分かってしまうため
            PasswordHash.matches(rawPassword == null ? "" : rawPassword, dummyHash());
            return Optional.empty();
        }
        if (!PasswordHash.matches(rawPassword, account.get().getPasswordHash())) {
            return Optional.empty();
        }
        return account;
    }

    /** 照合時間をそろえるためのダミーのハッシュ。 */
    private static String dummyHash() {
        return ACCOUNTS.values().iterator().next().getPasswordHash();
    }

    /**
     * 画面に出すデモ用の一覧 1 件分。
     *
     * <p><b>本物の利用者マスタに、パスワードの平文を持つ列は存在しません。</b>
     * このサンプルを試せるようにするためだけのものです。</p>
     */
    public static final class DemoRow {

        private final UserAccount account;
        private final String rawPassword;

        DemoRow(UserAccount account, String rawPassword) {
            this.account = account;
            this.rawPassword = rawPassword;
        }

        /** ログイン ID。 */
        public String getLoginId() {
            return account.getLoginId();
        }

        /** 氏名。 */
        public String getName() {
            return account.getName();
        }

        /** 役割。 */
        public Role getRole() {
            return account.getRole();
        }

        /** 試すためのパスワード (サンプル専用)。 */
        public String getRawPassword() {
            return rawPassword;
        }

        /** 実際に保存されている値の概要 (ハッシュそのものではありません)。 */
        public String getPasswordHashSummary() {
            return account.getPasswordHashSummary();
        }
    }
}
