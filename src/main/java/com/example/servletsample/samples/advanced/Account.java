package com.example.servletsample.samples.advanced;

/**
 * トランザクションのサンプルで使う口座。
 *
 * <p>「振替」は、<b>1 つの処理に見えて中身は複数の更新</b>という、
 * トランザクションの説明にちょうどよい題材です。</p>
 *
 * <pre>{@code
 * ① 送金元から引く      UPDATE accounts SET balance = balance - ? WHERE id = ?
 * ② 送金先に足す        UPDATE accounts SET balance = balance + ? WHERE id = ?
 * ③ 履歴を残す          INSERT INTO transfers ...
 * }</pre>
 *
 * <p>①だけ成功して②で落ちると、<b>お金が消えます</b>。
 * 「全部やるか、1 つもやらないか」にするのがトランザクションです。</p>
 */
public final class Account {

    private final long id;
    private final String code;
    private final String name;
    private final int balance;

    Account(long id, String code, String name, int balance) {
        this.id = id;
        this.code = code;
        this.name = name;
        this.balance = balance;
    }

    /** 口座 ID。 */
    public long getId() {
        return id;
    }

    /** 口座番号。 */
    public String getCode() {
        return code;
    }

    /** 名義。 */
    public String getName() {
        return name;
    }

    /** 残高。 */
    public int getBalance() {
        return balance;
    }

    @Override
    public String toString() {
        return code + " " + name + " " + balance;
    }
}
