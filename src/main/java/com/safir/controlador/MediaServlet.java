package com.safir.controlador;

import com.safir.util.AudioUtil;
import com.safir.util.ImagenUtil;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.*;

/**
 * Sirve las imágenes (avatar, portada) y los audios de los capítulos que están
 * en SAFIR_UPLOADS. Los audios admiten peticiones "Range" para que el
 * reproductor del navegador pueda adelantar y retroceder.
 */
@WebServlet("/media/*")
public class MediaServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String info = req.getPathInfo();
        if (info == null || info.length() < 2) { resp.sendError(404); return; }
        Path f;
        try { f = ImagenUtil.RAIZ.resolve(info.substring(1)).normalize(); }
        catch (InvalidPathException e) { resp.sendError(404); return; }
        if (!f.startsWith(ImagenUtil.RAIZ) || !Files.isRegularFile(f)) { resp.sendError(404); return; }

        String n = f.getFileName().toString().toLowerCase();
        String tipo = n.endsWith(".png") ? "image/png" : n.endsWith(".webp") ? "image/webp"
                    : n.endsWith(".jpg") ? "image/jpeg" : null;
        boolean esAudio = false;
        if (tipo == null && f.startsWith(ImagenUtil.RAIZ.resolve(AudioUtil.CARPETA))) {
            tipo = AudioUtil.tipoMime(n);
            esAudio = tipo != null;
        }
        if (tipo == null) { resp.sendError(404); return; }

        long largo = Files.size(f);
        resp.setContentType(tipo);
        resp.setHeader("Cache-Control", "public, max-age=86400");
        resp.setHeader("X-Content-Type-Options", "nosniff");

        if (!esAudio) {
            resp.setContentLengthLong(largo);
            Files.copy(f, resp.getOutputStream());
            return;
        }

        resp.setHeader("Accept-Ranges", "bytes");
        long[] rango = leerRango(req.getHeader("Range"), largo);

        if (rango == null) {                       // archivo completo
            resp.setContentLengthLong(largo);
            Files.copy(f, resp.getOutputStream());
            return;
        }
        if (rango.length == 0) {                   // rango imposible
            resp.setHeader("Content-Range", "bytes */" + largo);
            resp.sendError(HttpServletResponse.SC_REQUESTED_RANGE_NOT_SATISFIABLE);
            return;
        }

        long inicio = rango[0], fin = rango[1], cuantos = fin - inicio + 1;
        resp.setStatus(HttpServletResponse.SC_PARTIAL_CONTENT);
        resp.setHeader("Content-Range", "bytes " + inicio + "-" + fin + "/" + largo);
        resp.setContentLengthLong(cuantos);

        try (InputStream in = Files.newInputStream(f)) {
            in.skipNBytes(inicio);
            OutputStream out = resp.getOutputStream();
            byte[] buffer = new byte[64 * 1024];
            while (cuantos > 0) {
                int leidos = in.read(buffer, 0, (int) Math.min(buffer.length, cuantos));
                if (leidos < 0) break;
                out.write(buffer, 0, leidos);
                cuantos -= leidos;
            }
        }
    }

    /**
     * null = sin Range (o uno que no entendemos: se envía todo);
     * arreglo vacío = rango fuera del archivo; si no, {inicio, fin}.
     */
    private static long[] leerRango(String cabecera, long largo) {
        if (cabecera == null || !cabecera.startsWith("bytes=") || cabecera.contains(",")) {
            return null;
        }
        String r = cabecera.substring(6).trim();
        int guion = r.indexOf('-');
        if (guion < 0) return null;
        try {
            long inicio, fin;
            String a = r.substring(0, guion).trim(), b = r.substring(guion + 1).trim();
            if (a.isEmpty()) {                     // "-500": los últimos 500 bytes
                long ultimos = Long.parseLong(b);
                if (ultimos <= 0) return new long[0];
                inicio = Math.max(0, largo - ultimos);
                fin = largo - 1;
            } else {
                inicio = Long.parseLong(a);
                fin = b.isEmpty() ? largo - 1 : Math.min(Long.parseLong(b), largo - 1);
            }
            if (inicio < 0 || inicio >= largo || fin < inicio) return new long[0];
            return new long[] {inicio, fin};
        } catch (NumberFormatException e) {
            return null;
        }
    }
}