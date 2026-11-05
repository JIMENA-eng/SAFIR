package com.safir.controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import com.safir.dao.NotificacionDAO;
import com.safir.dao.UsuarioDAO;

import java.io.IOException;

/** Página de inicio del usuario con sesión activa: GET /auth/inicio. */
@WebServlet("/auth/inicio")
public class InicioServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/auth/login");
            return;
        }

        // Puntos rojos del encabezado. Si falla la consulta, simplemente no se muestran.
        long notificacionesNoLeidas = 0;
        try {
            long usuarioId = Long.parseLong(sesion.getAttribute("usuarioId").toString());
            notificacionesNoLeidas = new NotificacionDAO().contarNoLeidas(usuarioId);
        } catch (Exception e) {
            getServletContext().log("No se pudieron contar las notificaciones", e);
        }
        request.setAttribute("notificacionesNoLeidas", notificacionesNoLeidas);
        // Tarjeta de perfil del menú de cuenta (portada, foto, sobrenombre y usuario).
        // Si falla, el JSP usa los datos que ya hay en la sesión.
        try {
            long usuarioId = Long.parseLong(sesion.getAttribute("usuarioId").toString());
            java.util.Map<String, String> perfil = new UsuarioDAO().obtenerPerfilMenu(usuarioId);
            request.setAttribute("menuSobrenombre", perfil.get("sobrenombre"));
            request.setAttribute("menuUsuario", perfil.get("usuario"));
            request.setAttribute("menuAvatar", perfil.get("avatar"));
            request.setAttribute("menuPortada", perfil.get("portada"));
        } catch (Exception e) {
            getServletContext().log("No se pudo cargar el perfil del menú", e);
        }
        // TODO: cuando exista el módulo de mensajes, contar aquí los no leídos.
        request.setAttribute("mensajesNoLeidos", 0L);

        request.getRequestDispatcher(
                "/WEB-INF/vistas/comunes/inicio.jsp").forward(request, response);
    }
}