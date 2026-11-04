package com.safir.controlador;

import com.safir.dao.RecuperacionDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Paso 1 de la recuperación de contraseña.
 *
 * GET  /auth/recuperar -> formulario para escribir el correo.
 * POST /auth/recuperar -> si el correo es de una cuenta activa, genera el
 *      enlace de recuperación. La respuesta es SIEMPRE la misma, exista o no
 *      el correo, para que nadie pueda averiguar qué correos tienen cuenta.
 */
@WebServlet("/auth/recuperar")
public class RecuperarServlet extends HttpServlet {

    private static final String VISTA =
            "/WEB-INF/vistas/autenticacion/recuperar.jsp";

    private final RecuperacionDAO dao = new RecuperacionDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher(VISTA).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String correo = request.getParameter("correo");

        if (correo == null || correo.isBlank()
                || correo.length() > 254 || !correo.contains("@")) {
            mostrarError(request, response,
                    "Escribe un correo electrónico válido.");
            return;
        }

        try {
            Long usuarioId = dao.buscarUsuarioActivo(correo);

            if (usuarioId != null) {
                String token = RecuperacionDAO.generarToken();

                if (dao.crearToken(usuarioId,
                        RecuperacionDAO.hashDeToken(token))) {
                    enviarEnlace(correo.trim(), armarEnlace(request, token));
                }
            }
        } catch (SQLException e) {
            log("Error al generar la recuperación de contraseña", e);
            mostrarError(request, response,
                    "Ocurrió un error al conectar con la base de datos.");
            return;
        }

        // Misma respuesta exista o no la cuenta.
        response.sendRedirect(
                request.getContextPath() + "/auth/recuperar?enviado=1");
    }

    /** Dirección completa del enlace que recibirá el usuario. */
    private String armarEnlace(HttpServletRequest request, String token) {
        // En producción define la variable de entorno SAFIR_URL_BASE
        // (por ejemplo https://safir.pe/safir) para no depender del
        // encabezado Host de la petición.
        String base = System.getenv("SAFIR_URL_BASE");

        if (base == null || base.isBlank()) {
            int puerto = request.getServerPort();
            boolean puertoPorDefecto =
                    ("http".equals(request.getScheme()) && puerto == 80)
                    || ("https".equals(request.getScheme()) && puerto == 443);

            base = request.getScheme() + "://" + request.getServerName()
                    + (puertoPorDefecto ? "" : ":" + puerto)
                    + request.getContextPath();
        }

        if (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        return base + "/auth/restablecer?token=" + token;
    }

    /**
     * MODO DESARROLLO: todavía no se envía correo; el enlace se imprime en
     * la consola del servidor (ventana de salida de NetBeans).
     * Más adelante aquí se reemplaza por el envío real de correo.
     */
    private void enviarEnlace(String correo, String enlace) {
        System.out.println("=====================================");
        System.out.println("RECUPERACIÓN DE CONTRASEÑA (solo desarrollo)");
        System.out.println("Para: " + correo);
        System.out.println("Enlace (válido " + RecuperacionDAO.MINUTOS_VALIDEZ
                + " minutos): " + enlace);
        System.out.println("=====================================");
    }

    private void mostrarError(HttpServletRequest request,
                              HttpServletResponse response,
                              String mensaje)
            throws ServletException, IOException {

        request.setAttribute("error", mensaje);
        request.getRequestDispatcher(VISTA).forward(request, response);
    }
}