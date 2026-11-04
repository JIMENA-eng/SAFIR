<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Retiros de autores - SAFIR</title>
</head>
<body>

<h1>Retiros por revisar</h1>

<c:if test="${not empty flashOk}">
    <p style="color:green"><c:out value="${flashOk}"/></p>
</c:if>
<c:if test="${not empty flashError}">
    <p style="color:red"><c:out value="${flashError}"/></p>
</c:if>

<p>
    Aprobar significa que ya pagaste al autor por fuera (PayPal o Yape). Rechazar exige un
    motivo y devuelve al autor todas las monedas que pidió.
</p>

<c:choose>
    <c:when test="${empty retiros}">
        <p>No hay retiros pendientes.</p>
    </c:when>
    <c:otherwise>
        <c:forEach var="r" items="${retiros}">
            <fieldset style="margin-bottom:1em">
                <legend>
                    Retiro #<c:out value="${r.id}"/> ·
                    <fmt:formatDate value="${r.creadoEn}" pattern="dd/MM/yyyy HH:mm"
                                    timeZone="America/Lima"/>
                </legend>

                <p>
                    Autor: <strong><c:out value="${r.autor}"/></strong>
                    (<c:out value="${r.correo}"/>), nivel <c:out value="${r.nivel}"/><br>
                    Monedas solicitadas: <fmt:formatNumber value="${r.solicitadas}" groupingUsed="true"/>
                    → plataforma: <fmt:formatNumber value="${r.plataforma}" groupingUsed="true"/>,
                    autor: <fmt:formatNumber value="${r.paraAutor}" groupingUsed="true"/><br>
                    <strong>A pagar: US$ <fmt:formatNumber value="${r.montoUsd}"
                        minFractionDigits="2" maxFractionDigits="2"/></strong>
                    (valor por moneda: <c:out value="${r.valorMoneda}"/>)<br>
                    Método: <strong><c:out value="${r.metodo}"/></strong> ·
                    Destino: <strong><c:out value="${r.datos}"/></strong>
                </p>

                <form method="post" style="display:inline"
                      action="${pageContext.request.contextPath}/moderacion/retiros">
                    <input type="hidden" name="retiroId" value="${r.id}">
                    <input type="hidden" name="accion" value="aprobar">
                    <input type="text" name="referencia" maxlength="100"
                           placeholder="Referencia del pago (opcional)">
                    <button type="submit">Aprobar (ya pagué)</button>
                </form>

                <form method="post" style="display:inline"
                      action="${pageContext.request.contextPath}/moderacion/retiros">
                    <input type="hidden" name="retiroId" value="${r.id}">
                    <input type="hidden" name="accion" value="rechazar">
                    <input type="text" name="motivo" maxlength="300" required
                           placeholder="Motivo del rechazo">
                    <button type="submit">Rechazar</button>
                </form>
            </fieldset>
        </c:forEach>
    </c:otherwise>
</c:choose>

</body>
</html>
