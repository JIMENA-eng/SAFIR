/* SAFIR · Inicio: modo noche, buscador, menú de usuario e idioma (enlazado desde inicio.jsp) */
(function () {
  // Modo noche
  var root = document.documentElement;
  var themeBtn = document.getElementById('themeBtn');
  function setTheme(t) {
    if (t === 'dark') root.setAttribute('data-theme', 'dark'); else root.removeAttribute('data-theme');
    themeBtn.setAttribute('aria-pressed', t === 'dark' ? 'true' : 'false');
    themeBtn.textContent = t === 'dark' ? 'Modo claro' : 'Modo noche';
    try { localStorage.setItem('safir-theme', t); } catch (e) {}
  }
  var saved = null;
  try { saved = localStorage.getItem('safir-theme'); } catch (e) {}
  setTheme(saved === 'dark' ? 'dark' : 'light');
  themeBtn.addEventListener('click', function () {
    setTheme(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
  });

  // Buscador: evita enviar una búsqueda vacía al catálogo
  var form = document.getElementById('searchForm');
  var input = document.getElementById('searchInput');
  if (form && input) {
    form.addEventListener('submit', function (e) {
      if (input.value.trim() === '') { e.preventDefault(); input.focus(); }
    });
  }

  // Menú de usuario
  var menuBtn = document.getElementById('userMenuBtn');
  var menu = document.getElementById('userMenu');
  function setMenu(open) {
    menu.hidden = !open;
    menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  menuBtn.addEventListener('click', function (e) { e.stopPropagation(); setMenu(menu.hidden); });
  document.addEventListener('click', function (e) {
    if (!menu.hidden && !menu.contains(e.target)) setMenu(false);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !menu.hidden) { setMenu(false); menuBtn.focus(); }
  });
  // Menú de idioma (de momento solo guarda la preferencia; falta traducir los textos)
  var langBtn = document.getElementById('langBtn');
  var langMenu = document.getElementById('langMenu');
  function setLangMenu(open) {
    langMenu.hidden = !open;
    langBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  function marcarIdioma(l) {
    Array.prototype.forEach.call(langMenu.querySelectorAll('[data-lang]'), function (b) {
      b.setAttribute('aria-checked', b.getAttribute('data-lang') === l ? 'true' : 'false');
    });
  }
  var langGuardado = 'es';
  try { langGuardado = localStorage.getItem('safir-lang') || 'es'; } catch (e) {}
  marcarIdioma(langGuardado);
  langBtn.addEventListener('click', function (e) { e.stopPropagation(); setMenu(false); setLangMenu(langMenu.hidden); });
  Array.prototype.forEach.call(langMenu.querySelectorAll('[data-lang]'), function (b) {
    b.addEventListener('click', function () {
      var l = b.getAttribute('data-lang');
      try { localStorage.setItem('safir-lang', l); } catch (e) {}
      marcarIdioma(l);
      setLangMenu(false);
    });
  });
  document.addEventListener('click', function (e) {
    if (!langMenu.hidden && !langMenu.contains(e.target)) setLangMenu(false);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !langMenu.hidden) { setLangMenu(false); langBtn.focus(); }
  });
  menuBtn.addEventListener('click', function () { setLangMenu(false); });
  var msgBtn = document.querySelector('.icon-btn[data-pendiente]');
  if (msgBtn) msgBtn.addEventListener('click', function (e) { e.preventDefault(); });

  // TAREA 3: desglose de categorías del botón "Catálogo"
  var catBtn = document.getElementById('catBtn');
  var catMenu = document.getElementById('catMenu');
  function setCatMenu(open) {
    if (!catMenu) return;
    catMenu.hidden = !open;
    catBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  if (catBtn && catMenu) {
    catBtn.addEventListener('click', function (e) {
      e.stopPropagation();
      setMenu(false);
      setLangMenu(false);
      setCatMenu(catMenu.hidden);
    });
    document.addEventListener('click', function (e) {
      if (!catMenu.hidden && !catMenu.contains(e.target)) setCatMenu(false);
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && !catMenu.hidden) { setCatMenu(false); catBtn.focus(); }
    });
    menuBtn.addEventListener('click', function () { setCatMenu(false); });
    langBtn.addEventListener('click', function () { setCatMenu(false); });
  }

  Array.prototype.forEach.call(menu.querySelectorAll('a'), function (a) {
    a.addEventListener('click', function (e) {
      if (a.hasAttribute('data-pendiente')) e.preventDefault();
      setMenu(false);
    });
  });
})();