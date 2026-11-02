<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mi billetera - SAFIR</title>
</head>
<body>

<h1>Mi billetera</h1>

<h2>Saldo: <fmt:formatNumber value="${saldo}" groupingUsed="true"/> monedas</h2>

<c:if test="${not empty descuento}">
    <p>
        Tienes <strong>${descuento.porcentaje}% de descuento</strong> de bienvenida
        hasta el
        <fmt:formatDate value="${descuento.venceEn}" pattern="dd/MM/yyyy HH:mm"
                        timeZone="America/Lima"/>.
    </p>
</c:if>

<h2>Movimientos</h2>

<c:choose>
    <c:when test="${empty movimientos}">
        <p>Aún no tienes movimientos.</p>
    </c:when>
    <c:otherwise>
        <table border="1" cellpadding="6">
            <thead>
                <tr><th>Fecha</th><th>Tipo</th><th>Monedas</th><th>Saldo resultante</th></tr>
            </thead>
            <tbody>
            <c:forEach var="m" items="${movimientos}">
                <tr>
                    <td><fmt:formatDate value="${m.creadoEn}" pattern="dd/MM/yyyy HH:mm"
                                        timeZone="America/Lima"/></td>
                    <td><c:out value="${etiquetas[m.tipo]}"/></td>
                    <td><c:if test="${m.monedas > 0}">+</c:if><fmt:formatNumber value="${m.monedas}" groupingUsed="true"/></td>
                    <td><fmt:formatNumber value="${m.saldo}" groupingUsed="true"/></td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </c:otherwise>
</c:choose>

<p><a href="${pageContext.request.contextPath}/perfil">Volver al perfil</a></p>

</body>
</html>