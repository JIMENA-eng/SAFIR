package com.safir.controlador;

import com.safir.dao.UsuarioDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/** Agrega el rol "autor" al usuario con sesión: POST /auth/ser-autor. */
@WebServlet("/auth/ser-autor")
public class ConvertirseAutorServlet extends HttpServlet {

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null
                || !(sesion.getAttribute("usuarioId") instanceof Number)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long usuarioId = ((Number) sesion.getAttribute("usuarioId")).longValue();

        try {
            String roles = usuarioDAO.hacerseAutor(usuarioId);

            // Actualiza la sesión para que el filtro y los menús vean el nuevo rol.
            sesion.setAttribute("roles", roles);

            boolean esAutor = false;
            for (String rol : roles.split(",")) {
                if ("autor".equalsIgnoreCase(rol.trim())) {
                    esAutor = true;
                }
            }

            response.sendRedirect(request.getContextPath()
                    + (esAutor ? "/autor/panel" : "/perfil?error=autor"));

        } catch (SQLException e) {
            log("Error al asignar el rol de autor", e);
            response.sendRedirect(request.getContextPath() + "/perfil?error=autor");
        }
    }
}
