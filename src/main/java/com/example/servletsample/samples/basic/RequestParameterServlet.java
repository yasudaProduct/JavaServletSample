package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】リクエストパラメータ (画面から送られてきた値) の受け取り方。
 *
 * <p>画面の入力を受け取る入り口は、次の 3 つだけです。</p>
 * <table border="1">
 *   <caption>値を取り出す 3 つのメソッド</caption>
 *   <tr><th>メソッド</th><th>戻り値</th><th>使いどころ</th></tr>
 *   <tr>
 *     <td>{@code getParameter(name)}</td>
 *     <td>{@code String} (無ければ {@code null})</td>
 *     <td>ふつうの入力項目。値が複数あっても<b>先頭の 1 つ</b>しか返らない</td>
 *   </tr>
 *   <tr>
 *     <td>{@code getParameterValues(name)}</td>
 *     <td>{@code String[]} (無ければ {@code null})</td>
 *     <td>チェックボックスなど、同じ名前で複数送られる項目</td>
 *   </tr>
 *   <tr>
 *     <td>{@code getParameterMap()}</td>
 *     <td>{@code Map<String, String[]>} (変更不可)</td>
 *     <td>「実際に何が届いたのか」を確かめたいとき。デバッグで役に立つ</td>
 *   </tr>
 * </table>
 *
 * <p>どれも戻り値は {@code String} であり、型変換と検査はこちらの責任です。
 * URL もフォームも利用者が自由に書き換えられるので、
 * <b>「送られてくるはずの値」は当てにしない</b>という前提で書きます。</p>
 *
 * <p>この Servlet は受け取った値を加工せず、そのまま画面に並べるための
 * 表示用オブジェクト ({@link ParameterRow} / {@link NumberResult}) に詰め替えるだけです。</p>
 */
@WebServlet(name = "requestParameter", urlPatterns = {"/samples/basic/request-parameter"})
public class RequestParameterServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/basic/request-parameter.jsp";

    /**
     * どのフォームから送信されたかを見分けるための hidden。
     *
     * <p>GET は「まだ何も送っていない最初の表示」と「空欄のまま送信した」を
     * 区別できないため、送信した事実そのものを hidden で伝えます。</p>
     */
    private static final String FORM_MARKER = "form";

    /** 表示件数の既定値。数値に変換できなかったときはこの値で続けます。 */
    static final int DEFAULT_SIZE = 10;

    /** 表示件数の上限。利用者は何でも送れるので、こちらで範囲を決めておきます。 */
    static final int MAX_SIZE = 100;

    /** チェックボックスに添える hidden の値 (「チェックされていない」を表す)。 */
    static final String CHECKBOX_OFF = "off";

    /** チェックボックス本体の値 (「チェックされた」を表す)。 */
    static final String CHECKBOX_ON = "on";

    /** GET フォームの項目 : {パラメータ名, 画面に出す説明}。 */
    private static final String[][] GET_FIELDS = {
            {FORM_MARKER, "送信元のフォーム（hidden）"},
            {"keyword", "キーワード（テキスト）"},
            {"size", "表示件数（テキスト。数値に変換して使う）"},
    };

    /** POST フォームの項目 : {パラメータ名, 画面に出す説明}。 */
    private static final String[][] POST_FIELDS = {
            {FORM_MARKER, "送信元のフォーム（hidden）"},
            {"name", "氏名（テキスト）"},
            {"gender", "性別（ラジオボタン）"},
            {"interests", "興味のある分野（チェックボックス・複数）"},
            {"pref", "都道府県（セレクト）"},
            {"memo", "自由記述（テキストエリア）"},
            {"newsletter", "メール配信（チェックボックス + 同じ名前の hidden）"},
    };

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // GET のパラメータは URL のクエリ文字列 (?keyword=...) から取れる。
        // 最初の表示と「空欄のまま検索した」は hidden の有無で見分ける。
        boolean submitted = request.getParameter(FORM_MARKER) != null;
        buildModel(request, GET_FIELDS, submitted);
        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // POST 本文の文字コードは web.xml の <request-character-encoding>UTF-8</...> で
        // 指定済み (Servlet 4.0 の機能)。この指定が無いコンテナでは、
        // getParameter を 1 回でも呼ぶ前に request.setCharacterEncoding("UTF-8") が必要。
        // ※ 一度でも値を読んだあとに設定しても手遅れ (もう解析が済んでいる) なので、
        //   doPost の先頭に書くか、フィルタでまとめて設定する。
        buildModel(request, POST_FIELDS, true);
        forward(request, response, VIEW);
    }

    /**
     * 受け取った値を画面用に詰め替えて、リクエストスコープへ入れる。
     *
     * @param fields    表に並べる項目 (GET と POST で入力欄が違うので切り替える)
     * @param submitted フォームから送信された結果の表示かどうか
     */
    private void buildModel(HttpServletRequest request, String[][] fields, boolean submitted) {

        // ------------------------------------------------------------------
        // ① getParameter / ② getParameterValues : 名前を指定して取り出す
        // ------------------------------------------------------------------
        List<ParameterRow> rows = new ArrayList<>();
        for (String[] field : fields) {
            rows.add(ParameterRow.read(request, field[0], field[1]));
        }
        request.setAttribute("paramRows", rows);

        // ------------------------------------------------------------------
        // ③ getParameterMap : 名前を知らなくても「届いたもの全部」を見られる
        //    戻り値は変更不可の Map。put しようとすると例外になる。
        // ------------------------------------------------------------------
        List<ParameterRow> mapRows = new ArrayList<>();
        for (Map.Entry<String, String[]> entry : request.getParameterMap().entrySet()) {
            mapRows.add(ParameterRow.fromMap(entry.getKey(), entry.getValue()));
        }
        request.setAttribute("mapRows", mapRows);

        // ------------------------------------------------------------------
        // 数値への変換 : 例外で落とさず、既定値で続ける
        // ------------------------------------------------------------------
        request.setAttribute("sizeResult", parseSize(request.getParameter("size")));

        // ------------------------------------------------------------------
        // チェックボックス + hidden の正しい読み方 (最後に届いた値を見る)
        // ------------------------------------------------------------------
        request.setAttribute("newsletterChecked",
                checkedByLastValue(request.getParameterValues("newsletter")));

        // ------------------------------------------------------------------
        // 画面の説明に使うリクエスト自体の情報
        //   forward したあとの JSP から getQueryString() を呼ぶと、転送先 (JSP) の
        //   クエリ文字列が返るため、元の値はここで取っておく。
        // ------------------------------------------------------------------
        request.setAttribute("submitted", submitted);
        request.setAttribute("formName", text(request.getParameter(FORM_MARKER)));
        request.setAttribute("requestMethod", request.getMethod());
        request.setAttribute("queryStringText", text(request.getQueryString()));
        request.setAttribute("contentTypeText", text(request.getContentType()));
        request.setAttribute("encodingText", text(request.getCharacterEncoding()));
    }

    /**
     * 文字列を数値に変換する。変換できなければ既定値で続ける。
     *
     * <p>利用者は <code>?size=abc</code> でも <code>?size=-1</code> でも送れます。
     * {@code Integer.parseInt} は変換できないと {@link NumberFormatException} を投げるので、
     * 受け取った直後にここで受け止めてしまい、後ろの処理には正しい値だけを渡します。</p>
     */
    static NumberResult parseSize(String raw) {
        if (raw == null) {
            return new NumberResult(null, DEFAULT_SIZE, false,
                    "パラメータ自体が届いていません。既定値の " + DEFAULT_SIZE + " 件で続けます。");
        }

        // 前後の空白は落とす。" 10" は Integer.parseInt では失敗するため。
        String trimmed = raw.trim();
        if (trimmed.isEmpty()) {
            return new NumberResult(raw, DEFAULT_SIZE, false,
                    "空文字でした。既定値の " + DEFAULT_SIZE + " 件で続けます。");
        }

        try {
            int parsed = Integer.parseInt(trimmed);
            if (parsed < 1) {
                return new NumberResult(raw, 1, false, "1 より小さい値でした。1 件に丸めました。");
            }
            if (parsed > MAX_SIZE) {
                return new NumberResult(raw, MAX_SIZE, false,
                        MAX_SIZE + " 件より大きい値でした。" + MAX_SIZE + " 件に丸めました。");
            }
            return new NumberResult(raw, parsed, true, "数値として受け取れました。");
        } catch (NumberFormatException e) {
            // 数字以外・小数・int に収まらない桁数は、すべてここに来る。
            // 逆に全角数字の「１０」は Integer.parseInt が 10 として受け取るので、ここには来ない。
            // (内部で使われる Character.digit が全角数字も数字とみなすため)
            // 「変換できた = 正しい値」ではないので、範囲の検査は変換とは別に行う。
            // 500 エラーにせず、画面に理由を出して既定値で続けるのが親切。
            return new NumberResult(raw, DEFAULT_SIZE, false,
                    "数値として読めませんでした（NumberFormatException）。既定値の "
                            + DEFAULT_SIZE + " 件で続けます。");
        }
    }

    /**
     * 「hidden → チェックボックス」の順で同じ名前を並べたときの、チェック状態の読み方。
     *
     * <p>チェックされていれば {@code ["off", "on"]}、されていなければ {@code ["off"]} が届きます。
     * {@code getParameter} は先頭の {@code "off"} しか返さないので、
     * <b>最後の値</b>を見るのがこの書き方の作法です。</p>
     */
    static boolean checkedByLastValue(String[] values) {
        if (values == null || values.length == 0) {
            return false;
        }
        return CHECKBOX_ON.equals(values[values.length - 1]);
    }

    /** null を画面に出しても困らないよう空文字にする。 */
    private static String text(String value) {
        return value == null ? "" : value;
    }

    // ======================================================================
    // 画面表示用のオブジェクト
    // (EL から ${row.state} のように読めるよう、getter を持つ普通のクラスにする。
    //  record は getXxx() ではなく xxx() になるため、EL からは読めない)
    // ======================================================================

    /** パラメータ 1 件分の、getParameter と getParameterValues の結果。 */
    public static class ParameterRow {

        private final String name;
        private final String label;
        /** getParameter の結果。パラメータが無ければ null。 */
        private final String value;
        /** getParameterValues の結果。null のときは空リストにしてある。 */
        private final List<String> values;

        private ParameterRow(String name, String label, String value, String[] values) {
            this.name = name;
            this.label = label;
            this.value = value;
            this.values = values == null
                    ? Collections.emptyList()
                    : Collections.unmodifiableList(Arrays.asList(values));
        }

        /** 名前を指定してリクエストから読み取る。 */
        static ParameterRow read(HttpServletRequest request, String name, String label) {
            return new ParameterRow(name, label,
                    request.getParameter(name), request.getParameterValues(name));
        }

        /** getParameterMap の 1 エントリから作る (先頭の値が getParameter と同じ結果になる)。 */
        static ParameterRow fromMap(String name, String[] values) {
            String first = (values == null || values.length == 0) ? null : values[0];
            return new ParameterRow(name, "", first, values);
        }

        public String getName() {
            return name;
        }

        public String getLabel() {
            return label;
        }

        public String getValue() {
            return value;
        }

        public List<String> getValues() {
            return values;
        }

        /** パラメータそのものが届いたか。 */
        public boolean isSent() {
            return value != null;
        }

        /** 「届いていない」「空文字」「値あり」の 3 状態。ここを区別できることが大事。 */
        public String getState() {
            if (value == null) {
                return "届いていない";
            }
            if (value.isEmpty()) {
                return "空文字";
            }
            return "値あり";
        }

        /** 状態に応じた Bootstrap の色 (badge-xxx に使う)。 */
        public String getStateVariant() {
            if (value == null) {
                return "secondary";
            }
            if (value.isEmpty()) {
                return "warning";
            }
            return "success";
        }

        /** getParameter の結果を、null と空文字が見分けられる形の文字列にする。 */
        public String getValueText() {
            if (value == null) {
                return "null";
            }
            if (value.isEmpty()) {
                return "\"\"";
            }
            return value;
        }

        /** getParameterValues の結果を {@code ["java", "db"]} の形の文字列にする。 */
        public String getValuesText() {
            if (values.isEmpty()) {
                return "null";
            }
            StringBuilder builder = new StringBuilder("[");
            for (int i = 0; i < values.size(); i++) {
                if (i > 0) {
                    builder.append(", ");
                }
                builder.append('"').append(values.get(i)).append('"');
            }
            return builder.append(']').toString();
        }

        /** 文字数 (届いていなければ -1)。空文字なら 0 になる。 */
        public int getLength() {
            return value == null ? -1 : value.length();
        }

        /** 届いた値の個数。 */
        public int getValueCount() {
            return values.size();
        }

        /** 同じ名前で複数届いたか (getParameter では 1 つ目しか取れない状態)。 */
        public boolean isMultiple() {
            return values.size() > 1;
        }
    }

    /** 文字列を数値に変換した結果。失敗の理由も画面に出せるように持っておく。 */
    public static class NumberResult {

        private final String raw;
        private final int value;
        private final boolean valid;
        private final String message;

        NumberResult(String raw, int value, boolean valid, String message) {
            this.raw = raw;
            this.value = value;
            this.valid = valid;
            this.message = message;
        }

        /** 受け取った生の文字列。 */
        public String getRaw() {
            return raw;
        }

        /** null と空文字を見分けられる形にした、受け取った文字列。 */
        public String getRawText() {
            if (raw == null) {
                return "null";
            }
            if (raw.isEmpty()) {
                return "\"\"";
            }
            return raw;
        }

        /** 実際に使う値 (変換できなければ既定値・範囲内に丸めた値)。 */
        public int getValue() {
            return value;
        }

        /** そのまま数値として使えたか。 */
        public boolean isValid() {
            return valid;
        }

        /** 何が起きたかの説明。 */
        public String getMessage() {
            return message;
        }

        /** 表示に使う Bootstrap の色。 */
        public String getVariant() {
            return valid ? "success" : "warning";
        }
    }
}
