package com.ecommerce.servlet;

import com.ecommerce.dao.DbConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;

/**
 * Confirms the app can reach PostgreSQL. Visit /javaee-ecommerce/db-test.
 */
@WebServlet("/db-test")
public class DbTestServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("text/plain;charset=UTF-8");
        try (Connection conn = DbConnection.get()) {
            resp.getWriter().println("Connected to PostgreSQL successfully.");
            resp.getWriter().println("Catalog: " + conn.getCatalog());
        } catch (Exception e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().println("DB connection failed: " + e.getMessage());
        }
    }
}
