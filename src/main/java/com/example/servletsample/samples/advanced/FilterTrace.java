package com.example.servletsample.samples.advanced;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.servlet.ServletRequest;

/**
 * 1 リクエストが「どのフィルタをどの順で通ったか」の記録。
 *
 * <p>フィルタは目に見えないところで動くため、順番や入れ子の形が分かりにくくなりがちです。
 * このクラスは、通過したところを順に書き留めて画面に出すための<b>サンプル専用の道具</b>です。
 * 実際のアプリでは、この役目はログやトレーシング (OpenTelemetry など) が担います。</p>
 *
 * <p>1 つのリクエストは 1 つのスレッドが処理するので、書き込み中に別のスレッドが
 * 割り込むことはありません。そのため、このクラス自体は同期していません。
 * 記録し終えたものを他のリクエストから読めるようにするのは
 * {@link FilterTraceStore} の役目で、そちらは同期しています。</p>
 */
public final class FilterTrace {

    /** リクエストスコープに入れるときの属性名 (JSP からは {@code ${filterTrace}})。 */
    public static final String ATTRIBUTE_NAME = "filterTrace";

    private final String id;
    private final String method;
    private final String uri;
    private final List<Step> steps = new ArrayList<>();

    /** 入れ子の深さ。前処理で 1 つ深くなり、後処理で 1 つ浅くなる。 */
    private int depth;

    private long elapsedMillis = -1L;
    private boolean finished;

    FilterTrace(String id, String method, String uri) {
        this.id = id;
        this.method = method;
        this.uri = uri;
    }

    /**
     * リクエストスコープから記録を取り出す。
     *
     * <p>フィルタが登録されていない URL では {@code null} が返ります。
     * 呼び出し側は「記録が取れないこともある」前提で書いてください。</p>
     */
    public static FilterTrace of(ServletRequest request) {
        Object trace = request.getAttribute(ATTRIBUTE_NAME);
        return trace instanceof FilterTrace ? (FilterTrace) trace : null;
    }

    /** 前処理 ({@code chain.doFilter} を呼ぶ前) を記録する。 */
    public void enter(String name, String message) {
        steps.add(new Step(steps.size() + 1, Phase.BEFORE, name, message, depth));
        depth++;
    }

    /** 後処理 ({@code chain.doFilter} から戻ってきたあと) を記録する。 */
    public void exit(String name, String message) {
        depth = Math.max(0, depth - 1);
        steps.add(new Step(steps.size() + 1, Phase.AFTER, name, message, depth));
    }

    /** フィルタではない処理 (Servlet 本体など) を記録する。 */
    public void run(String name, String message) {
        steps.add(new Step(steps.size() + 1, Phase.RUN, name, message, depth));
    }

    /** いちばん外側のフィルタが、処理を終えるときに呼ぶ。 */
    void finish(long elapsedMillis) {
        this.elapsedMillis = elapsedMillis;
        this.finished = true;
    }

    /** リクエスト ID。レスポンスヘッダ {@code X-Request-Id} と同じ値。 */
    public String getId() {
        return id;
    }

    /** HTTP メソッド。 */
    public String getMethod() {
        return method;
    }

    /** リクエストされた URL。 */
    public String getUri() {
        return uri;
    }

    /** 記録された通過点。登録した順に並びます。 */
    public List<Step> getSteps() {
        return Collections.unmodifiableList(steps);
    }

    /** 全体の処理時間 (ミリ秒)。まだ終わっていなければ {@code -1}。 */
    public long getElapsedMillis() {
        return elapsedMillis;
    }

    /** いちばん外側のフィルタまで戻ってきたかどうか。 */
    public boolean isFinished() {
        return finished;
    }

    /** 通過点 1 件分。 */
    public static final class Step {

        private final int seq;
        private final Phase phase;
        private final String name;
        private final String message;
        private final int depth;

        Step(int seq, Phase phase, String name, String message, int depth) {
            this.seq = seq;
            this.phase = phase;
            this.name = name;
            this.message = message;
            this.depth = depth;
        }

        /** 通し番号 (1 から)。 */
        public int getSeq() {
            return seq;
        }

        /** 前処理 / 本体 / 後処理の区別。 */
        public Phase getPhase() {
            return phase;
        }

        /** フィルタや Servlet の名前。 */
        public String getName() {
            return name;
        }

        /** その場で何をしたか。 */
        public String getMessage() {
            return message;
        }

        /** 入れ子の深さ (画面の字下げに使う)。 */
        public int getDepth() {
            return depth;
        }
    }

    /** 通過点の種類。 */
    public enum Phase {

        /** {@code chain.doFilter} を呼ぶ前。 */
        BEFORE("前処理", "→", "primary"),

        /** Servlet 本体。 */
        RUN("本体", "●", "success"),

        /** {@code chain.doFilter} から戻ったあと。 */
        AFTER("後処理", "←", "secondary");

        private final String label;
        private final String mark;
        private final String variant;

        Phase(String label, String mark, String variant) {
            this.label = label;
            this.mark = mark;
            this.variant = variant;
        }

        /** 画面に出す名前。 */
        public String getLabel() {
            return label;
        }

        /** 画面に出す記号。 */
        public String getMark() {
            return mark;
        }

        /** Bootstrap のバッジ色。 */
        public String getVariant() {
            return variant;
        }
    }
}
