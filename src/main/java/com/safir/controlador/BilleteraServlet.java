package com.safir.controlador;

import com.safir.dao.BilleteraDAO;
import com.safir.dao.CompraPaqueteDAO;
import com.safir.dao.EconomiaAutorDAO;
import com.safir.dao.RetiroDAO;
import com.safir.util.EncabezadoUtil;
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
 * Billetera del usuario: GET /billetera.
 * Incluye la economía del autor (nivel, total ganado y retiros), que antes
 * estaba en /autor/economia. Si el usuario no tiene perfil de autor, esa
 * parte simplemente no se carga ni se muestra.
 */
@WebServlet("/billetera")
public class BilleteraServlet extends HttpServlet {

    private final BilleteraDAO billeteraDAO = new BilleteraDAO();
    private final CompraPaqueteDAO compraDAO = new CompraPaqueteDAO();
    private final EconomiaAutorDAO economiaDAO = new EconomiaAutorDAO();
    private final RetiroDAO retiroDAO = new RetiroDAO();

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
            request.setAttribute("saldo", billeteraDAO.obtenerSaldo(usuarioId));
            request.setAttribute("descuento", billeteraDAO.obtenerDescuento(usuarioId));
            request.setAttribute("movimientos",
                    billeteraDAO.listarMovimientos(usuarioId, 50));
            request.setAttribute("etiquetas", BilleteraDAO.ETIQUETAS);
            request.setAttribute("paquetes", compraDAO.listarPaquetes(usuarioId));

            // Economía de autor: null si el usuario no tiene perfil de autor.
            Map<String, Object> economia = economiaDAO.obtenerEconomia(usuarioId);
            if (economia != null) {
                request.setAttribute("eco", economia);
                request.setAttribute("retiros", retiroDAO.listarDelAutor(usuarioId));
                request.setAttribute("retiroCfg", retiroDAO.parametros());
            }

            EncabezadoUtil.cargar(request, usuarioId);
            Flash.aRequest(request);
        } catch (SQLException e) {
            throw new ServletException("Error al cargar la billetera.", e);
        }

        request.getRequestDispatcher("/WEB-INF/vistas/billetera/billetera.jsp")
               .forward(request, response);
    }
}