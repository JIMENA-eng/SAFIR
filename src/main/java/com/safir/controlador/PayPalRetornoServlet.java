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
import java.sql.SQLException;
import java.util.Map;

/**
 * PayPal devuelve aquí al comprador tras aprobar el pago: GET /pago/paypal/retorno?token=...
 * El cobro se hace desde el servidor y solo entonces se acreditan las monedas.
 */
@WebServlet("/pago/paypal/retorno")
public class PayPalRetornoServlet extends HttpServlet {

    private final CompraPaqueteDAO compraDAO = new CompraPaqueteDAO();
    private final PayPalClient paypal = new PayPalClient();

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
        String volver = request.getContextPath() + "/billetera";
        String ordenId = request.getParameter("token");

        if (!PayPalClient.ordenValida(ordenId)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        try {
            Map<String, Object> compra =
                    compraDAO.buscarPorReferencia("paypal", ordenId, usuarioId);

            if (compra == null) {
                Flash.error(sesion, "No encontramos esa compra.");
            } else if ("pagada".equals(compra.get("estado"))) {
                Flash.ok(sesion, "Esta compra ya había sido acreditada.");
            } else if (!"pendiente".equals(compra.get("estado"))) {
                Flash.error(sesion, "Esta compra ya no está disponible.");
            } else {
                procesar(sesion, compra, ordenId);
            }

        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                Flash.error(sesion, SqlErrores.mensaje(e));
            } else {
                log("Error al confirmar el pago de PayPal", e);
                Flash.error(sesion, mensajeSoporte(ordenId));
            }
        }

        response.sendRedirect(volver);
    }

    private void procesar(HttpSession sesion, Map<String, Object> compra, String ordenId)
            throws SQLException {

        long compraId = (Long) compra.get("id");
        BigDecimal esperado = (BigDecimal) compra.get("precioPagado");

        PayPalClient.Captura captura;
        try {
            captura = paypal.capturar(ordenId);
        } catch (IOException e) {
            log("No se pudo capturar la orden " + ordenId, e);
            Flash.error(sesion, mensajeSoporte(ordenId));
            return;
        }

        if (!captura.completada()) {
            Flash.error(sesion, "PayPal no completó el pago. No se te cobró nada.");
            return;
        }

        // Nunca se acreditan monedas si lo cobrado no coincide con lo esperado.
        boolean coincide = "USD".equals(captura.moneda())
                && captura.monto().compareTo(esperado) == 0
                && (captura.customId() == null
                    || captura.customId().equals(String.valueOf(compraId)));

        if (!coincide) {
            log("Pago de PayPal con datos distintos a la compra " + compraId
                    + ": " + captura);
            Flash.error(sesion, mensajeSoporte(ordenId));
            return;
        }

        compraDAO.confirmar(compraId);
        Flash.ok(sesion, "¡Pago confirmado! Se acreditaron "
                + compra.get("monedas") + " monedas a tu billetera.");
    }

    private static String mensajeSoporte(String ordenId) {
        return "No pudimos confirmar tu pago. Si PayPal te cobró, contáctanos con el "
                + "código " + ordenId + " y lo resolveremos.";
    }
}