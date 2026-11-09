package com.safir.util;

import com.safir.dao.ImportacionDAO;
import com.safir.modelo.Capitulo;
import com.safir.util.ImportadorCapitulos.Resultado;

import jakarta.servlet.http.Part;

import java.io.IOException;
import java.io.InputStream;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * Flujo completo de una importación:
 *
 *   preparar()    valida y lee el archivo (en memoria, no toca el disco ni la BD)
 *   iniciar()     guarda el archivo con nombre aleatorio y deja la importación
 *                 "en revisión", con sus capítulos como borradores ligados a ella
 *   pendiente() / capitulos()  lo que se muestra en la pantalla de revisión
 *   confirmar()   publica los capítulos (publicar_importacion) y borra el archivo
 *   rechazar()    borra los borradores, cierra con motivo y borra el archivo
 *
 * Los errores de contenido se informan con IllegalArgumentException (el
 * mensaje se muestra tal cual al autor); los de base de datos con SQLException.
 */
public final class ImportacionServicio {

    private static final ImportacionDAO dao = new ImportacionDAO();

    private ImportacionServicio() {}

    /** Archivo ya validado y leído, listo para iniciar la importación. */
    public static final class Preparada {
        private final byte[] datos;
        private final String nombre;
        private final Resultado resultado;

        private Preparada(byte[] datos, String nombre, Resultado resultado) {
            this.datos = datos;
            this.nombre = nombre;
            this.resultado = resultado;
        }

        public Resultado getResultado() { return resultado; }
    }

    public static boolean hayArchivo(Part p) {
        return p != null && p.getSize() > 0;
    }

    /** Valida el contenido (cabecera, tamaño, texto) y lo divide en capítulos. */
    public static Preparada preparar(Part p) {
        if (p.getSize() > ImportadorCapitulos.MAX_ARCHIVO) {
            throw new IllegalArgumentException(
                "El archivo supera el máximo de "
                + (ImportadorCapitulos.MAX_ARCHIVO / 1024 / 1024) + " MB.");
        }

        byte[] datos;
        try (InputStream in = p.getInputStream()) {
            // Un byte de más para detectar archivos que superan el límite
            datos = in.readNBytes((int) ImportadorCapitulos.MAX_ARCHIVO + 1);
        } catch (IOException e) {
            throw new IllegalArgumentException(
                "No se pudo leer el archivo de capítulos.");
        }

        Resultado r = ImportadorCapitulos.leer(datos);

        String nombre = nombreSeguro(p.getSubmittedFileName());
        if (nombre == null) {
            nombre = "archivo." + r.getTipo().extension();
        }

        return new Preparada(datos, nombre, r);
    }

    /**
     * Guarda el archivo y deja la importación en revisión.
     *
     * @return el id de la importación
     */
    public static long iniciar(Preparada prep, long autorId, long obraId)
            throws SQLException {

        Resultado r = prep.resultado;

        // Comprobaciones previas para dar un mensaje claro antes de escribir en disco.
        if (dao.enRevision(obraId, autorId) != null) {
            throw new IllegalArgumentException(
                "Ya tienes una importación en revisión en esta obra. "
                + "Confírmala o recházala antes de subir otro archivo.");
        }
        if (dao.existeHash(obraId, r.getSha256())) {
            throw new IllegalArgumentException(
                "Este archivo ya se importó en esta obra.");
        }

        String archivo;
        try {
            archivo = ImportacionArchivos.guardar(prep.datos);
        } catch (IOException e) {
            throw new SQLException("No se pudo guardar el archivo importado.", e);
        }

        try {
            return dao.registrar(obraId, autorId, prep.nombre,
                    prep.datos.length, r.getSha256(), archivo,
                    r.getCapitulos());
        } catch (SQLException | RuntimeException e) {
            // Sin registro en la BD el archivo quedaría huérfano en disco
            ImportacionArchivos.borrar(archivo);
            throw e;
        }
    }

    /** La importación en revisión de la obra (o null). */
    public static Map<String, Object> pendiente(long obraId, long autorId)
            throws SQLException {
        return dao.enRevision(obraId, autorId);
    }

    /** Los capítulos guardados de la importación, en el orden del archivo. */
    public static List<Capitulo> capitulos(Map<String, Object> imp,
            long autorId) throws SQLException {
        return dao.capitulos((Long) imp.get("id"), autorId);
    }

    /**
     * Publica los capítulos en orden y borra el archivo.
     *
     * @return cuántos capítulos se publicaron
     */
    public static int confirmar(Map<String, Object> imp, long autorId,
            long obraId) throws SQLException {

        int total = dao.confirmar((Long) imp.get("id"), autorId, obraId);

        ImportacionArchivos.borrar((String) imp.get("archivo"));
        return total;
    }

    /** Descarta la importación (borra sus borradores) y borra el archivo. */
    public static void rechazar(Map<String, Object> imp, long autorId,
            long obraId) throws SQLException {

        dao.rechazar((Long) imp.get("id"), autorId, obraId,
                "Rechazada por el autor.");
        ImportacionArchivos.borrar((String) imp.get("archivo"));
    }

    /** Nombre solo para mostrar: sin carpetas ni caracteres de control, máx. 255. */
    static String nombreSeguro(String enviado) {
        if (enviado == null) {
            return null;
        }
        String n = enviado.replace('\\', '/');
        n = n.substring(n.lastIndexOf('/') + 1)
                .replaceAll("\\p{Cntrl}", "").strip();
        if (n.isEmpty()) {
            return null;
        }
        return n.length() <= 255 ? n : n.substring(0, 255);
    }
}