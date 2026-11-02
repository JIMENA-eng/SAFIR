package com.safir.util;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

/** Mensajes de una sola vista: se guardan en sesión y se muestran tras redirigir. */
public final class Flash {

    private Flash() {}

    public static void ok(HttpSession sesion, String mensaje) {
        sesion.setAttribute("flashOk", mensaje);
    }

    public static void error(HttpSession sesion, String mensaje) {
        sesion.setAttribute("flashError", mensaje);
    }

    /** Pasa los mensajes pendientes de la sesión a la petición y los borra. */
    public static void aRequest(HttpServletRequest request) {
        HttpSession sesion = request.getSession(false);
        if (sesion == null) return;

        for (String clave : new String[] {"flashOk", "flashError"}) {
            Object valor = sesion.getAttribute(clave);
            if (valor != null) {
                request.setAttribute(clave, valor);
                sesion.removeAttribute(clave);
            }
        }
    }
}