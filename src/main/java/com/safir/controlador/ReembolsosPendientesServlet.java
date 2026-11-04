package com.safir.controlador;

import com.safir.dao.CuentaDAO;
import com.safir.util.Flash;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Reembolsos por cuentas eliminadas: GET/POST /moderacion/reembolsos.
 * AutorizacionFilter limita /moderacion/* (salvo reportes y retiros) a administradores.
 */
@WebServlet("/moderacion/reembolsos")
public class ReembolsosPendientesServlet extends HttpServlet {

    private final CuentaDAO cuentaDAO = new CuentaDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        try {
            request.setAttribute("reembolsos", cuentaDAO.listarReembolsosPendientes());
            Flash.aRequest(request);
            request.getRequestDispatcher("/WEB-INF/vistas/moderacion/reembolsos.jsp")
                   .forward(request, response);
        } catch (SQLException e) {
            throw new ServletException("Error al cargar los reembolsos pendientes.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession sesion = request.getSession(false);
        long reembolsoId;

        try {
            reembolsoId = Long.parseLong(request.getParameter("reembolsoId"));
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String referencia = request.getParameter("referencia");
        referencia = (referencia == null || referencia.isBlank()) ? null : referencia.trim();

        try {
            if (cuentaDAO.marcarReembolsoPagado(reembolsoId, referencia)) {
                Flash.ok(sesion, "Reembolso #" + reembolsoId + " marcado como pagado.");
            } else {
                Flash.error(sesion, "Ese reembolso ya no está pendiente.");
            }
        } catch (SQLException e) {
            log("Error al marcar el reembolso " + reembolsoId, e);
            Flash.error(sesion, "No se pudo completar la operación.");
        }

        response.sendRedirect(request.getContextPath() + "/moderacion/reembolsos");
    }
}