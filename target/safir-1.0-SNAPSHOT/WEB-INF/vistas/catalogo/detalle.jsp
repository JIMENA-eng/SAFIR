<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title><c:out value="${obra.titulo}"/> - SAFIR</title>
</head>
<body>

<h1><c:out value="${obra.titulo}"/></h1>

<p>Autor: <c:out value="${obra.autor}"/></p>
<p>Género: <c:out value="${obra.genero}"/></p>
<p>Clasificación: <c:out value="${obra.clasificacion}"/></p>
<p>Avance: <c:out value="${obra.avance}"/></p>

<c:if test="${not empty obra.descripcion}">
    <p><c:out value="${obra.descripcion}"/></p>
</c:if>

<c:if test="${not empty obra.etiquetas}">
    <p>Etiquetas: <c:out value="${obra.etiquetas}"/></p>
</c:if>

<p>Capítulos publicados: <c:out value="${obra.capitulosPublicados}"/></p>
<p>Lecturas: <c:out value="${obra.totalLecturas}"/></p>
<p>Seguidores: <c:out value="${obra.totalSeguidores}"/></p>
<p>
    Valoración promedio: <c:out value="${obra.promedio}"/>
    (<c:out value="${obra.totalValoraciones}"/> valoraciones)
</p>

<c:choose>
    <c:when test="${not empty sessionScope.usuarioId}">
        <p>
            <a href="${pageContext.request.contextPath}/lectura?obraId=${obra.id}">
                Leer obra
            </a>
        </p>

        <form method="post"
              action="${pageContext.request.contextPath}/biblioteca">
            <input type="hidden" name="obraId" value="${obra.id}">
            <input type="hidden" name="accion" value="agregar">

            <button type="submit">Agregar a mi biblioteca</button>
        </form>
    </c:when>

    <c:otherwise>
        <p>
            <a href="${pageContext.request.contextPath}/login">
                Inicia sesión para leer y agregar esta obra a tu biblioteca
            </a>
        </p>
    </c:otherwise>
</c:choose>

<p>
    <a href="${pageContext.request.contextPath}/catalogo">Volver al catálogo</a>
</p>

</body>
</html>
