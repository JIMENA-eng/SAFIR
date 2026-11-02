package com.safir.controlador;

import com.safir.dao.CompraPaqueteDAO;
import com.safir.pago.PayPalClient;
import com.safir.util.Flash;
import com.safir.util.SqlErrores;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.SQLException;
import java.util.Map;

/** Inicia la compra de un paquete de monedas: POST /billetera/comprar. */
@WebServlet("/billetera/comprar")
public class CompraPaqueteServlet extends HttpServlet {

    private final CompraPaqueteDAO compraDAO = new CompraPaqueteDAO();
    private final PayPalClient paypal = new PayPalClient();

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
        String base = urlBase(request);
        String volver = request.getContextPath() + "/billetera";

        int paqueteId;
        try {
            paqueteId = Integer.parseInt(request.getParameter("paqueteId"));
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String pasarela = request.getParameter("pasarela");

        try {
            if ("paypal".equals(pasarela)) {
                iniciarPayPal(request, response, sesion, usuarioId, paqueteId, base, volver);
            } else if ("yape".equals(pasarela)) {
                iniciarYape(request, response, sesion, usuarioId, paqueteId, volver);
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            }
        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                Flash.error(sesion, SqlErrores.mensaje(e));
            } else {
                log("Error al crear la compra", e);
                Flash.error(sesion, "No se pudo iniciar la compra. Inténtalo de nuevo.");
            }
            response.sendRedirect(volver);
        }
    }

    private void iniciarPayPal(HttpServletRequest request, HttpServletResponse response,
                               HttpSession sesion, long usuarioId, int paqueteId,
                               String base, String volver)
            throws SQLException, IOException {

        if (!PayPalClient.configurado()) {
            Flash.error(sesion, "El pago con PayPal no está disponible por ahora.");
            response.sendRedirect(volver);
            return;
        }

        long compraId = compraDAO.crear(usuarioId, paqueteId, "paypal");
        Map<String, Object> compra = compraDAO.obtenerPropia(compraId, usuarioId);

        try {
            PayPalClient.Orden orden = paypal.crearOrden(
                    compraId,
                    (BigDecimal) compra.get("precioPagado"),
                    "SAFIR: " + compra.get("monedas") + " monedas",
                    base + "/pago/paypal/retorno",
                    base + "/billetera?pago=cancelado");

            compraDAO.guardarReferencia(compraId, usuarioId, "paypal", orden.id());
            response.sendRedirect(orden.urlAprobacion());

        } catch (IOException e) {
            log("No se pudo crear la orden de PayPal", e);
            compraDAO.marcarFallida(compraId);
            Flash.error(sesion, "No se pudo conectar con PayPal. Inténtalo de nuevo.");
            response.sendRedirect(volver);
        }
    }

    private void iniciarYape(HttpServletRequest request, HttpServletResponse response,
                             HttpSession sesion, long usuarioId, int paqueteId,
                             String volver)
            throws SQLException, IOException {

        BigDecimal tipoCambio = compraDAO.tipoCambioPen();

        if (tipoCambio == null || tipoCambio.signum() <= 0) {
            Flash.error(sesion, "El pago con Yape no está disponible por ahora.");
            response.sendRedirect(volver);
            return;
        }

        long compraId = compraDAO.crear(usuarioId, paqueteId, "yape");
        Map<String, Object> compra = compraDAO.obtenerPropia(compraId, usuarioId);

        BigDecimal soles = ((BigDecimal) compra.get("precioPagado"))
                .multiply(tipoCambio).setScale(2, RoundingMode.HALF_UP);
        compraDAO.guardarMontoPen(compraId, soles);

        response.sendRedirect(request.getContextPath()
                + "/billetera/yape?compra=" + compraId);
    }

    /** URL pública de la app. Opcional: variable SAFIR_BASE_URL (p. ej. https://safir.com). */
    static String urlBase(HttpServletRequest request) {
        String configurada = System.getenv("SAFIR_BASE_URL");
        if (configurada != null && !configurada.isBlank()) {
            return configurada.replaceAll("/+$", "");
        }

        int puerto = request.getServerPort();
        boolean estandar = ("http".equals(request.getScheme()) && puerto == 80)
                || ("https".equals(request.getScheme()) && puerto == 443);

        return request.getScheme() + "://" + request.getServerName()
                + (estandar ? "" : ":" + puerto) + request.getContextPath();
    }
}