package com.safir.controlador;

import com.safir.dao.ObraDAO;
import com.safir.modelo.Obra;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/catalogo")
public class CatalogoServlet extends HttpServlet {

    private final ObraDAO obraDAO = new ObraDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String busqueda = request.getParameter("q");
        String genero = request.getParameter("genero");

        try {
            List<Obra> obras = obraDAO.listarPublicadas(busqueda, genero);

            request.setAttribute("obras", obras);
            request.setAttribute("busqueda", busqueda == null ? "" : busqueda);
            request.setAttribute("generoSeleccionado",
                    genero == null ? "" : genero);

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