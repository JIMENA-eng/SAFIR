/* SAFIR · Aviso flotante de "guardado" (enlazado desde autor/obra-formulario.jsp) */
(function () {
  var aviso = document.getElementById('avisoGuardado');
  if (!aviso) return;

  // Quita los parámetros del aviso de la barra de direcciones: al recargar no vuelve a salir
  try {
    var url = new URL(window.location.href);
    var params = ['guardado', 'publicado', 'obraPublicada', 'importados', 'importacionRechazada'];
    var hay = false;
    params.forEach(function (n) {
      if (url.searchParams.has(n)) { url.searchParams.delete(n); hay = true; }
    });
    if (hay) {
      window.history.replaceState(null, '', url.pathname + url.search + url.hash);
    }
  } catch (e) {}

  // Se oculta solo a los 6 segundos
  setTimeout(function () {
    aviso.classList.add('oculto');
    setTimeout(function () { aviso.remove(); }, 400);
  }, 6000);
})();