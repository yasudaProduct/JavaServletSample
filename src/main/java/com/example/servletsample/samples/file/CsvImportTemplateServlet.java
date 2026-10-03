package com.example.servletsample.samples.file;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/**
 * 【サンプル】CSV 取り込み : 取り込み用の CSV をダウンロードさせる。
 *
 * <p>取り込み機能には、<b>テンプレート (見出しだけの CSV) のダウンロード</b>を付けておくのが親切です。
 * 利用者が見出しを手で打つと、全角・半角や並び順の違いで必ずどこかが合いません。</p>
 *
 * <p>このサンプルでは、試しやすいように中身の入った CSV も用意しています。</p>
 * <ul>
 *   <li>正常なデータ … そのまま取り込める</li>
 *   <li>エラーを含むデータ … 入力チェックとエラーの出方を確かめる</li>
 *   <li>Shift_JIS で保存したデータ … 文字コードの選択を確かめる</li>
 * </ul>
 *
 * <p>ファイルの返し方 (ヘッダ・BOM・日本語のファイル名) は
 * 「CSV ダウンロード」のサンプルと同じなので、部品 ({@link Csv} と
 * {@link CsvExportServlet#contentDisposition}) をそのまま使っています。</p>
 */
@WebServlet(name = "csvImportTemplate", urlPatterns = {"/samples/file/csv-import/download"})
public class CsvImportTemplateServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** ダウンロードできるファイル。 */
    public enum SampleFile {

        TEMPLATE("template", "テンプレート（見出しだけ）",
                "1 行目の見出しだけが入っています。2 行目から書き足して使います。",
                "社員取込_テンプレート.csv", "employees_template.csv", StandardCharsets.UTF_8),
        VALID("valid", "正常なデータ",
                "そのまま取り込めます。E00003 は登録済みなので上書き (部署の異動) になります。",
                "社員取込_正常.csv", "employees_valid.csv", StandardCharsets.UTF_8),
        INVALID("invalid", "エラーを含むデータ",
                "必須・文字種・桁数・形式・範囲・マスタ・選択肢・重複・列数のエラーを 1 行ずつ入れてあります。",
                "社員取込_エラーあり.csv", "employees_invalid.csv", StandardCharsets.UTF_8),
        SJIS("sjis", "正常なデータ（Shift_JIS）",
                "「正常なデータ」を Shift_JIS で保存したものです。文字コードを UTF-8 のまま取り込むと差し戻されます。",
                "社員取込_ShiftJIS.csv", "employees_sjis.csv", CsvImporter.WINDOWS_31J);

        private final String key;
        private final String label;
        private final String description;
        private final String fileName;
        private final String fallbackFileName;
        private final Charset charset;

        SampleFile(String key, String label, String description, String fileName,
                   String fallbackFileName, Charset charset) {
            this.key = key;
            this.label = label;
            this.description = description;
            this.fileName = fileName;
            this.fallbackFileName = fallbackFileName;
            this.charset = charset;
        }

        /** URL に載せる値。 */
        public String getKey() {
            return key;
        }

        /** 画面に出す名前。 */
        public String getLabel() {
            return label;
        }

        /** 中身の説明。 */
        public String getDescription() {
            return description;
        }

        /** 保存されるファイル名。 */
        public String getFileName() {
            return fileName;
        }

        /** 文字コード (画面用)。 */
        public String getCharsetLabel() {
            return charset.equals(StandardCharsets.UTF_8) ? "UTF-8（BOM あり）" : "Shift_JIS";
        }

        /** 中身 (バイト列)。 */
        byte[] toBytes() {
            Csv csv = new Csv(',', "\r\n", true, false);
            csv.row(EmployeeCsvRow.Column.labels().toArray());
            for (String[] row : rowsOf(this)) {
                csv.row((Object[]) row);
            }
            byte[] body = csv.text().getBytes(charset);
            if (!charset.equals(StandardCharsets.UTF_8)) {
                return body;
            }
            // Excel で開いても文字化けしないよう、UTF-8 には BOM を付ける
            byte[] withBom = new byte[body.length + 3];
            withBom[0] = (byte) 0xEF;
            withBom[1] = (byte) 0xBB;
            withBom[2] = (byte) 0xBF;
            System.arraycopy(body, 0, withBom, 3, body.length);
            return withBom;
        }

        static SampleFile of(String key) {
            for (SampleFile file : values()) {
                if (file.key.equals(key)) {
                    return file;
                }
            }
            return null;
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        SampleFile file = SampleFile.of(request.getParameter("file"));
        if (file == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        byte[] body = file.toBytes();
        response.setContentType("text/csv");
        response.setCharacterEncoding(file.charset.name());
        response.setHeader("Content-Disposition",
                CsvExportServlet.contentDisposition(file.fileName, file.fallbackFileName));
        response.setContentLength(body.length);
        try (OutputStream out = response.getOutputStream()) {
            out.write(body);
        }
    }

    /** ファイルごとのデータ行 (見出しは含まない)。 */
    static List<String[]> rowsOf(SampleFile file) {
        switch (file) {
            case TEMPLATE:
                return List.of();
            case VALID:
            case SJIS:
                return validRows();
            case INVALID:
                return invalidRows();
            default:
                throw new IllegalArgumentException(file.name());
        }
    }

    /** 正常なデータ。 */
    private static List<String[]> validRows() {
        return List.of(
                // 登録済み (営業部 → 開発部 への異動)。取り込むと上書きされる
                new String[] {"E00003", "佐藤 花子", "サトウ ハナコ", "hanako.sato@example.com",
                    "D03", "正社員", "2021-04-01"},
                new String[] {"E10001", "山田 太郎", "ヤマダ タロウ", "taro.yamada@example.com",
                    "D02", "正社員", "2026-04-01"},
                // Excel で保存し直すと日付はこの形になる。受け付ける
                new String[] {"E10002", "鈴木 一郎", "スズキ イチロウ", "ichiro.suzuki@example.com",
                    "D03", "契約社員", "2026/4/15"},
                // 値の中にカンマ。CSV では " で囲まれる
                new String[] {"E10003", "Brown, Emily", "ブラウン エミリー", "emily.brown@example.com",
                    "D02", "契約社員", "2026-05-01"},
                new String[] {"E10004", "田中 ゆり", "タナカ ユリ", "yuri.tanaka@example.com",
                    "D04", "パート", "2026-06-01"});
    }

    /** エラーを含むデータ。どの行も 1 〜 2 種類のエラーになるようにしてある。 */
    private static List<String[]> invalidRows() {
        return List.of(
                // 2 行目 : 社員コードが空 (必須)
                new String[] {"", "山田 太郎", "ヤマダ タロウ", "taro.yamada@example.com",
                    "D02", "正社員", "2026-04-01"},
                // 3 行目 : 社員コードにハイフン (文字種)
                new String[] {"E-1001", "佐々木 健", "ササキ ケン", "ken.sasaki@example.com",
                    "D02", "正社員", "2026-04-01"},
                // 4 行目 : 社員コードが 5 文字 (桁数)
                new String[] {"E1002", "木村 陽子", "キムラ ヨウコ", "yoko.kimura@example.com",
                    "D03", "正社員", "2026-04-01"},
                // 5 行目 : フリガナがひらがな (文字種)
                new String[] {"E10006", "林 大輔", "はやし だいすけ", "daisuke.hayashi@example.com",
                    "D03", "正社員", "2026-04-01"},
                // 6 行目 : フリガナが半角カタカナ (文字種)、メールアドレスにドメインが無い (形式)
                new String[] {"E10007", "清水 愛", "ｼﾐｽﾞ ｱｲ", "ai.shimizu@example",
                    "D04", "正社員", "2026-04-01"},
                // 7 行目 : 部署マスタに無い (マスタ)、雇用区分が選択肢に無い (選択肢)
                new String[] {"E10008", "森 拓也", "モリ タクヤ", "takuya.mori@example.com",
                    "D99", "アルバイト", "2026-04-01"},
                // 8 行目 : 2 月 30 日は無い (形式)
                new String[] {"E10009", "池田 由美", "イケダ ユミ", "yumi.ikeda@example.com",
                    "D01", "正社員", "2026-02-30"},
                // 9 行目 : 日付の書き方が違う (形式)
                new String[] {"E10010", "山口 翔", "ヤマグチ ショウ", "sho.yamaguchi@example.com",
                    "D02", "正社員", "2026年4月1日"},
                // 10 行目 : 2026 と 2062 の打ち間違い (範囲)
                new String[] {"E10011", "阿部 さくら", "アベ サクラ", "sakura.abe@example.com",
                    "D03", "パート", "2062-04-01"},
                // 11 行目 : 正しい行。ただし 1 件でもエラーがあるので、この行も登録されない
                new String[] {"E10012", "石井 修", "イシイ オサム", "osamu.ishii@example.com",
                    "D03", "正社員", "2026-04-01"},
                // 12 行目 : 11 行目と同じ社員コード (重複)
                new String[] {"E10012", "前田 亮", "マエダ リョウ", "ryo.maeda@example.com",
                    "D02", "正社員", "2026-04-01"},
                // 13 行目 : 値が 8 つある (列数)。備考を書き足してしまった
                new String[] {"E10013", "岡田 結衣", "オカダ ユイ", "yui.okada@example.com",
                    "D01", "正社員", "2026-04-01", "4 月から時短勤務"},
                // 14 行目 : 氏名が 42 文字 (桁数)
                new String[] {"E10014", "寿限無寿限無五劫の擦り切れ海砂利水魚の水行末雲来末風来末食う寝る処に住む処やぶら小路",
                    "ジュゲム", "jugemu@example.com", "D01", "正社員", "2026-04-01"},
                // 15 行目 : 社員コード以外が空 (必須がまとめて出る)
                new String[] {"E10015", "", "", "", "", "", ""},
                // 16 行目 : 何も入っていない行。Excel で保存するとよく付いてくる。エラーにせず読み飛ばす
                new String[] {"", "", "", "", "", "", ""});
    }
}
