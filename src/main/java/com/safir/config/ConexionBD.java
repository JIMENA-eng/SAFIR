package com.safir.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionBD {

    private static final String URL =
            "jdbc:postgresql://localhost:5432/safir";

    private static final String USUARIO = "postgres";
    private static final String CLAVE = "admin";

    public static Connection conectar() throws SQLException {
        try {
            // Registra el driver explícitamente: dentro del servidor de aplicaciones
            // DriverManager puede no encontrarlo ("No suitable driver found").
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("No se encontró el driver de PostgreSQL en WEB-INF/lib.", e);
        }
        return DriverManager.getConnection(URL, USUARIO, CLAVE);
    }
}