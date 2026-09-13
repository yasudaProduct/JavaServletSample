package com.example.servletsample.web.tag;

import java.io.IOException;

import javax.servlet.ServletContext;
import javax.servlet.jsp.JspException;
import javax.servlet.jsp.JspWriter;
import javax.servlet.jsp.PageContext;
import javax.servlet.jsp.tagext.SimpleTagSupport;

import com.example.servletsample.common.SourceLoader;

/**
 * ソースコードを画面に表示するカスタムタグ。
 *
 * <pre>{@code
 * <%@ taglib prefix="site" uri="http://example.com/jsp/servlet-sample" %>
 * <site:source path="/WEB-INF/views/samples/basic/hello-world.jsp" language="xml" />
 * }</pre>
 *
 * <p>行番号の桁と本文を別々の要素にしているため、コピーボタンで行番号が混ざりません。</p>
 */
public class SourceTag extends SimpleTagSupport {

    /** Java ソースを WAR に取り込んでいる場所。 */
    private static final String JAVA_ROOT = "/WEB-INF/sources/java/";

    private String path;
    private String label;
    private String language = "plaintext";

    public void setPath(String path) {
        this.path = path;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    @Override
    public void doTag() throws JspException, IOException {
        PageContext pageContext = (PageContext) getJspContext();
        ServletContext servletContext = pageContext.getServletContext();
        JspWriter out = pageContext.getOut();

        String code = SourceLoader.read(servletContext, path);
        String displayName = (label == null || label.isEmpty()) ? fileNameOf(path) : label;

        if (code == null) {
            out.write("<div class=\"alert alert-warning\">ソースファイルを読み込めませんでした: ");
            out.write(escape(String.valueOf(path)));
            out.write("</div>");
            return;
        }

        out.write("<div class=\"code-block\">");
        out.write("<div class=\"code-block__head\">");
        out.write("<span class=\"code-block__name\">" + escape(displayName) + "</span>");
        out.write("<span class=\"code-block__path\">" + escape(repositoryPathOf(path)) + "</span>");
        out.write("<button type=\"button\" class=\"code-block__copy\" data-code-copy"
                + " aria-label=\"コードをコピー\">コピー</button>");
        out.write("</div>");

        out.write("<div class=\"code-block__body\">");
        out.write("<pre class=\"code-block__gutter\" aria-hidden=\"true\">");
        out.write(lineNumbers(code));
        out.write("</pre>");
        out.write("<pre class=\"code-block__code\"><code class=\"language-" + escape(language) + "\">");
        out.write(escape(code));
        out.write("</code></pre>");
        out.write("</div>");
        out.write("</div>");
    }

    /** 行番号を "1\n2\n3..." の形で組み立てる。 */
    private static String lineNumbers(String code) {
        int lines = code.isEmpty() ? 1 : code.split("\n", -1).length;
        StringBuilder builder = new StringBuilder();
        for (int i = 1; i <= lines; i++) {
            if (i > 1) {
                builder.append('\n');
            }
            builder.append(i);
        }
        return builder.toString();
    }

    /**
     * 実行時のパスを、リポジトリ上のパス表記に直す。
     * <p>画面を見た人が VS Code でファイルを探しやすいようにするための表示用。</p>
     */
    private static String repositoryPathOf(String path) {
        if (path == null) {
            return "";
        }
        if (path.startsWith(JAVA_ROOT)) {
            return "src/main/java/" + path.substring(JAVA_ROOT.length());
        }
        return "src/main/webapp" + path;
    }

    private static String fileNameOf(String path) {
        if (path == null) {
            return "";
        }
        int index = path.lastIndexOf('/');
        return index < 0 ? path : path.substring(index + 1);
    }

    /** HTML として安全に出力できるようエスケープする。 */
    private static String escape(String value) {
        StringBuilder builder = new StringBuilder(value.length() + 32);
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '&':
                    builder.append("&amp;");
                    break;
                case '<':
                    builder.append("&lt;");
                    break;
                case '>':
                    builder.append("&gt;");
                    break;
                case '"':
                    builder.append("&quot;");
                    break;
                case '\'':
                    builder.append("&#39;");
                    break;
                default:
                    builder.append(c);
            }
        }
        return builder.toString();
    }
}
