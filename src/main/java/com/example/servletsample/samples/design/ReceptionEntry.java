package com.example.servletsample.samples.design;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * モーダルのサンプルで登録した受付 1 件分。
 *
 * <p>「登録 → 完了モーダル → 一覧画面へ移動」の流れを見せるための入れ物です。
 * データベースではなく<b>セッション</b>に持たせているので、
 * 他の人が開いている画面には影響しません (ブラウザを閉じると消えます)。</p>
 */
public final class ReceptionEntry implements Serializable {

    private static final long serialVersionUID = 1L;

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");

    private final String receiptNumber;
    private final String name;
    private final LocalDateTime registeredAt;

    ReceptionEntry(String receiptNumber, String name, LocalDateTime registeredAt) {
        this.receiptNumber = receiptNumber;
        this.name = name;
        this.registeredAt = registeredAt;
    }

    /** 受付番号。例: {@code A-20260919-0003} */
    public String getReceiptNumber() {
        return receiptNumber;
    }

    /** 登録された名前。 */
    public String getName() {
        return name;
    }

    public LocalDateTime getRegisteredAt() {
        return registeredAt;
    }

    /** 画面に出す登録日時。 */
    public String getRegisteredAtText() {
        return registeredAt == null ? "" : registeredAt.format(FORMATTER);
    }

    @Override
    public String toString() {
        return receiptNumber + " " + name;
    }
}
