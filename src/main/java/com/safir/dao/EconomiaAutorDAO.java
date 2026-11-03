package com.safir.dao;

import com.safir.config.ConexionBD;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public class EconomiaAutorDAO {

    // ------------------------------------------------------------------
    // Regalos (fase 3)
    // ------------------------------------------------------------------

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

    // ------------------------------------------------------------------
    // Niveles y economía del autor (fase 5)
    // ------------------------------------------------------------------

    /**
     * Resumen económico del autor, o null si no tiene registro de autor.
     * Claves: nivel, maximo, costo, saldo, recibido, nivelRetiro, saldoRetiro.
     */
    public Map<String, Object> obtenerEconomia(long autorId) throws SQLException {
        String sql = "SELECT an.nivel, "
                + "COALESCE(b.saldo_monedas, 0) AS saldo, "
                + "COALESCE(b.total_recibido, 0) AS recibido, "
                + "cfg('costo_nivel_monedas')::BIGINT AS costo, "
                + "cfg('nivel_maximo')::INT AS maximo, "
                + "cfg('retiro_nivel_minimo')::INT AS nivel_retiro, "
                + "cfg('retiro_minimo_monedas')::BIGINT AS saldo_retiro "
                + "FROM autor_nivel an "
                + "LEFT JOIN billetera b ON b.usuario_id = an.autor_id "
                + "WHERE an.autor_id = ?";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, autorId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;

                Map<String, Object> m = new HashMap<>();
                m.put("nivel", rs.getInt("nivel"));
                m.put("maximo", rs.getInt("maximo"));
                m.put("costo", rs.getLong("costo"));
                m.put("saldo", rs.getLong("saldo"));
                m.put("recibido", rs.getLong("recibido"));
                m.put("nivelRetiro", rs.getInt("nivel_retiro"));
                m.put("saldoRetiro", rs.getLong("saldo_retiro"));
                return m;
            }
        }
    }

    /** Compra el siguiente nivel; devuelve el nivel nuevo. */
    public int comprarNivel(long autorId) throws SQLException {
        String sql = "SELECT comprar_nivel(?)";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, autorId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }
}