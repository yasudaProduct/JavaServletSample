package com.example.servletsample.samples.session;

/**
 * 利用者の役割 (ロール)。
 *
 * <p>「この人に何を許すか」を決めるための区分です。
 * 利用者 1 人ずつに「あれができる / これができない」を持たせると管理しきれなくなるため、
 * <b>役割をはさんで</b>「役割に権限をひもづけ、利用者に役割を割り当てる」形にします。</p>
 *
 * <p>このサンプルでは 2 種類だけですが、考え方は増えても同じです。</p>
 */
public enum Role {

    /** 一般の利用者。自分の情報を見られる。 */
    MEMBER("一般", "secondary"),

    /** 管理者。管理用の画面も見られる。 */
    ADMIN("管理者", "danger");

    private final String label;
    private final String variant;

    Role(String label, String variant) {
        this.label = label;
        this.variant = variant;
    }

    /** 画面に表示する名前。 */
    public String getLabel() {
        return label;
    }

    /** Bootstrap のバッジ色。 */
    public String getVariant() {
        return variant;
    }

    /** 管理者かどうか。 */
    public boolean isAdmin() {
        return this == ADMIN;
    }
}
