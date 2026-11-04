<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Eliminar cuenta - SAFIR</title>
</head>
<body>

<h1>Eliminar mi cuenta</h1>

<c:if test="${not empty flashError}">
    <p style="color:red"><c:out value="${flashError}"/></p>
</c:if>

<c:choose>
    <c:when test="${not empty bloqueo}">
        <p style="color:red"><c:out value="${bloqueo}"/></p>
        <p><a href="${pageContext.request.contextPath}/auth/cuenta">Volver a mi cuenta</a></p>
    </c:when>

    <c:otherwise>
        <p>
            Esta acción es <strong>definitiva</strong>: tu cuenta quedará eliminada,
            tu saldo en cero, se cerrarán tus sesiones y se eliminarán tus obras.
        </p>

        <h2>Tus monedas</h2>
        <ul>
            <li>Saldo actual: <strong><fmt:formatNumber value="${prev.saldo}" groupingUsed="true"/></strong></li>
            <li>Reembolsables (las que compraste con dinero):
                <strong><fmt:formatNumber value="${prev.reembolsables}" groupingUsed="true"/></strong></li>
            <li>No reembolsables (regalo de bienvenida y ganancias como autor):
                <strong><fmt:formatNumber value="${prev.perdidas}" groupingUsed="true"/></strong></li>
        </ul>

        <c:if test="${prev.reembolsables > 0}">
            <p>
                Se valoran al precio promedio que realmente pagaste por moneda, menos
                <c:out value="${prev.comisionPct}"/>% de comisión:<br>
                Valor: US$ <fmt:formatNumber value="${prev.brutoUsd}" minFractionDigits="2" maxFractionDigits="2"/>
                − comisión US$ <fmt:formatNumber value="${prev.comisionUsd}" minFractionDigits="2" maxFractionDigits="2"/>
                = <strong>te devolvemos US$
                <fmt:formatNumber value="${prev.montoUsd}" minFractionDigits="2" maxFractionDigits="2"/></strong>
            </p>
        </c:if>

        <c:if test="${prev.perdidas > 0}">
            <p style="color:#a00">
                ⚠ Perderás <fmt:formatNumber value="${prev.perdidas}" groupingUsed="true"/> monedas sin
                reembolso. Si eres autor, retira antes tus ganancias.
            </p>
        </c:if>

        <c:if test="${prev.obras > 0}">
            <p style="color:#a00">
                ⚠ Se eliminarán definitivamente tus <strong><c:out value="${prev.obras}"/></strong>
                obra(s) con todos sus capítulos, comentarios y valoraciones.
                <c:if test="${prev.lectores > 0}">
                    <strong><c:out value="${prev.lectores}"/></strong> lector(es) que desbloquearon
                    capítulos tuyos perderán el acceso a ellos.
                </c:if>
            </p>
        </c:if>

        <form method="post" action="${pageContext.request.contextPath}/auth/cuenta/eliminar">

            <c:if test="${prev.obras > 0}">
                <p>
                    <label>
                        <input type="checkbox" name="aceptaObras" required>
                        Entiendo que mis obras se eliminarán para siempre
                    </label>
                </p>
            </c:if>

            <c:if test="${prev.perdidas > 0}">
                <p>
                    <label>
                        <input type="checkbox" name="acepta" required>
                        Entiendo que perderé esas monedas
                    </label>
                </p>
            </c:if>

            <c:if test="${prev.reembolsables > 0}">
                <p>
                    <label>¿Dónde quieres recibir tu reembolso?</label>
                    <select name="metodo">
                        <option value="paypal">PayPal</option>
                        <option value="yape">Yape</option>
                    </select>
                    <input type="text" name="datos" maxlength="150" required
                           placeholder="Correo de PayPal o celular de Yape">
                </p>
            </c:if>

            <p>
                <label>Confirma tu contraseña</label>
                <input type="password" name="clave" required>
            </p>

            <button type="submit">Eliminar mi cuenta definitivamente</button>
            <a href="${pageContext.request.contextPath}/auth/cuenta">Cancelar</a>
        </form>
    </c:otherwise>
</c:choose>

</body>
</html>
