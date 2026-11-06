package com.safir.dao;

import com.safir.config.ConexionBD;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ObraEdicionDAO {

    public List<Map<String, Object>> listarGeneros() throws SQLException {
        List<Map<String, Object>> generos = new ArrayList<>();

        String sql = """
            SELECT id, nombre
            FROM genero
            ORDER BY nombre
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> genero = new LinkedHashMap<>();
                genero.put("id", rs.getInt("id"));
                genero.put("nombre", rs.getString("nombre"));
                generos.add(genero);
            }
        }

        return generos;
    }

    public Map<String, Object> obtenerPropia(
            long obraId, long autorId) throws SQLException {

        String sql = """
            SELECT id, titulo, descripcion, genero_id, clasificacion,
                   bloqueo_activo, portada_ruta
            FROM obra
            WHERE id = ? AND autor_id = ?
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setLong(2, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                Map<String, Object> obra = new LinkedHashMap<>();
                obra.put("id", rs.getLong("id"));
                obra.put("titulo", rs.getString("titulo"));
                obra.put("descripcion", rs.getString("descripcion"));
                obra.put("generoId", rs.getInt("genero_id"));
                obra.put("clasificacion",
                         rs.getString("clasificacion"));
                obra.put("bloqueoActivo", rs.getBoolean("bloqueo_activo"));
                obra.put("portadaRuta", rs.getString("portada_ruta"));

                return obra;
            }
        }
    }

    public long crear(
            long autorId,
            String titulo,
            String descripcion,
            int generoId,
            String clasificacion) throws SQLException {

        String sql = """
            INSERT INTO obra
                (autor_id, genero_id, titulo, descripcion,
                 clasificacion, estado)
            VALUES (?, ?, ?, ?, ?, 'borrador')
            RETURNING id
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, autorId);
            ps.setInt(2, generoId);
            ps.setString(3, titulo);
            ps.setString(4, descripcion);
            ps.setString(5, clasificacion);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }

        throw new SQLException("No se pudo crear la obra.");
    }

    public boolean actualizarPropia(
            long obraId,
            long autorId,
            String titulo,
            String descripcion,
            int generoId,
            String clasificacion) throws SQLException {

        String sql = """
            UPDATE obra
            SET titulo = ?,
                descripcion = ?,
                genero_id = ?,
                clasificacion = ?
            WHERE id = ? AND autor_id = ?
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, titulo);
            ps.setString(2, descripcion);
            ps.setInt(3, generoId);
            ps.setString(4, clasificacion);
            ps.setLong(5, obraId);
            ps.setLong(6, autorId);

            return ps.executeUpdate() == 1;
        }
    }

    public boolean existeGenero(int generoId) throws SQLException {
        String sql = "SELECT 1 FROM genero WHERE id = ?";

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, generoId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
    /** Guarda la ruta de la portada (ej. "obra/12-uuid.jpg") de una obra propia. */
    public boolean actualizarPortada(long obraId, long autorId, String portadaRuta)
            throws SQLException {
        String sql = "UPDATE obra SET portada_ruta = ? WHERE id = ? AND autor_id = ?";

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, portadaRuta);
            ps.setLong(2, obraId);
            ps.setLong(3, autorId);
            return ps.executeUpdate() == 1;
        }
    }

    public boolean actualizarBloqueo(long obraId, long autorId, boolean activo)
        throws SQLException {
    String sql = "UPDATE obra SET bloqueo_activo = ? WHERE id = ? AND autor_id = ?";

    try (Connection con = ConexionBD.conectar();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setBoolean(1, activo);
        ps.setLong(2, obraId);
        ps.setLong(3, autorId);
        return ps.executeUpdate() == 1;
    }
}

    /**
     * Publica la obra. Solo si es del autor, está en borrador y tiene al
     * menos un capítulo publicado. publicada_en es obligatorio al publicar
     * (CHECK ck_obra_publicada_en) y se conserva si ya existía.
     */
    public boolean publicar(long obraId, long autorId) throws SQLException {
        String sql = """
            UPDATE obra
            SET estado = 'publicada',
                publicada_en = COALESCE(publicada_en, now())
            WHERE id = ?
              AND autor_id = ?
              AND estado = 'borrador'
              AND EXISTS (
                  SELECT 1 FROM capitulo c
                  WHERE c.obra_id = obra.id
                    AND c.estado = 'publicado')
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setLong(2, autorId);

            return ps.executeUpdate() == 1;
        }
    }

    /** Quita la obra del catálogo (vuelve a borrador). */
    public boolean volverABorrador(long obraId, long autorId)
            throws SQLException {

        String sql = """
            UPDATE obra
            SET estado = 'borrador'
            WHERE id = ?
              AND autor_id = ?
              AND estado = 'publicada'
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setLong(2, autorId);

            return ps.executeUpdate() == 1;
        }
    }

    /** Motivo por el que la obra no se puede publicar, o null si cumple todo. */
    public String motivoNoPublicable(long obraId, long autorId)
            throws SQLException {

        String sql = """
            SELECT o.estado,
                   (SELECT COUNT(*) FROM capitulo c
                    WHERE c.obra_id = o.id
                      AND c.estado = 'publicado') AS publicados
            FROM obra o
            WHERE o.id = ? AND o.autor_id = ?
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setLong(2, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return "no_existe";
                }
                if (!"borrador".equals(rs.getString("estado"))) {
                    return "no_borrador";
                }
                if (rs.getLong("publicados") == 0) {
                    return "sin_capitulos";
                }
                return null;
            }
        }
    }
}