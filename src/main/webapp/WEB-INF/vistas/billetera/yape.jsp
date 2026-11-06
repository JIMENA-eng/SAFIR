<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%--
    Pagar con Yape. Lo usa YapeServlet (GET /billetera/yape?compra=ID).
    Atributos: compra (id, monedas, montoPen, estado, referencia), yapeNumero, yapeTitular.
    El código de operación se envía por POST a /billetera/yape, igual que antes.
    El encabezado es el compartido (encabezado-datos.jspf + encabezado.jspf), igual que en Mi biblioteca.
--%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pagar con Yape · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,300;7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/billetera/billetera.css">
<script>
  // Mismo modo claro/noche que el resto de SAFIR
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main class="bt-main bt-angosto">

  <a class="bt-volver" href="<%= contexto %>/billetera">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    Volver a Mi billetera
  </a>

  <div class="bt-titulo">
    <h1>Pagar con Yape</h1>
  </div>

  <c:if test="${not empty flashOk}">
    <div class="bt-aviso ok" role="status"><c:out value="${flashOk}"/></div>
  </c:if>
  <c:if test="${not empty flashError}">
    <div class="bt-aviso error" role="alert"><c:out value="${flashError}"/></div>
  </c:if>

  <c:choose>
    <c:when test="${compra.estado == 'pendiente'}">

      <section class="bt-resumen" aria-label="Resumen de la compra">
        <p class="bt-resumen-etq">Compra #<c:out value="${compra.id}"/></p>
        <p class="bt-resumen-monedas"><fmt:formatNumber value="${compra.monedas}" groupingUsed="true"/> <span>monedas</span></p>
        <p class="bt-resumen-monto">Total a pagar: <b>S/ <fmt:formatNumber value="${compra.montoPen}" minFractionDigits="2" maxFractionDigits="2"/></b></p>
      </section>

      <ol class="bt-pasos">
        <li>
          <span>
            Abre Yape y envía <b>S/ <fmt:formatNumber value="${compra.montoPen}" minFractionDigits="2" maxFractionDigits="2"/></b>
            al número <b id="btYapeNumero"><c:out value="${empty yapeNumero ? '(sin configurar)' : yapeNumero}"/></b>
            <c:if test="${not empty yapeTitular}">(a nombre de <c:out value="${yapeTitular}"/>)</c:if>.
            <c:if test="${not empty yapeNumero}">
              <button type="button" class="bt-copiar" data-copiar="#btYapeNumero">Copiar número</button>
            </c:if>
          </span>
        </li>
        <li><span>Copia el <b>código de operación</b> que aparece en tu constancia.</span></li>
        <li><span>Escríbelo aquí abajo. Revisaremos el pago y acreditaremos tus monedas.</span></li>
      </ol>

      <c:if test="${not empty compra.referencia}">
        <div class="bt-aviso info" role="status">
          Código registrado: <b><c:out value="${compra.referencia}"/></b>.
          Estamos verificando tu pago. Si te equivocaste, puedes enviarlo de nuevo.
        </div>
      </c:if>

      <form class="bt-form" method="post" action="<%= contexto %>/billetera/yape">
        <input type="hidden" name="compraId" value="${compra.id}">
        <label for="codigo">Código de operación</label>
        <input id="codigo" type="text" name="codigo" required maxlength="30"
               pattern="[A-Za-z0-9]{4,30}" autocomplete="off"
               title="Entre 4 y 30 letras o números">
        <button type="submit" class="btn">Enviar código</button>
      </form>
    </c:when>

    <c:when test="${compra.estado == 'pagada'}">
      <div class="bt-estado ok">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/></svg>
        <p><b>Tu pago fue confirmado.</b></p>
        <p>Las monedas ya están en tu billetera.</p>
        <a class="btn" href="<%= contexto %>/billetera">Ir a Mi billetera</a>
      </div>
    </c:when>

    <c:otherwise>
      <div class="bt-estado error">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="m9 9 6 6M15 9l-6 6"/></svg>
        <p><b>Este pago no pudo verificarse.</b></p>
        <p>Si crees que es un error, contáctanos.</p>
        <a class="btn outline" href="<%= contexto %>/billetera">Volver a Mi billetera</a>
      </div>
    </c:otherwise>
  </c:choose>

</main>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script src="<%= contexto %>/assets/js/billetera.js"></script>
</body>
</html>
