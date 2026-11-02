package com.safir.controlador;

import com.safir.dao.UsuarioDAO;
import com.safir.util.ImagenUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

@WebServlet("/perfil")
@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 8 * 1024 * 1024)
public class PerfilServlet extends HttpServlet {

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        try {
            long id = ((Number) sesion.getAttribute("usuarioId")).longValue();
            Map<String, String> img = usuarioDAO.obtenerImagenes(id);
            request.setAttribute("avatarRuta", img.get("avatar"));
            request.setAttribute("portadaRuta", img.get("portada"));
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        request.getRequestDispatcher("/WEB-INF/vistas/perfil/perfil.jsp")
               .forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        long id = ((Number) sesion.getAttribute("usuarioId")).longValue();
        try {
            Part avatar = request.getPart("avatar");
            Part portada = request.getPart("portada");
            Map<String, String> antes = usuarioDAO.obtenerImagenes(id);

            String a = ImagenUtil.hayArchivo(avatar)
                    ? ImagenUtil.guardar(avatar, "avatar", id, ImagenUtil.MAX_AVATAR) : null;
            String p = ImagenUtil.hayArchivo(portada)
                    ? ImagenUtil.guardar(portada, "portada", id, ImagenUtil.MAX_PORTADA) : null;

            if (a != null || p != null) {
                usuarioDAO.actualizarImagenes(id, a, p);
                if (a != null) { ImagenUtil.borrar(antes.get("avatar"));  sesion.setAttribute("avatarRuta", a); }
                if (p != null) { ImagenUtil.borrar(antes.get("portada")); }
            }
            response.sendRedirect(request.getContextPath() + "/perfil?ok=1");
        } catch (IllegalArgumentException | IllegalStateException e) {
            request.setAttribute("error", e instanceof IllegalStateException
                    ? "La imagen supera el tamaño permitido." : e.getMessage());
            doGet(request, response);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }
}