package com.example.servletsample.samples.a11y;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.OptionalInt;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】エラーを「見える人にも、見えない人にも」伝える。
 *
 * <p>入力チェックそのもののやり方は
 * {@code samples/form/input-validation}（サーバ側の検証）と
 * {@code samples/form/validation-rules}（チェックの種類）にまとめてあります。
 * こちらは<b>チェックの結果をどう画面に出すか</b>だけを扱います。</p>
 *
 * <h2>サーバ側でやること</h2>
 * <p>エラーの伝え方で大事なのは、画面の先頭に<b>エラーの一覧（エラーサマリ）</b>を出し、
 * そこから各項目へ飛べるようにすることです。そのために Servlet からは次の 3 つを渡します。</p>
 * <ol>
 *   <li>{@code errors} … どの項目に、どんなメッセージが出たか（登録順）</li>
 *   <li>{@code fieldIds} … 項目名 → 入力欄の {@code id}。サマリから
 *       {@code <a href="#esName">} で飛ぶために必要です</li>
 *   <li>{@code fieldLabels} … 項目名 → 画面に出している項目名。
 *       メッセージだけでは「どの欄の話か」が分からないためです</li>
 * </ol>
 *
 * <p>2 と 3 を JSP に直接書かずにここへ置いているのは、<b>メッセージの並び順を
 * 画面の並び順と一致させる</b>ためです。読み上げで上から順に聞いていく人にとって、
 * サマリの順番と欄の順番が違うのは、そのまま迷子になる原因になります。</p>
 *
 * <h2>エラー時に forward、成功時にリダイレクト</h2>
 * <p>エラー時は入力値をそのまま画面へ返したいので {@code forward}、
 * 成功後は再読み込みで二重送信されないように {@code sendRedirect} にしています（PRG パターン）。</p>
 */
@WebServlet(name = "a11yErrorSummary", urlPatterns = {"/samples/a11y/error-summary"})
public class ErrorSummaryServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/a11y/error-summary.jsp";

    private static final String PATH = "/samples/a11y/error-summary";

    /** 項目名 → 入力欄の id。エラーサマリのリンク先 (#…) に使います。 */
    private static final Map<String, String> FIELD_IDS = new LinkedHashMap<>();

    /** 項目名 → 画面に出している項目名。メッセージの先頭に付けて読み上げます。 */
    private static final Map<String, String> FIELD_LABELS = new LinkedHashMap<>();

    static {
        // 入れた順がエラーサマリの並び順になります (画面の並び順と同じにしておきます)
        FIELD_IDS.put("name", "esName");
        FIELD_IDS.put("email", "esEmail");
        FIELD_IDS.put("quantity", "esQuantity");
        FIELD_IDS.put("wantedOn", "esWantedOn");

        FIELD_LABELS.put("name", "氏名");
        FIELD_LABELS.put("email", "メールアドレス");
        FIELD_LABELS.put("quantity", "数量");
        FIELD_LABELS.put("wantedOn", "希望日");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 送信が成功したあとのリダイレクトで預けられたメッセージを取り出す
        Flash.consume(request);

        setCommonAttributes(request);
        request.setAttribute("form", emptyForm());
        request.setAttribute("errors", new ValidationErrors());
        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Map<String, String> form = readForm(request);
        ValidationErrors errors = validate(form);

        setCommonAttributes(request);

        if (errors.hasErrors()) {
            // 入力値を持たせて同じ画面へ戻す。
            // JSP 側はこの errors を見て、エラーサマリと各欄の赤枠を出します。
            request.setAttribute("form", form);
            request.setAttribute("errors", errors);
            forward(request, response, VIEW);
            return;
        }

        // 成功。本来はここで登録します (このサンプルでは保存しません)。
        Flash.set(request, "success", "送信しました",
                form.get("name") + " さんの依頼を受け付けました。このサンプルでは保存はしていません。");
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /** 画面がエラーサマリを組み立てるのに使う対応表を渡す。 */
    private void setCommonAttributes(HttpServletRequest request) {
        request.setAttribute("fieldIds", FIELD_IDS);
        request.setAttribute("fieldLabels", FIELD_LABELS);
    }

    private Map<String, String> emptyForm() {
        Map<String, String> form = new LinkedHashMap<>();
        for (String field : FIELD_IDS.keySet()) {
            form.put(field, "");
        }
        return form;
    }

    /** リクエストから値を取り出す (この時点では良し悪しを判断しない)。 */
    private Map<String, String> readForm(HttpServletRequest request) {
        Map<String, String> form = new LinkedHashMap<>();
        for (String field : FIELD_IDS.keySet()) {
            form.put(field, Validators.strip(request.getParameter(field)));
        }
        return form;
    }

    /**
     * 入力チェック。
     *
     * <p>メッセージは <b>「何がだめか」と「どうすれば直るか」の両方</b>を書きます。
     * 「不正な値です」では、利用者は次に何をすればよいか分かりません。</p>
     *
     * <p>また、先頭に項目名を入れているのは、エラーサマリで読み上げられたときに
     * それだけで意味が通るようにするためです。</p>
     */
    private ValidationErrors validate(Map<String, String> form) {
        ValidationErrors errors = new ValidationErrors();

        String name = form.get("name");
        if (Validators.isBlank(name)) {
            errors.add("name", "氏名を入力してください。");
        } else if (!Validators.isLengthAtMost(name, 20)) {
            errors.add("name", "氏名は 20 文字以内で入力してください。（現在 "
                    + Validators.length(name) + " 文字）");
        }

        String email = form.get("email");
        if (Validators.isBlank(email)) {
            errors.add("email", "メールアドレスを入力してください。");
        } else if (!email.matches("[^@\\s]+@[^@\\s]+\\.[^@\\s]+")) {
            errors.add("email", "メールアドレスは taro@example.com の形式で入力してください。");
        }

        String quantity = form.get("quantity");
        if (Validators.isBlank(quantity)) {
            errors.add("quantity", "数量を入力してください。");
        } else {
            OptionalInt parsed = Validators.toInt(quantity);
            if (!parsed.isPresent()) {
                errors.add("quantity", "数量は半角数字で入力してください。");
            } else if (parsed.getAsInt() < 1 || parsed.getAsInt() > 99) {
                errors.add("quantity", "数量は 1 以上 99 以下で入力してください。");
            }
        }

        String wantedOn = form.get("wantedOn");
        if (Validators.isBlank(wantedOn)) {
            errors.add("wantedOn", "希望日を入力してください。");
        } else if (!Validators.toDate(wantedOn).isPresent()) {
            errors.add("wantedOn", "希望日は実在する日付を入力してください。");
        }

        return errors;
    }
}
