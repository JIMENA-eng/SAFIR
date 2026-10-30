<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mi perfil - SAFIR</title>
</head>
<body>

<h1>Mi perfil</h1>

<p>
    Nombre público:
    <strong><c:out value="${sessionScope.nombreUsuario}"/></strong>
</p>

<p>
    Roles:
    <c:forEach var="rol" items="${sessionScope.roles}" varStatus="estado">
        <c:out value="${rol}"/><c:if test="${not estado.last}">, </c:if>
    </c:forEach>
</p>

<c:set var="esAutor" value="false"/>
<c:forEach var="rol" items="${sessionScope.roles}">
    <c:if test="${rol.toString().trim() == 'autor'}">
        <c:set var="esAutor" value="true"/>
    </c:if>
</c:forEach>

<c:if test="${param.error == 'autor'}">
    <p>No se pudo activar el rol de autor. Inténtalo de nuevo.</p>
</c:if>

<c:if test="${not esAutor}">
    <h2>¿Quieres publicar tus obras?</h2>
    <form method="post" action="${pageContext.request.contextPath}/auth/ser-autor">
        <button type="submit">Quiero ser autor</button>
    </form>
</c:if>

<h2>Accesos</h2>

<ul>
    <li>
        <a href="${pageContext.request.contextPath}/biblioteca">
            Mi biblioteca
        </a>
    </li>
    <li>
        <a href="${pageContext.request.contextPath}/notificaciones">
            Mis notificaciones
        </a>
    </li>
    <li>
        <a href="${pageContext.request.contextPath}/auth/cuenta">
            Mi cuenta
        </a>
    </li>
    <li>
        <a href="${pageContext.request.contextPath}/catalogo">
            Explorar el catálogo
        </a>
    </li>

    <c:forEach var="rol" items="${sessionScope.roles}">
        <c:if test="${rol.toString().trim() == 'autor'}">
            <li>
                <a href="${pageContext.request.contextPath}/autor/panel">
                    Panel de autor
                </a>
            </li>
        </c:if>
    </c:forEach>

    <li>
        <a href="${pageContext.request.contextPath}/auth/logout">
            Cerrar sesión
        </a>
    </li>
</ul>

</body>
</html>
