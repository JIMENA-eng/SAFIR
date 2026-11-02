package com.safir.dao;

import com.safir.config.ConexionBD;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class BilleteraDAO {

    /** Texto legible de cada tipo de movimiento del libro. */
    public static final Map<String, String> ETIQUETAS = Map.of(
            "bono_bienvenida",  "Regalo de bienvenida",
            "compra_paquete",   "Compra de paquete de monedas",
            "compra_capitulo",  "Capítulo desbloqueado",
            "venta_capitulo",   "Venta de capítulo",
            "regalo_enviado",   "Regalo enviado",
            "regalo_recibido",  "Regalo recibido",
            "compra_nivel",     "Nivel de autor comprado",
            "retiro",           "Retiro solicitado",
            "reembolso_retiro", "Devolución por retiro rechazado",
            "reembolso_cuenta", "Reembolso por eliminar la cuenta");

    public long obtenerSaldo(long usuarioId) throws SQLException {
        String sql = "SELECT saldo_monedas FROM billetera WHERE usuario_id = ?";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong(1) : 0L;
            }
        }
    }

    /** Descuento vigente: claves "porcentaje" y "venceEn"; null si no tiene. */
    public Map<String, Object> obtenerDescuento(long usuarioId) throws SQLException {
        String sql = "SELECT porcentaje, vence_en FROM promocion_usuario "
                + "WHERE usuario_id = ? AND now() >= inicia_en AND now() < vence_en "
                + "ORDER BY porcentaje DESC LIMIT 1";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String, Object> d = new HashMap<>();
                d.put("porcentaje", rs.getInt("porcentaje"));
                d.put("venceEn", rs.getTimestamp("vence_en"));
                return d;
            }
        }
    }

    /** Últimos movimientos del libro: creadoEn, tipo, monedas, saldo. */
    public List<Map<String, Object>> listarMovimientos(long usuarioId, int limite)
            throws SQLException {
        String sql = "SELECT creado_en, tipo, monedas, saldo_posterior "
                + "FROM movimiento_moneda WHERE usuario_id = ? "
                + "ORDER BY creado_en DESC, id DESC LIMIT ?";

        List<Map<String, Object>> lista = new ArrayList<>();

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            ps.setInt(2, limite);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("creadoEn", rs.getTimestamp("creado_en"));
                    m.put("tipo", rs.getString("tipo"));
                    m.put("monedas", rs.getLong("monedas"));
                    m.put("saldo", rs.getLong("saldo_posterior"));
                    lista.add(m);
                }
            }
        }
        return lista;
    }
}