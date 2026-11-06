package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.Capitulo;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class GestionCapituloDAO {

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

    public List<Capitulo> listarPorObra(
            long obraId, long autorId) throws SQLException {

        List<Capitulo> capitulos = new ArrayList<>();

        String sql = """
            SELECT c.id, c.obra_id, c.numero, c.titulo,
                   c.contenido, c.estado, c.publicado_en
            FROM capitulo c
            JOIN obra o ON o.id = c.obra_id
            WHERE c.obra_id = ? AND o.autor_id = ?
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

                con.commit();
                return id;

            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
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
                      AND length(btrim(titulo)) > 0
                      AND length(btrim(contenido)) > 0
                    """;

                String contenido;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT contenido FROM capitulo "
                        + "WHERE id = ? AND obra_id = ? "
                        + "AND estado = 'borrador'")) {
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