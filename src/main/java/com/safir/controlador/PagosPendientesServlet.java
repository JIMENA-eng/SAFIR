package com.safir.controlador;

import com.safir.dao.CompraPaqueteDAO;
import com.safir.util.Flash;
import com.safir.util.SqlErrores;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Revisión de pagos con Yape: GET/POST /moderacion/pagos.
 * AutorizacionFilter ya limita /moderacion/* a administradores.
 */
@WebServlet("/moderacion/pagos")
public class PagosPendientesServlet extends HttpServlet {

    private final CompraPaqueteDAO compraDAO = new CompraPaqueteDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        try {
            request.setAttribute("pagos", compraDAO.listarYapePendientes());
            Flash.aRequest(request);
            request.getRequestDispatcher("/WEB-INF/vistas/moderacion/pagos.jsp")
                   .forward(request, response);
        } catch (SQLException e) {
            throw new ServletException("Error al cargar los pagos pendientes.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);
        long compraId;

        try {
            compraId = Long.parseLong(request.getParameter("compraId"));
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String accion = request.getParameter("accion");

        try {
            if ("confirmar".equals(accion)) {
                compraDAO.confirmar(compraId);
                Flash.ok(sesion, "Pago #" + compraId + " confirmado: monedas acreditadas.");
            } else if ("rechazar".equals(accion)) {
                boolean hecho = compraDAO.marcarFallida(compraId);
                if (hecho) {
                    Flash.ok(sesion, "Pago #" + compraId + " rechazado.");
                } else {
                    Flash.error(sesion, "Ese pago ya no está pendiente.");
                }
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                Flash.error(sesion, SqlErrores.mensaje(e));
            } else {
                log("Error al resolver el pago " + compraId, e);
                Flash.error(sesion, "No se pudo completar la operación.");
            }
        }

        response.sendRedirect(request.getContextPath() + "/moderacion/pagos");
    }
}