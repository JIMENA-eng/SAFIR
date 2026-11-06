<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%--
    Editor de capítulo (nuevo / editar). Lo usa GestionCapituloServlet.
    Atributos: obraId, capitulo (solo al editar), error y tituloFormulario / contenidoFormulario
    cuando se vuelve a mostrar tras un error de validación.
    El encabezado es el compartido (encabezado-datos.jspf + encabezado.jspf), igual que en Mi cuenta y Obra.
--%>
<c:set var="editando" value="${not empty capitulo}"/>
<c:set var="tituloSel" value="${not empty tituloFormulario ? tituloFormulario : capitulo.titulo}"/>
<c:set var="contenidoSel" value="${not empty contenidoFormulario ? contenidoFormulario : capitulo.contenido}"/>
<c:choose>
  <c:when test="${editando}">
    <c:url var="urlFormulario" value="/autor/capitulo/editar"><c:param name="id" value="${capitulo.id}"/></c:url>
  </c:when>
  <c:otherwise>
    <c:url var="urlFormulario" value="/autor/capitulo/nuevo"/>
  </c:otherwise>
</c:choose>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><c:choose><c:when test="${editando}">Editar capítulo</c:when><c:otherwise>Nuevo capítulo</c:otherwise></c:choose> · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,300;7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/autor/capitulo-editor.css">
<script>
  // Mismo modo claro/noche que el resto de SAFIR
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main class="ce-main">

  <a class="ce-volver" href="<%= contexto %>/autor/capitulos?obraId=${obraId}">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    Volver a los capítulos
  </a>

  <div class="ce-titulo">
    <h1><c:choose><c:when test="${editando}">Editar capítulo</c:when><c:otherwise>Escribir un capítulo nuevo</c:otherwise></c:choose></h1>
    <p>Guarda tu avance como borrador y publícalo cuando esté listo.</p>
    <c:if test="${editando}">
      <p class="ce-estado">
        <c:if test="${not empty capitulo.numero}"><span class="ce-pildora">Capítulo <c:out value="${capitulo.numero}"/></span></c:if>
        <span class="ce-pildora ${capitulo.estado == 'publicado' ? 'ok' : 'borrador'}">
          <c:choose><c:when test="${capitulo.estado == 'publicado'}">Publicado</c:when><c:otherwise>Borrador</c:otherwise></c:choose>
        </span>
      </p>
    </c:if>
  </div>

  <c:if test="${not empty error}">
    <p class="ce-aviso" role="alert"><c:out value="${error}"/></p>
  </c:if>

  <form class="ce-form" id="capForm" method="post" action="${urlFormulario}">
    <input type="hidden" name="obraId" value="${obraId}">

    <div class="ce-card">
      <div class="ce-campo">
        <div class="ce-label-fila">
          <label for="titulo">Título del capítulo <b>*</b></label>
          <span class="ce-contador" id="tituloCont">0 / 150</span>
        </div>
        <input type="text" id="titulo" name="titulo" maxlength="150" required
               placeholder="Ej.: El primer vuelo"
               value="<c:out value='${tituloSel}'/>">
      </div>

      <div class="ce-campo">
        <div class="ce-label-fila">
          <label for="contenido">Contenido <b>*</b></label>
          <span class="ce-contador" id="palabrasCont" aria-live="polite">0 palabras</span>
        </div>
        <textarea id="contenido" name="contenido" rows="22" required
                  placeholder="Empieza a escribir tu historia…"><c:out value="${contenidoSel}"/></textarea>
        <small>Ctrl + S (o ⌘ + S) para guardar el borrador.</small>
      </div>
    </div>

    <div class="ce-acciones">
      <button type="submit" class="btn" id="btnGuardar">Guardar borrador</button>
      <a class="btn outline" href="<%= contexto %>/autor/capitulos?obraId=${obraId}">Cancelar</a>
    </div>
  </form>

  <c:if test="${editando and capitulo.estado == 'borrador'}">
    <form class="ce-card ce-publicar" method="post" action="<%= contexto %>/autor/capitulo/publicar">
      <input type="hidden" name="id" value="${capitulo.id}">
      <div class="ce-publicar-texto">
        <b>¿Listo para tus lectores?</b>
        <small>Guarda primero tus cambios: al publicar se usa la última versión guardada del borrador.</small>
      </div>
      <button type="submit" class="btn gold">Publicar capítulo</button>
    </form>
  </c:if>

</main>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script src="<%= contexto %>/assets/js/capitulo-editor.js"></script>
</body>
</html>
