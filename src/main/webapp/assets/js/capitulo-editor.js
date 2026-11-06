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
})();