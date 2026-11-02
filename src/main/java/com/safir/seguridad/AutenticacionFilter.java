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

@WebFilter(urlPatterns = {
    "/autor/*",
    "/perfil/*",
    "/lectura/*",
    "/biblioteca/*",
    "/billetera/*",
    "/moderacion/*"
})
public class AutenticacionFilter implements Filter {

    @Override
    public void doFilter(
            ServletRequest request,
            ServletResponse response,
            FilterChain chain
    ) throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        HttpSession sesion = req.getSession(false);

        boolean autenticado = sesion != null
                && sesion.getAttribute("usuarioId") != null;

        if (!autenticado) {
            res.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        chain.doFilter(request, response);
    }
}