package com.example.servletsample.samples.basic;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】レスポンスを直接書き出すデモ。画面の fetch から呼ばれます。
 *
 * <h2>受け付けるパラメータ</h2>
 * <table border="1">
 *   <caption>クエリパラメータ</caption>
 *   <tr><th>名前</th><th>値</th><th>意味</th></tr>
 *   <tr><td>{@code mode}</td><td>{@code writer} / {@code stream} / {@code both}</td>
 *       <td>何で書き出すか</td></tr>
 *   <tr><td>{@code size}</td><td>0 〜 30000</td>
 *       <td>本文の文字数。バッファ (既定 8KB) を超えるかどうかを切り替える</td></tr>
 *   <tr><td>{@code after}</td><td>{@code header} / {@code reset}</td>
 *       <td>本文を書いたあとに何を試みるか</td></tr>
 * </table>
 *
 * <h2>バッファと「送信済み」</h2>
 * <p>{@code getWriter()} に書いた内容は、すぐ送られるわけではありません。
 * いったん<b>バッファ</b>にたまり、いっぱいになるか、処理が終わったときに送られます。</p>
 *
 * <ul>
 *   <li><b>バッファにいる間</b> … まだ何も送っていないので、ヘッダの追加も、
 *       書いた内容の取り消し ({@code resetBuffer}) も、エラーページへの差し替えもできます</li>
 *   <li><b>送り始めたあと</b> ({@code isCommitted()} が {@code true}) …
 *       ステータス行もヘッダも相手に届いてしまっているので、もう変えられません。
 *       {@code resetBuffer} や {@code sendRedirect} は {@code IllegalStateException} になります</li>
 * </ul>
 */
@WebServlet(name = "responseOutputDemo", urlPatterns = {"/samples/basic/response-output/demo"})
public class ResponseOutputDemoServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** 本文に書ける文字数の上限。 */
    static final int MAX_SIZE = 30000;

    /** 本文の文字数を指定しなかったときの値。 */
    static final int DEFAULT_SIZE = 200;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        String mode = modeOf(request.getParameter("mode"));
        int size = bodySizeOf(request.getParameter("size"));
        String after = request.getParameter("after");

        // Content-Type は「書き始める前」に決めます。あとから変えても効きません
        response.setContentType("text/plain; charset=UTF-8");

        // 書く前の状態を、ヘッダで知らせておきます
        response.setHeader("X-Buffer-Size", String.valueOf(response.getBufferSize()));

        if ("stream".equals(mode)) {
            writeWithStream(response, size);
        } else if ("both".equals(mode)) {
            writeWithBoth(response, size);
        } else {
            writeWithWriter(response, size);
        }

        // ------------------------------------------------------------------
        // 書いたあとに何ができるか。ここが本題です
        // ------------------------------------------------------------------
        boolean committed = response.isCommitted();

        // 送信済みなら、ここから先のヘッダ指定はすべて黙って捨てられます。
        // 例外にはならないので、ヘッダが「付いてこない」ことでしか気付けません
        response.setHeader("X-Committed", String.valueOf(committed));

        if ("header".equals(after)) {
            response.setHeader("X-Added-After-Write", "added");

        } else if ("reset".equals(after)) {
            try {
                // 書いた本文を捨ててやり直す。送信済みなら例外
                response.resetBuffer();
                appendNote(response, mode, "resetBuffer() が成功しました。"
                        + "さっきまで書いていた本文は捨てられ、ここから下だけが残っています。");
            } catch (IllegalStateException e) {
                // 例外そのものは握りつぶさず、何が起きたかを本文に残します
                appendNote(response, mode, "resetBuffer() は失敗しました : " + e);
            }
        }

        // 本文は送信済みでも書き足せます。ヘッダと違って、こちらは最後まで届きます
        appendNote(response, mode, "本文を書き終えた時点の isCommitted() は "
                + committed + " でした。"
                + (committed
                        ? "送信済みなので、このあとに指定したヘッダ (X-Committed / X-Added-After-Write) は"
                                + " 1 つも届いていないはずです。"
                        : "まだ送っていないので、このあとのヘッダ指定も間に合います。"));
    }

    /** 文字として書く。文字コードの面倒は PrintWriter が見てくれます。 */
    private static void writeWithWriter(HttpServletResponse response, int size) throws IOException {
        PrintWriter out = response.getWriter();
        out.write("getWriter() で書いています（文字として書く）\n");
        out.write(filler(size));
    }

    /**
     * バイトとして書く。
     *
     * <p>文字コードの変換は自分で行います。画像や PDF、BOM 付き CSV のように
     * <b>バイト列を 1 バイトも違わずに送りたい</b>ときはこちらです。</p>
     */
    private static void writeWithStream(HttpServletResponse response, int size) throws IOException {
        String body = "getOutputStream() で書いています（バイトとして書く）\n" + filler(size);
        response.getOutputStream().write(body.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * 両方を使おうとする。
     *
     * <p>同じレスポンスに {@code getWriter()} と {@code getOutputStream()} の
     * 両方は使えません。あとから呼んだ方が {@code IllegalStateException} になります。</p>
     */
    private static void writeWithBoth(HttpServletResponse response, int size) throws IOException {
        PrintWriter out = response.getWriter();
        out.write("まず getWriter() を呼びました。\n");
        try {
            response.getOutputStream();
            out.write("getOutputStream() も呼べてしまいました（本来は例外になります）\n");
        } catch (IllegalStateException e) {
            out.write("続けて getOutputStream() を呼ぶと例外になります :\n  " + e + "\n");
        }
        out.write(filler(size));
    }

    /**
     * 本文に一言足す。送信済みでも、まだ書き足すことはできます。
     *
     * <p>書き足す先は、最初に選んだ方に合わせます。
     * 途中で {@code getWriter()} と {@code getOutputStream()} を混ぜると例外になるためです。</p>
     */
    private static void appendNote(HttpServletResponse response, String mode, String note)
            throws IOException {
        String text = "\n---\n" + note + "\n";
        if ("stream".equals(mode)) {
            response.getOutputStream().write(text.getBytes(StandardCharsets.UTF_8));
        } else {
            response.getWriter().write(text);
        }
    }

    /** 何で書き出すかを、決められた 3 つに絞る。 */
    static String modeOf(String mode) {
        if ("stream".equals(mode) || "both".equals(mode)) {
            return mode;
        }
        return "writer";
    }

    /** 本文の文字数を、決めた範囲に収める。 */
    static int bodySizeOf(String value) {
        return Validators.toInt(value)
                .stream()
                .map(size -> Math.max(0, Math.min(size, MAX_SIZE)))
                .findFirst()
                .orElse(DEFAULT_SIZE);
    }

    /**
     * 指定した文字数の本文を作る。
     *
     * <p>バッファに収まるかどうかを切り替えたいだけなので、中身は何でも構いません。
     * 何文字目かが分かるよう、80 文字ごとに区切りを入れています。</p>
     */
    static String filler(int size) {
        StringBuilder body = new StringBuilder(size);
        while (body.length() < size) {
            String marker = String.format("%06d:", body.length());
            body.append(marker);
            for (int i = marker.length(); i < 80 && body.length() < size; i++) {
                body.append('.');
            }
            if (body.length() < size) {
                body.append('\n');
            }
        }
        return body.length() > size ? body.substring(0, size) : body.toString();
    }
}
