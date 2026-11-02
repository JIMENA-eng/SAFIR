package com.safir.controlador;

import com.safir.dao.BilleteraDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/** Billetera del usuario: GET /billetera. */
@WebServlet("/billetera")
public class BilleteraServlet extends HttpServlet {

    private final BilleteraDAO billeteraDAO = new BilleteraDAO();

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
        } catch (SQLException e) {
            throw new ServletException("Error al cargar la billetera.", e);
        }

        request.getRequestDispatcher("/WEB-INF/vistas/billetera/billetera.jsp")
               .forward(request, response);
    }
}