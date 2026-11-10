/* SAFIR · Editor de capítulo (enlazado desde WEB-INF/vistas/autor/editor.jsp) */
(function () {
  var form = document.getElementById('capForm');
  var titulo = document.getElementById('titulo');
  var contenido = document.getElementById('contenido');
  var tituloCont = document.getElementById('tituloCont');
  var palabrasCont = document.getElementById('palabrasCont');
  if (!form || !titulo || !contenido) return;

  // Contadores: caracteres del título y palabras del contenido
  function actualizar() {
    var n = titulo.value.length;
    tituloCont.textContent = n + ' / 150';
    tituloCont.classList.toggle('limite', n >= 150);
    var texto = contenido.value.trim();
    var p = texto === '' ? 0 : texto.split(/\s+/).length;
    palabrasCont.textContent = p.toLocaleString('es-PE') + (p === 1 ? ' palabra' : ' palabras');
  }
  titulo.addEventListener('input', actualizar);
  contenido.addEventListener('input', actualizar);
  actualizar();

  // Aviso al salir con cambios sin guardar
  var sucio = false, enviando = false;
  function marcar() { sucio = true; }
  titulo.addEventListener('input', marcar);
  contenido.addEventListener('input', marcar);
  form.addEventListener('submit', function () { enviando = true; });
  window.addEventListener('beforeunload', function (e) {
    if (sucio && !enviando) { e.preventDefault(); e.returnValue = ''; }
  });

  // Ctrl/⌘ + S guarda el borrador
  document.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && (e.key === 's' || e.key === 'S')) {
      e.preventDefault();
      if (form.reportValidity()) { enviando = true; form.submit(); }
    }
  });

  // Evita doble envío
  form.addEventListener('submit', function () {
    var b = document.getElementById('btnGuardar');
    if (b) { b.disabled = true; b.textContent = 'Guardando…'; }
  });

  // ---- Música del capítulo (YouTube o archivo de audio) ----
  var opciones = form.querySelectorAll('input[name="musicaOpcion"]');
  var paneles = form.querySelectorAll('.ce-musica-panel');
  var bucleFila = document.getElementById('bucleFila');
  var ytInput = document.getElementById('musicaYoutube');
  var ytVista = document.getElementById('ytVista');
  var ytAyuda = document.getElementById('ytAyuda');
  var archivo = document.getElementById('musicaArchivo');
  var audioVista = document.getElementById('audioVista');
  var audioAyuda = document.getElementById('audioAyuda');
  if (!opciones.length) return;

  var AYUDA_YT = ytAyuda ? ytAyuda.textContent : '';
  var AYUDA_AUDIO = audioAyuda ? audioAyuda.textContent : '';

  function opcionElegida() {
    for (var i = 0; i < opciones.length; i++) if (opciones[i].checked) return opciones[i].value;
    return 'ninguna';
  }

  function mostrarPanel() {
    var elegida = opcionElegida();
    for (var i = 0; i < paneles.length; i++) {
      paneles[i].hidden = paneles[i].getAttribute('data-panel') !== elegida;
    }
    if (bucleFila) bucleFila.hidden = elegida === 'ninguna';
  }
  for (var i = 0; i < opciones.length; i++) {
    opciones[i].addEventListener('change', function () { mostrarPanel(); marcar(); });
  }
  mostrarPanel();

  // Mismo criterio que AudioUtil.youtubeId en el servidor
  function idYoutube(texto) {
    texto = (texto || '').trim();
    if (!texto) return null;
    if (!/^https?:\/\//i.test(texto)) texto = 'https://' + texto;
    var u;
    try { u = new URL(texto); } catch (e) { return null; }
    var host = u.hostname.toLowerCase(), ruta = u.pathname, id = null;
    if (host === 'youtu.be' || host === 'www.youtu.be') {
      id = ruta.split('/')[1];
    } else if (/^(www\.|m\.|music\.)?youtube\.com$/.test(host) || /^(www\.)?youtube-nocookie\.com$/.test(host)) {
      if (ruta === '/watch') id = u.searchParams.get('v');
      else {
        var m = ruta.match(/^\/(shorts|embed|live|v)\/([^/]+)/);
        if (m) id = m[2];
      }
    }
    return id && /^[A-Za-z0-9_-]{11}$/.test(id) ? id : null;
  }

  var ultimoId = null, esperaYt = null;
  function vistaYoutube() {
    if (!ytInput || !ytVista) return;
    var texto = ytInput.value.trim();
    var id = idYoutube(texto);
    ytAyuda.classList.toggle('ce-error-texto', !!texto && !id);
    ytAyuda.textContent = !texto ? AYUDA_YT
      : id ? 'Enlace correcto. Prueba el video aquí abajo.'
      : 'Ese enlace no parece de un video de YouTube.';
    if (id === ultimoId) return;
    ultimoId = id;
    ytVista.innerHTML = '';
    ytVista.hidden = !id;
    if (id) {
      var f = document.createElement('iframe');
      f.src = 'https://www.youtube-nocookie.com/embed/' + id + '?rel=0';
      f.title = 'Vista previa de la música (YouTube)';
      f.allow = 'autoplay; encrypted-media; picture-in-picture';
      f.allowFullscreen = true;
      ytVista.appendChild(f);
    }
  }
  if (ytInput) {
    ytInput.addEventListener('input', function () {
      marcar();
      clearTimeout(esperaYt);
      esperaYt = setTimeout(vistaYoutube, 400);
    });
    vistaYoutube();
  }

  var urlAudio = null;
  function avisoAudio(texto, esError) {
    audioAyuda.textContent = texto;
    audioAyuda.classList.toggle('ce-error-texto', !!esError);
  }
  if (archivo) {
    archivo.addEventListener('change', function () {
      marcar();
      if (urlAudio) { URL.revokeObjectURL(urlAudio); urlAudio = null; }
      audioVista.hidden = true;
      audioVista.removeAttribute('src');
      var f = archivo.files && archivo.files[0];
      if (!f) { avisoAudio(AYUDA_AUDIO, false); return; }

      // Se revisa aquí para no perder el texto: si el archivo supera el máximo,
      // el servidor no llega a recibir el título ni el contenido.
      var max = Number(archivo.getAttribute('data-max-bytes')) || 20971520;
      if (f.size > max) {
        archivo.value = '';
        avisoAudio('El archivo pesa ' + (f.size / 1048576).toFixed(1)
          + ' MB y el máximo es ' + Math.round(max / 1048576) + ' MB. Elige uno más pequeño.', true);
        return;
      }
      if (!/\.(mp3|m4a|aac|ogg|wav)$/i.test(f.name)) {
        archivo.value = '';
        avisoAudio('Formato no permitido. Usa MP3, M4A, AAC, OGG o WAV.', true);
        return;
      }
      urlAudio = URL.createObjectURL(f);
      audioVista.src = urlAudio;
      audioVista.hidden = false;
      avisoAudio(f.name + ' · ' + (f.size / 1048576).toFixed(1) + ' MB. Escúchalo antes de guardar.', false);
    });
  }

  // Antes de enviar: el enlace o el archivo elegidos deben ser válidos.
  form.addEventListener('submit', function (e) {
    var elegida = opcionElegida(), campo = null;
    if (elegida === 'youtube' && !idYoutube(ytInput.value)) {
      vistaYoutube();
      if (!ytInput.value.trim()) {
        ytAyuda.textContent = 'Pega el enlace del video o elige otra opción.';
        ytAyuda.classList.add('ce-error-texto');
      }
      campo = ytInput;
    } else if (elegida === 'archivo' && !(archivo.files && archivo.files.length)) {
      avisoAudio('Elige un archivo de audio o selecciona otra opción.', true);
      campo = archivo;
    }
    if (campo) {
      e.preventDefault(); e.stopImmediatePropagation();
      enviando = false;
      campo.focus();
    }
  }, true);
})();