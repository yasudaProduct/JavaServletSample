<%--
  【サンプル】検索条件つきの一覧画面 (ページング・並び替えあり)

  ProductListServlet が次の値をセットします。
    search       … 画面から受け取った検索条件 (ProductSearch)
    productPage  … 表示する行 + 全件数 (Page<Product>)
    categories   … 絞り込み用のカテゴリ一覧
    executedSql  … 実際に実行された SQL (説明用)
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<c:set var="listUrl" value="${ctx}/samples/list/search-list" />
<t:sample sampleId="search-list">

  <jsp:attribute name="explanation">
    <h2>ページングの考え方</h2>
    <p>
      一覧を全件取ってきて Java 側で切り出すこともできますが、
      件数が増えるとメモリも転送量も無駄になります。
      <strong>そのページに必要な行だけを DB に取り出させる</strong>のが基本です。
    </p>
    <p>そのために問い合わせを 2 回行います。</p>
<pre><code class="language-sql">-- ① 全部で何件あるか (ページ数の計算に使う)
SELECT COUNT(*) FROM products WHERE ...;

-- ② そのページの分だけ取り出す
SELECT id, code, name, category, price, stock, updated_at
  FROM products
 WHERE ...
 ORDER BY code ASC, id ASC
 LIMIT 10 OFFSET 20;   -- 3 ページ目 (10 件ずつ)</code></pre>
    <p>
      <code>OFFSET</code> は <code>(ページ番号 - 1) × 1ページの件数</code> です。
      並び順が一意に決まらないと、ページをまたいだときに同じ行が 2 回出たり抜けたりします。
      そのため <code>ORDER BY</code> の最後には必ず <code>id</code> のような一意な列を足しておきます。
    </p>

    <h2>検索条件は GET で受け取る</h2>
    <p>
      検索フォームを <code>method="get"</code> にすると、条件が URL に残ります。
    </p>
    <ul>
      <li>「2 ページ目の検索結果」をブックマークしたり、人に送ったりできる</li>
      <li>ページ送りのリンクを普通の <code>&lt;a&gt;</code> で書ける</li>
      <li>再読み込みしても「再送信しますか？」が出ない</li>
    </ul>
    <p>
      逆に、登録や削除のように<strong>状態を変える処理</strong>は POST にします
      （<a href="${ctx}/samples/design/modal-dialog">モーダル表示のサンプル</a>で扱っています）。
    </p>

    <h2>受け取った値は必ず検査する</h2>
    <p>
      URL は利用者が自由に書き換えられます。<code>?page=abc</code> でも
      <code>?page=-1</code> でも落ちないよう、受け取った時点で正規化します
      （このサンプルでは <code>ProductSearch.from(request)</code> がまとめて行っています）。
    </p>
    <p>
      特に危ないのが<strong>並び替え</strong>です。
      <code>ORDER BY</code> の列名は <code>?</code> で置き換えられないため、
      受け取った文字列をそのまま SQL に埋めると SQL インジェクションの入口になります。
      「許可した名前だけを通す」ホワイトリスト方式にします。
    </p>
<pre><code class="language-java">// 画面のキー → テーブルの列名。ここに無い値は既定 (code) に丸める
SORT_COLUMNS.put("code",  "code");
SORT_COLUMNS.put("name",  "name");
SORT_COLUMNS.put("price", "price");</code></pre>

    <h2>LIKE 検索の落とし穴</h2>
    <p>
      キーワードを <code>%キーワード%</code> の形にして <code>LIKE</code> で探しますが、
      利用者が <code>%</code> や <code>_</code> を入力すると、それ自体がワイルドカードとして働いてしまいます
      （<code>%</code> だけで検索すると全件一致）。エスケープ文字を決めて打ち消しておきます。
    </p>
<pre><code class="language-sql">WHERE LOWER(name) LIKE ? ESCAPE '!'   -- パラメータは "%50!%オフ%" のように渡す</code></pre>

    <h2>ページ番号を全部並べない</h2>
    <p>
      100 ページあるときに 1 〜 100 を並べても押せません。
      現在のページの前後だけを出し、行き来できるようにします
      （このサンプルでは <code>Page.getNumbers()</code> が計算しています）。
    </p>

    <h2>つまずきやすい所</h2>
    <ul>
      <li>
        <strong>ページ送りで条件が消える</strong>：
        ページ番号だけのリンクにすると検索条件が外れます。
        条件を持ち回るため、このサンプルでは
        <code>ProductSearch.queryForPage(n)</code> がクエリ文字列を組み立てています。
      </li>
      <li>
        <strong>絞り込んだら表示が空になる</strong>：
        5 ページ目を見ている状態で条件を絞ると、2 ページしか無いのに 5 ページ目を見ようとします。
        Servlet 側で総ページ数に収まるよう戻しています。
      </li>
      <li>
        <strong>日本語が文字化けする</strong>：
        GET のパラメータはサーブレットコンテナの設定に依存します。
        このサイトでは <code>web.xml</code> の
        <code>&lt;request-character-encoding&gt;</code> で UTF-8 にしています。
      </li>
      <li>
        <strong>件数の SQL と一覧の SQL で条件がずれる</strong>：
        WHERE 句は 1 か所で組み立て、件数用と一覧用で使い回します。
      </li>
    </ul>
  </jsp:attribute>

  <jsp:body>
    <%-- ============================================================
         検索フォーム (GET なので条件が URL に残る)
         ============================================================ --%>
    <t:panel title="検索条件" note="method=&quot;get&quot; : 条件が URL に残ります">
      <form action="${listUrl}" method="get" class="form-row align-items-end">
        <div class="form-group col-md-4 mb-2">
          <label for="q">キーワード</label>
          <input type="search" class="form-control" id="q" name="q"
                 value="${fn:escapeXml(search.keyword)}" placeholder="商品名・コード・カテゴリ">
        </div>

        <div class="form-group col-md-3 mb-2">
          <label for="category">カテゴリ</label>
          <select class="form-control" id="category" name="category">
            <option value="">すべて</option>
            <c:forEach var="category" items="${categories}">
              <option value="${fn:escapeXml(category)}"
                      ${search.category eq category ? 'selected' : ''}>${fn:escapeXml(category)}</option>
            </c:forEach>
          </select>
        </div>

        <div class="form-group col-md-2 mb-2">
          <label for="size">表示件数</label>
          <select class="form-control" id="size" name="size">
            <c:forEach var="pageSize" items="${search.pageSizes}">
              <option value="${pageSize}" ${search.pageSize eq pageSize ? 'selected' : ''}>
                ${pageSize} 件
              </option>
            </c:forEach>
          </select>
        </div>

        <div class="form-group col-md-3 mb-2">
          <div class="custom-control custom-checkbox mb-2">
            <input type="checkbox" class="custom-control-input" id="stock" name="stock"
                   ${search.inStockOnly ? 'checked' : ''}>
            <label class="custom-control-label" for="stock">在庫ありのみ</label>
          </div>
          <button type="submit" class="btn btn-primary">
            <t:icon name="search" cssClass="mr-1" />検索
          </button>
          <c:if test="${search.filtered}">
            <a class="btn btn-link" href="${listUrl}">条件をクリア</a>
          </c:if>
        </div>

        <%-- 並び順は検索し直しても維持したいので、hidden で持ち回る --%>
        <input type="hidden" name="sort" value="${fn:escapeXml(search.sort)}">
        <input type="hidden" name="order" value="${search.ascending ? 'asc' : 'desc'}">
      </form>
    </t:panel>

    <%-- ============================================================
         一覧
         ============================================================ --%>
    <t:panel title="商品一覧" note="見出しをクリックすると並び替わります">
      <c:choose>
        <c:when test="${empty productPage.items}">
          <div class="empty-state">
            <t:icon name="search" size="32" cssClass="empty-state__icon" />
            <p class="empty-state__text">条件に一致する商品が見つかりませんでした。</p>
            <a class="btn btn-outline-primary btn-sm" href="${listUrl}">条件をクリアする</a>
          </div>
        </c:when>
        <c:otherwise>
          <div class="d-flex justify-content-between align-items-center mb-2">
            <p class="text-muted small mb-0">
              <strong>${productPage.totalCount}</strong> 件中
              ${productPage.firstItemNumber} - ${productPage.lastItemNumber} 件を表示
              （全 ${allCount} 件中）
            </p>
            <p class="text-muted small mb-0">
              ${productPage.number} / ${productPage.totalPages} ページ
            </p>
          </div>

          <div class="table-responsive">
            <table class="table table-sm table-hover">
              <thead class="thead-light">
                <tr>
                  <%-- 見出しは「その列で並び替える URL」へのリンクにする --%>
                  <th scope="col">
                    <a href="${listUrl}?${fn:escapeXml(search.queryForSort('code'))}">コード</a>
                    <c:if test="${search.isSortedBy('code')}">${search.ascending ? '▲' : '▼'}</c:if>
                  </th>
                  <th scope="col">
                    <a href="${listUrl}?${fn:escapeXml(search.queryForSort('name'))}">商品名</a>
                    <c:if test="${search.isSortedBy('name')}">${search.ascending ? '▲' : '▼'}</c:if>
                  </th>
                  <th scope="col">
                    <a href="${listUrl}?${fn:escapeXml(search.queryForSort('category'))}">カテゴリ</a>
                    <c:if test="${search.isSortedBy('category')}">${search.ascending ? '▲' : '▼'}</c:if>
                  </th>
                  <th scope="col" class="text-right">
                    <a href="${listUrl}?${fn:escapeXml(search.queryForSort('price'))}">価格</a>
                    <c:if test="${search.isSortedBy('price')}">${search.ascending ? '▲' : '▼'}</c:if>
                  </th>
                  <th scope="col" class="text-right">
                    <a href="${listUrl}?${fn:escapeXml(search.queryForSort('stock'))}">在庫</a>
                    <c:if test="${search.isSortedBy('stock')}">${search.ascending ? '▲' : '▼'}</c:if>
                  </th>
                  <th scope="col">
                    <a href="${listUrl}?${fn:escapeXml(search.queryForSort('updated'))}">更新日</a>
                    <c:if test="${search.isSortedBy('updated')}">${search.ascending ? '▲' : '▼'}</c:if>
                  </th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="product" items="${productPage.items}">
                  <tr>
                    <td class="align-middle"><code>${fn:escapeXml(product.code)}</code></td>
                    <td class="align-middle">${fn:escapeXml(product.name)}</td>
                    <td class="align-middle">${fn:escapeXml(product.category)}</td>
                    <td class="align-middle text-right">
                      <fmt:formatNumber value="${product.price}" type="number" /> 円
                    </td>
                    <td class="align-middle text-right">
                      <c:choose>
                        <c:when test="${product.inStock}">${product.stock}</c:when>
                        <c:otherwise><span class="badge badge-secondary">在庫切れ</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="align-middle">${product.updatedAtText}</td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>

          <%-- ========================================================
               ページ送り
               ======================================================== --%>
          <nav aria-label="ページ送り">
            <ul class="pagination pagination-sm justify-content-center mb-0">
              <li class="page-item ${productPage.first ? 'disabled' : ''}">
                <a class="page-link" href="${listUrl}?${fn:escapeXml(search.queryForPage(1))}"
                   aria-label="最初のページ">&laquo;</a>
              </li>
              <li class="page-item ${productPage.first ? 'disabled' : ''}">
                <a class="page-link"
                   href="${listUrl}?${fn:escapeXml(search.queryForPage(productPage.previousNumber))}">前へ</a>
              </li>

              <c:if test="${productPage.firstPageHidden}">
                <li class="page-item disabled"><span class="page-link">…</span></li>
              </c:if>

              <c:forEach var="number" items="${productPage.numbers}">
                <li class="page-item ${number eq productPage.number ? 'active' : ''}">
                  <a class="page-link"
                     href="${listUrl}?${fn:escapeXml(search.queryForPage(number))}">${number}</a>
                </li>
              </c:forEach>

              <c:if test="${productPage.lastPageHidden}">
                <li class="page-item disabled"><span class="page-link">…</span></li>
              </c:if>

              <li class="page-item ${productPage.last ? 'disabled' : ''}">
                <a class="page-link"
                   href="${listUrl}?${fn:escapeXml(search.queryForPage(productPage.nextNumber))}">次へ</a>
              </li>
              <li class="page-item ${productPage.last ? 'disabled' : ''}">
                <a class="page-link"
                   href="${listUrl}?${fn:escapeXml(search.queryForPage(productPage.totalPages))}"
                   aria-label="最後のページ">&raquo;</a>
              </li>
            </ul>
          </nav>
        </c:otherwise>
      </c:choose>
    </t:panel>

    <%-- ============================================================
         いま実行された SQL (何が起きているかを見せるための表示)
         ============================================================ --%>
    <t:panel title="この画面で実行された SQL" note="入力値は ? のまま。SQL には埋め込みません">
      <pre class="code-snippet mb-0"><code class="language-sql">${fn:escapeXml(executedSql)}</code></pre>
      <p class="text-muted small mt-2 mb-0">
        条件を変えて検索すると、<code>WHERE</code> 句と <code>OFFSET</code> が変わることを確認できます。
      </p>
    </t:panel>
  </jsp:body>
</t:sample>
