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

  // Filtros: categoría (todo / mensajes / notificaciones) + estado (todas / sin leer / leídas)
  var tarjetas = Array.prototype.slice.call(lista.querySelectorAll('.nt-card'));
  var botones = Array.prototype.slice.call(document.querySelectorAll('.nt-filtro'));
  var pestanas = Array.prototype.slice.call(document.querySelectorAll('.nt-tab'));
  var vacio = document.getElementById('ntSinResultados');

  var ver = lista.getAttribute('data-ver');
  var categoria = (ver === 'mensajes' || ver === 'actividad') ? ver : 'todas';
  var estado = 'todas';

  function enCategoria(t, c) {
    return c === 'todas' || t.getAttribute('data-categoria') === c;
  }
  function enEstado(t, e) {
    if (e === 'todas') return true;
    var leida = t.getAttribute('data-leida') === 'true';
    return e === 'leidas' ? leida : !leida;
  }
  function marcar(grupo, activo) {
    grupo.forEach(function (x) {
      var si = x === activo;
      x.classList.toggle('activo', si);
      x.setAttribute('aria-pressed', si ? 'true' : 'false');
    });
  }
  function aplicar() {
    var visibles = 0;
    tarjetas.forEach(function (t) {
      var ok = enCategoria(t, categoria) && enEstado(t, estado);
      t.hidden = !ok;
      if (ok) visibles++;
    });
    vacio.hidden = visibles !== 0;
    // Los contadores de estado dependen de la categoría elegida
    botones.forEach(function (b) {
      var f = b.getAttribute('data-filtro');
      b.querySelector('.nt-n').textContent = tarjetas.filter(function (t) {
        return enCategoria(t, categoria) && enEstado(t, f);
      }).length;
    });
  }

  pestanas.forEach(function (p) {
    var c = p.getAttribute('data-categoria');
    var sinLeer = tarjetas.filter(function (t) {
      return enCategoria(t, c) && t.getAttribute('data-leida') !== 'true';
    }).length;
    var globo = p.querySelector('.nt-n');
    globo.textContent = sinLeer;
    globo.hidden = sinLeer === 0;            // sin globo rojo si no hay nada sin leer
    p.title = 'Sin leer';
    if (c === categoria) marcar(pestanas, p);
    p.addEventListener('click', function () {
      categoria = c;
      marcar(pestanas, p);
      if (history.replaceState) {
        history.replaceState(null, '', c === 'todas' ? location.pathname : location.pathname + '?ver=' + c);
      }
      aplicar();
    });
  });

  botones.forEach(function (b) {
    b.addEventListener('click', function () {
      estado = b.getAttribute('data-filtro');
      marcar(botones, b);
      aplicar();
    });
  });

  aplicar();

  // Si se llegó desde el desglose del encabezado (#notif-ID), resaltar esa notificación
  if (location.hash && /^#notif-\d+$/.test(location.hash)) {
    var destino = document.getElementById(location.hash.slice(1));
    if (destino) {
      if (destino.hidden) {               // por si el filtro la ocultaba
        categoria = 'todas'; estado = 'todas';
        marcar(pestanas, pestanas[0]); marcar(botones, botones[0]);
        aplicar();
      }
      destino.classList.add('destacada');
      destino.scrollIntoView({ block: 'center', behavior: 'smooth' });
      setTimeout(function () { destino.classList.remove('destacada'); }, 2600);
    }
  }
})();