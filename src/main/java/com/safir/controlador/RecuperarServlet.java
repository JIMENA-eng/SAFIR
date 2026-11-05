package com.safir.controlador;

import com.safir.dao.RecuperacionDAO;
import com.safir.dao.VerificacionDAO;
import com.safir.seguridad.ValidadorRegistro;
import com.safir.util.EnvioCodigo;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Paso 1 de la recuperación de contraseña.
 *
 * GET  /auth/recuperar -> formulario para escribir el correo.
 * POST /auth/recuperar -> si el correo está vinculado a una cuenta activa (y no
 *      recuperó su contraseña en los últimos 30 días) envía un código de 6
 *      dígitos y pasa a /auth/restablecer.
 */
@WebServlet("/auth/recuperar")
public class RecuperarServlet extends HttpServlet {

    private static final String VISTA =
            "/WEB-INF/vistas/autenticacion/recuperar.jsp";

    private final RecuperacionDAO dao = new RecuperacionDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher(VISTA).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String correo = request.getParameter("correo");
        correo = correo == null ? "" : correo.trim();

        if (!ValidadorRegistro.correoValido(correo)) {
            mostrarError(request, response,
                    "Escribe un correo electrónico válido.");
            return;
        }

        long id;
        try {
            Long usuarioId = dao.buscarUsuarioActivo(correo);

            if (usuarioId == null) {
                mostrarError(request, response,
                        "Ese correo no está vinculado a ninguna cuenta.");
                return;
            }

            int dias = dao.diasRestantesBloqueo(usuarioId);
            if (dias > 0) {
                mostrarError(request, response,
                        "Ya cambiaste tu contraseña por recuperación hace poco. "
                        + "Podrás volver a recuperarla dentro de " + dias
                        + (dias == 1 ? " día." : " días."));
                return;
            }

            String codigo = VerificacionDAO.generarCodigo();
            id = dao.crearCodigo(usuarioId, codigo);

            if (id < 0) {
                mostrarError(request, response,
                        "Ya te enviamos un código hace un momento. "
                        + "Espera un minuto para pedir otro.");
                return;
            }

            if (!EnvioCodigo.enviar("correo", correo.toLowerCase(), codigo,
                    RecuperacionDAO.MINUTOS_VALIDEZ)) {
                mostrarError(request, response,
                        "No pudimos enviar el código. Inténtalo de nuevo en un minuto.");
                return;
            }
        } catch (SQLException e) {
            log("Error al iniciar la recuperación de contraseña", e);
            mostrarError(request, response,
                    "Ocurrió un error al conectar con la base de datos.");
            return;
        }

        request.getSession(true).setAttribute("recId", id);
        response.sendRedirect(request.getContextPath() + "/auth/restablecer");
    }

    private void mostrarError(HttpServletRequest request,
                              HttpServletResponse response,
                              String mensaje)
            throws ServletException, IOException {

        request.setAttribute("error", mensaje);
        request.getRequestDispatcher(VISTA).forward(request, response);
    }
}