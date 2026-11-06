package com.safir.controlador;

import com.safir.dao.UsuarioDAO;
import com.safir.seguridad.ValidadorRegistro;
import com.safir.util.EncabezadoUtil;
import com.safir.util.ImagenUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * GET  /perfil -> perfil con el encabezado compartido y el formulario "Editar perfil".
 * POST /perfil -> guarda foto, portada, sobrenombre, nombre de usuario,
 *                 descripción y enlaces de redes sociales.
 */
@WebServlet("/perfil")
@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 8 * 1024 * 1024)
public class PerfilServlet extends HttpServlet {

    private static final int MAX_BIO = 300;
    private static final int MAX_ENLACES = 5;
    private static final Set<String> REDES =
            Set.of("instagram", "facebook", "x", "tiktok", "youtube", "web", "otro");

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
            EncabezadoUtil.cargar(request, id);
            Map<String, String> img = usuarioDAO.obtenerImagenes(id);
            request.setAttribute("avatarRuta", img.get("avatar"));
            request.setAttribute("portadaRuta", img.get("portada"));
            // Si venimos de un error de validación, se conservan los enlaces escritos.
            if (request.getAttribute("enlaces") == null) {
                request.setAttribute("enlaces", usuarioDAO.obtenerEnlaces(id));
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        request.getRequestDispatcher("/WEB-INF/vistas/perfil/perfil.jsp")
               .forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        long id = ((Number) sesion.getAttribute("usuarioId")).longValue();

        String nombre  = val(request.getParameter("nombre"));
        String usuario = val(request.getParameter("usuario"));
        String bio     = val(request.getParameter("biografia"));

        try {
            Part avatar = request.getPart("avatar");
            Part portada = request.getPart("portada");

            // 1. Validar todo ANTES de guardar algo.
            if (nombre.isEmpty() || nombre.length() > 60) {
                throw new IllegalArgumentException("El sobrenombre debe tener entre 1 y 60 caracteres.");
            }
            if (!ValidadorRegistro.usuarioValido(usuario)) {
                throw new IllegalArgumentException(
                        "Nombre de usuario no válido: 3 a 30 caracteres (letras, números, _ y .).");
            }
            if (bio.length() > MAX_BIO) {
                throw new IllegalArgumentException("La descripción admite hasta " + MAX_BIO + " caracteres.");
            }
            if (usuarioDAO.sobrenombreDeOtro(id, nombre)) {
                throw new IllegalArgumentException("Ese sobrenombre ya está en uso.");
            }
            if (usuarioDAO.usuarioDeOtro(id, usuario)) {
                throw new IllegalArgumentException("Ese nombre de usuario ya está en uso.");
            }
            List<String[]> enlaces = leerEnlaces(request);
            if (ImagenUtil.hayArchivo(avatar))  ImagenUtil.validar(avatar, ImagenUtil.MAX_AVATAR);
            if (ImagenUtil.hayArchivo(portada)) ImagenUtil.validar(portada, ImagenUtil.MAX_PORTADA);

            // 2. Guardar textos y enlaces (una transacción).
            usuarioDAO.actualizarPerfil(id, nombre, usuario, bio, enlaces);
            sesion.setAttribute("nombreUsuario", nombre);   // el encabezado usa este valor

            // 3. Guardar imágenes (igual que antes).
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
            response.sendRedirect(request.getContextPath() + "/auth/cuenta");

        } catch (IllegalArgumentException | IllegalStateException e) {
            mostrarError(request, response, nombre, usuario, bio,
                    e instanceof IllegalStateException
                            ? "La imagen supera el tamaño permitido." : e.getMessage());
        } catch (SQLException e) {
            if ("23505".equals(e.getSQLState())) {   // índice único: otro usuario se adelantó
                mostrarError(request, response, nombre, usuario, bio,
                        "Ese sobrenombre o nombre de usuario ya está en uso.");
            } else {
                throw new ServletException(e);
            }
        }
    }

    /** Vuelve al formulario conservando lo que la persona escribió. */
    private void mostrarError(HttpServletRequest request, HttpServletResponse response,
                              String nombre, String usuario, String bio, String mensaje)
            throws ServletException, IOException {
        request.setAttribute("error", mensaje);
        request.setAttribute("fNombre", nombre);
        request.setAttribute("fUsuario", usuario);
        request.setAttribute("fBio", bio);
        request.setAttribute("enlaces", enlacesCrudos(request));
        doGet(request, response);
    }

    private static String val(String s) {
        return s == null ? "" : s.trim();
    }

    /** Pares {red, url} tal como llegaron, sin validar (solo para repintar el formulario). */
    private List<String[]> enlacesCrudos(HttpServletRequest r) {
        List<String[]> out = new ArrayList<>();
        String[] redes = r.getParameterValues("red");
        String[] urls = r.getParameterValues("url");
        if (redes == null || urls == null) return out;
        for (int i = 0; i < Math.min(redes.length, urls.length); i++) {
            if (!urls[i].isBlank()) out.add(new String[]{redes[i], urls[i].trim()});
        }
        return out;
    }

    /** Valida los enlaces: red permitida, solo http/https, host presente, máximo 5. */
    private List<String[]> leerEnlaces(HttpServletRequest r) {
        List<String[]> out = new ArrayList<>();
        for (String[] par : enlacesCrudos(r)) {
            String red = par[0];
            String u = par[1];
            if (!u.matches("(?i)^https?://.*")) u = "https://" + u;
            try {
                if (new URI(u).getHost() == null) throw new URISyntaxException(u, "sin host");
            } catch (URISyntaxException e) {
                throw new IllegalArgumentException("Enlace no válido: " + par[1]);
            }
            if (u.length() > 255 || !REDES.contains(red)) {
                throw new IllegalArgumentException("Enlace no válido: " + par[1]);
            }
            out.add(new String[]{red, u});
        }
        if (out.size() > MAX_ENLACES) {
            throw new IllegalArgumentException("Puedes añadir hasta " + MAX_ENLACES + " enlaces.");
        }
        return out;
    }
}