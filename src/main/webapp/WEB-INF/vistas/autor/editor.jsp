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
<%-- Música: pista (la guardada, al editar), musicaOpcion / musicaYoutubeFormulario /
     musicaBucleFormulario cuando se vuelve a mostrar tras un error. --%>
<c:set var="musicaSel" value="${not empty musicaOpcion ? musicaOpcion : (not empty pista ? 'mantener' : 'ninguna')}"/>
<c:set var="bucleSel" value="${not empty musicaBucleFormulario ? musicaBucleFormulario : (not empty pista and pista.enBucle)}"/>
<c:choose>
  <c:when test="${editando}">
    <c:url var="urlFormulario" value="/autor/capitulo/editar"><c:param name="id" value="${capitulo.id}"/></c:url>
  </c:when>
  <c:otherwise>
    <%-- obraId también en la URL: así llega aunque el audio supere el máximo --%>
    <c:url var="urlFormulario" value="/autor/capitulo/nuevo"><c:param name="obraId" value="${obraId}"/></c:url>
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

  <form class="ce-form" id="capForm" method="post" action="${urlFormulario}" enctype="multipart/form-data">
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

    <%-- Música del capítulo: enlace de YouTube o archivo de audio --%>
    <section class="ce-card ce-musica" aria-labelledby="musicaTitulo">
      <div class="ce-musica-cabecera">
        <h2 id="musicaTitulo">Música del capítulo</h2>
        <p>Opcional. Tus lectores podrán reproducirla mientras leen este capítulo.</p>
      </div>

      <c:if test="${not empty pista}">
        <div class="ce-musica-actual">
          <span class="ce-musica-etiqueta">Música guardada:</span>
          <b><c:out value="${pista.titulo}"/></b>
          <c:choose>
            <c:when test="${pista.youtube}">
              <div class="ce-video">
                <iframe src="https://www.youtube-nocookie.com/embed/${pista.youtubeId}?rel=0"
                        title="Música del capítulo (YouTube)" loading="lazy"
                        allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen></iframe>
              </div>
            </c:when>
            <c:otherwise>
              <audio controls preload="none" src="${pageContext.request.contextPath}/media/${pista.archivoRuta}"></audio>
            </c:otherwise>
          </c:choose>
        </div>
      </c:if>

      <fieldset class="ce-opciones">
        <legend class="ce-oculto">¿Qué música acompaña al capítulo?</legend>
        <c:if test="${not empty pista}">
          <label><input type="radio" name="musicaOpcion" value="mantener" ${musicaSel == 'mantener' ? 'checked' : ''}> Mantener la actual</label>
        </c:if>
        <label><input type="radio" name="musicaOpcion" value="ninguna" ${musicaSel == 'ninguna' ? 'checked' : ''}>
          <c:choose><c:when test="${not empty pista}">Quitar la música</c:when><c:otherwise>Sin música</c:otherwise></c:choose>
        </label>
        <label><input type="radio" name="musicaOpcion" value="youtube" ${musicaSel == 'youtube' ? 'checked' : ''}> Enlace de YouTube</label>
        <label><input type="radio" name="musicaOpcion" value="archivo" ${musicaSel == 'archivo' ? 'checked' : ''}> Subir un audio</label>
      </fieldset>

      <div class="ce-campo ce-musica-panel" data-panel="youtube" ${musicaSel == 'youtube' ? '' : 'hidden'}>
        <label for="musicaYoutube">Enlace del video</label>
        <input type="url" id="musicaYoutube" name="musicaYoutube" maxlength="500" inputmode="url"
               placeholder="https://www.youtube.com/watch?v=…  o  https://youtu.be/…"
               value="<c:out value='${musicaYoutubeFormulario}'/>">
        <small id="ytAyuda">Pega el enlace de un video de YouTube. Se mostrará aquí para que lo pruebes.</small>
        <div class="ce-video" id="ytVista" hidden></div>
      </div>

      <div class="ce-campo ce-musica-panel" data-panel="archivo" ${musicaSel == 'archivo' ? '' : 'hidden'}>
        <label for="musicaArchivo">Archivo de audio</label>
        <input type="file" id="musicaArchivo" name="musicaArchivo"
               accept="audio/mpeg,.mp3,audio/mp4,.m4a,audio/aac,.aac,audio/ogg,.ogg,audio/wav,.wav"
               data-max-bytes="20971520">
        <small id="audioAyuda">MP3, M4A, AAC, OGG o WAV. Máximo 20 MB.</small>
        <audio id="audioVista" controls hidden></audio>
      </div>

      <label class="ce-check" id="bucleFila" ${musicaSel == 'ninguna' ? 'hidden' : ''}>
        <input type="checkbox" name="musicaBucle" value="1" ${bucleSel ? 'checked' : ''}>
        Repetir la música en bucle
      </label>
    </section>

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
