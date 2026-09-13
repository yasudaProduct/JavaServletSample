package com.example.servletsample.common;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

import com.example.servletsample.catalog.SampleCatalog;

/**
 * アプリケーション起動時にカタログを application スコープへ載せるリスナー。
 *
 * <p>これにより、どの JSP からも {@code ${catalog}} でサンプル一覧を参照できます。</p>
 */
@WebListener
public class CatalogInitializer implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent event) {
        SampleCatalog catalog = SampleCatalog.getInstance();
        event.getServletContext().setAttribute(SampleCatalog.ATTRIBUTE_NAME, catalog);
        event.getServletContext().log(
                "サンプルカタログを読み込みました: " + catalog.getSamples().size() + " 件");
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        event.getServletContext().removeAttribute(SampleCatalog.ATTRIBUTE_NAME);
    }
}
