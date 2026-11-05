package com.safir.controlador;

import com.safir.dao.UsuarioDAO;
import com.safir.util.ImagenUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Ventana que aparece justo después de registrarse para subir (opcional)
 * la foto de perfil y la portada.
 *
 * GET  /auth/fotos -> muestra la ventana.
 * POST /auth/fotos -> guarda las imágenes elegidas y va al inicio.
 * "Omitir" es un simple enlace a /auth/inicio.
 */
@WebServlet("/auth/fotos")
@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 8 * 1024 * 1024)
public class FotosServlet extends HttpServlet {

    private static final String VISTA = "/WEB-INF/vistas/autenticacion/fotos.jsp";

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (usuarioId(request) == null) {
            response.sendRedirect(request.getContextPath() + "/auth/login");
            return;
        }
        request.getRequestDispatcher(VISTA).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Long usuarioId = usuarioId(request);
        if (usuarioId == null) {
            response.sendRedirect(request.getContextPath() + "/auth/login");
            return;
        }

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

        try {
            if (ImagenUtil.hayArchivo(avatar)) {
                ImagenUtil.validar(avatar, ImagenUtil.MAX_AVATAR);
            }
            if (ImagenUtil.hayArchivo(portada)) {
                ImagenUtil.validar(portada, ImagenUtil.MAX_PORTADA);
            }
        } catch (IllegalArgumentException | IOException e) {
            mostrarError(request, response, e.getMessage());
            return;
        }

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
                usuarioDAO.actualizarImagenes(usuarioId, rutaAvatar, rutaPortada);
            }
            if (rutaAvatar != null) {
                request.getSession().setAttribute("avatarRuta", rutaAvatar);
            }
        } catch (IOException | SQLException e) {
            log("No se pudieron guardar las imágenes del registro", e);
            mostrarError(request, response,
                    "No pudimos guardar las imágenes. Puedes omitir este paso "
                    + "y subirlas luego desde tu perfil.");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/auth/inicio");
    }

    private Long usuarioId(HttpServletRequest request) {
        HttpSession s = request.getSession(false);
        Object v = (s == null) ? null : s.getAttribute("usuarioId");
        return (v instanceof Long) ? (Long) v : null;
    }

    private void mostrarError(HttpServletRequest request,
                              HttpServletResponse response, String mensaje)
            throws ServletException, IOException {
        request.setAttribute("error", mensaje);
        request.getRequestDispatcher(VISTA).forward(request, response);
    }
}