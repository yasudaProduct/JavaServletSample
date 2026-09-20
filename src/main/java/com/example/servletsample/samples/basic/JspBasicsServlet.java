package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】EL と JSTL の基本。
 *
 * <p>JSP に書く <code>${...}</code>（EL: Expression Language）と、
 * <code>c:forEach</code> などの JSTL タグの書き方を一通り見せるサンプルです。
 * この Servlet は<b>materials（材料）を並べるだけ</b>で、
 * 表示の組み立ては全部 JSP 側の EL / JSTL が行います。</p>
 *
 * <p>JSP に渡している値は次のとおりです。
 * 「EL が扱える型」をひととおり並べてあります。</p>
 *
 * <table border="1">
 *   <caption>リクエストスコープに入れている値</caption>
 *   <tr><th>名前</th><th>型</th><th>何のため</th></tr>
 *   <tr><td>{@code sampleCode}</td><td>String</td><td>fn:toUpperCase / fn:substring などの材料</td></tr>
 *   <tr><td>{@code tagCsv}</td><td>String</td><td>fn:split / fn:join の材料</td></tr>
 *   <tr><td>{@code price} / {@code quantity}</td><td>int</td><td>EL の算術演算</td></tr>
 *   <tr><td>{@code amount}</td><td>long</td><td>fmt:formatNumber（3 桁区切り・通貨）</td></tr>
 *   <tr><td>{@code rate}</td><td>double</td><td>fmt:formatNumber（パーセント）</td></tr>
 *   <tr><td>{@code premium}</td><td>boolean</td><td>c:if の条件</td></tr>
 *   <tr><td>{@code member}</td><td>{@link Member}</td><td>Bean のプロパティ参照（{@code ${member.name}}）</td></tr>
 *   <tr><td>{@code settings}</td><td>Map</td><td>{@code ${settings.theme}} / {@code ${settings['page-size']}}</td></tr>
 *   <tr><td>{@code items}</td><td>List&lt;{@link Item}&gt;</td><td>c:forEach と添字アクセス</td></tr>
 *   <tr><td>{@code emptyItems}</td><td>List（空）</td><td>empty 演算子</td></tr>
 *   <tr><td>{@code stock} / {@code nickname} / {@code sampleText}</td><td>画面から</td><td>その場で結果が変わるデモ</td></tr>
 * </table>
 *
 * <p>{@code member.email} だけは<b>わざと null</b>にしてあります。
 * EL は null のプロパティを参照しても例外にならず空文字として扱う、
 * という性質を画面で確かめるためです。</p>
 *
 * <p>「エスケープあり / なし」の比較では<b>利用者が入力した文字列をそのまま出しません</b>。
 * 入力欄にすると、このサンプル自体がクロスサイトスクリプティングの穴になってしまうためです。
 * サーバ側に用意した無害な文字列（太字や色が変わるだけのもの）から選ばせています。</p>
 */
@WebServlet(name = "jspBasics", urlPatterns = {JspBasicsServlet.SAMPLE_PATH})
public class JspBasicsServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** このサンプル画面の URL（コンテキストパスは含まない）。 */
    static final String SAMPLE_PATH = "/samples/basic/jsp-basics";

    private static final String VIEW = "/WEB-INF/views/samples/basic/jsp-basics.jsp";

    /** 在庫数の初期値。 */
    static final int DEFAULT_STOCK = 12;

    /** 在庫数の上限。画面の表示が崩れない程度に抑えます。 */
    static final int MAX_STOCK = 999;

    /** ニックネームの初期値。 */
    static final String DEFAULT_NICKNAME = "たろちゃん";

    /** ニックネームの最大文字数。 */
    static final int NICKNAME_MAX_LENGTH = 30;

    /** 既定で選ばれている「エスケープ比較用」の文字列のキー。 */
    static final String DEFAULT_TEXT_KEY = "bold";

    /**
     * エスケープあり / なしを見比べるための文字列。
     *
     * <p>エスケープせずに出すので、<b>太字や色が変わるだけの無害なもの</b>に限定しています。
     * 「利用者から受け取った文字列をエスケープせずに出す」のは危険なので、
     * 画面からはこのキーだけを受け取り、実際の文字列はサーバ側で決めます
     * （許可したものだけを通す、いわゆるホワイトリスト方式）。</p>
     */
    private static final Map<String, String> TEXT_PRESETS = createTextPresets();

    private static Map<String, String> createTextPresets() {
        // 画面の選択肢に出す順番を保ちたいので LinkedHashMap を使う
        Map<String, String> presets = new LinkedHashMap<>();
        presets.put("bold", "<b>太字</b>になる文字列");
        presets.put("color", "<span class=\"text-danger\">赤くなる文字列</span>");
        presets.put("amp", "Tom & Jerry / 5 < 10 / \"引用符\"");
        return Collections.unmodifiableMap(presets);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ----- 画面から受け取る値（結果がその場で変わるようにするため） -----
        int stock = parseStock(request.getParameter("stock"));
        String nickname = resolveNickname(request.getParameter("nickname"));
        String textKey = presetKey(request.getParameter("text"));

        request.setAttribute("stock", stock);
        request.setAttribute("nickname", nickname);
        request.setAttribute("textKey", textKey);
        request.setAttribute("sampleText", presetText(textKey));
        request.setAttribute("textPresets", TEXT_PRESETS);

        // ----- 文字列（fn: の材料） -----
        request.setAttribute("sampleCode", "jsp-basics");
        request.setAttribute("tagCsv", "EL,JSTL,fn,fmt");

        // ----- 数値・真偽値（EL の演算と fmt: の材料） -----
        request.setAttribute("price", 1280);
        request.setAttribute("quantity", 3);
        request.setAttribute("amount", 1234567L);
        request.setAttribute("rate", 0.185d);
        request.setAttribute("premium", true);

        // ----- Bean -----
        request.setAttribute("member", createMember());

        // ----- Map -----
        request.setAttribute("settings", createSettings());

        // ----- List -----
        request.setAttribute("items", createItems());
        // 空のコレクション。empty 演算子が null と同じ扱いになることを見せるために置いています
        request.setAttribute("emptyItems", Collections.emptyList());

        forward(request, response, VIEW);
    }

    /**
     * 在庫数を受け取る。
     *
     * <p>URL は利用者が自由に書き換えられるので、
     * {@code ?stock=abc} でも {@code ?stock=-1} でも落ちないように丸めます。</p>
     */
    static int parseStock(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return DEFAULT_STOCK;
        }
        try {
            int value = Integer.parseInt(raw.trim());
            // 負の在庫や桁あふれは意味がないので、扱える範囲に収める
            return Math.max(0, Math.min(MAX_STOCK, value));
        } catch (NumberFormatException e) {
            // 数字でなければ既定値で続ける（画面をエラーにしない）
            return DEFAULT_STOCK;
        }
    }

    /**
     * ニックネームを受け取る。
     *
     * <p>「送られていない（null）」と「空にして送られた（空文字）」を区別します。
     * 空文字のときに既定値へ戻してしまうと、
     * <code>empty</code> 演算子の動きを画面で確かめられなくなるためです。</p>
     */
    static String resolveNickname(String raw) {
        if (raw == null) {
            return DEFAULT_NICKNAME;
        }
        String trimmed = raw.trim();
        return trimmed.length() > NICKNAME_MAX_LENGTH
                ? trimmed.substring(0, NICKNAME_MAX_LENGTH)
                : trimmed;
    }

    /**
     * エスケープ比較用の文字列のキーを受け取る。
     *
     * <p>知らないキーは既定値に丸めます。画面から来た文字列を
     * そのまま HTML として出さないための入口がここです。</p>
     */
    static String presetKey(String raw) {
        return raw != null && TEXT_PRESETS.containsKey(raw) ? raw : DEFAULT_TEXT_KEY;
    }

    /** キーに対応する文字列（知らないキーなら既定のもの）。 */
    static String presetText(String raw) {
        return TEXT_PRESETS.get(presetKey(raw));
    }

    private static Member createMember() {
        return new Member(
                "山田 太郎",
                "情報システム部",
                34,
                LocalDate.of(2021, 4, 1),
                Arrays.asList("Java", "SQL", "JSP"));
    }

    private static Map<String, String> createSettings() {
        Map<String, String> settings = new LinkedHashMap<>();
        settings.put("theme", "light");
        settings.put("rowsPerPage", "20");
        // キーに「-」が入っていると ${settings.page-size} とは書けない（引き算に見えてしまう）。
        // [...] で書く必要があることを画面で見せるために入れています
        settings.put("page-size", "A4");
        // 値が null のキー。${settings.accentColor} は例外ではなく空になります
        settings.put("accentColor", null);
        return Collections.unmodifiableMap(settings);
    }

    private static List<Item> createItems() {
        List<Item> items = new ArrayList<>();
        items.add(new Item("A-001", "ボールペン（黒）", 120, false));
        items.add(new Item("A-002", "ノート A5", 280, true));
        items.add(new Item("B-010", "クリアファイル 10 枚組", 450, false));
        items.add(new Item("C-100", "デスクマット", 1980, true));
        return Collections.unmodifiableList(items);
    }

    /**
     * EL からプロパティを参照される Bean。
     *
     * <p>EL が {@code ${member.name}} で読めるのは、
     * <b>public なクラス</b>に <b>public な getter</b> があるからです
     * （フィールド名ではなく getter 名から決まります）。
     * このサンプルでは 1 ファイルに収めるため入れ子のクラスにしていますが、
     * 実際のアプリでは独立したクラスにします。</p>
     */
    public static final class Member {

        private static final DateTimeFormatter JOINED_FORMAT =
                DateTimeFormatter.ofPattern("yyyy年M月d日");

        private final String name;
        private final String department;
        private final int age;
        private final LocalDate joinedOn;
        private final List<String> skills;

        Member(String name, String department, int age, LocalDate joinedOn, List<String> skills) {
            this.name = name;
            this.department = department;
            this.age = age;
            this.joinedOn = joinedOn;
            this.skills = skills;
        }

        public String getName() {
            return name;
        }

        public String getDepartment() {
            return department;
        }

        public int getAge() {
            return age;
        }

        /**
         * メールアドレス。<b>いつも null</b> を返します。
         *
         * <p>{@code ${member.email}} が例外にならず空文字になること、
         * {@code ${empty member.email}} が true になることを画面で確かめるための
         * プロパティです。</p>
         */
        public String getEmail() {
            return null;
        }

        /**
         * 入社日。
         *
         * <p>{@code LocalDate} のままなので、JSTL の {@code fmt:formatDate} には渡せません
         * （{@code fmt:formatDate} が受け取れるのは {@code java.util.Date} と
         * {@code java.util.Calendar} だけです）。
         * 画面に出すときは下の {@link #getJoinedOnText()} を使います。</p>
         */
        public LocalDate getJoinedOn() {
            return joinedOn;
        }

        /** 画面に出す入社日。整形は Java 側で済ませておきます。 */
        public String getJoinedOnText() {
            return joinedOn == null ? "" : joinedOn.format(JOINED_FORMAT);
        }

        /** 得意分野。{@code c:forEach} と {@code fn:length} の材料です。 */
        public List<String> getSkills() {
            return skills;
        }

        @Override
        public String toString() {
            return name + "（" + department + "）";
        }
    }

    /**
     * 一覧に並べる 1 行分。
     *
     * <p>{@code sale} は boolean なので getter が {@code isSale()} になりますが、
     * EL からは型を意識せず {@code ${item.sale}} で読めます。</p>
     */
    public static final class Item {

        private final String code;
        private final String name;
        private final int price;
        private final boolean sale;

        Item(String code, String name, int price, boolean sale) {
            this.code = code;
            this.name = name;
            this.price = price;
            this.sale = sale;
        }

        public String getCode() {
            return code;
        }

        public String getName() {
            return name;
        }

        public int getPrice() {
            return price;
        }

        /** セール中かどうか（getter は is で始めます）。 */
        public boolean isSale() {
            return sale;
        }

        @Override
        public String toString() {
            return code + " " + name;
        }
    }
}
