package com.safir.controlador;

import com.safir.dao.RetiroDAO;
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
 * Revisión de retiros por moderadores y administradores:
 * GET /moderacion/retiros lista las solicitudes; POST las aprueba o rechaza.
 *
 * Requiere la rama de /moderacion/retiros en AutorizacionFilter.
 */
@WebServlet("/moderacion/retiros")
public class RetirosPendientesServlet extends HttpServlet {

    private final RetiroDAO retiroDAO = new RetiroDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        try {
            request.setAttribute("retiros", retiroDAO.listarPendientes());
            Flash.aRequest(request);
            request.getRequestDispatcher("/WEB-INF/vistas/moderacion/retiros.jsp")
                   .forward(request, response);
        } catch (SQLException e) {
            throw new ServletException("Error al cargar los retiros pendientes.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long moderadorId = ((Number) sesion.getAttribute("usuarioId")).longValue();
        long retiroId;

        try {
            retiroId = Long.parseLong(request.getParameter("retiroId"));
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String accion = request.getParameter("accion");

        if (!"aprobar".equals(accion) && !"rechazar".equals(accion)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        boolean aprobar = "aprobar".equals(accion);
        String referencia = vacioANulo(request.getParameter("referencia"));
        String motivo = vacioANulo(request.getParameter("motivo"));

        try {
            retiroDAO.resolver(retiroId, moderadorId, aprobar,
                    aprobar ? referencia : null,
                    aprobar ? null : motivo);

            Flash.ok(sesion, "Retiro #" + retiroId
                    + (aprobar ? " aprobado: marcado como pagado."
                               : " rechazado: monedas devueltas al autor."));

        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                Flash.error(sesion, SqlErrores.mensaje(e));
            } else {
                log("Error al resolver el retiro " + retiroId, e);
                Flash.error(sesion, "No se pudo completar la operación.");
            }
        }

        response.sendRedirect(request.getContextPath() + "/moderacion/retiros");
    }

    private static String vacioANulo(String texto) {
        return (texto == null || texto.isBlank()) ? null : texto.trim();
    }
}