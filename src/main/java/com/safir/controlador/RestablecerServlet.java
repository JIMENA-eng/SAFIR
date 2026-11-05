package com.safir.controlador;

import com.safir.dao.RecuperacionDAO;
import com.safir.dao.VerificacionDAO;
import com.safir.seguridad.ValidadorRegistro;
import com.safir.util.EnvioCodigo;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

/**
 * Pasos 2 y 3 de la recuperación de contraseña (una sola URL, tres pantallas):
 *
 *   paso "codigo" -> escribir el código de 6 dígitos (accion=confirmar / reenviar)
 *   paso "clave"  -> contraseña nueva y confirmación (accion=guardar)
 *   paso "listo"  -> aviso: la próxima recuperación será dentro de 30 días
 *
 * La solicitud en curso se guarda en la sesión (atributo "recId").
 */
@WebServlet("/auth/restablecer")
public class RestablecerServlet extends HttpServlet {

    private static final String VISTA =
            "/WEB-INF/vistas/autenticacion/restablecer.jsp";
    private static final String VISTA_RECUPERAR =
            "/WEB-INF/vistas/autenticacion/recuperar.jsp";

    private final RecuperacionDAO dao = new RecuperacionDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        // Pantalla final, una sola vez.
        if (sesion != null && sesion.getAttribute("recListo") != null) {
            sesion.removeAttribute("recListo");
            request.setAttribute("paso", "listo");
            request.setAttribute("dias", RecuperacionDAO.DIAS_BLOQUEO);
            request.getRequestDispatcher(VISTA).forward(request, response);
            return;
        }

        Long id = solicitud(request);
        if (id == null) {
            response.sendRedirect(request.getContextPath() + "/auth/recuperar");
            return;
        }
        mostrar(request, response, id, null, null);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Long id = solicitud(request);
        if (id == null) {
            response.sendRedirect(request.getContextPath() + "/auth/recuperar");
            return;
        }

        try {
            String accion = request.getParameter("accion");
            if ("reenviar".equals(accion)) {
                reenviar(request, response, id);
            } else if ("guardar".equals(accion)) {
                guardar(request, response, id);
            } else {
                confirmar(request, response, id);
            }
        } catch (SQLException e) {
            log("Error en la recuperación de contraseña", e);
            mostrar(request, response, id,
                    "Ocurrió un error al conectar con la base de datos.", null);
        }
    }

    private void confirmar(HttpServletRequest request,
                           HttpServletResponse response, long id)
            throws SQLException, ServletException, IOException {

        String codigo = request.getParameter("codigo");
        if (codigo == null || !codigo.trim().matches("\\d{6}")) {
            mostrar(request, response, id, "Escribe el código de 6 dígitos.", null);
            return;
        }

        String estado = dao.confirmarCodigo(id, codigo);

        if (VerificacionDAO.INCORRECTO.equals(estado)) {
            mostrar(request, response, id, "Código incorrecto. Inténtalo de nuevo.", null);
            return;
        }
        if (VerificacionDAO.BLOQUEADO.equals(estado)) {
            mostrar(request, response, id,
                    "Demasiados intentos. Pide un código nuevo.", null);
            return;
        }
        if (!VerificacionDAO.OK.equals(estado)) {
            solicitudVencida(request, response);
            return;
        }

        // Código correcto: se muestra el formulario de contraseña nueva.
        response.sendRedirect(request.getContextPath() + "/auth/restablecer");
    }

    private void reenviar(HttpServletRequest request,
                          HttpServletResponse response, long id)
            throws SQLException, ServletException, IOException {

        Map<String, String> s = dao.obtener(id);
        if (s == null) {
            solicitudVencida(request, response);
            return;
        }

        String codigo = VerificacionDAO.generarCodigo();
        if (!dao.renovarCodigo(id, codigo)) {
            mostrar(request, response, id,
                    "Espera un minuto antes de pedir otro código.", null);
            return;
        }
        if (!EnvioCodigo.enviar("correo", s.get("correo"), codigo,
                RecuperacionDAO.MINUTOS_VALIDEZ)) {
            mostrar(request, response, id,
                    "No pudimos enviar el código. Inténtalo de nuevo en un minuto.", null);
            return;
        }
        mostrar(request, response, id, null, "Te enviamos un código nuevo.");
    }

    private void guardar(HttpServletRequest request,
                         HttpServletResponse response, long id)
            throws SQLException, ServletException, IOException {

        Map<String, String> s = dao.obtener(id);
        if (s == null || !"true".equals(s.get("vigente"))) {
            solicitudVencida(request, response);
            return;
        }
        if (!"true".equals(s.get("verificado"))) {
            // Intento de saltarse el código.
            response.sendRedirect(request.getContextPath() + "/auth/restablecer");
            return;
        }

        String clave = request.getParameter("clave");
        String repetir = request.getParameter("repetir");

        String errorClave = ValidadorRegistro.errorClave(clave);
        if (errorClave != null) {
            mostrar(request, response, id, errorClave, null);
            return;
        }
        if (!clave.equals(repetir)) {
            mostrar(request, response, id, "Las contraseñas no coinciden.", null);
            return;
        }

        if (!dao.restablecer(id, clave)) {
            solicitudVencida(request, response);
            return;
        }

        HttpSession sesion = request.getSession();
        sesion.removeAttribute("recId");
        sesion.setAttribute("recListo", Boolean.TRUE);
        response.sendRedirect(request.getContextPath() + "/auth/restablecer");
    }

    private Long solicitud(HttpServletRequest request) {
        HttpSession s = request.getSession(false);
        Object v = (s == null) ? null : s.getAttribute("recId");
        return (v instanceof Long) ? (Long) v : null;
    }

    private void solicitudVencida(HttpServletRequest request,
                                  HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession s = request.getSession(false);
        if (s != null) s.removeAttribute("recId");
        request.setAttribute("error",
                "El código venció. Pide uno nuevo para continuar.");
        request.getRequestDispatcher(VISTA_RECUPERAR).forward(request, response);
    }

    private void mostrar(HttpServletRequest request,
                         HttpServletResponse response,
                         long id, String error, String info)
            throws ServletException, IOException {

        try {
            Map<String, String> s = dao.obtener(id);
            if (s == null) {
                response.sendRedirect(request.getContextPath() + "/auth/recuperar");
                return;
            }
            if (!"true".equals(s.get("vigente"))) {
                solicitudVencida(request, response);
                return;
            }
            request.setAttribute("correoOculto", ocultar(s.get("correo")));
            request.setAttribute("paso",
                    "true".equals(s.get("verificado")) ? "clave" : "codigo");
        } catch (SQLException e) {
            log("Error al leer la solicitud de recuperación", e);
            request.setAttribute("paso", "codigo");
        }
        request.setAttribute("error", error);
        request.setAttribute("info", info);
        request.getRequestDispatcher(VISTA).forward(request, response);
    }

    /** juan.perez@gmail.com -> ju***@gmail.com */
    private static String ocultar(String correo) {
        if (correo == null || !correo.contains("@")) return "";
        int at = correo.indexOf('@');
        String local = correo.substring(0, at);
        return local.substring(0, Math.min(2, local.length())) + "***" + correo.substring(at);
    }
}