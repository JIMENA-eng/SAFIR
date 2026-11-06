package com.safir.controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import com.safir.dao.BilleteraDAO;
import com.safir.dao.CuentaObrasDAO;
import com.safir.dao.UsuarioDAO;
import com.safir.util.EncabezadoUtil;
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
            // Encabezado compartido (foto, sobrenombre, puntos rojos) y datos del perfil.
            EncabezadoUtil.cargar(request, id);
            UsuarioDAO usuarioDAO = new UsuarioDAO();
            request.setAttribute("enlaces", usuarioDAO.obtenerEnlaces(id));
            request.setAttribute("estadisticas", usuarioDAO.obtenerEstadisticasPerfil(id));
            request.setAttribute("siguiendo", usuarioDAO.listarSiguiendo(id, 12));
            request.setAttribute("seguidores", usuarioDAO.listarSeguidores(id, 12));
            // Sección "Mis obras y listas": publicadas, borradores y listas.
            CuentaObrasDAO obrasDAO = new CuentaObrasDAO();
            request.setAttribute("obrasPublicadas", obrasDAO.listarObras(id, "publicada"));
            request.setAttribute("obrasBorrador", obrasDAO.listarObras(id, "borrador"));
            request.setAttribute("misListas", obrasDAO.listarListas(id));
        } catch (SQLException e) {
            throw new ServletException("Error al cargar el saldo.", e);
        }

        request.getRequestDispatcher(
                "/WEB-INF/vistas/cuenta.jsp").forward(request, response);
    }
      private final BilleteraDAO billeteraDAO = new BilleteraDAO();
}