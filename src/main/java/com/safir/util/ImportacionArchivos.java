package com.safir.util;

import java.io.IOException;
import java.nio.file.FileAlreadyExistsException;
import java.nio.file.Files;
import java.nio.file.InvalidPathException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.PosixFilePermissions;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Guarda temporalmente el archivo subido mientras el autor revisa la
 * importación.
 *
 * - Carpeta propia, FUERA de la raíz que sirve MediaServlet (ImagenUtil.RAIZ)
 *   y fuera de la carpeta pública de la aplicación.
 * - Nombre aleatorio (UUID) sin extensión: el nombre original nunca interviene
 *   en la ruta. El tipo real queda en la base de datos.
 */
public final class ImportacionArchivos {

    public static final Path RAIZ = Paths.get(
            System.getenv().getOrDefault("SAFIR_IMPORTACIONES",
                    System.getProperty("user.home") + "/safir-importaciones"))
            .toAbsolutePath().normalize();

    private static final Pattern NOMBRE_VALIDO = Pattern.compile(
            "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.bin");

    private ImportacionArchivos() {}

    /** Guarda los bytes y devuelve el nombre aleatorio generado. */
    public static String guardar(byte[] datos) throws IOException {
        if (RAIZ.startsWith(ImagenUtil.RAIZ) || ImagenUtil.RAIZ.startsWith(RAIZ)) {
            // Si la carpeta de importaciones quedara dentro de /media, se podría descargar.
            throw new IOException("SAFIR_IMPORTACIONES no puede estar dentro de SAFIR_UPLOADS.");
        }

        Files.createDirectories(RAIZ);
        restringir(RAIZ);

        for (int intento = 0; intento < 3; intento++) {
            String nombre = UUID.randomUUID() + ".bin";
            try {
                Files.write(RAIZ.resolve(nombre), datos,
                        StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
                return nombre;
            } catch (FileAlreadyExistsException e) {
                // UUID repetido: prácticamente imposible; se reintenta
            }
        }
        throw new IOException("No se pudo crear un nombre de archivo único.");
    }

    /** Lee el archivo guardado; null si ya no existe. */
    public static byte[] leer(String nombre) throws IOException {
        Path p = resolver(nombre);
        return p != null && Files.isRegularFile(p) ? Files.readAllBytes(p) : null;
    }

    /** Borra el archivo del disco; no falla si ya no estaba. */
    public static void borrar(String nombre) {
        try {
            Path p = resolver(nombre);
            if (p != null) {
                Files.deleteIfExists(p);
            }
        } catch (IOException ignored) {
        }
    }

    /** Solo acepta nombres con forma de UUID.bin y que caigan dentro de RAIZ. */
    private static Path resolver(String nombre) {
        if (nombre == null || !NOMBRE_VALIDO.matcher(nombre).matches()) {
            return null;
        }
        try {
            Path p = RAIZ.resolve(nombre).normalize();
            return p.startsWith(RAIZ) ? p : null;
        } catch (InvalidPathException e) {
            return null;
        }
    }

    private static void restringir(Path carpeta) {
        try {
            Files.setPosixFilePermissions(carpeta,
                    PosixFilePermissions.fromString("rwx------"));
        } catch (UnsupportedOperationException | IOException ignored) {
            // Windows: los permisos POSIX no existen; se usa la herencia de la carpeta
        }
    }
}