package com.safir.controlador;

import com.safir.dao.UsuarioDAO;
import com.safir.util.ImagenUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Controlador de registro de usuarios.
 *
 * GET  /registro | /auth/registro  -> muestra el formulario.
 * POST /registro | /auth/registro  -> valida los datos y crea la cuenta.
 *      Acepta (opcional) las imágenes "avatar" y "portada".
 *
 * Se mantiene también /auth/registro porque las vistas JSP existentes
 * apuntan a esa ruta.
 */
@WebServlet({"/registro", "/auth/registro"})
@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 8 * 1024 * 1024)
public class RegistroServlet extends HttpServlet {

    private static final String VISTA_REGISTRO =
            "/WEB-INF/vistas/autenticacion/registro.jsp";

    private static final String SQLSTATE_VIOLACION_UNICIDAD = "23505";

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

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

        // Imágenes opcionales (deben leerse antes de los parámetros).
        Part avatar;
        Part portada;
        try {
            avatar = request.getPart("avatar");
            portada = request.getPart("portada");
        } catch (IllegalStateException e) {
            mostrarError(request, response,
                    "Las imágenes superan el tamaño permitido "
                    + "(perfil 2 MB, portada 5 MB).");
            return;
        }

        String correo = request.getParameter("correo");
        String nombre = request.getParameter("nombre");
        String clave = request.getParameter("clave");
        String repetir = request.getParameter("repetir");

        if (correo == null || nombre == null || clave == null
                || repetir == null
                || correo.isBlank() || nombre.isBlank()
                || clave.length() < 8 || !clave.equals(repetir)
                || correo.length() > 254 || nombre.length() > 60) {

            mostrarError(request, response,
                    "Revisa tus datos. La contraseña debe tener al menos "
                    + "8 caracteres y ambas deben coincidir.");
            return;
        }

        // Validar las imágenes ANTES de crear la cuenta (si se enviaron).
        try {
            if (ImagenUtil.hayArchivo(avatar)) {
                ImagenUtil.validar(avatar, ImagenUtil.MAX_AVATAR);
            }
            if (ImagenUtil.hayArchivo(portada)) {
                ImagenUtil.validar(portada, ImagenUtil.MAX_PORTADA);
            }
        } catch (IllegalArgumentException e) {
            mostrarError(request, response, e.getMessage());
            return;
        }

        long usuarioId;

        try {
            usuarioId = usuarioDAO.registrar(correo, nombre, clave);
        } catch (SQLException e) {
            if (SQLSTATE_VIOLACION_UNICIDAD.equals(e.getSQLState())) {
                mostrarError(request, response,
                        "El correo o nombre público ya está registrado.");
            } else {
                log("Error al registrar usuario", e);
                mostrarError(request, response,
                        "Ocurrió un error al conectar con la base de datos.");
            }
            return;
        }

        // Guardar imágenes: un fallo aquí NO cancela el registro;
        // el usuario podrá subirlas luego desde su perfil.
        try {
            String rutaAvatar = ImagenUtil.hayArchivo(avatar)
                    ? ImagenUtil.guardar(avatar, "avatar", usuarioId,
                            ImagenUtil.MAX_AVATAR)
                    : null;
            String rutaPortada = ImagenUtil.hayArchivo(portada)
                    ? ImagenUtil.guardar(portada, "portada", usuarioId,
                            ImagenUtil.MAX_PORTADA)
                    : null;

            if (rutaAvatar != null || rutaPortada != null) {
                usuarioDAO.actualizarImagenes(
                        usuarioId, rutaAvatar, rutaPortada);
            }
        } catch (IOException | SQLException e) {
            log("Cuenta creada, pero no se guardaron las imágenes", e);
        }

        response.sendRedirect(
                request.getContextPath() + "/auth/login?registrado=1");
    }

    private void mostrarError(HttpServletRequest request,
                              HttpServletResponse response,
                              String mensaje)
            throws ServletException, IOException {

        request.setAttribute("error", mensaje);
        request.getRequestDispatcher(VISTA_REGISTRO).forward(request, response);
    }
}