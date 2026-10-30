<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Catálogo - SAFIR</title>
</head>
<body>

<h1>Catálogo de obras</h1>

<form method="get" action="${pageContext.request.contextPath}/catalogo">
    <label for="q">Buscar</label>
    <input type="text" id="q" name="q"
           value="<c:out value='${busqueda}'/>">

    <label for="genero">Género</label>
    <input type="text" id="genero" name="genero"
           value="<c:out value='${generoSeleccionado}'/>">

    <button type="submit">Buscar</button>
    <a href="${pageContext.request.contextPath}/catalogo">Limpiar</a>
</form>

<hr>

<c:choose>
    <c:when test="${empty obras}">
        <p>No se encontraron obras publicadas.</p>
    </c:when>

    <c:otherwise>
        <c:forEach var="obra" items="${obras}">
            <article>
                <h2>
                    <a href="${pageContext.request.contextPath}/obra?id=${obra.id}">
                        <c:out value="${obra.titulo}"/>
                    </a>
                </h2>

                <p>Autor: <c:out value="${obra.autor}"/></p>
                <p>Género: <c:out value="${obra.genero}"/></p>
                <p>Clasificación: <c:out value="${obra.clasificacion}"/></p>
                <p>Avance: <c:out value="${obra.avance}"/></p>
                <p>Capítulos publicados: <c:out value="${obra.capitulosPublicados}"/></p>
                <p>
                    Valoración:
                    <c:out value="${obra.promedio}"/>
                    (<c:out value="${obra.totalValoraciones}"/> valoraciones)
                </p>

                <c:if test="${not empty obra.descripcion}">
                    <p><c:out value="${obra.descripcion}"/></p>
                </c:if>

                <c:if test="${not empty obra.etiquetas}">
                    <p>Etiquetas: <c:out value="${obra.etiquetas}"/></p>
                </c:if>

                <hr>
            </article>
        </c:forEach>
    </c:otherwise>
</c:choose>

<p>
    <a href="${pageContext.request.contextPath}/biblioteca">Mi biblioteca</a>
</p>

</body>
</html>
