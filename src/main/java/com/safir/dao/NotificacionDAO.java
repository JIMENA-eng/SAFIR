package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.Notificacion;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class NotificacionDAO {

    public List<Notificacion> listar(long usuarioId)
            throws SQLException {

        List<Notificacion> lista = new ArrayList<>();

        String sql = """
            SELECT id, tipo, mensaje, actor_id, obra_id,
                   capitulo_id, comentario_id, creado_en, leida_en
            FROM notificacion
            WHERE usuario_id = ?
            ORDER BY creado_en DESC
            LIMIT 100
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Notificacion n = new Notificacion();

                    n.setId(rs.getLong("id"));
                    n.setTipo(rs.getString("tipo"));
                    n.setMensaje(rs.getString("mensaje"));
                    n.setActorId(nullableLong(rs, "actor_id"));
                    n.setObraId(nullableLong(rs, "obra_id"));
                    n.setCapituloId(nullableLong(rs, "capitulo_id"));
                    n.setComentarioId(nullableLong(rs, "comentario_id"));

                    Timestamp creado = rs.getTimestamp("creado_en");
                    if (creado != null) {
                        n.setCreadoEn(creado.toLocalDateTime());
                    }

                    Timestamp leido = rs.getTimestamp("leida_en");
                    if (leido != null) {
                        n.setLeidaEn(leido.toLocalDateTime());
                    }

                    lista.add(n);
                }
            }
        }

        return lista;
    }

    public long contarNoLeidas(long usuarioId)
            throws SQLException {

        String sql = """
            SELECT COUNT(*)
            FROM notificacion
            WHERE usuario_id = ?
              AND leida_en IS NULL
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
        }

        return 0;
    }

    public boolean marcarLeida(long usuarioId, long notificacionId)
            throws SQLException {

        String sql = """
            UPDATE notificacion
            SET leida_en = now()
            WHERE id = ?
              AND usuario_id = ?
              AND leida_en IS NULL
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, notificacionId);
            ps.setLong(2, usuarioId);

            return ps.executeUpdate() == 1;
        }
    }

    public int marcarTodasLeidas(long usuarioId)
            throws SQLException {

        String sql = """
            UPDATE notificacion
            SET leida_en = now()
            WHERE usuario_id = ?
              AND leida_en IS NULL
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);
            return ps.executeUpdate();
        }
    }

    private Long nullableLong(ResultSet rs, String columna)
            throws SQLException {

        long valor = rs.getLong(columna);
        return rs.wasNull() ? null : valor;
    }

    // =================================================================
    // TAREA 5: contadores y vista previa para los iconos del encabezado
    // =================================================================

    /**
     * Tipos que se muestran en el icono de MENSAJES (el sobre).
     * Todo lo demás (nuevo capítulo, nuevo seguidor, importación...) va
     * al icono de NOTIFICACIONES (la campana).
     */
    public static final String TIPOS_MENSAJES =
            "'sistema', 'reporte_resuelto', 'respuesta_comentario'";

    public static final String CATEGORIA_MENSAJES = "mensajes";
    public static final String CATEGORIA_ACTIVIDAD = "actividad";

    public static String categoriaDe(String tipo) {
        if ("sistema".equals(tipo) || "reporte_resuelto".equals(tipo)
                || "respuesta_comentario".equals(tipo)) {
            return CATEGORIA_MENSAJES;
        }
        return CATEGORIA_ACTIVIDAD;
    }

    public static String textoTipo(String tipo) {
        if (tipo == null) return "Aviso";
        switch (tipo) {
            case "nuevo_capitulo":       return "Nuevo cap\u00edtulo";
            case "respuesta_comentario": return "Respuesta a tu comentario";
            case "nuevo_seguidor":       return "Nuevo seguidor";
            case "reporte_resuelto":     return "Reporte resuelto";
            case "importacion_lista":    return "Importaci\u00f3n lista";
            case "sistema":              return "Mensaje del sistema";
            default:                     return tipo.replace('_', ' ');
        }
    }

    /** No leídas separadas: [0] = mensajes, [1] = actividad. */
    public long[] contarNoLeidasPorCategoria(long usuarioId)
            throws SQLException {

        String sql =
                "SELECT COUNT(*) FILTER (WHERE tipo IN (" + TIPOS_MENSAJES + ")) AS mensajes, " +
                "       COUNT(*) FILTER (WHERE tipo NOT IN (" + TIPOS_MENSAJES + ")) AS actividad " +
                "FROM notificacion " +
                "WHERE usuario_id = ? AND leida_en IS NULL";

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new long[] { rs.getLong("mensajes"), rs.getLong("actividad") };
                }
            }
        }

        return new long[] { 0, 0 };
    }

    /** Las más recientes de una categoría (primero las no leídas), para el desglose. */
    public List<Notificacion> listarRecientes(long usuarioId, String categoria, int limite)
            throws SQLException {

        String condicion = CATEGORIA_MENSAJES.equals(categoria)
                ? "tipo IN (" + TIPOS_MENSAJES + ")"
                : "tipo NOT IN (" + TIPOS_MENSAJES + ")";

        String sql =
                "SELECT id, tipo, mensaje, actor_id, obra_id, " +
                "       capitulo_id, comentario_id, creado_en, leida_en " +
                "FROM notificacion " +
                "WHERE usuario_id = ? AND " + condicion + " " +
                "ORDER BY (leida_en IS NULL) DESC, creado_en DESC " +
                "LIMIT ?";

        List<Notificacion> lista = new ArrayList<>();

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);
            ps.setInt(2, limite);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Notificacion n = new Notificacion();
                    n.setId(rs.getLong("id"));
                    n.setTipo(rs.getString("tipo"));
                    n.setMensaje(rs.getString("mensaje"));
                    n.setActorId(nullableLong(rs, "actor_id"));
                    n.setObraId(nullableLong(rs, "obra_id"));
                    n.setCapituloId(nullableLong(rs, "capitulo_id"));
                    n.setComentarioId(nullableLong(rs, "comentario_id"));
                    Timestamp creado = rs.getTimestamp("creado_en");
                    if (creado != null) n.setCreadoEn(creado.toLocalDateTime());
                    Timestamp leido = rs.getTimestamp("leida_en");
                    if (leido != null) n.setLeidaEn(leido.toLocalDateTime());
                    lista.add(n);
                }
            }
        }

        return lista;
    }
}