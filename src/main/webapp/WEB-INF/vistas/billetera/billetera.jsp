<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%--
    Mi billetera. Lo usa BilleteraServlet (GET /billetera).
    Atributos: saldo, descuento (porcentaje, venceEn; null si no hay), paquetes, movimientos, etiquetas.
    Solo para autores: eco (nivel, maximo, costo, saldo, recibido, nivelRetiro, saldoRetiro),
    retiros (solicitudes del autor) y retiroCfg (comisionPct, valorMoneda). Si eco no existe, esa parte no se muestra.
    Las compras son POST a /billetera/comprar (PayPal o Yape); subir de nivel es POST a /autor/nivel
    y pedir un retiro es POST a /autor/retiro. Esta página reemplaza a la antigua "Mi economía".
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
    <c:choose>
      <c:when test="${not empty eco}">
        <p>Tu saldo de monedas, tus compras, tu nivel y retiros de autor, y tu historial de movimientos.</p>
      </c:when>
      <c:otherwise>
        <p>Tu saldo de monedas, los paquetes para recargar y tu historial de movimientos.</p>
      </c:otherwise>
    </c:choose>
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
              <form class="bt-paq-form" method="post" action="<%= contexto %>/billetera/comprar" data-unico>
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

  <%-- ===== Economía de autor (solo si el usuario es autor) ===== --%>
  <c:if test="${not empty eco}">
  <section class="bt-seccion" aria-labelledby="btAutorTit" id="autor">
    <h2 id="btAutorTit">Economía de autor</h2>

    <div class="bt-stats">
      <div class="bt-stat">
        <p class="bt-stat-etq">Nivel de autor</p>
        <p class="bt-stat-val"><c:out value="${eco.nivel}"/> <span>de <c:out value="${eco.maximo}"/></span></p>
        <progress class="bt-progreso" max="${eco.maximo}" value="${eco.nivel}" aria-label="Progreso de nivel"></progress>
      </div>
      <div class="bt-stat">
        <p class="bt-stat-etq">Total ganado</p>
        <p class="bt-stat-val"><fmt:formatNumber value="${eco.recibido}" groupingUsed="true"/> <span>monedas</span></p>
        <p class="bt-stat-nota">Por regalos y ventas.</p>
      </div>
    </div>

    <!-- Niveles -->
    <div class="bt-card">
      <h3>Niveles</h3>
      <p>Mientras más alto sea tu nivel, tus obras aparecen con más visibilidad en el catálogo.
         Cada nivel cuesta <b><fmt:formatNumber value="${eco.costo}" groupingUsed="true"/></b> monedas.</p>

      <c:choose>
        <c:when test="${eco.nivel >= eco.maximo}">
          <p class="bt-estado-linea ok">Ya estás en el nivel máximo.</p>
        </c:when>
        <c:when test="${eco.saldo >= eco.costo}">
          <form method="post" action="<%= contexto %>/autor/nivel" data-unico
                data-confirmar="¿Subir al nivel ${eco.nivel + 1}? Se descontarán ${eco.costo} monedas de tu saldo.">
            <button type="submit" class="btn small">
              Subir al nivel <c:out value="${eco.nivel + 1}"/> por
              <fmt:formatNumber value="${eco.costo}" groupingUsed="true"/> monedas
            </button>
          </form>
        </c:when>
        <c:otherwise>
          <p class="bt-estado-linea">Te faltan <b><fmt:formatNumber value="${eco.costo - eco.saldo}" groupingUsed="true"/></b>
            monedas para el siguiente nivel.</p>
        </c:otherwise>
      </c:choose>
    </div>

    <!-- Retiros -->
    <div class="bt-card">
      <h3>Retiros</h3>
      <p>Para retirar necesitas cumplir las dos condiciones a la vez:</p>
      <ul class="bt-cond">
        <li class="${eco.nivel >= eco.nivelRetiro ? 'ok' : 'no'}">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <c:choose><c:when test="${eco.nivel >= eco.nivelRetiro}"><path d="m5 12 5 5L20 7"/></c:when><c:otherwise><path d="M6 6l12 12M18 6 6 18"/></c:otherwise></c:choose>
          </svg>
          <span><span class="bt-sr"><c:out value="${eco.nivel >= eco.nivelRetiro ? 'Cumplido: ' : 'Pendiente: '}"/></span>
            Nivel <c:out value="${eco.nivelRetiro}"/> o más (tienes el <c:out value="${eco.nivel}"/>)</span>
        </li>
        <li class="${eco.saldo >= eco.saldoRetiro ? 'ok' : 'no'}">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <c:choose><c:when test="${eco.saldo >= eco.saldoRetiro}"><path d="m5 12 5 5L20 7"/></c:when><c:otherwise><path d="M6 6l12 12M18 6 6 18"/></c:otherwise></c:choose>
          </svg>
          <span><span class="bt-sr"><c:out value="${eco.saldo >= eco.saldoRetiro ? 'Cumplido: ' : 'Pendiente: '}"/></span>
            Saldo de al menos <fmt:formatNumber value="${eco.saldoRetiro}" groupingUsed="true"/> monedas</span>
        </li>
      </ul>

      <c:if test="${eco.nivel >= eco.nivelRetiro and eco.saldo >= eco.saldoRetiro}">
        <p>
          Puedes retirar hasta <b><fmt:formatNumber value="${eco.saldo}" groupingUsed="true"/></b> monedas.
          La plataforma retiene el <c:out value="${retiroCfg.comisionPct}"/>% y cada moneda vale
          US$ <c:out value="${retiroCfg.valorMoneda}"/>. Las monedas se descuentan de inmediato;
          si la solicitud se rechaza, te las devolvemos completas.
        </p>

        <form class="bt-form" method="post" action="<%= contexto %>/autor/retiro" data-unico data-retiro
              data-pct="<c:out value='${retiroCfg.comisionPct}'/>" data-valor="<c:out value='${retiroCfg.valorMoneda}'/>">
          <label for="btRetiroMonedas">Monedas a retirar</label>
          <input id="btRetiroMonedas" type="number" name="monedas" min="1" max="${eco.saldo}" required inputmode="numeric">

          <label for="btRetiroMetodo">Método de pago</label>
          <select id="btRetiroMetodo" name="metodo">
            <option value="paypal">PayPal</option>
            <option value="yape">Yape</option>
          </select>

          <label for="btRetiroDatos" id="btRetiroDatosEtq">Correo de PayPal</label>
          <input id="btRetiroDatos" type="email" name="datos" maxlength="150" required
                 placeholder="tucorreo@ejemplo.com" autocomplete="off">

          <p class="bt-estimado" aria-live="polite"></p>
          <button type="submit" class="btn">Solicitar retiro</button>
        </form>
      </c:if>
    </div>

    <!-- Mis solicitudes de retiro -->
    <h3 class="bt-subtitulo">Mis solicitudes de retiro</h3>
    <c:choose>
      <c:when test="${empty retiros}">
        <div class="bt-vacio">
          <p><b>Aún no has solicitado retiros.</b></p>
        </div>
      </c:when>
      <c:otherwise>
        <div class="bt-tabla-wrap">
          <table class="bt-tabla">
            <thead>
              <tr><th scope="col">#</th><th scope="col">Fecha</th><th scope="col">Monedas</th><th scope="col">Monto (US$)</th>
                  <th scope="col">Método</th><th scope="col">Estado</th><th scope="col">Motivo</th></tr>
            </thead>
            <tbody>
              <c:forEach var="r" items="${retiros}">
                <tr>
                  <td><c:out value="${r.id}"/></td>
                  <td><fmt:formatDate value="${r.creadoEn}" pattern="dd/MM/yyyy HH:mm" timeZone="America/Lima"/></td>
                  <td><fmt:formatNumber value="${r.monedas}" groupingUsed="true"/></td>
                  <td><fmt:formatNumber value="${r.montoUsd}" minFractionDigits="2" maxFractionDigits="2"/></td>
                  <td><c:out value="${r.metodo == 'paypal' ? 'PayPal' : (r.metodo == 'yape' ? 'Yape' : r.metodo)}"/></td>
                  <td>
                    <c:choose>
                      <c:when test="${r.estado == 'pendiente'}"><span class="bt-badge pend">Pendiente</span></c:when>
                      <c:when test="${r.estado == 'pagado'}"><span class="bt-badge pag">Pagado</span></c:when>
                      <c:when test="${r.estado == 'rechazado'}"><span class="bt-badge rech">Rechazado</span></c:when>
                      <c:otherwise><span class="bt-badge"><c:out value="${r.estado}"/></span></c:otherwise>
                    </c:choose>
                  </td>
                  <td><c:out value="${empty r.motivo ? '—' : r.motivo}"/></td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
        <p class="bt-nota">Se muestran tus últimas 20 solicitudes.</p>
      </c:otherwise>
    </c:choose>
  </section>
  </c:if>

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
