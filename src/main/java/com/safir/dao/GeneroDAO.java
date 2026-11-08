package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.Genero;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Categorías (tabla genero) para el catálogo.
 *
 * El conteo usa la vista v_catalogo_obras, así que solo cuenta las obras
 * que realmente aparecen en el catálogo (publicadas).
 */
public class GeneroDAO {

    /** Todas las categorías con su número de obras publicadas ("Otro" al final). */
    private static final String SQL_LISTAR =
            "SELECT g.id, g.nombre, COUNT(v.id) AS total_obras " +
            "FROM genero g " +
            "LEFT JOIN v_catalogo_obras v ON v.genero = g.nombre " +
            "GROUP BY g.id, g.nombre " +
            "ORDER BY (LOWER(g.nombre) = 'otro'), g.nombre";

    public List<Genero> listarConConteo() throws SQLException {

        List<Genero> generos = new ArrayList<>();

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(SQL_LISTAR);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                generos.add(new Genero(
                        rs.getInt("id"),
                        rs.getString("nombre"),
                        rs.getLong("total_obras")));
            }
        }

        return generos;
    }

    /** Una categoría con su conteo, o null si no existe. */
    public Genero buscarPorId(int id) throws SQLException {

        String sql =
                "SELECT g.id, g.nombre, COUNT(v.id) AS total_obras " +
                "FROM genero g " +
                "LEFT JOIN v_catalogo_obras v ON v.genero = g.nombre " +
                "WHERE g.id = ? " +
                "GROUP BY g.id, g.nombre";

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Genero(
                            rs.getInt("id"),
                            rs.getString("nombre"),
                            rs.getLong("total_obras"));
                }
            }
        }

        return null;
    }

    /** Busca el id de una categoría por su nombre (sin importar mayúsculas). */
    public Integer buscarIdPorNombre(String nombre) throws SQLException {

        if (nombre == null || nombre.isBlank()) {
            return null;
        }

        String sql = "SELECT id FROM genero WHERE LOWER(nombre) = LOWER(?)";

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, nombre.trim());

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("id") : null;
            }
        }
    }

    // ------------------------------------------------------------------
    // Caché para el menú desplegable del encabezado: el encabezado sale en
    // casi todas las páginas y las categorías casi nunca cambian, así que
    // se consulta la BD como mucho una vez por minuto.
    // ------------------------------------------------------------------

    private static final long DURACION_CACHE_MS = 60_000;
    // Si la BD falla, no se reintenta en cada página (cada intento puede tardar):
    // se espera unos segundos antes de volver a consultar.
    private static final long REINTENTO_TRAS_ERROR_MS = 10_000;
    private static volatile List<Genero> cacheMenu = Collections.emptyList();
    private static volatile long cacheMenuHasta = 0;

    /** Categorías para el menú "Catálogo" del encabezado. Nunca lanza excepción. */
    public static List<Genero> listarParaMenu() {

        long ahora = System.currentTimeMillis();
        if (ahora < cacheMenuHasta) {
            return cacheMenu;
        }

        try {
            List<Genero> generos =
                    Collections.unmodifiableList(new GeneroDAO().listarConConteo());
            cacheMenu = generos;
            cacheMenuHasta = ahora + DURACION_CACHE_MS;
            return generos;
        } catch (SQLException e) {
            // Si falla la BD, el menú muestra lo último que se cargó (o solo
            // "Ver todo el catálogo") y se reintenta en unos segundos.
            cacheMenuHasta = ahora + REINTENTO_TRAS_ERROR_MS;
            return cacheMenu;
        }
    }

    /** Fuerza recargar el menú en la próxima visita (útil si se crean o editan categorías). */
    public static void invalidarCacheMenu() {
        cacheMenuHasta = 0;
    }
}