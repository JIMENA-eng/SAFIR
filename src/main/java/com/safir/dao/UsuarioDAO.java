package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.seguridad.PasswordUtil;
import com.safir.seguridad.ValidadorRegistro;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public class UsuarioDAO {

    /**
     * Crea la cuenta YA verificada. Se llama solo después de confirmar el
     * código. Uno de correo/telefono es null según el canal elegido.
     * "nombre" es el sobrenombre (nombre_publico); la clave llega ya cifrada.
     */
    public long registrarVerificado(String correo, String telefono,
                                    String nombreUsuario, String nombre,
                                    String hashClave)
            throws SQLException {

        String sqlUsuario =
                "INSERT INTO usuario " +
                "(correo, telefono, nombre_usuario, contrasena_hash, " +
                " nombre_publico, datos_consentidos_en) " +
                "VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP) RETURNING id";

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

                    ps.setString(1, correo);
                    ps.setString(2, telefono);
                    ps.setString(3, nombreUsuario.trim());
                    ps.setString(4, hashClave);
                    ps.setString(5, nombre.trim());

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

    /** true si ya existe una cuenta con ese correo (minúsculas) o teléfono (+51...). */
    public boolean existeContacto(String canal, String destino)
            throws SQLException {

        String sql = "telefono".equals(canal)
                ? "SELECT 1 FROM usuario WHERE telefono = ?"
                : "SELECT 1 FROM usuario WHERE LOWER(correo) = LOWER(?)";

        return existe(sql, destino);
    }

    public boolean existeNombreUsuario(String nombreUsuario) throws SQLException {
        return existe("SELECT 1 FROM usuario WHERE LOWER(nombre_usuario) = LOWER(?)",
                nombreUsuario.trim());
    }

    public boolean existeNombrePublico(String nombre) throws SQLException {
        return existe("SELECT 1 FROM usuario WHERE LOWER(nombre_publico) = LOWER(?)",
                nombre.trim());
    }

    private boolean existe(String sql, String valor) throws SQLException {
        try (Connection c = ConexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, valor);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Inicia sesión con correo O teléfono ("identificador") y contraseña. */
    public Map<String, Object> iniciarSesion(String identificador, String clave)
            throws SQLException {

        boolean porCorreo = ValidadorRegistro.esCorreo(identificador);
        String valor = porCorreo
                ? identificador.trim()
                : ValidadorRegistro.normalizarTelefono(identificador);

        if (valor == null) {
            return null;
        }

        String sql =
                "SELECT u.id, u.nombre_publico, u.contrasena_hash, " +
                "u.estado_cuenta, p.avatar_ruta, " +
                "COALESCE(STRING_AGG(r.nombre, ', '), '') AS roles " +
                "FROM usuario u " +
                "LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id " +
                "LEFT JOIN rol r ON r.id = ur.rol_id " +
                "LEFT JOIN perfil_usuario p ON p.usuario_id = u.id " +
                "WHERE " + (porCorreo ? "LOWER(u.correo) = LOWER(?) "
                                      : "u.telefono = ? ") +
                "GROUP BY u.id, u.nombre_publico, " +
                "u.contrasena_hash, u.estado_cuenta, p.avatar_ruta";

        try (Connection conexion = ConexionBD.conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, valor);

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
                usuario.put("avatarRuta", rs.getString("avatar_ruta"));

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

    /**
     * Datos para la tarjeta de perfil del menú de cuenta. Claves: "sobrenombre"
     * (nombre_publico), "usuario" (nombre_usuario), "avatar" y "portada" (estas
     * dos pueden ser null). Devuelve un mapa vacío si el usuario no existe.
     */
    public Map<String, String> obtenerPerfilMenu(long usuarioId)
            throws SQLException {

        String sql =
                "SELECT u.nombre_publico, u.nombre_usuario, " +
                "p.avatar_ruta, p.portada_ruta " +
                "FROM usuario u " +
                "LEFT JOIN perfil_usuario p ON p.usuario_id = u.id " +
                "WHERE u.id = ?";

        Map<String, String> datos = new HashMap<>();

        try (Connection conexion = ConexionBD.conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    datos.put("sobrenombre", rs.getString("nombre_publico"));
                    datos.put("usuario", rs.getString("nombre_usuario"));
                    datos.put("avatar", rs.getString("avatar_ruta"));
                    datos.put("portada", rs.getString("portada_ruta"));
                }
            }
        }
        return datos;
    }
}