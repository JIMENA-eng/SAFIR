package com.safir.util;

import jakarta.servlet.http.Part;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Música de los capítulos: archivos de audio subidos por el autor y enlaces
 * de YouTube. Los archivos se guardan en la misma carpeta que las imágenes
 * (SAFIR_UPLOADS), dentro de "audio/", y se sirven por /media/audio/...
 */
public final class AudioUtil {

    public static final String CARPETA = "audio";

    /** Igual que el maxFileSize de GestionCapituloServlet. */
    public static final long MAX_AUDIO = 20L * 1024 * 1024;

    public static final String FORMATOS = "MP3, M4A, AAC, OGG o WAV";

    private static final Pattern ID_YOUTUBE =
            Pattern.compile("[A-Za-z0-9_-]{11}");

    private static final Set<String> HOSTS_YOUTUBE = Set.of(
            "youtube.com", "www.youtube.com", "m.youtube.com",
            "music.youtube.com", "youtube-nocookie.com",
            "www.youtube-nocookie.com");

    private AudioUtil() {}

    public static boolean hayArchivo(Part p) {
        return p != null && p.getSize() > 0;
    }

    // ---- Archivos de audio ---------------------------------------------

    /**
     * Revisa los primeros bytes del archivo (no se confía en la extensión)
     * y devuelve la extensión real, o lanza IllegalArgumentException.
     */
    public static String validar(Part p) throws IOException {
        if (p.getSize() > MAX_AUDIO) {
            throw new IllegalArgumentException(
                "El audio supera el máximo de " + (MAX_AUDIO / 1024 / 1024) + " MB.");
        }

        byte[] b;
        try (InputStream in = p.getInputStream()) {
            b = in.readNBytes(12);
        }

        String ext = detectar(b);
        if (ext == null) {
            throw new IllegalArgumentException(
                "Formato de audio no permitido. Usa " + FORMATOS + ".");
        }
        return ext;
    }

    static String detectar(byte[] b) {
        if (b.length >= 3 && b[0] == 'I' && b[1] == 'D' && b[2] == '3') {
            return "mp3";                                   // MP3 con etiqueta ID3
        }
        if (b.length >= 2 && (b[0] & 0xFF) == 0xFF) {
            int b1 = b[1] & 0xFF;
            if ((b1 & 0xF6) == 0xF0) {
                return "aac";                               // AAC en bruto (ADTS)
            }
            if ((b1 & 0xE0) == 0xE0 && (b1 & 0x06) != 0) {
                return "mp3";                               // MP3 sin etiqueta
            }
        }
        if (b.length >= 8 && b[4] == 'f' && b[5] == 't' && b[6] == 'y' && b[7] == 'p') {
            return "m4a";                                   // M4A / MP4
        }
        if (b.length >= 4 && b[0] == 'O' && b[1] == 'g' && b[2] == 'g' && b[3] == 'S') {
            return "ogg";
        }
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'A' && b[10] == 'V' && b[11] == 'E') {
            return "wav";
        }
        return null;
    }

    /** Guarda el audio y devuelve la ruta relativa, ej. "audio/12-uuid.mp3". */
    public static String guardar(Part p, long autorId) throws IOException {
        String ext = validar(p);
        String nombre = autorId + "-" + UUID.randomUUID() + "." + ext;
        Path destino = ImagenUtil.RAIZ.resolve(CARPETA).resolve(nombre).normalize();
        Files.createDirectories(destino.getParent());
        try (InputStream in = p.getInputStream()) {
            Files.copy(in, destino, StandardCopyOption.REPLACE_EXISTING);
        }
        return CARPETA + "/" + nombre;
    }

    /** Nombre que se mostrará: el del archivo sin la extensión. */
    public static String tituloDesdeArchivo(Part p) {
        String nombre = p.getSubmittedFileName();
        if (nombre == null) {
            return "Audio del capítulo";
        }
        nombre = nombre.replace('\\', '/');
        nombre = nombre.substring(nombre.lastIndexOf('/') + 1);
        int punto = nombre.lastIndexOf('.');
        if (punto > 0) {
            nombre = nombre.substring(0, punto);
        }
        nombre = nombre.strip();
        if (nombre.isEmpty()) {
            return "Audio del capítulo";
        }
        return nombre.length() > 150 ? nombre.substring(0, 150) : nombre;
    }

    public static String tipoMime(String ruta) {
        String n = ruta.toLowerCase(Locale.ROOT);
        if (n.endsWith(".mp3")) return "audio/mpeg";
        if (n.endsWith(".m4a")) return "audio/mp4";
        if (n.endsWith(".aac")) return "audio/aac";
        if (n.endsWith(".ogg")) return "audio/ogg";
        if (n.endsWith(".wav")) return "audio/wav";
        return null;
    }

    // ---- YouTube --------------------------------------------------------

    /**
     * Saca el id del video de un enlace de YouTube (watch?v=, youtu.be/,
     * shorts/, embed/, live/). Devuelve null si el enlace no es de YouTube.
     */
    public static String youtubeId(String enlace) {
        if (enlace == null) {
            return null;
        }
        String texto = enlace.strip();
        if (texto.isEmpty() || texto.length() > 500) {
            return null;
        }
        if (!texto.matches("(?i)^https?://.*")) {
            texto = "https://" + texto;
        }

        URI uri;
        try {
            uri = new URI(texto);
        } catch (URISyntaxException e) {
            return null;
        }

        String host = uri.getHost();
        String ruta = uri.getPath() == null ? "" : uri.getPath();
        if (host == null) {
            return null;
        }
        host = host.toLowerCase(Locale.ROOT);

        String id = null;

        if (host.equals("youtu.be") || host.equals("www.youtu.be")) {
            id = primerTramo(ruta);
        } else if (HOSTS_YOUTUBE.contains(host)) {
            if (ruta.equals("/watch")) {
                id = parametro(uri.getRawQuery(), "v");
            } else {
                for (String prefijo : new String[] {"/shorts/", "/embed/", "/live/", "/v/"}) {
                    if (ruta.startsWith(prefijo)) {
                        id = primerTramo(ruta.substring(prefijo.length() - 1));
                        break;
                    }
                }
            }
        }

        return id != null && ID_YOUTUBE.matcher(id).matches() ? id : null;
    }

    /** Enlace normalizado que se guarda en la base. */
    public static String enlaceYoutube(String id) {
        return "https://www.youtube.com/watch?v=" + id;
    }

    private static String primerTramo(String ruta) {
        String r = ruta.startsWith("/") ? ruta.substring(1) : ruta;
        int fin = r.indexOf('/');
        return fin >= 0 ? r.substring(0, fin) : r;
    }

    private static String parametro(String query, String nombre) {
        if (query == null) {
            return null;
        }
        for (String par : query.split("&")) {
            if (par.startsWith(nombre + "=")) {
                return par.substring(nombre.length() + 1);
            }
        }
        return null;
    }
}