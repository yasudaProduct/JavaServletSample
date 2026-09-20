package com.example.servletsample.samples.form;

import java.io.IOException;
import java.util.regex.Pattern;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.ValidationErrors;

/**
 * 【サンプル】入力チェック (フォーカスアウト時)。
 *
 * <p>入力欄からフォーカスが外れた時点で、その場でチェックして知らせる形のサンプルです。
 * 画面側のチェックは JavaScript が行いますが、<b>この Servlet は同じチェックをもう一度行います</b>。
 * 画面側のチェックは「早く気づいてもらうための親切」で、
 * データを受け入れてよいかどうかを決めるのはサーバ側だけだからです
 * (サーバ側だけで確かめる形は
 * {@link InputValidationServlet} のサンプル「入力チェック (バリデーション)」で扱っています)。</p>
 *
 * <h2>画面の流れ</h2>
 * <ol>
 *   <li>GET … 空のフォームを表示する</li>
 *   <li>利用者が各欄を埋める … ここは JavaScript の担当 (blur でチェック、input でエラー解除)</li>
 *   <li>POST … {@link ContactForm#from(HttpServletRequest)} で受け取り、
 *       {@link ContactForm#validate()} でもう一度すべて確かめる</li>
 *   <li>エラーがある … 入力値とエラーを持たせて同じ画面へ <b>forward</b> し、画面の上部にまとめて出す</li>
 *   <li>エラーが無い … {@link Flash} に完了メッセージを預けて <b>リダイレクト</b> する (PRG パターン)</li>
 * </ol>
 *
 * <p>画面には「JavaScript のチェックを無効にして送る」ボタンを置いてあります。
 * これは {@code form.submit()} を直接呼ぶだけのボタンです。
 * <b>{@code form.submit()} は submit イベントを発生させない</b>ので、画面側のチェックは素通りし、
 * ここに書いたサーバ側のチェックだけが働きます。
 * 「画面のチェックは迂回できる」ことを、画面上で試せるようにしたものです。</p>
 *
 * <h2>チェックの内容を 2 か所に書くことについて</h2>
 * <p>同じ規則を JavaScript と Java の両方に書くことになります。これは避けられません
 * (画面側だけにすると守れず、サーバ側だけにすると送信するまで分かりません)。
 * せめてズレにくくするために、<b>文字数の上限は Java 側の定数を画面に渡して</b>、
 * JSP の説明文にも JavaScript にも同じ値が出るようにしています
 * ({@code request.setAttribute("nameMaxLength", ...)} → {@code data-name-max} 属性)。
 * 文面もサーバ側と画面側で同じにしてあります。</p>
 */
@WebServlet(name = "realtimeValidation", urlPatterns = {"/samples/form/realtime-validation"})
public class RealtimeValidationServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/form/realtime-validation.jsp";

    private static final String PATH = "/samples/form/realtime-validation";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 送信完了後のリダイレクトで預けられたメッセージを取り出す (あれば完了モーダルが開く)
        Flash.consume(request);

        // JSP が ${form.name} / ${errors.has('name')} を常に書けるよう、空のものを入れておく
        request.setAttribute("form", ContactForm.empty());
        request.setAttribute("errors", new ValidationErrors());
        putLimits(request);

        forward(request, response, VIEW);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ① 受け取る (この時点では良し悪しを判断しない)
        ContactForm form = ContactForm.from(request);

        // ② 確かめる。画面側の JavaScript が同じチェックを済ませているはずだが、
        //    「済ませているはず」を信用しない。ここが最後の砦になる
        ValidationErrors errors = form.validate();

        if (errors.hasErrors()) {
            // ③ エラーあり : 入力値とエラーを持たせて同じ画面へ戻す。
            //    リダイレクトすると request スコープが消えるので forward を使う
            request.setAttribute("form", form);
            request.setAttribute("errors", errors);
            putLimits(request);
            forward(request, response, VIEW);
            return;
        }

        // ④ エラーなし : 本来はここでメール送信や DB への保存を行う (このサンプルでは何もしません)。
        //    完了メッセージはセッションに預けてからリダイレクトする (PRG パターン)
        Flash.set(request, "success", "お問い合わせを受け付けました",
                form.getName() + " さん (" + form.getEmail() + ") からのお問い合わせとして受け付けました。"
                        + "このサンプルでは保存も送信もしていません。");
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /**
     * 文字数の上限を画面へ渡す。
     *
     * <p>JSP の説明文 (「30 文字以内」) と、JavaScript が使う上限値を
     * <b>Java の定数 1 か所から</b>出すためのものです。
     * 画面に直接 30 と書いてしまうと、Java 側を 40 に変えたときに画面だけ 30 のまま残ります。</p>
     */
    private void putLimits(HttpServletRequest request) {
        request.setAttribute("nameMaxLength", ContactForm.NAME_MAX_LENGTH);
        request.setAttribute("messageMaxLength", ContactForm.MESSAGE_MAX_LENGTH);
    }

    /**
     * 問い合わせフォームの入力値と、その入力チェック。
     *
     * <p>Servlet API に触れているのは {@link #from(HttpServletRequest)} だけで、
     * {@link #validate()} は文字列を見ているだけです。こう分けておくと
     * <b>Tomcat を起動せずに入力チェックのテストが書けます</b>
     * ({@code src/test/java/.../RealtimeValidationServletTest.java})。</p>
     *
     * <p>画面側の JavaScript も、ここと同じ順番・同じ文面でチェックしています。
     * 「必須 → 形式 → 長さ」の順に見て、引っかかったらその項目はそこで打ち切ります。</p>
     */
    public static final class ContactForm {

        /**
         * メールアドレスの形式。
         *
         * <p>「@ の前後に空白でない文字があり、後ろ側にドットがある」程度しか見ていません。
         * 厳密な正規表現は実用にならないほど複雑で、しかも実在するアドレスを弾いてしまいます。
         * <b>本当に届くかどうかは確認メールでしか分かりません</b>。
         * ここでの狙いは打ち間違いに気づいてもらうことです。</p>
         *
         * <p>画面側の JavaScript にも同じ正規表現を書いています
         * (JavaScript の {@code \s} と Java の {@code \s} は厳密には範囲が違いますが、
         * ここで見たいのは「空白や @ が混ざっていないか」なので実害はありません)。</p>
         */
        private static final Pattern EMAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

        /**
         * 電話番号の形式 (ハイフンあり・なしの両方を許す)。
         *
         * <p>0 から始まる 10 桁か 11 桁、またはハイフンで区切った形だけを受け付けます。
         * 国番号付き ({@code +81...}) を受け付けたいなら、ここを緩めることになります。
         * <b>「何を受け付けるか」は仕様として決める話</b>で、正規表現はその結果にすぎません。</p>
         */
        private static final Pattern TEL = Pattern.compile("^0[0-9]{9,10}$|^0[0-9]{1,4}-[0-9]{1,4}-[0-9]{3,4}$");

        /** お名前の上限 (文字数)。画面にもこの値を渡している。 */
        public static final int NAME_MAX_LENGTH = 30;

        /** お問い合わせ内容の上限 (文字数)。画面にもこの値を渡している。 */
        public static final int MESSAGE_MAX_LENGTH = 200;

        private final String name;
        private final String email;
        private final String tel;
        private final String message;

        private ContactForm(String name, String email, String tel, String message) {
            this.name = name;
            this.email = email;
            this.tel = tel;
            this.message = message;
        }

        /**
         * リクエストパラメータから組み立てる (POST を受けたときに呼ぶ)。
         *
         * <p><b>受け取る</b>ことと<b>確かめる</b>ことを分けておくと、
         * 確かめる側をリクエスト無しでテストできます。</p>
         */
        public static ContactForm from(HttpServletRequest request) {
            return new ContactForm(
                    strip(request.getParameter("name")),
                    strip(request.getParameter("email")),
                    strip(request.getParameter("tel")),
                    normalizeNewlines(strip(request.getParameter("message"))));
        }

        /** 値を直接指定して組み立てる (テストと、初期表示用の空のフォームで使う)。 */
        public static ContactForm of(String name, String email, String tel, String message) {
            return new ContactForm(strip(name), strip(email), strip(tel),
                    normalizeNewlines(strip(message)));
        }

        /** 何も入力されていないフォーム (初期表示用)。 */
        public static ContactForm empty() {
            return new ContactForm("", "", "", "");
        }

        /**
         * 入力内容を確かめて、見つかったエラーを返す。
         *
         * <p>1 つの項目につきメッセージは 1 つだけです
         * ({@link ValidationErrors} が同じ項目の 2 件目を捨てます)。</p>
         */
        public ValidationErrors validate() {
            ValidationErrors errors = new ValidationErrors();

            validateName(errors);
            validateEmail(errors);
            validateTel(errors);
            validateMessage(errors);

            return errors;
        }

        /** お名前 : 必須 → 長さ。 */
        private void validateName(ValidationErrors errors) {
            if (name.isEmpty()) {
                errors.add("name", "お名前を入力してください。");
                return;
            }
            int length = lengthOf(name);
            if (length > NAME_MAX_LENGTH) {
                errors.add("name", "お名前は " + NAME_MAX_LENGTH + " 文字以内で入力してください。"
                        + "(現在 " + length + " 文字)");
            }
        }

        /** メールアドレス : 必須 → 形式。 */
        private void validateEmail(ValidationErrors errors) {
            if (email.isEmpty()) {
                errors.add("email", "メールアドレスを入力してください。");
                return;
            }
            if (!EMAIL.matcher(email).matches()) {
                errors.add("email", "メールアドレスの形式が正しくありません。(例: taro@example.com)");
            }
        }

        /**
         * 電話番号 : 任意 → 形式。
         *
         * <p>任意の項目なので、未入力はエラーにしません。
         * 画面側も同じで、空のままフォーカスを外しても何も言いません
         * (「任意なのに毎回何か言われる」と、利用者はエラー表示そのものを見なくなります)。</p>
         */
        private void validateTel(ValidationErrors errors) {
            if (tel.isEmpty()) {
                return;
            }
            if (!TEL.matcher(tel).matches()) {
                errors.add("tel", "電話番号は半角数字とハイフンで入力してください。"
                        + "(例: 09012345678 または 090-1234-5678)");
            }
        }

        /** お問い合わせ内容 : 必須 → 長さ。 */
        private void validateMessage(ValidationErrors errors) {
            if (message.isEmpty()) {
                errors.add("message", "お問い合わせ内容を入力してください。");
                return;
            }
            int length = lengthOf(message);
            if (length > MESSAGE_MAX_LENGTH) {
                errors.add("message", "お問い合わせ内容は " + MESSAGE_MAX_LENGTH + " 文字以内で入力してください。"
                        + "(現在 " + length + " 文字)");
            }
        }

        /** お名前 (画面に戻すときに使う)。 */
        public String getName() {
            return name;
        }

        /** メールアドレス (画面に戻すときに使う)。 */
        public String getEmail() {
            return email;
        }

        /** 電話番号 (入力されたまま。ハイフンの有無は問わない)。 */
        public String getTel() {
            return tel;
        }

        /** お問い合わせ内容 (改行は {@code \n} に揃えてある)。 */
        public String getMessage() {
            return message;
        }

        /**
         * お問い合わせ内容の文字数。
         *
         * <p>画面の文字数カウンタ (JavaScript) と<b>同じ数え方</b>になっていることを
         * テストで確かめるために公開しています
         * ({@code RealtimeValidationServletTest} の CRLF・サロゲートペアのテスト)。</p>
         */
        public int getMessageLength() {
            return lengthOf(message);
        }

        /**
         * 文字数を数える。
         *
         * <p>{@code String.length()} は UTF-16 の単位数を返すため、絵文字や一部の漢字 (𠮟 など) が
         * 2 文字と数えられます。「200 文字以内」と画面に書いた以上、
         * 人が数えた文字数に合わせておくのが親切です。</p>
         *
         * <p>画面側の JavaScript も同じ理由で {@code value.length} ではなく
         * {@code Array.from(value).length} で数えています。
         * 数え方が違うと「画面では残り 3 文字なのにサーバでエラー」という、
         * 利用者からは理由の分からない現象になります。</p>
         */
        private static int lengthOf(String value) {
            return value.codePointCount(0, value.length());
        }

        /**
         * 改行コードを {@code \n} に揃える。
         *
         * <p><b>textarea の中身は、送信されるときに改行が CRLF ({@code \r\n}) に変換されます</b>。
         * 一方 JavaScript から見える {@code textarea.value} の改行は LF ({@code \n}) 1 文字です。
         * そのまま数えると、改行 1 つにつきサーバ側だけ 1 文字多くなり、
         * 「画面では 200 文字ちょうどなのにサーバでは 205 文字」という食い違いが起きます。</p>
         *
         * <p>そこで数える前に揃えます。改行を多く含む問い合わせほどズレが大きくなるので、
         * 文字数制限のある textarea では必ず引っかかる種類の話です。</p>
         */
        private static String normalizeNewlines(String value) {
            return value.replace("\r\n", "\n").replace("\r", "\n");
        }

        /**
         * 前後の空白を落とす。未送信 (null) は空文字として扱う。
         *
         * <p>{@code trim()} ではなく {@code strip()} (Java 11 以降) を使っています。
         * {@code trim()} が削るのは U+0020 以下の文字だけなので、
         * <b>全角スペースだけを入力されると「空白だけなのに入力あり」</b>になってしまいます。</p>
         *
         * <p>ちなみに JavaScript の {@code String.prototype.trim()} は全角スペースも落とします。
         * 画面側とサーバ側で判定を揃えるなら、Java 側は {@code strip()} を選ぶことになります。</p>
         */
        private static String strip(String value) {
            return value == null ? "" : value.strip();
        }

        @Override
        public String toString() {
            return "ContactForm{name='" + name + "', email='" + email + "', tel='" + tel
                    + "', messageLength=" + lengthOf(message) + "}";
        }
    }
}
