<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Pagar con Yape - SAFIR</title>
</head>
<body>

<h1>Pagar con Yape</h1>

<c:if test="${not empty flashOk}">
    <p style="color:green"><c:out value="${flashOk}"/></p>
</c:if>
<c:if test="${not empty flashError}">
    <p style="color:red"><c:out value="${flashError}"/></p>
</c:if>

<c:choose>
    <c:when test="${compra.estado == 'pendiente'}">
        <p>
            Compra #<c:out value="${compra.id}"/>:
            <strong><c:out value="${compra.monedas}"/></strong> monedas.
        </p>

        <ol>
            <li>
                Abre Yape y envía
                <strong>S/ <fmt:formatNumber value="${compra.montoPen}"
                    minFractionDigits="2" maxFractionDigits="2"/></strong>
                al número
                <strong><c:out value="${empty yapeNumero ? '(sin configurar)' : yapeNumero}"/></strong>
                <c:if test="${not empty yapeTitular}">
                    (a nombre de <c:out value="${yapeTitular}"/>)
                </c:if>.
            </li>
            <li>Copia el <strong>código de operación</strong> que aparece en tu constancia.</li>
            <li>Escríbelo aquí abajo. Revisaremos el pago y acreditaremos tus monedas.</li>
        </ol>

        <c:if test="${not empty compra.referencia}">
            <p>
                Código registrado: <strong><c:out value="${compra.referencia}"/></strong>.
                Estamos verificando tu pago. Si te equivocaste, puedes enviarlo de nuevo.
            </p>
        </c:if>

        <form method="post" action="${pageContext.request.contextPath}/billetera/yape">
            <input type="hidden" name="compraId" value="${compra.id}">
            <label>Código de operación</label>
            <input type="text" name="codigo" required maxlength="30"
                   pattern="[A-Za-z0-9]{4,30}">
            <button type="submit">Enviar código</button>
        </form>
    </c:when>

    <c:when test="${compra.estado == 'pagada'}">
        <p>✅ Tu pago fue confirmado y las monedas ya están en tu billetera.</p>
    </c:when>

    <c:otherwise>
        <p>❌ Este pago no pudo verificarse. Si crees que es un error, contáctanos.</p>
    </c:otherwise>
</c:choose>

<p><a href="${pageContext.request.contextPath}/billetera">Volver a mi billetera</a></p>

</body>
</html>
