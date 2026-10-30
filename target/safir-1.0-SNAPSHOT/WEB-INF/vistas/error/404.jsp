<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%-- Esta página NO usa JSTL a propósito: una página de error no debe fallar por falta de librerías. --%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Error 404 - SAFIR</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/estilos.css">
</head>
<body>
<main>
<h1>Error 404</h1>
<h2>Página no encontrada</h2>

<p>La página o el recurso que buscas no existe o ya no está disponible.</p>

<%
    Object mensaje = request.getAttribute("jakarta.servlet.error.message");
    if (mensaje != null && !String.valueOf(mensaje).isBlank()) {
        String texto = String.valueOf(mensaje).replace("&", "&amp;")
                .replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
%>
<p><%= texto %></p>
<% } %>

<p>
    <a href="${pageContext.request.contextPath}/auth/inicio">Ir al inicio</a>
    |
    <a href="${pageContext.request.contextPath}/catalogo">Ver el catálogo</a>
</p>
</main>
</body>
</html>
