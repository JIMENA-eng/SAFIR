<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%--
    Formulario de obra (crear / editar). Lo usa ObraEdicionServlet.
    Atributos: generos (lista de {id, nombre}), modoEdicion, obra (mapa, solo al editar),
    error y los valores *Formulario cuando se vuelve a mostrar tras un error de validación.
    El encabezado es el compartido (encabezado-datos.jspf + encabezado.jspf), igual que en Mi cuenta y Perfil.
--%>
<c:set var="tituloSel"
       value="${not empty tituloFormulario ? tituloFormulario : (modoEdicion ? obra.titulo : '')}"/>
<c:set var="descripcionSel"
       value="${not empty descripcionFormulario ? descripcionFormulario : (modoEdicion ? obra.descripcion : '')}"/>
<c:set var="generoSel"
       value="${not empty generoFormulario ? generoFormulario : (modoEdicion ? obra.generoId : '')}"/>
<c:set var="clasificacionSel"
       value="${not empty clasificacionFormulario ? clasificacionFormulario : (modoEdicion ? obra.clasificacion : 'todo_publico')}"/>
<c:set var="bloqueoSel"
       value="${not empty bloqueoFormulario ? bloqueoFormulario : (modoEdicion ? obra.bloqueoActivo : false)}"/>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><c:choose><c:when test="${modoEdicion}">Editar obra</c:when><c:otherwise>Nueva obra</c:otherwise></c:choose> · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,300;7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/autor/obra-formulario.css">
<script>
  // Mismo modo claro/noche que el resto de SAFIR
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
</script>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main class="of-main">

  <a class="of-volver" href="<%= contexto %>/auth/cuenta#mis-obras">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6"/></svg>
    Volver a Mi cuenta
  </a>

  <div class="of-titulo">
    <h1><c:choose><c:when test="${modoEdicion}">Editar obra</c:when><c:otherwise>Crear una obra</c:otherwise></c:choose></h1>
    <p>
      <c:choose>
        <c:when test="${modoEdicion}">Actualiza los datos de tu obra. Los cambios se ven en cuanto guardes.</c:when>
        <c:otherwise>Cuéntanos lo básico. Se guardará como borrador y podrás publicarla cuando tenga al menos un capítulo publicado.</c:otherwise>
      </c:choose>
    </p>
  </div>

  <c:if test="${not empty error}">
    <p class="of-aviso" role="alert"><c:out value="${error}"/></p>
  </c:if>

  <c:choose>
    <c:when test="${modoEdicion}">
      <c:url var="urlFormulario" value="/autor/obra/editar"><c:param name="id" value="${obra.id}"/></c:url>
    </c:when>
    <c:otherwise>
      <c:url var="urlFormulario" value="/autor/obra/nueva"/>
    </c:otherwise>
  </c:choose>

  <div class="of-grid">

    <form class="of-form" id="obraForm" method="post" action="${urlFormulario}" enctype="multipart/form-data">

      <!-- 1. Datos principales -->
      <div class="of-card">
        <h2><span class="of-num">1</span> Datos de la obra</h2>

        <div class="of-datos">

        <!-- Lado izquierdo: portada del libro -->
        <div class="of-subida">
          <span class="of-subida-etq">Portada</span>
          <label class="of-subida-caja" for="portadaInput">
            <img id="portadaImg" alt="Portada del libro"
                 <c:if test="${empty obra.portadaRuta}">hidden</c:if>
                 <c:if test="${not empty obra.portadaRuta}">src="${pageContext.request.contextPath}/media/<c:out value='${obra.portadaRuta}'/>"</c:if>>
            <span class="of-subida-vacio" id="portadaVacio" <c:if test="${not empty obra.portadaRuta}">hidden</c:if>>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.1-3.1a2 2 0 0 0-2.8 0L6 21"/></svg>
              Subir portada
            </span>
          </label>
          <input type="file" name="portada" id="portadaInput" class="of-sr" accept="image/png,image/jpeg,image/webp">
          <small id="portadaNombre">JPG, PNG o WebP · hasta 5 MB</small>
        </div>

        <!-- Lado derecho: título y descripción -->
        <div class="of-datos-campos">

        <div class="of-campo">
          <div class="of-label-fila">
            <label for="titulo">Título <b aria-hidden="true">*</b></label>
            <span class="of-contador" id="tituloCont" aria-live="polite">0/100</span>
          </div>
          <input type="text" id="titulo" name="titulo" maxlength="100" required autocomplete="off"
                 placeholder="Ej.: El faro de las estrellas"
                 value="<c:out value='${tituloSel}'/>">
        </div>

        <div class="of-campo">
          <div class="of-label-fila">
            <label for="descripcion">Descripción</label>
            <span class="of-contador" id="descCont" aria-live="polite">0/2000</span>
          </div>
          <textarea id="descripcion" name="descripcion" rows="6" maxlength="2000"
                    placeholder="¿De qué trata? Una buena sinopsis invita a leer."><c:out value="${descripcionSel}"/></textarea>
          <small>Opcional, pero ayuda a que los lectores se animen a empezar.</small>
        </div>

        </div><!-- /of-datos-campos -->
        </div><!-- /of-datos -->
      </div>

      <!-- 2. Género -->
      <div class="of-card">
        <h2><span class="of-num">2</span> Género <b class="of-req" aria-hidden="true">*</b></h2>
        <fieldset class="of-fieldset">
          <legend class="of-sr">Género de la obra</legend>
          <div class="of-chips" id="generos">
            <c:forEach var="g" items="${generos}">
              <label class="of-chip">
                <input type="radio" name="generoId" value="${g.id}" required ${g.id == generoSel ? 'checked' : ''}>
                <span><c:out value="${g.nombre}"/></span>
              </label>
            </c:forEach>
          </div>
        </fieldset>
      </div>

      <!-- 3. Clasificación -->
      <div class="of-card">
        <h2><span class="of-num">3</span> Clasificación <b class="of-req" aria-hidden="true">*</b></h2>
        <fieldset class="of-fieldset">
          <legend class="of-sr">Clasificación por edad</legend>
          <div class="of-opciones" id="clasificaciones">
            <label class="of-opcion">
              <input type="radio" name="clasificacion" value="todo_publico" ${clasificacionSel == 'todo_publico' ? 'checked' : ''}>
              <span class="of-opcion-cuerpo"><b>Todo público</b><small>Para cualquier lector.</small></span>
            </label>
            <label class="of-opcion">
              <input type="radio" name="clasificacion" value="mayores_13" ${clasificacionSel == 'mayores_13' ? 'checked' : ''}>
              <span class="of-opcion-cuerpo"><b>Mayores de 13</b><small>Para lectores desde los 13 años.</small></span>
            </label>
            <label class="of-opcion">
              <input type="radio" name="clasificacion" value="mayores_18" ${clasificacionSel == 'mayores_18' ? 'checked' : ''}>
              <span class="of-opcion-cuerpo"><b>Mayores de 18 (+18)</b><small>Contenido solo para adultos.</small></span>
            </label>
          </div>
        </fieldset>
      </div>

      <!-- 4. Monedas -->
      <div class="of-card">
        <h2><span class="of-num">4</span> Capítulos con monedas</h2>
        <label class="of-switch">
          <input type="checkbox" name="bloqueoActivo" role="switch" ${bloqueoSel ? 'checked' : ''}>
          <span class="of-pista" aria-hidden="true"><i></i></span>
          <span class="of-switch-texto">
            <b>Cobrar monedas por los capítulos avanzados</b>
            <small>Desactivado: todos los capítulos son gratis. Activado: los primeros capítulos siguen libres y los siguientes se desbloquean con monedas.</small>
          </span>
        </label>
      </div>

      <!-- 5. Capítulos desde un archivo (solo al crear) -->
      <c:if test="${not modoEdicion}">
      <div class="of-card">
        <h2><span class="of-num">5</span> Capítulos desde un archivo <small class="of-opcional">Opcional</small></h2>
        <label class="of-archivo" for="capitulosInput">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/><path d="M12 17v-6"/><path d="m9.5 13.5 2.5-2.5 2.5 2.5"/></svg>
          <span class="of-archivo-texto">
            <b id="capitulosNombre">Subir PDF, DOCX o TXT</b>
            <small id="capitulosAyuda">Hasta 20 MB. Los capítulos se detectan solos.</small>
          </span>
          <button type="button" class="of-archivo-quitar" id="capitulosQuitar" hidden>Quitar</button>
        </label>
        <input type="file" name="capitulosArchivo" id="capitulosInput" class="of-sr"
               accept=".pdf,.docx,.txt,application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document,text/plain">
        <p class="of-formato">
          Cada capítulo debe empezar con una línea como <code>Capítulo 1</code> o
          <code>Capítulo 2: El regreso</code>. Se guardan como borradores, en el orden del archivo,
          y los verás en la lista de capítulos al crear la obra.
        </p>
      </div>
      </c:if>

      <div class="of-acciones">
        <button type="submit" class="btn" id="btnGuardar">
          <c:choose><c:when test="${modoEdicion}">Guardar cambios</c:when><c:otherwise>Crear obra</c:otherwise></c:choose>
        </button>
        <c:if test="${modoEdicion}">
          <a class="btn outline" href="<%= contexto %>/autor/capitulos?obraId=${obra.id}">Administrar capítulos</a>
        </c:if>
        <a class="btn outline" href="<%= contexto %>/auth/cuenta#mis-obras">Cancelar</a>
      </div>
    </form>

    <!-- Vista previa (se actualiza mientras escribes) -->
    <aside class="of-previa" aria-label="Vista previa de la obra">
      <p class="of-previa-etq">Así se verá tu obra</p>
      <div class="of-tarjeta">
        <span class="of-portada" id="pvInicial" aria-hidden="true">
          <img id="pvImg" alt=""
               <c:if test="${empty obra.portadaRuta}">hidden</c:if>
               <c:if test="${not empty obra.portadaRuta}">src="${pageContext.request.contextPath}/media/<c:out value='${obra.portadaRuta}'/>"</c:if>>
          <span id="pvLetra">?</span>
        </span>
        <div class="of-tarjeta-info">
          <b id="pvTitulo" class="vacio">Título de tu obra</b>
          <div class="of-etiquetas">
            <span class="of-etiqueta" id="pvGenero">Género</span>
            <span class="of-etiqueta alt" id="pvClasif">Todo público</span>
            <span class="of-etiqueta oro" id="pvMonedas" hidden>Con monedas</span>
          </div>
        </div>
        <p class="of-tarjeta-desc vacio" id="pvDesc">Aquí aparecerá la descripción de tu obra.</p>
      </div>
    </aside>

  </div>
</main>

<%-- Aviso flotante: aparece al volver de guardar (?guardado=1) y se oculta solo --%>
<c:if test="${modoEdicion and param.guardado == '1'}">
  <div class="of-toast" id="avisoGuardado" role="status" aria-live="polite">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>
    <span>Los cambios se guardaron correctamente.</span>
  </div>
</c:if>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script src="<%= contexto %>/assets/js/aviso-flotante.js"></script>
<script>
(function () {
  var form = document.getElementById('obraForm');
  var titulo = document.getElementById('titulo');
  var desc = document.getElementById('descripcion');
  var tituloCont = document.getElementById('tituloCont');
  var descCont = document.getElementById('descCont');
  var pvLetra = document.getElementById('pvLetra');
  var pvImg = document.getElementById('pvImg');
  var inPortada = document.getElementById('portadaInput');
  var portadaImg = document.getElementById('portadaImg');
  var portadaVacio = document.getElementById('portadaVacio');
  var portadaNombre = document.getElementById('portadaNombre');
  var AYUDA = portadaNombre.textContent;
  var pvTitulo = document.getElementById('pvTitulo');
  var pvGenero = document.getElementById('pvGenero');
  var pvClasif = document.getElementById('pvClasif');
  var pvDesc = document.getElementById('pvDesc');
  var pvMonedas = document.getElementById('pvMonedas');
  var monedas = form.querySelector('input[name="bloqueoActivo"]');
  var inCapitulos = document.getElementById('capitulosInput');
  var capNombre = document.getElementById('capitulosNombre');
  var capAyuda = document.getElementById('capitulosAyuda');
  var capQuitar = document.getElementById('capitulosQuitar');

  function marcado(nombre) { return form.querySelector('input[name="' + nombre + '"]:checked'); }
  function textoDe(input) {
    if (!input) return '';
    var el = input.parentNode.querySelector('b') || input.parentNode.querySelector('span');
    return el ? el.textContent.trim() : '';
  }

  function actualizar() {
    var t = titulo.value.trim();
    var d = desc.value.trim();
    tituloCont.textContent = titulo.value.length + '/100';
    descCont.textContent = desc.value.length + '/2000';

    pvTitulo.textContent = t || 'Título de tu obra';
    pvTitulo.className = t ? '' : 'vacio';
    pvLetra.textContent = t ? Array.from(t)[0].toUpperCase() : '?';
    pvLetra.hidden = !pvImg.hidden;

    var g = marcado('generoId');
    pvGenero.textContent = g ? textoDe(g) : 'Género';
    pvGenero.className = 'of-etiqueta' + (g ? '' : ' vacio');

    var c = marcado('clasificacion');
    pvClasif.textContent = c ? textoDe(c) : 'Todo público';

    pvDesc.textContent = d || 'Aquí aparecerá la descripción de tu obra.';
    pvDesc.className = 'of-tarjeta-desc' + (d ? '' : ' vacio');
    pvMonedas.hidden = !monedas.checked;
  }

  // Portada: valida y muestra la imagen elegida (formulario y vista previa)
  inPortada.addEventListener('change', function () {
    var f = inPortada.files && inPortada.files[0];
    if (!f) return;
    if (['image/jpeg', 'image/png', 'image/webp'].indexOf(f.type) < 0) {
      alert('Formato no permitido. Usa JPG, PNG o WebP.');
      inPortada.value = ''; return;
    }
    if (f.size > 5 * 1024 * 1024) {
      alert('La portada supera el máximo de 5 MB.');
      inPortada.value = ''; return;
    }
    var url = URL.createObjectURL(f);
    portadaImg.src = url; portadaImg.hidden = false; portadaVacio.hidden = true;
    pvImg.src = url; pvImg.hidden = false;
    portadaNombre.textContent = f.name;
    actualizar();
  });

  // Archivo de capítulos (solo existe al crear): valida tipo y tamaño en el navegador.
  // El servidor repite la validación al leer el contenido.
  function limpiarCapitulos() {
    inCapitulos.value = '';
    capNombre.textContent = 'Subir PDF, DOCX o TXT';
    capAyuda.textContent = 'Hasta 20 MB. Los capítulos se detectan solos.';
    capQuitar.hidden = true;
  }
  if (inCapitulos) {
    inCapitulos.addEventListener('change', function () {
      var f = inCapitulos.files && inCapitulos.files[0];
      if (!f) { limpiarCapitulos(); return; }
      if (!/\.(pdf|docx|txt)$/i.test(f.name)) {
        alert('Formato no permitido. Sube un PDF, DOCX o TXT.');
        limpiarCapitulos(); return;
      }
      if (f.size > 20 * 1024 * 1024) {
        alert('El archivo supera el máximo de 20 MB.');
        limpiarCapitulos(); return;
      }
      capNombre.textContent = f.name;
      capAyuda.textContent = (f.size / 1024 / 1024 >= 1
        ? (f.size / 1024 / 1024).toFixed(1) + ' MB'
        : Math.max(1, Math.round(f.size / 1024)) + ' KB') + ' · listo para importar';
      capQuitar.hidden = false;
    });
    capQuitar.addEventListener('click', function (e) {
      e.preventDefault(); e.stopPropagation();
      limpiarCapitulos();
    });
  }

  form.addEventListener('input', actualizar);
  form.addEventListener('change', actualizar);
  actualizar();

  // Evita enviar dos veces el formulario
  form.addEventListener('submit', function () {
    var b = document.getElementById('btnGuardar');
    if (form.checkValidity()) {
      b.disabled = true; b.style.opacity = '.7';
      if (inCapitulos && inCapitulos.files && inCapitulos.files.length) { b.textContent = 'Importando capítulos…'; }
    }
  });
})();
</script>
</body>
</html>
