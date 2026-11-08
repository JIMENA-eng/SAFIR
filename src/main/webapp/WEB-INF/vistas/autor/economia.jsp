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

<c:if test="${eco.nivel >= eco.nivelRetiro and eco.saldo >= eco.saldoRetiro}">
    <p>
        Puedes retirar hasta <strong><fmt:formatNumber value="${eco.saldo}" groupingUsed="true"/></strong> monedas.
        La plataforma retiene el <c:out value="${retiroCfg.comisionPct}"/>% y cada moneda vale
        US$ <c:out value="${retiroCfg.valorMoneda}"/>. Las monedas se descuentan de inmediato;
        si la solicitud se rechaza, te las devolvemos completas.
    </p>

    <form method="post" action="${pageContext.request.contextPath}/autor/retiro">
        <label>Monedas a retirar</label>
        <input type="number" id="monedasRetiro" name="monedas" min="1" max="${eco.saldo}" required><br>

        <label>Método de pago</label>
        <select name="metodo">
            <option value="paypal">PayPal</option>
            <option value="yape">Yape</option>
        </select><br>

        <label>Correo de PayPal o celular de Yape</label>
        <input type="text" name="datos" maxlength="150" required><br>

        <p id="estimado"></p>
        <button type="submit">Solicitar retiro</button>
    </form>

    <script>
    (function () {
        var entrada = document.getElementById('monedasRetiro');
        var salida = document.getElementById('estimado');
        var pct = ${retiroCfg.comisionPct};
        var valor = ${retiroCfg.valorMoneda};
        entrada.addEventListener('input', function () {
            var m = parseInt(entrada.value, 10);
            if (!m || m < 1) { salida.textContent = ''; return; }
            var neto = m - Math.round(m * pct / 100);
            salida.textContent = 'Recibirías ' + neto.toLocaleString('es-PE')
                + ' monedas, aprox. US$ ' + (neto * valor).toFixed(2);
        });
    })();
    </script>
</c:if>

<h3>Mis solicitudes</h3>
<c:choose>
    <c:when test="${empty retiros}">
        <p>Aún no has solicitado retiros.</p>
    </c:when>
    <c:otherwise>
        <table border="1" cellpadding="6">
            <thead>
                <tr><th>#</th><th>Fecha</th><th>Monedas</th><th>Monto (US$)</th>
                    <th>Método</th><th>Estado</th><th>Motivo</th></tr>
            </thead>
            <tbody>
            <c:forEach var="r" items="${retiros}">
                <tr>
                    <td><c:out value="${r.id}"/></td>
                    <td><fmt:formatDate value="${r.creadoEn}" pattern="dd/MM/yyyy HH:mm"
                                        timeZone="America/Lima"/></td>
                    <td><fmt:formatNumber value="${r.monedas}" groupingUsed="true"/></td>
                    <td><fmt:formatNumber value="${r.montoUsd}" minFractionDigits="2" maxFractionDigits="2"/></td>
                    <td><c:out value="${r.metodo}"/></td>
                    <td><c:out value="${r.estado}"/></td>
                    <td><c:out value="${r.motivo}"/></td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </c:otherwise>
</c:choose>

<p><a href="${pageContext.request.contextPath}/billetera">Ver mi billetera y movimientos</a></p>
<p><a href="${pageContext.request.contextPath}/auth/cuenta#mis-obras">Ir a mis obras</a></p>

</body>
</html>
