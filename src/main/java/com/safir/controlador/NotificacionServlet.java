package com.safir.controlador;

import com.safir.dao.NotificacionDAO;
import com.safir.modelo.Notificacion;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/notificaciones")
public class NotificacionServlet extends HttpServlet {

    private final NotificacionDAO notificacionDAO =
            new NotificacionDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null
                || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(
                request.getContextPath() + "/login"
            );
            return;
        }

        try {
            long usuarioId = Long.parseLong(
                sesion.getAttribute("usuarioId").toString()
            );

            List<Notificacion> notificaciones =
                    notificacionDAO.listar(usuarioId);

            long pendientes =
                    notificacionDAO.contarNoLeidas(usuarioId);

            request.setAttribute("notificaciones", notificaciones);
            request.setAttribute("pendientes", pendientes);

            request.getRequestDispatcher(
                "/WEB-INF/vistas/notificaciones/notificaciones.jsp"
            ).forward(request, response);

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_UNAUTHORIZED
            );
        } catch (SQLException e) {
            throw new ServletException(
                "No se pudieron cargar las notificaciones.", e
            );
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession sesion = request.getSession(false);

        if (sesion == null
                || sesion.getAttribute("usuarioId") == null) {
            response.sendError(
                HttpServletResponse.SC_UNAUTHORIZED
            );
            return;
        }

        try {
            long usuarioId = Long.parseLong(
                sesion.getAttribute("usuarioId").toString()
            );

            String accion = request.getParameter("accion");

            if ("leer".equals(accion)) {
                long notificacionId = Long.parseLong(
                    request.getParameter("notificacionId")
                );

                notificacionDAO.marcarLeida(
                    usuarioId, notificacionId
                );

            } else if ("leerTodas".equals(accion)) {
                notificacionDAO.marcarTodasLeidas(usuarioId);

            } else {
                response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Acción no válida."
                );
                return;
            }

            response.sendRedirect(
                request.getContextPath() + "/notificaciones"
            );

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "El identificador no es válido."
            );
        } catch (SQLException e) {
            throw new ServletException(
                "No se pudieron actualizar las notificaciones.", e
            );
        }
    }
}