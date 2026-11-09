<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%--
    Revisión de una importación de capítulos. Lo usa GestionCapituloServlet
    (GET /autor/capitulos/importar/revision?obraId=).
    Atributos: obraId, obra, importacion (mapa: nombreOriginal, totalCapitulos)
    y vista (lista de mapas: numero, titulo, palabras, extracto).
--%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Revisar importación · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,300;7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/autor/capitulos.css">
<script>
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main class="cl-main">

  <a class="cl-volver" href="<%= contexto %>/autor/capitulos?obraId=${obraId}">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    Volver a los capítulos
  </a>

  <header class="cl-cab" style="grid-template-columns: minmax(0, 1fr);">
    <div class="cl-cab-texto">
      <p class="cl-etq">Importación en revisión · <c:out value="${obra.titulo}"/></p>
      <h1>Revisa los capítulos detectados</h1>
      <ul class="cl-resumen" aria-label="Resumen de la importación">
        <li><b><c:out value="${not empty importacion.nombreOriginal ? importacion.nombreOriginal : 'Archivo importado'}"/></b></li>
        <li><b>${fn:length(vista)}</b> <c:out value="${fn:length(vista) == 1 ? 'capítulo' : 'capítulos'}"/></li>
      </ul>
    </div>
  </header>

  <c:if test="${fn:length(vista) == 1}">
    <p class="cl-nota cl-rev-aviso" role="status">Solo se detectó un capítulo. Si no se encontró ningún encabezado («Capítulo 1», «Parte 1» o un número romano), todo el texto queda como un único capítulo. Si tu archivo tiene varios, recházalo, escribe cada encabezado en su propia línea y vuelve a subirlo.</p>
  </c:if>

  <p class="cl-nota cl-rev-aviso" role="status">Al confirmar, los capítulos se guardan como <b>borrador</b>: no se publica nada. Después podrás editarlos uno por uno y publicarlos cuando estés listo.</p>

  <ol class="cl-rev-lista">
    <c:forEach var="cap" items="${vista}">
      <li class="cl-rev-item">
        <span class="cl-rev-num" aria-hidden="true">${cap.numero}</span>
        <div>
          <b class="cl-rev-titulo"><c:out value="${cap.titulo}"/></b>
          <span class="cl-rev-meta">${cap.palabras} palabras</span>
          <p class="cl-rev-extracto"><c:out value="${cap.extracto}"/></p>
        </div>
      </li>
    </c:forEach>
  </ol>

  <div class="cl-rev-acciones">
    <form method="post" action="<%= contexto %>/autor/capitulos/importar/confirmar?obraId=${obraId}">
      <button type="submit" class="btn">Guardar como borradores</button>
    </form>
    <form method="post" action="<%= contexto %>/autor/capitulos/importar/rechazar?obraId=${obraId}"
          data-confirmar="¿Descartar esta importación? Se borrarán los capítulos detectados y el archivo.">
      <button type="submit" class="btn outline">Rechazar</button>
    </form>
  </div>

</main>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script>
  // Misma confirmación que en la lista de capítulos
  Array.prototype.forEach.call(document.querySelectorAll('form[data-confirmar]'), function (f) {
    f.addEventListener('submit', function (e) {
      if (!window.confirm(f.getAttribute('data-confirmar'))) { e.preventDefault(); }
    });
  });
</script>
</body>
</html>
