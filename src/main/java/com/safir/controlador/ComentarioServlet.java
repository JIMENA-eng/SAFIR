package com.safir.controlador;

import com.safir.dao.ComentarioDAO;
import com.safir.modelo.Comentario;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/comentarios")
public class ComentarioServlet extends HttpServlet {

    private final ComentarioDAO comentarioDAO = new ComentarioDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        try {
            long capituloId = Long.parseLong(
                request.getParameter("capituloId")
            );

            List<Comentario> comentarios =
                comentarioDAO.listarPorCapitulo(capituloId);

            request.setAttribute("comentarios", comentarios);

            request.getRequestDispatcher(
                "/WEB-INF/vistas/lectura/comentarios.jsp"
            ).forward(request, response);

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Identificador de capítulo inválido."
            );
        } catch (SQLException e) {
            throw new ServletException(
                "Error al consultar comentarios.", e
            );
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession sesion = request.getSession(false);

        if (sesion == null
                || sesion.getAttribute("usuarioId") == null) {
            response.sendError(
                HttpServletResponse.SC_UNAUTHORIZED
            );
            return;
        }

        try {
            long usuarioId = Long.parseLong(
                sesion.getAttribute("usuarioId").toString()
            );

            long capituloId = Long.parseLong(
                request.getParameter("capituloId")
            );

            String texto = request.getParameter("texto");
            String padreParametro = request.getParameter("padreId");

            if (texto == null || texto.isBlank()
                    || texto.trim().length() > 2000) {
                response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "El comentario debe tener entre 1 y 2000 caracteres."
                );
                return;
            }

            Long padreId = null;

            if (padreParametro != null
                    && !padreParametro.isBlank()) {
                padreId = Long.parseLong(padreParametro);
            }

            boolean guardado = comentarioDAO.insertar(
                usuarioId, capituloId, padreId, texto
            );

            if (!guardado) {
                response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "El capítulo no existe o no está publicado."
                );
                return;
            }

            response.sendRedirect(
                request.getContextPath()
                + "/lectura?capituloId=" + capituloId
            );

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Los identificadores no son válidos."
            );
        } catch (SQLException e) {
            throw new ServletException(
                "Error al guardar el comentario.", e
            );
        }
    }
}