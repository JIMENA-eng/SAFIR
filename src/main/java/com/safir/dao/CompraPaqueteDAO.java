package com.safir.dao;

import com.safir.config.ConexionBD;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CompraPaqueteDAO {

    private static final String SELECT_COMPRA =
            "SELECT id, usuario_id, monedas, precio_pagado_usd, monto_pen, "
            + "estado, pasarela, referencia_pago FROM compra_paquete ";

    /** Paquetes activos con el precio ya rebajado por el descuento vigente. */
    public List<Map<String, Object>> listarPaquetes(long usuarioId) throws SQLException {
        String sql = "SELECT p.id, p.monedas, p.precio_usd, "
                + "ROUND(p.precio_usd * (100 - descuento_vigente(?)) / 100.0, 2) AS precio_final, "
                + "descuento_vigente(?) AS descuento "
                + "FROM paquete_monedas p WHERE p.activo ORDER BY p.monedas";

        List<Map<String, Object>> lista = new ArrayList<>();

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            ps.setLong(2, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> p = new HashMap<>();
                    p.put("id", rs.getInt("id"));
                    p.put("monedas", rs.getInt("monedas"));
                    p.put("precioLista", rs.getBigDecimal("precio_usd"));
                    p.put("precioFinal", rs.getBigDecimal("precio_final"));
                    p.put("descuento", rs.getInt("descuento"));
                    lista.add(p);
                }
            }
        }
        return lista;
    }

    /** Crea la compra en estado "pendiente" y devuelve su id. */
    public long crear(long usuarioId, int paqueteId, String pasarela) throws SQLException {
        String sql = "SELECT crear_compra_paquete(?, ?, ?, ?)";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            ps.setShort(2, (short) paqueteId);
            ps.setString(3, pasarela);
            ps.setNull(4, Types.VARCHAR);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }

    /** Compra del usuario (null si no existe o es de otro usuario). */
    public Map<String, Object> obtenerPropia(long compraId, long usuarioId) throws SQLException {
        String sql = SELECT_COMPRA + "WHERE id = ? AND usuario_id = ?";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, compraId);
            ps.setLong(2, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapear(rs) : null;
            }
        }
    }

    public Map<String, Object> buscarPorReferencia(String pasarela, String referencia,
                                                   long usuarioId) throws SQLException {
        String sql = SELECT_COMPRA
                + "WHERE pasarela = ? AND referencia_pago = ? AND usuario_id = ?";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, pasarela);
            ps.setString(2, referencia);
            ps.setLong(3, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapear(rs) : null;
            }
        }
    }

    /**
     * Guarda la referencia de pago (id de orden de PayPal o código de operación de Yape).
     * Si otra compra ya usa la misma referencia lanza SQLException 23505.
     */
    public boolean guardarReferencia(long compraId, long usuarioId, String pasarela,
                                     String referencia) throws SQLException {
        String sql = "UPDATE compra_paquete SET referencia_pago = ? "
                + "WHERE id = ? AND usuario_id = ? AND pasarela = ? AND estado = 'pendiente'";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, referencia);
            ps.setLong(2, compraId);
            ps.setLong(3, usuarioId);
            ps.setString(4, pasarela);
            return ps.executeUpdate() == 1;
        }
    }

    public void guardarMontoPen(long compraId, BigDecimal montoPen) throws SQLException {
        String sql = "UPDATE compra_paquete SET monto_pen = ? WHERE id = ?";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBigDecimal(1, montoPen);
            ps.setLong(2, compraId);
            ps.executeUpdate();
        }
    }

    /** Soles por dólar (tabla configuracion); null si aún no se configuró. */
    public BigDecimal tipoCambioPen() throws SQLException {
        String sql = "SELECT cfg('tipo_cambio_pen_usd')";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getBigDecimal(1) : null;
        }
    }

    public boolean marcarFallida(long compraId) throws SQLException {
        String sql = "UPDATE compra_paquete SET estado = 'fallida' "
                + "WHERE id = ? AND estado = 'pendiente'";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, compraId);
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * La pasarela confirmó el pago: acredita las monedas y avisa al usuario.
     * Devuelve el saldo resultante. Lanza SQLException (P0001) si la compra
     * no está pendiente.
     */
    public long confirmar(long compraId) throws SQLException {
        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                long saldo;

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT confirmar_compra_paquete(?)")) {
                    ps.setLong(1, compraId);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        saldo = rs.getLong(1);
                    }
                }

                try (PreparedStatement ps = c.prepareStatement(
                        "INSERT INTO notificacion (usuario_id, tipo, mensaje) "
                        + "SELECT usuario_id, 'sistema', "
                        + "'Tu compra de ' || monedas || ' monedas fue confirmada.' "
                        + "FROM compra_paquete WHERE id = ?")) {
                    ps.setLong(1, compraId);
                    ps.executeUpdate();
                }

                c.commit();
                return saldo;

            } catch (SQLException | RuntimeException e) {
                try { c.rollback(); } catch (SQLException ignorada) { e.addSuppressed(ignorada); }
                throw e;
            }
        }
    }

    /** Pagos con Yape que ya tienen código de operación y esperan revisión. */
    public List<Map<String, Object>> listarYapePendientes() throws SQLException {
        String sql = "SELECT cp.id, u.nombre_publico, u.correo, cp.monedas, "
                + "cp.precio_pagado_usd, cp.monto_pen, cp.referencia_pago, cp.creado_en "
                + "FROM compra_paquete cp JOIN usuario u ON u.id = cp.usuario_id "
                + "WHERE cp.pasarela = 'yape' AND cp.estado = 'pendiente' "
                + "AND cp.referencia_pago IS NOT NULL ORDER BY cp.creado_en";

        List<Map<String, Object>> lista = new ArrayList<>();

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("id", rs.getLong("id"));
                m.put("usuario", rs.getString("nombre_publico"));
                m.put("correo", rs.getString("correo"));
                m.put("monedas", rs.getInt("monedas"));
                m.put("precioUsd", rs.getBigDecimal("precio_pagado_usd"));
                m.put("montoPen", rs.getBigDecimal("monto_pen"));
                m.put("referencia", rs.getString("referencia_pago"));
                m.put("creadoEn", rs.getTimestamp("creado_en"));
                lista.add(m);
            }
        }
        return lista;
    }

    private Map<String, Object> mapear(ResultSet rs) throws SQLException {
        Map<String, Object> m = new HashMap<>();
        m.put("id", rs.getLong("id"));
        m.put("usuarioId", rs.getLong("usuario_id"));
        m.put("monedas", rs.getInt("monedas"));
        m.put("precioPagado", rs.getBigDecimal("precio_pagado_usd"));
        m.put("montoPen", rs.getBigDecimal("monto_pen"));
        m.put("estado", rs.getString("estado"));
        m.put("pasarela", rs.getString("pasarela"));
        m.put("referencia", rs.getString("referencia_pago"));
        return m;
    }
}