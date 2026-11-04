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

/** Solicitud de retiro del autor: POST /autor/retiro. */
@WebServlet("/autor/retiro")
public class RetiroServlet extends HttpServlet {

    private final RetiroDAO retiroDAO = new RetiroDAO();

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

        long autorId = ((Number) sesion.getAttribute("usuarioId")).longValue();
        String destino = request.getContextPath() + "/autor/economia";

        long monedas;
        try {
            monedas = Long.parseLong(request.getParameter("monedas").trim());
            if (monedas <= 0) throw new NumberFormatException();
        } catch (NumberFormatException | NullPointerException e) {
            Flash.error(sesion, "Ingresa una cantidad válida de monedas.");
            response.sendRedirect(destino);
            return;
        }

        String metodo = request.getParameter("metodo");
        String datos = request.getParameter("datos");
        datos = datos == null ? "" : datos.trim();

        String errorDatos = null;

        if ("paypal".equals(metodo)) {
            if (datos.length() > 150
                    || !datos.matches("[^@\\s]{1,64}@[^@\\s]{1,100}\\.[^@\\s]{2,}")) {
                errorDatos = "Ingresa el correo de tu cuenta de PayPal.";
            }
        } else if ("yape".equals(metodo)) {
            if (!datos.matches("9\\d{8}")) {
                errorDatos = "Ingresa tu celular de Yape (9 dígitos, empieza con 9).";
            }
        } else {
            errorDatos = "Elige un método de pago.";
        }

        if (errorDatos != null) {
            Flash.error(sesion, errorDatos);
            response.sendRedirect(destino);
            return;
        }

        try {
            retiroDAO.solicitar(autorId, monedas, metodo, datos);
            Flash.ok(sesion, "Solicitud enviada. Se descontaron " + monedas
                    + " monedas de tu saldo; un moderador la revisará. "
                    + "Si se rechaza, te las devolvemos completas.");

        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                Flash.error(sesion, SqlErrores.mensaje(e));
            } else {
                log("Error al solicitar retiro", e);
                Flash.error(sesion, "No se pudo registrar la solicitud. Inténtalo de nuevo.");
            }
        }

        response.sendRedirect(destino);
    }
}