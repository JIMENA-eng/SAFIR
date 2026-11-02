package com.safir.controlador;

import com.safir.util.ImagenUtil;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.nio.file.*;

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
        if (tipo == null) { resp.sendError(404); return; }

        resp.setContentType(tipo);
        resp.setContentLengthLong(Files.size(f));
        resp.setHeader("Cache-Control", "public, max-age=86400");
        resp.setHeader("X-Content-Type-Options", "nosniff");
        Files.copy(f, resp.getOutputStream());
    }
}