package com.safir.util;

import com.safir.dao.NotificacionDAO;
import com.safir.dao.UsuarioDAO;
import jakarta.servlet.http.HttpServletRequest;

import java.util.Map;

/**
 * Carga los datos que necesita el encabezado compartido
 * (WEB-INF/vistas/comunes/encabezado.jspf) para que se vea igual en
 * el inicio y en el perfil. Si algo falla, el JSP usa lo que hay en sesión.
 */
public final class EncabezadoUtil {

    private EncabezadoUtil() {}

    public static void cargar(HttpServletRequest request, long usuarioId) {
        long noLeidas = 0;
        try {
            noLeidas = new NotificacionDAO().contarNoLeidas(usuarioId);
        } catch (Exception e) {
            request.getServletContext().log("No se pudieron contar las notificaciones", e);
        }
        request.setAttribute("notificacionesNoLeidas", noLeidas);
        // TODO: cuando exista el módulo de mensajes, contar aquí los no leídos.
        request.setAttribute("mensajesNoLeidos", 0L);

        try {
            Map<String, String> p = new UsuarioDAO().obtenerPerfilMenu(usuarioId);
            request.setAttribute("menuSobrenombre", p.get("sobrenombre"));
            request.setAttribute("menuUsuario", p.get("usuario"));
            request.setAttribute("menuAvatar", p.get("avatar"));
            request.setAttribute("menuPortada", p.get("portada"));
            request.setAttribute("menuBiografia", p.get("biografia"));
        } catch (Exception e) {
            request.getServletContext().log("No se pudo cargar el perfil del menú", e);
        }
    }
}