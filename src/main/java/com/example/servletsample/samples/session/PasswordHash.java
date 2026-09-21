package com.example.servletsample.samples.session;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.util.Base64;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * パスワードをハッシュにして保存し、照合するための部品。
 *
 * <h2>パスワードは「元に戻せない形」で保存する</h2>
 * <p><b>平文で保存してはいけません。</b>データベースを覗かれた時点で全員分が漏れます。
 * 暗号化 (鍵があれば戻せる) も駄目です。鍵も一緒に盗まれます。
 * 使うのは<b>ハッシュ</b>――元に戻せない一方通行の変換です。</p>
 *
 * <pre>{@code
 * 保存するとき : password1 ──ハッシュ──→ 6f3a...（これを保存する）
 * 照合するとき : 入力された値を同じ手順でハッシュにして、保存済みの値と比べる
 * }</pre>
 *
 * <h2>ただの SHA-256 では足りない</h2>
 * <p>ハッシュなら何でもよいわけではありません。3 つの工夫が要ります。</p>
 * <ol>
 *   <li><b>ソルト</b> … 利用者ごとに違うランダムな値を混ぜる。
 *       同じパスワードの人が同じハッシュにならなくなり、
 *       あらかじめ計算した対応表 (レインボーテーブル) が効かなくなります</li>
 *   <li><b>反復</b> … 何万回も繰り返して<b>わざと遅くする</b>。
 *       正規の利用者は 1 回だけなので気にならず、総当たりを狙う側だけが困ります</li>
 *   <li><b>一定時間での比較</b> … 「何文字目まで一致したか」が所要時間から分からないようにする
 *       ({@link MessageDigest#isEqual(byte[], byte[])})</li>
 * </ol>
 *
 * <h2>実務では専用のライブラリを使ってください</h2>
 * <p>ここでは JDK だけで完結させるため <b>PBKDF2</b> を使っています。
 * 実務では <b>bcrypt / scrypt / Argon2</b> が推奨されます
 * (Spring Security の {@code BCryptPasswordEncoder} など)。
 * これらは計算に<b>メモリも使う</b>ように作られており、
 * GPU で一気に総当たりする攻撃に強くなっています。</p>
 *
 * <h2>保存する文字列の形</h2>
 * <pre>{@code
 * pbkdf2$100000$c2FsdA==$aGFzaA==
 *   │       │       │        └ ハッシュ (Base64)
 *   │       │       └ ソルト (Base64)
 *   │       └ 反復回数
 *   └ 方式
 * }</pre>
 * <p>方式と反復回数も一緒に保存しておくのが要点です。
 * 後から「反復回数を増やしたい」となったとき、
 * <b>古い値を読めなくならずに</b>新しい設定へ移行できます。</p>
 */
public final class PasswordHash {

    /** 鍵導出の方式。JDK に標準で入っています。 */
    private static final String ALGORITHM = "PBKDF2WithHmacSHA256";

    /** 方式を表す印 (保存する文字列の先頭)。 */
    private static final String SCHEME = "pbkdf2";

    /**
     * 反復回数。
     *
     * <p>大きいほど安全ですが、その分ログインに時間がかかります。
     * サンプルとして待たされないよう控えめにしてあります
     * (OWASP は PBKDF2-HMAC-SHA256 で 60 万回以上を推奨しています)。</p>
     */
    private static final int ITERATIONS = 100_000;

    /** ソルトの長さ (バイト)。 */
    private static final int SALT_BYTES = 16;

    /** 鍵の長さ (ビット)。 */
    private static final int KEY_BITS = 256;

    /**
     * 乱数生成器。
     *
     * <p>{@link SecureRandom} を使うこと。{@link java.util.Random} は
     * 「次に何が出るか」を予測できてしまうため、秘密の値を作るのには使えません。</p>
     */
    private static final SecureRandom RANDOM = new SecureRandom();

    private PasswordHash() {
    }

    /**
     * パスワードから保存用の文字列を作る。
     *
     * <p>呼ぶたびにソルトが変わるので、<b>同じパスワードでも毎回違う結果</b>になります。</p>
     */
    public static String hash(String rawPassword) {
        byte[] salt = new byte[SALT_BYTES];
        RANDOM.nextBytes(salt);
        byte[] key = derive(rawPassword, salt, ITERATIONS);
        return SCHEME + "$" + ITERATIONS
                + "$" + Base64.getEncoder().encodeToString(salt)
                + "$" + Base64.getEncoder().encodeToString(key);
    }

    /**
     * 入力されたパスワードが、保存されている値と一致するか。
     *
     * <p>保存されている値からソルトと反復回数を取り出し、
     * <b>同じ条件で計算し直して</b>比べます。
     * 保存値が壊れていても例外を外へ出さず {@code false} を返します
     * (ログイン画面でスタックトレースを見せないため)。</p>
     */
    public static boolean matches(String rawPassword, String stored) {
        if (rawPassword == null || stored == null) {
            return false;
        }
        String[] parts = stored.split("\\$");
        if (parts.length != 4 || !SCHEME.equals(parts[0])) {
            return false;
        }
        try {
            int iterations = Integer.parseInt(parts[1]);
            byte[] salt = Base64.getDecoder().decode(parts[2]);
            byte[] expected = Base64.getDecoder().decode(parts[3]);
            byte[] actual = derive(rawPassword, salt, iterations);

            // 「途中まで一致したか」が所要時間から漏れないよう、必ず最後まで比べる。
            // equals や == で 1 バイトずつ早期に打ち切ると、
            // 応答時間の差からパスワードを推測されうる (タイミング攻撃)
            return MessageDigest.isEqual(expected, actual);

        } catch (RuntimeException e) {
            // 保存値の形が壊れている。認証は失敗扱いにする
            return false;
        }
    }

    /** PBKDF2 でパスワードとソルトから鍵を導出する。 */
    private static byte[] derive(String rawPassword, byte[] salt, int iterations) {
        // char[] を使うのは PBEKeySpec の決まり。
        // 本来は「使い終わったら上書きして消せる」ようにするためです
        PBEKeySpec spec = new PBEKeySpec(rawPassword.toCharArray(), salt, iterations, KEY_BITS);
        try {
            return SecretKeyFactory.getInstance(ALGORITHM).generateSecret(spec).getEncoded();
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            // JDK に標準で入っている方式なので、ここへ来るのは環境が壊れているとき。
            // 握りつぶさず、システムエラーとして扱う
            throw new IllegalStateException("パスワードのハッシュ化に失敗しました", e);
        } finally {
            spec.clearPassword();
        }
    }

    /** 保存用の文字列から、画面に見せてよい範囲の情報だけを取り出す (解説表示用)。 */
    public static String describe(String stored) {
        if (stored == null) {
            return "";
        }
        String[] parts = stored.split("\\$");
        if (parts.length != 4) {
            return "(形式が不正)";
        }
        String digest = parts[3];
        String head = digest.length() <= 12 ? digest : digest.substring(0, 12) + "...";
        return parts[0] + " / " + parts[1] + " 回 / ソルトあり / " + head;
    }

}
