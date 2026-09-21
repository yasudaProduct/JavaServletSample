package com.example.servletsample.samples.advanced;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * 振替を試した結果。
 *
 * <p>「何が起きたか」を画面で追えるように、通った手順も持たせています。
 * 成功／失敗だけだと、<b>rollback が効いたのかどうか</b>が見えないためです。</p>
 */
public final class TransferOutcome implements Serializable {

    private static final long serialVersionUID = 1L;

    private final List<String> steps = new ArrayList<>();
    private boolean committed;
    private boolean rolledBack;
    private final boolean autoCommit;
    private String message = "";
    private String errorType = "";

    TransferOutcome(boolean autoCommit) {
        this.autoCommit = autoCommit;
    }

    /** 手順を 1 つ書き留める。 */
    void step(String description) {
        steps.add(description);
    }

    void committed(String message) {
        this.committed = true;
        this.message = message;
    }

    void rolledBack(String message, String errorType) {
        this.rolledBack = true;
        this.message = message;
        this.errorType = errorType;
    }

    void failedWithoutRollback(String message, String errorType) {
        this.message = message;
        this.errorType = errorType;
    }

    /** 通った手順。 */
    public List<String> getSteps() {
        return Collections.unmodifiableList(steps);
    }

    /** コミットできたか。 */
    public boolean isCommitted() {
        return committed;
    }

    /** ロールバックしたか。 */
    public boolean isRolledBack() {
        return rolledBack;
    }

    /**
     * 自動コミットのまま実行したか。
     *
     * <p>{@code true} だと、途中で失敗しても<b>そこまでの更新は取り消されません</b>。</p>
     */
    public boolean isAutoCommit() {
        return autoCommit;
    }

    /** 画面に出すメッセージ。 */
    public String getMessage() {
        return message;
    }

    /** 失敗した場合の例外の型 (画面に出す)。 */
    public String getErrorType() {
        return errorType;
    }

    /** 失敗したか。 */
    public boolean isFailed() {
        return !committed;
    }
}
