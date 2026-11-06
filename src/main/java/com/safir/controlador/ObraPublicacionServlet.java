package com.safir.controlador;

import com.safir.dao.ObraEdicionDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Quita una obra del catálogo (despublicar) o la vuelve a publicar.
 * POST /autor/obra/publicar | /autor/obra/despublicar  (parámetro obraId).
 *
 * La publicación normal YA NO se hace desde el panel de autor: la obra se
 * publica sola al publicar su primer capítulo (GestionCapituloDAO.publicar).
 * "publicar" queda solo para obras despublicadas que ya tienen capítulos
 * publicados, y se usa desde "Mis borradores" en Mi cuenta.
 * El rol de autor ya lo exige AutorizacionFilter para /autor/*.
 */
@WebServlet({"/autor/obra/publicar", "/autor/obra/despublicar"})
public class ObraPublicacionServlet extends HttpServlet {

    private final ObraEdicionDAO dao = new ObraEdicionDAO();

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null
                || !(sesion.getAttribute("usuarioId") instanceof Number)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long autorId = ((Number) sesion.getAttribute("usuarioId")).longValue();
        long obraId;

        try {
            obraId = Long.parseLong(request.getParameter("obraId"));
            if (obraId <= 0) {
                throw new NumberFormatException();
            }
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "El identificador de la obra no es válido.");
            return;
        }

        boolean publicar =
                "/autor/obra/publicar".equals(request.getServletPath());

        String destino;

        try {
            boolean ok = publicar
                    ? dao.publicar(obraId, autorId)
                    : dao.volverABorrador(obraId, autorId);

            if (ok) {
                destino = publicar ? "publicada=1" : "despublicada=1";
            } else if (publicar) {
                String motivo = dao.motivoNoPublicable(obraId, autorId);
                destino = "error=" + (motivo != null ? motivo : "publicar");
            } else {
                destino = "error=despublicar";
            }
        } catch (SQLException e) {
            // Aquí cae, por ejemplo, un error del trigger fn_obra_validar_autor.
            log("Error al cambiar el estado de la obra " + obraId
                    + " (SQLState " + e.getSQLState() + "): " + e.getMessage(), e);
            destino = "error=bd";
        }

        // Ahora el resultado se muestra en Mi cuenta > Mis obras y listas
        response.sendRedirect(
                request.getContextPath() + "/auth/cuenta?" + destino
                + "#mis-obras");
    }
}