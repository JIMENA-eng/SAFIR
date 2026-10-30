package com.safir.controlador;

import com.safir.dao.GestionCapituloDAO;
import com.safir.modelo.Capitulo;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Collection;
import java.util.List;

@WebServlet(urlPatterns = {
    "/autor/capitulos",
    "/autor/capitulo/nuevo",
    "/autor/capitulo/editar",
    "/autor/capitulo/publicar"
})
public class GestionCapituloServlet extends HttpServlet {

    private final GestionCapituloDAO dao = new GestionCapituloDAO();

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

                if (!dao.perteneceAlAutor(obraId, autorId)) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "La obra no existe o no te pertenece.");
                    return;
                }

                List<Capitulo> capitulos =
                        dao.listarPorObra(obraId, autorId);

                request.setAttribute("obraId", obraId);
                request.setAttribute("capitulos", capitulos);

                request.getRequestDispatcher(
                    "/WEB-INF/vistas/autor/capitulos.jsp"
                ).forward(request, response);

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

            request.setAttribute("obraId", obraId);
            request.setAttribute("capitulo", capitulo);

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

                if (!dao.publicar(autorId, capituloId)) {
                    response.sendError(
                        HttpServletResponse.SC_CONFLICT,
                        "No se pudo publicar el capítulo.");
                    return;
                }

                response.sendRedirect(
                    request.getContextPath()
                    + "/autor/capitulos?obraId="
                    + capitulo.getObraId() + "&publicado=1");
                return;
            }

            boolean editar =
                    "/autor/capitulo/editar".equals(ruta);

            Long obraId;
            Long capituloId = null;

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

            } else {
                obraId = parametroPositivo(request, "obraId");

                if (obraId == null) {
                    response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "El ID de la obra no es válido.");
                    return;
                }
            }

            String titulo = request.getParameter("titulo");
            String contenido = request.getParameter("contenido");

            titulo = titulo == null ? "" : titulo.trim();
            contenido = contenido == null ? "" : contenido.trim();

            String error = null;

            if (titulo.isBlank()) {
                error = "El título es obligatorio.";
            } else if (titulo.length() > 150) {
                error = "El título no puede superar 150 caracteres.";
            } else if (contenido.isBlank()) {
                error = "El contenido del capítulo es obligatorio.";
            }

            if (error != null) {
                request.setAttribute("error", error);
                request.setAttribute("obraId", obraId);
                request.setAttribute("tituloFormulario", titulo);
                request.setAttribute("contenidoFormulario", contenido);

                if (editar) {
                    Capitulo capitulo =
                            dao.obtenerPropio(capituloId, autorId);
                    request.setAttribute("capitulo", capitulo);
                }

                request.getRequestDispatcher(
                    "/WEB-INF/vistas/autor/editor.jsp"
                ).forward(request, response);
                return;
            }

            dao.guardarBorrador(
                autorId, obraId, capituloId, titulo, contenido);

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