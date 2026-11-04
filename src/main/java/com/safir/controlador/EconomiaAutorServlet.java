package com.safir.controlador;

import com.safir.dao.EconomiaAutorDAO;
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
import java.util.Map;

/**
 * Economía del autor: nivel, saldo e historial de retiros.
 * GET /autor/economia  muestra la página.
 * POST /autor/economia con accion=comprar_nivel sube un nivel.
 *
 * AutorizacionFilter ya exige rol autor en /autor/*.
 */
@WebServlet("/autor/economia")
public class EconomiaAutorServlet extends HttpServlet {

    private final EconomiaAutorDAO economiaDAO = new EconomiaAutorDAO();
    private final RetiroDAO retiroDAO = new RetiroDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long autorId = ((Number) sesion.getAttribute("usuarioId")).longValue();

        try {
            Map<String, Object> economia = economiaDAO.obtenerEconomia(autorId);

            if (economia == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND,
                        "Tu cuenta aún no tiene perfil de autor.");
                return;
            }

            request.setAttribute("eco", economia);
            request.setAttribute("retiros", retiroDAO.listarDelAutor(autorId));
            request.setAttribute("retiroCfg", retiroDAO.parametros());
            Flash.aRequest(request);

            request.getRequestDispatcher("/WEB-INF/vistas/autor/economia.jsp")
                   .forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("Error al cargar la economía del autor.", e);
        }
    }

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

        if (!"comprar_nivel".equals(request.getParameter("accion"))) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

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

        response.sendRedirect(request.getContextPath() + "/autor/economia");
    }
}