package com.ecommerce.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Opens a JDBC connection to PostgreSQL using environment variables
 * (set in docker-compose.yml, or on your shell when running locally):
 *
 *   DB_URL      e.g. jdbc:postgresql://localhost:5432/ecommerce_db
 *   DB_USER     e.g. ecommerce
 *   DB_PASSWORD e.g. ecommerce_pass
 */
public class DbConnection {

    public static Connection get() throws SQLException {
        String url = System.getenv("DB_URL");
        String user = System.getenv("DB_USER");
        String password = System.getenv("DB_PASSWORD");

        if (url == null || user == null || password == null) {
            throw new SQLException(
                "Missing DB_URL / DB_USER / DB_PASSWORD environment variables. " +
                "Set them in docker-compose.yml or your shell before starting Tomcat.");
        }

        return DriverManager.getConnection(url, user, password);
    }
}
