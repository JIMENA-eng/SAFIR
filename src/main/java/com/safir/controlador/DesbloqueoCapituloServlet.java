package com.safir.controlador;

import com.safir.dao.CapituloDAO;
import com.safir.util.SqlErrores;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/** Desbloquea un capítulo con monedas: POST /capitulo/desbloquear. */
@WebServlet("/capitulo/desbloquear")
public class DesbloqueoCapituloServlet extends HttpServlet {

    private final CapituloDAO capituloDAO = new CapituloDAO();

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/auth/login");
            return;
        }

        long usuarioId = ((Number) sesion.getAttribute("usuarioId")).longValue();
        long obraId;
        long capituloId;

        try {
            obraId = Long.parseLong(request.getParameter("obraId"));
            capituloId = Long.parseLong(request.getParameter("capituloId"));
            if (obraId <= 0 || capituloId <= 0) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            if (capituloDAO.buscarPublicado(capituloId, obraId) == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            capituloDAO.comprar(usuarioId, capituloId);

        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                sesion.setAttribute("flashError", SqlErrores.mensaje(e));
            } else {
                log("Error al desbloquear capítulo", e);
                sesion.setAttribute("flashError",
                        "No se pudo completar la compra. Inténtalo de nuevo.");
            }
        }

        response.sendRedirect(request.getContextPath()
                + "/lectura?obraId=" + obraId + "&capituloId=" + capituloId);
    }
}