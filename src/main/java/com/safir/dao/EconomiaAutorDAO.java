package com.safir.dao;

import com.safir.config.ConexionBD;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class EconomiaAutorDAO {

    /** Id del autor de una obra publicada, o null si no existe. */
    public Long obtenerAutorDeObra(long obraId) throws SQLException {
        String sql = "SELECT autor_id FROM obra WHERE id = ? AND estado = 'publicada'";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, obraId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong(1) : null;
            }
        }
    }

    /** Comisión de la plataforma sobre regalos (desde la tabla configuracion). */
    public int comisionRegaloPct() throws SQLException {
        String sql = "SELECT cfg('comision_regalo_pct')::INT";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    /** Descuenta al remitente y acredita al autor (el SQL aplica la comisión). */
    public void enviarRegalo(long remitenteId, long autorId, int monedas,
                             long obraId, String mensaje) throws SQLException {
        String sql = "SELECT enviar_regalo(?, ?, ?, ?, ?)";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, remitenteId);
            ps.setLong(2, autorId);
            ps.setInt(3, monedas);
            ps.setLong(4, obraId);
            ps.setString(5, mensaje);
            ps.executeQuery().close();
        }
    }
}