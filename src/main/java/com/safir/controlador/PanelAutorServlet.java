package com.safir.controlador;

import com.safir.dao.PanelAutorDAO;
import com.safir.modelo.ObraAutor;

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

@WebServlet("/autor/panel")
public class PanelAutorServlet extends HttpServlet {

    private final PanelAutorDAO panelDAO = new PanelAutorDAO();

    private boolean tieneRolAutor(Object roles) {
        if (roles instanceof String) {
            return List.of(((String) roles).split(","))
                    .stream()
                    .map(String::trim)
                    .anyMatch("autor"::equalsIgnoreCase);
        }

        if (roles instanceof Collection<?> coleccion) {
            return coleccion.stream()
                    .anyMatch(rol ->
                        "autor".equalsIgnoreCase(String.valueOf(rol))
                    );
        }

        return false;
    }

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

        if (!tieneRolAutor(sesion.getAttribute("roles"))) {
            response.sendError(
                HttpServletResponse.SC_FORBIDDEN,
                "No tienes permisos para acceder al panel de autor."
            );
            return;
        }

        try {
            long autorId = Long.parseLong(
                sesion.getAttribute("usuarioId").toString()
            );

            List<ObraAutor> obras = panelDAO.listarObras(autorId);

            request.setAttribute("obras", obras);

            request.getRequestDispatcher(
                "/WEB-INF/vistas/autor/panel.jsp"
            ).forward(request, response);

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_UNAUTHORIZED
            );
        } catch (SQLException e) {
            throw new ServletException(
                "No se pudo cargar el panel del autor.", e
            );
        }
    }
}