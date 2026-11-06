/* SAFIR · Mi billetera y Pagar con Yape (enlazado desde billetera.jsp y yape.jsp) */
(function () {
  // Evita compras duplicadas por doble clic: deshabilita los botones tras enviar.
  // (Se hace en el siguiente ciclo para que el botón pulsado viaje con el formulario.)
  var formsCompra = Array.prototype.slice.call(document.querySelectorAll('form[data-comprar]'));
  function habilitar() {
    formsCompra.forEach(function (f) {
      Array.prototype.forEach.call(f.querySelectorAll('button'), function (b) { b.disabled = false; });
    });
  }
  formsCompra.forEach(function (f) {
    f.addEventListener('submit', function () {
      setTimeout(function () {
        Array.prototype.forEach.call(f.querySelectorAll('button'), function (b) { b.disabled = true; });
      }, 0);
    });
  });
  // Al volver con "atrás" desde la pasarela, los botones vuelven a estar activos
  window.addEventListener('pageshow', habilitar);

  // Copiar el número de Yape
  Array.prototype.forEach.call(document.querySelectorAll('[data-copiar]'), function (b) {
    b.addEventListener('click', function () {
      var origen = document.querySelector(b.getAttribute('data-copiar'));
      if (!origen || !navigator.clipboard) return;
      navigator.clipboard.writeText(origen.textContent.trim()).then(function () {
        var texto = b.textContent;
        b.textContent = 'Copiado';
        setTimeout(function () { b.textContent = texto; }, 1800);
      }, function () {});
    });
  });

  // Filtros de movimientos (todos / ingresos / egresos) sin recargar la página
  var lista = document.getElementById('btMovs');
  if (!lista) return;
  var filas = Array.prototype.slice.call(lista.querySelectorAll('.bt-mov'));
  var botones = Array.prototype.slice.call(document.querySelectorAll('.bt-filtro'));
  var vacio = document.getElementById('btSinResultados');

  function coincide(f, filtro) {
    return filtro === 'todos' || f.getAttribute('data-signo') === filtro;
  }

  botones.forEach(function (b) {
    var filtro = b.getAttribute('data-filtro');
    b.querySelector('.bt-n').textContent = filas.filter(function (f) { return coincide(f, filtro); }).length;
    b.addEventListener('click', function () {
      botones.forEach(function (x) {
        var activo = x === b;
        x.classList.toggle('activo', activo);
        x.setAttribute('aria-pressed', activo ? 'true' : 'false');
      });
      var visibles = 0;
      filas.forEach(function (f) {
        var ok = coincide(f, filtro);
        f.hidden = !ok;
        if (ok) visibles++;
      });
      vacio.hidden = visibles !== 0;
    });
  });
})();