package com.safir.controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * Política de privacidad (pública, sin iniciar sesión).
 *
 * GET /privacidad -> muestra la política.
 *
 * Correo de contacto para derechos sobre datos personales: se toma de la
 * variable de entorno (o propiedad -D) SAFIR_PRIVACIDAD_CORREO. Si no está
 * definida, la página indica contactar por el soporte de la plataforma.
 *
 * Esta ruta NO está bajo ningún patrón de AutenticacionFilter, por lo que
 * se puede abrir desde login, registro, verificación y desde el correo.
 */
@WebServlet("/privacidad")
public class PrivacidadServlet extends HttpServlet {

    /** Fecha de la última revisión del texto (actualízala al cambiarlo). */
    private static final String ACTUALIZADA = "8 de noviembre de 2026";

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String correo = System.getenv("SAFIR_PRIVACIDAD_CORREO");
        if (correo == null || correo.isBlank()) {
            correo = System.getProperty("SAFIR_PRIVACIDAD_CORREO");
        }

        request.setAttribute("actualizada", ACTUALIZADA);
        request.setAttribute("correoContacto",
                correo == null || correo.isBlank() ? null : correo.trim());

        request.getRequestDispatcher(
                "/WEB-INF/vistas/legal/privacidad.jsp")
                .forward(request, response);
    }
}