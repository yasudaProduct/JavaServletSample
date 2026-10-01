package com.example.servletsample.samples.file;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * PDF を返すときに付けるヘッダ。
 *
 * <p>ファイルから読んでも DB から読んでも、ブラウザへ返すときのヘッダは同じなので
 * ここにまとめています ({@link PdfFromFileServlet} / {@link PdfFromDbServlet} が使います)。</p>
 *
 * <h2>「画面に表示」と「ダウンロード」の違いは 1 語だけ</h2>
 * <pre>{@code
 * Content-Disposition: inline;     filename="..."   → ブラウザの中で開く
 * Content-Disposition: attachment; filename="..."   → 保存させる
 * }</pre>
 *
 * <p>{@code inline} でも {@code filename} を書いておくと、
 * PDF ビューアの保存ボタンを押したときのファイル名として使われます。
 * 書かないと URL の末尾 (このサンプルなら {@code db} や {@code file}) が名前になります。</p>
 */
public final class PdfResponse {

    /** PDF の MIME タイプ。 */
    static final String CONTENT_TYPE = "application/pdf";

    private PdfResponse() {
    }

    /** {@code ?download=1} が付いていたら、表示ではなくダウンロードさせる。 */
    static boolean wantsDownload(HttpServletRequest request) {
        return "1".equals(request.getParameter("download"));
    }

    /**
     * PDF を返すためのヘッダを設定する。本文を書く前に呼ぶこと。
     *
     * @param fileName 保存するときのファイル名 (日本語可)
     * @param size     バイト数
     * @param download true ならダウンロード、false なら画面に表示
     */
    static void setHeaders(HttpServletResponse response, String fileName, long size, boolean download) {
        // ① 中身は PDF です。
        //    これが違うと (text/html や application/octet-stream)、ブラウザは PDF ビューアを使わない
        response.setContentType(CONTENT_TYPE);

        // ② バイト数 (ブラウザが読み込みの進み具合を出せる)
        response.setContentLengthLong(size);

        // ③ その場で表示するか (inline)、保存させるか (attachment)
        response.setHeader("Content-Disposition", contentDisposition(download, fileName));

        // ④ ブラウザに中身を見て種類を推測させない (Content-Type のとおりに扱わせる)
        response.setHeader("X-Content-Type-Options", "nosniff");

        // ⑤ 同じサイトの画面からなら iframe に埋め込んでよい (よそのサイトからは埋め込ませない)
        response.setHeader("X-Frame-Options", "SAMEORIGIN");
    }

    /**
     * {@code Content-Disposition} ヘッダの値を組み立てる。
     *
     * <p>例: {@code inline; filename="___.pdf"; filename*=UTF-8''%E8%A6%8B%E7%A9%8D%E6%9B%B8.pdf}</p>
     *
     * <p>ヘッダには ASCII しか書けないため、古いブラウザ向けの {@code filename="..."} と、
     * RFC 6266 の {@code filename*=UTF-8''...} (パーセントエンコード) を並べます。</p>
     */
    static String contentDisposition(boolean download, String fileName) {
        return (download ? "attachment" : "inline")
                + "; filename=\"" + asciiFallback(fileName) + "\""
                + "; filename*=UTF-8''" + encode(fileName);
    }

    /** ASCII 以外と、ヘッダを壊す記号を {@code _} に置き換えた、古いブラウザ向けのファイル名。 */
    private static String asciiFallback(String fileName) {
        StringBuilder builder = new StringBuilder(fileName.length());
        for (int i = 0; i < fileName.length(); i++) {
            char c = fileName.charAt(i);
            builder.append(c < 0x20 || c > 0x7e || c == '"' || c == '\\' ? '_' : c);
        }
        return builder.toString();
    }

    /** RFC 6266 の {@code filename*} 用にパーセントエンコードする。 */
    private static String encode(String fileName) {
        // URLEncoder はフォームの送信用なので、ヘッダ用に 2 か所だけ直す
        // (半角スペースは + ではなく %20、* はそのままでは書けない文字なので %2A)
        return URLEncoder.encode(fileName, StandardCharsets.UTF_8)
                .replace("+", "%20")
                .replace("*", "%2A");
    }
}
