package com.example.servletsample.samples.test;

import java.util.LinkedHashMap;
import java.util.Map;

import javax.servlet.http.HttpServlet;

/**
 * 【サンプル】見積もり Servlet を Tomcat 無しで 1 回動かすための補助。
 *
 * <p>{@link LegacyEstimateCharacterizationTest} と {@link EstimateGoldenMasterTest} から使います。
 * 偽の request / response を作って {@code service} を呼び、
 * Servlet が画面に渡した値 ({@code request.setAttribute} したもの) を取り出します。</p>
 *
 * <p>{@code doPost} ではなく {@code service} を呼んでいるのは、
 * 直す前 ({@link LegacyEstimateServlet}) と直した後 ({@link EstimateServlet}) を
 * 同じ {@link HttpServlet} として扱いたいからです。
 * {@code service} は HTTP メソッドを見て {@code doPost} を呼び分けます。</p>
 */
final class EstimateRequests {

    /** Servlet が画面に渡す値の名前。直す前も直した後も同じ。 */
    static final String[] RESULT_NAMES = {"amount", "ship", "discount", "tax", "total", "estimateNo"};

    private EstimateRequests() {
    }

    /**
     * 見積もりを 1 回実行し、画面に渡された値を返す。
     *
     * <p>引数に {@code null} を渡したパラメータは「送られてこなかった」扱いになります。
     * Servlet が例外を投げた場合は、そのまま呼び出し元へ投げます。</p>
     */
    static Map<String, Object> post(HttpServlet servlet, String pref, String price, String qty,
                                    String weight, String member) throws Exception {
        FakeHttpServletRequest request = new FakeHttpServletRequest().withMethod("POST");
        putIfPresent(request, "pref", pref);
        putIfPresent(request, "price", price);
        putIfPresent(request, "qty", qty);
        putIfPresent(request, "weight", weight);
        putIfPresent(request, "member", member);

        servlet.service(request, new FakeHttpServletResponse());

        Map<String, Object> result = new LinkedHashMap<>();
        for (String name : RESULT_NAMES) {
            result.put(name, request.getAttribute(name));
        }
        return result;
    }

    private static void putIfPresent(FakeHttpServletRequest request, String name, String value) {
        if (value != null) {
            request.withParameter(name, value);
        }
    }
}
