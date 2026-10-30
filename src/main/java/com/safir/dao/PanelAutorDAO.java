package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.ObraAutor;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class PanelAutorDAO {

    public List<ObraAutor> listarObras(long autorId)
            throws SQLException {

        List<ObraAutor> obras = new ArrayList<>();

        String sql = """
            SELECT obra_id, titulo, estado, avance,
                   capitulos_publicados, capitulos_borrador,
                   total_lecturas, promedio, total_seguidores
            FROM v_panel_autor
            WHERE autor_id = ?
            ORDER BY obra_id DESC
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, autorId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ObraAutor obra = new ObraAutor();

                    obra.setObraId(rs.getLong("obra_id"));
                    obra.setTitulo(rs.getString("titulo"));
                    obra.setEstado(rs.getString("estado"));
                    obra.setAvance(rs.getString("avance"));
                    obra.setCapitulosPublicados(
                        rs.getLong("capitulos_publicados")
                    );
                    obra.setCapitulosBorrador(
                        rs.getLong("capitulos_borrador")
                    );
                    obra.setTotalLecturas(
                        rs.getLong("total_lecturas")
                    );
                    obra.setPromedio(
                        rs.getDouble("promedio")
                    );
                    obra.setTotalSeguidores(
                        rs.getLong("total_seguidores")
                    );

                    obras.add(obra);
                }
            }
        }

        return obras;
    }
}