package com.safir.controlador;

import com.safir.dao.CompraPaqueteDAO;
import com.safir.util.Flash;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

/**
 * Pago con Yape: GET /billetera/yape?compra=ID muestra las instrucciones;
 * POST registra el código de operación para que un administrador lo verifique.
 *
 * Variables de entorno: SAFIR_YAPE_NUMERO y SAFIR_YAPE_TITULAR.
 */
@WebServlet("/billetera/yape")
public class YapeServlet extends HttpServlet {

    private static final String SQLSTATE_VIOLACION_UNICIDAD = "23505";

    private final CompraPaqueteDAO compraDAO = new CompraPaqueteDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/auth/login");
            return;
        }

        long usuarioId = ((Number) sesion.getAttribute("usuarioId")).longValue();
        long compraId;

        try {
            compraId = Long.parseLong(request.getParameter("compra"));
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            Map<String, Object> compra = compraDAO.obtenerPropia(compraId, usuarioId);

            if (compra == null || !"yape".equals(compra.get("pasarela"))) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            request.setAttribute("compra", compra);
            request.setAttribute("yapeNumero", System.getenv("SAFIR_YAPE_NUMERO"));
            request.setAttribute("yapeTitular", System.getenv("SAFIR_YAPE_TITULAR"));
            Flash.aRequest(request);

            request.getRequestDispatcher("/WEB-INF/vistas/billetera/yape.jsp")
                   .forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("Error al cargar la compra.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/auth/login");
            return;
        }

        long usuarioId = ((Number) sesion.getAttribute("usuarioId")).longValue();
        long compraId;

        try {
            compraId = Long.parseLong(request.getParameter("compraId"));
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String destino = request.getContextPath() + "/billetera/yape?compra=" + compraId;
        String codigo = request.getParameter("codigo");
        codigo = codigo == null ? "" : codigo.trim();

        if (!codigo.matches("[A-Za-z0-9]{4,30}")) {
            Flash.error(sesion, "El código de operación debe tener entre 4 y 30 letras o números.");
            response.sendRedirect(destino);
            return;
        }

        try {
            boolean guardado = compraDAO.guardarReferencia(compraId, usuarioId, "yape", codigo);

            if (guardado) {
                Flash.ok(sesion, "Recibimos tu código. Verificaremos el pago y, al confirmarlo, "
                        + "tus monedas se acreditarán en tu billetera.");
            } else {
                Flash.error(sesion, "Esta compra ya no admite cambios.");
            }

        } catch (SQLException e) {
            if (SQLSTATE_VIOLACION_UNICIDAD.equals(e.getSQLState())) {
                Flash.error(sesion, "Ese código de operación ya fue registrado en otra compra.");
            } else {
                log("Error al registrar el código de Yape", e);
                Flash.error(sesion, "No se pudo guardar el código. Inténtalo de nuevo.");
            }
        }

        response.sendRedirect(destino);
    }
}