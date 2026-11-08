package com.safir.controlador;

import com.safir.dao.GeneroDAO;
import com.safir.dao.ObraDAO;
import com.safir.modelo.Genero;
import com.safir.modelo.Obra;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Página de una categoría: solo las obras publicadas de ese género.
 *
 * GET /catalogo/categoria?id=N          -> obras de la categoría N.
 * GET /catalogo/categoria?id=N&q=texto  -> búsqueda dentro de la categoría.
 */
@WebServlet("/catalogo/categoria")
public class CategoriaServlet extends HttpServlet {

    private final ObraDAO obraDAO = new ObraDAO();
    private final GeneroDAO generoDAO = new GeneroDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        int id;
        try {
            id = Integer.parseInt(request.getParameter("id"));
        } catch (NumberFormatException e) {
            // Sin id válido (o sin id): vuelve al desglose de categorías.
            response.sendRedirect(request.getContextPath() + "/catalogo");
            return;
        }

        String busqueda = request.getParameter("q");

        try {
            Genero genero = generoDAO.buscarPorId(id);
            if (genero == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            List<Obra> obras = obraDAO.listarPublicadas(busqueda, genero.getNombre());
            List<Genero> generos = generoDAO.listarConConteo();

            request.setAttribute("genero", genero);
            request.setAttribute("generos", generos);
            request.setAttribute("obras", obras);
            request.setAttribute("busqueda", busqueda == null ? "" : busqueda.trim());

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/catalogo/categoria.jsp"
            ).forward(request, response);

        } catch (SQLException e) {
            throw new ServletException(
                    "Error al cargar la categoría.", e
            );
        }
    }
}