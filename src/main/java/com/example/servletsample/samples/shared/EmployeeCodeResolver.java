package com.example.servletsample.samples.shared;

import java.util.regex.Pattern;

import com.example.servletsample.samples.form.EmployeeMaster;
import com.example.servletsample.shared.CodeResolver;

/**
 * 【サンプル】社員コードを氏名に引き当てる実装。<b>アプリ側</b>に置いています。
 *
 * <p>「社員コードは E + 4 桁」という<b>業務の決めごと</b>がここにあるのが要点です。
 * これを共通ライブラリ側に書くと、桁数の違う別のアプリが出てきたときに
 * 共通側を触らなければならなくなり、やがて
 * {@code if (アプリA なら 4 桁 else 5 桁)} が生えます。</p>
 *
 * <p>共通ライブラリが持っているのは
 * {@link CodeResolver} という<b>形</b>と、
 * {@code CodeFormatter} の<b>表記を揃える処理</b>だけです。
 * どちらもどのアプリでも意味が変わりません。</p>
 *
 * <h2>登録</h2>
 * <p>{@code src/main/resources/META-INF/services/com.example.servletsample.shared.CodeResolver}
 * にこのクラス名を書いてあります。共通側はこのクラスの名前を知りません。</p>
 */
public class EmployeeCodeResolver implements CodeResolver {

    /** 社員コードの形。E + 4 桁。<b>この決めごとがアプリ側にあることが大事</b>。 */
    private static final Pattern FORM = Pattern.compile("^E[0-9]{4}$");

    /**
     * {@link java.util.ServiceLoader} は<b>引数の無いコンストラクタ</b>で作ります。
     * private にしたり引数を付けると、実行時に見つからなくなります。
     */
    public EmployeeCodeResolver() {
    }

    @Override
    public String name() {
        return "社員コード";
    }

    @Override
    public String description() {
        return "E + 4 桁。社員マスタから氏名を引き当てます。";
    }

    @Override
    public boolean accepts(String code) {
        return code != null && FORM.matcher(code).matches();
    }

    @Override
    public String resolve(String code) {
        if (!accepts(code)) {
            return null;
        }
        String name = EmployeeMaster.nameOf(code);
        return name.isEmpty() ? null : name;
    }
}
