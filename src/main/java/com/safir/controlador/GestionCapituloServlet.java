package com.safir.controlador;

import com.safir.dao.GestionCapituloDAO;
import com.safir.dao.MusicaCapituloDAO;
import com.safir.dao.ObraEdicionDAO;
import com.safir.modelo.Capitulo;
import com.safir.modelo.PistaCapitulo;
import com.safir.util.AudioUtil;
import com.safir.util.EncabezadoUtil;
import com.safir.util.ImagenUtil;
import com.safir.util.ImportacionServicio;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

@WebServlet(urlPatterns = {
    "/autor/capitulos",
    "/autor/capitulo/nuevo",
    "/autor/capitulo/editar",
    "/autor/capitulo/publicar",
    "/autor/capitulos/importar",
    "/autor/capitulos/importar/revision",
    "/autor/capitulos/importar/confirmar",
    "/autor/capitulos/importar/rechazar"
})
// Reciben archivos: "importar" (PDF/DOCX/DOC/TXT) y el editor de capítulo (audio).
// maxRequestSize deja espacio para el texto del capítulo junto al audio de 20 MB.
@MultipartConfig(maxFileSize = 20 * 1024 * 1024, maxRequestSize = 24 * 1024 * 1024)
public class GestionCapituloServlet extends HttpServlet {

    private final GestionCapituloDAO dao = new GestionCapituloDAO();
    private final ObraEdicionDAO obraDao = new ObraEdicionDAO();
    private final MusicaCapituloDAO musicaDao = new MusicaCapituloDAO();

    // Valores del grupo de opciones "Música del capítulo" en editor.jsp
    private static final String OPCION_MANTENER = "mantener";
    private static final String OPCION_NINGUNA = "ninguna";
    private static final String OPCION_YOUTUBE = "youtube";
    private static final String OPCION_ARCHIVO = "archivo";

    private Long usuarioId(HttpServletRequest request) {
        HttpSession sesion = request.getSession(false);

        if (sesion == null) {
            return null;
        }

        Object valor = sesion.getAttribute("usuarioId");

        if (valor instanceof Number) {
            return ((Number) valor).longValue();
        }

        if (valor instanceof String) {
            try {
                return Long.parseLong((String) valor);
            } catch (NumberFormatException e) {
                return null;
            }
        }

        return null;
    }

    private boolean esAutor(HttpServletRequest request) {
        HttpSession sesion = request.getSession(false);

        if (sesion == null) {
            return false;
        }

        Object roles = sesion.getAttribute("roles");

        if (roles instanceof String) {
            for (String rol : ((String) roles).split(",")) {
                if ("autor".equalsIgnoreCase(rol.trim())) {
                    return true;
                }
            }
        }

        if (roles instanceof Collection<?>) {
            for (Object rol : (Collection<?>) roles) {
                if (rol != null
                        && "autor".equalsIgnoreCase(rol.toString().trim())) {
                    return true;
                }
            }
        }

        return false;
    }

    private Long parametroPositivo(
            HttpServletRequest request, String nombre) {

        String valor = request.getParameter(nombre);

        if (valor == null || valor.isBlank()) {
            return null;
        }

        try {
            long numero = Long.parseLong(valor);
            return numero > 0 ? numero : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private boolean autorizar(
            HttpServletRequest request,
            HttpServletResponse response) throws IOException {

        if (usuarioId(request) == null) {
            response.sendRedirect(
                request.getContextPath() + "/login");
            return false;
        }

        if (!esAutor(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "No tienes permiso para administrar capítulos.");
            return false;
        }

        return true;
    }

    /** Carga y muestra la lista de capítulos; errorImportacion puede ser null. */
    private void mostrarLista(
            HttpServletRequest request,
            HttpServletResponse response,
            long obraId,
            long autorId,
            String errorImportacion)
            throws SQLException, ServletException, IOException {

        if (!dao.perteneceAlAutor(obraId, autorId)) {
            response.sendError(
                HttpServletResponse.SC_NOT_FOUND,
                "La obra no existe o no te pertenece.");
            return;
        }

        List<Capitulo> capitulos = dao.listarPorObra(obraId, autorId);

        EncabezadoUtil.cargar(request, autorId);
        request.setAttribute("obra", obraDao.obtenerPropia(obraId, autorId));
        request.setAttribute("obraId", obraId);
        request.setAttribute("capitulos", capitulos);
        request.setAttribute("errorImportacion", errorImportacion);
        request.setAttribute("importacionPendiente",
                ImportacionServicio.pendiente(obraId, autorId));

        request.getRequestDispatcher(
            "/WEB-INF/vistas/autor/capitulos.jsp"
        ).forward(request, response);
    }

    /**
     * Paso 1 de la importación: valida y lee el archivo (PDF, DOCX, DOC o TXT),
     * lo guarda con nombre aleatorio y deja la importación "en revisión".
     * Los capítulos quedan como borradores ocultos, ligados a la importación;
     * el autor los revisa y confirma en /autor/capitulos/importar/revision. El obraId viaja en la URL (no en el
     * cuerpo multipart) para poder volver a la lista aunque el archivo sea
     * demasiado grande.
     */
    private void importarDesdeArchivo(
            HttpServletRequest request,
            HttpServletResponse response,
            long autorId)
            throws SQLException, ServletException, IOException {

        Long obraId = parametroPositivo(request, "obraId");

        if (obraId == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "El ID de la obra no es válido.");
            return;
        }

        if (!dao.perteneceAlAutor(obraId, autorId)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND,
                    "La obra no existe o no te pertenece.");
            return;
        }

        Part archivo = null;
        String error = null;

        try {
            archivo = request.getPart("capitulosArchivo");
        } catch (IllegalStateException e) {
            error = "El archivo supera el máximo de 20 MB.";
        }

        if (error == null && !ImportacionServicio.hayArchivo(archivo)) {
            error = "Selecciona un archivo PDF, DOCX, DOC o TXT.";
        }

        if (error == null) {
            try {
                ImportacionServicio.iniciar(
                    ImportacionServicio.preparar(archivo), autorId, obraId);
            } catch (IllegalArgumentException e) {
                error = e.getMessage();
            }
        }

        if (error != null) {
            mostrarLista(request, response, obraId, autorId, error);
            return;
        }

        response.sendRedirect(
            request.getContextPath()
            + "/autor/capitulos/importar/revision?obraId=" + obraId);
    }

    /** Paso 2: vista previa de los capítulos detectados, con Confirmar / Rechazar. */
    private void mostrarRevision(
            HttpServletRequest request,
            HttpServletResponse response,
            long autorId)
            throws SQLException, ServletException, IOException {

        Long obraId = parametroPositivo(request, "obraId");

        if (obraId == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "El ID de la obra no es válido.");
            return;
        }

        if (!dao.perteneceAlAutor(obraId, autorId)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND,
                    "La obra no existe o no te pertenece.");
            return;
        }

        Map<String, Object> imp = ImportacionServicio.pendiente(obraId, autorId);

        if (imp == null) {
            response.sendRedirect(request.getContextPath()
                    + "/autor/capitulos?obraId=" + obraId);
            return;
        }

        List<Map<String, Object>> vista = new ArrayList<>();
        int numero = 1;

        for (Capitulo c : ImportacionServicio.capitulos(imp, autorId)) {
            String texto = c.getContenido();
            Map<String, Object> fila = new java.util.HashMap<>();
            fila.put("numero", numero++);
            fila.put("titulo", c.getTitulo());
            fila.put("palabras", texto.isBlank()
                    ? 0 : texto.trim().split("\\s+").length);
            fila.put("extracto", texto.length() <= 220
                    ? texto : texto.substring(0, 220).strip() + "…");
            vista.add(fila);
        }

        EncabezadoUtil.cargar(request, autorId);
        request.setAttribute("obra", obraDao.obtenerPropia(obraId, autorId));
        request.setAttribute("obraId", obraId);
        request.setAttribute("importacion", imp);
        request.setAttribute("vista", vista);

        request.getRequestDispatcher(
            "/WEB-INF/vistas/autor/importacion-revision.jsp"
        ).forward(request, response);
    }

    /** Paso 3a: publica los capítulos en orden y borra el archivo. */
    private void confirmarImportacion(
            HttpServletRequest request,
            HttpServletResponse response,
            long autorId)
            throws SQLException, ServletException, IOException {

        Long obraId = parametroPositivo(request, "obraId");

        if (obraId == null || !dao.perteneceAlAutor(obraId, autorId)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND,
                    "La obra no existe o no te pertenece.");
            return;
        }

        Map<String, Object> imp = ImportacionServicio.pendiente(obraId, autorId);

        if (imp == null) {
            response.sendRedirect(request.getContextPath()
                    + "/autor/capitulos?obraId=" + obraId);
            return;
        }

        try {
            int total = ImportacionServicio.confirmar(imp, autorId, obraId);

            response.sendRedirect(
                request.getContextPath()
                + "/autor/capitulos?obraId=" + obraId
                + "&importados=" + total);

        } catch (IllegalArgumentException e) {
            mostrarLista(request, response, obraId, autorId, e.getMessage());
        }
    }

    /** Paso 3b: descarta la importación (borra sus borradores) y borra el archivo. */
    private void rechazarImportacion(
            HttpServletRequest request,
            HttpServletResponse response,
            long autorId)
            throws SQLException, ServletException, IOException {

        Long obraId = parametroPositivo(request, "obraId");

        if (obraId == null || !dao.perteneceAlAutor(obraId, autorId)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND,
                    "La obra no existe o no te pertenece.");
            return;
        }

        Map<String, Object> imp = ImportacionServicio.pendiente(obraId, autorId);

        if (imp != null) {
            ImportacionServicio.rechazar(imp, autorId, obraId);
        }

        response.sendRedirect(
            request.getContextPath()
            + "/autor/capitulos?obraId=" + obraId + "&importacionRechazada=1");
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        if (!autorizar(request, response)) {
            return;
        }

        long autorId = usuarioId(request);
        String ruta = request.getServletPath();

        try {
            if ("/autor/capitulos".equals(ruta)) {
                Long obraId = parametroPositivo(request, "obraId");

                if (obraId == null) {
                    response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "El ID de la obra no es válido.");
                    return;
                }

                mostrarLista(request, response, obraId, autorId, null);
                return;
            }

            if ("/autor/capitulos/importar/revision".equals(ruta)) {
                mostrarRevision(request, response, autorId);
                return;
            }

            if ("/autor/capitulos/importar".equals(ruta)
                    || "/autor/capitulos/importar/confirmar".equals(ruta)
                    || "/autor/capitulos/importar/rechazar".equals(ruta)) {
                response.sendError(
                    HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                    "La importación debe realizarse mediante POST.");
                return;
            }

            if ("/autor/capitulo/publicar".equals(ruta)) {
                response.sendError(
                    HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                    "La publicación debe realizarse mediante POST.");
                return;
            }

            Capitulo capitulo = null;
            Long obraId;

            if ("/autor/capitulo/editar".equals(ruta)) {
                Long capituloId = parametroPositivo(request, "id");

                if (capituloId == null) {
                    response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "El ID del capítulo no es válido.");
                    return;
                }

                capitulo = dao.obtenerPropio(capituloId, autorId);

                if (capitulo == null) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "El capítulo no existe o no te pertenece.");
                    return;
                }

                if (!"borrador".equals(capitulo.getEstado())) {
                    response.sendError(
                        HttpServletResponse.SC_FORBIDDEN,
                        "Solo puedes editar capítulos en borrador.");
                    return;
                }

                obraId = capitulo.getObraId();
            } else {
                obraId = parametroPositivo(request, "obraId");

                if (obraId == null) {
                    response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "El ID de la obra no es válido.");
                    return;
                }

                if (!dao.perteneceAlAutor(obraId, autorId)) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "La obra no existe o no te pertenece.");
                    return;
                }
            }

            EncabezadoUtil.cargar(request, autorId);
            request.setAttribute("obraId", obraId);
            request.setAttribute("capitulo", capitulo);

            if (capitulo != null) {
                request.setAttribute("pista", musicaDao.obtener(capitulo.getId()));
            }

            request.getRequestDispatcher(
                "/WEB-INF/vistas/autor/editor.jsp"
            ).forward(request, response);

        } catch (SQLException e) {
            throw new ServletException(
                "Error al consultar los capítulos.", e);
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        if (!autorizar(request, response)) {
            return;
        }

        long autorId = usuarioId(request);
        String ruta = request.getServletPath();

        try {
            if ("/autor/capitulos/importar".equals(ruta)) {
                importarDesdeArchivo(request, response, autorId);
                return;
            }

            if ("/autor/capitulos/importar/confirmar".equals(ruta)) {
                confirmarImportacion(request, response, autorId);
                return;
            }

            if ("/autor/capitulos/importar/rechazar".equals(ruta)) {
                rechazarImportacion(request, response, autorId);
                return;
            }

            if ("/autor/capitulos/importar/revision".equals(ruta)) {
                response.sendError(
                    HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                    "La revisión se abre con GET.");
                return;
            }

            if ("/autor/capitulo/publicar".equals(ruta)) {
                Long capituloId = parametroPositivo(request, "id");

                if (capituloId == null) {
                    response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "El ID del capítulo no es válido.");
                    return;
                }

                Capitulo capitulo =
                        dao.obtenerPropio(capituloId, autorId);

                if (capitulo == null) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "El capítulo no existe o no te pertenece.");
                    return;
                }

                if (!"borrador".equals(capitulo.getEstado())) {
                    response.sendError(
                        HttpServletResponse.SC_CONFLICT,
                        "Solo se pueden publicar borradores.");
                    return;
                }

                // ¿Es el primer capítulo? Entonces la obra se publicará con él.
                boolean obraYaPublicada =
                        dao.obraEstaPublicada(capitulo.getObraId(), autorId);

                if (!dao.publicar(autorId, capituloId)) {
                    response.sendError(
                        HttpServletResponse.SC_CONFLICT,
                        "No se pudo publicar el capítulo.");
                    return;
                }

                response.sendRedirect(
                    request.getContextPath()
                    + "/autor/capitulos?obraId="
                    + capitulo.getObraId() + "&publicado=1"
                    + (obraYaPublicada ? "" : "&obraPublicada=1"));
                return;
            }

            boolean editar =
                    "/autor/capitulo/editar".equals(ruta);

            // El editor se envía como multipart (puede llevar un audio).
            // Se lee la parte antes que los campos para detectar si el archivo
            // superó el tamaño máximo (en ese caso tampoco llegan los textos).
            Part audio = null;
            boolean audioMuyGrande = false;

            try {
                audio = request.getPart("musicaArchivo");
            } catch (IllegalStateException e) {
                audioMuyGrande = true;
            } catch (ServletException e) {
                audio = null;               // formulario no multipart: sin audio
            }

            Long obraId;
            Long capituloId = null;
            PistaCapitulo pistaActual = null;

            if (editar) {
                capituloId = parametroPositivo(request, "id");

                if (capituloId == null) {
                    response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "El ID del capítulo no es válido.");
                    return;
                }

                Capitulo existente =
                        dao.obtenerPropio(capituloId, autorId);

                if (existente == null) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "El capítulo no existe o no te pertenece.");
                    return;
                }

                if (!"borrador".equals(existente.getEstado())) {
                    response.sendError(
                        HttpServletResponse.SC_FORBIDDEN,
                        "Solo puedes editar capítulos en borrador.");
                    return;
                }

                obraId = existente.getObraId();
                pistaActual = musicaDao.obtener(capituloId);

            } else {
                obraId = parametroPositivo(request, "obraId");

                if (obraId == null) {
                    response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "El ID de la obra no es válido.");
                    return;
                }

                if (!dao.perteneceAlAutor(obraId, autorId)) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "La obra no existe o no te pertenece.");
                    return;
                }
            }

            String titulo = request.getParameter("titulo");
            String contenido = request.getParameter("contenido");

            titulo = titulo == null ? "" : titulo.trim();
            contenido = contenido == null ? "" : contenido.trim();

            // ---- Música del capítulo ----
            String opcion = request.getParameter("musicaOpcion");
            String enlace = request.getParameter("musicaYoutube");
            boolean enBucle = "1".equals(request.getParameter("musicaBucle"));

            enlace = enlace == null ? "" : enlace.trim();

            if (OPCION_MANTENER.equals(opcion) && pistaActual == null) {
                opcion = OPCION_NINGUNA;
            }
            if (!OPCION_MANTENER.equals(opcion)
                    && !OPCION_YOUTUBE.equals(opcion)
                    && !OPCION_ARCHIVO.equals(opcion)) {
                opcion = OPCION_NINGUNA;
            }

            String error = null;
            String youtubeId = null;

            if (audioMuyGrande) {
                error = "El audio supera el máximo de "
                        + (AudioUtil.MAX_AUDIO / 1024 / 1024)
                        + " MB y no se guardó nada. Elige un archivo más pequeño.";
            } else if (titulo.isBlank()) {
                error = "El título es obligatorio.";
            } else if (titulo.length() > 150) {
                error = "El título no puede superar 150 caracteres.";
            } else if (contenido.isBlank()) {
                error = "El contenido del capítulo es obligatorio.";
            } else if (OPCION_YOUTUBE.equals(opcion)) {
                youtubeId = AudioUtil.youtubeId(enlace);
                if (youtubeId == null) {
                    error = "El enlace de YouTube no es válido. Copia el enlace del video, "
                            + "por ejemplo https://www.youtube.com/watch?v=… o https://youtu.be/…";
                }
            } else if (OPCION_ARCHIVO.equals(opcion)) {
                if (!AudioUtil.hayArchivo(audio)) {
                    error = "Selecciona un archivo de audio (" + AudioUtil.FORMATOS + ").";
                } else {
                    try {
                        AudioUtil.validar(audio);
                    } catch (IllegalArgumentException e) {
                        error = e.getMessage();
                    }
                }
            }

            if (error != null) {
                // El navegador no puede volver a llenar un campo de archivo.
                if (OPCION_ARCHIVO.equals(opcion) && AudioUtil.hayArchivo(audio)
                        && !error.toLowerCase().contains("audio")) {
                    error += " Vuelve a elegir el archivo de audio.";
                }

                EncabezadoUtil.cargar(request, autorId);
                request.setAttribute("error", error);
                request.setAttribute("obraId", obraId);
                request.setAttribute("tituloFormulario", titulo);
                request.setAttribute("contenidoFormulario", contenido);
                request.setAttribute("musicaOpcion", opcion);
                request.setAttribute("musicaYoutubeFormulario", enlace);
                request.setAttribute("musicaBucleFormulario", enBucle);

                if (editar) {
                    Capitulo capitulo =
                            dao.obtenerPropio(capituloId, autorId);
                    request.setAttribute("capitulo", capitulo);
                    request.setAttribute("pista", pistaActual);
                }

                request.getRequestDispatcher(
                    "/WEB-INF/vistas/autor/editor.jsp"
                ).forward(request, response);
                return;
            }

            MusicaCapituloDAO.Cambio musica;
            String audioGuardado = null;

            if (OPCION_MANTENER.equals(opcion)) {
                musica = MusicaCapituloDAO.Cambio.mantener(enBucle);

            } else if (OPCION_YOUTUBE.equals(opcion)) {
                PistaCapitulo nueva = new PistaCapitulo();
                nueva.setTipo(PistaCapitulo.YOUTUBE);
                nueva.setTitulo("Video de YouTube");
                nueva.setUrl(AudioUtil.enlaceYoutube(youtubeId));
                musica = MusicaCapituloDAO.Cambio.nueva(nueva, enBucle);

            } else if (OPCION_ARCHIVO.equals(opcion)) {
                audioGuardado = AudioUtil.guardar(audio, autorId);

                PistaCapitulo nueva = new PistaCapitulo();
                nueva.setTipo(PistaCapitulo.ARCHIVO);
                nueva.setTitulo(AudioUtil.tituloDesdeArchivo(audio));
                nueva.setUrl("/media/" + audioGuardado);
                nueva.setArchivoRuta(audioGuardado);
                nueva.setTamanoBytes((int) audio.getSize());
                musica = MusicaCapituloDAO.Cambio.nueva(nueva, enBucle);

            } else {
                // "ninguna": en un capítulo nuevo no hay nada que quitar.
                musica = pistaActual == null ? null : MusicaCapituloDAO.Cambio.quitar();
            }

            try {
                dao.guardarBorrador(
                    autorId, obraId, capituloId, titulo, contenido, musica);
            } catch (SQLException e) {
                ImagenUtil.borrar(audioGuardado);   // no dejar archivos huérfanos
                throw e;
            }

            response.sendRedirect(
                request.getContextPath()
                + "/autor/capitulos?obraId="
                + obraId + "&guardado=1");

        } catch (SQLException e) {
            throw new ServletException(
                "Error al guardar o publicar el capítulo.", e);
        }
    }
}