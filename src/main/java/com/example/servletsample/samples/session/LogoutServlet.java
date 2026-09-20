package com.example.servletsample.samples.session;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;

/**
 * 【サンプル】ログアウト。
 *
 * <h2>ログアウトは POST で受ける</h2>
 * <p>このクラスは {@code doPost} しか実装していません。
 * {@code doGet} を実装しないと、{@link javax.servlet.http.HttpServlet} の既定の動きで
 * <b>405 (Method Not Allowed)</b> が返ります。これは意図した動作です。</p>
 *
 * <p>ログアウトを GET で受けると、次のような仕掛けで<b>勝手にログアウトさせられます</b>。</p>
 *
 * <pre>{@code
 * <!-- 攻撃者のページに、こう書いておくだけ -->
 * <img src="https://example.com/logout" width="1" height="1">
 * }</pre>
 *
 * <p>ブラウザは画像を読み込もうとして、その URL へ Cookie 付きで GET します。
 * 実害はログアウトだけとはいえ、<b>状態を変える処理を GET で受けない</b>という
 * 原則そのものは、退会・削除・送金でも同じです。</p>
 *
 * <p>GET / POST の使い分けの目安は「何度呼んでも結果が変わらないか」です。
 * 変わらないなら GET、変わるなら POST。
 * ブラウザや中継サーバは GET を勝手に再実行・先読み・キャッシュすることがあります。</p>
 *
 * <h2>セッションごと捨てる</h2>
 * <p>{@code removeAttribute("loginUser")} だけで済ませる実装をときどき見かけますが、
 * それでは<b>カートや検索条件など他の値が残ります</b>。
 * {@link HttpSession#invalidate()} でセッションごと捨てるのが基本です。</p>
 */
@WebServlet(name = "logout", urlPatterns = {"/samples/session/login/logout"})
public class LogoutServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 無ければ作らない。ログアウトのために新しいセッションを作る意味はない
        HttpSession session = request.getSession(false);
        if (session != null) {
            // セッションごと捨てる。この 1 行で、中に入っていた値はすべて無くなる
            session.invalidate();
        }

        // invalidate のあとに Flash.set を呼ぶと、新しいセッションが作られてそこへ入ります。
        // 「ログアウトしました」を次の画面で 1 回だけ出すために、ここでは意図的にそうしています
        Flash.set(request, "info", "ログアウトしました", "セッションを破棄しました。");

        // PRG。再読み込みでログアウト処理が走らないようにする
        response.sendRedirect(request.getContextPath() + LoginServlet.PATH);
    }
}
