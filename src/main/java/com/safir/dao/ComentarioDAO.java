package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.Comentario;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class ComentarioDAO {

    public List<Comentario> listarPorCapitulo(long capituloId)
            throws SQLException {

        List<Comentario> comentarios = new ArrayList<>();

        String sql = """
            SELECT id, capitulo_id, usuario_id, padre_id,
                   autor, texto, creado_en, me_gusta, no_me_gusta
            FROM v_comentarios_capitulo
            WHERE capitulo_id = ?
            ORDER BY creado_en ASC
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, capituloId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Comentario c = new Comentario();

                    c.setId(rs.getLong("id"));
                    c.setCapituloId(rs.getLong("capitulo_id"));
                    c.setUsuarioId(rs.getLong("usuario_id"));

                    long padre = rs.getLong("padre_id");
                    c.setPadreId(rs.wasNull() ? null : padre);

                    c.setAutor(rs.getString("autor"));
                    c.setTexto(rs.getString("texto"));
                    c.setCreadoEn(
                        rs.getTimestamp("creado_en").toLocalDateTime()
                    );
                    c.setMeGusta(rs.getLong("me_gusta"));
                    c.setNoMeGusta(rs.getLong("no_me_gusta"));

                    comentarios.add(c);
                }
            }
        }

        return comentarios;
    }

    public boolean insertar(
            long usuarioId,
            long capituloId,
            Long padreId,
            String texto) throws SQLException {

        String sql = """
            INSERT INTO comentario
                (usuario_id, capitulo_id, padre_id, texto)
            SELECT ?, c.id, ?, ?
            FROM capitulo c
            JOIN obra o ON o.id = c.obra_id
            WHERE c.id = ?
              AND c.estado = 'publicado'
              AND o.estado = 'publicada'
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);

            if (padreId == null) {
                ps.setNull(2, java.sql.Types.BIGINT);
            } else {
                ps.setLong(2, padreId);
            }

            ps.setString(3, texto.trim());
            ps.setLong(4, capituloId);

            return ps.executeUpdate() == 1;
        }
    }
}