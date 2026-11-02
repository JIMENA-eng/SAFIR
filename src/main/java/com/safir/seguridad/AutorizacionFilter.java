package com.safir.seguridad;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;

import java.io.IOException;
import java.util.Collection;

@WebFilter(urlPatterns = {
    "/autor/*",
    "/perfil/*",
    "/lectura/*",
    "/biblioteca/*",
    "/billetera/*",
    "/moderacion/*"
})
public class AutorizacionFilter implements Filter {

    @Override
    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain
    ) throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        HttpSession sesion = req.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            res.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        Object rolesSesion = sesion.getAttribute("roles");

        String uri = req.getRequestURI().substring(
                req.getContextPath().length()
        );

        boolean autorizado = false;

        if ((uri.equals("/autor") || uri.startsWith("/autor/"))) {
            autorizado = tieneRol(rolesSesion, "autor")
                    || tieneRol(rolesSesion, "administrador");

        } else if (uri.startsWith("/moderacion/usuarios")) {
            autorizado = tieneRol(rolesSesion, "administrador");

        } else if (uri.startsWith("/moderacion/reportes")) {
            autorizado = tieneRol(rolesSesion, "moderador")
                    || tieneRol(rolesSesion, "administrador");

        } else if (uri.startsWith("/moderacion/")) {
            autorizado = tieneRol(rolesSesion, "administrador");

        } else if (uri.equals("/perfil") || uri.startsWith("/perfil/")
                || uri.equals("/lectura") || uri.startsWith("/lectura/")
                || uri.equals("/billetera") || uri.startsWith("/billetera/")
                || uri.equals("/biblioteca") || uri.startsWith("/biblioteca/")) {
            autorizado = tieneAlgunRol(rolesSesion);
        }

        if (!autorizado) {
            res.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        chain.doFilter(request, response);
    }

    private boolean tieneRol(Object roles, String rolBuscado) {
        if (roles instanceof Collection<?>) {
            return ((Collection<?>) roles).stream()
                    .anyMatch(rol -> rolBuscado.equalsIgnoreCase(
                            String.valueOf(rol)
                    ));
        }

        if (roles instanceof String[]) {
            for (String rol : (String[]) roles) {
                if (rolBuscado.equalsIgnoreCase(rol)) {
                    return true;
                }
            }
        }

        if (roles instanceof String) {
            String valor = (String) roles;

            for (String rol : valor.split("[,;]")) {
                if (rolBuscado.equalsIgnoreCase(rol.trim())) {
                    return true;
                }
            }
        }

        return false;
    }

    private boolean tieneAlgunRol(Object roles) {
        if (roles instanceof Collection<?>) {
            return !((Collection<?>) roles).isEmpty();
        }

        if (roles instanceof String[]) {
            return ((String[]) roles).length > 0;
        }

        if (roles instanceof String) {
            return !((String) roles).isBlank();
        }

        return false;
    }
}