package com.example.servletsample.samples.form;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * 休暇の種類 (選択肢のチェックに使う「許可された値の一覧」)。
 *
 * <p>プルダウンやラジオボタンで選ばせる項目は、画面に出した選択肢以外の値が
 * 送られてくることがあります。開発者ツールで {@code <option>} を書き換える、
 * {@code curl} で直接 POST する、といったことができるためです。</p>
 *
 * <p>そこで<b>受け取った値が一覧にあるかどうかを必ず確かめます</b>
 * ({@link #findByCode(String)} が空を返したらエラー)。
 * 「一覧にあるものだけを通す」この形をホワイトリスト方式と呼びます。
 * 逆に「危ない値を弾く」ブラックリスト方式は、想定外の値を書き漏らすと素通りします。</p>
 *
 * <p>選択肢を enum にしておくと、画面に出す一覧 ({@link #all()}) と
 * チェックに使う一覧が<b>同じ 1 か所</b>になるので、追加し忘れが起きません。</p>
 */
public enum LeaveType {

    /** 年次有給休暇。 */
    ANNUAL("10", "年次有給休暇", "半日単位でも取得できます"),

    /** 特別休暇 (慶弔など)。 */
    SPECIAL("20", "特別休暇", "慶弔・結婚・出産など"),

    /** 病気休暇。 */
    SICK("30", "病気休暇", "診断書が必要になる場合があります"),

    /** 欠勤 (無給)。 */
    ABSENCE("40", "欠勤", "給与が支払われない扱いになります");

    private final String code;
    private final String label;
    private final String note;

    LeaveType(String code, String label, String note) {
        this.code = code;
        this.label = label;
        this.note = note;
    }

    /** 画面から送られてくる値。 */
    public String getCode() {
        return code;
    }

    /** 画面に表示する名前。 */
    public String getLabel() {
        return label;
    }

    /** 選択肢の下に出す補足。 */
    public String getNote() {
        return note;
    }

    /** 定義順の一覧 (画面の選択肢はここから作ります)。 */
    public static List<LeaveType> all() {
        return Arrays.asList(values());
    }

    /**
     * コードから探す。<b>一覧に無いコードなら空</b>。
     *
     * <p>{@code valueOf(String)} ではなくこのメソッドを使います。
     * {@code valueOf} は知らない名前を渡されると
     * {@link IllegalArgumentException} を投げるため、
     * 入力チェックのつもりで呼ぶと 500 エラーになってしまいます。</p>
     */
    public static Optional<LeaveType> findByCode(String code) {
        if (code == null) {
            return Optional.empty();
        }
        return all().stream()
                .filter(type -> type.code.equals(code))
                .findFirst();
    }

    /** コードに対応する表示名。見つからなければコードをそのまま返す。 */
    public static String labelOf(String code) {
        return findByCode(code).map(LeaveType::getLabel).orElse(code == null ? "" : code);
    }
}
