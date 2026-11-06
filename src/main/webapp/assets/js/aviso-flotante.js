/* SAFIR · Aviso flotante de "guardado" (enlazado desde autor/obra-formulario.jsp) */
(function () {
  var aviso = document.getElementById('avisoGuardado');
  if (!aviso) return;

  // Quita ?guardado=1 / ?publicado=1 de la barra de direcciones: al recargar no vuelve a salir
  try {
    var url = new URL(window.location.href);
    if (url.searchParams.has('guardado') || url.searchParams.has('publicado') || url.searchParams.has('obraPublicada')) {
      url.searchParams.delete('guardado');
      url.searchParams.delete('publicado');
      url.searchParams.delete('obraPublicada');
      window.history.replaceState(null, '', url.pathname + url.search + url.hash);
    }
  } catch (e) {}

  // Se oculta solo a los 4 segundos
  setTimeout(function () {
    aviso.classList.add('oculto');
    setTimeout(function () { aviso.remove(); }, 400);
  }, 4000);
})();