package com.safir.controlador;

import com.safir.dao.ObraDAO;
import com.safir.modelo.Obra;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.safir.dao.BilleteraDAO;
import com.safir.dao.EconomiaAutorDAO;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet("/obra")
public class ObraServlet extends HttpServlet {

    private final ObraDAO obraDAO = new ObraDAO();
    private final BilleteraDAO billeteraDAO = new BilleteraDAO();
    private final EconomiaAutorDAO economiaDAO = new EconomiaAutorDAO();

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
            HttpSession sesion = request.getSession(false);

            if (sesion != null && sesion.getAttribute("usuarioId") != null) {
                long usuarioId = ((Number) sesion.getAttribute("usuarioId")).longValue();

                request.setAttribute("autorId", economiaDAO.obtenerAutorDeObra(id));
                request.setAttribute("saldo", billeteraDAO.obtenerSaldo(usuarioId));
                request.setAttribute("autorRecibePct", 100 - economiaDAO.comisionRegaloPct());

                // Mensajes de una operación anterior (se muestran una sola vez).
                for (String clave : new String[] {"flashOk", "flashError"}) {
                    Object v = sesion.getAttribute(clave);
                    if (v != null) {
                        request.setAttribute(clave, v);
                        sesion.removeAttribute(clave);
                    }
                }
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