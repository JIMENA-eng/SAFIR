package com.safir.controlador;

import com.safir.dao.NotificacionDAO;
import com.safir.modelo.Notificacion;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * TAREA 5: datos de los iconos de mensajes y notificaciones del encabezado.
 *
 * GET /notificaciones/resumen  ->  JSON
 * {
 *   "mensajes":  { "noLeidas": 3, "items": [ {id, tipo, mensaje, creadoEn, leida, url}, ... ] },
 *   "actividad": { "noLeidas": 5, "items": [ ... ] }
 * }
 *
 * Lo pide /assets/js/avisos.js al cargar cada página y cada minuto.
 */
@WebServlet("/notificaciones/resumen")
public class NotificacionResumenServlet extends HttpServlet {

    /** Cuántas notificaciones se ven en el desglose al pasar el cursor. */
    private static final int ITEMS_DESGLOSE = 5;

    private final NotificacionDAO notificacionDAO = new NotificacionDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json; charset=UTF-8");
        response.setHeader("Cache-Control", "no-store");

        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"sin_sesion\"}");
            return;
        }

        long usuarioId;
        try {
            usuarioId = Long.parseLong(sesion.getAttribute("usuarioId").toString());
        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"sin_sesion\"}");
            return;
        }

        try {
            long[] noLeidas = notificacionDAO.contarNoLeidasPorCategoria(usuarioId);
            List<Notificacion> mensajes = notificacionDAO.listarRecientes(
                    usuarioId, NotificacionDAO.CATEGORIA_MENSAJES, ITEMS_DESGLOSE);
            List<Notificacion> actividad = notificacionDAO.listarRecientes(
                    usuarioId, NotificacionDAO.CATEGORIA_ACTIVIDAD, ITEMS_DESGLOSE);

            String ctx = request.getContextPath();
            StringBuilder json = new StringBuilder(2048);
            json.append('{');
            bloque(json, "mensajes", noLeidas[0], mensajes, ctx);
            json.append(',');
            bloque(json, "actividad", noLeidas[1], actividad, ctx);
            json.append('}');

            response.getWriter().write(json.toString());

        } catch (SQLException e) {
            log("No se pudo armar el resumen de notificaciones", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("{\"error\":\"bd\"}");
        }
    }

    private void bloque(StringBuilder json, String categoria, long noLeidas,
                        List<Notificacion> items, String ctx) {

        json.append('"').append(categoria).append("\":{\"noLeidas\":").append(noLeidas)
            .append(",\"items\":[");

        for (int i = 0; i < items.size(); i++) {
            Notificacion n = items.get(i);
            if (i > 0) json.append(',');
            json.append("{\"id\":").append(n.getId())
                .append(",\"tipo\":").append(texto(n.getTipoTexto()))
                .append(",\"mensaje\":").append(texto(n.getMensaje()))
                .append(",\"creadoEn\":").append(texto(n.getCreadoEn() == null ? null : n.getCreadoEn().toString()))
                .append(",\"leida\":").append(n.isLeida())
                .append(",\"url\":").append(texto(ctx + "/notificaciones?ver=" + categoria + "#notif-" + n.getId()))
                .append('}');
        }

        json.append("]}");
    }

    /** Cadena JSON escapada (o null). */
    private static String texto(String s) {
        if (s == null) return "null";
        StringBuilder b = new StringBuilder(s.length() + 2).append('"');
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"':  b.append("\\\""); break;
                case '\\': b.append("\\\\"); break;
                case '\n': b.append("\\n"); break;
                case '\r': b.append("\\r"); break;
                case '\t': b.append("\\t"); break;
                case '<':  b.append("\\u003c"); break;
                default:
                    if (c < 0x20) b.append(String.format("\\u%04x", (int) c));
                    else b.append(c);
            }
        }
        return b.append('"').toString();
    }
}