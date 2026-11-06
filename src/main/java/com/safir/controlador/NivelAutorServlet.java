package com.safir.controlador;

import com.safir.dao.EconomiaAutorDAO;
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
 * Compra del siguiente nivel de autor: POST /autor/nivel.
 * Reemplaza la acción "comprar_nivel" de la antigua página /autor/economia;
 * ahora se muestra dentro de Mi billetera y vuelve a /billetera.
 *
 * AutorizacionFilter ya exige rol autor en /autor/*.
 */
@WebServlet("/autor/nivel")
public class NivelAutorServlet extends HttpServlet {

    private final EconomiaAutorDAO economiaDAO = new EconomiaAutorDAO();

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long autorId = ((Number) sesion.getAttribute("usuarioId")).longValue();

        try {
            int nivel = economiaDAO.comprarNivel(autorId);
            Flash.ok(sesion, "¡Subiste al nivel " + nivel + "! Tus obras ganan visibilidad en el catálogo.");
        } catch (SQLException e) {
            if (SqlErrores.esReglaNegocio(e)) {
                Flash.error(sesion, SqlErrores.mensaje(e));
            } else {
                log("Error al comprar nivel", e);
                Flash.error(sesion, "No se pudo comprar el nivel. Inténtalo de nuevo.");
            }
        }

        response.sendRedirect(request.getContextPath() + "/billetera");
    }
}