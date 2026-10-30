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
}