package com.safir.controlador;

import com.safir.dao.CuentaDAO;
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
import java.util.Map;

/**
 * Eliminación de la cuenta del usuario con sesión activa.
 * GET  /auth/cuenta/eliminar  muestra el aviso (qué se reembolsa y qué se pierde).
 * POST /auth/cuenta/eliminar  elimina, cierra la sesión y vuelve al inicio de sesión.
 */
@WebServlet("/auth/cuenta/eliminar")
public class EliminarCuentaServlet extends HttpServlet {

    private final CuentaDAO cuentaDAO = new CuentaDAO();

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

        try {
            request.setAttribute("prev", cuentaDAO.vistaPrevia(usuarioId));
        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                // Por ejemplo: "Tienes un retiro pendiente; espera a que se resuelva".
                request.setAttribute("bloqueo", SqlErrores.mensaje(e));
            } else {
                throw new ServletException("Error al calcular el reembolso.", e);
            }
        }

        Flash.aRequest(request);
        request.getRequestDispatcher("/WEB-INF/vistas/eliminar-cuenta.jsp")
               .forward(request, response);
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
        String volver = request.getContextPath() + "/auth/cuenta/eliminar";

        boolean aceptaPerder = request.getParameter("acepta") != null;
        String metodo = request.getParameter("metodo");
        String datos = request.getParameter("datos");
        datos = datos == null ? "" : datos.trim();

        try {
            if (!cuentaDAO.verificarClave(usuarioId, request.getParameter("clave"))) {
                Flash.error(sesion, "La contraseña no es correcta.");
                response.sendRedirect(volver);
                return;
            }

            Map<String, Object> prev = cuentaDAO.vistaPrevia(usuarioId);
            String metodoGuardar = null;
            String datosGuardar = null;

            // Solo se pide el destino si realmente hay dinero que devolver.
            if ((Long) prev.get("reembolsables") > 0) {
                String error = null;

                if ("paypal".equals(metodo)) {
                    if (datos.length() > 150
                            || !datos.matches("[^@\\s]{1,64}@[^@\\s]{1,100}\\.[^@\\s]{2,}")) {
                        error = "Ingresa el correo de tu cuenta de PayPal.";
                    }
                } else if ("yape".equals(metodo)) {
                    if (!datos.matches("9\\d{8}")) {
                        error = "Ingresa tu celular de Yape (9 dígitos, empieza con 9).";
                    }
                } else {
                    error = "Elige cómo quieres recibir tu reembolso.";
                }

                if (error != null) {
                    Flash.error(sesion, error);
                    response.sendRedirect(volver);
                    return;
                }
                metodoGuardar = metodo;
                datosGuardar = datos;
            }

            cuentaDAO.eliminar(usuarioId, aceptaPerder, metodoGuardar, datosGuardar);

            sesion.invalidate();
            response.sendRedirect(request.getContextPath() + "/auth/login?eliminada=1");

        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                Flash.error(sesion, SqlErrores.mensaje(e));
            } else {
                log("Error al eliminar la cuenta " + usuarioId, e);
                Flash.error(sesion, "No se pudo eliminar la cuenta. Inténtalo de nuevo.");
            }
            response.sendRedirect(volver);
        }
    }
}