package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.seguridad.PasswordUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CuentaDAO {

    /** Confirma la contraseña de una cuenta activa. */
    public boolean verificarClave(long usuarioId, String clave) throws SQLException {
        if (clave == null || clave.isEmpty()) return false;

        String sql = "SELECT contrasena_hash FROM usuario "
                + "WHERE id = ? AND estado_cuenta = 'activa'";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return false;
                String hash = rs.getString(1);
                return hash != null && PasswordUtil.verificar(clave, hash);
            }
        }
    }

    /**
     * Calcula, sin eliminar nada, cuánto se reembolsaría y cuántas monedas se perderían.
     * Ejecuta eliminar_cuenta() dentro de una transacción que SIEMPRE se revierte, así el
     * cálculo es exactamente el mismo que el de la eliminación real.
     *
     * Claves: saldo, reembolsables, perdidas (long); brutoUsd, comisionUsd, montoUsd,
     * comisionPct (BigDecimal). Lanza SQLException P0001 si no se puede eliminar
     * (por ejemplo, tiene un retiro pendiente).
     */
    public Map<String, Object> vistaPrevia(long usuarioId) throws SQLException {
        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                Map<String, Object> m = new HashMap<>();
                long saldo = 0;

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT saldo_monedas FROM billetera WHERE usuario_id = ?")) {
                    ps.setLong(1, usuarioId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) saldo = rs.getLong(1);
                    }
                }

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT eliminar_cuenta(?, TRUE)")) {
                    ps.setLong(1, usuarioId);
                    ps.executeQuery().close();
                }

                long reembolsables = 0;
                BigDecimal bruto = BigDecimal.ZERO;
                BigDecimal comision = BigDecimal.ZERO;
                BigDecimal monto = BigDecimal.ZERO;
                BigDecimal pct = BigDecimal.ZERO;

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT monedas, valor_bruto_usd, comision_pct, comision_usd, monto_usd "
                        + "FROM reembolso_cuenta WHERE usuario_id = ? "
                        + "ORDER BY id DESC LIMIT 1")) {
                    ps.setLong(1, usuarioId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            reembolsables = rs.getLong("monedas");
                            bruto = rs.getBigDecimal("valor_bruto_usd");
                            pct = rs.getBigDecimal("comision_pct");
                            comision = rs.getBigDecimal("comision_usd");
                            monto = rs.getBigDecimal("monto_usd");
                        }
                    }
                }

                if (pct.signum() == 0) {
                    try (PreparedStatement ps = c.prepareStatement(
                            "SELECT cfg('comision_reembolso_pct')");
                         ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getBigDecimal(1) != null) pct = rs.getBigDecimal(1);
                    }
                }

                m.put("saldo", saldo);
                m.put("reembolsables", reembolsables);
                m.put("perdidas", saldo - reembolsables);
                m.put("brutoUsd", bruto);
                m.put("comisionUsd", comision);
                m.put("montoUsd", monto);
                m.put("comisionPct", pct);
                return m;

            } finally {
                try { c.rollback(); } catch (SQLException ignorada) { }
            }
        }
    }

    /**
     * Elimina la cuenta: el SQL deja el saldo en cero, marca la cuenta como eliminada,
     * cierra sesiones y registra el reembolso pendiente. Devuelve los dólares a devolver.
     * metodo y datos (destino del reembolso) pueden ser null si no hay reembolso.
     */
    public BigDecimal eliminar(long usuarioId, boolean aceptaPerder,
                               String metodo, String datos) throws SQLException {
        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                BigDecimal monto;

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT eliminar_cuenta(?, ?)")) {
                    ps.setLong(1, usuarioId);
                    ps.setBoolean(2, aceptaPerder);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        monto = rs.getBigDecimal(1);
                    }
                }

                if (metodo != null) {
                    try (PreparedStatement ps = c.prepareStatement(
                            "UPDATE reembolso_cuenta SET metodo_pago = ?, datos_pago = ? "
                            + "WHERE usuario_id = ?")) {
                        ps.setString(1, metodo);
                        ps.setString(2, datos);
                        ps.setLong(3, usuarioId);
                        ps.executeUpdate();
                    }
                }

                c.commit();
                return monto;

            } catch (SQLException | RuntimeException e) {
                try { c.rollback(); } catch (SQLException ignorada) { e.addSuppressed(ignorada); }
                throw e;
            }
        }
    }

    /** Reembolsos por eliminación de cuenta que aún hay que pagar. */
    public List<Map<String, Object>> listarReembolsosPendientes() throws SQLException {
        String sql = "SELECT r.id, r.creado_en, u.nombre_publico, u.correo, r.monedas, "
                + "r.valor_bruto_usd, r.comision_pct, r.comision_usd, r.monto_usd, "
                + "r.monedas_perdidas, r.metodo_pago, r.datos_pago "
                + "FROM reembolso_cuenta r JOIN usuario u ON u.id = r.usuario_id "
                + "WHERE r.estado = 'pendiente' ORDER BY r.creado_en, r.id";

        List<Map<String, Object>> lista = new ArrayList<>();

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("id", rs.getLong("id"));
                m.put("creadoEn", rs.getTimestamp("creado_en"));
                m.put("usuario", rs.getString("nombre_publico"));
                m.put("correo", rs.getString("correo"));
                m.put("monedas", rs.getLong("monedas"));
                m.put("brutoUsd", rs.getBigDecimal("valor_bruto_usd"));
                m.put("comisionPct", rs.getBigDecimal("comision_pct"));
                m.put("comisionUsd", rs.getBigDecimal("comision_usd"));
                m.put("montoUsd", rs.getBigDecimal("monto_usd"));
                m.put("perdidas", rs.getLong("monedas_perdidas"));
                m.put("metodo", rs.getString("metodo_pago"));
                m.put("datos", rs.getString("datos_pago"));
                lista.add(m);
            }
        }
        return lista;
    }

    /** Marca el reembolso como pagado (después de haber transferido el dinero). */
    public boolean marcarReembolsoPagado(long reembolsoId, String referencia) throws SQLException {
        String sql = "UPDATE reembolso_cuenta SET estado = 'pagado', referencia_pago = ?, "
                + "resuelto_en = now() WHERE id = ? AND estado = 'pendiente'";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, referencia);
            ps.setLong(2, reembolsoId);
            return ps.executeUpdate() == 1;
        }
    }
}