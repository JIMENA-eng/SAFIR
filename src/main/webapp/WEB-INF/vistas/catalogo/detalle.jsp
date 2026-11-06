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

<c:if test="${not empty obra.portadaRuta}">
    <img src="${pageContext.request.contextPath}/media/<c:out value='${obra.portadaRuta}'/>"
         alt="Portada de <c:out value='${obra.titulo}'/>"
         style="width:220px;max-width:100%;aspect-ratio:3/4;object-fit:cover;border-radius:12px;">
</c:if>
<c:if test="${not empty flashOk}">
    <p style="color:green"><c:out value="${flashOk}"/></p>
</c:if>
<c:if test="${not empty flashError}">
    <p style="color:red"><c:out value="${flashError}"/></p>
</c:if>

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
        <c:if test="${sessionScope.usuarioId != autorId}">
        <h2>Apoyar al autor</h2>
        <p>
            Tu saldo: <strong><c:out value="${saldo}"/></strong> monedas.
            El autor recibe el <c:out value="${autorRecibePct}"/>% de tu regalo.
        </p>

        <c:choose>
            <c:when test="${saldo > 0}">
                <form method="post" action="${pageContext.request.contextPath}/regalo">
                    <input type="hidden" name="obraId" value="${obra.id}">

                    <label>Monedas a regalar</label>
                    <input type="number" name="monedas" min="1" max="${saldo}" required><br>

                    <label>Mensaje (opcional)</label>
                    <input type="text" name="mensaje" maxlength="300"><br>

                    <button type="submit">Enviar regalo</button>
                </form>
            </c:when>
            <c:otherwise>
                <p>No tienes monedas para regalar.
                    <a href="${pageContext.request.contextPath}/billetera">Ir a mi billetera</a></p>
            </c:otherwise>
        </c:choose>
    </c:if>
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
