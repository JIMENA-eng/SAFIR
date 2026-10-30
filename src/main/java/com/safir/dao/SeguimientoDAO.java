package com.safir.dao;

import com.safir.config.ConexionBD;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class SeguimientoDAO {

    public boolean seguir(long usuarioId, long obraId)
            throws SQLException {

        String sql = """
            INSERT INTO seguimiento_obra (usuario_id, obra_id)
            SELECT ?, o.id
            FROM obra o
            WHERE o.id = ?
              AND o.estado = 'publicada'
            ON CONFLICT (usuario_id, obra_id) DO NOTHING
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);
            ps.setLong(2, obraId);

            return ps.executeUpdate() == 1;
        }
    }

    public boolean dejarDeSeguir(long usuarioId, long obraId)
            throws SQLException {

        String sql = """
            DELETE FROM seguimiento_obra
            WHERE usuario_id = ?
              AND obra_id = ?
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);
            ps.setLong(2, obraId);

            return ps.executeUpdate() == 1;
        }
    }

    public boolean cambiarAvisos(
            long usuarioId,
            long obraId,
            boolean avisar) throws SQLException {

        String sql = """
            UPDATE seguimiento_obra
            SET avisar = ?
            WHERE usuario_id = ?
              AND obra_id = ?
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setBoolean(1, avisar);
            ps.setLong(2, usuarioId);
            ps.setLong(3, obraId);

            return ps.executeUpdate() == 1;
        }
    }
}