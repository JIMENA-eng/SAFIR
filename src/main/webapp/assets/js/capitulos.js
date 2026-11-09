/* SAFIR · Gestión de capítulos (enlazado desde WEB-INF/vistas/autor/capitulos.jsp) */
(function () {
  // Pide confirmación antes de publicar (un capítulo publicado ya no se puede editar)
  Array.prototype.forEach.call(document.querySelectorAll('form[data-confirmar]'), function (f) {
    f.addEventListener('submit', function (e) {
      if (!window.confirm(f.getAttribute('data-confirmar'))) { e.preventDefault(); return; }
      var b = f.querySelector('button[type="submit"]');
      if (b) { b.disabled = true; b.textContent = 'Publicando…'; }
    });
  });

  // Importar capítulos desde un archivo: valida tipo y tamaño y envía al elegirlo.
  // El servidor repite la validación al leer el contenido.
  var form = document.getElementById('importarForm');
  var input = document.getElementById('importarInput');
  if (form && input) {
    var nombre = document.getElementById('importarNombre');
    var ayuda = document.getElementById('importarAyuda');
    var elegir = document.getElementById('importarElegir');
    var enviar = document.getElementById('importarEnviar');
    var textoInicial = nombre.textContent;
    var ayudaInicial = ayuda.textContent;

    function reiniciar() {
      input.value = '';
      nombre.textContent = textoInicial;
      ayuda.textContent = ayudaInicial;
      elegir.hidden = false;
      enviar.hidden = true;
    }

    input.addEventListener('change', function () {
      var f = input.files && input.files[0];
      if (!f) { reiniciar(); return; }
      if (!/\.(pdf|docx|doc|txt)$/i.test(f.name)) {
        window.alert('Formato no permitido. Sube un PDF, DOCX, DOC o TXT.');
        reiniciar(); return;
      }
      if (f.size > 20 * 1024 * 1024) {
        window.alert('El archivo supera el máximo de 20 MB.');
        reiniciar(); return;
      }
      nombre.textContent = f.name;
      ayuda.textContent = 'Antes de publicarlos podrás revisar los capítulos detectados.';
      elegir.textContent = 'Cambiar';
      enviar.hidden = false;
    });

    form.addEventListener('submit', function () {
      enviar.disabled = true;
      enviar.textContent = 'Importando…';
    });
  }
})();