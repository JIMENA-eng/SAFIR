package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.seguridad.PasswordUtil;
import com.safir.seguridad.SocialAuth;

import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

/** Cuentas vinculadas a Google / Facebook / X (tabla identidad_social). */
public class SocialDAO {

    private static final SecureRandom ALEATORIO = new SecureRandom();

    /** Resultado de entrar con una red social. */
    public static final class Resultado {
        public long usuarioId;
        public boolean nuevo;
        public String error; // null si todo salió bien
    }

    /**
     * Busca la cuenta del usuario o la crea:
     *  1. Si esa identidad ya está vinculada -> entra a esa cuenta.
     *  2. Si el correo ya existe y el proveedor lo verificó -> vincula y entra.
     *  3. Si el correo existe pero NO está verificado -> error (no se vincula).
     *  4. Si no existe -> crea la cuenta (con bono de bienvenida por trigger).
     */
    public Resultado entrar(String proveedor, SocialAuth.Perfil perfil)
            throws SQLException {

        Resultado r = new Resultado();
        String correo = (perfil.correo == null || perfil.correo.isBlank())
                ? null : perfil.correo.trim().toLowerCase();

        try (Connection c = ConexionBD.conectar()) {
            c.setAutoCommit(false);
            try {
                // 1. Identidad ya vinculada
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT u.id, u.estado_cuenta FROM identidad_social i " +
                        "JOIN usuario u ON u.id = i.usuario_id " +
                        "WHERE i.proveedor = ? AND i.proveedor_uid = ?")) {
                    ps.setString(1, proveedor);
                    ps.setString(2, perfil.uid);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            if (!"activa".equalsIgnoreCase(rs.getString(2))) {
                                r.error = "Tu cuenta no está disponible.";
                            } else {
                                r.usuarioId = rs.getLong(1);
                            }
                            c.commit();
                            return r;
                        }
                    }
                }

                // 2 y 3. ¿Ya hay una cuenta con ese correo?
                if (correo != null) {
                    try (PreparedStatement ps = c.prepareStatement(
                            "SELECT id, estado_cuenta FROM usuario " +
                            "WHERE LOWER(correo) = LOWER(?)")) {
                        ps.setString(1, correo);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                if (!perfil.correoVerificado) {
                                    r.error = "Ese correo ya tiene una cuenta en SAFIR. "
                                            + "Inicia sesión con tu contraseña o con Google.";
                                    c.rollback();
                                    return r;
                                }
                                if (!"activa".equalsIgnoreCase(rs.getString(2))) {
                                    r.error = "Tu cuenta no está disponible.";
                                    c.rollback();
                                    return r;
                                }
                                r.usuarioId = rs.getLong(1);
                                vincular(c, r.usuarioId, proveedor, perfil.uid);
                                c.commit();
                                return r;
                            }
                        }
                    }
                }

                // 4. Cuenta nueva
                r.usuarioId = crearUsuario(c, correo, perfil.nombre);
                r.nuevo = true;
                vincular(c, r.usuarioId, proveedor, perfil.uid);
                c.commit();
                return r;

            } catch (SQLException | RuntimeException e) {
                try { c.rollback(); } catch (SQLException ignorado) { }
                throw e;
            }
        }
    }

    private void vincular(Connection c, long usuarioId, String proveedor, String uid)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO identidad_social (usuario_id, proveedor, proveedor_uid) " +
                "VALUES (?, ?, ?)")) {
            ps.setLong(1, usuarioId);
            ps.setString(2, proveedor);
            ps.setString(3, uid);
            ps.executeUpdate();
        }
    }

    private long crearUsuario(Connection c, String correo, String nombre)
            throws SQLException {

        String base = (nombre == null ? "" : nombre.trim());
        if (base.isEmpty()) base = "lector";
        if (base.length() > 50) base = base.substring(0, 50).trim();

        String publico = base;
        for (int i = 0; existe(c, "nombre_publico", publico); i++) {
            if (i > 20) throw new SQLException("No se pudo generar un sobrenombre libre.");
            publico = base + " " + (1000 + ALEATORIO.nextInt(9000));
        }

        String raiz = base.toLowerCase().replaceAll("[^a-z0-9_.]", "");
        if (raiz.length() < 3) raiz = "lector";
        if (raiz.length() > 20) raiz = raiz.substring(0, 20);
        String usuario = raiz;
        for (int i = 0; existe(c, "nombre_usuario", usuario); i++) {
            if (i > 20) throw new SQLException("No se pudo generar un usuario libre.");
            usuario = raiz + "_" + (1000 + ALEATORIO.nextInt(9000));
        }

        // Sin contraseña propia: se guarda una aleatoria que nadie conoce.
        byte[] b = new byte[32];
        ALEATORIO.nextBytes(b);
        String hash = PasswordUtil.hash(Base64.getEncoder().encodeToString(b));

        long id;
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO usuario (correo, nombre_usuario, contrasena_hash, " +
                "nombre_publico, datos_consentidos_en) " +
                "VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP) RETURNING id")) {
            ps.setString(1, correo);
            ps.setString(2, usuario);
            ps.setString(3, hash);
            ps.setString(4, publico);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                id = rs.getLong(1);
            }
        }

        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO usuario_rol (usuario_id, rol_id) " +
                "SELECT ?, id FROM rol WHERE nombre = 'lector'")) {
            ps.setLong(1, id);
            if (ps.executeUpdate() != 1) {
                throw new SQLException("No existe el rol 'lector' en la base de datos.");
            }
        }

        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO perfil_usuario (usuario_id) VALUES (?) " +
                "ON CONFLICT (usuario_id) DO NOTHING")) {
            ps.setLong(1, id);
            ps.executeUpdate();
        }
        return id;
    }

    private boolean existe(Connection c, String columna, String valor)
            throws SQLException {
        // "columna" viene siempre de constantes de este archivo, nunca del usuario.
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT 1 FROM usuario WHERE LOWER(" + columna + ") = LOWER(?)")) {
            ps.setString(1, valor);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Datos para la sesión (mismas claves que UsuarioDAO.iniciarSesion):
     * id, nombre, roles, avatarRuta. También actualiza el último acceso.
     */
    public Map<String, Object> datosSesion(long usuarioId) throws SQLException {
        String sql =
                "SELECT u.nombre_publico, p.avatar_ruta, " +
                "COALESCE(STRING_AGG(r.nombre, ', '), '') AS roles " +
                "FROM usuario u " +
                "LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id " +
                "LEFT JOIN rol r ON r.id = ur.rol_id " +
                "LEFT JOIN perfil_usuario p ON p.usuario_id = u.id " +
                "WHERE u.id = ? GROUP BY u.nombre_publico, p.avatar_ruta";

        try (Connection c = ConexionBD.conectar()) {
            Map<String, Object> m = new HashMap<>();
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setLong(1, usuarioId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) return null;
                    m.put("id", usuarioId);
                    m.put("nombre", rs.getString("nombre_publico"));
                    m.put("roles", rs.getString("roles"));
                    m.put("avatarRuta", rs.getString("avatar_ruta"));
                }
            }
            try (PreparedStatement ps = c.prepareStatement(
                    "UPDATE usuario SET ultimo_acceso = CURRENT_TIMESTAMP WHERE id = ?")) {
                ps.setLong(1, usuarioId);
                ps.executeUpdate();
            }
            return m;
        }
    }
}