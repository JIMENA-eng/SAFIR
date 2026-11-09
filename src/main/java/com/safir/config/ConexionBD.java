package com.safir.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Conexión a PostgreSQL. Ningún dato secreto va en el código: todo sale de
 * variables de entorno (o, si no existen, de propiedades -D de la JVM).
 *
 *   SAFIR_DB_URL      opcional, por defecto jdbc:postgresql://localhost:5432/safir
 *   SAFIR_DB_USUARIO  opcional, por defecto postgres
 *   SAFIR_DB_CLAVE    OBLIGATORIA, sin valor por defecto
 */
public class ConexionBD {

    private static final String URL_POR_DEFECTO =
            "jdbc:postgresql://localhost:5432/safir";
    private static final String USUARIO_POR_DEFECTO = "postgres";

    private ConexionBD() { }

    /** Lee primero la variable de entorno y luego la propiedad -D con el mismo nombre. */
    private static String leer(String nombre) {
        String v = System.getenv(nombre);
        if (v == null || v.isBlank()) {
            v = System.getProperty(nombre);
        }
        return (v == null || v.isBlank()) ? null : v.trim();
    }

    public static Connection conectar() throws SQLException {
        try {
            // Registra el driver explícitamente: dentro del servidor de aplicaciones
            // DriverManager puede no encontrarlo ("No suitable driver found").
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("No se encontró el driver de PostgreSQL en WEB-INF/lib.", e);
        }

        String url = leer("SAFIR_DB_URL");
        String usuario = leer("SAFIR_DB_USUARIO");
        String clave = leer("SAFIR_DB_CLAVE");

        if (clave == null) {
            // Mensaje claro, sin revelar nada secreto.
            throw new SQLException(
                    "Falta la variable de entorno SAFIR_DB_CLAVE (clave de PostgreSQL). "
                    + "Defínela antes de iniciar Tomcat; mira el README.");
        }
        return DriverManager.getConnection(
                url != null ? url : URL_POR_DEFECTO,
                usuario != null ? usuario : USUARIO_POR_DEFECTO,
                clave);
    }
}