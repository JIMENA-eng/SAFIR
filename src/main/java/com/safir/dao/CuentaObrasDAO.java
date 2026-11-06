package com.safir.dao;

import com.safir.config.ConexionBD;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Datos de la sección "Mis obras y listas" de Mi cuenta.
 * Devuelve filas simples (String[]) para pintarlas directo en cuenta.jsp.
 */
public class CuentaObrasDAO {

    /**
     * Obras del autor en un estado dado ('publicada' o 'borrador').
     * Fila: {id, titulo, genero, avance, lecturas, promedio, capPublicados, capBorrador, portadaRuta}
     */
    public List<String[]> listarObras(long autorId, String estado) throws SQLException {
        String sql =
            "SELECT o.id, o.titulo, g.nombre AS genero, o.avance, o.portada_ruta, " +
            "       COALESCE(e.total_lecturas, 0) AS lecturas, " +
            "       COALESCE(e.promedio, 0)       AS promedio, " +
            "       (SELECT COUNT(*) FROM capitulo c WHERE c.obra_id = o.id AND c.estado = 'publicado') AS cap_pub, " +
            "       (SELECT COUNT(*) FROM capitulo c WHERE c.obra_id = o.id AND c.estado = 'borrador')  AS cap_bor " +
            "FROM obra o " +
            "JOIN genero g ON g.id = o.genero_id " +
            "LEFT JOIN obra_estadistica e ON e.obra_id = o.id " +
            "WHERE o.autor_id = ? AND o.estado = ? " +
            "ORDER BY o.actualizado_en DESC, o.id DESC";

        List<String[]> filas = new ArrayList<>();
        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, autorId);
            ps.setString(2, estado);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    filas.add(new String[]{
                        String.valueOf(rs.getLong("id")),
                        rs.getString("titulo"),
                        rs.getString("genero"),
                        rs.getString("avance"),
                        String.valueOf(rs.getLong("lecturas")),
                        rs.getBigDecimal("promedio").toPlainString(),
                        String.valueOf(rs.getLong("cap_pub")),
                        String.valueOf(rs.getLong("cap_bor")),
                        rs.getString("portada_ruta")
                    });
                }
            }
        }
        return filas;
    }

    /**
     * Listas (colecciones) creadas por el usuario.
     * Fila: {id, nombre, descripcion, publica("true"/"false"), totalObras}
     */
    public List<String[]> listarListas(long usuarioId) throws SQLException {
        String sql =
            "SELECT k.id, k.nombre, COALESCE(k.descripcion, '') AS descripcion, k.publica, " +
            "       (SELECT COUNT(*) FROM coleccion_obra co WHERE co.coleccion_id = k.id) AS total " +
            "FROM coleccion k " +
            "WHERE k.usuario_id = ? " +
            "ORDER BY k.creado_en DESC, k.id DESC";

        List<String[]> filas = new ArrayList<>();
        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    filas.add(new String[]{
                        String.valueOf(rs.getLong("id")),
                        rs.getString("nombre"),
                        rs.getString("descripcion"),
                        String.valueOf(rs.getBoolean("publica")),
                        String.valueOf(rs.getLong("total"))
                    });
                }
            }
        }
        return filas;
    }
}