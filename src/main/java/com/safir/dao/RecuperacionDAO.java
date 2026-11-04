package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.seguridad.PasswordUtil;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Base64;
import java.util.HexFormat;

/**
 * Recuperación de contraseña mediante un token de un solo uso.
 *
 * En la base de datos solo se guarda el HASH (SHA-256) del token: el token
 * real viaja únicamente en el enlace enviado al usuario.
 */
public class RecuperacionDAO {

    /** Minutos que dura el enlace. */
    public static final int MINUTOS_VALIDEZ = 30;

    private static final SecureRandom ALEATORIO = new SecureRandom();

    /** Genera un token aleatorio y seguro para usar en una URL. */
    public static String generarToken() {
        byte[] bytes = new byte[32];
        ALEATORIO.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /** SHA-256 del token, en hexadecimal (64 caracteres). */
    public static String hashDeToken(String token) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(
                    md.digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
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

    /**
     * Guarda un token nuevo para el usuario e invalida los anteriores.
     * Devuelve false (sin crear nada) si ya se pidió uno hace menos de un
     * minuto, para que nadie llene el buzón de otra persona.
     */
    public boolean crearToken(long usuarioId, String tokenHash)
            throws SQLException {

        String sqlReciente =
                "SELECT 1 FROM recuperacion_contrasena " +
                "WHERE usuario_id = ? " +
                "AND creado_en > CURRENT_TIMESTAMP - INTERVAL '1 minute'";

        String sqlInvalidar =
                "UPDATE recuperacion_contrasena SET usado = TRUE " +
                "WHERE usuario_id = ? AND usado = FALSE";

        String sqlInsertar =
                "INSERT INTO recuperacion_contrasena " +
                "(usuario_id, token_hash, expira_en) VALUES " +
                "(?, ?, CURRENT_TIMESTAMP + (? * INTERVAL '1 minute'))";

        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                try (PreparedStatement ps = c.prepareStatement(sqlReciente)) {
                    ps.setLong(1, usuarioId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            c.rollback();
                            return false;
                        }
                    }
                }
                try (PreparedStatement ps = c.prepareStatement(sqlInvalidar)) {
                    ps.setLong(1, usuarioId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = c.prepareStatement(sqlInsertar)) {
                    ps.setLong(1, usuarioId);
                    ps.setString(2, tokenHash);
                    ps.setInt(3, MINUTOS_VALIDEZ);
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

    /** true si el token existe, no se usó y no ha caducado. */
    public boolean tokenValido(String tokenHash) throws SQLException {
        String sql =
                "SELECT 1 FROM recuperacion_contrasena " +
                "WHERE token_hash = ? AND usado = FALSE " +
                "AND expira_en > CURRENT_TIMESTAMP";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, tokenHash);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Cambia la contraseña si el token sigue siendo válido y lo marca como
     * usado, todo en una sola transacción. Devuelve false si el token no
     * sirve (no existe, ya se usó o caducó).
     */
    public boolean restablecer(String tokenHash, String nuevaClave)
            throws SQLException {

        String sqlToken =
                "SELECT usuario_id FROM recuperacion_contrasena " +
                "WHERE token_hash = ? AND usado = FALSE " +
                "AND expira_en > CURRENT_TIMESTAMP FOR UPDATE";

        String sqlClave =
                "UPDATE usuario SET contrasena_hash = ? WHERE id = ?";

        String sqlUsar =
                "UPDATE recuperacion_contrasena SET usado = TRUE " +
                "WHERE usuario_id = ? AND usado = FALSE";

        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                long usuarioId;
                try (PreparedStatement ps = c.prepareStatement(sqlToken)) {
                    ps.setString(1, tokenHash);
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