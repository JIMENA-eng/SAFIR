<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Pagos con Yape - SAFIR</title>
</head>
<body>

<h1>Pagos con Yape por revisar</h1>

<c:if test="${not empty flashOk}">
    <p style="color:green"><c:out value="${flashOk}"/></p>
</c:if>
<c:if test="${not empty flashError}">
    <p style="color:red"><c:out value="${flashError}"/></p>
</c:if>

<p>Compara el código y el monto con tu app de Yape antes de confirmar.</p>

<c:choose>
    <c:when test="${empty pagos}">
        <p>No hay pagos pendientes.</p>
    </c:when>
    <c:otherwise>
        <table border="1" cellpadding="6">
            <thead>
                <tr>
                    <th>#</th><th>Fecha</th><th>Usuario</th><th>Monedas</th>
                    <th>Monto (S/)</th><th>Código de operación</th><th></th>
                </tr>
            </thead>
            <tbody>
            <c:forEach var="p" items="${pagos}">
                <tr>
                    <td><c:out value="${p.id}"/></td>
                    <td><fmt:formatDate value="${p.creadoEn}" pattern="dd/MM/yyyy HH:mm"
                                        timeZone="America/Lima"/></td>
                    <td><c:out value="${p.usuario}"/><br><small><c:out value="${p.correo}"/></small></td>
                    <td><c:out value="${p.monedas}"/></td>
                    <td><fmt:formatNumber value="${p.montoPen}" minFractionDigits="2"
                                          maxFractionDigits="2"/></td>
                    <td><c:out value="${p.referencia}"/></td>
                    <td>
                        <form method="post" style="display:inline"
                              action="${pageContext.request.contextPath}/moderacion/pagos">
                            <input type="hidden" name="compraId" value="${p.id}">
                            <button name="accion" value="confirmar">Confirmar</button>
                            <button name="accion" value="rechazar">Rechazar</button>
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
