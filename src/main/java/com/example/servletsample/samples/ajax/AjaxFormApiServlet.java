package com.example.servletsample.samples.ajax;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;
import java.util.regex.Pattern;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Json;
import com.example.servletsample.common.ValidationErrors;

/**
 * 【サンプル】Ajax で送られてきた問い合わせフォームを受け取る JSON API。
 *
 * <p>画面 ({@link AjaxFormServlet} が表示する JSP) の {@code fetch} が POST してくる先です。
 * HTML ではなく<b>結果だけ</b>を JSON で返し、画面は切り替えません。</p>
 *
 * <pre>{@code
 * ［送信ボタン］ JavaScript ──POST /samples/ajax/ajax-form/api──→ この Servlet
 *                            ←── 200 {"ok":true,"receipt":"A-0001"} ──
 *                            ←── 400 {"ok":false,"errors":{"name":"…"}} ──
 *               ※ どちらの場合もブラウザは画面を捨てない。入力値もそのまま残る
 * }</pre>
 *
 * <h2>返すもの</h2>
 * <table border="1">
 *   <caption>応答</caption>
 *   <tr><th>状況</th><th>HTTP</th><th>本文</th></tr>
 *   <tr><td>受け付けた</td><td>200</td>
 *       <td>{@code {"ok":true,"receipt":"A-0001","message":"…"}}</td></tr>
 *   <tr><td>入力に誤りがある</td><td>400</td>
 *       <td>{@code {"ok":false,"errors":{"name":"…","mail":"…"}}}</td></tr>
 *   <tr><td>POST 以外で呼ばれた</td><td>405</td>
 *       <td>{@code {"ok":false,"message":"…"}}</td></tr>
 * </table>
 *
 * <p>エラーのときも<b>本文は JSON のまま</b>返します。
 * {@code response.sendError(400)} を使うとコンテナのエラーページ (HTML) が本文になり、
 * 画面側が {@code res.json()} で読もうとして例外になります。</p>
 *
 * <h2>画面側のチェックがあっても、ここで必ず確かめる</h2>
 * <p>この URL は<b>誰でも直接叩けます</b>。ブラウザの開発者ツールからでも
 * {@code curl -d "name=&mail=" …} からでも、画面を通さずに POST できます。
 * 「画面の JavaScript がチェック済みのはず」という前提は成り立ちません。
 * とくに<b>セレクトボックスの値</b>は、画面に並べた選択肢以外が送られてくる前提で、
 * 受け付けてよい値かどうかを {@link InquiryForm#TYPES} との突き合わせで確かめています。</p>
 *
 * <h2>このサンプルで省いていること</h2>
 * <p><b>CSRF 対策 (ワンタイムトークンの検証) を省いています。</b>
 * 実務では、画面を表示するときにトークンを発行してセッションに覚えておき、
 * POST されたトークンと突き合わせて、一致しなければ 403 で断ります。
 * ここでは「非同期でフォームを送る流れ」に集中するために省略しています。
 * 保存も送信もしていません (受付番号を採番して返すだけです)。</p>
 */
@WebServlet(name = "ajaxFormApi", urlPatterns = {"/samples/ajax/ajax-form/api"})
public class AjaxFormApiServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /**
     * この API の URL。
     *
     * <p>画面へ渡して {@code fetch} の送り先にします。
     * {@code @WebServlet} に書いた文字列と同じものですが、
     * アノテーションの値には定数しか書けないため 2 か所に同じ文字列が並びます。</p>
     */
    static final String PATH = "/samples/ajax/ajax-form/api";

    /** 受付時刻の書式 ({@link DateTimeFormatter} は変更できないので共有して安全)。 */
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * 「同じ内容の送信」とみなす時間 (ミリ秒)。
     *
     * <p>この時間内に<b>まったく同じ内容</b>が届いたら、新しく採番せずに
     * 前回と同じ受付番号を返します。二重送信でデータが 2 件できるのを防ぐためです。</p>
     */
    static final long DUPLICATE_WINDOW_MILLIS = 10_000L;

    /**
     * 受付番号の連番。
     *
     * <p>Servlet のインスタンスはアプリ全体で 1 つ、そこへ複数のスレッドが同時に入ってきます。
     * 素の {@code long} で {@code ++} すると、重なったときに同じ番号を 2 人に渡してしまいます。
     * {@link AtomicLong} なら「1 つ増やして、増えた後の値を受け取る」が途中で割り込まれません。</p>
     *
     * <p>アプリを再起動すると 1 番に戻ります。実務では採番テーブルや
     * データベースの採番 (IDENTITY / SEQUENCE) を使います。</p>
     */
    private final AtomicLong receiptSequence = new AtomicLong();

    /** 二重送信を見つけるための、直前の受付の記録。 */
    private final DuplicateGuard duplicateGuard = new DuplicateGuard(DUPLICATE_WINDOW_MILLIS);

    /**
     * 問い合わせを受け付ける。
     *
     * <p>データを増やす処理なので POST です。GET にすると、ブラウザの先読みや
     * クローラがアクセスしただけで受け付けてしまいます。</p>
     *
     * <p>処理の順番は「① 受け取る → ② 確かめる → ③ 二重送信を見る → ④ JSON を返す」です。</p>
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 受付の結果を中継サーバやブラウザにキャッシュさせない
        response.setHeader("Cache-Control", "no-store");

        // ① 受け取る (この時点では良し悪しを判断しない)。
        //    POST の本文が UTF-8 として読まれるのは web.xml の
        //    <request-character-encoding>UTF-8</request-character-encoding> のおかげです。
        //    これが無い環境では、getParameter を呼ぶ前に
        //    request.setCharacterEncoding("UTF-8") が必要です (呼んだ後では手遅れです)
        InquiryForm form = InquiryForm.from(request);

        // ② 確かめる。画面側の JavaScript も同じことをしているが、「しているはず」を信用しない。
        //    この API は URL さえ分かれば画面を通さずに叩けるため、ここが最後の砦になる
        ValidationErrors errors = form.validate();

        if (errors.hasErrors()) {
            // 入力の誤りは 400 (Bad Request)。
            // 「受け取ったが内容が悪くて処理できなかった」ことを、ステータスでも伝えます
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            Json.write(response, errorPayload(errors));
            return;
        }

        // ③ 二重送信を見る。ボタンを押せなくするのは画面側の工夫で、
        //    通信が途中で切れて利用者が押し直した場合などは、ここに 2 回届きます
        String key = fingerprint(request.getSession().getId(), form);
        DuplicateGuard.Result accepted =
                duplicateGuard.accept(key, System.currentTimeMillis(), this::issueReceipt);

        // ④ 受け付けた内容を JSON で返す。
        //    本来はこの手前で DB への保存やメール送信を行います (このサンプルでは何もしません)
        Json.write(response, successPayload(form, accepted));
    }

    /**
     * GET で叩かれたときの応答。
     *
     * <p>「このフォームは GET では受け付けない」ことを 405 (Method Not Allowed) で伝えます。
     * {@code Allow} ヘッダーに使えるメソッドを書くのが作法です。</p>
     *
     * <p>ここで {@code response.sendError(405)} を使うと、本文がコンテナのエラーページ (HTML) に
     * なってしまいます。API では {@code setStatus} と自前の JSON のほうが扱いやすくなります。</p>
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        response.setHeader("Allow", "POST");
        Json.write(response, Json.object()
                .put("ok", false)
                .put("status", HttpServletResponse.SC_METHOD_NOT_ALLOWED)
                .put("message", "この URL は POST でだけ受け付けます。"));
    }

    // ----------------------------------------------------------------------
    // 返す JSON の組み立て (Servlet API に触れないので、そのままテストできる)
    // ----------------------------------------------------------------------

    /**
     * 入力エラーを返す JSON を組み立てる。
     *
     * <p>大事なのは {@code errors} を<b>「項目名をキーにしたオブジェクト」</b>にすることです。</p>
     * <pre>{@code
     * {"ok":false,"status":400,"message":"…",
     *  "errors":{"name":"お名前を入力してください。","mail":"メールアドレスの形式が…"}}
     * }</pre>
     *
     * <p>キーは画面の入力欄と 1 対 1 で対応するので、受け取った JavaScript は
     * 「キーから対象の欄を探して、そこにメッセージを出す」だけで済みます。
     * これを {@code ["お名前を入力してください。", "…"]} のような<b>配列</b>にすると、
     * どの欄のエラーなのかが分からなくなり、画面の上にまとめて出すことしかできません。</p>
     *
     * <p>{@link ValidationErrors} は入れた順を覚えているので、
     * JSON のキーの順番も画面の項目の並び順と同じになります
     * (JavaScript の {@code Object.keys()} もその順で返すため、
     * 「最初のエラー項目へフォーカスを移す」といった処理が素直に書けます)。</p>
     */
    Json.JsonObject errorPayload(ValidationErrors errors) {
        Json.JsonObject fields = Json.object();
        for (Map.Entry<String, String> entry : errors.getFields().entrySet()) {
            fields.put(entry.getKey(), entry.getValue());
        }
        return Json.object()
                .put("ok", false)
                .put("status", HttpServletResponse.SC_BAD_REQUEST)
                .put("message", "入力内容を確認してください。")
                .put("errorCount", errors.getCount())
                .put("errors", fields);
    }

    /**
     * 受け付けたことを返す JSON を組み立てる。
     *
     * <p>{@code received} には<b>サーバが実際に受け取った値</b>を入れています。
     * 画面が送ったつもりの値と見比べられるようにするためです
     * (文字化けや、前後の空白を落とした結果がここに出ます)。
     * 本文 ({@code body}) はそのまま返さず、文字数だけにしています。</p>
     */
    Json.JsonObject successPayload(InquiryForm form, DuplicateGuard.Result accepted) {
        return Json.object()
                .put("ok", true)
                .put("receipt", accepted.getReceipt())
                .put("message", accepted.isDuplicate()
                        ? "同じ内容がすでに受け付けられています。受付番号は変わりません。"
                        : "お問い合わせを受け付けました。折り返しご連絡します。")
                // 二重送信として同じ受付番号を返したのかどうか。画面の表示を変えるために使う
                .put("duplicate", accepted.isDuplicate())
                .put("acceptedAt", LocalDateTime.now().format(TIME_FORMAT))
                .put("received", Json.object()
                        .put("name", form.getName())
                        .put("mail", form.getMail())
                        .put("type", form.getType())
                        .put("typeLabel", InquiryForm.labelOf(form.getType()))
                        .put("bodyLength", form.getBody().length()));
    }

    // ----------------------------------------------------------------------
    // 二重送信の防止
    // ----------------------------------------------------------------------

    /**
     * 受付番号を採番する ({@code A-0001} の形)。
     *
     * <p>番号の桁が足りなくなったら {@code A-10000} のように自然に伸びます。</p>
     */
    private String issueReceipt() {
        return formatReceipt(receiptSequence.incrementAndGet());
    }

    /** 連番を受付番号の文字列にする。 */
    static String formatReceipt(long number) {
        return String.format("A-%04d", number);
    }

    /**
     * 「同じ送信かどうか」を判定するための鍵を作る。
     *
     * <p>セッション ID を混ぜているので、<b>別の利用者が偶然同じ内容を書いても
     * 二重送信とは判定されません</b>。混ぜ忘れると、同じ問い合わせを送った 2 人目が
     * 1 人目の受付番号を受け取ってしまいます。</p>
     *
     * <p>区切りに改行を入れているのは、項目の境目をはっきりさせるためです。
     * 単純につなぐと {@code ("ab", "c")} と {@code ("a", "bc")} が同じ鍵になります。</p>
     */
    static String fingerprint(String sessionId, InquiryForm form) {
        return sessionId + "\n" + form.getName() + "\n" + form.getMail()
                + "\n" + form.getType() + "\n" + form.getBody();
    }

    /**
     * 直前に受け付けた内容を短い時間だけ覚えておき、同じものが来たら採番し直さない仕組み。
     *
     * <p>画面側でボタンを {@code disabled} にしても、次のような経路では 2 回届きます。</p>
     * <ul>
     *   <li>応答が返る前に通信が切れ、利用者が送り直した</li>
     *   <li>画面を通さず {@code curl} や開発者ツールから直接 POST した</li>
     *   <li>通信経路の途中で再送が起きた</li>
     * </ul>
     *
     * <p>同じ鍵が期間内に来たら、新しい番号を出さずに<b>前と同じ受付番号を返します</b>。
     * 「2 回呼ばれても結果が 1 回分と同じ」になるので、画面はエラーにせず素直に受付完了を出せます。</p>
     *
     * <p><b>この作りの限界</b>: 覚えているのはアプリのメモリの中だけなので、
     * 再起動すると消えますし、サーバを複数台に並べると台ごとに別々の記憶になります。
     * きちんとやるなら、画面を出すときに<b>ワンタイムトークン</b>を発行してセッションに覚えておき、
     * POST で使い終わったら捨てる形にします (これは CSRF 対策も兼ねられます)。
     * 保存先そのものに一意制約を張って、重複を DB に弾かせる手もあります。</p>
     */
    static final class DuplicateGuard {

        /**
         * 覚えておく件数の上限。
         *
         * <p>上限を決めないと、送信されるたびに記録が増え続けてメモリを食いつぶします
         * (いわゆるメモリリークです)。</p>
         */
        private static final int MAX_ENTRIES = 1000;

        /**
         * 直前の受付の記録。
         *
         * <p>複数のスレッドから同時に読み書きされるので {@link ConcurrentHashMap} を使います。
         * 素の {@link java.util.HashMap} を共有すると、書き込みが重なったときに
         * 中身が壊れる (取り出せなくなる) ことがあります。</p>
         */
        private final Map<String, Entry> recent = new ConcurrentHashMap<>();

        private final long windowMillis;

        DuplicateGuard(long windowMillis) {
            this.windowMillis = windowMillis;
        }

        /**
         * 受け付けてよいか判定する。
         *
         * @param key       {@link AjaxFormApiServlet#fingerprint} が作った鍵
         * @param nowMillis 現在時刻。引数で受け取るのは、<b>テストで時間を進められるようにする</b>ため
         * @param issuer    新しい受付番号を作る処理
         * @return 受付番号と、二重送信だったかどうか
         */
        Result accept(String key, long nowMillis, Supplier<String> issuer) {
            sweep(nowMillis);

            // 「探してから入れる」を 2 文に分けて書くと、その間に別のスレッドが割り込んで
            // 同じ内容に 2 つの番号が振られることがあります。compute なら鍵ごとに 1 つずつ処理されます。
            // (compute に渡す処理は短く保ち、この Map 自身を触らないのが約束事です)
            boolean[] duplicate = {false};
            Entry kept = recent.compute(key, (ignored, current) -> {
                if (current != null && nowMillis - current.acceptedAtMillis < windowMillis) {
                    duplicate[0] = true;
                    return current;
                }
                return new Entry(issuer.get(), nowMillis);
            });
            return new Result(kept.receipt, duplicate[0]);
        }

        /**
         * 期限切れの記録を捨てる。
         *
         * <p>毎回すべてを見に行くと無駄なので、件数が増えたときだけ掃除します。</p>
         *
         * <p>掃除しても減らないことがあります。短い間に<b>別々の内容</b>が大量に送られると、
         * どれもまだ期限内なので 1 件も消せません。そのまま入れ続けると記録が際限なく増え、
         * メモリを食いつぶします (公開している画面では、これが攻撃の的になります)。
         * そこで、掃除しても上限を下回らなければ<b>いったん全部忘れます</b>。
         * 二重送信の判定が一時的に効かなくなりますが、
         * 「番号が 2 つ振られることがある」ほうが「サーバが落ちる」より軽い、という判断です。</p>
         */
        private void sweep(long nowMillis) {
            if (recent.size() < MAX_ENTRIES) {
                return;
            }
            recent.values().removeIf(entry -> nowMillis - entry.acceptedAtMillis >= windowMillis);
            if (recent.size() >= MAX_ENTRIES) {
                recent.clear();
            }
        }

        /** 覚えている件数 (テストと動作確認のため)。 */
        int size() {
            return recent.size();
        }

        /** 受付 1 件の記録。 */
        private static final class Entry {

            private final String receipt;
            private final long acceptedAtMillis;

            Entry(String receipt, long acceptedAtMillis) {
                this.receipt = receipt;
                this.acceptedAtMillis = acceptedAtMillis;
            }
        }

        /** 判定の結果。 */
        static final class Result {

            private final String receipt;
            private final boolean duplicate;

            Result(String receipt, boolean duplicate) {
                this.receipt = receipt;
                this.duplicate = duplicate;
            }

            /** 受付番号 (二重送信なら前回と同じ番号)。 */
            String getReceipt() {
                return receipt;
            }

            /** 同じ内容が期間内にもう一度来たか。 */
            boolean isDuplicate() {
                return duplicate;
            }
        }
    }

    // ----------------------------------------------------------------------
    // 入力値と、その検証
    // ----------------------------------------------------------------------

    /**
     * 問い合わせフォームの入力値と、その入力チェック。
     *
     * <p>Servlet API に触れているのは {@link #from(HttpServletRequest)} だけで、
     * {@link #validate()} は文字列を見ているだけです。こう分けておくと
     * <b>Tomcat を起動せずに入力チェックのテストが書けます</b>
     * ({@code src/test/java/.../AjaxFormApiServletTest.java})。</p>
     *
     * <p>チェックは 1 項目につき<b>必須 → 形式 → 長さ</b>の順に見て、
     * どれかに引っかかったらその項目はそこで打ち切ります。
     * 「未入力です」と「30 文字以内です」を同時に出しても混乱するだけだからです。</p>
     */
    public static final class InquiryForm {

        /**
         * メールアドレスの形式。
         *
         * <p>「@ の前後に空白でない文字があり、後ろ側にドットがある」程度しか見ていません。
         * 厳密な正規表現は実用にならないほど複雑で、しかも実在するアドレスを弾いてしまいます。
         * <b>本当に届くかどうかは確認メールでしか分かりません</b>。
         * ここでの狙いは打ち間違いに気づいてもらうことです。</p>
         */
        private static final Pattern MAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

        /** お名前の上限 (文字数)。画面にもこの値を渡している。 */
        public static final int NAME_MAX_LENGTH = 30;

        /** お問い合わせ内容の上限 (文字数)。画面にもこの値を渡している。 */
        public static final int BODY_MAX_LENGTH = 200;

        /**
         * 選べる種別 (値 → 画面に出す名前)。
         *
         * <p>画面のセレクトボックスの選択肢も、サーバ側で受け付けてよい値の一覧も、
         * <b>この 1 つの定義から出しています</b>。2 か所に書くと、片方に選択肢を足したときに
         * 「画面では選べるのに送ると弾かれる」というちぐはぐな状態になります。</p>
         *
         * <p>{@link LinkedHashMap} なので、画面に出る順番は書いた順のままです
         * ({@link java.util.HashMap} だと順番は保証されません)。
         * {@code unmodifiableMap} で包んで、誰かが後から書き換えられないようにしています。</p>
         */
        public static final Map<String, String> TYPES;

        static {
            Map<String, String> types = new LinkedHashMap<>();
            types.put("question", "ご質問");
            types.put("request", "ご要望・ご提案");
            types.put("trouble", "不具合のご報告");
            types.put("other", "その他");
            TYPES = Collections.unmodifiableMap(types);
        }

        private final String name;
        private final String mail;
        private final String type;
        private final String body;

        private InquiryForm(String name, String mail, String type, String body) {
            this.name = name;
            this.mail = mail;
            this.type = type;
            this.body = body;
        }

        /**
         * リクエストパラメータから組み立てる。
         *
         * <p><b>受け取る</b>ことと<b>確かめる</b>ことを分けておくと、
         * 確かめる側をリクエスト無しでテストできます。</p>
         *
         * <p>前後の空白を落とすのに {@code trim()} ではなく {@code strip()} を使っています。
         * {@code trim()} は U+0020 以下しか削らないため<b>全角スペースが残り</b>、
         * 全角スペースだけの氏名が「入力あり」として通ってしまいます。</p>
         */
        public static InquiryForm from(HttpServletRequest request) {
            return new InquiryForm(
                    strip(request.getParameter("name")),
                    strip(request.getParameter("mail")),
                    strip(request.getParameter("type")),
                    normalizeNewlines(strip(request.getParameter("body"))));
        }

        /** 値を直接指定して組み立てる (テスト用)。 */
        public static InquiryForm of(String name, String mail, String type, String body) {
            return new InquiryForm(strip(name), strip(mail), strip(type),
                    normalizeNewlines(strip(body)));
        }

        /**
         * 入力内容を確かめて、見つかったエラーを返す。
         *
         * <p>1 つの項目につきメッセージは 1 つだけです
         * ({@link ValidationErrors} が同じ項目の 2 件目を捨てます)。
         * キーに使う名前 ({@code name} / {@code mail} / {@code type} / {@code body}) は、
         * <b>画面の入力欄の id と揃えてあります</b>。
         * 受け取った JavaScript が、キーから対象の欄を引けるようにするためです。</p>
         */
        public ValidationErrors validate() {
            ValidationErrors errors = new ValidationErrors();

            if (name.isEmpty()) {
                errors.add("name", "お名前を入力してください。");
            } else {
                errors.addIf(name.length() > NAME_MAX_LENGTH, "name",
                        "お名前は " + NAME_MAX_LENGTH + " 文字以内で入力してください。");
            }

            if (mail.isEmpty()) {
                errors.add("mail", "メールアドレスを入力してください。");
            } else {
                errors.addIf(!MAIL.matcher(mail).matches(), "mail",
                        "メールアドレスの形式が正しくありません。");
            }

            // セレクトボックスは「選択肢に無い値が送られてくる」前提で確かめます。
            // 画面に並べた選択肢は、開発者ツールからいくらでも書き換えられます
            if (type.isEmpty()) {
                errors.add("type", "お問い合わせの種別を選んでください。");
            } else {
                errors.addIf(!TYPES.containsKey(type), "type",
                        "お問い合わせの種別に不正な値が指定されました。選び直してください。");
            }

            if (body.isEmpty()) {
                errors.add("body", "お問い合わせ内容を入力してください。");
            } else {
                errors.addIf(body.length() > BODY_MAX_LENGTH, "body",
                        "お問い合わせ内容は " + BODY_MAX_LENGTH + " 文字以内で入力してください。");
            }

            return errors;
        }

        /** 種別の値に対応する表示名。知らない値なら空文字。 */
        public static String labelOf(String type) {
            return TYPES.getOrDefault(type, "");
        }

        /** お名前。 */
        public String getName() {
            return name;
        }

        /** メールアドレス。 */
        public String getMail() {
            return mail;
        }

        /** 種別の値 ({@code question} など)。 */
        public String getType() {
            return type;
        }

        /** お問い合わせ内容。 */
        public String getBody() {
            return body;
        }

        /** null を空文字にしてから前後の空白を落とす。 */
        private static String strip(String value) {
            return value == null ? "" : value.strip();
        }

        /**
         * 改行を LF だけに揃える。
         *
         * <p>ブラウザは textarea の改行を CRLF (2 文字) で送ってきます。
         * そのまま数えると、画面に見えている行数の分だけ文字数が増えて、
         * 「200 文字以内のはずなのに長すぎると言われる」ことになります。</p>
         */
        private static String normalizeNewlines(String value) {
            return value.replace("\r\n", "\n").replace('\r', '\n');
        }
    }
}
