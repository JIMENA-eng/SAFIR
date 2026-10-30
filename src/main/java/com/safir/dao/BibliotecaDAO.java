package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.Obra;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class BibliotecaDAO {

    public boolean agregar(long usuarioId, long obraId)
            throws SQLException {

        String sql = """
            INSERT INTO biblioteca_obra (usuario_id, obra_id)
            SELECT ?, o.id
            FROM obra o
            WHERE o.id = ?
              AND o.estado = 'publicada'
            ON CONFLICT (usuario_id, obra_id) DO NOTHING
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);
            ps.setLong(2, obraId);

            return ps.executeUpdate() == 1;
        }
    }

    public boolean actualizarEstado(
            long usuarioId,
            long obraId,
            String estado) throws SQLException {

        if (estado == null || !List.of(
                "por_leer", "leyendo",
                "terminada", "abandonada"
        ).contains(estado)) {
            throw new IllegalArgumentException(
                "Estado de biblioteca no válido."
            );
        }

        String sql = """
            UPDATE biblioteca_obra
            SET estado = ?
            WHERE usuario_id = ?
              AND obra_id = ?
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setString(1, estado);
            ps.setLong(2, usuarioId);
            ps.setLong(3, obraId);

            return ps.executeUpdate() == 1;
        }
    }

    public boolean cambiarFavorito(
            long usuarioId,
            long obraId,
            boolean favorita) throws SQLException {

        String sql = """
            UPDATE biblioteca_obra
            SET favorita = ?
            WHERE usuario_id = ?
              AND obra_id = ?
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setBoolean(1, favorita);
            ps.setLong(2, usuarioId);
            ps.setLong(3, obraId);

            return ps.executeUpdate() == 1;
        }
    }

    public boolean eliminar(long usuarioId, long obraId)
            throws SQLException {

        String sql = """
            DELETE FROM biblioteca_obra
            WHERE usuario_id = ?
              AND obra_id = ?
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);
            ps.setLong(2, obraId);

            return ps.executeUpdate() == 1;
        }
    }

    public List<Obra> listar(long usuarioId) throws SQLException {

        List<Obra> obras = new ArrayList<>();

        String sql = """
            SELECT v.id, v.titulo, v.descripcion,
                   v.portada_ruta, v.genero, v.autor,
                   v.clasificacion, v.avance, v.promedio,
                   v.total_valoraciones, v.total_lecturas,
                   v.total_seguidores, v.capitulos_publicados,
                   COALESCE(array_to_string(v.etiquetas, ', '), '')
                       AS etiquetas,
                   b.estado AS estado_biblioteca,
                   b.favorita
            FROM biblioteca_obra b
            JOIN v_catalogo_obras v ON v.id = b.obra_id
            WHERE b.usuario_id = ?
            ORDER BY b.agregada_en DESC
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Obra obra = new Obra();

                    obra.setId(rs.getLong("id"));
                    obra.setTitulo(rs.getString("titulo"));
                    obra.setDescripcion(rs.getString("descripcion"));
                    obra.setPortadaRuta(rs.getString("portada_ruta"));
                    obra.setGenero(rs.getString("genero"));
                    obra.setAutor(rs.getString("autor"));
                    obra.setClasificacion(
                        rs.getString("clasificacion")
                    );
                    obra.setAvance(rs.getString("avance"));
                    obra.setPromedio(rs.getBigDecimal("promedio"));
                    obra.setTotalValoraciones(
                        rs.getLong("total_valoraciones")
                    );
                    obra.setTotalLecturas(
                        rs.getLong("total_lecturas")
                    );
                    obra.setTotalSeguidores(
                        rs.getLong("total_seguidores")
                    );
                    obra.setCapitulosPublicados(
                        rs.getLong("capitulos_publicados")
                    );

                    obra.setEstadoBiblioteca(
                        rs.getString("estado_biblioteca")
                    );

                    obra.setFavorita(
                        rs.getBoolean("favorita")
                    );

                    obra.setEtiquetas(rs.getString("etiquetas"));

                    obras.add(obra);
                }
            }
        }

        return obras;
    }
}