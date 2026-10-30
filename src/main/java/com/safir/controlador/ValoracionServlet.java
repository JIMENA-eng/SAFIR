package com.safir.controlador;

import com.safir.dao.ValoracionDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/valoracion")
public class ValoracionServlet extends HttpServlet {

    private final ValoracionDAO valoracionDAO = new ValoracionDAO();

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

            long obraId = Long.parseLong(
                request.getParameter("obraId")
            );

            int puntaje = Integer.parseInt(
                request.getParameter("puntaje")
            );

            String resena = request.getParameter("resena");

            if (puntaje < 1 || puntaje > 5) {
                response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "El puntaje debe estar entre 1 y 5."
                );
                return;
            }

            if (resena != null && resena.length() > 5000) {
                response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "La reseña es demasiado larga."
                );
                return;
            }

            boolean guardado = valoracionDAO.guardar(
                usuarioId, obraId, puntaje, resena
            );

            if (!guardado) {
                response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "La obra no existe o no está publicada."
                );
                return;
            }

            response.sendRedirect(
                request.getContextPath() + "/obra?id=" + obraId
            );

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Los datos de la valoración no son válidos."
            );
        } catch (SQLException e) {
            throw new ServletException(
                "Error al guardar la valoración.", e
            );
        }
    }
}