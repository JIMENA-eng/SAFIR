package com.safir.util;

import jakarta.servlet.http.Part;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.util.UUID;

public final class ImagenUtil {

    public static final Path RAIZ = Paths.get(
            System.getenv().getOrDefault("SAFIR_UPLOADS",
                    System.getProperty("user.home") + "/safir-uploads"))
            .toAbsolutePath().normalize();

    public static final long MAX_AVATAR  = 2L * 1024 * 1024;
    public static final long MAX_PORTADA = 5L * 1024 * 1024;

    private ImagenUtil() {}

    public static boolean hayArchivo(Part p) {
        return p != null && p.getSize() > 0;
    }

    /** Devuelve la extensión real (jpg/png/webp) o lanza IllegalArgumentException. */
    public static String validar(Part p, long maxBytes) throws IOException {
        if (p.getSize() > maxBytes) {
            throw new IllegalArgumentException(
                "La imagen supera el máximo de " + (maxBytes / 1024 / 1024) + " MB.");
        }
        byte[] b;
        try (InputStream in = p.getInputStream()) { b = in.readNBytes(12); }
        if (b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8
                && (b[2] & 0xFF) == 0xFF) return "jpg";
        if (b.length >= 4 && (b[0] & 0xFF) == 0x89 && b[1] == 'P'
                && b[2] == 'N' && b[3] == 'G') return "png";
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') return "webp";
        throw new IllegalArgumentException("Formato no permitido. Usa JPG, PNG o WebP.");
    }

    /** Guarda y devuelve la ruta relativa, ej. "avatar/12-uuid.jpg". */
    public static String guardar(Part p, String carpeta, long usuarioId, long maxBytes)
            throws IOException {
        String ext = validar(p, maxBytes);
        String nombre = usuarioId + "-" + UUID.randomUUID() + "." + ext;
        Path destino = RAIZ.resolve(carpeta).resolve(nombre).normalize();
        Files.createDirectories(destino.getParent());
        try (InputStream in = p.getInputStream()) {
            Files.copy(in, destino, StandardCopyOption.REPLACE_EXISTING);
        }
        return carpeta + "/" + nombre;
    }

    public static void borrar(String rutaRelativa) {
        if (rutaRelativa == null || rutaRelativa.isBlank()) return;
        try {
            Path p = RAIZ.resolve(rutaRelativa).normalize();
            if (p.startsWith(RAIZ)) Files.deleteIfExists(p);
        } catch (IOException | InvalidPathException ignored) { }
    }
}