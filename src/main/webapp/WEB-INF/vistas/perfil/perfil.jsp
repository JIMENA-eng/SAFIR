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
<c:if test="${param.ok == '1'}"><p>Imágenes actualizadas.</p></c:if>
<c:if test="${not empty error}"><p style="color:red"><c:out value="${error}"/></p></c:if>

<c:if test="${not empty portadaRuta}">
    <img src="${pageContext.request.contextPath}/media/<c:out value='${portadaRuta}'/>"
         alt="Portada" style="width:100%;max-height:220px;object-fit:cover">
</c:if>
<c:if test="${not empty avatarRuta}">
    <img src="${pageContext.request.contextPath}/media/<c:out value='${avatarRuta}'/>"
         alt="Foto de perfil" style="width:96px;height:96px;border-radius:50%;object-fit:cover">
</c:if>

<form method="post" action="${pageContext.request.contextPath}/perfil"
      enctype="multipart/form-data">
    <label>Foto de perfil</label>
    <input type="file" name="avatar" accept="image/png,image/jpeg,image/webp"><br>
    <label>Portada</label>
    <input type="file" name="portada" accept="image/png,image/jpeg,image/webp"><br>
    <button type="submit">Guardar imágenes</button>
</form>
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
