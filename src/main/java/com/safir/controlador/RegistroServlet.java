package com.safir.controlador;

import com.safir.dao.UsuarioDAO;
import com.safir.dao.VerificacionDAO;
import com.safir.seguridad.PasswordUtil;
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
 * Paso 1 del registro.
 *
 * GET  /registro | /auth/registro -> formulario.
 * POST /registro | /auth/registro -> valida los datos, guarda un registro
 *      PENDIENTE y envía un código por correo o SMS. La cuenta se crea en
 *      VerificarServlet cuando el usuario ingresa el código correcto.
 *
 * Las fotos de perfil y portada ya no se piden aquí (no se pueden conservar
 * entre el formulario y la verificación); se suben luego desde el perfil.
 */
@WebServlet({"/registro", "/auth/registro"})
public class RegistroServlet extends HttpServlet {

    private static final String VISTA_REGISTRO =
            "/WEB-INF/vistas/autenticacion/registro.jsp";

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final VerificacionDAO verificacionDAO = new VerificacionDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher(VISTA_REGISTRO).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String nombre = trim(request.getParameter("nombre"));      // sobrenombre
        String usuario = trim(request.getParameter("usuario"));    // nombre de usuario
        String contacto = trim(request.getParameter("contacto"));  // correo o teléfono
        String clave = request.getParameter("clave");
        String repetir = request.getParameter("repetir");

        if (nombre.isEmpty() || nombre.length() > 60) {
            mostrarError(request, response,
                    "Escribe tu sobrenombre (hasta 60 caracteres).");
            return;
        }
        if (!ValidadorRegistro.usuarioValido(usuario)) {
            mostrarError(request, response,
                    "El nombre de usuario debe tener de 3 a 30 caracteres: "
                    + "letras, números, punto o guion bajo.");
            return;
        }

        // Correo o teléfono: se decide por la presencia de "@".
        String canal;
        String destino;
        if (ValidadorRegistro.esCorreo(contacto)) {
            if (!ValidadorRegistro.correoValido(contacto)) {
                mostrarError(request, response,
                        "Escribe un correo electrónico válido.");
                return;
            }
            canal = "correo";
            destino = contacto.toLowerCase();
        } else {
            destino = ValidadorRegistro.normalizarTelefono(contacto);
            if (destino == null) {
                mostrarError(request, response,
                        "Escribe un correo o un número de teléfono válido "
                        + "(ej. 999 888 777 o +51999888777).");
                return;
            }
            canal = "telefono";
        }

        String errorClave = ValidadorRegistro.errorClave(clave);
        if (errorClave != null) {
            mostrarError(request, response, errorClave);
            return;
        }
        if (!clave.equals(repetir)) {
            mostrarError(request, response, "Las contraseñas no coinciden.");
            return;
        }

        try {
            if (usuarioDAO.existeContacto(canal, destino)) {
                mostrarError(request, response, "telefono".equals(canal)
                        ? "Ese número de teléfono ya está registrado."
                        : "Ese correo ya está registrado.");
                return;
            }
            if (usuarioDAO.existeNombreUsuario(usuario)) {
                mostrarError(request, response,
                        "Ese nombre de usuario ya está en uso.");
                return;
            }
            if (usuarioDAO.existeNombrePublico(nombre)) {
                mostrarError(request, response,
                        "Ese sobrenombre ya está en uso.");
                return;
            }

            String codigo = VerificacionDAO.generarCodigo();
            long id = verificacionDAO.guardarPendiente(canal, destino, nombre,
                    usuario, PasswordUtil.hash(clave), codigo);

            if (id < 0) {
                mostrarError(request, response,
                        "Ya te enviamos un código hace un momento. "
                        + "Espera un minuto para pedir otro.");
                return;
            }

            if (!EnvioCodigo.enviar(canal, destino, codigo,
                    VerificacionDAO.MINUTOS_VALIDEZ)) {
                mostrarError(request, response,
                        "No pudimos enviar el código. Revisa el dato e inténtalo de nuevo.");
                return;
            }

            request.getSession(true).setAttribute("verifId", id);

        } catch (SQLException e) {
            log("Error al iniciar el registro", e);
            mostrarError(request, response,
                    "Ocurrió un error al conectar con la base de datos.");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/auth/verificar");
    }

    private static String trim(String s) {
        return s == null ? "" : s.trim();
    }

    private void mostrarError(HttpServletRequest request,
                              HttpServletResponse response,
                              String mensaje)
            throws ServletException, IOException {

        request.setAttribute("error", mensaje);
        request.getRequestDispatcher(VISTA_REGISTRO).forward(request, response);
    }
}