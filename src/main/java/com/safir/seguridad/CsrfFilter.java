package com.safir.seguridad;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletOutputStream;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpServletResponseWrapper;
import jakarta.servlet.http.HttpSession;

import java.io.CharArrayWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Protección CSRF para toda la aplicación.
 *
 * 1) PETICIONES: todo método que cambia datos (POST, PUT, PATCH, DELETE)
 *    debe traer el token de la sesión; si falta o no coincide se responde 403.
 *    El token se acepta, en este orden:
 *      - cabecera  X-CSRF-Token
 *      - formularios multipart: parámetro _csrf en la URL (el cuerpo no se
 *        lee aquí para no romper el mensaje de "archivo demasiado grande"
 *        de los servlets); si no está, se prueba el campo del formulario
 *      - cualquier otro: campo/parámetro _csrf del cuerpo
 *
 * 2) RESPUESTAS HTML: igual que IdiomaFilter, se reescribe la página para
 *    no tocar cada vista:
 *      - cada &lt;form method="post"&gt; recibe un campo oculto _csrf; si es
 *        multipart, además se añade _csrf a su action;
 *      - se añade &lt;meta name="csrf-token"&gt; en el head, para que el
 *        JavaScript (fetch, sendBeacon) lo lea.
 *    Solo toca respuestas escritas con getWriter() y de tipo text/html.
 *
 * El token (32 bytes aleatorios) vive en la sesión; si la página trae un
 * formulario POST y aún no hay sesión (login, registro, recuperar) se crea.
 * Las rutas de retorno de pasarelas y de OAuth son GET, así que no se ven
 * afectadas.
 */
@WebFilter(urlPatterns = "/*")
public class CsrfFilter implements Filter {

    public static final String PARAMETRO = "_csrf";
    public static final String CABECERA = "X-CSRF-Token";
    private static final String ATRIBUTO = "csrfToken";

    private static final Set<String> METODOS_SEGUROS =
            Set.of("GET", "HEAD", "OPTIONS", "TRACE");

    private static final SecureRandom ALEATORIO = new SecureRandom();

    private static final Pattern FORM =
            Pattern.compile("<form\\b[^>]*>", Pattern.CASE_INSENSITIVE);
    private static final Pattern METODO_POST = Pattern.compile(
            "\\bmethod\\s*=\\s*[\"']?post\\b", Pattern.CASE_INSENSITIVE);
    private static final Pattern MULTIPART = Pattern.compile(
            "\\benctype\\s*=\\s*[\"']?multipart/form-data", Pattern.CASE_INSENSITIVE);
    private static final Pattern ACTION = Pattern.compile(
            "(\\baction\\s*=\\s*\")([^\"]*)(\")", Pattern.CASE_INSENSITIVE);
    private static final Pattern HEAD = Pattern.compile(
            "<head\\b[^>]*>", Pattern.CASE_INSENSITIVE);

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String ruta = req.getRequestURI().substring(req.getContextPath().length());

        // Archivos estáticos y multimedia: no se tocan.
        if (ruta.startsWith("/assets/") || ruta.startsWith("/media/")) {
            chain.doFilter(request, response);
            return;
        }

        if (!METODOS_SEGUROS.contains(req.getMethod().toUpperCase(Locale.ROOT))
                && !tokenValido(req)) {
            res.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "La solicitud no es válida o tu sesión caducó. "
                    + "Recarga la página e inténtalo de nuevo.");
            return;
        }

        Captura envoltura = new Captura(res);
        chain.doFilter(request, envoltura);

        if (!envoltura.usoWriter()) {
            return;                     // binario, redirección o error: ya se envió tal cual
        }

        String cuerpo = envoltura.texto();
        String tipo = envoltura.getContentType();

        if (tipo != null && tipo.toLowerCase(Locale.ROOT).startsWith("text/html")
                && !cuerpo.isEmpty() && !res.isCommitted()) {
            cuerpo = inyectar(req, cuerpo);
        }

        if (!cuerpo.isEmpty()) {
            PrintWriter salida = res.getWriter();
            salida.write(cuerpo);
            salida.flush();
        }
    }

    // ---- Validación -----------------------------------------------------

    private static boolean tokenValido(HttpServletRequest req) {
        HttpSession sesion = req.getSession(false);
        Object esperado = sesion == null ? null : sesion.getAttribute(ATRIBUTO);
        if (!(esperado instanceof String)) {
            return false;
        }

        String recibido = req.getHeader(CABECERA);

        if (recibido == null) {
            String tipo = req.getContentType();
            boolean multipart = tipo != null
                    && tipo.toLowerCase(Locale.ROOT).startsWith("multipart/");

            if (multipart) {
                recibido = deQuery(req.getQueryString());
            }

            if (recibido == null) {
                try {
                    // Sin esto, el cuerpo se leería en ISO-8859-1 y se
                    // estropearían las tildes antes de que el servlet
                    // pueda llamar a setCharacterEncoding("UTF-8").
                    if (req.getCharacterEncoding() == null) {
                        req.setCharacterEncoding("UTF-8");
                    }
                    recibido = req.getParameter(PARAMETRO);
                } catch (IllegalStateException | IOException e) {
                    recibido = null;    // multipart demasiado grande, etc.
                }
            }
        }

        return recibido != null && MessageDigest.isEqual(
                ((String) esperado).getBytes(StandardCharsets.UTF_8),
                recibido.getBytes(StandardCharsets.UTF_8));
    }

    /** Lee _csrf de la query string a mano, sin tocar el cuerpo de la petición. */
    private static String deQuery(String query) {
        if (query == null) {
            return null;
        }
        for (String par : query.split("&")) {
            if (par.startsWith(PARAMETRO + "=")) {
                return par.substring(PARAMETRO.length() + 1);
            }
        }
        return null;
    }

    // ---- Token ----------------------------------------------------------

    private static String token(HttpServletRequest req) {
        HttpSession sesion = req.getSession(true);
        Object actual = sesion.getAttribute(ATRIBUTO);
        if (actual instanceof String) {
            return (String) actual;
        }
        byte[] b = new byte[32];
        ALEATORIO.nextBytes(b);
        String nuevo = Base64.getUrlEncoder().withoutPadding().encodeToString(b);
        sesion.setAttribute(ATRIBUTO, nuevo);
        return nuevo;
    }

    // ---- Reescritura del HTML ------------------------------------------

    private static String inyectar(HttpServletRequest req, String html) {
        boolean hayForm = false;
        Matcher m = FORM.matcher(html);
        while (m.find()) {
            if (METODO_POST.matcher(m.group()).find()) {
                hayForm = true;
                break;
            }
        }

        // Sin formularios POST y sin sesión: no hay nada que proteger ni se crea sesión.
        if (!hayForm && req.getSession(false) == null) {
            return html;
        }

        String token = token(req);

        StringBuilder sb = new StringBuilder(html.length() + 256);
        m = FORM.matcher(html);
        int desde = 0;
        while (m.find()) {
            String etiqueta = m.group();
            if (!METODO_POST.matcher(etiqueta).find()) {
                continue;
            }
            if (MULTIPART.matcher(etiqueta).find()) {
                Matcher a = ACTION.matcher(etiqueta);
                if (a.find()) {
                    String url = a.group(2);
                    String nueva = url + (url.contains("?") ? "&" : "?")
                            + PARAMETRO + "=" + token;
                    etiqueta = etiqueta.substring(0, a.start(2)) + nueva
                            + etiqueta.substring(a.end(2));
                }
            }
            sb.append(html, desde, m.start()).append(etiqueta)
              .append("<input type=\"hidden\" name=\"").append(PARAMETRO)
              .append("\" value=\"").append(token).append("\">");
            desde = m.end();
        }
        sb.append(html, desde, html.length());
        String resultado = sb.toString();

        Matcher h = HEAD.matcher(resultado);
        if (h.find()) {
            resultado = resultado.substring(0, h.end())
                    + "\n<meta name=\"csrf-token\" content=\"" + token + "\">"
                    + resultado.substring(h.end());
        }
        return resultado;
    }

    // ---- Captura de la respuesta (mismo esquema que IdiomaFilter) --------

    private static final class Captura extends HttpServletResponseWrapper {

        private final CharArrayWriter buffer = new CharArrayWriter();
        private PrintWriter writer;
        private boolean usoStream;
        private long largoPendiente = -1;

        Captura(HttpServletResponse respuesta) {
            super(respuesta);
        }

        boolean usoWriter() {
            return writer != null;
        }

        String texto() {
            writer.flush();
            return buffer.toString();
        }

        @Override
        public PrintWriter getWriter() {
            if (usoStream) {
                throw new IllegalStateException("getOutputStream() ya fue llamado");
            }
            if (writer == null) {
                writer = new PrintWriter(buffer);
            }
            return writer;
        }

        @Override
        public ServletOutputStream getOutputStream() throws IOException {
            if (writer != null) {
                throw new IllegalStateException("getWriter() ya fue llamado");
            }
            usoStream = true;
            if (largoPendiente >= 0) {
                super.setContentLengthLong(largoPendiente);
            }
            return super.getOutputStream();
        }

        // El largo cambia al inyectar el token: solo se respeta si se usa el stream.
        @Override
        public void setContentLength(int largo) {
            setContentLengthLong(largo);
        }

        @Override
        public void setContentLengthLong(long largo) {
            if (usoStream) {
                super.setContentLengthLong(largo);
            } else {
                largoPendiente = largo;
            }
        }

        @Override
        public void flushBuffer() throws IOException {
            if (writer != null) {
                writer.flush();          // no envía nada todavía
            } else {
                super.flushBuffer();
            }
        }

        @Override
        public void resetBuffer() {
            buffer.reset();
            if (writer == null) {
                super.resetBuffer();
            }
        }

        @Override
        public void reset() {
            buffer.reset();
            largoPendiente = -1;
            super.reset();
        }
    }
}