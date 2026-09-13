<%--
  【サンプル】Bootstrap 4 の基本パーツ

  Servlet を使わない、JSP だけのサンプルです。
  カタログに登録しておけば SampleDispatcherServlet がこの JSP へ転送してくれます。
--%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="t" tagdir="/WEB-INF/tags" %>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<t:sample sampleId="bootstrap-basics">

  <jsp:attribute name="explanation">
    <%-- ===================== 解説タブ ===================== --%>
    <h2>Bootstrap 4 の考え方</h2>
    <p>
      Bootstrap は「あらかじめ用意された CSS のクラス名を HTML に付けるだけで画面が整う」ライブラリです。
      独自の CSS を書く前に、まず既存のクラスで組めないかを考えると、画面全体の見た目が揃いやすくなります。
    </p>

    <h2>覚えておくと困らない 4 つ</h2>
    <ul>
      <li>
        <strong>グリッド</strong>：<code>container</code> &gt; <code>row</code> &gt; <code>col-*</code> の 3 階層。
        列は 12 分割で、<code>col-md-6</code> のように画面幅の区切り（<code>sm / md / lg / xl</code>）を挟むと
        「狭い画面では縦積み、広い画面では横並び」になります。
      </li>
      <li>
        <strong>余白</strong>：<code>m</code>(margin) / <code>p</code>(padding) + 方向（<code>t b l r x y</code>）+ 大きさ（<code>0〜5</code>）。
        例：<code>mt-3</code>（上に余白）、<code>px-2</code>（左右に余白）。
        独自 CSS を書かずに余白を調整できます。
      </li>
      <li>
        <strong>色</strong>：<code>primary / secondary / success / danger / warning / info / light / dark</code> の 8 色。
        <code>btn-primary</code>、<code>text-danger</code>、<code>badge-success</code> のように部品名と組み合わせます。
      </li>
      <li>
        <strong>JavaScript が要る部品</strong>：タブ、モーダル、ドロップダウン、トーストなどは
        jQuery と Bootstrap の JS 読み込みが必要です（このサイトでは <code>layout.tag</code> でまとめて読み込んでいます）。
      </li>
    </ul>

    <h2>このページの作り</h2>
    <p>
      このサンプルには Servlet がありません。
      <code>SampleDefinitions</code> にサンプルを登録し、<code>/WEB-INF/views/samples/design/bootstrap-basics.jsp</code>
      を置くだけで、<code>SampleDispatcherServlet</code> が URL と JSP を結び付けます。
    </p>
  </jsp:attribute>

  <jsp:body>
    <%-- ===================== デモタブ ===================== --%>

    <t:panel title="グリッド（12 分割）" note="画面幅で自動的に折り返します">
      <div class="row text-center mb-2">
        <div class="col-md-4"><div class="grid-demo">col-md-4</div></div>
        <div class="col-md-4"><div class="grid-demo">col-md-4</div></div>
        <div class="col-md-4"><div class="grid-demo">col-md-4</div></div>
      </div>
      <div class="row text-center mb-2">
        <div class="col-md-8"><div class="grid-demo">col-md-8</div></div>
        <div class="col-md-4"><div class="grid-demo">col-md-4</div></div>
      </div>
      <div class="row text-center">
        <div class="col-6 col-lg-3"><div class="grid-demo">col-6 col-lg-3</div></div>
        <div class="col-6 col-lg-3"><div class="grid-demo">col-6 col-lg-3</div></div>
        <div class="col-6 col-lg-3"><div class="grid-demo">col-6 col-lg-3</div></div>
        <div class="col-6 col-lg-3"><div class="grid-demo">col-6 col-lg-3</div></div>
      </div>
    </t:panel>

    <t:panel title="ボタン">
      <div class="mb-3">
        <button type="button" class="btn btn-primary">primary</button>
        <button type="button" class="btn btn-secondary">secondary</button>
        <button type="button" class="btn btn-success">success</button>
        <button type="button" class="btn btn-danger">danger</button>
        <button type="button" class="btn btn-warning">warning</button>
        <button type="button" class="btn btn-info">info</button>
        <button type="button" class="btn btn-light">light</button>
        <button type="button" class="btn btn-dark">dark</button>
        <button type="button" class="btn btn-link">link</button>
      </div>
      <div class="mb-3">
        <button type="button" class="btn btn-outline-primary">outline</button>
        <button type="button" class="btn btn-primary btn-sm">小さい (btn-sm)</button>
        <button type="button" class="btn btn-primary btn-lg">大きい (btn-lg)</button>
        <button type="button" class="btn btn-primary" disabled>無効 (disabled)</button>
      </div>
      <div class="btn-group" role="group" aria-label="ボタングループ">
        <button type="button" class="btn btn-outline-secondary">左</button>
        <button type="button" class="btn btn-outline-secondary">中</button>
        <button type="button" class="btn btn-outline-secondary">右</button>
      </div>
    </t:panel>

    <t:panel title="バッジとアラート">
      <p class="mb-3">
        <span class="badge badge-primary">primary</span>
        <span class="badge badge-success">success</span>
        <span class="badge badge-danger">danger</span>
        <span class="badge badge-warning">warning</span>
        <span class="badge badge-pill badge-info">丸い (badge-pill)</span>
      </p>
      <div class="alert alert-success" role="alert">登録が完了しました。（alert-success）</div>
      <div class="alert alert-warning" role="alert">入力内容を確認してください。（alert-warning）</div>
      <div class="alert alert-danger alert-dismissible fade show mb-0" role="alert">
        エラーが発生しました。（alert-danger / 閉じるボタン付き）
        <button type="button" class="close" data-dismiss="alert" aria-label="閉じる">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    </t:panel>

    <t:panel title="カード">
      <div class="row">
        <div class="col-md-4 mb-3">
          <div class="card h-100">
            <div class="card-body">
              <h5 class="card-title">カードの見出し</h5>
              <h6 class="card-subtitle mb-2 text-muted">サブタイトル</h6>
              <p class="card-text">一覧の 1 件分を表す箱としてよく使います。</p>
              <a href="#" class="card-link">詳細</a>
            </div>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="card h-100">
            <div class="card-header">ヘッダー付き</div>
            <div class="card-body">
              <p class="card-text mb-0">card-header / card-footer で区切れます。</p>
            </div>
            <div class="card-footer text-muted small">フッター</div>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="card h-100 border-primary">
            <div class="card-body">
              <h5 class="card-title text-primary">枠に色を付ける</h5>
              <p class="card-text mb-0"><code>border-primary</code> のように色を指定できます。</p>
            </div>
          </div>
        </div>
      </div>
    </t:panel>

    <t:panel title="テーブル" note="table-responsive で横スクロールできます">
      <div class="table-responsive">
        <table class="table table-striped table-hover table-bordered mb-0">
          <thead class="thead-light">
            <tr>
              <th scope="col">#</th>
              <th scope="col">商品名</th>
              <th scope="col" class="text-right">単価</th>
              <th scope="col" class="text-center">状態</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row">1</th>
              <td>サンプル商品A</td>
              <td class="text-right">1,200 円</td>
              <td class="text-center"><span class="badge badge-success">販売中</span></td>
            </tr>
            <tr>
              <th scope="row">2</th>
              <td>サンプル商品B</td>
              <td class="text-right">3,480 円</td>
              <td class="text-center"><span class="badge badge-secondary">在庫なし</span></td>
            </tr>
            <tr>
              <th scope="row">3</th>
              <td>サンプル商品C</td>
              <td class="text-right">980 円</td>
              <td class="text-center"><span class="badge badge-warning">入荷待ち</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </t:panel>

    <t:panel title="フォーム部品">
      <form onsubmit="return false;">
        <div class="form-row">
          <div class="form-group col-md-6">
            <label for="demoName">氏名 <span class="text-danger">*</span></label>
            <input type="text" class="form-control" id="demoName" placeholder="山田 太郎">
            <small class="form-text text-muted">補助的な説明は form-text で書きます。</small>
          </div>
          <div class="form-group col-md-6">
            <label for="demoEmail">メールアドレス</label>
            <input type="email" class="form-control is-invalid" id="demoEmail" value="taro.example">
            <div class="invalid-feedback">メールアドレスの形式が正しくありません。</div>
          </div>
        </div>
        <div class="form-row">
          <div class="form-group col-md-4">
            <label for="demoSelect">都道府県</label>
            <select class="form-control" id="demoSelect">
              <option>東京都</option>
              <option>大阪府</option>
              <option>愛知県</option>
            </select>
          </div>
          <div class="form-group col-md-8">
            <label for="demoNote">備考</label>
            <textarea class="form-control" id="demoNote" rows="2"></textarea>
          </div>
        </div>
        <div class="form-group form-check">
          <input type="checkbox" class="form-check-input" id="demoCheck" checked>
          <label class="form-check-label" for="demoCheck">利用規約に同意する</label>
        </div>
        <div class="form-group mb-0">
          <div class="form-check form-check-inline">
            <input class="form-check-input" type="radio" name="demoRadio" id="demoRadio1" checked>
            <label class="form-check-label" for="demoRadio1">はい</label>
          </div>
          <div class="form-check form-check-inline">
            <input class="form-check-input" type="radio" name="demoRadio" id="demoRadio2">
            <label class="form-check-label" for="demoRadio2">いいえ</label>
          </div>
        </div>
      </form>
    </t:panel>

    <t:panel title="ページネーションとモーダル">
      <nav aria-label="ページ送り" class="mb-3">
        <ul class="pagination mb-0">
          <li class="page-item disabled"><a class="page-link" href="#">前へ</a></li>
          <li class="page-item active"><a class="page-link" href="#">1</a></li>
          <li class="page-item"><a class="page-link" href="#">2</a></li>
          <li class="page-item"><a class="page-link" href="#">3</a></li>
          <li class="page-item"><a class="page-link" href="#">次へ</a></li>
        </ul>
      </nav>

      <button type="button" class="btn btn-outline-primary" data-toggle="modal" data-target="#demoModal">
        モーダルを開く
      </button>
      <div class="modal fade" id="demoModal" tabindex="-1" role="dialog" aria-labelledby="demoModalLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="demoModalLabel">確認</h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="閉じる">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p class="mb-0">モーダルは Bootstrap の JavaScript で動きます。</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-dismiss="modal">閉じる</button>
              <button type="button" class="btn btn-primary" data-dismiss="modal">OK</button>
            </div>
          </div>
        </div>
      </div>
    </t:panel>

  </jsp:body>
</t:sample>
