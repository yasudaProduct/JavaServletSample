<%--
  【サンプル】ファイルのアップロード / ダウンロード / 削除 (中身は DB に保存)

  FileUploadServlet   … 一覧の表示・アップロード・削除
  FileDownloadServlet … ダウンロード
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="file-upload">

  <jsp:attribute name="explanation">
    <h2>アップロードの流れ</h2>
    <ol>
      <li>フォームに <code>method="post"</code> と <code>enctype="multipart/form-data"</code> を付ける</li>
      <li>Servlet に <code>@MultipartConfig</code> を付ける</li>
      <li><code>request.getPart("file")</code> で受け取り、<code>getInputStream()</code> で中身を読む</li>
      <li>読んだ中身を DB の <code>BLOB</code> 列に保存する</li>
      <li>保存できたらリダイレクトする（PRG パターン）</li>
    </ol>
    <p>
      <code>enctype</code> を付け忘れると、ファイルの中身ではなく<strong>ファイル名だけ</strong>が
      送られてきます。「中身が空になる」ときはまずここを疑ってください。
    </p>
<pre><code class="language-java">@WebServlet("/samples/file/file-upload")
@MultipartConfig(
        fileSizeThreshold = 512 * 1024,     // これを超えたら一時ファイルに書き出す
        maxFileSize       = 5 * 1024 * 1024, // ファイル 1 つの上限
        maxRequestSize    = 6 * 1024 * 1024) // リクエスト全体の上限
public class FileUploadServlet extends BaseServlet { ... }</code></pre>

    <h2>ファイルを DB に入れる / ディスクに置く</h2>
    <div class="table-responsive">
      <table class="table table-sm table-bordered">
        <thead>
          <tr><th>方式</th><th>良い点</th><th>気をつける点</th></tr>
        </thead>
        <tbody>
          <tr>
            <td>DB に入れる（このサンプル）</td>
            <td>バックアップと一貫性が DB だけで済む / サーバを増やしても共有できる</td>
            <td>大きいファイルだと DB が重くなる / 一覧で中身まで読まないよう注意</td>
          </tr>
          <tr>
            <td>ディスクやオブジェクトストレージに置く</td>
            <td>大きいファイルに強い / 配信を任せられる</td>
            <td>DB のレコードと実ファイルがずれる（消し忘れ）ことがある</td>
          </tr>
        </tbody>
      </table>
    </div>
    <p>
      目安として、数 MB を超えるものはストレージに置き、DB にはパスだけを持たせる構成が一般的です。
    </p>

    <h2>一覧では中身を読まない</h2>
    <p>
      一覧に必要なのはファイル名・サイズ・日時だけです。
      <code>SELECT *</code> にすると全ファイルの中身まで読み込んでしまうため、
      列を指定して <code>BLOB</code> を外します。
    </p>
<pre><code class="language-sql">-- 一覧 : content (BLOB) は読まない
SELECT id, file_name, content_type, file_size, uploaded_at
  FROM uploaded_files
 ORDER BY uploaded_at DESC</code></pre>

    <h2>ダウンロードで付けるヘッダ</h2>
<pre><code class="language-java">response.setContentType(file.getContentType());
response.setContentLengthLong(file.getSize());
response.setHeader("Content-Disposition", "attachment; filename=\"...\"; filename*=UTF-8''...");
response.setHeader("X-Content-Type-Options", "nosniff");

try (OutputStream out = response.getOutputStream()) {
    dao.copyContentTo(id, out);   // DB から読みながらそのまま流す
}</code></pre>
    <ul>
      <li>
        <strong>日本語のファイル名</strong>：HTTP ヘッダには ASCII しか書けないため、
        古いブラウザ向けの <code>filename="..."</code> と、
        RFC 6266 の <code>filename*=UTF-8''...</code>（パーセントエンコード）を並べて書きます。
      </li>
      <li>
        <strong><code>attachment</code> と <code>nosniff</code></strong>：
        利用者がアップロードしたファイルをそのまま画面に表示すると、
        HTML や JavaScript が実行されてしまうおそれがあります（クロスサイトスクリプティング）。
        必ずダウンロードさせ、ブラウザに種類を推測させないようにします。
      </li>
      <li>
        <strong>中身は流しながら書く</strong>：
        いったん <code>byte[]</code> に読み込むと、大きいファイルでメモリを使い切ります。
      </li>
    </ul>

    <h2>受け取った値は必ず検査する</h2>
    <ul>
      <li>
        <strong>ファイル名</strong>：ブラウザによってはフルパスで送られてきます。
        また <code>../../etc/passwd</code> のような値が来ることもあるため、
        最後の区切り文字以降だけを使います（このサンプルでは
        <code>sanitizeFileName</code> が行っています）。
      </li>
      <li>
        <strong>サイズ</strong>：<code>@MultipartConfig</code> の上限はサーバが落とすための最後の砦です。
        画面にきちんとメッセージを出したいので、アプリ側でも
        <code>part.getSize()</code> を見て判断しています。
      </li>
      <li>
        <strong>ID</strong>：<code>?id=abc</code> のような値でも落ちないよう数値に変換できるか確認し、
        見つからなければ 404 を返します。
      </li>
      <li>
        <strong>表示</strong>：ファイル名は利用者が付けた文字列なので、
        画面に出すときは <code>fn:escapeXml</code> を通します。
      </li>
    </ul>

    <h2>このデモの制限</h2>
    <p>
      公開しているデモなので、保存できるのは <strong>1 ファイル ${fn:escapeXml(maxFileSizeText)} まで</strong>、
      <strong>${maxFiles} 件まで</strong>にしています。
      また DB はメモリ上で動かしているため、<strong>アプリを再起動すると保存したファイルは消えます</strong>。
    </p>
  </jsp:attribute>

  <jsp:attribute name="scripts">
    <script>
      // 削除モーダルは 1 つだけ用意し、押されたボタンの data 属性から中身を差し替える
      $('#deleteModal').on('show.bs.modal', function (event) {
        var button = $(event.relatedTarget);
        $('#deleteTargetName').text(button.data('file-name'));
        $('#deleteTargetId').val(button.data('file-id'));
      });

      // 選んだファイル名をボタンの横に出す (見た目だけの処理)
      $('#fileInput').on('change', function () {
        var name = this.files && this.files.length > 0 ? this.files[0].name : '選択されていません';
        $('#selectedFileName').text(name);
        $('#sizeError').addClass('d-none');
      });

      // 大きすぎるファイルは送信する前に止める。
      // これは待ち時間を減らすための「親切」であって、チェックではありません。
      // JavaScript は利用者側で無効にできるため、サーバ側の判定が本体です。
      $('#uploadForm').on('submit', function (event) {
        var input = document.getElementById('fileInput');
        if (input.files && input.files.length > 0 && input.files[0].size > ${maxFileSize}) {
          event.preventDefault();
          $('#sizeError').removeClass('d-none');
        }
      });
    </script>
  </jsp:attribute>

  <jsp:body>
    <%-- ============================================================
         アップロード
         ============================================================ --%>
    <t:panel title="ファイルをアップロードする"
             note="enctype=&quot;multipart/form-data&quot; が必須です">
      <form id="uploadForm" action="${ctx}/samples/file/file-upload" method="post"
            enctype="multipart/form-data">
        <div class="form-group">
          <label for="fileInput">ファイルを選ぶ</label>
          <input type="file" class="form-control-file" id="fileInput" name="file" required>
          <small class="form-text text-muted">
            選択中: <span id="selectedFileName">選択されていません</span>
          </small>
        </div>
        <button type="submit" class="btn btn-primary">
          <t:icon name="file-earmark-arrow-up" cssClass="mr-1" />アップロード
        </button>
        <span class="text-muted small ml-2">
          1 ファイル ${fn:escapeXml(maxFileSizeText)} まで / ${maxFiles} 件まで
        </span>

        <div id="sizeError" class="alert alert-danger mt-3 mb-0 d-none">
          ファイルが大きすぎます。${fn:escapeXml(maxFileSizeText)} 以下のファイルを選んでください。
        </div>
      </form>
    </t:panel>

    <%-- ============================================================
         一覧 (ダウンロード・削除)
         ============================================================ --%>
    <t:panel title="保存されているファイル"
             note="中身はデータベースの BLOB 列に入っています">
      <c:choose>
        <c:when test="${empty files}">
          <div class="empty-state">
            <t:icon name="file-earmark-arrow-up" size="32" cssClass="empty-state__icon" />
            <p class="empty-state__text mb-0">まだファイルがありません。上のフォームから追加してみてください。</p>
          </div>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-hover mb-2">
              <thead class="thead-light">
                <tr>
                  <th scope="col">ファイル名</th>
                  <th scope="col">種類</th>
                  <th scope="col" class="text-right">サイズ</th>
                  <th scope="col">アップロード日時</th>
                  <th scope="col" class="text-right">操作</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="file" items="${files}">
                  <tr>
                    <td class="align-middle">${fn:escapeXml(file.fileName)}</td>
                    <td class="align-middle"><code>${fn:escapeXml(file.contentType)}</code></td>
                    <td class="align-middle text-right">${file.sizeText}</td>
                    <td class="align-middle">${file.uploadedAtText}</td>
                    <td class="align-middle text-right text-nowrap">
                      <a class="btn btn-sm btn-outline-primary"
                         href="${ctx}/samples/file/file-upload/download?id=${file.id}">ダウンロード</a>
                      <button type="button" class="btn btn-sm btn-outline-danger ml-1"
                              data-toggle="modal" data-target="#deleteModal"
                              data-file-id="${file.id}" data-file-name="${fn:escapeXml(file.fileName)}">
                        削除
                      </button>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <p class="text-muted small mb-0">
            ${fn:length(files)} 件 / 合計 ${fn:escapeXml(totalSizeText)}
          </p>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <%-- ============================================================
         削除の確認モーダル (行ごとに作らず 1 つを使い回す)
         ============================================================ --%>
    <div class="modal fade" id="deleteModal" tabindex="-1" role="dialog"
         aria-labelledby="deleteModalTitle" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
          <form action="${ctx}/samples/file/file-upload" method="post">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="id" id="deleteTargetId">
            <div class="modal-header">
              <h5 class="modal-title" id="deleteModalTitle">削除の確認</h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p class="mb-0">
                <strong id="deleteTargetName"></strong> を削除します。よろしいですか？
              </p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-dismiss="modal">キャンセル</button>
              <button type="submit" class="btn btn-danger">削除する</button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <%-- 処理のあとにリダイレクトで戻ってきたときだけ、完了モーダルが開く --%>
    <t:resultModal message="${flash}" />
  </jsp:body>
</t:sample>
