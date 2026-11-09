package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.Capitulo;
import com.safir.util.SqlErrores;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Importaciones de capítulos desde archivo, sobre la tabla importacion_pdf y
 * las columnas capitulo.importacion_id / orden_importacion.
 *
 * Ciclo: al subir, la importación queda "en_revision" y sus capítulos se
 * guardan como borradores ligados a ella. Confirmar NO publica: suelta los
 * borradores de la importación (quedan como borradores normales, editables y
 * publicables uno por uno) y deja la importación "confirmada"; rechazar borra
 * esos borradores y la deja "rechazada" con motivo.
 *
 * Los índices únicos de sql/importacion_indices.sql garantizan una sola
 * importación en revisión por obra y un archivo (SHA-256) una vez por obra.
 */
public class ImportacionDAO {

    private static final String UNICO_UNA_EN_REVISION = "ux_importacion_una_en_revision";
    private static final String SQLSTATE_UNICO = "23505";

    private final GestionCapituloDAO capituloDao = new GestionCapituloDAO();

    /**
     * La importación en revisión de la obra, o null.
     * Claves: id, nombreOriginal, sha256, archivo, totalCapitulos, creadoEn.
     */
    public Map<String, Object> enRevision(long obraId, long autorId)
            throws SQLException {

        String sql = """
            SELECT id, nombre_archivo, hash_archivo, archivo_ruta,
                   capitulos_detectados, creado_en
            FROM importacion_pdf
            WHERE obra_id = ? AND autor_id = ? AND estado = 'en_revision'
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setLong(2, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Map<String, Object> m = new HashMap<>();
                m.put("id", rs.getLong("id"));
                m.put("nombreOriginal", rs.getString("nombre_archivo"));
                m.put("sha256", rs.getString("hash_archivo"));
                m.put("archivo", rs.getString("archivo_ruta"));
                m.put("totalCapitulos", rs.getInt("capitulos_detectados"));
                m.put("creadoEn", rs.getTimestamp("creado_en"));
                return m;
            }
        }
    }

    /** true si ese archivo (por su SHA-256) ya está en revisión o confirmado en la obra. */
    public boolean existeHash(long obraId, String sha256) throws SQLException {
        String sql = """
            SELECT 1 FROM importacion_pdf
            WHERE obra_id = ? AND hash_archivo = ?
              AND estado IN ('en_revision', 'confirmada')
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setString(2, sha256);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Registra la importación en revisión y guarda sus capítulos como
     * borradores ligados a ella, todo en una transacción.
     *
     * @return el id de la importación
     * @throws IllegalArgumentException con un mensaje para el autor si ya hay
     *         otra en revisión o el archivo ya se importó
     */
    public long registrar(long obraId, long autorId, String nombreArchivo,
            int tamanoBytes, String sha256, String archivoRuta,
            List<Capitulo> capitulos) throws SQLException {

        try (Connection con = ConexionBD.conectar()) {
            con.setAutoCommit(false);

            try {
                long id;

                try (PreparedStatement ps = con.prepareStatement("""
                        INSERT INTO importacion_pdf
                            (obra_id, autor_id, nombre_archivo, tamano_bytes,
                             hash_archivo, archivo_ruta, capitulos_detectados)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                        RETURNING id
                        """)) {
                    ps.setLong(1, obraId);
                    ps.setLong(2, autorId);
                    ps.setString(3, nombreArchivo);
                    ps.setInt(4, tamanoBytes);
                    ps.setString(5, sha256);
                    ps.setString(6, archivoRuta);
                    ps.setInt(7, capitulos.size());

                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        id = rs.getLong(1);
                    }
                }

                capituloDao.insertarBorradores(
                        con, autorId, obraId, id, capitulos);

                con.commit();
                return id;

            } catch (SQLException e) {
                con.rollback();

                if (SQLSTATE_UNICO.equals(e.getSQLState())) {
                    String m = e.getMessage() == null ? "" : e.getMessage();
                    throw new IllegalArgumentException(
                        m.contains(UNICO_UNA_EN_REVISION)
                            ? "Ya tienes una importación en revisión en esta obra. "
                              + "Confírmala o recházala antes de subir otro archivo."
                            : "Este archivo ya se importó en esta obra.");
                }
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    /** Los capítulos de la importación, en el orden del archivo (solo del autor). */
    public List<Capitulo> capitulos(long importacionId, long autorId)
            throws SQLException {

        String sql = """
            SELECT c.titulo, c.contenido
            FROM capitulo c
            JOIN importacion_pdf i ON i.id = c.importacion_id
            WHERE i.id = ? AND i.autor_id = ? AND c.estado = 'borrador'
            ORDER BY c.orden_importacion, c.id
            """;

        List<Capitulo> lista = new ArrayList<>();

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, importacionId);
            ps.setLong(2, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Capitulo c = new Capitulo();
                    c.setTitulo(rs.getString("titulo"));
                    c.setContenido(rs.getString("contenido"));
                    lista.add(c);
                }
            }
        }

        return lista;
    }

    /**
     * Confirma la importación SIN publicar nada: los capítulos se sueltan de
     * la importación (importacion_id y orden_importacion en NULL) y quedan
     * como borradores normales de la obra. Desde la lista de capítulos el
     * autor los edita uno por uno y los publica cuando esté listo
     * (GestionCapituloDAO.publicar, que numera al publicar). La obra sigue
     * en borrador hasta que se publique el primer capítulo.
     *
     * @return cuántos capítulos quedaron como borrador
     * @throws IllegalArgumentException si la importación ya no está en revisión
     */
    public int confirmar(long importacionId, long autorId, long obraId)
            throws SQLException {

        try (Connection con = ConexionBD.conectar()) {
            con.setAutoCommit(false);

            try {
                comprobarEnRevision(con, importacionId, autorId, obraId);

                int total;
                try (PreparedStatement ps = con.prepareStatement("""
                        UPDATE capitulo
                        SET importacion_id = NULL, orden_importacion = NULL
                        WHERE importacion_id = ? AND estado = 'borrador'
                        """)) {
                    ps.setLong(1, importacionId);
                    total = ps.executeUpdate();
                }

                try (PreparedStatement ps = con.prepareStatement("""
                        UPDATE importacion_pdf
                        SET estado = 'confirmada', resuelto_en = now(),
                            archivo_ruta = NULL
                        WHERE id = ?
                        """)) {
                    ps.setLong(1, importacionId);
                    ps.executeUpdate();
                }

                con.commit();
                return total;

            } catch (SQLException e) {
                con.rollback();
                if (SqlErrores.esReglaNegocio(e)) {
                    throw new IllegalArgumentException(SqlErrores.mensaje(e));
                }
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    /**
     * Borra los borradores de la importación y la cierra como rechazada,
     * con motivo (la tabla lo exige).
     *
     * @return false si ya no estaba en revisión
     */
    public boolean rechazar(long importacionId, long autorId, long obraId,
            String motivo) throws SQLException {

        try (Connection con = ConexionBD.conectar()) {
            con.setAutoCommit(false);

            try {
                try {
                    comprobarEnRevision(con, importacionId, autorId, obraId);
                } catch (IllegalArgumentException e) {
                    con.rollback();
                    return false;
                }

                try (PreparedStatement ps = con.prepareStatement("""
                        DELETE FROM capitulo
                        WHERE importacion_id = ? AND estado = 'borrador'
                        """)) {
                    ps.setLong(1, importacionId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = con.prepareStatement("""
                        UPDATE importacion_pdf
                        SET estado = 'rechazada', motivo_rechazo = ?,
                            resuelto_en = now(), archivo_ruta = NULL
                        WHERE id = ?
                        """)) {
                    ps.setString(1, motivo == null || motivo.isBlank()
                            ? "Rechazada por el autor." : motivo);
                    ps.setLong(2, importacionId);
                    ps.executeUpdate();
                }

                con.commit();
                return true;

            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    /** Bloquea la fila y comprueba dueño, obra y estado "en_revision". */
    private void comprobarEnRevision(Connection con, long importacionId,
            long autorId, long obraId) throws SQLException {

        try (PreparedStatement ps = con.prepareStatement("""
                SELECT 1 FROM importacion_pdf
                WHERE id = ? AND autor_id = ? AND obra_id = ?
                  AND estado = 'en_revision'
                FOR UPDATE
                """)) {
            ps.setLong(1, importacionId);
            ps.setLong(2, autorId);
            ps.setLong(3, obraId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IllegalArgumentException(
                        "Esta importación ya se cerró desde otra ventana.");
                }
            }
        }
    }
}