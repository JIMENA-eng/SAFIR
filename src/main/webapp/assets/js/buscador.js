/*
 * SAFIR · Sugerencias del buscador del encabezado (TAREA 7)
 *
 * Mientras el usuario escribe (desde 1 letra) muestra un desglose con:
 *   - Obras cuyo título (o género / etiqueta) coincide con lo escrito.
 *   - Autores cuyo nombre o @usuario coincide con lo escrito.
 * Se navega con ↑ ↓, Enter abre la opción marcada y Esc cierra.
 * Sin opción marcada, Enter busca normalmente en el catálogo.
 */
(function () {
  var form = document.getElementById('hdrSearchForm');
  var input = document.getElementById('hdrSearchInput');
  if (!form || !input || !window.fetch) return;

  var URL_SUG = form.getAttribute('data-sugerencias-url');
  var CTX = form.getAttribute('data-contexto') || '';
  var ESPERA_MS = 180;          // espera tras cada tecla antes de consultar
  var cache = {};
  var temporizador = null;
  var peticion = null;          // AbortController de la consulta en curso
  var activo = -1;              // índice de la opción marcada con el teclado

  // ---------- Panel ----------
  var panel = document.createElement('div');
  panel.className = 'sug-panel';
  panel.id = 'hdrSugerencias';
  panel.setAttribute('role', 'listbox');
  panel.setAttribute('aria-label', 'Sugerencias de búsqueda');
  panel.hidden = true;
  form.appendChild(panel);

  input.setAttribute('role', 'combobox');
  input.setAttribute('aria-autocomplete', 'list');
  input.setAttribute('aria-expanded', 'false');
  input.setAttribute('aria-controls', panel.id);

  function abrir(si) {
    panel.hidden = !si;
    input.setAttribute('aria-expanded', si ? 'true' : 'false');
    if (!si) marcar(-1);
  }

  function opciones() {
    return Array.prototype.slice.call(panel.querySelectorAll('.sug-op'));
  }

  function marcar(i) {
    var ops = opciones();
    activo = i;
    ops.forEach(function (o, k) {
      var si = k === i;
      o.classList.toggle('activa', si);
      o.setAttribute('aria-selected', si ? 'true' : 'false');
      if (si) {
        input.setAttribute('aria-activedescendant', o.id);
        o.scrollIntoView({ block: 'nearest' });
      }
    });
    if (i < 0) input.removeAttribute('aria-activedescendant');
  }

  // ---------- Utilidades ----------
  function sinTildes(t) {
    return (t || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  }

  /** Escribe el texto y resalta con <mark> la parte que coincide con lo buscado. */
  function resaltar(el, texto, q) {
    texto = texto || '';
    var base = sinTildes(texto), buscado = sinTildes(q).trim();
    var i = buscado ? base.indexOf(buscado) : -1;
    if (i < 0) { el.textContent = texto; return; }
    el.appendChild(document.createTextNode(texto.slice(0, i)));
    var m = document.createElement('mark');
    m.textContent = texto.slice(i, i + buscado.length);
    el.appendChild(m);
    el.appendChild(document.createTextNode(texto.slice(i + buscado.length)));
  }

  function el(tag, clase, texto) {
    var e = document.createElement(tag);
    if (clase) e.className = clase;
    if (texto != null) e.textContent = texto;
    return e;
  }

  var n = 0;
  function opcion(href, clase) {
    var a = el('a', 'sug-op ' + clase);
    a.href = href;
    a.id = 'sug-' + (n++);
    a.setAttribute('role', 'option');
    a.setAttribute('aria-selected', 'false');
    a.tabIndex = -1;
    return a;
  }

  function miniatura(ruta, letra, redonda) {
    var s = el('span', 'sug-img' + (redonda ? ' redonda' : ''));
    if (ruta) {
      var img = document.createElement('img');
      img.src = CTX + '/media/' + ruta;
      img.alt = '';
      img.loading = 'lazy';
      s.appendChild(img);
    } else {
      s.textContent = letra;
    }
    return s;
  }

  function buscarEnCatalogo(q) {
    return CTX + '/catalogo?q=' + encodeURIComponent(q);
  }

  // ---------- Pintar resultados ----------
  function pintar(q, datos) {
    panel.innerHTML = '';
    activo = -1;
    var obras = (datos && datos.obras) || [];
    var autores = (datos && datos.autores) || [];

    if (obras.length) {
      panel.appendChild(el('div', 'sug-tit', 'Obras'));
      obras.forEach(function (o) {
        var a = opcion(CTX + '/obra?id=' + o.id, 'obra');
        a.appendChild(miniatura(o.portada, '\u2726', false));
        var txt = el('span', 'sug-txt');
        var t = el('b'); resaltar(t, o.titulo, q); txt.appendChild(t);
        txt.appendChild(el('small', null, 'Por ' + (o.autor || '\u2014') + (o.genero ? ' \u00b7 ' + o.genero : '')));
        a.appendChild(txt);
        panel.appendChild(a);
      });
    }

    if (autores.length) {
      panel.appendChild(el('div', 'sug-tit', 'Autores'));
      autores.forEach(function (u) {
        // Lleva al catálogo filtrado por su nombre: ahí salen todas sus obras.
        var a = opcion(buscarEnCatalogo(u.nombre), 'autor');
        a.appendChild(miniatura(u.avatar, (u.nombre || '?').charAt(0).toUpperCase(), true));
        var txt = el('span', 'sug-txt');
        var t = el('b'); resaltar(t, u.nombre, q); txt.appendChild(t);
        var det = (u.usuario ? '@' + u.usuario + ' \u00b7 ' : '') +
                  u.obras + (u.obras === 1 ? ' obra publicada' : ' obras publicadas');
        txt.appendChild(el('small', null, det));
        a.appendChild(txt);
        panel.appendChild(a);
      });
    }

    if (!obras.length && !autores.length) {
      panel.appendChild(el('p', 'sug-vacio', 'No encontramos obras ni autores con \u00ab' + q + '\u00bb.'));
    }

    // Siempre: buscar en todo el catálogo
    var todo = opcion(buscarEnCatalogo(q), 'todo');
    todo.appendChild(el('span', 'sug-lupa', '\u2315'));
    var tt = el('span', 'sug-txt');
    tt.appendChild(el('b', null, 'Ver todos los resultados para \u00ab' + q + '\u00bb'));
    todo.appendChild(tt);
    panel.appendChild(todo);

    abrir(true);
  }

  // ---------- Consultar ----------
  function consultar() {
    var q = input.value.trim();
    if (!q) { abrir(false); return; }
    var clave = sinTildes(q);
    if (cache[clave]) { pintar(q, cache[clave]); return; }

    if (peticion && peticion.abort) peticion.abort();
    peticion = window.AbortController ? new AbortController() : null;

    fetch(URL_SUG + '?q=' + encodeURIComponent(q), {
      credentials: 'same-origin',
      headers: { 'Accept': 'application/json' },
      signal: peticion ? peticion.signal : undefined
    })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (json) {
        if (!json) return;
        cache[clave] = json;
        if (input.value.trim() === q) pintar(q, json);   // ignora respuestas viejas
      })
      .catch(function () { /* cancelada o sin conexión: no se muestra nada */ });
  }

  input.addEventListener('input', function () {
    clearTimeout(temporizador);
    if (!input.value.trim()) { abrir(false); return; }
    temporizador = setTimeout(consultar, ESPERA_MS);
  });

  input.addEventListener('focus', function () {
    if (input.value.trim()) consultar();
  });

  // ---------- Teclado ----------
  input.addEventListener('keydown', function (e) {
    var ops = opciones();
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (panel.hidden) { consultar(); return; }
      marcar(activo + 1 >= ops.length ? 0 : activo + 1);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (!panel.hidden) marcar(activo <= 0 ? ops.length - 1 : activo - 1);
    } else if (e.key === 'Enter') {
      if (!panel.hidden && activo >= 0 && ops[activo]) {
        e.preventDefault();
        window.location.href = ops[activo].href;
      }
      // sin opción marcada: el formulario busca en el catálogo como siempre
    } else if (e.key === 'Escape') {
      if (!panel.hidden) { e.preventDefault(); abrir(false); }
    }
  });

  // Que el clic en una opción no quite el foco antes de navegar
  panel.addEventListener('mousedown', function (e) { e.preventDefault(); });
  panel.addEventListener('mousemove', function (e) {
    var op = e.target.closest ? e.target.closest('.sug-op') : null;
    if (op) marcar(opciones().indexOf(op));
  });

  // Cerrar al hacer clic fuera
  document.addEventListener('click', function (e) {
    if (!panel.hidden && !form.contains(e.target)) abrir(false);
  });
  input.addEventListener('blur', function () {
    setTimeout(function () { if (document.activeElement !== input) abrir(false); }, 150);
  });
})();