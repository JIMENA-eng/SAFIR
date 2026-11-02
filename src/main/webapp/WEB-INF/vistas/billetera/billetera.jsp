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
<c:if test="${not empty flashOk}">
    <p style="color:green"><c:out value="${flashOk}"/></p>
</c:if>
<c:if test="${not empty flashError}">
    <p style="color:red"><c:out value="${flashError}"/></p>
</c:if>
<c:if test="${param.pago == 'cancelado'}">
    <p>Cancelaste el pago. No se te cobró nada.</p>
</c:if>

<h2>Comprar monedas</h2>
<table border="1" cellpadding="6">
    <thead><tr><th>Monedas</th><th>Precio</th><th></th></tr></thead>
    <tbody>
    <c:forEach var="p" items="${paquetes}">
        <tr>
            <td><c:out value="${p.monedas}"/></td>
            <td>
                <c:if test="${p.descuento > 0}">
                    <s>US$ <fmt:formatNumber value="${p.precioLista}" minFractionDigits="2" maxFractionDigits="2"/></s>
                </c:if>
                <strong>US$ <fmt:formatNumber value="${p.precioFinal}" minFractionDigits="2" maxFractionDigits="2"/></strong>
            </td>
            <td>
                <form method="post" style="display:inline"
                      action="${pageContext.request.contextPath}/billetera/comprar">
                    <input type="hidden" name="paqueteId" value="${p.id}">
                    <button type="submit" name="pasarela" value="paypal">Pagar con PayPal</button>
                    <button type="submit" name="pasarela" value="yape">Pagar con Yape</button>
                </form>
            </td>
        </tr>
    </c:forEach>
    </tbody>
</table>

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