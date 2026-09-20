package com.example.servletsample.common;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;
import java.util.Optional;
import java.util.OptionalInt;
import java.util.regex.Pattern;

/**
 * 入力チェックでよく使う判定を集めた部品。
 *
 * <p>「必須」「半角英数字だけか」「日付として実在するか」といった判定は、
 * どのフォームでも同じものを書くことになります。ここにまとめておくと、
 * <b>フォームのクラスには「どの項目に何を課すか」だけが並ぶ</b>ので読みやすくなります。</p>
 *
 * <pre>{@code
 * // 使う側 (フォームのクラス)
 * if (Validators.isBlank(employeeCode)) {
 *     errors.add("employeeCode", "社員コードを入力してください。");
 * } else if (!Validators.isHalfWidthAlphanumeric(employeeCode)) {
 *     errors.add("employeeCode", "社員コードは半角の英数字で入力してください。");
 * }
 * }</pre>
 *
 * <p>このクラスは <b>Servlet API に依存していません</b>。
 * 純粋な Java なので Tomcat を起動せずにテストできます
 * ({@code src/test/java/.../ValidatorsTest.java})。</p>
 *
 * <h2>ここに置く判定・置かない判定</h2>
 * <p>置くのは「どのアプリでも意味が変わらないもの」だけです。
 * 「社員コードは 5 桁」のような<b>業務の決めごとは各フォームのクラスに書きます</b>。
 * ここに書いてしまうと、別のアプリで桁数が違ったときに直せなくなります。</p>
 */
public final class Validators {

    /**
     * 半角の英数字だけか。
     *
     * <p>{@code [0-9A-Za-z]} と書いています。{@code \w} ではありません
     * ({@code \w} は {@code _} を含み、設定によっては全角の英数字にも当たります)。</p>
     */
    private static final Pattern HALF_WIDTH_ALPHANUMERIC = Pattern.compile("^[0-9A-Za-z]+$");

    /** 半角の数字だけか。全角数字 (１２３) を弾くために使う。 */
    private static final Pattern HALF_WIDTH_DIGITS = Pattern.compile("^[0-9]+$");

    /**
     * 全角カタカナ (と、ふりがなで使う記号) だけか。
     *
     * <p>文字の範囲は次のとおりです。</p>
     * <ul>
     *   <li>{@code ァ-ヶ} … 全角カタカナ (U+30A1 〜 U+30F6)</li>
     *   <li>{@code ー} … 長音記号 (U+30FC)。カタカナの範囲には入っていないので別に足します</li>
     *   <li>{@code ・} … 中点 (U+30FB)。「サン・テグジュペリ」のような姓名に使われます</li>
     *   <li>{@code 全角スペース} (U+3000) と半角スペース … 姓と名の区切り</li>
     * </ul>
     *
     * <p><b>半角カタカナ (ｱｲｳ: U+FF66 〜 U+FF9F) は通しません</b>。
     * 半角カタカナは文字化けの原因になりやすく、保存後に並び替えても
     * 全角と混ざって期待どおりに並ばないためです。</p>
     */
    private static final Pattern FULL_WIDTH_KATAKANA = Pattern.compile("^[ァ-ヶー・　 ]+$");

    /** 整数として読める形か (全角数字や {@code 1e3} を弾くため、変換の前に形を見る)。 */
    private static final Pattern INTEGER = Pattern.compile("^-?[0-9]+$");

    /**
     * 日付の形式。
     *
     * <p><b>{@code yyyy} ではなく {@code uuuu}</b> を使っています。
     * {@link ResolverStyle#STRICT} と組み合わせたとき、{@code yyyy} は
     * 「年号 (西暦か紀元前か)」の指定も必要になり、{@code 2026-04-01} すら
     * 解析に失敗するためです ({@code uuuu} は元号を持たない通し番号の年)。</p>
     *
     * <p>{@code STRICT} にしているのは <b>存在しない日付を弾く</b>ためです。
     * 既定の {@code SMART} では {@code 2026-02-30} がその月の末日 (2 月 28 日) へ
     * 勝手に丸められてしまい、利用者が打ち間違いに気づけません。</p>
     */
    private static final DateTimeFormatter STRICT_DATE =
            DateTimeFormatter.ofPattern("uuuu-MM-dd").withResolverStyle(ResolverStyle.STRICT);

    private Validators() {
    }

    /**
     * 未入力か (null・空文字・空白だけ)。
     *
     * <p>{@code trim()} ではなく {@code strip()} を使っているので、
     * <b>全角スペースだけの入力も「未入力」</b>と判定します。</p>
     */
    public static boolean isBlank(String value) {
        return value == null || value.strip().isEmpty();
    }

    /** 入力されているか ({@link #isBlank(String)} の逆)。 */
    public static boolean isPresent(String value) {
        return !isBlank(value);
    }

    /** 半角の英数字だけでできているか (未入力は false)。 */
    public static boolean isHalfWidthAlphanumeric(String value) {
        return value != null && HALF_WIDTH_ALPHANUMERIC.matcher(value).matches();
    }

    /** 半角の数字だけでできているか (未入力は false)。 */
    public static boolean isHalfWidthDigits(String value) {
        return value != null && HALF_WIDTH_DIGITS.matcher(value).matches();
    }

    /** 全角カタカナ (長音・中点・スペースを含む) だけでできているか (未入力は false)。 */
    public static boolean isFullWidthKatakana(String value) {
        return value != null && FULL_WIDTH_KATAKANA.matcher(value).matches();
    }

    /**
     * 人が数えたときの文字数。
     *
     * <p>{@code String.length()} は UTF-16 の単位数を返すため、絵文字や一部の漢字
     * (𠮟 など) が 2 文字と数えられます。画面に「30 文字以内」と書いたなら、
     * <b>コードポイントで数えるほうが利用者の感覚に合います</b>。</p>
     */
    public static int length(String value) {
        return value == null ? 0 : value.codePointCount(0, value.length());
    }

    /** 文字数が上限以内か (未入力は 0 文字として true)。 */
    public static boolean isLengthAtMost(String value, int max) {
        return length(value) <= max;
    }

    /** 文字数がちょうどか (社員コードのような固定長のチェックに使う)。 */
    public static boolean isLengthExactly(String value, int expected) {
        return length(value) == expected;
    }

    /**
     * 整数に変換する。整数として読めなければ空を返す。
     *
     * <p>{@code Integer.parseInt} をそのまま呼ばずに形を先に見ているのは、
     * <b>{@code Integer.parseInt("２０")} が 20 を返してしまう</b>からです
     * (全角数字も通ります)。また、数字だけでも 20 桁並べば {@code int} には
     * 収まらないので、例外は<b>範囲外</b>として扱います。</p>
     */
    public static OptionalInt toInt(String value) {
        if (value == null || !INTEGER.matcher(value.strip()).matches()) {
            return OptionalInt.empty();
        }
        try {
            return OptionalInt.of(Integer.parseInt(value.strip()));
        } catch (NumberFormatException e) {
            // 桁あふれ。「数字だが扱えない値」なので、形式ではなく範囲のエラーとして扱う
            return OptionalInt.empty();
        }
    }

    /**
     * {@code uuuu-MM-dd} の文字列を日付に変換する。<b>実在しない日付なら空</b>を返す。
     *
     * <pre>{@code
     * Validators.toDate("2026-04-01")  // → 2026-04-01
     * Validators.toDate("2026-02-30")  // → 空 (2 月 30 日は存在しない)
     * Validators.toDate("2026/04/01")  // → 空 (区切りが違う)
     * Validators.toDate("2026-4-1")    // → 空 (MM / dd は 2 桁ぴったり)
     * }</pre>
     */
    public static Optional<LocalDate> toDate(String value) {
        if (isBlank(value)) {
            return Optional.empty();
        }
        try {
            return Optional.of(LocalDate.parse(value.strip(), STRICT_DATE));
        } catch (DateTimeParseException e) {
            // 形が違う / 存在しない日付。どちらも「日付として読めない」として扱う
            return Optional.empty();
        }
    }

    /** 日付を {@code uuuu-MM-dd} の文字列にする (画面に戻すときに使う)。 */
    public static String formatDate(LocalDate date) {
        return date == null ? "" : date.format(STRICT_DATE);
    }

    /** 前後の空白を落とす。未送信 (null) は空文字にする。 */
    public static String strip(String value) {
        return value == null ? "" : value.strip();
    }

    /**
     * 改行コードを {@code \n} に揃える。
     *
     * <p>テキストエリアの改行は、送信されるときに {@code \r\n} (2 文字) になります。
     * 揃えずに数えると、画面の文字数カウンタとサーバ側の文字数が食い違い、
     * 「画面では 200 文字なのにエラーになる」という状態になります。</p>
     */
    public static String normalizeNewlines(String value) {
        return value == null ? "" : value.replace("\r\n", "\n").replace("\r", "\n");
    }
}
