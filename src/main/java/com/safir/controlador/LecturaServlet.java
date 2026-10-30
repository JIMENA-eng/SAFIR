package com.safir.controlador;

import com.safir.dao.CapituloDAO;
import com.safir.modelo.Capitulo;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/lectura")
public class LecturaServlet extends HttpServlet {

    private final CapituloDAO capituloDAO = new CapituloDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long usuarioId;

        try {
            usuarioId = ((Number) sesion.getAttribute("usuarioId")).longValue();
        } catch (RuntimeException e) {
            sesion.invalidate();
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        long obraId;

        try {
            obraId = Long.parseLong(request.getParameter("obraId"));

            if (obraId <= 0) {
                throw new NumberFormatException();
            }
        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "El ID de la obra no es válido."
            );
            return;
        }

        try {
            String capituloTexto = request.getParameter("capituloId");
            Capitulo capitulo;

            if (capituloTexto != null && !capituloTexto.isBlank()) {
                long capituloId = Long.parseLong(capituloTexto);

                if (capituloId <= 0) {
                    throw new NumberFormatException();
                }

                capitulo = capituloDAO.buscarPublicado(capituloId, obraId);

                if (capitulo == null) {
                    response.sendError(
                            HttpServletResponse.SC_NOT_FOUND,
                            "El capítulo no existe o no está publicado."
                    );
                    return;
                }
            } else {
                capitulo = capituloDAO.buscarParaContinuar(usuarioId, obraId);

                if (capitulo == null) {
                    capitulo = capituloDAO.obtenerPrimero(obraId);
                }

                if (capitulo == null) {
                    response.sendError(
                            HttpServletResponse.SC_NOT_FOUND,
                            "Esta obra no tiene capítulos publicados."
                    );
                    return;
                }
            }

            double posicionGuardada = capituloDAO.obtenerPosicion(
                    usuarioId, obraId, capitulo.getId()
            );

            request.setAttribute("posicionGuardada", posicionGuardada);

            List<Capitulo> capitulos =
                    capituloDAO.listarPublicados(obraId);

            Capitulo anterior = capituloDAO.obtenerAnterior(
                    obraId, capitulo.getNumero()
            );

            Capitulo siguiente = capituloDAO.obtenerSiguiente(
                    obraId, capitulo.getNumero()
            );

            request.setAttribute("capitulo", capitulo);
            request.setAttribute("capitulos", capitulos);
            request.setAttribute("capituloAnterior", anterior);
            request.setAttribute("capituloSiguiente", siguiente);
            request.setAttribute("obraId", obraId);

            request.getRequestDispatcher(
                    "/WEB-INF/vistas/lectura/lector.jsp"
            ).forward(request, response);

        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "El ID del capítulo no es válido."
            );
        } catch (SQLException e) {
            throw new ServletException(
                    "Error al cargar el capítulo.", e
            );
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        HttpSession sesion = request.getSession(false);

        if (sesion == null || sesion.getAttribute("usuarioId") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        long usuarioId;

        try {
            usuarioId = ((Number) sesion.getAttribute("usuarioId")).longValue();
        } catch (RuntimeException e) {
            sesion.invalidate();
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        long obraId;
        long capituloId;
        double posicion;

        try {
            obraId = Long.parseLong(request.getParameter("obraId"));
            capituloId = Long.parseLong(request.getParameter("capituloId"));
            posicion = Double.parseDouble(request.getParameter("posicion"));

            if (obraId <= 0 || capituloId <= 0
                    || !Double.isFinite(posicion)
                    || posicion < 0 || posicion > 100) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException | NullPointerException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Los datos del progreso no son válidos."
            );
            return;
        }

        try {
            Capitulo capitulo =
                    capituloDAO.buscarPublicado(capituloId, obraId);

            if (capitulo == null) {
                response.sendError(
                        HttpServletResponse.SC_NOT_FOUND,
                        "No se puede guardar el progreso de este capítulo."
                );
                return;
            }

            capituloDAO.guardarProgreso(
                    usuarioId, obraId, capituloId, posicion
            );

            response.setStatus(HttpServletResponse.SC_NO_CONTENT);

        } catch (SQLException e) {
            throw new ServletException(
                    "Error al guardar el progreso de lectura.", e
            );
        }
    }
}