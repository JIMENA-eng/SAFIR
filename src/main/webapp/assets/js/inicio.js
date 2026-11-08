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

  // TAREA 6: buscador del encabezado (no existe en el inicio). Tampoco envía búsquedas vacías.
  var hdrForm = document.getElementById('hdrSearchForm');
  var hdrInput = document.getElementById('hdrSearchInput');
  if (hdrForm && hdrInput) {
    hdrForm.addEventListener('submit', function (e) {
      if (hdrInput.value.trim() === '') { e.preventDefault(); hdrInput.focus(); }
    });
    // Atajo: "/" enfoca el buscador (si no se está escribiendo en otro campo)
    document.addEventListener('keydown', function (e) {
      var t = e.target, escribiendo = t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName));
      if (e.key === '/' && !escribiendo && !e.ctrlKey && !e.metaKey && !e.altKey) {
        e.preventDefault();
        hdrInput.focus();
      }
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
  // El menú de idioma lo maneja /assets/js/idioma.js (TAREA 4).
  // Mensajes y notificaciones: los maneja /assets/js/avisos.js (TAREA 5).

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
      setCatMenu(catMenu.hidden);
    });
    document.addEventListener('click', function (e) {
      if (!catMenu.hidden && !catMenu.contains(e.target)) setCatMenu(false);
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && !catMenu.hidden) { setCatMenu(false); catBtn.focus(); }
    });
    menuBtn.addEventListener('click', function () { setCatMenu(false); });
  }

  Array.prototype.forEach.call(menu.querySelectorAll('a'), function (a) {
    a.addEventListener('click', function (e) {
      if (a.hasAttribute('data-pendiente')) e.preventDefault();
      setMenu(false);
    });
  });
})();