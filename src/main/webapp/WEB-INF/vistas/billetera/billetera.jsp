<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%--
    Mi billetera. Lo usa BilleteraServlet (GET /billetera).
    Atributos: saldo, descuento (porcentaje, venceEn; null si no hay), paquetes, movimientos, etiquetas.
    Las compras son POST a /billetera/comprar (PayPal o Yape), igual que antes.
    El encabezado es el compartido (encabezado-datos.jspf + encabezado.jspf), igual que en Mi biblioteca.
--%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mi billetera · SAFIR</title>
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

<main class="bt-main">

  <a class="bt-volver" href="<%= contexto %>/auth/cuenta">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    Volver a Mi cuenta
  </a>

  <div class="bt-titulo">
    <h1>Mi billetera</h1>
    <p>Tu saldo de monedas, los paquetes para recargar y tu historial de movimientos.</p>
  </div>

  <%-- Avisos de una sola vista --%>
  <c:if test="${not empty flashOk}">
    <div class="bt-aviso ok" role="status"><c:out value="${flashOk}"/></div>
  </c:if>
  <c:if test="${not empty flashError}">
    <div class="bt-aviso error" role="alert"><c:out value="${flashError}"/></div>
  </c:if>
  <c:if test="${param.pago == 'cancelado'}">
    <div class="bt-aviso info" role="status">Cancelaste el pago. No se te cobró nada.</div>
  </c:if>

  <!-- Saldo -->
  <section class="bt-saldo" aria-labelledby="btSaldoTit">
    <p class="bt-saldo-etq" id="btSaldoTit">Saldo disponible</p>
    <p class="bt-saldo-monto"><fmt:formatNumber value="${saldo}" groupingUsed="true"/> <span>monedas</span></p>
    <c:if test="${not empty descuento}">
      <p class="bt-promo">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20.6 13.4 13.4 20.6a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8Z"/><circle cx="7.5" cy="7.5" r="1.2"/></svg>
        <span>Tienes <b><c:out value="${descuento.porcentaje}"/>% de descuento</b> en tus compras hasta el
        <fmt:formatDate value="${descuento.venceEn}" pattern="dd/MM/yyyy HH:mm" timeZone="America/Lima"/>.</span>
      </p>
    </c:if>
  </section>

  <!-- Comprar monedas -->
  <section class="bt-seccion" aria-labelledby="btComprarTit">
    <h2 id="btComprarTit">Comprar monedas</h2>

    <c:choose>
      <c:when test="${empty paquetes}">
        <div class="bt-vacio">
          <p><b>No hay paquetes disponibles por ahora.</b></p>
          <p>Vuelve a intentarlo más tarde.</p>
        </div>
      </c:when>
      <c:otherwise>
        <ul class="bt-paquetes">
          <c:forEach var="p" items="${paquetes}">
            <li class="bt-paquete">
              <p class="bt-paq-monedas"><fmt:formatNumber value="${p.monedas}" groupingUsed="true"/> <span>monedas</span></p>
              <p class="bt-paq-precio">
                <c:if test="${p.descuento > 0}">
                  <s>US$ <fmt:formatNumber value="${p.precioLista}" minFractionDigits="2" maxFractionDigits="2"/></s>
                </c:if>
                <strong>US$ <fmt:formatNumber value="${p.precioFinal}" minFractionDigits="2" maxFractionDigits="2"/></strong>
              </p>
              <form class="bt-paq-form" method="post" action="<%= contexto %>/billetera/comprar" data-comprar>
                <input type="hidden" name="paqueteId" value="${p.id}">
                <button type="submit" class="btn small" name="pasarela" value="paypal">Pagar con PayPal</button>
                <button type="submit" class="btn outline small" name="pasarela" value="yape">Pagar con Yape</button>
              </form>
            </li>
          </c:forEach>
        </ul>
        <p class="bt-nota">Con Yape pagas en soles: el monto exacto aparece al elegir esa opción.</p>
      </c:otherwise>
    </c:choose>
  </section>

  <!-- Movimientos -->
  <section class="bt-seccion" aria-labelledby="btMovTit">
    <h2 id="btMovTit">Movimientos</h2>

    <c:choose>
      <c:when test="${empty movimientos}">
        <div class="bt-vacio">
          <p><b>Aún no tienes movimientos.</b></p>
          <p>Cuando compres monedas o desbloquees capítulos, aparecerán aquí.</p>
        </div>
      </c:when>

      <c:otherwise>
        <!-- Filtros (los cuenta y aplica billetera.js sin recargar la página) -->
        <div class="bt-filtros" role="group" aria-label="Filtrar movimientos">
          <button type="button" class="bt-filtro activo" data-filtro="todos" aria-pressed="true">Todos <span class="bt-n">0</span></button>
          <button type="button" class="bt-filtro" data-filtro="ingreso" aria-pressed="false">Ingresos <span class="bt-n">0</span></button>
          <button type="button" class="bt-filtro" data-filtro="egreso" aria-pressed="false">Egresos <span class="bt-n">0</span></button>
        </div>

        <ul class="bt-movs" id="btMovs">
          <c:forEach var="m" items="${movimientos}">
            <li class="bt-mov" data-signo="${m.monedas > 0 ? 'ingreso' : (m.monedas < 0 ? 'egreso' : 'neutro')}">
              <div class="bt-mov-info">
                <p class="bt-mov-tipo"><c:out value="${not empty etiquetas[m.tipo] ? etiquetas[m.tipo] : m.tipo}"/></p>
                <p class="bt-mov-fecha"><fmt:formatDate value="${m.creadoEn}" pattern="dd/MM/yyyy HH:mm" timeZone="America/Lima"/></p>
              </div>
              <p class="bt-mov-monto ${m.monedas > 0 ? 'pos' : (m.monedas < 0 ? 'neg' : '')}">
                <c:if test="${m.monedas > 0}">+</c:if><fmt:formatNumber value="${m.monedas}" groupingUsed="true"/>
              </p>
              <p class="bt-mov-saldo">Saldo: <fmt:formatNumber value="${m.saldo}" groupingUsed="true"/></p>
            </li>
          </c:forEach>
        </ul>

        <p class="bt-sin-resultados" id="btSinResultados" hidden>No hay movimientos con este filtro.</p>
        <p class="bt-nota">Se muestran tus últimos 50 movimientos.</p>
      </c:otherwise>
    </c:choose>
  </section>

</main>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script src="<%= contexto %>/assets/js/billetera.js"></script>
</body>
</html>
