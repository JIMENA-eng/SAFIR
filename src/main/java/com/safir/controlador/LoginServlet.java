package com.safir.controlador;

import com.safir.dao.UsuarioDAO;
import com.safir.modelo.ResultadoLogin;
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
 *
 * TAREA 1 (LOGIN-BLOQUEO): tras 3 contraseñas incorrectas seguidas la
 * cuenta queda bloqueada 59 segundos (ver UsuarioDAO.iniciarSesion).
 */
@WebServlet({"/login", "/auth/login"})
public class LoginServlet extends HttpServlet {

    private static final String VISTA_LOGIN =
            "/WEB-INF/vistas/autenticacion/login.jsp";

    /** 429 Too Many Requests: respuesta estándar para un bloqueo por intentos. */
    private static final int SC_DEMASIADOS_INTENTOS = 429;

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

        ResultadoLogin resultado;

        try {
            resultado = usuarioDAO.iniciarSesion(identificador, clave);
        } catch (SQLException e) {
            log("Error al iniciar sesión", e);
            mostrarError(request, response,
                    "Ocurrió un error al conectar con la base de datos.");
            return;
        }

        switch (resultado.getEstado()) {

            case BLOQUEADO:
                mostrarBloqueo(request, response, resultado.getSegundosBloqueo());
                return;

            case CREDENCIALES_INVALIDAS:
                mostrarError(request, response,
                        mensajeCredencialesInvalidas(resultado.getIntentosRestantes()));
                return;

            case EXITO:
            default:
                iniciarSesion(request, resultado.getUsuario());
                response.sendRedirect(request.getContextPath() + "/auth/inicio");
        }
    }

    private String mensajeCredencialesInvalidas(int intentosRestantes) {
        String base = "Correo/teléfono o contraseña incorrectos, o cuenta no disponible.";
        if (intentosRestantes == 1) {
            return base + " Te queda 1 intento antes de un bloqueo de "
                    + UsuarioDAO.SEGUNDOS_BLOQUEO_LOGIN + " segundos.";
        }
        if (intentosRestantes > 1) {
            return base + " Te quedan " + intentosRestantes + " intentos.";
        }
        return base;
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

    /** Muestra el login con la cuenta bloqueada y la cuenta regresiva. */
    private void mostrarBloqueo(HttpServletRequest request,
                                HttpServletResponse response,
                                int segundos)
            throws ServletException, IOException {

        response.setStatus(SC_DEMASIADOS_INTENTOS);
        response.setHeader("Retry-After", String.valueOf(segundos));
        request.setAttribute("bloqueoSegundos", segundos);
        request.setAttribute("error",
                "Demasiados intentos fallidos. Espera " + segundos
                + " segundos para volver a intentarlo.");
        request.getRequestDispatcher(VISTA_LOGIN).forward(request, response);
    }

    private void mostrarError(HttpServletRequest request,
                              HttpServletResponse response,
                              String mensaje)
            throws ServletException, IOException {

        request.setAttribute("error", mensaje);
        request.getRequestDispatcher(VISTA_LOGIN).forward(request, response);
    }
}