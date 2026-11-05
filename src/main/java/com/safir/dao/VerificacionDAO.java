package com.safir.dao;

import com.safir.config.ConexionBD;

import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

/**
 * Registros pendientes de verificar (tabla verificacion_registro).
 * El código se guarda como hash SHA-256; nunca en texto plano.
 */
public class VerificacionDAO {

    public static final int MINUTOS_VALIDEZ = 10;
    public static final int MAX_INTENTOS = 5;
    public static final int SEGUNDOS_ENTRE_ENVIOS = 60;

    public static final String OK = "ok";
    public static final String INCORRECTO = "incorrecto";
    public static final String EXPIRADO = "expirado";
    public static final String BLOQUEADO = "bloqueado";

    private static final SecureRandom ALEATORIO = new SecureRandom();

    /** Código numérico de 6 dígitos. */
    public static String generarCodigo() {
        return String.format("%06d", ALEATORIO.nextInt(1_000_000));
    }

    private static String hashCodigo(String destino, String codigo) {
        return RecuperacionDAO.hashDeToken(destino + ":" + codigo);
    }

    /**
     * Crea (o reemplaza) el registro pendiente de ese correo/teléfono.
     * Devuelve el id, o -1 si ya se envió un código hace menos de 60 s.
     */
    public long guardarPendiente(String canal, String destino,
                                 String nombrePublico, String nombreUsuario,
                                 String hashClave, String codigo)
            throws SQLException {

        String sqlReciente =
                "SELECT 1 FROM verificacion_registro WHERE destino = ? " +
                "AND ultimo_envio_en > CURRENT_TIMESTAMP - (? * INTERVAL '1 second')";

        String sql =
                "INSERT INTO verificacion_registro " +
                "(canal, destino, nombre_publico, nombre_usuario, contrasena_hash, " +
                " codigo_hash, expira_en) " +
                "VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP + (? * INTERVAL '1 minute')) " +
                "ON CONFLICT (destino) DO UPDATE SET " +
                " canal = EXCLUDED.canal, nombre_publico = EXCLUDED.nombre_publico, " +
                " nombre_usuario = EXCLUDED.nombre_usuario, " +
                " contrasena_hash = EXCLUDED.contrasena_hash, " +
                " codigo_hash = EXCLUDED.codigo_hash, intentos = 0, " +
                " expira_en = EXCLUDED.expira_en, ultimo_envio_en = CURRENT_TIMESTAMP " +
                "RETURNING id";

        try (Connection c = ConexionBD.conectar()) {
            try (PreparedStatement ps = c.prepareStatement(sqlReciente)) {
                ps.setString(1, destino);
                ps.setInt(2, SEGUNDOS_ENTRE_ENVIOS);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) return -1;
                }
            }
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, canal);
                ps.setString(2, destino);
                ps.setString(3, nombrePublico);
                ps.setString(4, nombreUsuario);
                ps.setString(5, hashClave);
                ps.setString(6, hashCodigo(destino, codigo));
                ps.setInt(7, MINUTOS_VALIDEZ);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    return rs.getLong(1);
                }
            }
        }
    }

    /** Canal y destino de un pendiente (claves "canal" y "destino"); null si no existe. */
    public Map<String, String> obtener(long id) throws SQLException {
        String sql = "SELECT canal, destino FROM verificacion_registro WHERE id = ?";
        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String, String> m = new HashMap<>();
                m.put("canal", rs.getString("canal"));
                m.put("destino", rs.getString("destino"));
                return m;
            }
        }
    }

    /** Genera un código nuevo para el mismo pendiente. false si es muy pronto. */
    public boolean renovarCodigo(long id, String destino, String codigo)
            throws SQLException {

        String sql =
                "UPDATE verificacion_registro SET codigo_hash = ?, intentos = 0, " +
                "expira_en = CURRENT_TIMESTAMP + (? * INTERVAL '1 minute'), " +
                "ultimo_envio_en = CURRENT_TIMESTAMP " +
                "WHERE id = ? " +
                "AND ultimo_envio_en <= CURRENT_TIMESTAMP - (? * INTERVAL '1 second')";

        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, hashCodigo(destino, codigo));
            ps.setInt(2, MINUTOS_VALIDEZ);
            ps.setLong(3, id);
            ps.setInt(4, SEGUNDOS_ENTRE_ENVIOS);
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * Comprueba el código. En "estado" devuelve OK / INCORRECTO / EXPIRADO /
     * BLOQUEADO. Si es OK, el pendiente se elimina y el mapa trae los datos
     * para crear la cuenta: canal, destino, nombrePublico, nombreUsuario, hashClave.
     */
    public Map<String, String> confirmar(long id, String codigo)
            throws SQLException {

        Map<String, String> r = new HashMap<>();

        String sqlLeer =
                "SELECT canal, destino, nombre_publico, nombre_usuario, " +
                "contrasena_hash, codigo_hash, intentos, " +
                "(expira_en > CURRENT_TIMESTAMP) AS vigente " +
                "FROM verificacion_registro WHERE id = ? FOR UPDATE";

        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                try (PreparedStatement ps = c.prepareStatement(sqlLeer)) {
                    ps.setLong(1, id);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            r.put("estado", EXPIRADO);
                            c.rollback();
                            return r;
                        }

                        String destino = rs.getString("destino");

                        if (rs.getInt("intentos") >= MAX_INTENTOS) {
                            r.put("estado", BLOQUEADO);
                            c.rollback();
                            return r;
                        }
                        if (!rs.getBoolean("vigente")) {
                            r.put("estado", EXPIRADO);
                            c.rollback();
                            return r;
                        }

                        String esperado = rs.getString("codigo_hash");
                        String recibido = hashCodigo(destino, codigo == null ? "" : codigo.trim());

                        if (!MessageDigest.isEqual(esperado.getBytes(), recibido.getBytes())) {
                            try (PreparedStatement up = c.prepareStatement(
                                    "UPDATE verificacion_registro SET intentos = intentos + 1 WHERE id = ?")) {
                                up.setLong(1, id);
                                up.executeUpdate();
                            }
                            c.commit();
                            r.put("estado", INCORRECTO);
                            return r;
                        }

                        r.put("canal", rs.getString("canal"));
                        r.put("destino", destino);
                        r.put("nombrePublico", rs.getString("nombre_publico"));
                        r.put("nombreUsuario", rs.getString("nombre_usuario"));
                        r.put("hashClave", rs.getString("contrasena_hash"));
                    }
                }

                try (PreparedStatement ps = c.prepareStatement(
                        "DELETE FROM verificacion_registro WHERE id = ?")) {
                    ps.setLong(1, id);
                    ps.executeUpdate();
                }
                c.commit();
                r.put("estado", OK);
                return r;

            } catch (SQLException | RuntimeException e) {
                try { c.rollback(); } catch (SQLException ignorado) { }
                throw e;
            }
        }
    }
}