package com.safir.controlador;

import com.safir.dao.ObraEdicionDAO;
import com.safir.util.EncabezadoUtil;
import com.safir.util.ImagenUtil;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.Part;
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
@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 8 * 1024 * 1024)
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

        // La portada se lee primero: con multipart, si supera el límite no se leen los demás campos.
        Part portada = null;
        String errorPortada = null;
        try {
            portada = request.getPart("portada");
        } catch (IllegalStateException e) {
            errorPortada = "La portada supera el máximo de 5 MB.";
        }

        String titulo = request.getParameter("titulo");
        String descripcion = request.getParameter("descripcion");
        String generoTexto = request.getParameter("generoId");
        String clasificacion = request.getParameter("clasificacion");

        titulo = titulo == null ? "" : titulo.trim();
        descripcion = descripcion == null ? "" : descripcion.trim();
        clasificacion = clasificacion == null
                ? "" : clasificacion.trim();
        boolean bloqueo = request.getParameter("bloqueoActivo") != null;

        String error = null;
        int generoId = -1;

        if (errorPortada != null) {
            error = errorPortada;
        } else if (titulo.isBlank()) {
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

        if (error == null && ImagenUtil.hayArchivo(portada)) {
            try {
                ImagenUtil.validar(portada, ImagenUtil.MAX_PORTADA);
            } catch (IllegalArgumentException e) {
                error = e.getMessage();
            }
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
                request.setAttribute("bloqueoFormulario", bloqueo);

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

            // Portada nueva (null si no se eligió archivo)
            String portadaNueva = ImagenUtil.hayArchivo(portada)
                    ? ImagenUtil.guardar(portada, "obra", usuarioId,
                            ImagenUtil.MAX_PORTADA)
                    : null;

            if (edicion) {
                Map<String, Object> antes = dao.obtenerPropia(obraId, usuarioId);
                boolean actualizado = dao.actualizarPropia(
                    obraId, usuarioId, titulo, descripcion,
                    generoId, clasificacion);

                if (!actualizado) {
                    ImagenUtil.borrar(portadaNueva);
                    response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "La obra no existe o no te pertenece.");
                    return;
                }
                dao.actualizarBloqueo(obraId, usuarioId, bloqueo);

                if (portadaNueva != null) {
                    dao.actualizarPortada(obraId, usuarioId, portadaNueva);
                    if (antes != null) {
                        ImagenUtil.borrar((String) antes.get("portadaRuta"));
                    }
                }
            } else {
                long nuevaId = dao.crear(usuarioId, titulo, descripcion,
                        generoId, clasificacion);
                dao.actualizarBloqueo(nuevaId, usuarioId, bloqueo);
                if (portadaNueva != null) {
                    dao.actualizarPortada(nuevaId, usuarioId, portadaNueva);
                }
                // Obra recién creada: ir directo a escribir su primer capítulo
                response.sendRedirect(
                    request.getContextPath()
                    + "/autor/capitulo/nuevo?obraId=" + nuevaId);
                return;
            }

            // Edición: se queda en el formulario y muestra el aviso flotante "guardado"
            response.sendRedirect(
                request.getContextPath()
                + "/autor/obra/editar?id=" + obraId + "&guardado=1");

        } catch (SQLException e) {
            throw new ServletException(
                "No se pudo guardar la obra.", e);
        }
    }

    private void prepararFormulario(HttpServletRequest request)
            throws SQLException {
        request.setAttribute("generos", dao.listarGeneros());
        // Datos del encabezado compartido (foto, portada, @usuario, puntos rojos)
        Long usuarioId = obtenerUsuarioId(request);
        if (usuarioId != null) {
            EncabezadoUtil.cargar(request, usuarioId);
        }
    }
}