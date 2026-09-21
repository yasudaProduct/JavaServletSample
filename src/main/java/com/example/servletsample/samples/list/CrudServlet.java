package com.example.servletsample.samples.list;

import java.io.IOException;
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
 * 【サンプル】マスタメンテナンス（登録・編集・削除）。
 *
 * <p>業務システムで何十画面も作ることになる、いちばん基本の形です。
 * 一覧を起点にして、登録・編集・削除がそこへ戻ってきます。</p>
 *
 * <pre>{@code
 *                ┌──────────────┐
 *                │     一覧      │←──────────┐
 *                └──────────────┘            │
 *                  │    │     │              │
 *          新規登録 │    │編集  │削除          │ リダイレクト
 *                  ↓    ↓     ↓              │ (PRG)
 *              ［入力］ ［入力］ ［確認］ ──POST─┘
 * }</pre>
 *
 * <h2>URL の持たせ方</h2>
 * <p>1 つの URL に {@code action} を付けて切り替えています。</p>
 *
 * <table border="1">
 *   <caption>受け付けるリクエスト</caption>
 *   <tr><th>リクエスト</th><th>動き</th></tr>
 *   <tr><td>{@code GET  /samples/list/crud}</td><td>一覧</td></tr>
 *   <tr><td>{@code GET  ?action=new}</td><td>登録フォーム</td></tr>
 *   <tr><td>{@code GET  ?action=edit&id=1}</td><td>編集フォーム</td></tr>
 *   <tr><td>{@code GET  ?action=delete&id=1}</td><td>削除の確認</td></tr>
 *   <tr><td>{@code POST action=create}</td><td>登録する</td></tr>
 *   <tr><td>{@code POST action=update}</td><td>更新する</td></tr>
 *   <tr><td>{@code POST action=delete}</td><td>削除する</td></tr>
 * </table>
 *
 * <p><b>表示は GET、更新は POST</b> がすべての土台です。
 * 削除を GET のリンクにすると、検索エンジンのクローラや
 * ブラウザの先読みが<b>勝手に削除して回ります</b>。
 * 実際に「管理画面のデータが全部消えた」事故の典型です。</p>
 *
 * <h2>更新と削除には version を付ける</h2>
 * <p>一覧を表示してから操作するまでの間に、
 * 誰かが同じ行を触っているかもしれません。
 * 詳しくは「更新の競合（楽観ロック）」のサンプルにあります。</p>
 */
@WebServlet(name = "crud", urlPatterns = {"/samples/list/crud"})
public class CrudServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    private static final String VIEW = "/WEB-INF/views/samples/list/crud.jsp";

    /** このサンプルの URL。 */
    static final String PATH = "/samples/list/crud";

    /** 一覧。 */
    static final String MODE_LIST = "list";

    /** 登録フォーム。 */
    static final String MODE_NEW = "new";

    /** 編集フォーム。 */
    static final String MODE_EDIT = "edit";

    /** 削除の確認。 */
    static final String MODE_DELETE = "delete";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Flash.consume(request);

        CustomerDao dao = new CustomerDao();
        String action = request.getParameter("action");
        long id = Validators.toInt(request.getParameter("id")).orElse(0);

        if (MODE_NEW.equals(action)) {
            render(request, response, dao, MODE_NEW, CustomerForm.empty(), new ValidationErrors());
            return;
        }

        if (MODE_EDIT.equals(action) || MODE_DELETE.equals(action)) {
            Optional<Customer> customer = dao.findById(id);
            if (customer.isEmpty()) {
                // 一覧を開いたあとに誰かが消した、ブックマークから開いた、URL を打ち間違えた
                Flash.set(request, "warning", "見つかりません",
                        "指定された取引先は存在しません。一覧から選び直してください。");
                response.sendRedirect(request.getContextPath() + PATH);
                return;
            }
            render(request, response, dao, action, CustomerForm.of(customer.get()),
                    new ValidationErrors());
            return;
        }

        render(request, response, dao, MODE_LIST, CustomerForm.empty(), new ValidationErrors());
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        CustomerDao dao = new CustomerDao();
        String action = request.getParameter("action");

        switch (action == null ? "" : action) {
            case "create":
                save(request, response, dao, false);
                return;
            case "update":
                save(request, response, dao, true);
                return;
            case "delete":
                delete(request, response, dao);
                return;
            case "reset":
                dao.reset();
                Flash.set(request, "info", "元に戻しました", "取引先マスタを初期状態に戻しました。");
                response.sendRedirect(request.getContextPath() + PATH);
                return;
            default:
                response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                        "action に指定できない値です: " + action);
        }
    }

    /** 登録・更新。 */
    private void save(HttpServletRequest request, HttpServletResponse response,
                      CustomerDao dao, boolean update) throws ServletException, IOException {

        CustomerForm form = CustomerForm.from(request);
        ValidationErrors errors = form.validate();

        // 一意性の確認。データベースにも UNIQUE 制約を置いてありますが、
        // 制約違反の例外をそのまま利用者に見せるわけにはいかないので、
        // ふだんはここで丁寧に伝えます
        if (Validators.isPresent(form.getCode())
                && dao.existsCode(form.getCode(), form.getIdValue())) {
            errors.add("code", "その取引先コードは既に使われています。");
        }

        if (errors.hasErrors()) {
            render(request, response, dao, update ? MODE_EDIT : MODE_NEW, form, errors);
            return;
        }

        if (!update) {
            long id = dao.insert(form);
            Flash.set(request, "success", "登録しました",
                    form.getName() + " を登録しました。(ID: " + id + ")");
            response.sendRedirect(request.getContextPath() + PATH);
            return;
        }

        int updated = dao.update(form);
        if (updated == 0) {
            // 楽観ロックで弾かれた
            Flash.set(request, "warning", "更新できませんでした",
                    "この取引先は、画面を開いたあとに他の人が変更しています。"
                            + "一覧を開き直して、最新の内容を確認してください。");
        } else {
            Flash.set(request, "success", "更新しました", form.getName() + " を更新しました。");
        }
        // PRG。再読み込みで二重に登録されないようにする
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /** 削除。 */
    private void delete(HttpServletRequest request, HttpServletResponse response, CustomerDao dao)
            throws IOException {

        long id = Validators.toInt(request.getParameter("id")).orElse(0);
        int version = Validators.toInt(request.getParameter("version")).orElse(-1);

        int deleted = dao.delete(id, version);
        if (deleted == 0) {
            Flash.set(request, "warning", "削除できませんでした",
                    "この取引先は、画面を開いたあとに他の人が変更または削除しています。");
        } else {
            Flash.set(request, "success", "削除しました", "取引先を削除しました。");
        }
        response.sendRedirect(request.getContextPath() + PATH);
    }

    /** 画面を組み立てる。 */
    private void render(HttpServletRequest request, HttpServletResponse response,
                        CustomerDao dao, String mode, CustomerForm form, ValidationErrors errors)
            throws ServletException, IOException {

        request.setAttribute("mode", mode);
        request.setAttribute("customers", dao.findAll());
        request.setAttribute("form", form);
        request.setAttribute("errors", errors);
        forward(request, response, VIEW);
    }
}
