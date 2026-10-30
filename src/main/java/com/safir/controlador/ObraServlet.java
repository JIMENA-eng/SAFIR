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

@WebServlet("/obra")
public class ObraServlet extends HttpServlet {

    private final ObraDAO obraDAO = new ObraDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        String idTexto = request.getParameter("id");

        if (idTexto == null || idTexto.isBlank()) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Debe especificar el ID de la obra."
            );
            return;
        }

        long id;

        try {
            id = Long.parseLong(idTexto);

            if (id <= 0) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "El ID de la obra no es válido."
            );
            return;
        }

        try {
            Obra obra = obraDAO.buscarPublicadaPorId(id);

            if (obra == null) {
                response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "La obra no existe o no está publicada."
                );
                return;
            }

            request.setAttribute("obra", obra);

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/catalogo/detalle.jsp"
            ).forward(request, response);

        } catch (SQLException e) {
            throw new ServletException(
                    "Error al consultar los detalles de la obra.", e
            );
        }
    }
}