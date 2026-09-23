package com.example.servletsample.samples.shared;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.samples.form.EmployeeMaster;
import com.example.servletsample.shared.CodeFormatter;
import com.example.servletsample.shared.ClassOrigin;
import com.example.servletsample.shared.CodeResolver;
import com.example.servletsample.shared.ResolverRegistry;
import com.example.servletsample.shared.SharedLibrary;

/**
 * 【サンプル】インタフェースで共通側とアプリ側を切り離す。
 *
 * <p>JAR を分けるだけでは「共通側がアプリの事情を知ってしまう」問題は解けません。
 * 共通ライブラリに業務ルールを書き始めると、
 * やがて {@code if (アプリA なら…)} が生えて動かせなくなります。</p>
 *
 * <p>この画面では、共通側が {@link CodeResolver} という<b>形</b>だけを持ち、
 * 実装はアプリ側にある状態を実際に動かします。
 * 共通側は実装クラスの名前を 1 つも知りません
 * ({@link java.util.ServiceLoader} が探してきます)。</p>
 */
@WebServlet(name = "sharedInterface", urlPatterns = {"/samples/shared/shared-interface"})
public class SharedInterfaceServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 登録されている実装を集める。共通側が知っているのは CodeResolver という型だけ
        List<CodeResolver> resolvers = ResolverRegistry.all();

        // 画面には「実装がどこから読まれたか」も並べたいので、行の形にまとめる。
        // EL では ${x.class.simpleName} と書けない (class が EL の予約語) ため、
        // クラス名は Java 側で取り出しておく必要があります。
        List<Row> rows = new ArrayList<>(resolvers.size());
        for (CodeResolver resolver : resolvers) {
            rows.add(new Row(resolver, SharedLibrary.originOf(resolver.getClass())));
        }
        request.setAttribute("rows", rows);
        request.setAttribute("sharedVersion", SharedLibrary.VERSION);
        request.setAttribute("employeeSamples", EmployeeMaster.all());
        request.setAttribute("productSamples", ProductCodeResolver.all());

        String input = request.getParameter("code");
        if (input != null) {
            // ① 表記を揃える (共通側の処理。どのアプリでも意味が変わらない)
            String normalized = CodeFormatter.normalize(input);
            request.setAttribute("input", input);
            request.setAttribute("normalized", normalized);

            if (normalized.isEmpty()) {
                request.setAttribute("message", "コードを入力してください。");
            } else {
                // ② 扱える実装を探す (どのアプリの実装が選ばれるかは共通側は知らない)
                Optional<CodeResolver> resolver = ResolverRegistry.forCode(normalized);
                if (resolver.isEmpty()) {
                    request.setAttribute("message",
                            "このコードを扱える実装がありません。E + 4 桁 か P + 3 桁 で入力してください。");
                } else {
                    CodeResolver chosen = resolver.get();
                    request.setAttribute("chosen", chosen);
                    request.setAttribute("chosenOrigin", SharedLibrary.originOf(chosen.getClass()));

                    // ③ 引き当てる (業務ルールはこの実装の中。共通側には無い)
                    String resolved = chosen.resolve(normalized);
                    if (resolved == null) {
                        request.setAttribute("message",
                                "形は合っていますが、マスタに登録がありません。");
                    } else {
                        request.setAttribute("resolved", resolved);
                    }
                }
            }
        }

        render(request, response, "samples/shared/shared-interface");
    }

    /** 画面 1 行分。実装と、その実装がどこから読まれたか。 */
    public static final class Row {

        private final CodeResolver resolver;
        private final ClassOrigin origin;

        Row(CodeResolver resolver, ClassOrigin origin) {
            this.resolver = resolver;
            this.origin = origin;
        }

        public CodeResolver getResolver() {
            return resolver;
        }

        public ClassOrigin getOrigin() {
            return origin;
        }
    }
}
