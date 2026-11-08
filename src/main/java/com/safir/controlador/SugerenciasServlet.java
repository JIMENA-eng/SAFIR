package com.safir.controlador;

import com.safir.dao.BusquedaDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * TAREA 7: sugerencias mientras se escribe en el buscador del encabezado.
 *
 * GET /buscar/sugerencias?q=texto  ->  JSON
 * {
 *   "q": "texto",
 *   "obras":   [ {id, titulo, autor, genero, portada}, ... ],
 *   "autores": [ {nombre, usuario, avatar, obras}, ... ]
 * }
 *
 * Lo usa /assets/js/buscador.js. Solo devuelve datos públicos (obras
 * publicadas y autores activos), así que no exige sesión.
 */
@WebServlet("/buscar/sugerencias")
public class SugerenciasServlet extends HttpServlet {

    private static final int MAX_OBRAS = 6;
    private static final int MAX_AUTORES = 4;
    private static final int MAX_LARGO = 60;

    private final BusquedaDAO busquedaDAO = new BusquedaDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");
        response.setHeader("Cache-Control", "no-store");

        String q = request.getParameter("q");
        q = q == null ? "" : q.trim();
        if (q.length() > MAX_LARGO) {
            q = q.substring(0, MAX_LARGO);
        }

        StringBuilder json = new StringBuilder(2048);
        json.append("{\"q\":").append(texto(q));

        if (q.isEmpty()) {
            json.append(",\"obras\":[],\"autores\":[]}");
            response.getWriter().write(json.toString());
            return;
        }

        try {
            List<Map<String, Object>> obras = busquedaDAO.sugerirObras(q, MAX_OBRAS);
            List<Map<String, Object>> autores = busquedaDAO.sugerirAutores(q, MAX_AUTORES);

            json.append(",\"obras\":").append(lista(obras));
            json.append(",\"autores\":").append(lista(autores));
            json.append('}');

            response.getWriter().write(json.toString());

        } catch (SQLException e) {
            log("No se pudieron buscar sugerencias", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("{\"error\":\"bd\"}");
        }
    }

    private static String lista(List<Map<String, Object>> filas) {
        StringBuilder b = new StringBuilder("[");
        for (int i = 0; i < filas.size(); i++) {
            if (i > 0) b.append(',');
            b.append('{');
            int j = 0;
            for (Map.Entry<String, Object> e : filas.get(i).entrySet()) {
                if (j++ > 0) b.append(',');
                b.append('"').append(e.getKey()).append("\":");
                Object v = e.getValue();
                b.append(v instanceof Number ? v.toString() : texto(v == null ? null : v.toString()));
            }
            b.append('}');
        }
        return b.append(']').toString();
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