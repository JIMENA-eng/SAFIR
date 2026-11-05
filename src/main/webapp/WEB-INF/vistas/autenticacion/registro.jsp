<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%!
    private static String esc(String t) {
        if (t == null) return "";
        return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contexto = request.getContextPath();

    String error = esc((String) request.getAttribute("error"));

    // Conserva lo escrito si el servidor devuelve el formulario con un error
    String nombrePrevio = esc(request.getParameter("nombre"));
    String usuarioPrevio = esc(request.getParameter("usuario"));
    String contactoPrevio = esc(request.getParameter("contacto"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Crear cuenta · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/css/autenticacion.css">
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/simbolos-logo.jspf" %>

<!-- Fondo (queda desenfocado detrás de la ventana) -->
<div class="backdrop" aria-hidden="true">
  <div class="bg-plane"><svg viewBox="0 0 380 280"><use href="#plane-color"/></svg></div>
  <div class="bg-moon"></div>
</div>

<!-- Ventana flotante: POST /auth/registro -->
<div class="overlay">
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="regTitle">
    <a class="close" href="<%= contexto %>/index.jsp" aria-label="Cerrar y volver al inicio">×</a>

    <div class="m-brand" aria-hidden="true">
      <svg class="lt" viewBox="0 0 380 280"><use href="#plane-color"/></svg>
      <svg class="dk" viewBox="0 0 380 280"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </div>

    <h2 id="regTitle">Crea tu cuenta</h2>
    <p class="m-sub">Únete para leer y publicar tus historias.</p>

    <form id="regForm" action="<%= contexto %>/auth/registro" method="post" novalidate>
      <label for="regNombre">Sobrenombre</label>
      <input id="regNombre" name="nombre" type="text" maxlength="60" autocomplete="nickname"
             placeholder="Cómo te verán los demás" value="<%= nombrePrevio %>">

      <label for="regUsuario">Nombre de usuario</label>
      <input id="regUsuario" name="usuario" type="text" maxlength="30" autocomplete="username"
             placeholder="ej. lectora_91" value="<%= usuarioPrevio %>">

      <label for="regContacto">Correo electrónico o número de teléfono</label>
      <input id="regContacto" name="contacto" type="text" maxlength="254" autocomplete="email"
             placeholder="tucorreo@ejemplo.com o 999 888 777" value="<%= contactoPrevio %>">
      <small class="hint" id="regContactoHint">Te enviaremos un código de verificación.</small>

      <label for="regPass">Contraseña</label>
      <div class="pw">
        <input id="regPass" name="clave" type="password" minlength="8" maxlength="72" autocomplete="new-password" placeholder="Crea una contraseña">
        <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
      </div>
      <div class="strength" aria-live="polite">
        <div class="strength-bar"><span id="regBar"></span></div>
        <span class="strength-label" id="regFuerza">Seguridad: —</span>
      </div>
      <ul class="reglas" id="regReglas">
        <li data-r="len">Mínimo 8 caracteres</li>
        <li data-r="may">Al menos una letra mayúscula</li>
        <li data-r="seq">Sin números seguidos (12345678, 1111)</li>
      </ul>

      <label for="regPass2">Confirmar contraseña</label>
      <div class="pw">
        <input id="regPass2" name="repetir" type="password" minlength="8" maxlength="72" autocomplete="new-password" placeholder="Repite tu contraseña">
        <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
      </div>

      <% if (!error.isEmpty()) { %>
        <p class="form-msg err" id="regMsg" role="alert"><%= error %></p>
      <% } else { %>
        <p class="form-msg" id="regMsg" role="status"></p>
      <% } %>

      <button class="btn" type="submit">Continuar</button>
    </form>

    <p class="m-switch">¿Ya tienes una cuenta? <a href="<%= contexto %>/auth/login">Iniciar sesión</a></p>
    <p class="m-legal">Te enviaremos un código por correo o SMS. Al ingresarlo autorizas el uso de tus datos personales según nuestra política de privacidad.</p>
  </div>
</div>

<script>
(function () {
  // Tema guardado (el mismo del resto del sitio)
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}

  var form = document.getElementById('regForm');
  var nombre = document.getElementById('regNombre');
  var usuario = document.getElementById('regUsuario');
  var contacto = document.getElementById('regContacto');
  var pass = document.getElementById('regPass');
  var pass2 = document.getElementById('regPass2');
  var msg = document.getElementById('regMsg');
  var bar = document.getElementById('regBar');
  var fuerzaTxt = document.getElementById('regFuerza');
  var hint = document.getElementById('regContactoHint');

  function say(text, kind) { msg.className = 'form-msg' + (kind ? ' ' + kind : ''); msg.textContent = text; }
  function isEmail(v) { return /^[^ @]+@[^ @]+[.][^ @]+$/.test(v); }
  function phoneOk(v) {
    var s = v.replace(/[\s\-().]/g, '');
    if (s.indexOf('00') === 0) s = '+' + s.slice(2);
    if (s.charAt(0) !== '+') { if (!/^9\d{8}$/.test(s)) return false; s = '+51' + s; }
    return /^\+[1-9]\d{7,14}$/.test(s);
  }
  // 4 o más dígitos seguidos (ascendentes, descendentes o repetidos)
  function numerosSeguidos(c) {
    var asc = 1, desc = 1, rep = 1;
    for (var i = 1; i < c.length; i++) {
      var a = c.charCodeAt(i - 1), b = c.charCodeAt(i), dig = a >= 48 && a <= 57 && b >= 48 && b <= 57;
      if (dig) { asc = b === a + 1 ? asc + 1 : 1; desc = b === a - 1 ? desc + 1 : 1; rep = b === a ? rep + 1 : 1; }
      else { asc = desc = rep = 1; }
      if (asc >= 4 || desc >= 4 || rep >= 4) return true;
    }
    return false;
  }
  function reglas(c) { return { len: c.length >= 8, may: /[A-ZÁÉÍÓÚÑÜ]/.test(c), seq: c.length > 0 && !numerosSeguidos(c) }; }
  // 0 débil, 1 media, 2 fuerte (igual que ValidadorRegistro.fuerza en el servidor)
  function fuerza(c) {
    var p = 0;
    if (c.length >= 8) p++;
    if (c.length >= 12) p++;
    if (/[a-zñáéíóúü]/.test(c) && /[A-ZÑÁÉÍÓÚÜ]/.test(c)) p++;
    if (/[0-9]/.test(c)) p++;
    if (/[^A-Za-z0-9ÁÉÍÓÚÑÜáéíóúñü]/.test(c)) p++;
    return p <= 2 ? 0 : (p === 3 ? 1 : 2);
  }

  // Mostrar / ocultar contraseña
  Array.prototype.forEach.call(document.querySelectorAll('.pw-toggle'), function (btn) {
    btn.addEventListener('click', function () {
      var input = btn.previousElementSibling;
      var show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      btn.textContent = show ? 'Ocultar' : 'Mostrar';
      btn.setAttribute('aria-pressed', show ? 'true' : 'false');
      btn.setAttribute('aria-label', show ? 'Ocultar contraseña' : 'Mostrar contraseña');
    });
  });

  // Indicador de seguridad y lista de reglas
  pass.addEventListener('input', function () {
    var c = pass.value, r = reglas(c);
    Array.prototype.forEach.call(document.querySelectorAll('#regReglas li'), function (li) {
      li.className = c ? (r[li.getAttribute('data-r')] ? 'ok' : 'no') : '';
    });
    var niveles = ['Débil', 'Media', 'Fuerte'];
    var f = c ? fuerza(c) : -1;
    bar.className = f < 0 ? '' : 'n' + f;
    fuerzaTxt.textContent = 'Seguridad: ' + (f < 0 ? '—' : niveles[f]);
  });

  // Aviso según lo que escribe (correo o teléfono)
  contacto.addEventListener('input', function () {
    var v = contacto.value.trim();
    hint.textContent = !v ? 'Te enviaremos un código de verificación.'
      : v.indexOf('@') >= 0 ? 'Te enviaremos el código por correo.'
      : 'Te enviaremos el código por SMS.';
  });

  // Valida y, si todo está bien, envía a /auth/registro
  form.addEventListener('submit', function (e) {
    function stop(text) { e.preventDefault(); say(text, 'err'); }
    var c = contacto.value.trim(), r = reglas(pass.value);
    if (!nombre.value.trim()) return stop('Escribe tu sobrenombre.');
    if (nombre.value.trim().length > 60) return stop('El sobrenombre admite hasta 60 caracteres.');
    if (!/^[A-Za-z0-9_.]{3,30}$/.test(usuario.value.trim())) return stop('El nombre de usuario debe tener de 3 a 30 caracteres: letras, números, punto o guion bajo.');
    if (c.indexOf('@') >= 0 ? !isEmail(c) : !phoneOk(c)) return stop('Escribe un correo o un número de teléfono válido.');
    if (!r.len) return stop('La contraseña debe tener al menos 8 caracteres.');
    if (!r.may) return stop('La contraseña debe incluir al menos una letra mayúscula.');
    if (!r.seq) return stop('No uses números seguidos (12345678) ni repetidos (1111).');
    if (pass.value !== pass2.value) return stop('Las contraseñas no coinciden.');
    say('Enviando tu código…', 'ok');
  });

  // Escape cierra la ventana y vuelve al index
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') window.location.href = document.querySelector('.close').href;
  });

  nombre.focus();
})();
</script>
</body>
</html>
