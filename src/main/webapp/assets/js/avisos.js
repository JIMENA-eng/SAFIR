/*
 * SAFIR · Iconos de mensajes y notificaciones del encabezado (TAREA 5)
 *
 * - Pide /notificaciones/resumen al cargar la página y cada minuto.
 * - Pone el número de no leídos en el punto rojo de cada icono (99+ como máximo).
 * - Al pasar el cursor (o enfocar con el teclado) muestra un desglose de
 *   las últimas notificaciones; al hacer clic lleva a la página de notificaciones.
 */
(function () {
  var wraps = Array.prototype.slice.call(document.querySelectorAll('.aviso-wrap[data-aviso]'));
  if (!wraps.length) return;

  var URL_RESUMEN = wraps[0].getAttribute('data-resumen-url');
  var CADA_MS = 60000;
  var tituloBase = document.title.replace(/^\(\d+\+?\)\s*/, '');
  var temporizador = null;

  var TEXTOS = {
    mensajes:  { uno: 'mensaje sin leer', varios: 'mensajes sin leer', ninguno: 'No tienes mensajes sin leer',
                 vacio: 'Aún no tienes mensajes.', nombre: 'Mensajes' },
    actividad: { uno: 'notificación sin leer', varios: 'notificaciones sin leer', ninguno: 'Estás al día',
                 vacio: 'Aún no tienes notificaciones.', nombre: 'Notificaciones' }
  };

  // ---------- Utilidades ----------
  function textoBadge(n) { return n > 99 ? '99+' : String(n); }

  function hace(iso) {
    if (!iso) return '';
    var d = new Date(iso.replace(/\.(\d+)$/, function (_, f) { return '.' + (f + '000').slice(0, 3); }));
    if (isNaN(d.getTime())) return '';
    var seg = Math.max(0, (Date.now() - d.getTime()) / 1000);
    if (seg < 60) return 'hace un momento';
    if (seg < 3600) return 'hace ' + Math.floor(seg / 60) + ' min';
    if (seg < 86400) return 'hace ' + Math.floor(seg / 3600) + ' h';
    if (seg < 172800) return 'ayer';
    return d.toLocaleDateString('es-PE', { day: 'numeric', month: 'short' });
  }

  function el(tag, clase, texto) {
    var e = document.createElement(tag);
    if (clase) e.className = clase;
    if (texto != null) e.textContent = texto;
    return e;
  }

  // ---------- Pintar un icono con sus datos ----------
  function pintar(wrap, datos) {
    var cat = wrap.getAttribute('data-aviso');
    var t = TEXTOS[cat];
    var n = (datos && datos.noLeidas) || 0;

    var badge = wrap.querySelector('[data-badge]');
    badge.textContent = textoBadge(n);
    badge.hidden = n === 0;

    var link = wrap.querySelector('.icon-btn');
    link.setAttribute('aria-label', t.nombre + (n ? ' (' + n + ' ' + (n === 1 ? t.uno : t.varios) + ')' : ''));

    var resumen = wrap.querySelector('[data-resumen]');
    resumen.textContent = n ? n + ' ' + (n === 1 ? t.uno : t.varios) : t.ninguno;

    var lista = wrap.querySelector('[data-lista]');
    lista.innerHTML = '';
    var items = (datos && datos.items) || [];
    if (!items.length) {
      lista.appendChild(el('li', 'aviso-vacio', t.vacio));
      return n;
    }
    items.forEach(function (it) {
      var li = el('li');
      var a = el('a', 'aviso-item' + (it.leida ? '' : ' nueva'));
      a.href = it.url;
      var cab = el('span', 'aviso-tipo', it.tipo);
      if (!it.leida) cab.appendChild(el('span', 'aviso-punto'));
      a.appendChild(cab);
      a.appendChild(el('span', 'aviso-msg', it.mensaje));
      a.appendChild(el('time', 'aviso-fecha', hace(it.creadoEn)));
      li.appendChild(a);
      lista.appendChild(li);
    });
    return n;
  }

  // ---------- Pedir datos al servidor ----------
  function actualizar() {
    if (!URL_RESUMEN || !window.fetch) return;
    fetch(URL_RESUMEN, { credentials: 'same-origin', headers: { 'Accept': 'application/json' } })
      .then(function (r) {
        if (r.status === 401) { detener(); return null; }   // sesión cerrada
        return r.ok ? r.json() : null;
      })
      .then(function (json) {
        if (!json) return;
        var total = 0;
        wraps.forEach(function (w) { total += pintar(w, json[w.getAttribute('data-aviso')]); });
        document.title = (total ? '(' + textoBadge(total) + ') ' : '') + tituloBase;
      })
      .catch(function () { /* sin conexión: se deja lo que había */ });
  }

  function iniciar() {
    detener();
    actualizar();
    temporizador = setInterval(actualizar, CADA_MS);
  }
  function detener() {
    if (temporizador) { clearInterval(temporizador); temporizador = null; }
  }

  document.addEventListener('visibilitychange', function () {
    if (document.hidden) detener(); else iniciar();
  });
  iniciar();

  // ---------- Desglose al pasar el cursor ----------
  wraps.forEach(function (wrap) {
    var pop = wrap.querySelector('.aviso-pop');
    var abrirT = null, cerrarT = null, silenciar = false;

    function mostrar() {
      clearTimeout(cerrarT);
      abrirT = setTimeout(function () {
        wraps.forEach(function (o) { if (o !== wrap) o.querySelector('.aviso-pop').hidden = true; });
        pop.hidden = false;
      }, 120);
    }
    function ocultar(inmediato) {
      clearTimeout(abrirT);
      cerrarT = setTimeout(function () { pop.hidden = true; }, inmediato ? 0 : 220);
    }

    wrap.addEventListener('mouseenter', mostrar);
    wrap.addEventListener('mouseleave', function () { ocultar(false); });
    wrap.addEventListener('focusin', function () {
      if (silenciar) { silenciar = false; return; }
      mostrar();
    });
    wrap.addEventListener('focusout', function (e) {
      if (!wrap.contains(e.relatedTarget)) ocultar(true);
    });
    wrap.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') { ocultar(true); silenciar = true; wrap.querySelector('.icon-btn').focus(); }
    });
  });
})();