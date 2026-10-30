package com.safir.dao;

import com.safir.config.ConexionBD;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class ValoracionDAO {

    public boolean guardar(
            long usuarioId,
            long obraId,
            int puntaje,
            String resena) throws SQLException {

        if (puntaje < 1 || puntaje > 5) {
            throw new IllegalArgumentException(
                "El puntaje debe estar entre 1 y 5."
            );
        }

        String sql = """
            INSERT INTO valoracion
                (usuario_id, obra_id, puntaje, resena)
            SELECT ?, o.id, ?, ?
            FROM obra o
            WHERE o.id = ?
              AND o.estado = 'publicada'
            ON CONFLICT (usuario_id, obra_id)
            DO UPDATE SET
                puntaje = EXCLUDED.puntaje,
                resena = EXCLUDED.resena,
                actualizado_en = now()
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);
            ps.setInt(2, puntaje);
            ps.setString(
                3,
                resena == null || resena.isBlank()
                    ? null
                    : resena.trim()
            );
            ps.setLong(4, obraId);

            return ps.executeUpdate() == 1;
        }
    }
}