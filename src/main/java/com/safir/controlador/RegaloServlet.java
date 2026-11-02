package com.safir.controlador;

import com.safir.dao.EconomiaAutorDAO;
import com.safir.util.SqlErrores;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/** Regalo de monedas al autor de una obra: POST /regalo. */
@WebServlet("/regalo")
public class RegaloServlet extends HttpServlet {

    private final EconomiaAutorDAO economiaDAO = new EconomiaAutorDAO();

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
        long obraId;

        try {
            obraId = Long.parseLong(request.getParameter("obraId"));
            if (obraId <= 0) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        String destino = request.getContextPath() + "/obra?id=" + obraId;

        int monedas;
        try {
            monedas = Integer.parseInt(request.getParameter("monedas").trim());
            if (monedas <= 0) throw new NumberFormatException();
        } catch (NumberFormatException | NullPointerException e) {
            sesion.setAttribute("flashError", "Ingresa una cantidad válida de monedas.");
            response.sendRedirect(destino);
            return;
        }

        String mensaje = request.getParameter("mensaje");
        mensaje = (mensaje == null || mensaje.isBlank()) ? null : mensaje.trim();

        if (mensaje != null && mensaje.length() > 300) {
            sesion.setAttribute("flashError", "El mensaje no puede superar 300 caracteres.");
            response.sendRedirect(destino);
            return;
        }

        try {
            Long autorId = economiaDAO.obtenerAutorDeObra(obraId);

            if (autorId == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            economiaDAO.enviarRegalo(usuarioId, autorId, monedas, obraId, mensaje);
            sesion.setAttribute("flashOk",
                    "¡Regalo de " + monedas + " monedas enviado! Gracias por apoyar al autor.");

        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                sesion.setAttribute("flashError", SqlErrores.mensaje(e));
            } else {
                log("Error al enviar regalo", e);
                sesion.setAttribute("flashError",
                        "No se pudo enviar el regalo. Inténtalo de nuevo.");
            }
        }

        response.sendRedirect(destino);
    }
}