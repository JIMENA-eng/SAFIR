<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Biblioteca de <c:out value="${sessionScope.nombreUsuario}"/> - SAFIR</title>
</head>
<body>

<h1>
    Biblioteca de <c:out value="${sessionScope.nombreUsuario}"/>
</h1>

<p>
    <a href="${pageContext.request.contextPath}/auth/inicio">Volver al inicio</a>
</p>

<c:choose>
    <c:when test="${empty obras}">
        <p>Aún no hay obras en esta biblioteca.</p>
        <a href="${pageContext.request.contextPath}/catalogo">
            Explorar catálogo
        </a>
    </c:when>

    <c:otherwise>
        <c:forEach var="obra" items="${obras}">
            <article>
                <h2>
                    <a href="${pageContext.request.contextPath}/obra?id=${obra.id}">
                        <c:out value="${obra.titulo}"/>
                    </a>
                    <c:if test="${obra.favorita}">(favorita)</c:if>
                </h2>

                <p>Autor: <c:out value="${obra.autor}"/></p>
                <p>Género: <c:out value="${obra.genero}"/></p>
                <p>Estado de lectura: <c:out value="${obra.estadoBiblioteca}"/></p>

                <hr>
            </article>
        </c:forEach>
    </c:otherwise>
</c:choose>

</body>
</html>
