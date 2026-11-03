<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mi economía de autor - SAFIR</title>
</head>
<body>

<h1>Mi economía de autor</h1>

<c:if test="${not empty flashOk}">
    <p style="color:green"><c:out value="${flashOk}"/></p>
</c:if>
<c:if test="${not empty flashError}">
    <p style="color:red"><c:out value="${flashError}"/></p>
</c:if>

<p>
    Saldo: <strong><fmt:formatNumber value="${eco.saldo}" groupingUsed="true"/></strong> monedas<br>
    Total ganado (regalos y ventas): <fmt:formatNumber value="${eco.recibido}" groupingUsed="true"/> monedas<br>
    Nivel: <strong><c:out value="${eco.nivel}"/></strong> de <c:out value="${eco.maximo}"/>
</p>

<h2>Niveles</h2>
<p>
    Mientras más alto sea tu nivel, tus obras aparecen con más visibilidad en el catálogo.
    Cada nivel cuesta <fmt:formatNumber value="${eco.costo}" groupingUsed="true"/> monedas.
</p>

<c:choose>
    <c:when test="${eco.nivel >= eco.maximo}">
        <p>Ya estás en el nivel máximo.</p>
    </c:when>
    <c:when test="${eco.saldo >= eco.costo}">
        <form method="post" action="${pageContext.request.contextPath}/autor/economia">
            <input type="hidden" name="accion" value="comprar_nivel">
            <button type="submit">
                Subir al nivel <c:out value="${eco.nivel + 1}"/> por
                <fmt:formatNumber value="${eco.costo}" groupingUsed="true"/> monedas
            </button>
        </form>
    </c:when>
    <c:otherwise>
        <p>Te faltan <fmt:formatNumber value="${eco.costo - eco.saldo}" groupingUsed="true"/>
            monedas para el siguiente nivel.</p>
    </c:otherwise>
</c:choose>

<h2>Retiros</h2>
<p>Para retirar necesitas cumplir las dos condiciones a la vez:</p>
<ul>
    <li>
        <c:out value="${eco.nivel >= eco.nivelRetiro ? '✅' : '❌'}"/>
        Nivel <c:out value="${eco.nivelRetiro}"/> o más (tienes el <c:out value="${eco.nivel}"/>)
    </li>
    <li>
        <c:out value="${eco.saldo >= eco.saldoRetiro ? '✅' : '❌'}"/>
        Saldo de al menos <fmt:formatNumber value="${eco.saldoRetiro}" groupingUsed="true"/> monedas
    </li>
</ul>

<p><a href="${pageContext.request.contextPath}/billetera">Ver mi billetera y movimientos</a></p>
<p><a href="${pageContext.request.contextPath}/autor/panel">Volver al panel de autor</a></p>

</body>
</html>
