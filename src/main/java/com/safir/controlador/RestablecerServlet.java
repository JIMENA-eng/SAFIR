package com.safir.controlador;

import com.safir.dao.RecuperacionDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Paso 2 de la recuperación de contraseña.
 *
 * GET  /auth/restablecer?token=... -> formulario de contraseña nueva
 *      (o aviso de que el enlace no sirve).
 * POST /auth/restablecer           -> guarda la contraseña nueva.
 */
@WebServlet("/auth/restablecer")
public class RestablecerServlet extends HttpServlet {

    private static final String VISTA =
            "/WEB-INF/vistas/autenticacion/restablecer.jsp";

    private final RecuperacionDAO dao = new RecuperacionDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String token = request.getParameter("token");

        try {
            if (token == null || token.isBlank()
                    || !dao.tokenValido(RecuperacionDAO.hashDeToken(token))) {
                enlaceInvalido(request, response);
                return;
            }
        } catch (SQLException e) {
            log("Error al validar el token de recuperación", e);
            enlaceInvalido(request, response);
            return;
        }

        request.setAttribute("token", token);
        request.getRequestDispatcher(VISTA).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String token = request.getParameter("token");
        String clave = request.getParameter("clave");
        String repetir = request.getParameter("repetir");

        if (token == null || token.isBlank()) {
            enlaceInvalido(request, response);
            return;
        }

        if (clave == null || repetir == null
                || clave.length() < 8 || !clave.equals(repetir)) {
            request.setAttribute("token", token);
            request.setAttribute("error",
                    "La contraseña debe tener al menos 8 caracteres "
                    + "y ambas deben coincidir.");
            request.getRequestDispatcher(VISTA).forward(request, response);
            return;
        }

        try {
            boolean cambiada = dao.restablecer(
                    RecuperacionDAO.hashDeToken(token), clave);

            if (!cambiada) {
                enlaceInvalido(request, response);
                return;
            }
        } catch (SQLException e) {
            log("Error al restablecer la contraseña", e);
            request.setAttribute("token", token);
            request.setAttribute("error",
                    "Ocurrió un error al conectar con la base de datos.");
            request.getRequestDispatcher(VISTA).forward(request, response);
            return;
        }

        response.sendRedirect(
                request.getContextPath() + "/auth/login?restablecido=1");
    }

    private void enlaceInvalido(HttpServletRequest request,
                                HttpServletResponse response)
            throws ServletException, IOException {

        request.setAttribute("tokenInvalido", Boolean.TRUE);
        request.getRequestDispatcher(VISTA).forward(request, response);
    }
}