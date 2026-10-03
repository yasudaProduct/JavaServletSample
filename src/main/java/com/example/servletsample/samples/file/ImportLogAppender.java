package com.example.servletsample.samples.file;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.LoggerContext;
import org.apache.logging.log4j.core.appender.AbstractAppender;
import org.apache.logging.log4j.core.config.Configuration;
import org.apache.logging.log4j.core.config.Property;
import org.apache.logging.log4j.core.layout.PatternLayout;

/**
 * 取り込み 1 回ぶんのログを、画面に出すためにメモリへ取っておく Appender。
 *
 * <p><b>このクラスは画面にログを見せるためだけのもので、実際のアプリには要りません。</b>
 * ログはファイル ({@code log4j2.xml} の {@code File}) に出して、そちらを見ます。
 * このサイトは公開デモで、サーバのログファイルを見られない人にも
 * 「実際に何が出たか」を見せたいので置いています。</p>
 *
 * <p>Appender は「ログをどこへ書くか」を受け持つ部品です。
 * {@code log4j2.xml} に書いた {@code Console} (標準出力) や {@code RollingFile} (ファイル) も Appender で、
 * 1 つのロガーに複数つなぐと、同じ 1 行がそれぞれへ書かれます。
 * これを {@code Root} につなぎ、取り込み ID ({@code %X{importId}}) が付いた行だけを取っておきます。</p>
 *
 * <p>Log4j のプラグインとして {@code log4j2.xml} に書く方法もありますが、
 * ビルド時の注釈処理 (アノテーションプロセッサ) が必要になり、
 * Eclipse の既定の設定では動きません。ここではプログラムからつないでいます。</p>
 */
public final class ImportLogAppender extends AbstractAppender {

    /** Appender の名前。 */
    static final String NAME = "CsvImportScreen";

    /** 書式。log4j2.xml の pattern と同じにしてある (画面とファイルで同じ 1 行になる)。 */
    static final String PATTERN = "%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level [%t] [%X{importId}] %logger{1}"
            + " - %enc{%m}{CRLF}%n%ex{filters(org.apache.catalina,org.apache.coyote,org.apache.tomcat)}";

    /** 取っておく取り込みの数 (古いものから捨てる)。 */
    private static final int MAX_IMPORTS = 50;

    /** 取り込み 1 回ぶんで取っておく行の上限。 */
    private static final int MAX_LINES_PER_IMPORT = 100;

    /** 取り込み ID → その取り込みで出たログ。古いものから捨てる。 */
    private static final Map<String, List<LogLine>> LINES = new LinkedHashMap<>() {
        private static final long serialVersionUID = 1L;

        @Override
        protected boolean removeEldestEntry(Map.Entry<String, List<LogLine>> eldest) {
            return size() > MAX_IMPORTS;
        }
    };

    private final PatternLayout layout;

    private ImportLogAppender(PatternLayout layout) {
        super(NAME, null, layout, true, Property.EMPTY_ARRAY);
        this.layout = layout;
    }

    /**
     * Log4j の設定に、この Appender を (まだなら) つなぐ。何度呼んでもよい。
     *
     * <p>{@code log4j2.xml} を読み直すと、プログラムでつないだ Appender は外れます。
     * このサンプルは読み直す設定 ({@code monitorInterval}) にしていないので、起動時に 1 回つなげば足ります。</p>
     */
    public static synchronized void install() {
        LoggerContext context = LoggerContext.getContext(false);
        Configuration configuration = context.getConfiguration();
        if (configuration.getAppenders().containsKey(NAME)) {
            return;
        }
        PatternLayout layout = PatternLayout.newBuilder()
                .setPattern(PATTERN)
                .setConfiguration(configuration)
                .build();
        ImportLogAppender appender = new ImportLogAppender(layout);
        appender.start();
        configuration.addAppender(appender);
        configuration.getRootLogger().addAppender(appender, null, null);
        context.updateLoggers();
    }

    /** その取り込みで出たログ (出た順)。 */
    public static List<LogLine> linesOf(String importId) {
        synchronized (LINES) {
            List<LogLine> lines = LINES.get(importId);
            return lines == null ? List.of() : Collections.unmodifiableList(new ArrayList<>(lines));
        }
    }

    @Override
    public void append(LogEvent event) {
        String importId = event.getContextData().getValue(CsvImporter.IMPORT_ID_KEY);
        if (importId == null) {
            return;   // 取り込みの外で出たログは取っておかない
        }
        LogLine line = new LogLine(event.getLevel().name(), layout.toSerializable(event));
        synchronized (LINES) {
            List<LogLine> lines = LINES.computeIfAbsent(importId, key -> new ArrayList<>());
            if (lines.size() < MAX_LINES_PER_IMPORT) {
                lines.add(line);
            }
        }
    }

    /** ログ 1 件 (例外があればスタックトレースまで含む)。 */
    public static final class LogLine {

        private final String level;
        private final String text;

        LogLine(String level, String text) {
            this.level = level;
            this.text = text;
        }

        /** レベル (ERROR / WARN / INFO / DEBUG)。 */
        public String getLevel() {
            return level;
        }

        /** 書式どおりに組み立てた行。 */
        public String getText() {
            return text;
        }
    }
}
