package com.example.servletsample.samples.advanced;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.Enumeration;
import java.util.List;
import java.util.Locale;
import java.util.MissingResourceException;
import java.util.ResourceBundle;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】国際化 (多言語表示)。
 *
 * <p>国際化 (i18n) でやることは、突き詰めると次の 2 つです。</p>
 * <ol>
 *   <li>画面に出す文字を JSP から追い出し、言語ごとのファイル ({@code .properties}) にまとめる</li>
 *   <li>「今回はどの言語で出すか」(ロケール) を決めて、それに合うファイルを選ぶ</li>
 * </ol>
 *
 * <h2>ロケールの決め方</h2>
 * <p>この Servlet は次の順で決めています。実際のアプリでもほぼこの形です。</p>
 * <ol>
 *   <li>画面で選ばれた言語 (セッションに覚えておく) … 利用者の意思がいちばん強い</li>
 *   <li>ブラウザの設定 ({@code Accept-Language} ヘッダ) … {@code request.getLocale()} で読める</li>
 *   <li>それも無ければアプリの既定</li>
 * </ol>
 *
 * <p>ログイン機能があるアプリなら、1 のさらに手前に「利用者マスタに登録された言語」が入ります。
 * セッションに持つと、ログインし直すと消えてしまうためです。</p>
 *
 * <h2>言語だけでなく国も指定する</h2>
 * <p>{@code Locale.JAPAN} ({@code ja_JP}) のように<b>国まで</b>指定しているのは、
 * 通貨や日付の書式が国で決まるためです。
 * {@code new Locale("en")} のように言語だけだと、通貨記号が決まりません。</p>
 *
 * <table border="1">
 *   <caption>同じ値のロケールごとの見え方</caption>
 *   <tr><th>ロケール</th><th>金額</th><th>日付</th></tr>
 *   <tr><td>{@code ja_JP}</td><td>￥12,345</td><td>2026/09/20</td></tr>
 *   <tr><td>{@code en_US}</td><td>$12,345.00</td><td>9/20/26</td></tr>
 *   <tr><td>{@code fr_FR}</td><td>12 345,00 €</td><td>20/09/2026</td></tr>
 * </table>
 *
 * <p>小数点が {@code .} か {@code ,} か、桁区切りがどちらか、という違いまであります。
 * <b>自分で文字列を組み立てず、必ず書式化の仕組みに任せてください。</b></p>
 */
@WebServlet(name = "i18n", urlPatterns = {"/samples/advanced/i18n"})
public class I18nServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/advanced/i18n.jsp";

    /** 選ばれた言語を覚えておくセッション属性名。 */
    static final String SESSION_KEY = "i18nSample.lang";

    /** メッセージをまとめた properties のベース名 ({@code WEB-INF/classes/messages*.properties})。 */
    static final String BUNDLE_BASE_NAME = "messages";

    /** 画面で選べる言語。"" はブラウザの設定に従う。 */
    static final List<String> SELECTABLE = List.of("", "ja", "en", "fr");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ------------------------------------------------ ① 言語の選択を受け取って覚える
        String selected = selectedLang(request);

        // ------------------------------------------------ ② 今回のロケールを決める
        Locale locale = selected.isEmpty()
                // ブラウザの設定 (Accept-Language ヘッダ)。ヘッダが無ければコンテナの既定が返る
                ? request.getLocale()
                : toLocale(selected);

        // レスポンスヘッダ Content-Language に入る。
        // 「この応答は何語か」を中継サーバやブラウザに伝えるためのものです
        response.setLocale(locale);

        // setLocale は「その言語で普通に使われる文字コード」を勝手に選ぶことがあります
        // (Tomcat の既定では ja → Shift_JIS、fr → ISO-8859-1)。
        // 文字化けの原因になるので、UTF-8 を明示して打ち消しておきます
        response.setCharacterEncoding("UTF-8");

        // ------------------------------------------------ ③ 画面へ渡す
        request.setAttribute("selectedLang", selected);
        request.setAttribute("locale", locale);
        request.setAttribute("acceptLanguage", header(request, "Accept-Language"));
        request.setAttribute("browserLocales", browserLocales(request));

        // 実際に選ばれた properties のロケール。
        // 「ja を頼んだのに英語が出る」ときは、ここを見ると原因が分かります
        request.setAttribute("bundleLocale", bundleLocaleOf(locale));
        request.setAttribute("jvmDefaultLocale", Locale.getDefault());

        // 書式化して見せるための値。数値と日付は「値のまま」渡し、
        // 見た目を整えるのは JSP (fmt タグ) の仕事にします
        // 見比べ用のロケール一覧 (画面の比較表で使う)
        request.setAttribute("sampleLocales", List.of(Locale.JAPAN, Locale.US, Locale.FRANCE));

        request.setAttribute("now", new Date());
        request.setAttribute("amount", 12345);
        request.setAttribute("quantity", 1234.5);
        request.setAttribute("orderCount", 3);
        request.setAttribute("userName", selected.equals("ja") || selected.isEmpty()
                ? "山田" : "Yamada");

        forward(request, response, VIEW);
    }

    /**
     * 選ばれた言語を決める。
     *
     * <p>パラメータで指定されていればそれをセッションに覚え、
     * 指定が無ければ覚えてある値を使います。
     * 「1 回選んだら、次のページでもその言語で出る」ようにするためです。</p>
     *
     * @return {@code "ja"} / {@code "en"} / {@code "fr"} のいずれか。ブラウザ設定に従う場合は {@code ""}
     */
    private String selectedLang(HttpServletRequest request) {
        String param = request.getParameter("lang");
        if (param != null) {
            // 外から来た文字列をそのままロケールにしない。
            // 用意してある言語だけを通す (ホワイトリスト方式)
            String lang = SELECTABLE.contains(param) ? param : "";
            request.getSession().setAttribute(SESSION_KEY, lang);
            return lang;
        }
        HttpSession session = request.getSession(false);
        if (session == null) {
            return "";
        }
        Object saved = session.getAttribute(SESSION_KEY);
        return saved instanceof String && SELECTABLE.contains(saved) ? (String) saved : "";
    }

    /**
     * 言語コードを {@link Locale} に直す。
     *
     * <p>国まで指定しているのは、通貨や日付の書式が国で決まるためです。</p>
     */
    static Locale toLocale(String lang) {
        switch (lang) {
            case "ja":
                return Locale.JAPAN;        // ja_JP
            case "en":
                return Locale.US;           // en_US
            case "fr":
                return Locale.FRANCE;       // fr_FR
            default:
                return Locale.getDefault();
        }
    }

    /**
     * 頼んだロケールに対して、実際に読み込まれた properties のロケールを返す。
     *
     * <p>{@code messages_fr.properties} を用意していないのに {@code fr_FR} を頼むと、
     * ここには {@code fr_FR} 以外 (JVM の既定ロケール、または「言語指定なし」を表す
     * {@link Locale#ROOT}) が返ります。
     * 「ちゃんと切り替えたつもりなのに文字が変わらない」ときの確認に使えます。</p>
     *
     * @return 実際に読み込まれたロケール。properties が 1 つも見つからなければ {@code null}
     */
    static Locale bundleLocaleOf(Locale locale) {
        try {
            return ResourceBundle.getBundle(BUNDLE_BASE_NAME, locale).getLocale();
        } catch (MissingResourceException e) {
            // 既定の messages.properties すら無い場合。設定の誤りなので画面で気付けるようにする
            return null;
        }
    }

    /** ブラウザが送ってきたロケールを、優先度の高い順に並べる。 */
    private static List<String> browserLocales(HttpServletRequest request) {
        List<String> locales = new ArrayList<>();
        // getLocales() は Accept-Language を優先度 (q 値) の順に並べ替えて返してくれる
        Enumeration<Locale> enumeration = request.getLocales();
        while (enumeration.hasMoreElements()) {
            locales.add(enumeration.nextElement().toLanguageTag());
        }
        return Collections.unmodifiableList(locales);
    }

    /** ヘッダを取り出す。無ければ空文字。 */
    private static String header(HttpServletRequest request, String name) {
        String value = request.getHeader(name);
        return value == null ? "" : value;
    }
}
