/*
 * SAFIR · Selector de idioma (TAREA 4)
 *
 * Traduce TODA la página a cualquiera de los idiomas que soporta el
 * traductor de Google (más de 130). El idioma elegido se guarda en la
 * cookie "googtrans" (path=/), así que se aplica en todas las páginas
 * del sitio hasta que el usuario vuelva a "Español".
 *
 * - Si la página tiene el encabezado compartido (#langBtn / #langMenu),
 *   usa ese botón del globo.
 * - Si no lo tiene (login, catálogo, lector, errores...), crea un botón
 *   flotante 🌐 en la esquina inferior izquierda.
 *
 * Lo inyecta IdiomaFilter en todas las páginas HTML; no hace falta
 * agregarlo a mano en cada JSP.
 */
(function () {
  if (window.__safirIdioma) return;          // evita cargarlo dos veces
  window.__safirIdioma = true;

  var ORIGEN = 'es';                         // idioma en que está escrito SAFIR

  // Sugeridos primero (Puno: quechua y aimara), luego todos los demás.
  var SUGERIDOS = ['es', 'en', 'qu', 'ay', 'pt', 'fr', 'it', 'de', 'zh-CN', 'ja'];
  var TODOS = ['af','sq','am','ar','hy','as','ay','az','bm','eu','be','bn','bho','bs','bg',
    'ca','ceb','ny','zh-CN','zh-TW','co','hr','cs','da','dv','doi','nl','en','eo','et','ee',
    'tl','fi','fr','fy','gl','ka','de','el','gn','gu','ht','ha','haw','iw','hi','hmn','hu',
    'is','ig','ilo','id','ga','it','ja','jw','kn','kk','km','rw','gom','ko','kri','ku','ckb',
    'ky','lo','la','lv','ln','lt','lg','lb','mk','mai','mg','ms','ml','mt','mi','mr',
    'mni-Mtei','lus','mn','my','ne','no','or','om','ps','fa','pl','pt','pa','qu','ro','ru',
    'sm','sa','gd','nso','sr','st','sn','sd','si','sk','sl','so','es','su','sw','sv','tg',
    'ta','tt','te','th','ti','ts','tr','tk','ak','uk','ur','ug','uz','vi','cy','xh','yi',
    'yo','zu'];

  // Códigos de Google que no coinciden con el estándar (para obtener el nombre)
  var ALIAS = { 'iw': 'he', 'jw': 'jv', 'mni-Mtei': 'mni', 'zh-CN': 'zh-Hans', 'zh-TW': 'zh-Hant' };
  var NOMBRES_EXTRA = {
    'zh-CN': 'Chino (simplificado)', 'zh-TW': 'Chino (tradicional)', 'gom': 'Konkani',
    'doi': 'Dogri', 'kri': 'Krio', 'lus': 'Mizo', 'nso': 'Sepedi', 'ilo': 'Ilocano',
    'ckb': 'Kurdo (sorani)', 'bho': 'Bhojpuri', 'mni-Mtei': 'Meitei (manipuri)', 'hmn': 'Hmong',
    'haw': 'Hawaiano', 'ceb': 'Cebuano', 'qu': 'Quechua', 'ay': 'Aimara', 'gn': 'Guaraní'
  };

  var enEs = null, nativo = {};
  try { enEs = new Intl.DisplayNames(['es'], { type: 'language' }); } catch (e) {}

  function nombreEs(c) {
    if (NOMBRES_EXTRA[c]) return NOMBRES_EXTRA[c];
    try {
      var n = enEs && enEs.of(ALIAS[c] || c);
      if (n && n.toLowerCase() !== (ALIAS[c] || c).toLowerCase()) {
        return n.charAt(0).toUpperCase() + n.slice(1);
      }
    } catch (e) {}
    return c;
  }
  function nombreNativo(c) {
    var cod = ALIAS[c] || c;
    try {
      if (!nativo[c]) nativo[c] = new Intl.DisplayNames([cod], { type: 'language' }).of(cod) || '';
    } catch (e) { nativo[c] = ''; }
    var n = nativo[c];
    return n ? n.charAt(0).toUpperCase() + n.slice(1) : '';
  }
  function sinTildes(t) {
    return (t || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  }

  // ---------- Cookie "googtrans" (la lee el traductor de Google) ----------
  function idiomaActual() {
    var m = document.cookie.match(/(?:^|;\s*)googtrans=([^;]+)/);
    if (!m) return ORIGEN;
    var partes = decodeURIComponent(m[1]).split('/');   // "/es/en"
    return partes[2] || ORIGEN;
  }
  function borrarCookie() {
    var exp = '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
    var host = location.hostname;
    document.cookie = 'googtrans' + exp;
    document.cookie = 'googtrans' + exp + '; domain=' + host;
    document.cookie = 'googtrans' + exp + '; domain=.' + host;
  }
  function elegir(codigo) {
    try { localStorage.setItem('safir-lang', codigo); } catch (e) {}
    borrarCookie();
    if (codigo !== ORIGEN) {
      document.cookie = 'googtrans=/' + ORIGEN + '/' + codigo + '; path=/; max-age=31536000; SameSite=Lax';
    }
    location.reload();                       // el traductor se aplica al cargar
  }

  // ---------- Estilos (ocultan la barra de Google y dan forma al panel) ----------
  var css = [
    'iframe.goog-te-banner-frame,.goog-te-banner-frame,.skiptranslate>iframe,#goog-gt-tt,',
    '.goog-te-balloon-frame,.goog-tooltip,.VIpgJd-ZVi9od-ORHb-OEVmcd,.VIpgJd-ZVi9od-aZ2wEe-wOHMyf',
    '{display:none!important}',
    'body{top:0!important}',
    '.goog-text-highlight{background:none!important;box-shadow:none!important}',
    '#google_translate_element{display:none!important}',
    '.sf-lang-panel{width:min(300px,86vw);padding:.6rem!important}',
    '.sf-lang-search{width:100%;box-sizing:border-box;padding:.6rem .75rem;margin-bottom:.45rem;border-radius:10px;',
    'border:1.5px solid var(--line,#E3E0F7);background:var(--surface,#fff);color:var(--text,#292936);font:inherit;font-size:.95rem}',
    '.sf-lang-search:focus{outline:none;border-color:var(--lav,#7775D6)}',
    '.sf-lang-list{max-height:min(55vh,360px);overflow-y:auto;display:grid;gap:2px}',
    '.sf-lang-tit{font-size:.75rem;letter-spacing:.06em;text-transform:uppercase;color:var(--muted,#77758d);padding:.5rem .6rem .2rem}',
    '.sf-lang-item{display:flex;justify-content:space-between;align-items:baseline;gap:.8rem;width:100%;text-align:left;',
    'padding:.55rem .65rem;border:0;border-radius:9px;background:transparent;color:var(--text,#292936);font:inherit;font-size:.95rem;cursor:pointer}',
    '.sf-lang-item small{color:var(--muted,#77758d);font-size:.8rem}',
    '.sf-lang-item:hover,.sf-lang-item:focus-visible{background:var(--soft,#eeeaff);outline:none}',
    '.sf-lang-item[aria-checked="true"]{font-weight:600;color:var(--title,#292866)}',
    '.sf-lang-item[aria-checked="true"]::after{content:"\\2713"}',
    '.sf-lang-vacio{padding:.6rem;color:var(--muted,#77758d);font-size:.9rem}',
    '.sf-lang-flot{position:fixed;left:14px;bottom:14px;z-index:9999;font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}',
    '.sf-lang-flot>button{width:46px;height:46px;border-radius:50%;border:1px solid #E3E0F7;background:#fff;color:#292866;',
    'box-shadow:0 8px 24px -8px rgba(41,40,102,.45);display:grid;place-items:center;cursor:pointer}',
    '.sf-lang-flot>button svg{width:22px;height:22px}',
    '.sf-lang-flot .sf-lang-panel{position:absolute;left:0;bottom:56px;background:#fff;color:#292936;border:1px solid #E3E0F7;',
    'border-radius:16px;box-shadow:0 24px 50px -18px rgba(18,20,46,.5)}',
    '.sf-lang-flot .sf-lang-panel[hidden]{display:none}',
    ':root[data-theme="dark"] .sf-lang-flot>button,:root[data-theme="dark"] .sf-lang-flot .sf-lang-panel{background:#1D2042;color:#F1F0FF;border-color:#2C3060}'
  ].join('');
  var estilo = document.createElement('style');
  estilo.textContent = css;
  document.head.appendChild(estilo);

  // ---------- Botón y panel ----------
  var GLOBO = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" ' +
              'stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18"/>' +
              '<path d="M12 3c2.8 3 2.8 15 0 18M12 3c-2.8 3-2.8 15 0 18"/></svg>';

  var btn = document.getElementById('langBtn');
  var panel = document.getElementById('langMenu');

  if (!btn || !panel) {                      // página sin encabezado: botón flotante
    var flot = document.createElement('div');
    flot.className = 'sf-lang-flot notranslate';
    flot.innerHTML = '<button type="button" id="langBtn" aria-haspopup="true" aria-expanded="false" ' +
                     'aria-controls="langMenu" aria-label="Idioma" title="Idioma">' + GLOBO + '</button>' +
                     '<div id="langMenu" hidden></div>';
    document.body.appendChild(flot);
    btn = flot.querySelector('#langBtn');
    panel = flot.querySelector('#langMenu');
  }

  var actual = idiomaActual();
  panel.classList.add('sf-lang-panel', 'notranslate');   // la lista NO se traduce
  panel.setAttribute('role', 'dialog');
  panel.setAttribute('aria-label', 'Elegir idioma');
  panel.innerHTML = '<input class="sf-lang-search" type="search" placeholder="Buscar idioma\u2026" ' +
                    'aria-label="Buscar idioma" autocomplete="off">' +
                    '<div class="sf-lang-list" role="listbox" aria-label="Idiomas"></div>';
  var buscador = panel.querySelector('.sf-lang-search');
  var lista = panel.querySelector('.sf-lang-list');

  function item(c) {
    var b = document.createElement('button');
    b.type = 'button';
    b.className = 'sf-lang-item';
    b.setAttribute('role', 'option');
    b.setAttribute('aria-checked', c === actual ? 'true' : 'false');
    b.setAttribute('lang', ALIAS[c] || c);
    var es = nombreEs(c), nat = nombreNativo(c);
    b.innerHTML = '<span></span>' + (nat && sinTildes(nat) !== sinTildes(es) ? '<small></small>' : '');
    b.firstChild.textContent = es;
    if (b.childNodes[1]) b.childNodes[1].textContent = nat;
    b.dataset.buscar = sinTildes(es + ' ' + nat + ' ' + c);
    b.addEventListener('click', function () {
      if (c === actual) { abrir(false); return; }
      elegir(c);
    });
    return b;
  }
  function titulo(t) {
    var d = document.createElement('div');
    d.className = 'sf-lang-tit';
    d.textContent = t;
    return d;
  }

  var resto = TODOS.filter(function (c) { return SUGERIDOS.indexOf(c) < 0; })
                   .sort(function (a, b) { return nombreEs(a).localeCompare(nombreEs(b), 'es'); });

  function pintar(filtro) {
    var f = sinTildes(filtro).trim();
    lista.innerHTML = '';
    if (!f) {
      lista.appendChild(titulo('Sugeridos'));
      SUGERIDOS.forEach(function (c) { lista.appendChild(item(c)); });
      lista.appendChild(titulo('Todos los idiomas'));
      resto.forEach(function (c) { lista.appendChild(item(c)); });
      return;
    }
    var n = 0;
    SUGERIDOS.concat(resto).forEach(function (c) {
      var it = item(c);
      if (it.dataset.buscar.indexOf(f) >= 0) { lista.appendChild(it); n++; }
    });
    if (!n) {
      var v = document.createElement('p');
      v.className = 'sf-lang-vacio';
      v.textContent = 'No encontramos ese idioma.';
      lista.appendChild(v);
    }
  }
  pintar('');
  buscador.addEventListener('input', function () { pintar(buscador.value); });

  function abrir(si) {
    panel.hidden = !si;
    btn.setAttribute('aria-expanded', si ? 'true' : 'false');
    if (si) {
      buscador.value = '';
      pintar('');
      setTimeout(function () { buscador.focus(); }, 0);
    }
  }
  btn.addEventListener('click', function () { abrir(panel.hidden); });
  // Fase de captura: cierra aunque otros menús detengan la propagación del clic.
  document.addEventListener('click', function (e) {
    if (!panel.hidden && !panel.contains(e.target) && !btn.contains(e.target)) abrir(false);
  }, true);
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !panel.hidden) { abrir(false); btn.focus(); }
  });
  // Enter en el buscador elige el primer resultado
  buscador.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') {
      e.preventDefault();
      var primero = lista.querySelector('.sf-lang-item');
      if (primero) primero.click();
    }
  });

  // ---------- Traductor de Google (solo si se eligió otro idioma) ----------
  if (actual !== ORIGEN) {
    var cont = document.createElement('div');
    cont.id = 'google_translate_element';
    document.body.appendChild(cont);
    window.safirIniciarTraductor = function () {
      /* global google */
      new google.translate.TranslateElement({ pageLanguage: ORIGEN, autoDisplay: false },
                                            'google_translate_element');
    };
    var s = document.createElement('script');
    s.src = 'https://translate.google.com/translate_a/element.js?cb=safirIniciarTraductor';
    s.async = true;
    document.body.appendChild(s);
  }
})();