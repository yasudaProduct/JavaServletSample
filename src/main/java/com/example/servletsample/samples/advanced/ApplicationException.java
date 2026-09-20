package com.example.servletsample.samples.advanced;

/**
 * 業務上の決めごとに反したことを表す例外 (業務例外)。
 *
 * <p>例外は大きく 2 つに分けて考えると整理しやすくなります。</p>
 *
 * <table border="1">
 *   <caption>例外の分け方</caption>
 *   <tr><th></th><th>業務例外</th><th>システム例外</th></tr>
 *   <tr><td>例</td>
 *       <td>在庫が足りない、締め切りを過ぎている、権限が無い</td>
 *       <td>DB に繋がらない、NullPointerException、ディスクが一杯</td></tr>
 *   <tr><td>原因</td><td>想定できる。業務の決めごとの範囲内</td><td>想定外。プログラムや環境の異常</td></tr>
 *   <tr><td>利用者への伝え方</td>
 *       <td>何が起きて次に何をすればよいかを具体的に伝える</td>
 *       <td>「エラーが発生しました」とだけ伝える (中身は見せない)</td></tr>
 *   <tr><td>ログ</td><td>WARN 程度。スタックトレースは不要なことが多い</td>
 *       <td>ERROR。スタックトレースを必ず残す</td></tr>
 * </table>
 *
 * <p>このクラスは前者を表します。利用者に見せてよいメッセージ ({@link #getMessage()}) と、
 * 問い合わせのときに突き合わせるためのエラーコード ({@link #getCode()}) を持たせています。</p>
 *
 * <h2>検査例外にしていない理由</h2>
 * <p>{@link RuntimeException} を継承しているので、{@code throws} の宣言も {@code catch} も強制されません。
 * 業務例外は「起きたら画面にメッセージを出して終わり」という扱いがほとんどで、
 * 途中の層で {@code catch} して詰め替える必要がないためです。
 * 途中の層に {@code throws ApplicationException} が並ぶと、
 * 本当に処理したい場所が埋もれてしまいます。</p>
 *
 * <h2>専用のエラーページへ割り当てる</h2>
 * <p>{@code web.xml} で例外の型ごとにエラーページを指定できます。
 * コンテナは<b>継承関係のうちもっとも近いもの</b>を選ぶので、
 * この例外だけ専用の画面に飛ばせます。</p>
 *
 * <pre>{@code
 * <error-page>
 *   <exception-type>com.example.servletsample.samples.advanced.ApplicationException</exception-type>
 *   <location>/WEB-INF/views/error/application-error.jsp</location>
 * </error-page>
 * <error-page>
 *   <exception-type>java.lang.Throwable</exception-type>
 *   <location>/WEB-INF/views/error/500.jsp</location>
 * </error-page>
 * }</pre>
 */
public class ApplicationException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /** 問い合わせのときに突き合わせるためのコード。例: {@code E-1001} */
    private final String code;

    /**
     * @param code    エラーコード (画面とログの両方に出す)
     * @param message 利用者にそのまま見せてよいメッセージ
     */
    public ApplicationException(String code, String message) {
        super(message);
        this.code = code;
    }

    /**
     * 原因となった例外つきで作る。
     *
     * <p><b>原因は必ず引き渡してください。</b>
     * {@code catch} したあと {@code new ApplicationException(...)} だけを投げると、
     * 元の例外のスタックトレースが消えて、後から原因を追えなくなります。</p>
     */
    public ApplicationException(String code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }

    /** エラーコード。 */
    public String getCode() {
        return code;
    }
}
