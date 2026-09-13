package com.example.servletsample.web;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.example.servletsample.common.BaseServlet;

/** このサンプル集について (構成・使い方の説明ページ)。 */
@WebServlet(name = "about", urlPatterns = {"/about"})
public class AboutServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("serverInfo", getServletContext().getServerInfo());
        request.setAttribute("javaVersion", System.getProperty("java.version"));
        request.setAttribute("servletVersion",
                getServletContext().getMajorVersion() + "." + getServletContext().getMinorVersion());
        render(request, response, "about");
    }
}
