package com.safir.dao;

import com.safir.config.ConexionBD;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class RetiroDAO {

    /** Valor por moneda y comisión vigentes (tabla configuracion). */
    public Map<String, Object> parametros() throws SQLException {
        String sql = "SELECT cfg('valor_moneda_retiro_usd') AS valor, "
                + "cfg('retiro_comision_pct') AS comision";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            rs.next();
            Map<String, Object> m = new HashMap<>();
            m.put("valorMoneda", rs.getBigDecimal("valor"));
            m.put("comisionPct", rs.getBigDecimal("comision"));
            return m;
        }
    }

    /**
     * Crea la solicitud y descuenta las monedas de inmediato (lo hace el SQL).
     * Las reglas (nivel, saldo mínimo, monto) las valida solicitar_retiro.
     */
    public long solicitar(long autorId, long monedas, String metodo, String datosPago)
            throws SQLException {

        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                long id;

                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT solicitar_retiro(?, ?, ?)")) {
                    ps.setLong(1, autorId);
                    ps.setLong(2, monedas);
                    ps.setString(3, metodo);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        id = rs.getLong(1);
                    }
                }

                try (PreparedStatement ps = c.prepareStatement(
                        "UPDATE retiro SET datos_pago = ? WHERE id = ?")) {
                    ps.setString(1, datosPago);
                    ps.setLong(2, id);
                    ps.executeUpdate();
                }

                c.commit();
                return id;

            } catch (SQLException | RuntimeException e) {
                try { c.rollback(); } catch (SQLException ignorada) { e.addSuppressed(ignorada); }
                throw e;
            }
        }
    }

    /** Últimos retiros del autor. */
    public List<Map<String, Object>> listarDelAutor(long autorId) throws SQLException {
        String sql = "SELECT id, creado_en, monedas_solicitadas, monto_usd, metodo_pago, "
                + "estado, motivo_rechazo FROM retiro WHERE autor_id = ? "
                + "ORDER BY creado_en DESC, id DESC LIMIT 20";

        List<Map<String, Object>> lista = new ArrayList<>();

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, autorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("id", rs.getLong("id"));
                    m.put("creadoEn", rs.getTimestamp("creado_en"));
                    m.put("monedas", rs.getLong("monedas_solicitadas"));
                    m.put("montoUsd", rs.getBigDecimal("monto_usd"));
                    m.put("metodo", rs.getString("metodo_pago"));
                    m.put("estado", rs.getString("estado"));
                    m.put("motivo", rs.getString("motivo_rechazo"));
                    lista.add(m);
                }
            }
        }
        return lista;
    }

    /** Solicitudes pendientes de revisión, las más antiguas primero. */
    public List<Map<String, Object>> listarPendientes() throws SQLException {
        String sql = "SELECT r.id, r.creado_en, u.nombre_publico, COALESCE(u.correo, u.telefono) AS correo, an.nivel, "
                + "r.monedas_solicitadas, r.monedas_plataforma, r.monedas_autor, "
                + "r.valor_moneda_usd, r.monto_usd, r.metodo_pago, r.datos_pago "
                + "FROM retiro r JOIN usuario u ON u.id = r.autor_id "
                + "LEFT JOIN autor_nivel an ON an.autor_id = r.autor_id "
                + "WHERE r.estado = 'pendiente' ORDER BY r.creado_en, r.id";

        List<Map<String, Object>> lista = new ArrayList<>();

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("id", rs.getLong("id"));
                m.put("creadoEn", rs.getTimestamp("creado_en"));
                m.put("autor", rs.getString("nombre_publico"));
                m.put("correo", rs.getString("correo"));
                m.put("nivel", rs.getInt("nivel"));
                m.put("solicitadas", rs.getLong("monedas_solicitadas"));
                m.put("plataforma", rs.getLong("monedas_plataforma"));
                m.put("paraAutor", rs.getLong("monedas_autor"));
                m.put("valorMoneda", rs.getBigDecimal("valor_moneda_usd"));
                m.put("montoUsd", rs.getBigDecimal("monto_usd"));
                m.put("metodo", rs.getString("metodo_pago"));
                m.put("datos", rs.getString("datos_pago"));
                lista.add(m);
            }
        }
        return lista;
    }

    /**
     * Aprueba (queda "pagado") o rechaza (exige motivo y devuelve TODAS las monedas).
     * Devuelve "pagado" o "rechazado". El SQL verifica que quien resuelve sea
     * moderador o administrador.
     */
    public String resolver(long retiroId, long moderadorId, boolean aprobar,
                           String referenciaPago, String motivo) throws SQLException {
        String sql = "SELECT resolver_retiro(?, ?, ?, ?, ?)";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, retiroId);
            ps.setLong(2, moderadorId);
            ps.setBoolean(3, aprobar);
            ps.setString(4, referenciaPago);
            ps.setString(5, motivo);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getString(1);
            }
        }
    }
}