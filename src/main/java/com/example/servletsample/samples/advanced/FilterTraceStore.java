package com.example.servletsample.samples.advanced;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 処理を終えた {@link FilterTrace} を、直近の数件だけ預かっておく置き場。
 *
 * <p>フィルタの<b>後処理</b>は、画面 (JSP) を組み立て終わったあとに動きます。
 * そのため「そのリクエストの記録」を、そのリクエストの画面に出すことはできません。
 * そこでいったんここに預けておき、あとから別のリクエストで取りに来ます。</p>
 *
 * <pre>{@code
 * ① fetch  /samples/advanced/filter/api           → フィルタを通って記録が完成し、ここへ入る
 * ② fetch  /samples/advanced/filter/api?trace=R-3 → ①の記録を JSON で取り出す
 * }</pre>
 *
 * <h2>アプリ全体で 1 つの入れ物を共有するということ</h2>
 * <p>{@code static} のフィールドはアプリ全体で 1 つなので、
 * <b>複数のリクエスト (スレッド) が同時に読み書きします</b>。
 * {@link LinkedHashMap} はそのままでは同時アクセスに耐えられないため、
 * 出入り口のメソッドをすべて {@code synchronized} にしています。</p>
 *
 * <p>もう 1 つ大事なのが<b>上限</b>です。記録を消さずに貯め続けると、
 * アクセスがあるだけメモリを食い続け、いつかアプリが落ちます
 * ({@code removeEldestEntry} で古いものから捨てています)。
 * 「アプリ全体で共有する入れ物には必ず上限を付ける」は、
 * キャッシュを自作するときにも同じことが言えます。</p>
 */
public final class FilterTraceStore {

    /** 預かっておく件数の上限。 */
    private static final int MAX_ENTRIES = 20;

    /**
     * リクエスト ID → 記録。
     *
     * <p>{@link LinkedHashMap} は入れた順を覚えているので、
     * あふれたときに「いちばん古いもの」を捨てられます。</p>
     */
    private static final Map<String, FilterTrace> TRACES =
            new LinkedHashMap<>(MAX_ENTRIES + 1, 0.75f, false) {

                private static final long serialVersionUID = 1L;

                @Override
                protected boolean removeEldestEntry(Map.Entry<String, FilterTrace> eldest) {
                    return size() > MAX_ENTRIES;
                }
            };

    private FilterTraceStore() {
    }

    /** 処理を終えた記録を預ける。 */
    static synchronized void save(FilterTrace trace) {
        TRACES.put(trace.getId(), trace);
    }

    /** リクエスト ID で記録を探す。まだ預けられていなければ {@code null}。 */
    public static synchronized FilterTrace find(String id) {
        return id == null ? null : TRACES.get(id);
    }

    /** 預かっている記録を新しい順に返す。 */
    public static synchronized List<FilterTrace> recent() {
        List<FilterTrace> all = new ArrayList<>(TRACES.values());
        Collections.reverse(all);
        return all;
    }

    /** 預かっている記録をすべて捨てる (画面の「消す」ボタン用)。 */
    public static synchronized void clear() {
        TRACES.clear();
    }
}
