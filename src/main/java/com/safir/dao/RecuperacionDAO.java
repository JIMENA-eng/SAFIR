package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.seguridad.PasswordUtil;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.Map;

/**
 * Recuperación de contraseña con código de 6 dígitos (tabla recuperacion_contrasena).
 *
 * Flujo: crearCodigo -> confirmarCodigo -> restablecer.
 * El código se guarda como hash SHA-256; nunca en texto plano.
 * Tras restablecer, usuario.clave_restablecida_en bloquea otra recuperación
 * durante DIAS_BLOQUEO días.
 */
public class RecuperacionDAO {

    public static final int MINUTOS_VALIDEZ = 10;
    public static final int MAX_INTENTOS = 5;
    public static final int SEGUNDOS_ENTRE_ENVIOS = 60;
    public static final int DIAS_BLOQUEO = 30;

    /** SHA-256 en hexadecimal (64 caracteres). También lo usa VerificacionDAO. */
    public static String hashDeToken(String texto) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(
                    md.digest(texto.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    private static String hashCodigo(long usuarioId, String codigo) {
        return hashDeToken(usuarioId + ":" + codigo);
    }

    /** ID del usuario con ese correo si su cuenta está activa; si no, null. */
    public Long buscarUsuarioActivo(String correo) throws SQLException {
        String sql =
                "SELECT id FROM usuario " +
                "WHERE LOWER(correo) = LOWER(?) AND estado_cuenta = 'activa'";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, correo.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("id") : null;
            }
        }
    }

    /** Días que faltan para poder recuperar otra vez la contraseña; 0 si ya puede. */
    public int diasRestantesBloqueo(long usuarioId) throws SQLException {
        String sql =
                "SELECT CEIL(EXTRACT(EPOCH FROM (clave_restablecida_en + " +
                "(? * INTERVAL '1 day') - CURRENT_TIMESTAMP)) / 86400.0)::int " +
                "FROM usuario WHERE id = ? " +
                "AND clave_restablecida_en > CURRENT_TIMESTAMP - (? * INTERVAL '1 day')";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, DIAS_BLOQUEO);
            ps.setLong(2, usuarioId);
            ps.setInt(3, DIAS_BLOQUEO);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Math.max(1, rs.getInt(1)) : 0;
            }
        }
    }

    /**
     * Invalida los códigos anteriores del usuario y crea uno nuevo.
     * Devuelve el id de la solicitud, o -1 si ya se envió un código hace menos de 60 s.
     */
    public long crearCodigo(long usuarioId, String codigo) throws SQLException {
        String sqlReciente =
                "SELECT 1 FROM recuperacion_contrasena WHERE usuario_id = ? " +
                "AND ultimo_envio_en > CURRENT_TIMESTAMP - (? * INTERVAL '1 second')";

        String sqlInvalidar =
                "UPDATE recuperacion_contrasena SET usado = TRUE " +
                "WHERE usuario_id = ? AND usado = FALSE";

        String sqlInsertar =
                "INSERT INTO recuperacion_contrasena (usuario_id, codigo_hash, expira_en) " +
                "VALUES (?, ?, CURRENT_TIMESTAMP + (? * INTERVAL '1 minute')) RETURNING id";

        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                try (PreparedStatement ps = c.prepareStatement(sqlReciente)) {
                    ps.setLong(1, usuarioId);
                    ps.setInt(2, SEGUNDOS_ENTRE_ENVIOS);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            c.rollback();
                            return -1;
                        }
                    }
                }
                try (PreparedStatement ps = c.prepareStatement(sqlInvalidar)) {
                    ps.setLong(1, usuarioId);
                    ps.executeUpdate();
                }
                long id;
                try (PreparedStatement ps = c.prepareStatement(sqlInsertar)) {
                    ps.setLong(1, usuarioId);
                    ps.setString(2, hashCodigo(usuarioId, codigo));
                    ps.setInt(3, MINUTOS_VALIDEZ);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        id = rs.getLong(1);
                    }
                }
                c.commit();
                return id;
            } catch (SQLException | RuntimeException e) {
                try { c.rollback(); } catch (SQLException ignorado) { }
                throw e;
            }
        }
    }

    /**
     * Estado de una solicitud aún sin usar: claves "correo", "verificado" y
     * "vigente" ("true"/"false"). null si no existe o ya se usó.
     */
    public Map<String, String> obtener(long id) throws SQLException {
        String sql =
                "SELECT u.correo, (r.verificado_en IS NOT NULL) AS verificado, " +
                "(r.expira_en > CURRENT_TIMESTAMP) AS vigente " +
                "FROM recuperacion_contrasena r JOIN usuario u ON u.id = r.usuario_id " +
                "WHERE r.id = ? AND r.usado = FALSE";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String, String> m = new HashMap<>();
                m.put("correo", rs.getString("correo"));
                m.put("verificado", String.valueOf(rs.getBoolean("verificado")));
                m.put("vigente", String.valueOf(rs.getBoolean("vigente")));
                return m;
            }
        }
    }

    /** Código nuevo para la misma solicitud. false si es muy pronto o ya no aplica. */
    public boolean renovarCodigo(long id, String codigo) throws SQLException {
        String sql =
                "UPDATE recuperacion_contrasena SET codigo_hash = ?, intentos = 0, " +
                "expira_en = CURRENT_TIMESTAMP + (? * INTERVAL '1 minute'), " +
                "ultimo_envio_en = CURRENT_TIMESTAMP " +
                "WHERE id = ? AND usado = FALSE AND verificado_en IS NULL " +
                "AND ultimo_envio_en <= CURRENT_TIMESTAMP - (? * INTERVAL '1 second') " +
                "RETURNING usuario_id";

        try (Connection c = ConexionBD.conectar()) {
            // El hash depende del usuario; se obtiene primero.
            long usuarioId;
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT usuario_id FROM recuperacion_contrasena WHERE id = ?")) {
                ps.setLong(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) return false;
                    usuarioId = rs.getLong(1);
                }
            }
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, hashCodigo(usuarioId, codigo));
                ps.setInt(2, MINUTOS_VALIDEZ);
                ps.setLong(3, id);
                ps.setInt(4, SEGUNDOS_ENTRE_ENVIOS);
                try (ResultSet rs = ps.executeQuery()) {
                    return rs.next();
                }
            }
        }
    }

    /**
     * Comprueba el código. Devuelve OK / INCORRECTO / EXPIRADO / BLOQUEADO
     * (constantes de VerificacionDAO). Si es OK marca la solicitud como
     * verificada y da MINUTOS_VALIDEZ más para escribir la contraseña nueva.
     */
    public String confirmarCodigo(long id, String codigo) throws SQLException {
        String sqlLeer =
                "SELECT usuario_id, codigo_hash, intentos, " +
                "(expira_en > CURRENT_TIMESTAMP) AS vigente " +
                "FROM recuperacion_contrasena " +
                "WHERE id = ? AND usado = FALSE AND verificado_en IS NULL FOR UPDATE";

        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                long usuarioId;
                String esperado;
                try (PreparedStatement ps = c.prepareStatement(sqlLeer)) {
                    ps.setLong(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            c.rollback();
                            return VerificacionDAO.EXPIRADO;
                        }
                        if (rs.getInt("intentos") >= MAX_INTENTOS) {
                            c.rollback();
                            return VerificacionDAO.BLOQUEADO;
                        }
                        if (!rs.getBoolean("vigente")) {
                            c.rollback();
                            return VerificacionDAO.EXPIRADO;
                        }
                        usuarioId = rs.getLong("usuario_id");
                        esperado = rs.getString("codigo_hash");
                    }
                }

                String recibido = hashCodigo(usuarioId, codigo == null ? "" : codigo.trim());
                if (!MessageDigest.isEqual(esperado.getBytes(StandardCharsets.UTF_8),
                                           recibido.getBytes(StandardCharsets.UTF_8))) {
                    try (PreparedStatement up = c.prepareStatement(
                            "UPDATE recuperacion_contrasena SET intentos = intentos + 1 WHERE id = ?")) {
                        up.setLong(1, id);
                        up.executeUpdate();
                    }
                    c.commit();
                    return VerificacionDAO.INCORRECTO;
                }

                try (PreparedStatement up = c.prepareStatement(
                        "UPDATE recuperacion_contrasena SET verificado_en = CURRENT_TIMESTAMP, " +
                        "expira_en = CURRENT_TIMESTAMP + (? * INTERVAL '1 minute') WHERE id = ?")) {
                    up.setInt(1, MINUTOS_VALIDEZ);
                    up.setLong(2, id);
                    up.executeUpdate();
                }
                c.commit();
                return VerificacionDAO.OK;

            } catch (SQLException | RuntimeException e) {
                try { c.rollback(); } catch (SQLException ignorado) { }
                throw e;
            }
        }
    }

    /**
     * Cambia la contraseña (solo si el código ya fue verificado y sigue vigente),
     * registra la fecha en usuario.clave_restablecida_en y marca la solicitud
     * como usada, todo en una transacción. false si la solicitud ya no sirve.
     */
    public boolean restablecer(long id, String nuevaClave) throws SQLException {
        String sqlSolicitud =
                "SELECT usuario_id FROM recuperacion_contrasena " +
                "WHERE id = ? AND usado = FALSE AND verificado_en IS NOT NULL " +
                "AND expira_en > CURRENT_TIMESTAMP FOR UPDATE";

        String sqlClave =
                "UPDATE usuario SET contrasena_hash = ?, " +
                "clave_restablecida_en = CURRENT_TIMESTAMP, " +
                "intentos_fallidos = 0, bloqueado_hasta = NULL " +
                "WHERE id = ?";

        String sqlUsar =
                "UPDATE recuperacion_contrasena SET usado = TRUE " +
                "WHERE usuario_id = ? AND usado = FALSE";

        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                long usuarioId;
                try (PreparedStatement ps = c.prepareStatement(sqlSolicitud)) {
                    ps.setLong(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            c.rollback();
                            return false;
                        }
                        usuarioId = rs.getLong("usuario_id");
                    }
                }
                try (PreparedStatement ps = c.prepareStatement(sqlClave)) {
                    ps.setString(1, PasswordUtil.hash(nuevaClave));
                    ps.setLong(2, usuarioId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = c.prepareStatement(sqlUsar)) {
                    ps.setLong(1, usuarioId);
                    ps.executeUpdate();
                }
                c.commit();
                return true;
            } catch (SQLException | RuntimeException e) {
                try { c.rollback(); } catch (SQLException ignorado) { }
                throw e;
            }
        }
    }
}