package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.Obra;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class ObraDAO {

    private static final String COLUMNAS =
            "id, titulo, descripcion, portada_ruta, genero, autor, "
            + "clasificacion, avance, promedio, total_valoraciones, "
            + "total_lecturas, total_seguidores, capitulos_publicados, "
            + "COALESCE(array_to_string(etiquetas, ', '), '') AS etiquetas ";

    public List<Obra> listarPublicadas(String busqueda, String genero)
            throws SQLException {

        List<Obra> obras = new ArrayList<>();

        String sql = "SELECT " + COLUMNAS
                + "FROM v_catalogo_obras "
                + "WHERE (? = '' OR titulo ILIKE ? "
                + "OR autor ILIKE ? "
                + "OR COALESCE(descripcion, '') ILIKE ? "
                + "OR genero ILIKE ? "
                + "OR COALESCE(array_to_string(etiquetas, ', '), '') ILIKE ?) "
                + "AND (? = '' OR genero = ?) "
                + "ORDER BY publicada_en DESC NULLS LAST, id DESC";

        String termino = busqueda == null ? "" : busqueda.trim();
        String filtroGenero = genero == null ? "" : genero.trim();
        String patron = "%" + termino + "%";

        try (Connection conexion = ConexionBD.conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setString(1, termino);
            ps.setString(2, patron);
            ps.setString(3, patron);
            ps.setString(4, patron);
            ps.setString(5, patron);
            ps.setString(6, patron);
            ps.setString(7, filtroGenero);
            ps.setString(8, filtroGenero);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    obras.add(mapearObra(rs));
                }
            }
        }

        return obras;
    }

    public Obra buscarPublicadaPorId(long id) throws SQLException {

        String sql = "SELECT " + COLUMNAS
                + "FROM v_catalogo_obras WHERE id = ?";

        try (Connection conexion = ConexionBD.conectar();
             PreparedStatement ps = conexion.prepareStatement(sql)) {

            ps.setLong(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapearObra(rs);
                }
            }
        }

        return null;
    }

    private Obra mapearObra(ResultSet rs) throws SQLException {

        Obra obra = new Obra();

        obra.setId(rs.getLong("id"));
        obra.setTitulo(rs.getString("titulo"));
        obra.setDescripcion(rs.getString("descripcion"));
        obra.setPortadaRuta(rs.getString("portada_ruta"));
        obra.setGenero(rs.getString("genero"));
        obra.setAutor(rs.getString("autor"));
        obra.setClasificacion(rs.getString("clasificacion"));
        obra.setAvance(rs.getString("avance"));
        obra.setPromedio(rs.getBigDecimal("promedio"));
        obra.setTotalValoraciones(rs.getLong("total_valoraciones"));
        obra.setTotalLecturas(rs.getLong("total_lecturas"));
        obra.setTotalSeguidores(rs.getLong("total_seguidores"));
        obra.setCapitulosPublicados(rs.getLong("capitulos_publicados"));
        obra.setEtiquetas(rs.getString("etiquetas"));

        return obra;
    }
}