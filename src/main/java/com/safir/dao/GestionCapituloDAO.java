package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.Capitulo;
import com.safir.util.ImagenUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class GestionCapituloDAO {

    private final MusicaCapituloDAO musicaDao = new MusicaCapituloDAO();

    public boolean perteneceAlAutor(long obraId, long autorId)
            throws SQLException {

        String sql = """
            SELECT 1 FROM obra
            WHERE id = ? AND autor_id = ?
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setLong(2, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** true si la obra del autor ya está publicada en el catálogo. */
    public boolean obraEstaPublicada(long obraId, long autorId)
            throws SQLException {

        String sql = """
            SELECT 1 FROM obra
            WHERE id = ? AND autor_id = ? AND estado = 'publicada'
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setLong(2, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public List<Capitulo> listarPorObra(
            long obraId, long autorId) throws SQLException {

        List<Capitulo> capitulos = new ArrayList<>();

        String sql = """
            SELECT c.id, c.obra_id, c.numero, c.titulo,
                   c.contenido, c.estado, c.publicado_en
            FROM capitulo c
            JOIN obra o ON o.id = c.obra_id
            WHERE c.obra_id = ? AND o.autor_id = ?
              -- Los de una importación en revisión se ven en su pantalla de revisión
              AND NOT (c.importacion_id IS NOT NULL AND c.estado = 'borrador')
            ORDER BY
                CASE WHEN c.numero IS NULL THEN 1 ELSE 0 END,
                c.numero,
                c.creado_en,
                c.id
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setLong(2, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    capitulos.add(mapear(rs));
                }
            }
        }

        return capitulos;
    }

    public Capitulo obtenerPropio(
            long capituloId, long autorId) throws SQLException {

        String sql = """
            SELECT c.id, c.obra_id, c.numero, c.titulo,
                   c.contenido, c.estado, c.publicado_en
            FROM capitulo c
            JOIN obra o ON o.id = c.obra_id
            WHERE c.id = ? AND o.autor_id = ?
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, capituloId);
            ps.setLong(2, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapear(rs);
                }
            }
        }

        return null;
    }

    public long guardarBorrador(
            long autorId,
            long obraId,
            Long capituloId,
            String titulo,
            String contenido) throws SQLException {

        return guardarBorrador(autorId, obraId, capituloId, titulo, contenido, null);
    }

    /**
     * Guarda el borrador y, en la misma transacción, la música del capítulo
     * (musica puede ser null: no se toca). Si algo falla no queda nada a medias.
     * Los archivos de audio que dejan de usarse se borran después del commit.
     */
    public long guardarBorrador(
            long autorId,
            long obraId,
            Long capituloId,
            String titulo,
            String contenido,
            MusicaCapituloDAO.Cambio musica) throws SQLException {

        List<String> audiosSinUso = new ArrayList<>();
        long idGuardado;

        try (Connection con = ConexionBD.conectar()) {
            con.setAutoCommit(false);

            try {
                comprobarPropiedad(con, obraId, autorId);

                long id;

                if (capituloId == null) {
                    String sql = """
                        INSERT INTO capitulo
                            (obra_id, titulo, contenido, estado, palabras)
                        VALUES (?, ?, ?, 'borrador', ?)
                        RETURNING id
                        """;

                    try (PreparedStatement ps =
                                 con.prepareStatement(sql)) {
                        ps.setLong(1, obraId);
                        ps.setString(2, titulo);
                        ps.setString(3, contenido);
                        ps.setInt(4, contarPalabras(contenido));

                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                throw new SQLException(
                                    "No se pudo crear el capítulo.");
                            }
                            id = rs.getLong("id");
                        }
                    }
                } else {
                    String sql = """
                        UPDATE capitulo c
                        SET titulo = ?, contenido = ?, palabras = ?
                        FROM obra o
                        WHERE c.id = ?
                          AND c.obra_id = ?
                          AND o.id = c.obra_id
                          AND o.autor_id = ?
                          AND c.estado = 'borrador'
                        """;

                    try (PreparedStatement ps =
                                 con.prepareStatement(sql)) {
                        ps.setString(1, titulo);
                        ps.setString(2, contenido);
                        ps.setInt(3, contarPalabras(contenido));
                        ps.setLong(4, capituloId);
                        ps.setLong(5, obraId);
                        ps.setLong(6, autorId);

                        if (ps.executeUpdate() != 1) {
                            throw new SQLException(
                                "El capítulo no existe, no te pertenece "
                                + "o ya no es un borrador.");
                        }
                    }

                    id = capituloId;
                }

                audiosSinUso = musicaDao.aplicar(con, id, autorId, musica);

                con.commit();
                idGuardado = id;

            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }

        for (String ruta : audiosSinUso) {
            ImagenUtil.borrar(ruta);
        }

        return idGuardado;
    }

    public boolean publicar(
            long autorId, long capituloId) throws SQLException {

        try (Connection con = ConexionBD.conectar()) {
            con.setAutoCommit(false);

            try {
                long obraId;

                // Bloquea la fila de la obra para serializar
                // las publicaciones de capítulos de esa obra.
                String bloqueo = """
                    SELECT id
                    FROM obra
                    WHERE id = (
                        SELECT obra_id FROM capitulo WHERE id = ?
                    )
                    AND autor_id = ?
                    FOR UPDATE
                    """;

                try (PreparedStatement ps =
                             con.prepareStatement(bloqueo)) {
                    ps.setLong(1, capituloId);
                    ps.setLong(2, autorId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            con.rollback();
                            return false;
                        }
                        obraId = rs.getLong("id");
                    }
                }

                String actualizar = """
                    UPDATE capitulo
                    SET numero = (
                            SELECT COALESCE(MAX(c2.numero), 0) + 1
                            FROM capitulo c2
                            WHERE c2.obra_id = ? 
                              AND c2.estado = 'publicado'
                        ),
                        estado = 'publicado',
                        palabras = ?
                    WHERE id = ?
                      AND obra_id = ?
                      AND estado = 'borrador'
                      AND importacion_id IS NULL
                      AND length(btrim(titulo)) > 0
                      AND length(btrim(contenido)) > 0
                    """;

                String contenido;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT contenido FROM capitulo "
                        + "WHERE id = ? AND obra_id = ? "
                        + "AND estado = 'borrador' "
                        + "AND importacion_id IS NULL")) {
                    ps.setLong(1, capituloId);
                    ps.setLong(2, obraId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            con.rollback();
                            return false;
                        }
                        contenido = rs.getString("contenido");
                    }
                }

                try (PreparedStatement ps =
                             con.prepareStatement(actualizar)) {
                    ps.setLong(1, obraId);
                    ps.setInt(2, contarPalabras(contenido));
                    ps.setLong(3, capituloId);
                    ps.setLong(4, obraId);

                    if (ps.executeUpdate() != 1) {
                        con.rollback();
                        return false;
                    }
                }

                // Al publicar un capítulo, la obra pasa de borrador a publicada
                try (PreparedStatement ps = con.prepareStatement("""
                        UPDATE obra
                        SET estado = 'publicada',
                            publicada_en = COALESCE(publicada_en, now())
                        WHERE id = ? AND autor_id = ? AND estado = 'borrador'
                        """)) {
                    ps.setLong(1, obraId);
                    ps.setLong(2, autorId);
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

    /**
     * Inserta varios capítulos como borradores de una misma obra, en una sola
     * transacción: o se guardan todos o ninguno. Conservan el orden recibido
     * (el listado ordena por fecha de creación y luego por id).
     * El número se asigna al publicar, igual que con los capítulos escritos
     * a mano.
     */
    public int importarBorradores(
            long autorId,
            long obraId,
            List<Capitulo> capitulos) throws SQLException {

        if (capitulos == null || capitulos.isEmpty()) {
            return 0;
        }

        try (Connection con = ConexionBD.conectar()) {
            con.setAutoCommit(false);

            try {
                insertarBorradores(con, autorId, obraId, null, capitulos);
                con.commit();
                return capitulos.size();

            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }

    /**
     * Inserta borradores dentro de una transacción ya abierta (no hace commit
     * ni rollback). Con importacionId, los capítulos quedan ligados a esa
     * importación (capitulo.importacion_id) y con su orden en el archivo
     * (capitulo.orden_importacion, desde 1); publicar_importacion los publica
     * en ese orden.
     */
    void insertarBorradores(
            Connection con,
            long autorId,
            long obraId,
            Long importacionId,
            List<Capitulo> capitulos) throws SQLException {

        comprobarPropiedad(con, obraId, autorId);

        String sql = """
            INSERT INTO capitulo
                (obra_id, importacion_id, orden_importacion,
                 titulo, contenido, estado, palabras)
            VALUES (?, ?, ?, ?, ?, 'borrador', ?)
            """;

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            int orden = 1;
            for (Capitulo c : capitulos) {
                ps.setLong(1, obraId);
                if (importacionId == null) {
                    ps.setNull(2, Types.BIGINT);
                    ps.setNull(3, Types.INTEGER);
                } else {
                    ps.setLong(2, importacionId);
                    ps.setInt(3, orden);
                }
                orden++;
                ps.setString(4, c.getTitulo());
                ps.setString(5, c.getContenido());
                ps.setInt(6, contarPalabras(c.getContenido()));
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private void comprobarPropiedad(
            Connection con, long obraId, long autorId)
            throws SQLException {

        String sql = """
            SELECT 1 FROM obra
            WHERE id = ? AND autor_id = ?
            FOR UPDATE
            """;

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setLong(1, obraId);
            ps.setLong(2, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException(
                        "La obra no existe o no te pertenece.");
                }
            }
        }
    }

    private int contarPalabras(String contenido) {
        if (contenido == null || contenido.isBlank()) {
            return 0;
        }

        return contenido.trim().split("\\s+").length;
    }

    private Capitulo mapear(ResultSet rs) throws SQLException {
        Capitulo c = new Capitulo();

        c.setId(rs.getLong("id"));
        c.setObraId(rs.getLong("obra_id"));

        int numero = rs.getInt("numero");
        c.setNumero(rs.wasNull() ? null : numero);

        c.setTitulo(rs.getString("titulo"));
        c.setContenido(rs.getString("contenido"));
        c.setEstado(rs.getString("estado"));

        java.sql.Timestamp fecha = rs.getTimestamp("publicado_en");
        if (fecha != null) {
            c.setPublicadoEn(fecha.toLocalDateTime());
        }

        return c;
    }
}