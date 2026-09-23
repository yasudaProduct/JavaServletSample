package com.example.servletsample.shared;

/**
 * 「コードを名前に引き当てる」という<b>形だけ</b>を決めたインタフェース。
 *
 * <h2>なぜインタフェースが必要か (JAR だけでは足りない理由)</h2>
 * <p>JAR は<b>配る単位</b>を分ける道具です。それだけでは
 * 「共通側が業務ルールを知ってしまう」問題は解けません。</p>
 *
 * <p>たとえば共通 JAR に「社員コードは 5 桁」と書いてしまうと、
 * 別のアプリで桁数が違ったときに直せなくなります。
 * そこで妥協して {@code if (管理アプリなら) ... else ...} を共通側に書き始めると、
 * <b>そこが共通化の失敗点</b>です。共通 JAR が全アプリの事情を抱え込み、
 * 片方の都合で触れないコードになります。</p>
 *
 * <p>インタフェースは<b>依存の向きを変える</b>道具です。
 * 共通側は「コードを渡すと名前が返る」という形だけを持ち、
 * 何のコードかは各アプリが決めます。こうすると</p>
 * <ul>
 *   <li>共通 → アプリ の依存が生まれない (アプリが増えても共通側は変わらない)</li>
 *   <li>アプリごとに違うルールを、分岐フラグ無しで持てる</li>
 * </ul>
 *
 * <h2>使い分けのまとめ</h2>
 * <table border="1">
 *   <caption>JAR とインタフェースの役割</caption>
 *   <tr><th>道具</th><th>解決すること</th></tr>
 *   <tr><td>JAR</td><td>同じコードを複数のアプリに<b>配る</b></td></tr>
 *   <tr><td>インタフェース</td><td>共通側がアプリの事情を<b>知らないようにする</b></td></tr>
 * </table>
 * <p>どちらか一方ではなく、両方を使います。</p>
 *
 * <h2>実装の登録方法</h2>
 * <p>実装はアプリ側 ({@code src/main/java/.../samples/shared/}) に置き、
 * {@link java.util.ServiceLoader} で見つけます。登録は
 * {@code src/main/resources/META-INF/services/} に
 * このインタフェースの完全修飾名のファイルを置き、
 * 実装クラス名を 1 行ずつ書くだけです。詳しくは {@link ResolverRegistry}。</p>
 */
public interface CodeResolver {

    /** 画面に出すこの実装の名前。例: 「社員コード」 */
    String name();

    /** 何を引き当てるものかの 1 行説明。 */
    String description();

    /** このコードを扱えるか (形が合っているか)。 */
    boolean accepts(String code);

    /**
     * コードを名前に引き当てる。
     *
     * @param code 入力されたコード
     * @return 引き当てた名前。見つからなければ {@code null}
     */
    String resolve(String code);
}
