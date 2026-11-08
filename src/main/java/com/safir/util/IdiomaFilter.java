package com.safir.util;

import jakarta.servlet.DispatcherType;
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

import java.io.CharArrayWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Locale;

/**
 * TAREA 4: selector de idioma en TODA la página.
 *
 * Agrega <script src=".../assets/js/idioma.js"> justo antes de </body> en
 * todas las respuestas HTML (JSP), así no hay que tocar cada vista y las
 * páginas nuevas lo reciben solas.
 *
 * Solo toca respuestas escritas con getWriter() y con tipo text/html.
 * Imágenes, archivos y todo lo que use getOutputStream() pasan intactos.
 */
@WebFilter(urlPatterns = "/*",
           dispatcherTypes = {DispatcherType.REQUEST, DispatcherType.ERROR})
public class IdiomaFilter implements Filter {

    private static final String SCRIPT = "/assets/js/idioma.js";

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

        RespuestaCapturada envoltura = new RespuestaCapturada(res);
        chain.doFilter(request, envoltura);

        if (!envoltura.usoWriter()) {
            return;                     // binario, redirección o error: ya se envió tal cual
        }

        String cuerpo = envoltura.texto();
        String tipo = envoltura.getContentType();

        if (tipo != null && tipo.toLowerCase(Locale.ROOT).startsWith("text/html")
                && !cuerpo.contains(SCRIPT)) {

            int cierre = cuerpo.toLowerCase(Locale.ROOT).lastIndexOf("</body>");
            if (cierre >= 0) {
                String etiqueta = "<script src=\"" + req.getContextPath() + SCRIPT
                        + "\" defer></script>\n";
                cuerpo = cuerpo.substring(0, cierre) + etiqueta + cuerpo.substring(cierre);
            }
        }

        if (!cuerpo.isEmpty()) {
            PrintWriter salida = res.getWriter();
            salida.write(cuerpo);
            salida.flush();
        }
    }

    /** Guarda en memoria lo que se escribe con getWriter() para poder modificarlo. */
    private static final class RespuestaCapturada extends HttpServletResponseWrapper {

        private final CharArrayWriter buffer = new CharArrayWriter();
        private PrintWriter writer;
        private boolean usoStream;
        private long largoPendiente = -1;

        RespuestaCapturada(HttpServletResponse respuesta) {
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

        // El largo cambia al inyectar el script: solo se respeta si se usa el stream.
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