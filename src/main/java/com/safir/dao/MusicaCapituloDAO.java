package com.safir.dao;

import com.safir.config.ConexionBD;
import com.safir.modelo.PistaCapitulo;
import com.safir.util.AudioUtil;

import java.sql.Array;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Música de un capítulo. Usa las tablas que ya existen en la base:
 *   pista_musica   → la pista (enlace de YouTube o archivo subido)
 *   capitulo_pista → qué pista suena en qué capítulo (aquí, una por capítulo, orden 1)
 */
public class MusicaCapituloDAO {

    /** Lo que el autor eligió en el editor. */
    public static final class Cambio {

        public static final String MANTENER = "mantener";
        public static final String QUITAR = "quitar";
        public static final String NUEVA = "nueva";

        private final String accion;
        private final PistaCapitulo nueva;
        private final boolean enBucle;

        private Cambio(String accion, PistaCapitulo nueva, boolean enBucle) {
            this.accion = accion;
            this.nueva = nueva;
            this.enBucle = enBucle;
        }

        public static Cambio mantener(boolean enBucle) {
            return new Cambio(MANTENER, null, enBucle);
        }

        public static Cambio quitar() {
            return new Cambio(QUITAR, null, false);
        }

        public static Cambio nueva(PistaCapitulo pista, boolean enBucle) {
            return new Cambio(NUEVA, pista, enBucle);
        }

        public String getAccion() {
            return accion;
        }

        public PistaCapitulo getNueva() {
            return nueva;
        }

        public boolean isEnBucle() {
            return enBucle;
        }
    }

    /** Música del capítulo, o null si no tiene. */
    public PistaCapitulo obtener(long capituloId) throws SQLException {

        String sql = """
            SELECT p.id, p.titulo, p.url, p.archivo_ruta, cp.en_bucle
            FROM capitulo_pista cp
            JOIN pista_musica p ON p.id = cp.pista_id
            WHERE cp.capitulo_id = ?
              AND p.activa
            ORDER BY cp.orden
            LIMIT 1
            """;

        try (Connection con = ConexionBD.conectar();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, capituloId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                PistaCapitulo p = new PistaCapitulo();
                p.setPistaId(rs.getLong("id"));
                p.setTitulo(rs.getString("titulo"));
                p.setUrl(rs.getString("url"));
                p.setArchivoRuta(rs.getString("archivo_ruta"));
                p.setEnBucle(rs.getBoolean("en_bucle"));

                if (p.getArchivoRuta() != null) {
                    p.setTipo(PistaCapitulo.ARCHIVO);
                } else {
                    String id = AudioUtil.youtubeId(p.getUrl());
                    if (id == null) {
                        return null;            // enlace que no sabemos reproducir
                    }
                    p.setTipo(PistaCapitulo.YOUTUBE);
                    p.setYoutubeId(id);
                }
                return p;
            }
        }
    }

    /**
     * Aplica el cambio dentro de una transacción ya abierta (no hace commit).
     * Devuelve las rutas de los archivos de audio que dejaron de usarse;
     * se borran del disco solo después del commit.
     */
    List<String> aplicar(Connection con, long capituloId, long autorId, Cambio cambio)
            throws SQLException {

        List<String> sinUso = new ArrayList<>();

        if (cambio == null) {
            return sinUso;
        }

        if (Cambio.MANTENER.equals(cambio.getAccion())) {
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE capitulo_pista SET en_bucle = ? WHERE capitulo_id = ?")) {
                ps.setBoolean(1, cambio.isEnBucle());
                ps.setLong(2, capituloId);
                ps.executeUpdate();
            }
            return sinUso;
        }

        // QUITAR o NUEVA: primero se suelta la música anterior.
        List<Long> anteriores = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(
                "DELETE FROM capitulo_pista WHERE capitulo_id = ? RETURNING pista_id")) {
            ps.setLong(1, capituloId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    anteriores.add(rs.getLong(1));
                }
            }
        }

        if (!anteriores.isEmpty()) {
            // Solo se borran pistas que subió este autor y que ningún otro capítulo usa.
            String sql = """
                DELETE FROM pista_musica p
                WHERE p.id = ANY (?)
                  AND p.subida_por = ?
                  AND NOT EXISTS (SELECT 1 FROM capitulo_pista cp WHERE cp.pista_id = p.id)
                RETURNING p.archivo_ruta
                """;
            Array ids = con.createArrayOf("bigint", anteriores.toArray());
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setArray(1, ids);
                ps.setLong(2, autorId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String ruta = rs.getString(1);
                        if (ruta != null) {
                            sinUso.add(ruta);
                        }
                    }
                }
            } finally {
                ids.free();
            }
        }

        if (Cambio.NUEVA.equals(cambio.getAccion()) && cambio.getNueva() != null) {
            PistaCapitulo n = cambio.getNueva();
            long pistaId;

            // Las pistas del propio autor quedan aprobadas para que suenen al publicar.
            String insertarPista = """
                INSERT INTO pista_musica
                    (titulo, url, subida_por, archivo_ruta, tamano_bytes, estado_revision)
                VALUES (?, ?, ?, ?, ?, 'aprobada')
                RETURNING id
                """;
            try (PreparedStatement ps = con.prepareStatement(insertarPista)) {
                ps.setString(1, n.getTitulo());
                ps.setString(2, n.getUrl());
                ps.setLong(3, autorId);
                ps.setString(4, n.getArchivoRuta());
                if (n.getTamanoBytes() != null) {
                    ps.setInt(5, n.getTamanoBytes());
                } else {
                    ps.setNull(5, java.sql.Types.INTEGER);
                }
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    pistaId = rs.getLong(1);
                }
            }

            try (PreparedStatement ps = con.prepareStatement("""
                    INSERT INTO capitulo_pista (capitulo_id, pista_id, orden, posicion_inicio, en_bucle)
                    VALUES (?, ?, 1, 0, ?)
                    """)) {
                ps.setLong(1, capituloId);
                ps.setLong(2, pistaId);
                ps.setBoolean(3, cambio.isEnBucle());
                ps.executeUpdate();
            }
        }

        return sinUso;
    }
}