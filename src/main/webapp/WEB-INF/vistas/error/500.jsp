<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%-- Esta página NO usa JSTL a propósito: si la librería faltara, la propia página
     de error fallaría y el navegador mostraría un "HTTP ERROR 500" en blanco. --%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Error 500 - SAFIR</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/estilos.css">
</head>
<body>
<main>
<h1>Error 500</h1>
<h2>Error interno del servidor</h2>

<p>Ocurrió un problema inesperado al procesar tu solicitud. Inténtalo de nuevo en unos minutos.</p>

<%
    // Solo para desarrollo: muestra la causa real del error. Borra este bloque en producción.
    Throwable error = (Throwable) request.getAttribute("jakarta.servlet.error.exception");
    if (error != null) {
        Throwable causa = error;
        while (causa.getCause() != null && causa.getCause() != causa) {
            causa = causa.getCause();
        }
        String detalle = causa.getClass().getSimpleName() + ": " + causa.getMessage();
        detalle = detalle.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;");
%>
<details>
    <summary>Detalle técnico (solo desarrollo)</summary>
    <pre><%= detalle %></pre>
</details>
<% } %>

<p>
    <a href="${pageContext.request.contextPath}/auth/inicio">Ir al inicio</a>
    |
    <a href="${pageContext.request.contextPath}/catalogo">Ver el catálogo</a>
</p>
</main>
</body>
</html>
