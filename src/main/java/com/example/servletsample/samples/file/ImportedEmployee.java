package com.example.servletsample.samples.file;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * CSV から取り込んだ社員 1 人ぶん (テーブル {@code csv_import_employees} の 1 行)。
 *
 * <p>{@link EmployeeCsvRow} が<b>文字列のまま</b>持っていた値を、
 * 入力チェックを通ったあとで型のある値 (日付は {@link LocalDate}) に直したものです。</p>
 */
public final class ImportedEmployee {

    private static final DateTimeFormatter UPDATED_AT_FORMAT =
            DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss");

    private final String code;
    private final String name;
    private final String kana;
    private final String email;
    private final String departmentCode;
    private final String employmentType;
    private final LocalDate hireDate;
    private final LocalDateTime updatedAt;

    public ImportedEmployee(String code, String name, String kana, String email, String departmentCode,
                            String employmentType, LocalDate hireDate, LocalDateTime updatedAt) {
        this.code = code;
        this.name = name;
        this.kana = kana;
        this.email = email;
        this.departmentCode = departmentCode;
        this.employmentType = employmentType;
        this.hireDate = hireDate;
        this.updatedAt = updatedAt;
    }

    /** 社員コード。 */
    public String getCode() {
        return code;
    }

    /** 氏名。 */
    public String getName() {
        return name;
    }

    /** フリガナ。 */
    public String getKana() {
        return kana;
    }

    /** メールアドレス。 */
    public String getEmail() {
        return email;
    }

    /** 部署コード。 */
    public String getDepartmentCode() {
        return departmentCode;
    }

    /** 部署名 (部署マスタから引く)。 */
    public String getDepartmentName() {
        return EmployeeCsvRow.DEPARTMENTS.getOrDefault(departmentCode, "");
    }

    /** 雇用区分。 */
    public String getEmploymentType() {
        return employmentType;
    }

    /** 入社日。 */
    public LocalDate getHireDate() {
        return hireDate;
    }

    /** 最後に登録・更新した日時。 */
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    /** 最後に登録・更新した日時 (画面用)。 */
    public String getUpdatedAtText() {
        return updatedAt == null ? "" : updatedAt.format(UPDATED_AT_FORMAT);
    }
}
