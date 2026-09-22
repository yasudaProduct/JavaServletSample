package com.example.servletsample.samples.test;

import java.util.List;
import java.util.Optional;

/**
 * 注文サンプルのデータ置き場。
 *
 * <p><b>ここが「テストしやすさ」の分かれ目です。</b>
 * {@link OrderService} が {@code JdbcOrderRepository} を直接 {@code new} していると、
 * サービスのテストに必ず DB が付いてきます (DB を用意する、後片付けをする、遅い、
 * 在庫が他のテストと干渉する)。</p>
 *
 * <p>間に<b>インターフェース</b>を 1 枚挟んでおけば、本番では H2 を使う実装
 * ({@code JdbcOrderRepository})、テストではメモリ上の実装
 * ({@link InMemoryOrderRepository}) と差し替えられます。
 * サービスは「どちらが来ているか」を知りません。これを依存性の注入 (DI) と呼びます。</p>
 *
 * <p>差し替えるためのインターフェースなので、メソッドは
 * <b>サービスが本当に必要とするものだけ</b>に絞ります。
 * ここに {@code Connection} や {@code ResultSet} が出てくると、
 * メモリ上の実装が作れなくなり、挟んだ意味がなくなります。</p>
 */
public interface OrderRepository {

    /** 注文できる商品の一覧。 */
    List<Item> findItems();

    /** 商品コードで 1 件探す。無ければ空。 */
    Optional<Item> findItem(String code);

    /** 在庫を減らす。 */
    void decreaseStock(String itemCode, int quantity);

    /** 登録済みの注文件数 (受注番号の連番に使う)。 */
    int countOrders();

    /** 注文を保存する。 */
    void save(OrderEntry order);

    /** 新しい順に注文を取り出す。 */
    List<OrderEntry> findRecentOrders(int limit);

    /** サンプルを何度も試せるように、初期状態へ戻す。 */
    void reset();
}
