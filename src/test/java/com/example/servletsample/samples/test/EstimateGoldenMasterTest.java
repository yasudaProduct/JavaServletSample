package com.example.servletsample.samples.test;

import static org.junit.jupiter.api.Assertions.fail;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import javax.servlet.http.HttpServlet;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * 【サンプル】仕様化テストを「まとめて記録する」形で書いたもの (ゴールデンマスター)。
 *
 * <p>入力の組み合わせを総当たりで流し、結果を 1 行ずつテキストにして、
 * リポジトリに置いた<b>記録ファイル</b> ({@code EstimateGoldenMasterTest.approved.txt}) と比べます。
 * 1 件ずつ {@code assertEquals} を書く代わりに、今の動きを丸ごと写し取っておくやり方です。</p>
 *
 * <h2>直す前と直した後の両方に当てる</h2>
 * <p>同じ記録ファイルを、直す前の {@link LegacyEstimateServlet} と
 * 直した後の {@link EstimateServlet} の<b>両方</b>で確かめています。
 * 両方が通れば、「計算を切り出したが、動きは 1 つも変わっていない」と言えます。</p>
 *
 * <h2>使い方</h2>
 * <ul>
 *   <li><b>記録ファイルが無いとき</b> … 今の結果を書き出して、わざと失敗させます。
 *       中身を目で確かめてからコミットしてください。</li>
 *   <li><b>結果が記録と違ったとき</b> … 違う行を表示して失敗します。
 *       今回の結果は {@code EstimateGoldenMasterTest.received.txt} に書き出すので、
 *       記録ファイルと差分ツールで見比べられます (このファイルはコミットしません)。</li>
 *   <li><b>わざと動きを変えたとき</b> … {@code mvn test -Dtest=EstimateGoldenMasterTest -Dapprove=true}
 *       で記録ファイルを書き直します。差分を確かめてからコミットします。</li>
 * </ul>
 *
 * <p>記録ファイルをテストクラスの隣に {@code *.approved.txt} という名前で置くのは、
 * Java 用のライブラリ ApprovalTests と同じ決まりです。このサンプルではライブラリを使わず、
 * 同じことを JUnit だけで書いています。</p>
 */
class EstimateGoldenMasterTest {

    private static final Path DIRECTORY =
            Path.of("src", "test", "java", "com", "example", "servletsample", "samples", "test");

    /** 承認済みの記録 (リポジトリにコミットする)。 */
    private static final Path APPROVED = DIRECTORY.resolve("EstimateGoldenMasterTest.approved.txt");

    /** 記録と違ったときの今回の結果 (差分を見るためのもの。コミットしない)。 */
    private static final Path RECEIVED = DIRECTORY.resolve("EstimateGoldenMasterTest.received.txt");

    /** 違う行を何行まで表示するか。 */
    private static final int MAX_DIFF_LINES = 20;

    static Stream<Arguments> implementations() {
        return Stream.of(
                Arguments.of("直す前 LegacyEstimateServlet", new LegacyEstimateServlet()),
                Arguments.of("直した後 EstimateServlet", new EstimateServlet()));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("implementations")
    @DisplayName("記録ファイルと同じ結果になる")
    void matchesApprovedRecord(String label, HttpServlet servlet) throws IOException {
        String received = record(servlet);

        if (Boolean.getBoolean("approve") || !Files.exists(APPROVED)) {
            Files.writeString(APPROVED, received, StandardCharsets.UTF_8);
            fail("記録ファイルを書き出しました: " + APPROVED
                    + "\n中身を確かめてから、-Dapprove を付けずに実行し直してください。");
        }

        List<String> differences = differences(
                Files.readAllLines(APPROVED, StandardCharsets.UTF_8), received.lines().toList());
        if (!differences.isEmpty()) {
            Files.writeString(RECEIVED, received, StandardCharsets.UTF_8);
            fail(label + " の動きが記録と違います (今回の結果: " + RECEIVED + ")\n"
                    + String.join("\n", differences));
        }
        Files.deleteIfExists(RECEIVED);
    }

    // ======================================================================
    // 記録の作り方
    // ======================================================================

    /** 入力の組み合わせを全部流して、1 行 1 件のテキストにする。 */
    private static String record(HttpServlet servlet) {
        StringBuilder text = new StringBuilder();
        text.append("# 見積もりの仕様化テストの記録 (EstimateGoldenMasterTest)\n");
        text.append("# 今の動きをそのまま写したもの。正しいかどうかは問わない。\n");
        text.append("# 見積番号の日時は毎回変わるので {日時} に置き換えている。\n");

        text.append("\n# --- 地域 x 重さの境界 x 金額の境界 x 会員 ---\n");
        for (String pref : new String[]{"東京", "北海道", "沖縄", ""}) {
            for (String weight : new String[]{"2000", "2001", "4999", "5000", "5001"}) {
                for (String price : new String[]{"4999", "5000", "10000", "10001"}) {
                    for (String member : new String[]{null, "1"}) {
                        text.append(line(servlet, pref, price, "1", weight, member)).append('\n');
                    }
                }
            }
        }

        text.append("\n# --- 数量 (重さは 1 個の重さ x 数量) ---\n");
        for (String pref : new String[]{"東京", "北海道"}) {
            for (String qty : new String[]{"2", "3"}) {
                text.append(line(servlet, pref, "1000", qty, "2000", null)).append('\n');
            }
        }

        text.append("\n# --- 変な入力 ---\n");
        text.append(line(servlet, "東京", "3000", "0", "2000", null)).append('\n');
        text.append(line(servlet, "東京", "3000", "-1", "2000", null)).append('\n');
        text.append(line(servlet, "東京", "３０００", "１", "２０００", null)).append('\n');
        text.append(line(servlet, "東京", "3,000", "1", "2000", null)).append('\n');
        text.append(line(servlet, "東京", "", "1", "2000", null)).append('\n');
        text.append(line(servlet, "東京", null, "1", "2000", null)).append('\n');
        text.append(line(servlet, null, "3000", "1", "2000", null)).append('\n');
        text.append(line(servlet, "大阪", "5000", "1", "2000", "0")).append('\n');
        text.append(line(servlet, "大阪", "5000", "1", "2000", "true")).append('\n');
        return text.toString();
    }

    /**
     * 1 件分を 1 行にする。例外も結果の 1 つとして書く。
     *
     * <p>例外は<b>クラス名だけ</b>を書きます。メッセージは Java のバージョンや
     * 書き方の細かい違いで変わるため、記録すると、動きは同じなのに落ちるテストになります。</p>
     */
    private static String line(HttpServlet servlet, String pref, String price, String qty,
                               String weight, String member) {
        String input = "pref=" + show(pref) + " price=" + show(price) + " qty=" + show(qty)
                + " weight=" + show(weight) + " member=" + show(member);
        try {
            Map<String, Object> result = EstimateRequests.post(servlet, pref, price, qty, weight, member);
            StringBuilder output = new StringBuilder();
            for (String name : EstimateRequests.RESULT_NAMES) {
                output.append(' ').append(name).append('=').append(result.get(name));
            }
            return input + " ->" + maskVolatile(output.toString());
        } catch (Exception e) {
            return input + " -> 例外 " + e.getClass().getSimpleName();
        }
    }

    /** 毎回変わる値を、決まった文字に置き換える。 */
    private static String maskVolatile(String text) {
        return text.replaceAll("EST-\\d{14}", "EST-{日時}");
    }

    /** 送られてこなかったパラメータと、空文字を見分けられるように書く。 */
    private static String show(String value) {
        if (value == null) {
            return "(なし)";
        }
        return value.isEmpty() ? "(空)" : value;
    }

    /** 記録と今回の結果で違う行を、読みやすい形に並べる。 */
    private static List<String> differences(List<String> approved, List<String> received) {
        List<String> lines = new ArrayList<>();
        int size = Math.max(approved.size(), received.size());
        for (int i = 0; i < size && lines.size() < MAX_DIFF_LINES * 3; i++) {
            String expected = i < approved.size() ? approved.get(i) : "(行なし)";
            String actual = i < received.size() ? received.get(i) : "(行なし)";
            if (!expected.equals(actual)) {
                lines.add((i + 1) + " 行目");
                lines.add("  記録: " + expected);
                lines.add("  今回: " + actual);
            }
        }
        return lines;
    }
}
