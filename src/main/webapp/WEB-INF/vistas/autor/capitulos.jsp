<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%--
    Gestión de capítulos de una obra. Lo usa GestionCapituloServlet (GET /autor/capitulos?obraId=).
    Atributos: obraId, capitulos (lista de Capitulo) y obra (mapa con titulo y portadaRuta).
    El encabezado es el compartido (encabezado-datos.jspf + encabezado.jspf), igual que en Mi cuenta y Obra.
--%>
<c:set var="total" value="${fn:length(capitulos)}"/>
<c:set var="nPublicados" value="0"/>
<c:forEach var="cap" items="${capitulos}">
  <c:if test="${cap.estado == 'publicado'}"><c:set var="nPublicados" value="${nPublicados + 1}"/></c:if>
</c:forEach>
<c:set var="nBorradores" value="${total - nPublicados}"/>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Capítulos · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,300;7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/autor/capitulos.css">
<script>
  // Mismo modo claro/noche que el resto de SAFIR
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main class="cl-main">

  <a class="cl-volver" href="<%= contexto %>/autor/obra/editar?id=${obraId}">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    Volver a la obra
  </a>

  <!-- Cabecera: portada + título de la obra + acción principal -->
  <header class="cl-cab">
    <span class="cl-portada" aria-hidden="true">
      <c:choose>
        <c:when test="${not empty obra.portadaRuta}">
          <img src="<%= contexto %>/media/<c:out value='${obra.portadaRuta}'/>" alt="">
        </c:when>
        <c:otherwise>
          <span><c:out value="${not empty obra.titulo ? fn:toUpperCase(fn:substring(obra.titulo, 0, 1)) : '?'}"/></span>
        </c:otherwise>
      </c:choose>
    </span>
    <div class="cl-cab-texto">
      <p class="cl-etq">Capítulos de</p>
      <h1><c:out value="${not empty obra.titulo ? obra.titulo : 'tu obra'}"/></h1>
      <ul class="cl-resumen" aria-label="Resumen de capítulos">
        <li><b>${total}</b> <c:out value="${total == 1 ? 'capítulo' : 'capítulos'}"/></li>
        <li><b>${nPublicados}</b> <c:out value="${nPublicados == 1 ? 'publicado' : 'publicados'}"/></li>
        <li><b>${nBorradores}</b> <c:out value="${nBorradores == 1 ? 'borrador' : 'borradores'}"/></li>
      </ul>
    </div>
    <a class="btn cl-nuevo" href="<%= contexto %>/autor/capitulo/nuevo?obraId=${obraId}">+ Nuevo capítulo</a>
  </header>

  <c:choose>
    <c:when test="${empty capitulos}">
      <div class="cl-vacio">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>
        <p><b>Todavía no tienes capítulos en esta obra.</b></p>
        <p>Escribe el primero, guárdalo como borrador y publícalo cuando esté listo.</p>
        <a class="btn" href="<%= contexto %>/autor/capitulo/nuevo?obraId=${obraId}">Escribir el primer capítulo</a>
      </div>
    </c:when>

    <c:otherwise>
      <ol class="cl-lista">
        <c:forEach var="capitulo" items="${capitulos}" varStatus="fila">
          <li class="cl-item">
            <span class="cl-num" aria-hidden="true">
              <c:choose>
                <c:when test="${not empty capitulo.numero}"><c:out value="${capitulo.numero}"/></c:when>
                <c:otherwise>–</c:otherwise>
              </c:choose>
            </span>

            <div class="cl-info">
              <b class="cl-nombre"><c:out value="${capitulo.titulo}"/></b>
              <span class="cl-meta">
                <span class="cl-pildora ${capitulo.estado == 'publicado' ? 'ok' : 'borrador'}">
                  <c:choose><c:when test="${capitulo.estado == 'publicado'}">Publicado</c:when><c:otherwise>Borrador</c:otherwise></c:choose>
                </span>
                <c:if test="${empty capitulo.numero}"><small>Sin número hasta que lo publiques</small></c:if>
              </span>
            </div>

            <div class="cl-acciones">
              <c:if test="${capitulo.estado == 'borrador'}">
                <a class="btn outline small" href="<%= contexto %>/autor/capitulo/editar?id=${capitulo.id}">Editar</a>
                <form method="post" action="<%= contexto %>/autor/capitulo/publicar" data-confirmar="¿Publicar este capítulo? Se usará la última versión guardada del borrador.">
                  <input type="hidden" name="id" value="${capitulo.id}">
                  <button type="submit" class="btn small">Publicar</button>
                </form>
              </c:if>
            </div>
          </li>
        </c:forEach>
      </ol>
    </c:otherwise>
  </c:choose>

</main>

<%-- Aviso flotante: aparece al volver de guardar o publicar y se oculta solo --%>
<c:if test="${param.guardado == '1' or param.publicado == '1'}">
  <div class="cl-toast" id="avisoGuardado" role="status" aria-live="polite">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>
    <span><c:choose><c:when test="${param.publicado == '1'}">El capítulo se publicó correctamente.</c:when><c:otherwise>El borrador se guardó correctamente.</c:otherwise></c:choose></span>
  </div>
</c:if>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script src="<%= contexto %>/assets/js/aviso-flotante.js"></script>
<script src="<%= contexto %>/assets/js/capitulos.js"></script>
</body>
</html>
