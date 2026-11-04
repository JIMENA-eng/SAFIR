<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reembolsos por cuentas eliminadas - SAFIR</title>
</head>
<body>

<h1>Reembolsos por cuentas eliminadas</h1>

<c:if test="${not empty flashOk}">
    <p style="color:green"><c:out value="${flashOk}"/></p>
</c:if>
<c:if test="${not empty flashError}">
    <p style="color:red"><c:out value="${flashError}"/></p>
</c:if>

<p>Transfiere el monto al destino indicado y luego márcalo como pagado.</p>

<c:choose>
    <c:when test="${empty reembolsos}">
        <p>No hay reembolsos pendientes.</p>
    </c:when>
    <c:otherwise>
        <table border="1" cellpadding="6">
            <thead>
                <tr><th>#</th><th>Fecha</th><th>Usuario</th><th>Monedas</th>
                    <th>Valor / comisión</th><th>A pagar (US$)</th><th>Destino</th><th></th></tr>
            </thead>
            <tbody>
            <c:forEach var="r" items="${reembolsos}">
                <tr>
                    <td><c:out value="${r.id}"/></td>
                    <td><fmt:formatDate value="${r.creadoEn}" pattern="dd/MM/yyyy HH:mm"
                                        timeZone="America/Lima"/></td>
                    <td><c:out value="${r.usuario}"/><br><small><c:out value="${r.correo}"/></small></td>
                    <td><fmt:formatNumber value="${r.monedas}" groupingUsed="true"/></td>
                    <td>
                        <fmt:formatNumber value="${r.brutoUsd}" minFractionDigits="2" maxFractionDigits="2"/>
                        − <fmt:formatNumber value="${r.comisionUsd}" minFractionDigits="2" maxFractionDigits="2"/>
                        (<c:out value="${r.comisionPct}"/>%)
                    </td>
                    <td><strong><fmt:formatNumber value="${r.montoUsd}" minFractionDigits="2"
                                                  maxFractionDigits="2"/></strong></td>
                    <td><c:out value="${r.metodo}"/>:<br><c:out value="${r.datos}"/></td>
                    <td>
                        <form method="post" style="display:inline"
                              action="${pageContext.request.contextPath}/moderacion/reembolsos">
                            <input type="hidden" name="reembolsoId" value="${r.id}">
                            <input type="text" name="referencia" maxlength="100"
                                   placeholder="Referencia (opcional)">
                            <button type="submit">Marcar como pagado</button>
                        </form>
                    </td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </c:otherwise>
</c:choose>

</body>
</html>
