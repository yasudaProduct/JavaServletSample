package com.example.servletsample.samples.list;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 取引先マスタの 1 件。
 *
 * <p>「マスタメンテナンス」と「更新の競合（楽観ロック）」の 2 つのサンプルで共有しています。</p>
 *
 * <h2>version 列</h2>
 * <p>更新のたびに 1 ずつ増える数です。<b>楽観ロックのためだけにある列</b>で、
 * 業務上の意味はありません。</p>
 *
 * <pre>{@code
 * 画面を開いたとき : version = 3 を画面に隠して持たせる
 * 更新するとき     : UPDATE ... SET version = version + 1 WHERE id = ? AND version = 3
 *                    → 更新できた行が 0 なら、その間に誰かが更新している
 * }</pre>
 *
 * <p>{@code updated_at} で代用することもできますが、
 * <b>同じ秒のうちに 2 回更新されると見分けられません</b>。
 * 専用の列を持つほうが確実です。</p>
 */
public final class Customer {

    private static final DateTimeFormatter TIME_FORMAT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final long id;
    private final String code;
    private final String name;
    private final String contact;
    private final String email;
    private final int version;
    private final LocalDateTime updatedAt;

    Customer(long id, String code, String name, String contact, String email,
             int version, LocalDateTime updatedAt) {
        this.id = id;
        this.code = code;
        this.name = name;
        this.contact = contact;
        this.email = email;
        this.version = version;
        this.updatedAt = updatedAt;
    }

    /** 取引先 ID。 */
    public long getId() {
        return id;
    }

    /** 取引先コード。 */
    public String getCode() {
        return code;
    }

    /** 取引先名。 */
    public String getName() {
        return name;
    }

    /** 担当者。 */
    public String getContact() {
        return contact;
    }

    /** メールアドレス。 */
    public String getEmail() {
        return email;
    }

    /** 更新のたびに増える数 (楽観ロック用)。 */
    public int getVersion() {
        return version;
    }

    /** 最終更新日時。 */
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    /** 画面に出す最終更新日時。 */
    public String getUpdatedAtText() {
        return updatedAt == null ? "" : updatedAt.format(TIME_FORMAT);
    }

    @Override
    public String toString() {
        return code + " " + name + " (v" + version + ")";
    }
}
