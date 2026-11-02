package com.safir.util;

import java.sql.SQLException;

public final class SqlErrores {

    /** SQLSTATE de los RAISE EXCEPTION escritos en las funciones de negocio. */
    public static final String REGLA_NEGOCIO = "P0001";

    private SqlErrores() {}

    public static boolean esReglaNegocio(SQLException e) {
        return REGLA_NEGOCIO.equals(e.getSQLState());
    }

    /** Solo el texto del RAISE, sin "ERROR:" ni el "Where:" de PostgreSQL. */
    public static String mensaje(SQLException e) {
        String m = e.getMessage();
        if (m == null) return "Ocurrió un error.";
        String primera = m.lines().findFirst().orElse(m);
        return primera.replaceFirst("^ERROR:\\s*", "").trim();
    }
}