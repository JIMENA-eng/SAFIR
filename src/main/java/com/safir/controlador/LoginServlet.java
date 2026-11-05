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
import java.util.Map;

/**
 * Controlador de inicio de sesión.
 *
 * GET  /login | /auth/login  -> muestra el formulario.
 * POST /login | /auth/login  -> valida credenciales y crea la sesión.
 *
 * Se mantiene también /auth/login porque las vistas JSP existentes
 * apuntan a esa ruta; /login es la que usan filtros y otros servlets.
 */
@WebServlet({"/login", "/auth/login"})
public class LoginServlet extends HttpServlet {

    private static final String VISTA_LOGIN =
            "/WEB-INF/vistas/autenticacion/login.jsp";


    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher(VISTA_LOGIN).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        // Correo o teléfono (se acepta "correo" por compatibilidad con vistas antiguas)
        String identificador = request.getParameter("identificador");
        if (identificador == null) {
            identificador = request.getParameter("correo");
        }
        String clave = request.getParameter("clave");

        if (identificador == null || clave == null
                || identificador.isBlank() || clave.isEmpty()) {
            mostrarError(request, response,
                    "Ingresa tu correo o teléfono y tu contraseña.");
            return;
        }

        Map<String, Object> usuario;

        try {
            usuario = usuarioDAO.iniciarSesion(identificador, clave);
        } catch (SQLException e) {
            log("Error al iniciar sesión", e);
            mostrarError(request, response,
                    "Ocurrió un error al conectar con la base de datos.");
            return;
        }

        if (usuario == null) {
            mostrarError(request, response,
                    "Correo/teléfono o contraseña incorrectos, o cuenta no disponible.");
            return;
        }

        iniciarSesion(request, usuario);

        response.sendRedirect(request.getContextPath() + "/auth/inicio");
    }

    /** Descarta cualquier sesión previa y crea una nueva (evita fijación de sesión). */
    private void iniciarSesion(HttpServletRequest request,
                               Map<String, Object> usuario) {

        HttpSession anterior = request.getSession(false);
        if (anterior != null) {
            anterior.invalidate();
        }

        HttpSession sesion = request.getSession(true);
        request.changeSessionId();

        sesion.setAttribute("usuarioId", usuario.get("id"));
        sesion.setAttribute("nombreUsuario", usuario.get("nombre"));
        sesion.setAttribute("roles", usuario.get("roles"));
        sesion.setAttribute("avatarRuta", usuario.get("avatarRuta"));
    }

    private void mostrarError(HttpServletRequest request,
                              HttpServletResponse response,
                              String mensaje)
            throws ServletException, IOException {

        request.setAttribute("error", mensaje);
        request.getRequestDispatcher(VISTA_LOGIN).forward(request, response);
    }
}