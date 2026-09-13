package com.ecommerce.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Opens a JDBC connection to SQL Server using environment variables
 * (set in docker-compose.yml, or on your shell when running locally):
 *
 *   DB_URL      e.g. jdbc:sqlserver://localhost:1433;databaseName=ecommerce_db;encrypt=true;trustServerCertificate=true
 *   DB_USER     e.g. sa
 *   DB_PASSWORD e.g. Ecommerce_Pass1!
 *
 * Requires the mssql-jdbc driver jar in web/WEB-INF/lib (see README).
 *
 * NOTE: the driver is loaded explicitly below via Class.forName(), rather
 * than relying on JDBC 4+ automatic service-loader registration. Tomcat's
 * built-in memory-leak-prevention listener triggers DriverManager's
 * one-time driver scan very early during server startup, before this
 * webapp's WEB-INF/lib jars are visible - so automatic registration
 * silently fails to pick up drivers that only live in a webapp's own
 * lib folder. Explicitly loading the class here forces it to register
 * itself (its static initializer calls DriverManager.registerDriver()),
 * independent of that early scan.
 */
public class DbConnection {

    static {
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError(
                    "mssql-jdbc driver not found on classpath - check web/WEB-INF/lib. " + e);
        }
    }

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