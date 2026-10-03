package com.example.servletsample.samples.file;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * 社員 CSV の取り込み。チェックを順に行い、通ったものだけを登録する。
 *
 * <h2>チェックは外側から順に</h2>
 * <ol>
 *   <li><b>ファイル</b> … 空でないか / 拡張子 / 大きさ</li>
 *   <li><b>文字コード</b> … 選ばれた文字コードで読めるか (化けたまま進まない)</li>
 *   <li><b>CSV の形</b> … {@code "} の閉じ忘れが無いか</li>
 *   <li><b>見出し</b> … 1 行目がテンプレートと同じか (別のファイルではないか)</li>
 *   <li><b>件数</b> … データ行が 1 件以上・上限以下か</li>
 *   <li><b>行ごと</b> … 列の数 → 各列の値 ({@link EmployeeCsvRow}) → ファイル内の重複</li>
 * </ol>
 * <p>1 〜 5 で引っかかったら、その時点で止めます (ファイルごと差し戻す)。
 * 6 は<b>止めずに最後の行まで見て、エラーをまとめて返します</b>。
 * 1 件直すたびに取り込み直して次のエラーが出る、を繰り返させないためです。</p>
 *
 * <h2>1 件でもエラーがあれば、1 件も登録しない</h2>
 * <p>「正しい行だけ登録して、エラーの行だけ返す」やり方もありますが、
 * それだと直した CSV を取り込み直すとき、<b>どの行が登録済みか</b>を利用者が考えることになります。
 * 全件チェックを通ったときだけ、全件を 1 つのトランザクションで登録します。</p>
 *
 * <h2>ログ (Log4j 2)</h2>
 * <table border="1">
 *   <caption>何をどのレベルで出すか</caption>
 *   <tr><th>レベル</th><th>出すもの</th></tr>
 *   <tr><td>INFO</td><td>取り込みの開始 (ファイル名・大きさ) と完了 (件数・かかった時間)</td></tr>
 *   <tr><td>WARN</td><td>差し戻した理由。入力エラーは件数だけ</td></tr>
 *   <tr><td>DEBUG</td><td>入力エラーの位置 (行・列・種類)。<b>入力値は出さない</b></td></tr>
 *   <tr><td>ERROR</td><td>システムの異常。ここでは出さず、受け止めた {@link CsvImportServlet} が出す</td></tr>
 * </table>
 * <p>各行には {@link #IMPORT_ID_KEY} (取り込み ID) が付きます。
 * {@link CsvImportServlet} が {@code ThreadContext} に入れたもので、
 * ログの書式 ({@code log4j2.xml}) の {@code %X{importId}} がそれを書き出しています。</p>
 */
public class CsvImporter {

    /**
     * ロガー。クラスごとに 1 つ、{@code static final} で持つのが定番です。
     * ロガーの名前 (= クラス名) で、{@code log4j2.xml} からレベルを変えられます。
     */
    private static final Logger LOG = LogManager.getLogger(CsvImporter.class);

    /** ThreadContext (MDC) に取り込み ID を入れるときのキー。log4j2.xml の %X{importId} と合わせる。 */
    public static final String IMPORT_ID_KEY = "importId";

    /** Shift_JIS (Windows で作られた CSV はこれ。「①」「㈱」も読める Windows-31J を使う)。 */
    public static final Charset WINDOWS_31J = Charset.forName("Windows-31J");

    /** 受け付けるファイルの大きさの上限 (256 KB)。 */
    public static final int MAX_FILE_SIZE = 256 * 1024;

    /** 1 回に取り込めるデータ行の上限。 */
    public static final int MAX_ROWS = 100;

    /** 登録できる社員の上限 (公開デモなので、際限なく増えないようにする)。 */
    public static final int MAX_EMPLOYEES = 200;

    /** 画面に出すエラーの上限 (これを超えた分は件数だけ伝える)。 */
    static final int MAX_ERRORS_SHOWN = 100;

    /** DEBUG ログに 1 行ずつ出すエラー行の上限 (1 万行が全部エラーでも、ログが埋まらないように)。 */
    static final int MAX_ERROR_ROWS_LOGGED = 20;

    private final ImportedEmployeeDao dao;

    public CsvImporter() {
        this(new ImportedEmployeeDao());
    }

    CsvImporter(ImportedEmployeeDao dao) {
        this.dao = dao;
    }

    /**
     * 取り込み ID (問い合わせ番号) を作る。
     *
     * <p>ログの各行と画面に同じ値を出します。利用者から「IMP-3F9A0C21 で失敗した」と
     * 連絡をもらえば、ログを 1 回 grep するだけで、その取り込みの行がすべて揃います。</p>
     */
    public static String newImportId() {
        return String.format("IMP-%08X", ThreadLocalRandom.current().nextInt());
    }

    /**
     * CSV を取り込む。
     *
     * <p>入力の誤りやファイルの問題は<b>例外にせず</b>、結果として返します。
     * システムの異常 (DB に書けないなど) だけが例外として出ていきます。</p>
     *
     * @param importId     取り込み ID
     * @param fileName     送られてきたファイル名 (ディレクトリ部分と制御文字は落としたもの)
     * @param content      ファイルの中身
     * @param charset      利用者が選んだ文字コード
     * @param breakHalfway デモ用。true にすると、登録の途中で障害を起こす
     * @throws IllegalStateException 登録に失敗したとき (ロールバック済み)
     */
    public CsvImportResult importCsv(String importId, String fileName, byte[] content, Charset charset,
                                     boolean breakHalfway) {
        long started = System.currentTimeMillis();

        // 引数は {} の位置に順に入る。文字列を + でつなぐより読みやすく、
        // DEBUG のように出さないレベルでは、組み立てる手間そのものを省いてくれる
        LOG.info("取り込みを始めます file={} size={}B encoding={}", fileName, content.length, charset.name());

        // ---------------------------------------------------------------- ① ファイル
        if (fileName.isEmpty() || content.length == 0) {
            return reject(importId, fileName, "ファイルが空",
                    "ファイルが選ばれていないか、中身が空です。");
        }
        if (!fileName.toLowerCase(Locale.ROOT).endsWith(".csv")) {
            return reject(importId, fileName, "拡張子が .csv でない",
                    "CSV ファイル (拡張子が .csv のもの) を選んでください。");
        }
        if (content.length > MAX_FILE_SIZE) {
            return reject(importId, fileName, "大きさが上限を超えた",
                    "ファイルが大きすぎます。" + (MAX_FILE_SIZE / 1024) + " KB 以下にしてください。");
        }

        // ---------------------------------------------------------------- ② 文字コード
        Charset actual = hasUtf8Bom(content) ? StandardCharsets.UTF_8 : charset;
        if (!actual.equals(charset)) {
            LOG.debug("先頭に BOM があるため、選択によらず UTF-8 として読みます");
        }
        String text;
        try {
            text = decode(content, actual);
        } catch (CharacterCodingException e) {
            // 想定内の失敗 (利用者が選び間違えた) なので、スタックトレースは要らない
            return reject(importId, fileName, actual.name() + " として読めない",
                    "選んだ文字コード (" + label(actual) + ") として読めない文字があります。"
                    + "Excel の「CSV (コンマ区切り)」で保存したファイルなら Shift_JIS を、"
                    + "「CSV UTF-8」で保存したファイルなら UTF-8 を選んでください。");
        }

        // ---------------------------------------------------------------- ③ CSV の形
        List<CsvReader.Row> rows;
        try {
            rows = CsvReader.read(text);
        } catch (CsvReader.CsvFormatException e) {
            return reject(importId, fileName, "CSV として読めない (" + e.getLineNumber() + " 行目)",
                    e.getLineNumber() + " 行目: " + e.getMessage());
        }

        // ---------------------------------------------------------------- ④ 見出し
        List<String> expected = EmployeeCsvRow.Column.labels();
        if (rows.isEmpty() || !expected.equals(stripAll(rows.get(0).getValues()))) {
            return reject(importId, fileName, "見出しが違う",
                    "1 行目 (見出し) がテンプレートと違います。「" + String.join(",", expected)
                    + "」にしてください。文字化けしているときは、文字コードの選択を確かめてください。");
        }

        // ---------------------------------------------------------------- ⑤ 件数
        List<CsvReader.Row> dataRows = new ArrayList<>();
        for (CsvReader.Row row : rows.subList(1, rows.size())) {
            if (row.isBlank()) {
                LOG.debug("{} 行目は空なので読み飛ばします", row.getLineNumber());
            } else {
                dataRows.add(row);
            }
        }
        if (dataRows.isEmpty()) {
            return reject(importId, fileName, "データ行が無い",
                    "取り込む行がありません。2 行目からデータを書いてください。");
        }
        if (dataRows.size() > MAX_ROWS) {
            return reject(importId, fileName, "行数が上限を超えた (" + dataRows.size() + " 行)",
                    "一度に取り込めるのは " + MAX_ROWS + " 行までです。(いまは " + dataRows.size()
                    + " 行) ファイルを分けてください。");
        }

        // ---------------------------------------------------------------- ⑥ 行ごと
        LocalDate today = LocalDate.now();
        LocalDateTime now = LocalDateTime.now();
        List<CsvImportError> errors = new ArrayList<>();
        List<ImportedEmployee> employees = new ArrayList<>();
        Map<String, Integer> firstLineOfCode = new HashMap<>();
        int errorRows = 0;

        for (CsvReader.Row row : dataRows) {
            List<CsvImportError> rowErrors = validateRow(row, today, firstLineOfCode);
            if (rowErrors.isEmpty()) {
                employees.add(EmployeeCsvRow.of(row.getLineNumber(), row.getValues()).toEmployee(now));
                continue;
            }
            errors.addAll(rowErrors);
            errorRows++;
            if (errorRows <= MAX_ERROR_ROWS_LOGGED) {
                // どこが・どの種類で引っかかったかだけを出す。入力値 (個人情報) は出さない
                LOG.debug("{} 行目に入力エラー {}", row.getLineNumber(),
                        rowErrors.stream().map(CsvImportError::toLogText).collect(Collectors.toList()));
            }
        }

        // ---------------------------------------------------------------- ⑦ 1 件でもあれば登録しない
        if (!errors.isEmpty()) {
            // 利用者の入力の誤りは「人を呼ぶ」ものではないので ERROR にはしない。
            // 取り込みが完了しなかった記録として WARN で 1 行、件数だけを残す
            LOG.warn("入力エラーがあるため取り込みませんでした rows={} errorRows={} errors={}",
                    dataRows.size(), errorRows, errors.size());
            return CsvImportResult.invalid(importId, fileName, dataRows.size(),
                    errors.subList(0, Math.min(errors.size(), MAX_ERRORS_SHOWN)), errors.size());
        }

        // ---------------------------------------------------------------- ⑧ 登録
        Set<String> registered = dao.findAllCodes();
        int updating = (int) employees.stream().filter(e -> registered.contains(e.getCode())).count();
        int inserting = employees.size() - updating;
        if (registered.size() + inserting > MAX_EMPLOYEES) {
            return reject(importId, fileName, "登録件数の上限を超える",
                    "登録できる社員は " + MAX_EMPLOYEES + " 人までです。"
                    + "下の「初期状態に戻す」で減らしてから取り込んでください。");
        }

        // 失敗したら例外が出ていく (ロールバック済み)。受け止めるのは Servlet
        dao.saveAll(employees, breakHalfway);

        LOG.info("取り込みが完了しました rows={} inserted={} updated={} elapsed={}ms",
                employees.size(), inserting, updating, System.currentTimeMillis() - started);
        return CsvImportResult.success(importId, fileName, employees.size(), inserting, updating);
    }

    /**
     * 1 行を確かめる : 列の数 → 各列の値 → ファイルの中での重複。
     *
     * @param firstLineOfCode これまでに出てきた社員コードと、その行番号 (重複の検出に使う)
     */
    static List<CsvImportError> validateRow(CsvReader.Row row, LocalDate today,
                                            Map<String, Integer> firstLineOfCode) {
        int columns = EmployeeCsvRow.Column.values().length;
        if (row.getValues().size() != columns) {
            // 値の中のカンマを " で囲み忘れると、ここに来る。
            // どの値がどの列か決められないので、この行の値は確かめない
            return List.of(new CsvImportError(row.getLineNumber(), "", "列数", "",
                    "値が " + row.getValues().size() + " 個あります。(" + columns + " 個のはずです) "
                    + "値の中にカンマがあるときは、値を \" で囲んでください。"));
        }

        EmployeeCsvRow employee = EmployeeCsvRow.of(row.getLineNumber(), row.getValues());
        List<CsvImportError> errors = new ArrayList<>(employee.validate(today));

        // 社員コードの形が正しいときだけ、重複を見る (空のコードどうしを「重複」と言っても仕方がない)
        String codeLabel = EmployeeCsvRow.Column.CODE.getLabel();
        boolean codeIsValid = errors.stream().noneMatch(e -> e.getColumn().equals(codeLabel));
        if (codeIsValid) {
            Integer firstLine = firstLineOfCode.putIfAbsent(employee.getCode(), row.getLineNumber());
            if (firstLine != null) {
                errors.add(new CsvImportError(row.getLineNumber(), codeLabel, "重複", employee.getCode(),
                        "社員コード " + employee.getCode() + " は " + firstLine + " 行目と重複しています。"));
            }
        }
        return errors;
    }

    /**
     * 差し戻す。理由をログに残し、利用者向けのメッセージを結果にする。
     *
     * @param reason  ログに出す理由 (短く。利用者が入力した値は含めない)
     * @param message 画面に出すメッセージ (どうすればよいかまで書く)
     */
    private CsvImportResult reject(String importId, String fileName, String reason, String message) {
        LOG.warn("ファイルを受け付けられないため取り込みませんでした reason={}", reason);
        return CsvImportResult.rejected(importId, fileName, message);
    }

    /**
     * 選ばれた文字コードで文字列にする。<b>読めないバイトがあれば例外</b>にする。
     *
     * <p>{@code new String(bytes, charset)} は、読めないバイトを黙って {@code ?} や
     * {@code U+FFFD} に置き換えます。文字化けしたまま登録まで進んでしまうので、
     * {@link CodingErrorAction#REPORT} を指定したデコーダで「読めなかった」ことに気付けるようにします。</p>
     */
    static String decode(byte[] content, Charset charset) throws CharacterCodingException {
        String text = charset.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(ByteBuffer.wrap(content))
                .toString();
        // BOM は文字としては U+FEFF。残すと 1 列目の見出しが「﻿社員コード」になり、見出しが合わない
        return text.startsWith("﻿") ? text.substring(1) : text;
    }

    /** 先頭が UTF-8 の BOM (EF BB BF) か。 */
    static boolean hasUtf8Bom(byte[] content) {
        return content.length >= 3
                && (content[0] & 0xFF) == 0xEF
                && (content[1] & 0xFF) == 0xBB
                && (content[2] & 0xFF) == 0xBF;
    }

    private static List<String> stripAll(List<String> values) {
        return values.stream().map(String::strip).collect(Collectors.toList());
    }

    private static String label(Charset charset) {
        return charset.equals(WINDOWS_31J) ? "Shift_JIS" : charset.name();
    }
}
