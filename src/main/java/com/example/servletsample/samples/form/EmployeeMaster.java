package com.example.servletsample.samples.form;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * 社員マスタの代わり (固定データ)。
 *
 * <p>「入力された社員コードが実在するか」を確かめるための一覧です。
 * <b>実際のアプリではデータベースを引きます</b>
 * (DAO の書き方は {@code samples/list/ProductDao.java} が実例です)。
 * このサンプルは入力チェックの種類を見せるのが目的なので、
 * 話が逸れないように固定のデータにしてあります。</p>
 *
 * <h2>マスタ突き合わせは最後に行う</h2>
 * <p>「形は合っているか」を先に確かめ、<b>通ったものだけをマスタに問い合わせます</b>。
 * 理由は 2 つあります。</p>
 * <ul>
 *   <li>データベースへの問い合わせは、文字列の判定よりずっと時間がかかる</li>
 *   <li>形が壊れた値 (空文字や 100 文字の文字列) を検索しても意味がない</li>
 * </ul>
 */
public final class EmployeeMaster {

    private static final List<Employee> EMPLOYEES = Arrays.asList(
            new Employee("E1001", "山田 太郎", "情報システム部"),
            new Employee("E1002", "佐藤 花子", "情報システム部"),
            new Employee("E1003", "鈴木 一郎", "営業部"),
            new Employee("E2001", "田中 美咲", "営業部"),
            new Employee("E2002", "高橋 健", "総務部"),
            new Employee("E3001", "伊藤 涼", "経理部"));

    private EmployeeMaster() {
    }

    /** 社員の一覧 (画面の選択肢と、入力の手本として表示するために使う)。 */
    public static List<Employee> all() {
        return EMPLOYEES;
    }

    /** 社員コードから探す。見つからなければ空。 */
    public static Optional<Employee> find(String code) {
        if (code == null) {
            return Optional.empty();
        }
        return EMPLOYEES.stream()
                .filter(employee -> employee.getCode().equals(code))
                .findFirst();
    }

    /** その社員コードが実在するか。 */
    public static boolean exists(String code) {
        return find(code).isPresent();
    }

    /** 社員コードに対応する氏名。見つからなければ空文字。 */
    public static String nameOf(String code) {
        return find(code).map(Employee::getName).orElse("");
    }

    /**
     * 社員 1 人分。
     *
     * <p>JSP から {@code ${employee.code}} で読めるよう、
     * <b>public なクラスに public な getter</b> を用意しています
     * (EL はフィールド名ではなく getter を見ます)。</p>
     */
    public static final class Employee {

        private final String code;
        private final String name;
        private final String department;

        Employee(String code, String name, String department) {
            this.code = code;
            this.name = name;
            this.department = department;
        }

        /** 社員コード (半角英数字 5 桁)。 */
        public String getCode() {
            return code;
        }

        /** 氏名。 */
        public String getName() {
            return name;
        }

        /** 所属部署。 */
        public String getDepartment() {
            return department;
        }

        @Override
        public String toString() {
            return code + " " + name;
        }
    }
}
