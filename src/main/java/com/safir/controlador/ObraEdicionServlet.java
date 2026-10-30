
package com.safir.controlador;

import com.safir.dao.ObraEdicionDAO;
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
import java.util.Map;

@WebServlet(urlPatterns = {
    "/autor/obra/nueva",
    "/autor/obra/editar"
})
public class ObraEdicionServlet extends HttpServlet {

    private final ObraEdicionDAO dao = new ObraEdicionDAO();

    private Long obtenerUsuarioId(HttpServletRequest request) {
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

    private boolean tieneRolAutor(HttpServletRequest request) {
        HttpSession sesion = request.getSession(false);

        if (sesion == null) {
            return false;
        }

        Object valor = sesion.getAttribute("roles");

        if (valor instanceof String) {
            String[] roles = ((String) valor).split(",");
            for (String rol : roles) {
                if ("autor".equalsIgnoreCase(rol.trim())) {
                    return true;
                }
            }
        }

        if (valor instanceof Collection<?>) {
            for (Object rol : (Collection<?>) valor) {
                if (rol != null
                        && "autor".equalsIgnoreCase(rol.toString().trim())) {
                    return true;
                }
            }
        }

        return false;
    }

    private boolean esEdicion(HttpServletRequest request) {
        return request.getServletPath().endsWith("/editar");
    }

    private Long obtenerObraId(HttpServletRequest request) {
        String valor = request.getParameter("id");

        if (valor == null || valor.isBlank()) {
            return null;
        }

        try {
            long id = Long.parseLong(valor);
            return id > 0 ? id : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        Long usuarioId = obtenerUsuarioId(request);

        if (usuarioId == null) {
            response.sendRedirect(
                request.getContextPath() + "/login");
            return;
        }

        if (!tieneRolAutor(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Necesitas el rol de autor.");
            return;
        }

        try {
            prepararFormulario(request);

            if (esEdicion(request)) {
                Long obraId = obtenerObraId(request);

                if (obraId == null) {
                    response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "El identificador de la obra no es válido.");
                    return;
                }

                Map<String, Object> obra =
                        dao.obtenerPropia(obraId, usuarioId);

                if (obra == null) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "La obra no existe o no te pertenece.");
                    return;
                }

                request.setAttribute("obra", obra);
            }

            request.setAttribute("modoEdicion", esEdicion(request));

            request.getRequestDispatcher(
                "/WEB-INF/vistas/autor/obra-formulario.jsp"
            ).forward(request, response);

        } catch (SQLException e) {
            throw new ServletException(
                "Error al cargar el formulario de la obra.", e);
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Long usuarioId = obtenerUsuarioId(request);

        if (usuarioId == null) {
            response.sendRedirect(
                request.getContextPath() + "/login");
            return;
        }

        if (!tieneRolAutor(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Necesitas el rol de autor.");
            return;
        }

        boolean edicion = esEdicion(request);
        Long obraId = edicion ? obtenerObraId(request) : null;

        if (edicion && obraId == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "El identificador de la obra no es válido.");
            return;
        }

        String titulo = request.getParameter("titulo");
        String descripcion = request.getParameter("descripcion");
        String generoTexto = request.getParameter("generoId");
        String clasificacion = request.getParameter("clasificacion");

        titulo = titulo == null ? "" : titulo.trim();
        descripcion = descripcion == null ? "" : descripcion.trim();
        clasificacion = clasificacion == null
                ? "" : clasificacion.trim();

        String error = null;
        int generoId = -1;

        if (titulo.isBlank()) {
            error = "El título es obligatorio.";
        } else if (titulo.length() > 100) {
            error = "El título no puede superar los 100 caracteres.";
        } else if (generoTexto == null || generoTexto.isBlank()) {
            error = "Debes seleccionar un género.";
        } else {
            try {
                generoId = Integer.parseInt(generoTexto);
                if (generoId <= 0) {
                    error = "El género seleccionado no es válido.";
                }
            } catch (NumberFormatException e) {
                error = "El género seleccionado no es válido.";
            }
        }

        if (error == null
                && !List.of(
                    "todo_publico",
                    "mayores_13",
                    "mayores_18"
                ).contains(clasificacion)) {
            error = "Selecciona una clasificación válida.";
        }

        try {
            // La validación se repite en el servidor.
            if (error == null && !dao.existeGenero(generoId)) {
                error = "El género seleccionado no existe.";
            }

            if (error != null) {
                prepararFormulario(request);
                request.setAttribute("error", error);
                request.setAttribute("modoEdicion", edicion);
                request.setAttribute("tituloFormulario", titulo);
                request.setAttribute("descripcionFormulario", descripcion);
                request.setAttribute("generoFormulario", generoTexto);
                request.setAttribute("clasificacionFormulario",
                        clasificacion);

                if (edicion) {
                    Map<String, Object> obra =
                            dao.obtenerPropia(obraId, usuarioId);

                    if (obra == null) {
                        response.sendError(
                            HttpServletResponse.SC_NOT_FOUND,
                            "La obra no existe o no te pertenece.");
                        return;
                    }

                    request.setAttribute("obra", obra);
                }

                request.getRequestDispatcher(
                    "/WEB-INF/vistas/autor/obra-formulario.jsp"
                ).forward(request, response);
                return;
            }

            if (edicion) {
                boolean actualizado = dao.actualizarPropia(
                    obraId, usuarioId, titulo, descripcion,
                    generoId, clasificacion);

                if (!actualizado) {
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "La obra no existe o no te pertenece.");
                    return;
                }
            } else {
                dao.crear(usuarioId, titulo, descripcion,
                        generoId, clasificacion);
            }

            response.sendRedirect(
                request.getContextPath() + "/autor/panel?guardado=1");

        } catch (SQLException e) {
            throw new ServletException(
                "No se pudo guardar la obra.", e);
        }
    }

    private void prepararFormulario(HttpServletRequest request)
            throws SQLException {
        request.setAttribute("generos", dao.listarGeneros());
    }
}
