<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%--
    Notificaciones. Lo usa NotificacionServlet (GET /notificaciones).
    Atributos: notificaciones (lista de Notificacion), pendientes (total sin leer).
    Las acciones (leer, leerTodas) son POST a /notificaciones, igual que antes.
    El encabezado es el compartido (encabezado-datos.jspf + encabezado.jspf), igual que en Mi biblioteca.
--%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Notificaciones · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,300;7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/notificaciones/notificaciones.css">
<script>
  // Mismo modo claro/noche que el resto de SAFIR
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main class="nt-main">

  <a class="nt-volver" href="<%= contexto %>/auth/cuenta">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    Volver a Mi cuenta
  </a>

  <div class="nt-titulo">
    <h1>Notificaciones</h1>
    <p>Tus últimos avisos, del más reciente al más antiguo.</p>
    <p class="nt-resumen">
      <c:choose>
        <c:when test="${pendientes == 0}">No tienes notificaciones sin leer.</c:when>
        <c:when test="${pendientes == 1}">Tienes <b>1</b> notificación sin leer.</c:when>
        <c:otherwise>Tienes <b><c:out value="${pendientes}"/></b> notificaciones sin leer.</c:otherwise>
      </c:choose>
    </p>
  </div>

  <c:choose>
    <c:when test="${empty notificaciones}">
      <div class="nt-vacio">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 9a6 6 0 0 1 12 0c0 6 2.5 7.5 2.5 7.5h-17S6 15 6 9"/><path d="M10 20a2 2 0 0 0 4 0"/></svg>
        <p><b>No tienes notificaciones todavía.</b></p>
        <p>Cuando haya novedades, aparecerán aquí.</p>
      </div>
    </c:when>

    <c:otherwise>
      <!-- TAREA 5: Mensajes (sobre) / Actividad (campana). ?ver=mensajes|actividad abre la pestaña. -->
      <div class="nt-tabs" role="group" aria-label="Tipo de aviso">
        <button type="button" class="nt-tab" data-categoria="todas" aria-pressed="false">Todo <span class="nt-n">0</span></button>
        <button type="button" class="nt-tab" data-categoria="mensajes" aria-pressed="false">Mensajes <span class="nt-n">0</span></button>
        <button type="button" class="nt-tab" data-categoria="actividad" aria-pressed="false">Notificaciones <span class="nt-n">0</span></button>
      </div>

      <div class="nt-barra">
        <!-- Filtros (los cuenta y aplica notificaciones.js sin recargar la página) -->
        <div class="nt-filtros" role="group" aria-label="Filtrar notificaciones">
          <button type="button" class="nt-filtro activo" data-filtro="todas" aria-pressed="true">Todas <span class="nt-n">0</span></button>
          <button type="button" class="nt-filtro" data-filtro="sin_leer" aria-pressed="false">Sin leer <span class="nt-n">0</span></button>
          <button type="button" class="nt-filtro" data-filtro="leidas" aria-pressed="false">Leídas <span class="nt-n">0</span></button>
        </div>

        <c:if test="${pendientes > 0}">
          <form method="post" action="<%= contexto %>/notificaciones">
            <input type="hidden" name="accion" value="leerTodas">
            <input type="hidden" name="ver" value="<c:out value='${ver}'/>">
            <button type="submit" class="btn outline small">Marcar todas como leídas</button>
          </form>
        </c:if>
      </div>

      <ul class="nt-lista" id="ntLista" data-ver="<c:out value='${ver}'/>">
        <c:forEach var="n" items="${notificaciones}">
          <li class="nt-card ${n.leida ? 'leida' : 'nueva'}" id="notif-${n.id}" data-leida="${n.leida}" data-categoria="${n.categoria}">

            <span class="nt-icono" aria-hidden="true">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9a6 6 0 0 1 12 0c0 6 2.5 7.5 2.5 7.5h-17S6 15 6 9"/><path d="M10 20a2 2 0 0 0 4 0"/></svg>
            </span>

            <div class="nt-cuerpo">
              <p class="nt-tipo">
                <span class="nt-tipo-txt"><c:out value="${n.tipoTexto}"/></span>
                <c:if test="${not n.leida}"><span class="nt-badge">Nueva</span></c:if>
              </p>
              <p class="nt-mensaje"><c:out value="${n.mensaje}"/></p>
              <p class="nt-fecha">
                <time datetime="${n.creadoEn}" data-fecha><c:out value="${fn:replace(fn:substring(n.creadoEn, 0, 16), 'T', ' ')}"/></time>
              </p>

              <c:choose>
                <c:when test="${not empty n.capituloId and not empty n.obraId}">
                  <a class="btn outline small nt-enlace" href="<%= contexto %>/lectura?obraId=${n.obraId}&amp;capituloId=${n.capituloId}">Abrir capítulo</a>
                </c:when>
                <c:when test="${not empty n.obraId}">
                  <a class="btn outline small nt-enlace" href="<%= contexto %>/obra?id=${n.obraId}">Ver obra</a>
                </c:when>
              </c:choose>
            </div>

            <c:if test="${not n.leida}">
              <div class="nt-acciones">
                <form method="post" action="<%= contexto %>/notificaciones">
                  <input type="hidden" name="accion" value="leer">
                  <input type="hidden" name="notificacionId" value="${n.id}">
                  <input type="hidden" name="ver" value="<c:out value='${ver}'/>">
                  <button type="submit" class="nt-icono-btn" title="Marcar como leída" aria-label="Marcar como leída">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>
                  </button>
                </form>
              </div>
            </c:if>
          </li>
        </c:forEach>
      </ul>

      <p class="nt-sin-resultados" id="ntSinResultados" hidden>No hay notificaciones con este filtro.</p>
    </c:otherwise>
  </c:choose>

</main>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script src="<%= contexto %>/assets/js/notificaciones.js"></script>
</body>
</html>