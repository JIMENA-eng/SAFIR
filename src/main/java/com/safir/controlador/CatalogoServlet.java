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
 * Catálogo general.
 *
 * GET /catalogo          -> desglose de todas las categorías + todas las obras.
 * GET /catalogo?q=texto  -> igual, pero las obras filtradas por la búsqueda.
 *
 * Las obras de UNA categoría se ven en /catalogo/categoria?id=N
 * (CategoriaServlet). Los enlaces antiguos /catalogo?genero=Nombre se
 * redirigen ahí para no romperlos.
 */
@WebServlet("/catalogo")
public class CatalogoServlet extends HttpServlet {

    private final ObraDAO obraDAO = new ObraDAO();
    private final GeneroDAO generoDAO = new GeneroDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String busqueda = request.getParameter("q");
        String generoAntiguo = request.getParameter("genero");

        try {
            // Compatibilidad: /catalogo?genero=Romance -> /catalogo/categoria?id=2
            if (generoAntiguo != null && !generoAntiguo.isBlank()) {
                Integer id = generoDAO.buscarIdPorNombre(generoAntiguo);
                if (id != null) {
                    response.sendRedirect(request.getContextPath()
                            + "/catalogo/categoria?id=" + id);
                    return;
                }
            }

            List<Genero> generos = generoDAO.listarConConteo();
            List<Obra> obras = obraDAO.listarPublicadas(busqueda, "");

            request.setAttribute("generos", generos);
            request.setAttribute("obras", obras);
            request.setAttribute("busqueda", busqueda == null ? "" : busqueda.trim());

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/catalogo/catalogo.jsp"
            ).forward(request, response);

        } catch (SQLException e) {
            throw new ServletException(
                    "Error al cargar el catálogo de obras.", e
            );
        }
    }
}