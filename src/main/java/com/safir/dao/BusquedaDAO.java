package com.safir.dao;

import com.safir.config.ConexionBD;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * TAREA 7: sugerencias del buscador del encabezado.
 *
 * Busca por coincidencia ("comunes"): basta con escribir una letra o parte de
 * una palabra. No distingue mayúsculas ni tildes ("fantasia" encuentra
 * "Fantasía"). Primero salen las que EMPIEZAN con el texto, luego las que
 * tienen una PALABRA que empieza con el texto y al final las que lo CONTIENEN.
 */
public class BusquedaDAO {

    /** Pasa una columna a minúsculas y sin tildes, igual que normalizar() en Java. */
    private static String sinTildes(String columna) {
        return "translate(lower(" + columna + "), "
                + "'\u00e1\u00e0\u00e4\u00e2\u00e9\u00e8\u00eb\u00ea\u00ed\u00ec\u00ef\u00ee\u00f3\u00f2\u00f6\u00f4\u00fa\u00f9\u00fc\u00fb\u00f1', "
                + "'aaaaeeeeiiiioooouuuun')";
    }

    /** Texto del usuario en minúsculas, sin tildes y con los comodines de LIKE escapados. */
    public static String normalizar(String texto) {
        if (texto == null) return "";
        String t = Normalizer.normalize(texto.trim(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT);
        return t.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }

    /** Obras publicadas cuyo título (o género / etiqueta) coincide con el texto. */
    public List<Map<String, Object>> sugerirObras(String texto, int limite) throws SQLException {

        String t = normalizar(texto);
        List<Map<String, Object>> lista = new ArrayList<>();
        if (t.isEmpty()) return lista;

        String titulo = sinTildes("titulo");
        String sql =
                "SELECT id, titulo, autor, genero, portada_ruta, " +
                "  CASE WHEN " + titulo + " LIKE ? THEN 0 " +          // empieza con
                "       WHEN " + titulo + " LIKE ? THEN 1 " +          // alguna palabra empieza con
                "       WHEN " + titulo + " LIKE ? THEN 2 " +          // lo contiene
                "       ELSE 3 END AS rango " +                         // coincide por género/etiqueta
                "FROM v_catalogo_obras " +
                "WHERE " + titulo + " LIKE ? " +
                "   OR " + sinTildes("genero") + " LIKE ? " +
                "   OR " + sinTildes("COALESCE(array_to_string(etiquetas, ' '), '')") + " LIKE ? " +
                "ORDER BY rango, total_lecturas DESC NULLS LAST, titulo " +
                "LIMIT ?";

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, t + "%");
            ps.setString(2, "% " + t + "%");
            ps.setString(3, "%" + t + "%");
            ps.setString(4, "%" + t + "%");
            ps.setString(5, t + "%");
            ps.setString(6, "%" + t + "%");
            ps.setInt(7, limite);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> o = new LinkedHashMap<>();
                    o.put("id", rs.getLong("id"));
                    o.put("titulo", rs.getString("titulo"));
                    o.put("autor", rs.getString("autor"));
                    o.put("genero", rs.getString("genero"));
                    o.put("portada", rs.getString("portada_ruta"));
                    lista.add(o);
                }
            }
        }

        return lista;
    }

    /** Autores (con al menos una obra publicada) cuyo nombre o @usuario coincide con el texto. */
    public List<Map<String, Object>> sugerirAutores(String texto, int limite) throws SQLException {

        String t = normalizar(texto);
        List<Map<String, Object>> lista = new ArrayList<>();
        if (t.isEmpty()) return lista;

        String nombre = sinTildes("u.nombre_publico");
        String usuario = "lower(COALESCE(u.nombre_usuario, ''))";
        String sql =
                "SELECT u.nombre_publico, u.nombre_usuario, p.avatar_ruta, COUNT(o.id) AS obras, " +
                "  CASE WHEN " + nombre + " LIKE ? OR " + usuario + " LIKE ? THEN 0 " +
                "       WHEN " + nombre + " LIKE ? THEN 1 ELSE 2 END AS rango " +
                "FROM usuario u " +
                "JOIN obra o ON o.autor_id = u.id AND o.estado = 'publicada' " +
                "LEFT JOIN perfil_usuario p ON p.usuario_id = u.id " +
                "WHERE u.estado_cuenta = 'activa' " +
                "  AND (" + nombre + " LIKE ? OR " + usuario + " LIKE ?) " +
                "GROUP BY u.id, u.nombre_publico, u.nombre_usuario, p.avatar_ruta " +
                "ORDER BY rango, obras DESC, u.nombre_publico " +
                "LIMIT ?";

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, t + "%");
            ps.setString(2, t + "%");
            ps.setString(3, "% " + t + "%");
            ps.setString(4, "%" + t + "%");
            ps.setString(5, "%" + t + "%");
            ps.setInt(6, limite);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> a = new LinkedHashMap<>();
                    a.put("nombre", rs.getString("nombre_publico"));
                    a.put("usuario", rs.getString("nombre_usuario"));
                    a.put("avatar", rs.getString("avatar_ruta"));
                    a.put("obras", rs.getLong("obras"));
                    lista.add(a);
                }
            }
        }

        return lista;
    }
}