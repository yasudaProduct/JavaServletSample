package com.example.servletsample.samples.list;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;
import com.example.servletsample.common.Flash;
import com.example.servletsample.common.ValidationErrors;
import com.example.servletsample.common.Validators;

/**
 * 【サンプル】更新の競合（楽観ロック）。
 *
 * <p>2 人が同じ行を同時に編集したときに何が起きるかを確かめます。</p>
 *
 * <pre>{@code
 * 10:00  A さんが編集画面を開く      (version = 1)
 * 10:01  B さんが編集画面を開く      (version = 1)
 * 10:02  B さんが保存               (version = 2 になる)
 * 10:05  A さんが保存               ← ここで何が起きるか
 * }</pre>
 *
 * <p>対策していないと、<b>A さんの保存が B さんの変更を黙って消します</b>
 * (更新の喪失)。誰も気付かないまま、B さんの修正がなかったことになります。</p>
 *
 * <p>楽観ロックは、この「黙って消す」を<b>「気付いて止まる」</b>に変えます。</p>
 *
 * <h2>このサンプルの試し方</h2>
 * <ol>
 *   <li>編集画面で値を書き換える (まだ保存しない)</li>
 *   <li>「別の人が先に更新した状況を作る」を押す
 *       — 画面はそのままで、データベース側だけが変わります</li>
 *   <li>「更新する」を押す → 競合が検出されます</li>
 * </ol>
 *
 * <p>本来はブラウザを 2 つ開いて試すところですが、1 人でも試せるようにしています。</p>
 */
@WebServlet(name = "optimisticLock", urlPatterns = {"/samples/list/optimistic-lock"})
public class OptimisticLockServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/list/optimistic-lock.jsp";

    /** このサンプルの URL。 */
    static final String PATH = "/samples/list/optimistic-lock";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Flash.consume(request);

        CustomerDao dao = new CustomerDao();
        List<Customer> customers = dao.findAll();

        // 指定が無ければ先頭の 1 件を編集対象にする
        long id = Validators.toInt(request.getParameter("id")).orElse(0);
        Optional<Customer> target = id > 0 ? dao.findById(id) : customers.stream().findFirst();

        if (target.isEmpty()) {
            Flash.set(request, "warning", "対象がありません", "取引先が登録されていません。");
            render(request, response, customers, CustomerForm.empty(), new ValidationErrors());
            return;
        }
        render(request, response, customers, CustomerForm.of(target.get()), new ValidationErrors());
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        CustomerDao dao = new CustomerDao();

        if ("reset".equals(action)) {
            dao.reset();
            Flash.set(request, "info", "元に戻しました", "取引先マスタを初期状態に戻しました。");
            response.sendRedirect(request.getContextPath() + PATH);
            return;
        }

        CustomerForm form = CustomerForm.from(request);

        if ("simulate".equals(action)) {
            simulate(request, response, dao, form);
            return;
        }

        if ("force".equals(action)) {
            forceUpdate(request, response, dao, form);
            return;
        }

        update(request, response, dao, form);
    }

    /**
     * 「別の人が先に更新した」状況を作る (デモ専用)。
     *
     * <p>要点は<b>リダイレクトしない</b>ことです。
     * 画面を読み込み直すと version も新しくなってしまい、競合が起きなくなります。
     * 送られてきた入力値 (古い version を含む) をそのまま画面に戻すことで、
     * 「利用者の画面はまだ気付いていない」状態を再現しています。</p>
     */
    private void simulate(HttpServletRequest request, HttpServletResponse response,
                          CustomerDao dao, CustomerForm form)
            throws ServletException, IOException {

        dao.simulateConcurrentUpdate(form.getIdValue());
        request.setAttribute("simulated", true);
        render(request, response, dao.findAll(), form, new ValidationErrors());
    }

    /** 通常の更新 (楽観ロックあり)。 */
    private void update(HttpServletRequest request, HttpServletResponse response,
                        CustomerDao dao, CustomerForm form)
            throws ServletException, IOException {

        ValidationErrors errors = form.validate();
        if (dao.existsCode(form.getCode(), form.getIdValue())) {
            errors.add("code", "その取引先コードは既に使われています。");
        }
        if (errors.hasErrors()) {
            render(request, response, dao.findAll(), form, errors);
            return;
        }

        int updated = dao.update(form);

        if (updated == 0) {
            // 更新できた行が 0 = 画面を開いたあとに誰かが更新している。
            // ここで「上書きしてしまう」実装にすると、相手の修正が黙って消えます
            conflict(request, response, dao, form);
            return;
        }

        Flash.set(request, "success", "更新しました",
                form.getName() + " を更新しました。version が 1 つ進みます。");
        response.sendRedirect(request.getContextPath() + PATH + "?id=" + form.getIdValue());
    }

    /**
     * 競合したことを画面に伝える。
     *
     * <p><b>「エラーです」だけで終わらせないこと。</b>
     * 利用者は何をすればよいか分かりません。
     * 「入力した内容」と「いま保存されている内容」を並べて見せ、
     * どうするかを選べるようにします。</p>
     */
    private void conflict(HttpServletRequest request, HttpServletResponse response,
                          CustomerDao dao, CustomerForm form)
            throws ServletException, IOException {

        Optional<Customer> current = dao.findById(form.getIdValue());

        if (current.isEmpty()) {
            // 競合ではなく、行そのものが消えていた場合
            ValidationErrors errors = new ValidationErrors();
            errors.addGlobal("この取引先は削除されています。一覧から選び直してください。");
            render(request, response, dao.findAll(), CustomerForm.empty(), errors);
            return;
        }

        request.setAttribute("conflict", true);
        request.setAttribute("currentCustomer", current.get());
        render(request, response, dao.findAll(), form, new ValidationErrors());
    }

    /**
     * 競合したうえで「自分の入力で上書きする」を選んだ場合。
     *
     * <p>最新の version を読み直してから更新します。
     * <b>これは「相手の変更を捨てる」という判断</b>なので、
     * 利用者に選ばせたうえで行います。勝手にやってはいけません。</p>
     */
    private void forceUpdate(HttpServletRequest request, HttpServletResponse response,
                             CustomerDao dao, CustomerForm form)
            throws ServletException, IOException {

        Optional<Customer> current = dao.findById(form.getIdValue());
        if (current.isEmpty()) {
            Flash.set(request, "warning", "更新できません", "この取引先は削除されています。");
            response.sendRedirect(request.getContextPath() + PATH);
            return;
        }

        // 画面から来た version ではなく、いまの version で更新する
        CustomerForm latest = CustomerForm.from(request);
        int updated = dao.update(withVersion(latest, current.get().getVersion()));

        if (updated == 0) {
            // 読み直してから更新するまでの間に、さらに別の更新が入った
            Flash.set(request, "warning", "もう一度お試しください",
                    "更新中にさらに別の変更がありました。");
        } else {
            Flash.set(request, "success", "上書きしました",
                    "他の人の変更を、入力した内容で上書きしました。");
        }
        response.sendRedirect(request.getContextPath() + PATH + "?id=" + form.getIdValue());
    }

    /** version だけ差し替えたフォームを作る。 */
    private static CustomerForm withVersion(CustomerForm form, int version) {
        return CustomerForm.of(new Customer(form.getIdValue(), form.getCode(), form.getName(),
                form.getContact(), form.getEmail(), version, null));
    }

    /** 画面を組み立てる。 */
    private void render(HttpServletRequest request, HttpServletResponse response,
                        List<Customer> customers, CustomerForm form, ValidationErrors errors)
            throws ServletException, IOException {

        request.setAttribute("customers", customers);
        request.setAttribute("form", form);
        request.setAttribute("errors", errors);
        forward(request, response, VIEW);
    }
}
