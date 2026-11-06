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
})();