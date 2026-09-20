package com.example.servletsample.common;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 入力チェックの結果 (どの項目に、どんなエラーがあるか) を入れておく箱。
 *
 * <p>項目ごとのメッセージと、項目に紐づかないメッセージ (「ログインできません」など) を持てます。
 * 項目ごとのメッセージは<b>最初に入れた 1 件だけ</b>を残します。
 * 1 つの欄にいくつもメッセージが並ぶと読みにくいためです。</p>
 *
 * <p>JSP からはこう使います。</p>
 * <pre>{@code
 * <c:if test="${errors.hasErrors}"> ... </c:if>
 * <input class="form-control ${errors.has('name') ? 'is-invalid' : ''}" ...>
 * <div class="invalid-feedback">${fn:escapeXml(errors.get('name'))}</div>
 * }</pre>
 *
 * <p><b>注意</b>: {@code empty} は EL の予約語なので、
 * {@code ${errors.empty}} とは書けません (画面が 500 エラーになります)。
 * このクラスが {@code isEmpty()} ではなく {@link #hasErrors()} を持っているのはそのためです。</p>
 */
public final class ValidationErrors implements Serializable {

    private static final long serialVersionUID = 1L;

    private final Map<String, String> fields = new LinkedHashMap<>();
    private final List<String> globals = new ArrayList<>();

    /** 項目のエラーを追加する (同じ項目に 2 件目を入れても、最初の 1 件が残る)。 */
    public ValidationErrors add(String field, String message) {
        fields.putIfAbsent(field, message);
        return this;
    }

    /** 条件が成り立たないときだけ項目のエラーを追加する。 */
    public ValidationErrors addIf(boolean invalid, String field, String message) {
        if (invalid) {
            add(field, message);
        }
        return this;
    }

    /** 項目に紐づかないエラーを追加する。 */
    public ValidationErrors addGlobal(String message) {
        globals.add(message);
        return this;
    }

    /** エラーが 1 件でもあるか。 */
    public boolean hasErrors() {
        return !fields.isEmpty() || !globals.isEmpty();
    }

    /** その項目にエラーがあるか。 */
    public boolean has(String field) {
        return fields.containsKey(field);
    }

    /** その項目のメッセージ。無ければ空文字。 */
    public String get(String field) {
        return fields.getOrDefault(field, "");
    }

    /** 項目ごとのメッセージ (登録順)。 */
    public Map<String, String> getFields() {
        return Collections.unmodifiableMap(fields);
    }

    /** 項目に紐づかないメッセージ。 */
    public List<String> getGlobals() {
        return Collections.unmodifiableList(globals);
    }

    /** 画面の先頭にまとめて出すためのメッセージ一覧。 */
    public List<String> getMessages() {
        List<String> messages = new ArrayList<>(globals);
        messages.addAll(fields.values());
        return Collections.unmodifiableList(messages);
    }

    /** エラーの件数。 */
    public int getCount() {
        return fields.size() + globals.size();
    }

    @Override
    public String toString() {
        return "ValidationErrors" + getMessages();
    }
}
