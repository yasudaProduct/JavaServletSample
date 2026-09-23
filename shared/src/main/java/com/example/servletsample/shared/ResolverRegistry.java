package com.example.servletsample.shared;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.ServiceLoader;

/**
 * {@link CodeResolver} の実装を集める窓口。
 *
 * <p>共通側は<b>実装クラスの名前を 1 つも知りません</b>。
 * {@link ServiceLoader} が、クラスパス上に登録されている実装を探してきます。
 * これで「共通 → アプリ」の依存が生まれずに済みます。</p>
 *
 * <h2>登録のしかた</h2>
 * <p>アプリ側に、インタフェースの完全修飾名と同じ名前のファイルを作り、
 * 実装クラス名を 1 行ずつ書きます。</p>
 *
 * <pre>
 * src/main/resources/
 *   META-INF/services/
 *     com.example.servletsample.shared.CodeResolver   ← ファイル名がインタフェース名
 *         com.example.servletsample.samples.shared.EmployeeCodeResolver
 *         com.example.servletsample.samples.shared.ProductCodeResolver
 * </pre>
 *
 * <p><b>Eclipse での注意</b>: このファイルは {@code src/main/resources} の下に置きます
 * ({@code src/main/java} に置くとコンパイル対象外として無視され、
 * {@code WEB-INF/classes} にコピーされません)。
 * このリポジトリでは {@code src/main/resources} がソース・フォルダとして
 * {@code WEB-INF/classes} に割り当て済みなので、置くだけで動きます。
 * ここを間違えると「実装が 0 件」になり、原因が分かりにくい詰まり方をします。</p>
 *
 * <h2>どのクラスローダから探すか</h2>
 * <p>{@code ServiceLoader.load(Class)} は<b>スレッドのコンテキストクラスローダ</b>から探します。
 * Tomcat のリクエスト処理スレッドではアプリのクラスローダが設定されているため、
 * {@code WEB-INF/classes} と {@code WEB-INF/lib} の登録が見つかります。
 * つまり<b>アプリごとに違う実装が入っていてよい</b>ということです。</p>
 */
public final class ResolverRegistry {

    private ResolverRegistry() {
    }

    /**
     * 登録されている実装をすべて集める。
     *
     * <p>{@link ServiceLoader} は呼ぶたびに読み直すので、結果を返す形にしています
     * (共通側で {@code static} に持つと、それ自体が
     * {@link SequenceCounter} と同じ「共通化できない状態」になります)。</p>
     *
     * @return 登録順の実装一覧。1 件も無ければ空
     */
    public static List<CodeResolver> all() {
        List<CodeResolver> resolvers = new ArrayList<>();
        for (CodeResolver resolver : ServiceLoader.load(CodeResolver.class)) {
            resolvers.add(resolver);
        }
        return Collections.unmodifiableList(resolvers);
    }

    /** 名前で 1 件探す。見つからなければ空。 */
    public static Optional<CodeResolver> byName(String name) {
        if (name == null) {
            return Optional.empty();
        }
        return all().stream()
                .filter(resolver -> name.equals(resolver.name()))
                .findFirst();
    }

    /**
     * そのコードを扱える実装を探す。
     *
     * <p>{@link CodeResolver#accepts(String)} が最初に true を返した実装を使います。
     * <b>どれが選ばれるかは登録順で決まる</b>ので、形が重なる実装を登録すると
     * 意図しない方が選ばれます。実務では明示的に選ばせるのが無難です。</p>
     */
    public static Optional<CodeResolver> forCode(String code) {
        String normalized = CodeFormatter.normalize(code);
        if (normalized.isEmpty()) {
            return Optional.empty();
        }
        return all().stream()
                .filter(resolver -> resolver.accepts(normalized))
                .findFirst();
    }
}
