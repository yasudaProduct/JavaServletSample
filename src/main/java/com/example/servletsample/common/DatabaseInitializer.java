package com.example.servletsample.common;

import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Enumeration;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

import com.example.servletsample.samples.advanced.TransferDao;
import com.example.servletsample.samples.file.StoredFileDao;
import com.example.servletsample.samples.list.CustomerDao;
import com.example.servletsample.samples.list.ProductDao;
import com.example.servletsample.samples.test.JdbcOrderRepository;

/**
 * アプリケーションの起動・停止に合わせて組み込みデータベースを準備するリスナー。
 *
 * <p>テーブルの作成そのものは、それぞれのサンプルの DAO
 * ({@link StoredFileDao} / {@link ProductDao} / {@link CustomerDao} /
 * {@link TransferDao} / {@link JdbcOrderRepository}) が持っています。
 * ここではアプリの起動時にまとめて呼び出し、
 * 「最初の 1 人目のアクセスが遅くなる」「起動時に気付けない」を防いでいます。</p>
 */
@WebListener
public class DatabaseInitializer implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent event) {
        ServletContext context = event.getServletContext();
        try {
            StoredFileDao.prepareTable();
            ProductDao.prepareTable();
            CustomerDao.prepareTable();
            TransferDao.prepareTable();
            JdbcOrderRepository.prepareTable();
            context.log("組み込みデータベース (H2) を初期化しました");
        } catch (RuntimeException e) {
            context.log("組み込みデータベースの初期化に失敗しました", e);
            throw e;
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        ServletContext context = event.getServletContext();
        try {
            Database.shutdown();
        } catch (RuntimeException e) {
            // 停止処理なので、失敗してもアプリの終了は続行する
            context.log("組み込みデータベースの停止に失敗しました", e);
        }
        deregisterDrivers(context);
    }

    /**
     * このアプリが読み込んだ JDBC ドライバの登録を解除する。
     *
     * <p>{@code WEB-INF/lib} に入れたドライバは、アプリを入れ替えても
     * {@link DriverManager} 側に登録が残り、古いクラスローダごとメモリに居座ってしまいます
     * (Tomcat のログに「failed to unregister it」と警告が出るのはこれです)。
     * 自分で読み込んだものだけを対象に、停止時に外しておきます。</p>
     */
    private void deregisterDrivers(ServletContext context) {
        ClassLoader loader = getClass().getClassLoader();
        Enumeration<Driver> drivers = DriverManager.getDrivers();
        while (drivers.hasMoreElements()) {
            Driver driver = drivers.nextElement();
            if (driver.getClass().getClassLoader() != loader) {
                continue;   // Tomcat 本体や JDK が読み込んだものには触らない
            }
            try {
                DriverManager.deregisterDriver(driver);
            } catch (SQLException e) {
                context.log("JDBC ドライバの登録解除に失敗しました: " + driver.getClass().getName(), e);
            }
        }
    }
}
