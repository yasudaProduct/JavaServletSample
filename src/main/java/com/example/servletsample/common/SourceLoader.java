package com.example.servletsample.common;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.stream.Collectors;

import javax.servlet.ServletContext;

/**
 * 画面に表示するソースコードを読み込むユーティリティ。
 *
 * <p>WAR の中の {@code /WEB-INF/} 配下だけを読み込み対象にしています。
 * (開発時は docker-compose のマウントによりホスト側の最新ファイルが読まれます)</p>
 */
public final class SourceLoader {

    private SourceLoader() {
    }

    /**
     * ソースファイルを読み込む。
     *
     * @param context ServletContext
     * @param path    {@code /WEB-INF/} で始まるパス
     * @return ファイルの中身。見つからない場合は {@code null}
     * @throws IOException 読み込みに失敗した場合
     */
    public static String read(ServletContext context, String path) throws IOException {
        if (!isReadable(path)) {
            return null;
        }
        try (InputStream in = context.getResourceAsStream(path)) {
            if (in == null) {
                return null;
            }
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8))) {
                return reader.lines().collect(Collectors.joining("\n"));
            }
        }
    }

    /**
     * 読み込んでよいパスかどうか。
     * <p>ディレクトリを遡るパス ({@code ..}) や WEB-INF の外は拒否します。</p>
     */
    public static boolean isReadable(String path) {
        return path != null
                && path.startsWith("/WEB-INF/")
                && !path.contains("..");
    }
}
