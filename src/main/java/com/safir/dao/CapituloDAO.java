package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.Capitulo;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class CapituloDAO {

    private static final String COLUMNAS_COMPLETAS = """
        c.id, c.obra_id, c.numero, c.titulo, c.contenido,
        c.palabras, c.estado, c.publicado_en
        """;

    private static final String COLUMNAS_RESUMEN = """
        c.id, c.obra_id, c.numero, c.titulo,
        c.palabras, c.estado, c.publicado_en
        """;

    public Capitulo buscarPublicado(long capituloId, long obraId)
            throws SQLException {

        String sql = "SELECT " + COLUMNAS_COMPLETAS + """
            FROM capitulo c
            WHERE c.id = ?
              AND c.obra_id = ?
              AND c.estado = 'publicado'
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, capituloId);
            ps.setLong(2, obraId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapear(rs, true) : null;
            }
        }
    }

    public Capitulo buscarParaContinuar(long usuarioId, long obraId)
            throws SQLException {

        String sql = "SELECT " + COLUMNAS_COMPLETAS + """
            FROM progreso_lectura p
            JOIN capitulo c ON c.id = p.capitulo_id
            WHERE p.usuario_id = ?
              AND p.obra_id = ?
              AND c.obra_id = p.obra_id
              AND c.estado = 'publicado'
            ORDER BY p.actualizado_en DESC
            LIMIT 1
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);
            ps.setLong(2, obraId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapear(rs, true) : null;
            }
        }
    }

    public Capitulo obtenerPrimero(long obraId) throws SQLException {

        String sql = "SELECT " + COLUMNAS_COMPLETAS + """
            FROM capitulo c
            WHERE c.obra_id = ?
              AND c.estado = 'publicado'
            ORDER BY c.numero ASC
            LIMIT 1
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, obraId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapear(rs, true) : null;
            }
        }
    }

    public List<Capitulo> listarPublicados(long obraId)
            throws SQLException {

        List<Capitulo> capitulos = new ArrayList<>();

        String sql = "SELECT " + COLUMNAS_RESUMEN + """
            FROM capitulo c
            WHERE c.obra_id = ?
              AND c.estado = 'publicado'
            ORDER BY c.numero ASC
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, obraId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    capitulos.add(mapear(rs, false));
                }
            }
        }

        return capitulos;
    }

    public Capitulo obtenerAnterior(long obraId, int numero)
            throws SQLException {

        String sql = "SELECT " + COLUMNAS_RESUMEN + """
            FROM capitulo c
            WHERE c.obra_id = ?
              AND c.estado = 'publicado'
              AND c.numero < ?
            ORDER BY c.numero DESC
            LIMIT 1
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setInt(2, numero);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapear(rs, false) : null;
            }
        }
    }

    public Capitulo obtenerSiguiente(long obraId, int numero)
            throws SQLException {

        String sql = "SELECT " + COLUMNAS_RESUMEN + """
            FROM capitulo c
            WHERE c.obra_id = ?
              AND c.estado = 'publicado'
              AND c.numero > ?
            ORDER BY c.numero ASC
            LIMIT 1
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, obraId);
            ps.setInt(2, numero);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapear(rs, false) : null;
            }
        }
    }

    public double obtenerPosicion(
            long usuarioId,
            long obraId,
            long capituloId
    ) throws SQLException {

        String sql = """
            SELECT posicion
            FROM progreso_lectura
            WHERE usuario_id = ?
              AND obra_id = ?
              AND capitulo_id = ?
            """;

        try (Connection cn = ConexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {

            ps.setLong(1, usuarioId);
            ps.setLong(2, obraId);
            ps.setLong(3, capituloId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getDouble("posicion");
                }
            }
        }

        return 0.0;
    }

    public void guardarProgreso(
            long usuarioId,
            long obraId,
            long capituloId,
            double posicion
    ) throws SQLException {

        String actualizar = """
            UPDATE progreso_lectura
            SET posicion = ?, actualizado_en = NOW()
            WHERE usuario_id = ?
              AND obra_id = ?
              AND capitulo_id = ?
            """;

        String insertar = """
            INSERT INTO progreso_lectura
                (usuario_id, obra_id, capitulo_id, posicion, actualizado_en)
            VALUES (?, ?, ?, ?, NOW())
            """;

        try (Connection cn = ConexionBD.conectar()) {
            cn.setAutoCommit(false);

            try {
                int filas;

                try (PreparedStatement ps = cn.prepareStatement(actualizar)) {
                    ps.setDouble(1, posicion);
                    ps.setLong(2, usuarioId);
                    ps.setLong(3, obraId);
                    ps.setLong(4, capituloId);
                    filas = ps.executeUpdate();
                }

                if (filas == 0) {
                    try (PreparedStatement ps = cn.prepareStatement(insertar)) {
                        ps.setLong(1, usuarioId);
                        ps.setLong(2, obraId);
                        ps.setLong(3, capituloId);
                        ps.setDouble(4, posicion);
                        ps.executeUpdate();
                    }
                }

                cn.commit();

            } catch (SQLException e) {
                cn.rollback();
                throw e;
            } finally {
                cn.setAutoCommit(true);
            }
        }
    }

    private Capitulo mapear(ResultSet rs, boolean conContenido)
            throws SQLException {

        Capitulo c = new Capitulo();

        c.setId(rs.getLong("id"));
        c.setObraId(rs.getLong("obra_id"));

        int numero = rs.getInt("numero");
        c.setNumero(rs.wasNull() ? null : numero);

        c.setTitulo(rs.getString("titulo"));

        if (conContenido) {
            c.setContenido(rs.getString("contenido"));
        }

        int palabras = rs.getInt("palabras");
        c.setPalabras(rs.wasNull() ? null : palabras);

        c.setEstado(rs.getString("estado"));

        Timestamp fecha = rs.getTimestamp("publicado_en");
        if (fecha != null) {
            c.setPublicadoEn(fecha.toLocalDateTime());
        }

        return c;
    }
}