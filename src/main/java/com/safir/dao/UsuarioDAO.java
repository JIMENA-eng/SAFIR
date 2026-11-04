package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.seguridad.PasswordUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.Map;

public class UsuarioDAO {

    /** RNF-03: intentos fallidos permitidos antes de bloquear la cuenta. */
    public static final int MAX_INTENTOS_FALLIDOS = 5;

    /** RNF-03: minutos que dura el bloqueo. */
    public static final int MINUTOS_BLOQUEO = 15;

    public long registrar(String correo, String nombre, String clave)
            throws SQLException {

        String sqlUsuario =
                "INSERT INTO usuario " +
                "(correo, contrasena_hash, nombre_publico) " +
                "VALUES (?, ?, ?) RETURNING id";

        String sqlRol =
                "INSERT INTO usuario_rol (usuario_id, rol_id) " +
                "SELECT ?, id FROM rol WHERE nombre = ?";

        String sqlPerfil =
                "INSERT INTO perfil_usuario (usuario_id) VALUES (?) " +
                "ON CONFLICT (usuario_id) DO NOTHING";

        try (Connection conexion = ConexionBD.conectar()) {

            boolean autoCommitOriginal = conexion.getAutoCommit();
            conexion.setAutoCommit(false);

            try {
                long usuarioId;

                // 1. Registrar al usuario.
                try (PreparedStatement ps =
                        conexion.prepareStatement(sqlUsuario)) {

                    ps.setString(1, correo.trim());
                    ps.setString(2, PasswordUtil.hash(clave));
                    ps.setString(3, nombre.trim());

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException(
                                    "No se pudo obtener el ID del usuario."
                            );
                        }

                        usuarioId = rs.getLong("id");
                    }
                }

                // 2. Asignar el rol inicial.
                try (PreparedStatement ps =
                        conexion.prepareStatement(sqlRol)) {

                    ps.setLong(1, usuarioId);
                    ps.setString(2, "lector");

                    int filas = ps.executeUpdate();

                    if (filas != 1) {
                        throw new SQLException(
                                "No existe el rol 'lector' en la base de datos."
                        );
                    }
                }

                // 3. Crear el perfil del usuario.
                try (PreparedStatement ps =
                        conexion.prepareStatement(sqlPerfil)) {

                    ps.setLong(1, usuarioId);
                    ps.executeUpdate();
                }

                // 4. Confirmar las operaciones.
                conexion.commit();
                return usuarioId;

            } catch (SQLException | RuntimeException e) {
                try {
                    conexion.rollback();
                } catch (SQLException errorRollback) {
                    e.addSuppressed(errorRollback);
                }

                throw e;

            } finally {
                try {
                    conexion.setAutoCommit(autoCommitOriginal);
                } catch (SQLException ignored) {
                    // La conexión se cerrará al salir del bloque try.
                }
            }
        }
    }

    /**
     * Valida las credenciales.
     *
     * @return los datos del usuario, o null si el correo no existe, la cuenta
     *         no está activa o la contraseña es incorrecta.
     * @throws CuentaBloqueadaException si la cuenta está bloqueada; mientras
     *         dure el bloqueo se rechaza incluso la contraseña correcta.
     */
    public Map<String, Object> iniciarSesion(String correo, String clave)
            throws SQLException, CuentaBloqueadaException {

        String sql =
                "SELECT u.id, u.nombre_publico, u.contrasena_hash, " +
                "u.estado_cuenta, u.bloqueado_hasta, " +
                "(u.bloqueado_hasta IS NOT NULL AND u.bloqueado_hasta > now()) AS bloqueada, " +
                "p.avatar_ruta, " +
                "COALESCE(STRING_AGG(r.nombre, ', '), '') AS roles " +
                "FROM usuario u " +
                "LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id " +
                "LEFT JOIN rol r ON r.id = ur.rol_id " +
                "LEFT JOIN perfil_usuario p ON p.usuario_id = u.id " +
                "WHERE LOWER(u.correo) = LOWER(?) " +
                "GROUP BY u.id, u.nombre_publico, " +
                "u.contrasena_hash, u.estado_cuenta, u.bloqueado_hasta, p.avatar_ruta";

        try (Connection conexion = ConexionBD.conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, correo.trim());

            try (ResultSet rs = ps.executeQuery()) {

                if (!rs.next()) {
                    return null;
                }

                String hash = rs.getString("contrasena_hash");
                String estado = rs.getString("estado_cuenta");

                // Verificar que la cuenta esté activa.
                if (!"activa".equalsIgnoreCase(estado)) {
                    return null;
                }

                long usuarioId = rs.getLong("id");

                // Cuenta bloqueada: se rechaza aunque la contraseña sea correcta.
                if (rs.getBoolean("bloqueada")) {
                    Timestamp hasta = rs.getTimestamp("bloqueado_hasta");
                    throw new CuentaBloqueadaException(hasta.toInstant());
                }

                // Verificar la contraseña.
                if (hash == null || !PasswordUtil.verificar(clave, hash)) {
                    registrarIntentoFallido(conexion, usuarioId);
                    return null;
                }

                String nombre = rs.getString("nombre_publico");
                String roles = rs.getString("roles");

                // Acceso correcto: reinicia el contador y anota el último acceso.
                registrarAccesoCorrecto(conexion, usuarioId);

                // Devolver los datos del usuario.
                Map<String, Object> usuario = new HashMap<>();
                usuario.put("id", usuarioId);
                usuario.put("nombre", nombre);
                usuario.put("roles", roles);
                usuario.put("avatarRuta", rs.getString("avatar_ruta"));

                return usuario;
            }
        }
    }

    /**
     * Suma un intento fallido y, al llegar al máximo, bloquea la cuenta.
     * Si un bloqueo anterior ya venció, el conteo vuelve a empezar en 1.
     * Todo en una sola sentencia para que sea atómico ante peticiones simultáneas.
     */
    private void registrarIntentoFallido(
            Connection conexion, long usuarioId) throws SQLException {

        String sql = """
            WITH nuevo AS (
                SELECT id,
                       CASE WHEN bloqueado_hasta IS NOT NULL
                                 AND bloqueado_hasta <= now()
                            THEN 1
                            ELSE intentos_fallidos + 1
                       END AS intentos
                FROM usuario
                WHERE id = ?
            )
            UPDATE usuario u
            SET intentos_fallidos = nuevo.intentos,
                bloqueado_hasta = CASE WHEN nuevo.intentos >= ?
                                       THEN now() + make_interval(mins => ?)
                                       ELSE NULL
                                  END
            FROM nuevo
            WHERE u.id = nuevo.id
            """;

        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            ps.setInt(2, MAX_INTENTOS_FALLIDOS);
            ps.setInt(3, MINUTOS_BLOQUEO);
            ps.executeUpdate();
        }
    }

    /** Reinicia el contador de intentos y actualiza el último acceso. */
    private void registrarAccesoCorrecto(
            Connection conexion, long usuarioId) throws SQLException {

        String sql =
                "UPDATE usuario " +
                "SET ultimo_acceso = CURRENT_TIMESTAMP, " +
                "    intentos_fallidos = 0, " +
                "    bloqueado_hasta = NULL " +
                "WHERE id = ?";

        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setLong(1, usuarioId);
            ps.executeUpdate();
        }
    }

    /**
     * Agrega el rol "autor" (si aún no lo tiene) y devuelve los roles
     * actuales del usuario en el mismo formato que el inicio de sesión.
     */
    public String hacerseAutor(long usuarioId) throws SQLException {

        String sqlInsertar = """
            INSERT INTO usuario_rol (usuario_id, rol_id)
            SELECT ?, r.id
            FROM rol r
            WHERE r.nombre = 'autor'
              AND NOT EXISTS (
                  SELECT 1 FROM usuario_rol ur
                  WHERE ur.usuario_id = ? AND ur.rol_id = r.id)
            """;

        String sqlRoles = """
            SELECT COALESCE(STRING_AGG(r.nombre, ', '), '')
            FROM usuario_rol ur
            JOIN rol r ON r.id = ur.rol_id
            WHERE ur.usuario_id = ?
            """;

        try (Connection conexion = ConexionBD.conectar()) {

            try (PreparedStatement ps = conexion.prepareStatement(sqlInsertar)) {
                ps.setLong(1, usuarioId);
                ps.setLong(2, usuarioId);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = conexion.prepareStatement(sqlRoles)) {
                ps.setLong(1, usuarioId);

                try (ResultSet rs = ps.executeQuery()) {
                    return rs.next() ? rs.getString(1) : "";
                }
            }
        }
    }

    /**
     * Actualiza foto de perfil y/o portada. Un valor null conserva el actual.
     */
    public void actualizarImagenes(long usuarioId, String avatarRuta,
                                   String portadaRuta) throws SQLException {

        String sql =
                "UPDATE perfil_usuario SET " +
                "avatar_ruta = COALESCE(?, avatar_ruta), " +
                "portada_ruta = COALESCE(?, portada_ruta) " +
                "WHERE usuario_id = ?";

        try (Connection conexion = ConexionBD.conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, avatarRuta);
            ps.setString(2, portadaRuta);
            ps.setLong(3, usuarioId);
            ps.executeUpdate();
        }
    }

    /** Devuelve las rutas actuales: claves "avatar" y "portada" (pueden ser null). */
    public Map<String, String> obtenerImagenes(long usuarioId)
            throws SQLException {

        String sql =
                "SELECT avatar_ruta, portada_ruta " +
                "FROM perfil_usuario WHERE usuario_id = ?";

        Map<String, String> imagenes = new HashMap<>();

        try (Connection conexion = ConexionBD.conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    imagenes.put("avatar", rs.getString("avatar_ruta"));
                    imagenes.put("portada", rs.getString("portada_ruta"));
                }
            }
        }
        return imagenes;
    }
}
