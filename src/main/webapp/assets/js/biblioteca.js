/* SAFIR · Mi biblioteca (enlazado desde WEB-INF/vistas/biblioteca/biblioteca.jsp) */
(function () {
  // Guarda el estado de lectura apenas se elige una opción
  Array.prototype.forEach.call(document.querySelectorAll('select[data-autoenviar]'), function (s) {
    s.addEventListener('change', function () { s.form.submit(); });
  });

  // Confirmación antes de quitar una obra de la biblioteca
  Array.prototype.forEach.call(document.querySelectorAll('form[data-confirmar]'), function (f) {
    f.addEventListener('submit', function (e) {
      if (!window.confirm(f.getAttribute('data-confirmar'))) e.preventDefault();
    });
  });

  // Filtros por estado / favoritas (sin recargar la página)
  var grid = document.getElementById('biGrid');
  if (!grid) return;
  var tarjetas = Array.prototype.slice.call(grid.querySelectorAll('.bi-card'));
  var botones = Array.prototype.slice.call(document.querySelectorAll('.bi-filtro'));
  var vacio = document.getElementById('biSinResultados');

  function coincide(t, filtro) {
    if (filtro === 'todas') return true;
    if (filtro === 'favoritas') return t.getAttribute('data-fav') === 'true';
    return t.getAttribute('data-estado') === filtro;
  }

  botones.forEach(function (b) {
    var filtro = b.getAttribute('data-filtro');
    b.querySelector('.bi-n').textContent = tarjetas.filter(function (t) { return coincide(t, filtro); }).length;
    b.addEventListener('click', function () {
      botones.forEach(function (x) {
        var activo = x === b;
        x.classList.toggle('activo', activo);
        x.setAttribute('aria-pressed', activo ? 'true' : 'false');
      });
      var visibles = 0;
      tarjetas.forEach(function (t) {
        var ok = coincide(t, filtro);
        t.hidden = !ok;
        if (ok) visibles++;
      });
      vacio.hidden = visibles !== 0;
    });
  });
})();