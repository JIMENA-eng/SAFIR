package com.safir.controlador;

import com.safir.dao.UsuarioDAO;
import com.safir.dao.VerificacionDAO;
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
 * Paso 2 del registro: confirmar el código recibido por correo o SMS.
 *
 * GET  /auth/verificar -> formulario del código.
 * POST /auth/verificar -> accion=confirmar (crea la cuenta) o accion=reenviar.
 */
@WebServlet("/auth/verificar")
public class VerificarServlet extends HttpServlet {

    private static final String VISTA = "/WEB-INF/vistas/autenticacion/verificar.jsp";
    private static final String SQLSTATE_UNICIDAD = "23505";

    private final VerificacionDAO verificacionDAO = new VerificacionDAO();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Long id = pendiente(request);
        if (id == null) {
            response.sendRedirect(request.getContextPath() + "/auth/registro");
            return;
        }
        mostrar(request, response, id, null, null);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Long id = pendiente(request);
        if (id == null) {
            response.sendRedirect(request.getContextPath() + "/auth/registro");
            return;
        }

        try {
            if ("reenviar".equals(request.getParameter("accion"))) {
                reenviar(request, response, id);
            } else {
                confirmar(request, response, id);
            }
        } catch (SQLException e) {
            log("Error en la verificación del registro", e);
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

        Map<String, String> r = verificacionDAO.confirmar(id, codigo);
        String estado = r.get("estado");

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
            request.getSession().removeAttribute("verifId");
            request.setAttribute("error",
                    "El código venció. Completa el registro de nuevo.");
            request.getRequestDispatcher("/WEB-INF/vistas/autenticacion/registro.jsp")
                    .forward(request, response);
            return;
        }

        boolean porTelefono = "telefono".equals(r.get("canal"));
        long usuarioId;
        try {
            usuarioId = usuarioDAO.registrarVerificado(
                    porTelefono ? null : r.get("destino"),
                    porTelefono ? r.get("destino") : null,
                    r.get("nombreUsuario"), r.get("nombrePublico"),
                    r.get("hashClave"));
        } catch (SQLException e) {
            request.getSession().removeAttribute("verifId");
            if (SQLSTATE_UNICIDAD.equals(e.getSQLState())) {
                request.setAttribute("error",
                        "Ese usuario, sobrenombre o contacto ya fue tomado. "
                        + "Completa el registro de nuevo.");
                request.getRequestDispatcher(
                        "/WEB-INF/vistas/autenticacion/registro.jsp")
                        .forward(request, response);
                return;
            }
            throw e;
        }

        // Cuenta creada: se inicia sesión automáticamente (sesión nueva,
        // evita fijación de sesión) y se ofrece subir las fotos.
        HttpSession anterior = request.getSession(false);
        if (anterior != null) {
            anterior.invalidate();
        }
        HttpSession sesion = request.getSession(true);
        request.changeSessionId();
        sesion.setAttribute("usuarioId", usuarioId);
        sesion.setAttribute("nombreUsuario", r.get("nombrePublico"));
        sesion.setAttribute("roles", "lector");
        sesion.setAttribute("avatarRuta", null);

        response.sendRedirect(request.getContextPath() + "/auth/fotos");
    }

    private void reenviar(HttpServletRequest request,
                          HttpServletResponse response, long id)
            throws SQLException, ServletException, IOException {

        Map<String, String> p = verificacionDAO.obtener(id);
        if (p == null) {
            response.sendRedirect(request.getContextPath() + "/auth/registro");
            return;
        }

        String codigo = VerificacionDAO.generarCodigo();
        if (!verificacionDAO.renovarCodigo(id, p.get("destino"), codigo)) {
            mostrar(request, response, id,
                    "Espera un minuto antes de pedir otro código.", null);
            return;
        }

        if (!EnvioCodigo.enviar(p.get("canal"), p.get("destino"), codigo,
                VerificacionDAO.MINUTOS_VALIDEZ)) {
            mostrar(request, response, id,
                    "No pudimos enviar el código. Inténtalo de nuevo en un minuto.", null);
            return;
        }
        mostrar(request, response, id, null, "Te enviamos un código nuevo.");
    }

    private Long pendiente(HttpServletRequest request) {
        HttpSession s = request.getSession(false);
        Object v = (s == null) ? null : s.getAttribute("verifId");
        return (v instanceof Long) ? (Long) v : null;
    }

    private void mostrar(HttpServletRequest request, HttpServletResponse response,
                         long id, String error, String info)
            throws ServletException, IOException {

        try {
            Map<String, String> p = verificacionDAO.obtener(id);
            if (p == null) {
                response.sendRedirect(request.getContextPath() + "/auth/registro");
                return;
            }
            request.setAttribute("destinoOculto",
                    ocultar(p.get("canal"), p.get("destino")));
            request.setAttribute("canal", p.get("canal"));
        } catch (SQLException e) {
            log("Error al leer el registro pendiente", e);
        }
        request.setAttribute("error", error);
        request.setAttribute("info", info);
        request.getRequestDispatcher(VISTA).forward(request, response);
    }

    /** juan.perez@gmail.com -> ju***@gmail.com ; +51999888777 -> +51******777 */
    private static String ocultar(String canal, String destino) {
        if ("telefono".equals(canal)) {
            int n = destino.length();
            return destino.substring(0, 3) + "*".repeat(Math.max(0, n - 6))
                    + destino.substring(n - 3);
        }
        int at = destino.indexOf('@');
        String local = destino.substring(0, at);
        return local.substring(0, Math.min(2, local.length())) + "***"
                + destino.substring(at);
    }
}