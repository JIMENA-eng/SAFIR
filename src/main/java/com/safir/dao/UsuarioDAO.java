
package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.seguridad.PasswordUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public class UsuarioDAO {

    public boolean registrar(String correo, String nombre, String clave)
            throws SQLException {

        String sqlUsuario =
                "INSERT INTO usuario " +
                "(correo, contrasena_hash, nombre_publico) " +
                "VALUES (?, ?, ?) RETURNING id";

        String sqlRol =
                "INSERT INTO usuario_rol (usuario_id, rol_id) " +
                "SELECT ?, id FROM rol WHERE nombre = ?";

        String sqlPerfil =
                "INSERT INTO perfil_usuario (usuario_id) VALUES (?)";

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
                return true;

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

    public Map<String, Object> iniciarSesion(String correo, String clave)
            throws SQLException {

        String sql =
                "SELECT u.id, u.nombre_publico, u.contrasena_hash, " +
                "u.estado_cuenta, " +
                "COALESCE(STRING_AGG(r.nombre, ', '), '') AS roles " +
                "FROM usuario u " +
                "LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id " +
                "LEFT JOIN rol r ON r.id = ur.rol_id " +
                "WHERE LOWER(u.correo) = LOWER(?) " +
                "GROUP BY u.id, u.nombre_publico, " +
                "u.contrasena_hash, u.estado_cuenta";

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

                // Verificar la contraseña.
                if (hash == null || !PasswordUtil.verificar(clave, hash)) {
                    return null;
                }

                long usuarioId = rs.getLong("id");
                String nombre = rs.getString("nombre_publico");
                String roles = rs.getString("roles");

                // Actualizar la fecha del último acceso.
                actualizarUltimoAcceso(conexion, usuarioId);

                // Devolver los datos del usuario.
                Map<String, Object> usuario = new HashMap<>();
                usuario.put("id", usuarioId);
                usuario.put("nombre", nombre);
                usuario.put("roles", roles);

                return usuario;
            }
        }
    }

    private void actualizarUltimoAcceso(
            Connection conexion, long usuarioId) throws SQLException {

        String sql =
                "UPDATE usuario " +
                "SET ultimo_acceso = CURRENT_TIMESTAMP " +
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
}
