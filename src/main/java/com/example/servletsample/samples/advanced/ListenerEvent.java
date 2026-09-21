package com.example.servletsample.samples.advanced;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * リスナーが捕まえた出来事 1 件分。
 *
 * <p>リスナー (Listener) は「アプリが起動した」「セッションが作られた」といった
 * <b>節目</b>でコンテナから呼ばれます。呼ばれたことを画面で見えるようにするため、
 * 1 回の呼び出しを 1 件の記録としてこのクラスに詰め、
 * {@link ListenerEventLog} に預けています。</p>
 *
 * <p>実際のアプリでは、この役目はログ出力 ({@code context.log(...)} や SLF4J) が担います。
 * 画面に出しているのはサンプル都合です。</p>
 */
public final class ListenerEvent {

    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm:ss.SSS");

    private final int seq;
    private final LocalDateTime at;
    private final Kind kind;
    private final String source;
    private final String method;
    private final String message;

    ListenerEvent(int seq, LocalDateTime at, Kind kind, String source, String method, String message) {
        this.seq = seq;
        this.at = at;
        this.kind = kind;
        this.source = source;
        this.method = method;
        this.message = message;
    }

    /** 通し番号 (1 から)。 */
    public int getSeq() {
        return seq;
    }

    /** 記録した時刻。 */
    public LocalDateTime getAt() {
        return at;
    }

    /** 画面に出す時刻 ({@code 12:34:56.789})。 */
    public String getTime() {
        return TIME_FORMAT.format(at);
    }

    /** アプリ / セッション / 属性 の区別。 */
    public Kind getKind() {
        return kind;
    }

    /** 記録したリスナーのクラス名。 */
    public String getSource() {
        return source;
    }

    /** コンテナから呼ばれたメソッド名。例: {@code sessionCreated} */
    public String getMethod() {
        return method;
    }

    /** 何が起きたか。 */
    public String getMessage() {
        return message;
    }

    @Override
    public String toString() {
        return getTime() + " " + source + "#" + method + " " + message;
    }

    /** 出来事の種類。画面のバッジの色分けに使う。 */
    public enum Kind {

        /** アプリ (ServletContext) の起動・停止。 */
        APPLICATION("アプリ", "primary"),

        /** セッションの作成・破棄。 */
        SESSION("セッション", "success"),

        /** セッションに置いた値の出し入れ。 */
        ATTRIBUTE("属性", "secondary");

        private final String label;
        private final String variant;

        Kind(String label, String variant) {
            this.label = label;
            this.variant = variant;
        }

        /** 画面に出す名前。 */
        public String getLabel() {
            return label;
        }

        /** Bootstrap のバッジ色 (badge-primary など)。 */
        public String getVariant() {
            return variant;
        }
    }
}
