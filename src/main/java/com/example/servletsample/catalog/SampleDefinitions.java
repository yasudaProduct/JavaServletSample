package com.example.servletsample.catalog;

import java.util.ArrayList;
import java.util.List;

import com.example.servletsample.common.CatalogInitializer;
import com.example.servletsample.common.Database;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.Json;
import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.common.Validators;
import com.example.servletsample.samples.a11y.ErrorSummaryServlet;
import com.example.servletsample.samples.advanced.AccessCheckFilter;
import com.example.servletsample.samples.advanced.AccessLogFilter;
import com.example.servletsample.samples.advanced.Account;
import com.example.servletsample.samples.advanced.AppLifecycleListener;
import com.example.servletsample.samples.advanced.ApplicationException;
import com.example.servletsample.samples.advanced.AsyncApiServlet;
import com.example.servletsample.samples.advanced.AsyncJobListener;
import com.example.servletsample.samples.advanced.AsyncServlet;
import com.example.servletsample.samples.advanced.AsyncWorkerPool;
import com.example.servletsample.samples.advanced.ErrorHandlingApiServlet;
import com.example.servletsample.samples.advanced.ErrorHandlingServlet;
import com.example.servletsample.samples.advanced.FilterApiServlet;
import com.example.servletsample.samples.advanced.FilterServlet;
import com.example.servletsample.samples.advanced.FilterTrace;
import com.example.servletsample.samples.advanced.FilterTraceStore;
import com.example.servletsample.samples.advanced.I18nServlet;
import com.example.servletsample.samples.advanced.ListenerEvent;
import com.example.servletsample.samples.advanced.ListenerEventLog;
import com.example.servletsample.samples.advanced.ListenerServlet;
import com.example.servletsample.samples.advanced.RequestIdFilter;
import com.example.servletsample.samples.advanced.SessionLifecycleListener;
import com.example.servletsample.samples.advanced.TransactionServlet;
import com.example.servletsample.samples.advanced.TransferDao;
import com.example.servletsample.samples.advanced.TransferOutcome;
import com.example.servletsample.samples.ajax.AjaxBasicsApiServlet;
import com.example.servletsample.samples.ajax.AjaxBasicsServlet;
import com.example.servletsample.samples.ajax.AjaxFormApiServlet;
import com.example.servletsample.samples.ajax.AjaxFormServlet;
import com.example.servletsample.samples.ajax.AjaxPollingApiServlet;
import com.example.servletsample.samples.ajax.AjaxPollingServlet;
import com.example.servletsample.samples.ajax.AjaxSearchApiServlet;
import com.example.servletsample.samples.ajax.AjaxSearchServlet;
import com.example.servletsample.samples.basic.CharacterEncodingServlet;
import com.example.servletsample.samples.basic.ContextPathServlet;
import com.example.servletsample.samples.basic.CookieServlet;
import com.example.servletsample.samples.basic.Cookies;
import com.example.servletsample.samples.basic.DispatcherAttributes;
import com.example.servletsample.samples.basic.DispatcherIncludeDemoServlet;
import com.example.servletsample.samples.basic.DispatcherIncludePartServlet;
import com.example.servletsample.samples.basic.DispatcherIncludeServlet;
import com.example.servletsample.samples.basic.ForwardRedirectGoalServlet;
import com.example.servletsample.samples.basic.ForwardRedirectServlet;
import com.example.servletsample.samples.basic.HelloWorldServlet;
import com.example.servletsample.samples.basic.JspBasicsServlet;
import com.example.servletsample.samples.basic.LifecycleCounterApiServlet;
import com.example.servletsample.samples.basic.LifecycleServlet;
import com.example.servletsample.samples.basic.Mojibake;
import com.example.servletsample.samples.basic.OrderBean;
import com.example.servletsample.samples.basic.RequestParameterServlet;
import com.example.servletsample.samples.basic.RequestResponseApiServlet;
import com.example.servletsample.samples.basic.RequestResponseServlet;
import com.example.servletsample.samples.basic.ResponseOutputDemoServlet;
import com.example.servletsample.samples.basic.ResponseOutputServlet;
import com.example.servletsample.samples.basic.ScopeServlet;
import com.example.servletsample.samples.basic.ServletConfigDemoServlet;
import com.example.servletsample.samples.basic.ServletConfigServlet;
import com.example.servletsample.samples.basic.UrlMappingDemoServlet;
import com.example.servletsample.samples.basic.UrlMappingRules;
import com.example.servletsample.samples.basic.UrlMappingServlet;
import com.example.servletsample.samples.design.ModalDialogEntriesServlet;
import com.example.servletsample.samples.design.ModalDialogServlet;
import com.example.servletsample.samples.design.ReceptionEntry;
import com.example.servletsample.samples.file.Csv;
import com.example.servletsample.samples.file.CsvDownloadServlet;
import com.example.servletsample.samples.file.CsvExportServlet;
import com.example.servletsample.samples.file.CsvOptions;
import com.example.servletsample.samples.file.FileDownloadServlet;
import com.example.servletsample.samples.file.FileUploadServlet;
import com.example.servletsample.samples.file.SalesRecord;
import com.example.servletsample.samples.file.SalesRecords;
import com.example.servletsample.samples.file.StoredFile;
import com.example.servletsample.samples.file.StoredFileDao;
import com.example.servletsample.samples.form.ConfirmFormServlet;
import com.example.servletsample.samples.form.EmployeeMaster;
import com.example.servletsample.samples.form.InputValidationServlet;
import com.example.servletsample.samples.form.LeaveRequestForm;
import com.example.servletsample.samples.form.LeaveType;
import com.example.servletsample.samples.form.MemberForm;
import com.example.servletsample.samples.form.RealtimeValidationServlet;
import com.example.servletsample.samples.form.SeminarForm;
import com.example.servletsample.samples.form.ValidationRulesServlet;
import com.example.servletsample.samples.list.CrudServlet;
import com.example.servletsample.samples.list.Customer;
import com.example.servletsample.samples.list.CustomerDao;
import com.example.servletsample.samples.list.CustomerForm;
import com.example.servletsample.samples.list.OptimisticLockServlet;
import com.example.servletsample.samples.list.Page;
import com.example.servletsample.samples.list.Product;
import com.example.servletsample.samples.list.ProductDao;
import com.example.servletsample.samples.list.ProductListServlet;
import com.example.servletsample.samples.list.ProductSearch;
import com.example.servletsample.samples.session.AuthApiServlet;
import com.example.servletsample.samples.session.AuthFilterServlet;
import com.example.servletsample.samples.session.AuthenticationFilter;
import com.example.servletsample.samples.session.AuthorizationFilter;
import com.example.servletsample.samples.session.CsrfServlet;
import com.example.servletsample.samples.session.CsrfToken;
import com.example.servletsample.samples.session.LoginServlet;
import com.example.servletsample.samples.session.LoginUser;
import com.example.servletsample.samples.session.LogoutServlet;
import com.example.servletsample.samples.session.PasswordHash;
import com.example.servletsample.samples.session.ProtectedPageServlet;
import com.example.servletsample.samples.session.UserAccounts;

/**
 * ★ サンプルを追加する場所 ★
 *
 * <p>サンプルを 1 つ増やすときにやることは 2 つだけです。</p>
 * <ol>
 *   <li>{@code src/main/webapp/WEB-INF/views/samples/{カテゴリ}/{ID}.jsp} を作る</li>
 *   <li>このクラスの {@link #define()} に定義を 1 つ足す</li>
 * </ol>
 *
 * <p>Servlet が必要なサンプル (画面から POST を受けるなど) は
 * {@code com.example.servletsample.samples} 配下に {@code @WebServlet("/samples/{カテゴリ}/{ID}")}
 * で作れば、そちらが優先して呼ばれます。Servlet が無いサンプルは
 * {@link com.example.servletsample.web.SampleDispatcherServlet} が JSP へ転送します。</p>
 *
 * <p>詳しい手順とテンプレートはリポジトリの {@code docs/ADD_SAMPLE.md} にあります。</p>
 */
final class SampleDefinitions {

    private SampleDefinitions() {
    }

    static List<Sample> define() {
        List<Sample> samples = new ArrayList<>();

        // ------------------------------------------------------------------
        // 基本
        // ------------------------------------------------------------------
        samples.add(Sample.builder("hello-world", Category.BASIC)
                .title("Hello World (Servlet → JSP)")
                .summary("Servlet でデータを用意して JSP へ転送する、Web アプリのもっとも基本的な流れ。")
                .tags("Servlet", "JSP", "forward", "リクエストスコープ")
                .source(HelloWorldServlet.class)
                .build());

        samples.add(Sample.builder("request-parameter", Category.BASIC)
                .title("リクエストパラメータの受け取り方")
                .summary("画面から送られてきた値を getParameter / getParameterValues / getParameterMap で受け取る。"
                        + "null と空文字の違い、チェックボックスの落とし穴、数値変換の例外対策まで。")
                .tags("Servlet", "パラメータ", "フォーム", "GET", "POST", "getParameter", "EL")
                .source(RequestParameterServlet.class)
                .build());

        samples.add(Sample.builder("forward-redirect", Category.BASIC)
                .title("forward と redirect の違い")
                .summary("同じ「注文を受け付ける」処理を forward と redirect の 2 通りで実行し、"
                        + "URL・リクエストスコープ・履歴・再読み込みの違いを見比べます。")
                .tags("forward", "redirect", "sendRedirect", "PRG", "リクエストスコープ", "画面遷移", "POST")
                .source(ForwardRedirectServlet.class)
                .source(ForwardRedirectGoalServlet.class)
                .source(SourceFile.jsp("/WEB-INF/views/samples/basic/forward-redirect-goal.jsp"))
                .build());

        samples.add(Sample.builder("dispatcher-include", Category.BASIC)
                .title("include と forward（画面の一部を差し込む）")
                .summary("RequestDispatcher には forward のほかに include がある。"
                        + "同じ部品を複数の画面から呼び、レスポンスがどちらに書かれるか、"
                        + "呼び出し元に処理が戻ってくるかの違いを見ます。")
                .tags("RequestDispatcher", "include", "forward", "jsp:include", "部品化")
                .source(DispatcherIncludeServlet.class)
                .source(DispatcherIncludeDemoServlet.class)
                .source(DispatcherIncludePartServlet.class)
                .source(DispatcherAttributes.class)
                .source(SourceFile.jsp("/WEB-INF/views/samples/basic/dispatcher-include-part.jsp"))
                .build());

        samples.add(Sample.builder("scope", Category.BASIC)
                .title("スコープ (request / session / application)")
                .summary("値をどこに置くかで、いつまで残り、誰に見えるかが変わる。"
                        + "3 つのスコープに同じ値を入れて、開き直したり破棄したりしながら違いを確かめます。")
                .tags("スコープ", "リクエストスコープ", "セッション", "ServletContext", "EL", "invalidate",
                        "スレッドセーフ")
                .source(ScopeServlet.class)
                .build());

        samples.add(Sample.builder("servlet-lifecycle", Category.BASIC)
                .title("Servlet のライフサイクルとスレッド")
                .summary("Servlet はアプリ全体で 1 インスタンス。そこへリクエストごとの別スレッドが同時に入ってきます。"
                        + "init / service / destroy の流れと、インスタンス変数を共有したときに起きる数のずれを体験します。")
                .tags("Servlet", "ライフサイクル", "スレッド", "init", "loadOnStartup", "AtomicInteger",
                        "スレッドセーフ", "JSON")
                .source(LifecycleServlet.class)
                .source(LifecycleCounterApiServlet.class)
                .source(Json.class)
                .build());

        samples.add(Sample.builder("url-mapping", Category.BASIC)
                .title("URL と Servlet の対応づけ（url-pattern の優先順位）")
                .summary("@WebServlet と web.xml で URL を割り当てる。完全一致・前方一致・拡張子・既定の"
                        + "どれが選ばれるか、getContextPath / getServletPath / getPathInfo が"
                        + "それぞれ何を返すかを呼び分けて確かめます。")
                .tags("Servlet", "@WebServlet", "url-pattern", "web.xml", "getPathInfo",
                        "getServletPath", "マッピング")
                .source(UrlMappingServlet.class)
                .source(UrlMappingDemoServlet.class)
                .source(UrlMappingRules.class)
                .build());

        samples.add(Sample.builder("request-response", Category.BASIC)
                .title("リクエストとレスポンスの中身を見る")
                .summary("Servlet は HTTP を Java のオブジェクトにしたもの。"
                        + "メソッド・URL・ヘッダを一覧で確かめ、ステータスコードやヘッダを"
                        + "自分で決めて返してみます。")
                .tags("HTTP", "リクエストヘッダ", "レスポンスヘッダ", "ステータスコード",
                        "setStatus", "sendError", "Content-Type")
                .source(RequestResponseServlet.class)
                .source(RequestResponseApiServlet.class)
                .source(Json.class)
                .source(Validators.class)
                .build());

        samples.add(Sample.builder("character-encoding", Category.BASIC)
                .title("文字コードと文字化け")
                .summary("日本語が「????」や「譁?ｭ怜喧」になるのはどこで起きるのか。"
                        + "リクエストの読み方・レスポンスの書き方・HTML の宣言を切り替えて、"
                        + "化ける瞬間と直し方を見比べます。")
                .tags("文字コード", "文字化け", "UTF-8", "setCharacterEncoding",
                        "request-character-encoding", "Content-Type", "POST", "GET")
                .source(CharacterEncodingServlet.class)
                .source(Mojibake.class)
                .build());

        samples.add(Sample.builder("cookie", Category.BASIC)
                .title("Cookie の基本")
                .summary("ブラウザに小さな値を預けて、次のリクエストで受け取る。"
                        + "有効期限・パス・HttpOnly・SameSite を切り替えて、"
                        + "セッション (JSESSIONID) との関係まで確かめます。")
                .tags("Cookie", "addCookie", "getCookies", "maxAge", "HttpOnly", "SameSite",
                        "JSESSIONID", "セッション")
                .source(CookieServlet.class)
                .source(Cookies.class)
                .source(Flash.class)
                .build());

        samples.add(Sample.builder("response-output", Category.BASIC)
                .title("Servlet から直接出力する（getWriter とバッファ）")
                .summary("JSP を使わずに HTML・テキスト・JSON を書き出す。"
                        + "Content-Type で見え方が変わること、書き始めたあとに forward すると"
                        + "例外になること、バッファと flush の関係を確かめます。")
                .tags("getWriter", "Content-Type", "PrintWriter", "バッファ", "flushBuffer",
                        "IllegalStateException", "getOutputStream")
                .source(ResponseOutputServlet.class)
                .source(ResponseOutputDemoServlet.class)
                .build());

        samples.add(Sample.builder("servlet-config", Category.BASIC)
                .title("設定値の渡し方（init-param と context-param）")
                .summary("上限値や接続先をソースに直接書かず web.xml へ出す。"
                        + "Servlet 1 つに渡す init-param とアプリ全体で使う context-param を、"
                        + "読み出すタイミングの違いも含めて比べます。")
                .tags("web.xml", "init-param", "context-param", "ServletConfig", "ServletContext",
                        "initParam", "設定")
                .source(ServletConfigServlet.class)
                .source(ServletConfigDemoServlet.class)
                .source(SourceFile.of("/WEB-INF/web.xml", "web.xml", "xml"))
                .build());

        samples.add(Sample.builder("jsp-basics", Category.BASIC)
                .title("EL と JSTL の基本")
                .summary("EL の書き方と JSTL (core / fmt / functions) の使い方を、書いた EL とその結果を並べて確かめる。"
                        + "エスケープあり / なしの見え方の違いも比較できます。")
                .tags("JSP", "EL", "JSTL", "c:forEach", "c:choose", "c:set", "fn:escapeXml",
                        "fmt:formatNumber", "XSS")
                .source(JspBasicsServlet.class)
                .build());

        samples.add(Sample.builder("jsp-syntax", Category.BASIC)
                .title("JSP の記法（ディレクティブ・スクリプトレット・アクション）")
                .summary("ディレクティブ・宣言・スクリプトレット・式・アクションが、変換後の Servlet の"
                        + "どこへ行くのかを動かしながら確かめる。インクルードの 2 種類、jsp:useBean、"
                        + "コメントがブラウザまで届くかどうかまで。")
                .tags("JSP", "スクリプトレット", "ディレクティブ", "jsp:include", "jsp:useBean",
                        "暗黙オブジェクト", "JSPコメント", "翻訳", "JavaBeans")
                .source(OrderBean.class)
                .source(SourceFile.jsp("/WEB-INF/views/samples/basic/jsp-syntax-scripting.jsp"))
                .source(SourceFile.jsp("/WEB-INF/views/samples/basic/jsp-syntax-part.jspf"))
                .source(SourceFile.jsp("/WEB-INF/views/samples/basic/jsp-syntax-included.jsp"))
                .source(SourceFile.jsp("/WEB-INF/views/samples/basic/jsp-syntax-comments.jsp"))
                .build());

        samples.add(Sample.builder("context-path", Category.BASIC)
                .title("コンテキストパスと相対パス（リンクが 404 になる）")
                .summary("画像や CSS へのリンクが配備先で切れるのはなぜか。"
                        + "「/ 始まり」「相対」「${pageContext.request.contextPath} 付き」の 3 通りを並べ、"
                        + "forward したあとにどこを指すかまで見比べます。")
                .tags("contextPath", "相対パス", "リンク", "404", "pageContext", "sendRedirect", "配備")
                .source(ContextPathServlet.class)
                .build());

        // ------------------------------------------------------------------
        // 画面デザイン
        // ------------------------------------------------------------------
        samples.add(Sample.builder("bootstrap-basics", Category.DESIGN)
                .title("Bootstrap 4 の基本パーツ")
                .summary("グリッド、ボタン、カード、テーブル、アラートなど、画面作成で使う部品の一覧。")
                .tags("Bootstrap4", "グリッド", "カード", "ボタン", "CSS")
                .build());

        samples.add(Sample.builder("modal-dialog", Category.DESIGN)
                .title("モーダル（ダイアログ）の出し方 6 パターン")
                .summary("ボタンで開く確認モーダル、処理後の完了モーダル、画面遷移後に出すモーダル、"
                        + "「確認 → 登録 → 完了モーダル → 画面遷移」の流れ、"
                        + "さらにモーダルで入力した内容や検索して選んだ行を元の画面のフォームへ渡すパターン。")
                .tags("Bootstrap4", "モーダル", "確認ダイアログ", "検索ダイアログ", "PRG", "フラッシュメッセージ",
                        "リダイレクト", "画面遷移", "JavaScript")
                .source(ModalDialogServlet.class)
                .source(ModalDialogEntriesServlet.class)
                .source(ReceptionEntry.class)
                .source(Flash.class)
                .source(SourceFile.jsp("/WEB-INF/views/samples/design/modal-dialog-entries.jsp"))
                .build());

        // ------------------------------------------------------------------
        // アクセシビリティ
        // ------------------------------------------------------------------
        samples.add(Sample.builder("mobile-keyboard", Category.ACCESSIBILITY)
                .title("スマホで開くキーボードを切り替える")
                .summary("type / inputmode / enterkeyhint で、電話番号や郵便番号の欄に数字キーボードを出す。"
                        + "業務システムで type=\"number\" を使ってはいけない理由も、"
                        + "実際に値がどう壊れるかを並べて確かめます。")
                .tags("アクセシビリティ", "スマートフォン", "inputmode", "enterkeyhint", "type",
                        "フォーム", "キーボード", "HTML")
                .build());

        samples.add(Sample.builder("autocomplete", Category.ACCESSIBILITY)
                .title("自動入力（autocomplete）と、余計なお節介を切る")
                .summary("住所・氏名・パスワードをブラウザに補完させるトークンの書き方と、"
                        + "社員コードの欄で iOS の自動大文字化・自動修正を止める指定。")
                .tags("アクセシビリティ", "autocomplete", "自動入力", "autocapitalize", "one-time-code",
                        "住所", "フォーム", "HTML", "WCAG")
                .build());

        samples.add(Sample.builder("form-labels", Category.ACCESSIBILITY)
                .title("ラベルの付け方と入力欄のグループ化")
                .summary("label for / fieldset / legend / aria-describedby という、"
                        + "フォームの骨組み。placeholder をラベル代わりにしない理由と、"
                        + "タップできる大きさの目安まで。")
                .tags("アクセシビリティ", "label", "fieldset", "legend", "aria-describedby",
                        "placeholder", "必須", "フォーム", "HTML")
                .build());

        samples.add(Sample.builder("error-summary", Category.ACCESSIBILITY)
                .title("エラーの伝え方（エラーサマリとフォーカス移動）")
                .summary("画面の先頭にエラーの一覧を出し、そこへフォーカスを移して、"
                        + "各項目へリンクで飛べるようにする。aria-invalid と aria-describedby、"
                        + "色だけに頼らないメッセージの書き方まで。")
                .tags("アクセシビリティ", "エラー", "エラーサマリ", "aria-invalid", "role=alert",
                        "フォーカス", "バリデーション", "フォーム")
                .source(ErrorSummaryServlet.class)
                .source(ValidationErrors.class)
                .source(Validators.class)
                .build());

        samples.add(Sample.builder("keyboard-operation", Category.ACCESSIBILITY)
                .title("マウスを使わずに操作する")
                .summary("Tab の順番、tabindex の使い分け、:focus-visible、「本文へスキップ」リンク、"
                        + "モーダルのフォーカストラップ。div をボタンにすると何が起きるかを並べて確かめます。")
                .tags("アクセシビリティ", "キーボード", "フォーカス", "tabindex", "focus-visible",
                        "スキップリンク", "モーダル", "button")
                .source(SourceFile.jsp("/WEB-INF/tags/layout.tag"))
                .build());

        samples.add(Sample.builder("live-region", Category.ACCESSIBILITY)
                .title("画面の変化を読み上げで知らせる（aria-live）")
                .summary("Ajax で一部だけ書き換えたとき、その変化を音でも伝える。"
                        + "role=status と role=alert の使い分け、進捗バーの aria-valuenow、aria-busy。")
                .tags("アクセシビリティ", "aria-live", "role=status", "role=alert", "progressbar",
                        "aria-busy", "Ajax", "JavaScript")
                .build());

        samples.add(Sample.builder("accessible-table", Category.ACCESSIBILITY)
                .title("表を読み上げと相性よく作る")
                .summary("caption / th scope / aria-sort と、横に長い表をキーボードでもスクロールできるようにする方法。"
                        + "レイアウト目的で table を使わない、空セルを空のままにしない、といった定番の注意も。")
                .tags("アクセシビリティ", "テーブル", "caption", "scope", "aria-sort",
                        "table-responsive", "一覧", "HTML")
                .build());

        samples.add(Sample.builder("alt-text", Category.ACCESSIBILITY)
                .title("画像とアイコンの代替テキスト")
                .summary("alt の書き分け（意味のある画像・装飾・リンクの中・グラフ）、"
                        + "アイコンだけのボタンに aria-label を付ける、"
                        + "画面に出さず読み上げにだけ足す .sr-only の使い方。")
                .tags("アクセシビリティ", "alt", "aria-label", "aria-hidden", "sr-only",
                        "アイコン", "SVG", "リンク")
                .build());

        samples.add(Sample.builder("visual-design", Category.ACCESSIBILITY)
                .title("色・コントラスト・拡大・動きへの配慮")
                .summary("コントラスト比の基準と Bootstrap 4 の既定色の実測、色だけに頼らない伝え方、"
                        + "200% に拡大しても壊れない組み方、prefers-reduced-motion。")
                .tags("アクセシビリティ", "コントラスト", "色", "拡大", "リフロー",
                        "prefers-reduced-motion", "CSS", "WCAG")
                .build());

        samples.add(Sample.builder("a11y-check", Category.ACCESSIBILITY)
                .title("自分の画面をチェックする手順")
                .summary("キーボードで一周する、200% に拡大する、色を抜く、Lighthouse や axe を掛ける、"
                        + "読み上げを聞く。10 分でできる点検の手順と、そのまま使えるチェックリスト。")
                .tags("アクセシビリティ", "チェック", "Lighthouse", "axe", "スクリーンリーダー",
                        "WCAG", "JIS X 8341-3", "NVDA", "VoiceOver")
                .build());

        // ------------------------------------------------------------------
        // フォーム・入力
        // ------------------------------------------------------------------
        samples.add(Sample.builder("input-validation", Category.FORM)
                .title("入力チェック（サーバ側）")
                .summary("送られてきた値をサーバ側だけで確かめる会員登録フォーム。"
                        + "エラーは画面の先頭と各項目に出し、入力値は保持したまま返します。")
                .tags("フォーム", "バリデーション", "POST", "エラー表示", "相関チェック", "PRG")
                .source(InputValidationServlet.class)
                .source(MemberForm.class)
                .source(ValidationErrors.class)
                .build());

        samples.add(Sample.builder("validation-rules", Category.FORM)
                .title("入力チェックの種類（必須・文字種・桁数・日付・相関）")
                .summary("必須、文字種、桁数、日付の実在、範囲、相関、選択肢、マスタ突き合わせ。"
                        + "休暇申請フォームを題材に、種類ごとの書き方と「どの順に並べるか」を確かめます。")
                .tags("フォーム", "バリデーション", "入力チェック", "正規表現", "日付", "相関チェック",
                        "ホワイトリスト", "複数選択", "POST")
                .source(ValidationRulesServlet.class)
                .source(LeaveRequestForm.class)
                .source(Validators.class)
                .source(LeaveType.class)
                .source(EmployeeMaster.class)
                .source(ValidationErrors.class)
                .build());

        samples.add(Sample.builder("realtime-validation", Category.FORM)
                .title("入力チェック（フォーカスアウト時）")
                .summary("フォーカスが外れた時点で JavaScript がその場でチェックし、"
                        + "同じ内容をサーバ側でも確かめる。JavaScript を通さずに送るとどうなるかも試せます。")
                .tags("フォーム", "バリデーション", "JavaScript", "blur", "アクセシビリティ", "文字数カウンタ")
                .source(RealtimeValidationServlet.class)
                .source(ValidationErrors.class)
                .build());

        samples.add(Sample.builder("confirm-form", Category.FORM)
                .title("入力 → 確認 → 完了（3 画面）")
                .summary("業務システムで定番の流れ。値の持ち回りを隠し項目とセッションの 2 通りで試し、"
                        + "確定時に検証をやり直す理由、二重送信をワンタイムトークンで防ぐ方法まで。")
                .tags("フォーム", "確認画面", "PRG", "二重送信", "ワンタイムトークン", "hidden",
                        "セッション", "POST", "XSS")
                .source(ConfirmFormServlet.class)
                .source(SeminarForm.class)
                .source(Flash.class)
                .build());

        // ------------------------------------------------------------------
        // 一覧・検索
        // ------------------------------------------------------------------
        samples.add(Sample.builder("search-list", Category.LIST)
                .title("検索つき一覧画面（ページング・並び替え）")
                .summary("キーワードとカテゴリで絞り込み、ページを送りながら見る一覧。SQL の LIMIT / OFFSET で必要な行だけを取り出します。")
                .tags("一覧", "検索", "ページング", "ソート", "SQL", "JDBC", "JSTL")
                .source(ProductListServlet.class)
                .source(ProductSearch.class)
                .source(ProductDao.class)
                .source(Page.class)
                .source(Product.class)
                .source(Database.class)
                .build());

        samples.add(Sample.builder("crud", Category.LIST)
                .title("マスタメンテナンス（登録・編集・削除）")
                .summary("業務システムで何十画面も作ることになる基本の形。一覧を起点に、"
                        + "登録・編集・削除を行き来します。表示は GET・更新は POST、削除の確認、"
                        + "一意性チェックの二段構え、PRG まで。")
                .tags("CRUD", "マスタ", "登録", "更新", "削除", "PRG", "UNIQUE制約",
                        "楽観ロック", "JDBC")
                .source(CrudServlet.class)
                .source(CustomerForm.class)
                .source(CustomerDao.class)
                .source(Customer.class)
                .build());

        samples.add(Sample.builder("optimistic-lock", Category.LIST)
                .title("更新の競合（楽観ロック）")
                .summary("2 人が同じ行を同時に編集すると、後から保存した人が相手の変更を黙って消します。"
                        + "version 列でそれに気付き、何が違うのかを並べて見せて選ばせるところまで。"
                        + "1 人でも競合を再現できます。")
                .tags("楽観ロック", "悲観ロック", "更新の喪失", "version", "排他制御",
                        "同時更新", "JDBC", "UPDATE")
                .source(OptimisticLockServlet.class)
                .source(CustomerDao.class)
                .source(Customer.class)
                .source(CustomerForm.class)
                .build());

        // ------------------------------------------------------------------
        // ファイル
        // ------------------------------------------------------------------
        samples.add(Sample.builder("file-upload", Category.FILE)
                .title("ファイルのアップロード・ダウンロード・削除（DB 保存）")
                .summary("選んだファイルをデータベースの BLOB 列に保存し、一覧からダウンロード・削除する。")
                .tags("ファイル", "アップロード", "ダウンロード", "multipart", "BLOB", "JDBC")
                .source(FileUploadServlet.class)
                .source(FileDownloadServlet.class)
                .source(StoredFileDao.class)
                .source(StoredFile.class)
                .source(SourceFile.jsp("/WEB-INF/tags/resultModal.tag"))
                .build());

        samples.add(Sample.builder("csv-download", Category.FILE)
                .title("CSV ダウンロード（文字化け・エスケープ対策）")
                .summary("「Excel で開いたら文字化けした」の正体は BOM。文字コード・改行・"
                        + "エスケープの有無を切り替えながら、組み立てた CSV をその場で見比べます。"
                        + "日本語のファイル名と CSV インジェクション対策まで。")
                .tags("CSV", "ダウンロード", "文字コード", "BOM", "Shift_JIS", "エスケープ",
                        "RFC4180", "Content-Disposition", "CSVインジェクション")
                .source(CsvDownloadServlet.class)
                .source(CsvExportServlet.class)
                .source(Csv.class)
                .source(CsvOptions.class)
                .source(SalesRecord.class)
                .source(SalesRecords.class)
                .build());

        // ------------------------------------------------------------------
        // 非同期通信
        // ------------------------------------------------------------------
        samples.add(Sample.builder("ajax-basics", Category.AJAX)
                .title("非同期通信の基本（fetch で JSON を取得）")
                .summary("画面を読み込み直さずにサーバへ問い合わせ、返ってきた JSON で画面の一部だけを書き換える。"
                        + "ローディング表示、404 / 500 のときの出方、通信できないときの扱いまで。")
                .tags("Ajax", "fetch", "JSON", "非同期通信", "JavaScript", "エラー処理", "API")
                .source(AjaxBasicsServlet.class)
                .source(AjaxBasicsApiServlet.class)
                .source(Json.class)
                .build());

        samples.add(Sample.builder("ajax-search", Category.AJAX)
                .title("インクリメンタルサーチ（入力するたびに検索）")
                .summary("入力のたびに JSON API を呼んで候補を出す検索欄。debounce で投げすぎを抑え、"
                        + "AbortController と通し番号で古い応答の上書きを防ぎます。")
                .tags("Ajax", "fetch", "JSON", "インクリメンタルサーチ", "debounce",
                        "AbortController", "検索", "アクセシビリティ")
                .source(AjaxSearchServlet.class)
                .source(AjaxSearchApiServlet.class)
                .build());

        samples.add(Sample.builder("ajax-form", Category.AJAX)
                .title("Ajax でフォームを送信する")
                .summary("問い合わせフォームを画面遷移せずに送り、項目ごとのエラーと受付番号を JSON で受け取る。")
                .tags("Ajax", "fetch", "POST", "フォーム", "バリデーション", "JSON", "二重送信")
                .source(AjaxFormServlet.class)
                .source(AjaxFormApiServlet.class)
                .source(ValidationErrors.class)
                .source(Json.class)
                .build());

        samples.add(Sample.builder("ajax-polling", Category.AJAX)
                .title("処理の進捗をポーリングで取得する")
                .summary("時間のかかる集計処理の進捗を 1 秒おきに問い合わせて進捗バーに反映する。"
                        + "間隔の決め方、終了条件の作り方、画面を離れたときの止め方まで。")
                .tags("Ajax", "ポーリング", "setInterval", "進捗バー", "JSON", "fetch", "セッション")
                .source(AjaxPollingServlet.class)
                .source(AjaxPollingApiServlet.class)
                .build());

        // ------------------------------------------------------------------
        // セッション・認証
        // ------------------------------------------------------------------
        samples.add(Sample.builder("login", Category.SESSION)
                .title("ログインとログアウト")
                .summary("セッションに「ログイン済み」の印を置き、次のリクエストで確かめる。"
                        + "パスワードのハッシュ化、ログイン成功時のセッション ID の振り直し、"
                        + "ログアウトを POST で受ける理由まで。")
                .tags("セッション", "ログイン", "ログアウト", "認証", "パスワード", "ハッシュ",
                        "PBKDF2", "セッション固定攻撃", "invalidate", "PRG")
                .source(LoginServlet.class)
                .source(LogoutServlet.class)
                .source(PasswordHash.class)
                .source(UserAccounts.class)
                .source(LoginUser.class)
                .build());

        samples.add(Sample.builder("auth-filter", Category.SESSION)
                .title("フィルタで未ログインを弾く（認証・認可）")
                .summary("ログイン確認を画面ごとに書くと必ず漏れる。フィルタで URL ごとに一括で掛け、"
                        + "認証は 401、権限不足は 403 と返し分けます。"
                        + "Ajax にリダイレクトを返してはいけない理由も。")
                .tags("フィルタ", "認証", "認可", "ロール", "401", "403", "セッション",
                        "オープンリダイレクト", "Ajax", "web.xml")
                .source(AuthenticationFilter.class)
                .source(AuthorizationFilter.class)
                .source(AuthFilterServlet.class)
                .source(ProtectedPageServlet.class)
                .source(AuthApiServlet.class)
                .source(SourceFile.of("/WEB-INF/web.xml", "web.xml", "xml"))
                .source(SourceFile.jsp("/WEB-INF/views/samples/session/auth-filter-protected.jsp"))
                .build());

        samples.add(Sample.builder("csrf", Category.SESSION)
                .title("CSRF 対策（ワンタイムトークン）")
                .summary("罠のページから送られた依頼を、ログイン済みの本人からの依頼と区別する。"
                        + "トークンを付けた場合・付けない場合・でたらめな場合を送り比べ、"
                        + "SameSite Cookie や二重送信防止との違いも整理します。")
                .tags("CSRF", "セキュリティ", "トークン", "セッション", "403", "SameSite",
                        "二重送信", "POST", "SecureRandom")
                .source(CsrfServlet.class)
                .source(CsrfToken.class)
                .build());

        // ------------------------------------------------------------------
        // 応用・その他
        // ------------------------------------------------------------------
        samples.add(Sample.builder("error-handling", Category.ADVANCED)
                .title("エラー処理とエラーページ")
                .summary("入力の誤り・業務上の都合・システムの異常。どれをどこで受け止め、"
                        + "何を画面に出すか。web.xml でのエラーページの割り当て、"
                        + "JSP の errorPage 属性、非同期通信での返し方まで。")
                .tags("エラー処理", "例外", "エラーページ", "web.xml", "sendError", "業務例外",
                        "ログ", "errorPage", "Ajax")
                .source(ErrorHandlingServlet.class)
                .source(ApplicationException.class)
                .source(ErrorHandlingApiServlet.class)
                .source(Validators.class)
                .source(SourceFile.of("/WEB-INF/web.xml", "web.xml", "xml"))
                .source(SourceFile.jsp("/WEB-INF/tags/errorDetail.tag"))
                .source(SourceFile.jsp("/WEB-INF/views/error/500.jsp"))
                .source(SourceFile.jsp("/WEB-INF/views/error/error.jsp"))
                .source(SourceFile.jsp("/WEB-INF/views/error/application-error.jsp"))
                .source(SourceFile.jsp("/WEB-INF/views/samples/advanced/error-handling-jsp.jsp"))
                .source(SourceFile.jsp("/WEB-INF/views/samples/advanced/error-handling-jsp-error.jsp"))
                .build());

        samples.add(Sample.builder("filter", Category.ADVANCED)
                .title("フィルタ（Filter）で共通処理をはさむ")
                .summary("Servlet の手前と奥に共通処理を差し込む。3 つのフィルタが"
                        + "どの順に呼ばれるかを 1 往復ぶん記録して表示し、"
                        + "chain.doFilter を呼ばずに止めるとどうなるかも確かめます。")
                .tags("フィルタ", "Filter", "FilterChain", "web.xml", "アクセスログ",
                        "dispatcher", "リクエストID", "レスポンスヘッダ", "スレッドセーフ")
                .source(RequestIdFilter.class)
                .source(AccessLogFilter.class)
                .source(AccessCheckFilter.class)
                .source(FilterServlet.class)
                .source(FilterApiServlet.class)
                .source(FilterTrace.class)
                .source(FilterTraceStore.class)
                .source(SourceFile.of("/WEB-INF/web.xml", "web.xml", "xml"))
                .build());

        samples.add(Sample.builder("i18n", Category.ADVANCED)
                .title("国際化（多言語表示）")
                .summary("画面の文字を properties にまとめ、ロケールで切り替える。"
                        + "Accept-Language の読み方、properties の探索順、"
                        + "日付・数値・通貨・タイムゾーンの書式まで。")
                .tags("国際化", "i18n", "ロケール", "ResourceBundle", "properties", "JSTL",
                        "fmt", "Accept-Language", "タイムゾーン", "文字コード")
                .source(I18nServlet.class)
                .source(SourceFile.of("/WEB-INF/classes/messages_ja.properties",
                        "messages_ja.properties", "ini"))
                .source(SourceFile.of("/WEB-INF/classes/messages_en.properties",
                        "messages_en.properties", "ini"))
                .source(SourceFile.of("/WEB-INF/classes/messages.properties",
                        "messages.properties", "ini"))
                .build());

        samples.add(Sample.builder("transaction", Category.ADVANCED)
                .title("データベースのトランザクション（commit と rollback）")
                .summary("口座間の振替を題材に、複数の更新を「全部やるか 1 つもやらないか」にまとめる。"
                        + "トランザクションを使わずに途中で失敗させると、"
                        + "出金だけが確定して残高の合計が合わなくなる様子まで確かめられます。")
                .tags("トランザクション", "commit", "rollback", "setAutoCommit", "JDBC",
                        "分離レベル", "排他制御", "コネクション")
                .source(TransactionServlet.class)
                .source(TransferDao.class)
                .source(TransferOutcome.class)
                .source(Account.class)
                .source(Database.class)
                .build());

        samples.add(Sample.builder("listener", Category.ADVANCED)
                .title("リスナーで起動・終了・セッションを捕まえる")
                .summary("アプリの起動時と停止時、セッションの作成と破棄に処理を差し込む。"
                        + "呼ぶのはコンテナで、こちらは実装して登録するだけ。"
                        + "セッションに値を入れる・消す・破棄すると、どのメソッドが"
                        + "どの順に呼ばれるかをその場で確かめられます。")
                .tags("リスナー", "Listener", "ServletContextListener", "HttpSessionListener",
                        "HttpSessionAttributeListener", "WebListener", "起動処理", "後始末",
                        "セッション", "メモリリーク")
                .source(ListenerServlet.class)
                .source(AppLifecycleListener.class)
                .source(SessionLifecycleListener.class)
                .source(ListenerEvent.class)
                .source(ListenerEventLog.class)
                .source(CatalogInitializer.class)
                .build());

        samples.add(Sample.builder("async", Category.ADVANCED)
                .title("時間のかかる処理を非同期で動かす")
                .summary("AsyncContext でコンテナのスレッドを先に返し、"
                        + "終わってから別のスレッドで応答する。同期と非同期を並べて実行し、"
                        + "どのスレッドが待っていたか、時間切れをどう返すか、"
                        + "同時に投げると順番待ちがどこに現れるかまで。")
                .tags("非同期", "AsyncContext", "AsyncListener", "asyncSupported", "スレッド",
                        "スレッドプール", "タイムアウト", "complete", "dispatch", "503")
                .source(AsyncServlet.class)
                .source(AsyncApiServlet.class)
                .source(AsyncJobListener.class)
                .source(AsyncWorkerPool.class)
                .source(Json.class)
                .build());

        // ------------------------------------------------------------------
        // 「これから作るサンプル」を先に登録しておくこともできます。
        // status(SampleStatus.PLANNED) を付けると、一覧にグレー表示され、
        // リンクは張られません (JSP はまだ無くて構いません)。
        //
        // samples.add(Sample.builder("pdf-download", Category.FILE)
        //         .title("PDF を出力する")
        //         .summary("帳票を PDF で作ってダウンロードさせる。")
        //         .status(SampleStatus.PLANNED)
        //         .tags("PDF", "帳票", "ダウンロード")
        //         .build());
        // ------------------------------------------------------------------

        return samples;
    }
}
