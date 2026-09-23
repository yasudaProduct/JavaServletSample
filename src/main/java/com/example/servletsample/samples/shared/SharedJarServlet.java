package com.example.servletsample.samples.shared;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Validators;
import com.example.servletsample.shared.ClassOrigin;
import com.example.servletsample.shared.CodeResolver;
import com.example.servletsample.shared.SharedLibrary;

/**
 * 【サンプル】共通処理を JAR に切り出したとき、クラスがどこから読まれているかを見る。
 *
 * <p>複数サーバー構成の話でいちばん誤解されるのが
 * <b>「共通 JAR は 2 台の間で共有されている」</b>という思い込みです。
 * 共有されていません。それぞれの WAR の中にコピーが入っているだけです。</p>
 *
 * <p>この画面は {@code getProtectionDomain().getCodeSource()} を使って、
 * クラスごとの<b>実際の読み込み元</b>を一覧にします。
 * 「どこまでが WAR の中で、どこからが Tomcat 側か」が境界として見えます。</p>
 */
@WebServlet(name = "sharedJar", urlPatterns = {"/samples/shared/shared-jar"})
public class SharedJarServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /**
     * 読み込み元を調べて並べるクラスたち。
     *
     * <p>「共通ライブラリ」「アプリ本体」「外部ライブラリ」「Tomcat」「JDK」を
     * 1 件ずつ入れて、境界が分かるようにしています。</p>
     */
    private static final Class<?>[] TARGETS = {
            SharedLibrary.class,
            CodeResolver.class,
            Validators.class,
            EmployeeCodeResolver.class,
            javax.servlet.jsp.jstl.core.Config.class,
            javax.servlet.http.HttpServlet.class,
            String.class,
    };

    /** その行が何であるかの説明 (TARGETS と同じ順)。 */
    private static final String[] NOTES = {
            "共通ライブラリ (shared プロジェクト)",
            "共通ライブラリのインタフェース",
            "アプリ本体の共通処理",
            "アプリ本体 (CodeResolver の実装)",
            "外部ライブラリ (JSTL)",
            "Tomcat が提供する Servlet API",
            "JDK 本体",
    };

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        List<Row> rows = new ArrayList<>(TARGETS.length);
        for (int i = 0; i < TARGETS.length; i++) {
            rows.add(new Row(SharedLibrary.originOf(TARGETS[i]), NOTES[i]));
        }

        request.setAttribute("rows", rows);
        request.setAttribute("sharedVersion", SharedLibrary.VERSION);
        // 共通 JAR そのものの置き場所 (WEB-INF/lib/... になるのを見せる)
        request.setAttribute("sharedJar", SharedLibrary.originOf(SharedLibrary.class).getCodeSource());

        render(request, response, "samples/shared/shared-jar");
    }

    /** 画面 1 行分。JSP から {@code ${row.origin.simpleName}} のように参照する。 */
    public static final class Row {

        private final ClassOrigin origin;
        private final String note;

        Row(ClassOrigin origin, String note) {
            this.origin = origin;
            this.note = note;
        }

        public ClassOrigin getOrigin() {
            return origin;
        }

        public String getNote() {
            return note;
        }
    }
}
