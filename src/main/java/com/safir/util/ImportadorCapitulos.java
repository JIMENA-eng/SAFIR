package com.safir.util;

import com.safir.modelo.Capitulo;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.List;

/**
 * Lee un archivo (PDF, DOCX, DOC o TXT) y lo separa en capítulos.
 *
 * Pasos: 1) el tipo se decide por los bytes de cabecera, nunca por la extensión;
 * 2) ExtractorTexto saca el texto según el formato; 3) SeparadorCapitulos lo
 * corta en capítulos.
 *
 * Los errores de contenido se informan con IllegalArgumentException, cuyo
 * mensaje se puede mostrar tal cual al autor.
 */
public final class ImportadorCapitulos {

    public static final long MAX_ARCHIVO = 20L * 1024 * 1024;

    public enum Tipo {
        PDF("pdf"), DOCX("docx"), DOC("doc"), TXT("txt");

        private final String extension;

        Tipo(String extension) { this.extension = extension; }

        public String extension() { return extension; }

        public static Tipo deExtension(String valor) {
            for (Tipo t : values()) {
                if (t.extension.equals(valor)) return t;
            }
            throw new IllegalArgumentException("Tipo de archivo desconocido.");
        }
    }

    /** Resultado de leer un archivo. */
    public static final class Resultado {
        private final Tipo tipo;
        private final String sha256;
        private final List<Capitulo> capitulos;
        private final boolean capituloUnico;
        private final int palabrasDescartadas;

        Resultado(Tipo tipo, String sha256, SeparadorCapitulos.Division d) {
            this.tipo = tipo;
            this.sha256 = sha256;
            this.capitulos = d.capitulos;
            this.capituloUnico = d.capituloUnico;
            this.palabrasDescartadas = d.palabrasDescartadas;
        }

        public Tipo getTipo() { return tipo; }
        public String getSha256() { return sha256; }
        public List<Capitulo> getCapitulos() { return capitulos; }

        /** true si no se halló ningún encabezado y todo quedó en un capítulo. */
        public boolean isCapituloUnico() { return capituloUnico; }

        /** Palabras de portada/índice/prólogo anteriores al primer capítulo. */
        public int getPalabrasDescartadas() { return palabrasDescartadas; }
    }

    private ImportadorCapitulos() {}

    // ---- API pública --------------------------------------------------------

    /** Valida, lee y divide en capítulos. Lanza IllegalArgumentException con el motivo. */
    public static Resultado leer(byte[] datos) {
        if (datos == null || datos.length == 0) {
            throw new IllegalArgumentException("El archivo está vacío.");
        }

        if (datos.length > MAX_ARCHIVO) {
            throw new IllegalArgumentException(
                "El archivo supera el máximo de "
                + (MAX_ARCHIVO / 1024 / 1024) + " MB.");
        }

        Tipo tipo = detectar(datos);
        String texto;

        switch (tipo) {
            case PDF:  texto = ExtractorTexto.pdf(datos);  break;
            case DOCX: texto = ExtractorTexto.docx(datos); break;
            case DOC:  texto = ExtractorTexto.doc(datos);  break;
            default:   texto = textoPlano(datos);          break;
        }

        texto = SeparadorCapitulos.normalizar(texto);

        if (texto.isBlank()) {
            throw new IllegalArgumentException(tipo == Tipo.PDF
                ? "El PDF no tiene texto seleccionable (¿es un escaneo?)."
                : "El archivo no tiene texto.");
        }

        return new Resultado(tipo, sha256(datos),
                SeparadorCapitulos.dividir(texto, tipo));
    }

    /** SHA-256 en hexadecimal (64 caracteres, minúsculas). */
    public static String sha256(byte[] datos) {
        try {
            byte[] h = MessageDigest.getInstance("SHA-256").digest(datos);
            StringBuilder sb = new StringBuilder(64);
            for (byte b : h) {
                sb.append(Character.forDigit((b >> 4) & 0xF, 16))
                  .append(Character.forDigit(b & 0xF, 16));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    // ---- Tipo de archivo (por contenido) ------------------------------------

    static Tipo detectar(byte[] d) {
        // PDF: empieza con "%PDF"
        if (empiezaCon(d, '%', 'P', 'D', 'F')) {
            return Tipo.PDF;
        }

        // DOCX es un ZIP: "PK" 03 04. Que realmente sea Word lo comprueba POI.
        if (empiezaCon(d, 'P', 'K', 3, 4)) {
            return Tipo.DOCX;
        }

        // DOC antiguo (contenedor OLE2): D0 CF 11 E0
        if (empiezaCon(d, 0xD0, 0xCF, 0x11, 0xE0)) {
            return Tipo.DOC;
        }

        // TXT no tiene cabecera: se rechaza si hay bytes binarios en cualquier parte.
        if (tieneBytesBinarios(d)) {
            throw new IllegalArgumentException(
                "Formato no permitido. Sube un PDF, DOCX, DOC o TXT.");
        }

        return Tipo.TXT;
    }

    private static boolean empiezaCon(byte[] d, int... esperado) {
        if (d.length < esperado.length) return false;
        for (int i = 0; i < esperado.length; i++) {
            if ((d[i] & 0xFF) != esperado[i]) return false;
        }
        return true;
    }

    /**
     * Texto válido: nada por debajo de 0x20 salvo tabulador, salto de línea,
     * retorno y salto de página (ni NUL ni otros controles). Los bytes altos
     * (UTF-8 o Windows-1252) son normales en español.
     */
    private static boolean tieneBytesBinarios(byte[] d) {
        for (byte b : d) {
            int v = b & 0xFF;
            if (v < 0x20 && v != '\t' && v != '\n' && v != '\r' && v != '\f') {
                return true;
            }
            if (v == 0x7F) {
                return true;
            }
        }
        return false;
    }

    // ---- TXT ----------------------------------------------------------------

    /**
     * UTF-8 estricto; si hay bytes que no son UTF-8 válido se prueba con el
     * juego de caracteres de Windows (Bloc de notas antiguo), para que no se
     * rompan las tildes.
     *
     * Se usa windows-1252 y no ISO-8859-1 a propósito: las dos coinciden en
     * á é í ó ú ñ ¿ ¡, pero en ISO-8859-1 los bytes 0x80–0x9F son caracteres
     * de control y se perderían las comillas “ ” ‘ ’, la raya — y los puntos
     * suspensivos … que tanto usan los textos literarios.
     */
    static String textoPlano(byte[] datos) {
        try {
            return StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(datos)).toString();
        } catch (CharacterCodingException e) {
            return new String(datos, Charset.forName("windows-1252"));
        }
    }
}