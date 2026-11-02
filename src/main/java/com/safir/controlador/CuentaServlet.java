package com.safir.controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import com.safir.dao.BilleteraDAO;
import java.io.IOException;
import java.sql.SQLException;

/** Página "Mi cuenta" del usuario con sesión activa: GET /auth/cuenta. */
@WebServlet("/auth/cuenta")
public class CuentaServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/auth/login");
            return;
        }
          try {
            long id = ((Number) sesion.getAttribute("usuarioId")).longValue();
            request.setAttribute("monedas", billeteraDAO.obtenerSaldo(id));
        } catch (SQLException e) {
            throw new ServletException("Error al cargar el saldo.", e);
        }

        request.getRequestDispatcher(
                "/WEB-INF/vistas/cuenta.jsp").forward(request, response);
    }
      private final BilleteraDAO billeteraDAO = new BilleteraDAO();
}
