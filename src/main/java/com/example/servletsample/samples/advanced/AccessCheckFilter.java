package com.example.servletsample.samples.advanced;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * 【サンプル】3 番目のフィルタ : 条件に合わないリクエストをここで止める。
 *
 * <p>フィルタのもう 1 つの役目が<b>門番</b>です。
 * {@code chain.doFilter(...)} を<b>呼ばなければ</b>、その先 (Servlet) は動きません。
 * ログインしていない人を弾く、メンテナンス中の案内を出す、といった処理はこの形になります。</p>
 *
 * <pre>{@code
 * if (ログインしていない) {
 *     response.sendRedirect(request.getContextPath() + "/login");
 *     return;                       // ← chain.doFilter を呼ばずに終わる
 * }
 * chain.doFilter(request, response);
 * }</pre>
 *
 * <p><b>{@code return} の書き忘れがいちばん危ない</b>ところです。
 * リダイレクトやエラーを返したあとに {@code chain.doFilter} まで進んでしまうと、
 * 弾いたはずの処理がそのまま動きます。
 * 「弾いたら必ず {@code return}」を守ってください。</p>
 *
 * <h2>このサンプルでの止め方</h2>
 * <p>本物の権限チェックの代わりに、{@code ?blocked=1} が付いていたら
 * 「権限が無かった」とみなして {@code sendError(403)} で止めています。
 * コンテナは {@code web.xml} の {@code <error-page>} にしたがって
 * 403 用のエラーページを表示します
 * (「エラー処理とエラーページ」のサンプルで用意したものです)。</p>
 *
 * <h2>フィルタが呼ばれるタイミング</h2>
 * <p>{@code <filter-mapping>} に何も書かなければ、フィルタが動くのは
 * <b>ブラウザから届いたリクエスト ({@code REQUEST})</b> のときだけです。
 * Servlet から JSP への {@code forward} では動きません。</p>
 *
 * <pre>{@code
 * <filter-mapping>
 *   <filter-name>accessCheckFilter</filter-name>
 *   <url-pattern>/samples/advanced/filter/*</url-pattern>
 *   <dispatcher>REQUEST</dispatcher>     <!-- 既定。ブラウザから来たとき -->
 *   <dispatcher>FORWARD</dispatcher>     <!-- forward 先でも動かしたいとき -->
 *   <dispatcher>INCLUDE</dispatcher>
 *   <dispatcher>ERROR</dispatcher>       <!-- エラーページへ転送されるとき -->
 * </filter-mapping>
 * }</pre>
 *
 * <p>ログインチェックのフィルタで {@code FORWARD} まで足してしまうと、
 * 画面表示のたびに二重で動きます。
 * 逆に {@code /WEB-INF/} の JSP を直接守りたいときは {@code FORWARD} が要ります
 * (このサイトは JSP をすべて {@code /WEB-INF/} に置いているため、その心配はありません)。</p>
 */
public class AccessCheckFilter implements Filter {

    /** 画面の記録に出す名前。 */
    static final String NAME = "AccessCheckFilter";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        FilterTrace trace = FilterTrace.of(request);

        // 本来はセッションを見てログイン済みかどうかを判定するところ。
        // サンプルなので、URL に ?blocked=1 が付いていたら「権限が無い」とみなします
        boolean allowed = !"1".equals(httpRequest.getParameter("blocked"));

        if (!allowed) {
            if (trace != null) {
                trace.enter(NAME, "権限が無いと判断した");
                trace.run(NAME, "chain.doFilter を呼ばずに 403 を返す → この先の Servlet は動かない");
                trace.exit(NAME, "ここで折り返した");
            }
            httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "この操作を行う権限がありません (AccessCheckFilter が止めました)");
            return;   // ← これを忘れると、弾いたはずの処理が動いてしまう
        }

        if (trace != null) {
            trace.enter(NAME, "通過を許可した");
        }
        try {
            chain.doFilter(request, response);
        } finally {
            if (trace != null) {
                trace.exit(NAME, "特にすることは無いのでそのまま戻す");
            }
        }
    }
}
