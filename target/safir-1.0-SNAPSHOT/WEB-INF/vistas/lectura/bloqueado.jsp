<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Capítulo bloqueado - SAFIR</title>
</head>
<body>

<h1>
    Capítulo <c:out value="${capitulo.numero}"/>:
    <c:out value="${capitulo.titulo}"/>
</h1>

<p>🔒 Este capítulo está bloqueado.</p>

<c:if test="${not empty error}">
    <p style="color:red"><c:out value="${error}"/></p>
</c:if>

<p>
    Precio: <strong><c:out value="${detalle.precio}"/></strong> monedas
    <c:if test="${detalle.descuento > 0}">
        <br>Con tu descuento de bienvenida (<c:out value="${detalle.descuento}"/>%):
        <strong><c:out value="${detalle.pagar}"/></strong> monedas
    </c:if>
</p>
<p>Tu saldo: <strong><c:out value="${detalle.saldo}"/></strong> monedas</p>

<c:choose>
    <c:when test="${detalle.saldo >= detalle.pagar}">
        <form method="post" action="${pageContext.request.contextPath}/capitulo/desbloquear">
            <input type="hidden" name="obraId" value="${obraId}">
            <input type="hidden" name="capituloId" value="${capitulo.id}">
            <button type="submit">Desbloquear por <c:out value="${detalle.pagar}"/> monedas</button>
        </form>
    </c:when>
    <c:otherwise>
        <p>No tienes monedas suficientes.</p>
        <p><a href="${pageContext.request.contextPath}/billetera">Ir a mi billetera</a></p>
    </c:otherwise>
</c:choose>

<p><a href="${pageContext.request.contextPath}/catalogo">Volver al catálogo</a></p>

</body>
</html>