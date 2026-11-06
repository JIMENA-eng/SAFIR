/* SAFIR · Mi billetera y Pagar con Yape (enlazado desde billetera.jsp y yape.jsp) */
(function () {
  // ---------- Formularios que no deben enviarse dos veces (compras, nivel, retiro) ----------
  // Se deshabilitan los botones en el siguiente ciclo para que el botón pulsado viaje con el formulario.
  var formsUnicos = Array.prototype.slice.call(document.querySelectorAll('form[data-unico]'));

  function botones(f) { return Array.prototype.slice.call(f.querySelectorAll('button')); }
  function habilitar() { formsUnicos.forEach(function (f) { botones(f).forEach(function (b) { b.disabled = false; }); }); }

  // Mensaje de confirmación: fijo (data-confirmar) o calculado para el retiro
  function mensajeConfirmacion(f) {
    if (f.hasAttribute('data-confirmar')) return f.getAttribute('data-confirmar');
    if (f.hasAttribute('data-retiro')) {
      var m = parseInt(f.querySelector('[name="monedas"]').value, 10);
      if (m > 0) {
        return '¿Solicitar el retiro de ' + m.toLocaleString('es-PE') +
               ' monedas? Se descontarán de tu saldo de inmediato; si se rechaza, te las devolvemos completas.';
      }
    }
    return null;
  }

  formsUnicos.forEach(function (f) {
    f.addEventListener('submit', function (e) {
      var msg = mensajeConfirmacion(f);
      if (msg && !window.confirm(msg)) { e.preventDefault(); return; }
      setTimeout(function () { botones(f).forEach(function (b) { b.disabled = true; }); }, 0);
    });
  });
  // Al volver con "atrás" desde la pasarela, los botones vuelven a estar activos
  window.addEventListener('pageshow', habilitar);

  // ---------- Retiro: estimado y tipo de dato según el método ----------
  var formRetiro = document.querySelector('form[data-retiro]');
  if (formRetiro) {
    var entrada = formRetiro.querySelector('[name="monedas"]');
    var salida = formRetiro.querySelector('.bt-estimado');
    var pct = parseFloat(formRetiro.getAttribute('data-pct'));
    var valor = parseFloat(formRetiro.getAttribute('data-valor'));

    entrada.addEventListener('input', function () {
      var m = parseInt(entrada.value, 10);
      if (!m || m < 1 || isNaN(pct) || isNaN(valor)) { salida.textContent = ''; return; }
      var neto = m - Math.round(m * pct / 100);
      salida.textContent = 'Recibirías ' + neto.toLocaleString('es-PE') +
        ' monedas, aprox. US$ ' + (neto * valor).toFixed(2);
    });

    var metodo = formRetiro.querySelector('[name="metodo"]');
    var datos = formRetiro.querySelector('[name="datos"]');
    var etiqueta = document.getElementById('btRetiroDatosEtq');
    var porMetodo = {
      paypal: { etq: 'Correo de PayPal', tipo: 'email', ph: 'tucorreo@ejemplo.com', patron: '', modo: 'email', max: '150' },
      yape: { etq: 'Celular de Yape', tipo: 'text', ph: '9XXXXXXXX', patron: '9[0-9]{8}', modo: 'numeric', max: '9' }
    };
    function aplicarMetodo() {
      var c = porMetodo[metodo.value];
      if (!c) return;
      datos.value = '';
      datos.type = c.tipo;
      datos.placeholder = c.ph;
      datos.setAttribute('inputmode', c.modo);
      datos.setAttribute('maxlength', c.max);
      if (c.patron) {
        datos.setAttribute('pattern', c.patron);
        datos.title = 'Celular de 9 dígitos que empieza con 9';
      } else {
        datos.removeAttribute('pattern');
        datos.removeAttribute('title');
      }
      etiqueta.textContent = c.etq;
    }
    metodo.addEventListener('change', aplicarMetodo);
  }

  // ---------- Copiar el número de Yape ----------
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

  // ---------- Filtros de movimientos (todos / ingresos / egresos) ----------
  var lista = document.getElementById('btMovs');
  if (!lista) return;
  var filas = Array.prototype.slice.call(lista.querySelectorAll('.bt-mov'));
  var filtros = Array.prototype.slice.call(document.querySelectorAll('.bt-filtro'));
  var vacio = document.getElementById('btSinResultados');

  function coincide(f, filtro) {
    return filtro === 'todos' || f.getAttribute('data-signo') === filtro;
  }

  filtros.forEach(function (b) {
    var filtro = b.getAttribute('data-filtro');
    b.querySelector('.bt-n').textContent = filas.filter(function (f) { return coincide(f, filtro); }).length;
    b.addEventListener('click', function () {
      filtros.forEach(function (x) {
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