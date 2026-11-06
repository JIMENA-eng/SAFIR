/* SAFIR · Notificaciones (enlazado desde WEB-INF/vistas/notificaciones/notificaciones.jsp) */
(function () {
  var lista = document.getElementById('ntLista');
  if (!lista) return;

  // Fechas legibles ("hace 5 min", "ayer", ...). Si algo falla, queda el texto del servidor.
  function normalizar(iso) {
    return iso.replace(/\.(\d+)$/, function (_, f) { return '.' + (f + '000').slice(0, 3); });
  }
  function textoFecha(d) {
    var seg = Math.max(0, (Date.now() - d.getTime()) / 1000);
    if (seg < 60) return 'hace un momento';
    if (seg < 3600) return 'hace ' + Math.floor(seg / 60) + ' min';
    if (seg < 86400) return 'hace ' + Math.floor(seg / 3600) + ' h';
    if (seg < 172800) return 'ayer';
    return d.toLocaleDateString('es-PE', { day: 'numeric', month: 'short', year: 'numeric' });
  }
  Array.prototype.forEach.call(lista.querySelectorAll('time[data-fecha]'), function (t) {
    var iso = t.getAttribute('datetime');
    if (!iso) return;
    var d = new Date(normalizar(iso));
    if (isNaN(d.getTime())) return;
    t.textContent = textoFecha(d);
    t.title = d.toLocaleString('es-PE');
  });

  // Filtros (todas / sin leer / leídas) sin recargar la página
  var tarjetas = Array.prototype.slice.call(lista.querySelectorAll('.nt-card'));
  var botones = Array.prototype.slice.call(document.querySelectorAll('.nt-filtro'));
  var vacio = document.getElementById('ntSinResultados');

  function coincide(t, filtro) {
    if (filtro === 'todas') return true;
    var leida = t.getAttribute('data-leida') === 'true';
    return filtro === 'leidas' ? leida : !leida;
  }

  botones.forEach(function (b) {
    var filtro = b.getAttribute('data-filtro');
    b.querySelector('.nt-n').textContent = tarjetas.filter(function (t) { return coincide(t, filtro); }).length;
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