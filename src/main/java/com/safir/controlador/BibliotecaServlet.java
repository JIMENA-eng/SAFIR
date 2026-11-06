package com.safir.controlador;

import com.safir.dao.BibliotecaDAO;
import com.safir.dao.SeguimientoDAO;
import com.safir.util.EncabezadoUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

import com.safir.modelo.Obra;

@WebServlet("/biblioteca")
public class BibliotecaServlet extends HttpServlet {

    private final BibliotecaDAO bibliotecaDAO = new BibliotecaDAO();
    private final SeguimientoDAO seguimientoDAO = new SeguimientoDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null
                || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(
                request.getContextPath() + "/login"
            );
            return;
        }

        try {
            long usuarioId = Long.parseLong(
                sesion.getAttribute("usuarioId").toString()
            );

            List<Obra> obras = bibliotecaDAO.listar(usuarioId);

            EncabezadoUtil.cargar(request, usuarioId);
            request.setAttribute("obras", obras);

            request.getRequestDispatcher(
                "/WEB-INF/vistas/biblioteca/biblioteca.jsp"
            ).forward(request, response);

        } catch (SQLException | NumberFormatException e) {
            throw new ServletException(
                "No se pudo cargar la biblioteca.", e
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

            long obraId = Long.parseLong(
                request.getParameter("obraId")
            );

            String accion = request.getParameter("accion");

            if (accion == null) {
                response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST
                );
                return;
            }

            switch (accion) {
                case "agregar" ->
                    bibliotecaDAO.agregar(usuarioId, obraId);

                case "estado" -> {
                    String estado = request.getParameter("estado");
                    bibliotecaDAO.actualizarEstado(
                        usuarioId, obraId, estado
                    );
                }

                case "favorito" -> {
                    boolean favorita = Boolean.parseBoolean(
                        request.getParameter("favorita")
                    );

                    bibliotecaDAO.cambiarFavorito(
                        usuarioId, obraId, favorita
                    );
                }

                case "eliminar" ->
                    bibliotecaDAO.eliminar(usuarioId, obraId);

                case "seguir" ->
                    seguimientoDAO.seguir(usuarioId, obraId);

                case "dejarDeSeguir" ->
                    seguimientoDAO.dejarDeSeguir(usuarioId, obraId);

                case "avisos" -> {
                    boolean avisar = Boolean.parseBoolean(
                        request.getParameter("avisar")
                    );

                    seguimientoDAO.cambiarAvisos(
                        usuarioId, obraId, avisar
                    );
                }

                default -> {
                    response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Acción no válida."
                    );
                    return;
                }
            }

            response.sendRedirect(
                request.getContextPath() + "/biblioteca"
            );

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "El identificador no es válido."
            );
        } catch (IllegalArgumentException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                e.getMessage()
            );
        } catch (SQLException e) {
            throw new ServletException(
                "No se pudo actualizar la biblioteca.", e
            );
        }
    }
}