package com.example.servletsample.shared;

/**
 * この共通ライブラリ自身についての情報。
 *
 * <p>「共通処理を JAR に切り出す」サンプルで、<b>このクラスがどこから読み込まれたか</b>を
 * 画面に出すために使います。</p>
 *
 * <h2>このクラスが共通側にあってよい理由</h2>
 * <p>状態を持たず、どのアプリから呼んでも同じ答えを返すからです。
 * 逆に言えば、状態を持つものは JAR に入れても共通化できません
 * (サーバーが 2 台あれば JVM も 2 つあり、{@code static} はそれぞれ別に存在します)。
 * その実例は {@link SequenceCounter} にあります。</p>
 */
public final class SharedLibrary {

    /**
     * この共通ライブラリの版。
     *
     * <p>JAR のファイル名 ({@code servlet-sample-shared-1.0.0.jar}) と合わせています。
     * <b>版を固定して配るのが、複数サーバー構成でいちばん大事なところ</b>です。
     * どのサーバーのどのアプリが、どの版の共通処理で動いているかを
     * 後から追えるようにするためです。</p>
     */
    public static final String VERSION = "1.0.0";

    private SharedLibrary() {
    }

    /**
     * そのクラスが「どこから読み込まれたか」を調べる。
     *
     * @param type 調べたいクラス
     * @return 読み込み元の情報
     */
    public static ClassOrigin originOf(Class<?> type) {
        return ClassOrigin.of(type);
    }
}
