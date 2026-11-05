package com.safir.controlador;

import com.safir.dao.SocialDAO;
import com.safir.seguridad.SocialAuth;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.SQLException;
import java.util.Map;

/**
 * Inicio de sesión con Google, Facebook o X.
 *
 * GET /auth/social/{proveedor}           -> envía al usuario al proveedor.
 * GET /auth/social/{proveedor}/callback  -> el proveedor devuelve aquí el código.
 *
 * Direcciones de redirección que hay que registrar en cada proveedor:
 *   {BASE}/auth/social/google/callback, .../facebook/callback, .../x/callback
 * donde BASE es SAFIR_URL_BASE o, si no existe, la dirección de la petición
 * (ej. http://localhost:8080/safir).
 */
@WebServlet("/auth/social/*")
public class SocialServlet extends HttpServlet {

    private static final String VISTA_LOGIN = "/WEB-INF/vistas/autenticacion/login.jsp";

    private final SocialDAO socialDAO = new SocialDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String info = request.getPathInfo();
        String[] partes = (info == null) ? new String[0]
                : info.replaceFirst("^/", "").split("/");

        if (partes.length == 0 || !SocialAuth.esProveedor(partes[0])) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        String proveedor = partes[0];

        if (!SocialAuth.configurado(proveedor)) {
            error(request, response, "Este método de acceso no está disponible por ahora.");
            return;
        }

        if (partes.length == 1) {
            iniciar(request, response, proveedor);
        } else if (partes.length == 2 && "callback".equals(partes[1])) {
            retorno(request, response, proveedor);
        } else {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void iniciar(HttpServletRequest request, HttpServletResponse response,
                         String proveedor) throws IOException {

        String state = SocialAuth.aleatorio();
        String verificador = SocialAuth.aleatorio();

        HttpSession s = request.getSession(true);
        s.setAttribute("oauth.proveedor", proveedor);
        s.setAttribute("oauth.state", state);
        s.setAttribute("oauth.verificador", verificador);

        response.sendRedirect(SocialAuth.urlAutorizacion(
                proveedor, urlRetorno(request, proveedor), state, verificador));
    }

    private void retorno(HttpServletRequest request, HttpServletResponse response,
                         String proveedor) throws ServletException, IOException {

        HttpSession s = request.getSession(false);
        String stateEsperado = (s == null) ? null : (String) s.getAttribute("oauth.state");
        String provEsperado = (s == null) ? null : (String) s.getAttribute("oauth.proveedor");
        String verificador = (s == null) ? null : (String) s.getAttribute("oauth.verificador");

        if (s != null) {
            s.removeAttribute("oauth.state");
            s.removeAttribute("oauth.proveedor");
            s.removeAttribute("oauth.verificador");
        }

        // El usuario canceló o el proveedor devolvió un error.
        if (request.getParameter("error") != null) {
            error(request, response, "Cancelaste el inicio de sesión o el proveedor lo rechazó.");
            return;
        }

        String state = request.getParameter("state");
        String codigo = request.getParameter("code");

        if (stateEsperado == null || state == null || codigo == null
                || !proveedor.equals(provEsperado)
                || !MessageDigest.isEqual(
                        stateEsperado.getBytes(StandardCharsets.UTF_8),
                        state.getBytes(StandardCharsets.UTF_8))) {
            error(request, response,
                    "La sesión de acceso expiró. Vuelve a intentarlo.");
            return;
        }

        SocialAuth.Perfil perfil;
        try {
            perfil = SocialAuth.obtenerPerfil(proveedor, codigo,
                    urlRetorno(request, proveedor), verificador);
        } catch (IOException | RuntimeException e) {
            log("Error al consultar al proveedor " + proveedor, e);
            error(request, response, "No pudimos conectar con el proveedor. Inténtalo de nuevo.");
            return;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            error(request, response, "No pudimos conectar con el proveedor. Inténtalo de nuevo.");
            return;
        }

        SocialDAO.Resultado r;
        Map<String, Object> usuario;
        try {
            r = socialDAO.entrar(proveedor, perfil);
            if (r.error != null) {
                error(request, response, r.error);
                return;
            }
            usuario = socialDAO.datosSesion(r.usuarioId);
        } catch (SQLException e) {
            log("Error al iniciar sesión con " + proveedor, e);
            error(request, response, "Ocurrió un error al conectar con la base de datos.");
            return;
        }

        if (usuario == null) {
            error(request, response, "Tu cuenta no está disponible.");
            return;
        }

        // Sesión nueva (evita fijación de sesión)
        HttpSession anterior = request.getSession(false);
        if (anterior != null) {
            anterior.invalidate();
        }
        HttpSession sesion = request.getSession(true);
        request.changeSessionId();
        sesion.setAttribute("usuarioId", usuario.get("id"));
        sesion.setAttribute("nombreUsuario", usuario.get("nombre"));
        sesion.setAttribute("roles", usuario.get("roles"));
        sesion.setAttribute("avatarRuta", usuario.get("avatarRuta"));

        response.sendRedirect(request.getContextPath()
                + (r.nuevo ? "/auth/fotos" : "/auth/inicio"));
    }

    /** Dirección de retorno; debe ser idéntica a la registrada en el proveedor. */
    private String urlRetorno(HttpServletRequest request, String proveedor) {
        String base = System.getenv("SAFIR_URL_BASE");
        if (base == null || base.isBlank()) base = System.getProperty("SAFIR_URL_BASE");

        if (base == null || base.isBlank()) {
            int puerto = request.getServerPort();
            boolean porDefecto =
                    ("http".equals(request.getScheme()) && puerto == 80)
                    || ("https".equals(request.getScheme()) && puerto == 443);
            base = request.getScheme() + "://" + request.getServerName()
                    + (porDefecto ? "" : ":" + puerto) + request.getContextPath();
        }
        if (base.endsWith("/")) base = base.substring(0, base.length() - 1);
        return base + "/auth/social/" + proveedor + "/callback";
    }

    private void error(HttpServletRequest request, HttpServletResponse response,
                       String mensaje) throws ServletException, IOException {
        request.setAttribute("error", mensaje);
        request.getRequestDispatcher(VISTA_LOGIN).forward(request, response);
    }
}