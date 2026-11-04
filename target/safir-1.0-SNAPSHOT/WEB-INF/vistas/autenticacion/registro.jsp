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
    String nombrePrevio = "";
    String correoPrevio = "";
    try {
        nombrePrevio = esc(request.getParameter("nombre"));
        correoPrevio = esc(request.getParameter("correo"));
    } catch (RuntimeException e) {
        // Sin valores previos (por ejemplo, si la subida superó el tamaño permitido)
    }
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

    <form id="regForm" action="<%= contexto %>/auth/registro" method="post" enctype="multipart/form-data" novalidate>
      <label for="regNombre">Nombre público</label>
      <input id="regNombre" name="nombre" type="text" maxlength="60" autocomplete="nickname"
             placeholder="Cómo te verán los demás" value="<%= nombrePrevio %>">

      <label for="regEmail">Correo electrónico</label>
      <input id="regEmail" name="correo" type="email" maxlength="254" autocomplete="email"
             placeholder="tucorreo@ejemplo.com" value="<%= correoPrevio %>">

      <label for="regPass">Contraseña (mínimo 8 caracteres)</label>
      <div class="pw">
        <input id="regPass" name="clave" type="password" minlength="8" autocomplete="new-password" placeholder="Crea una contraseña">
        <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
      </div>

      <label for="regPass2">Repetir contraseña</label>
      <div class="pw">
        <input id="regPass2" name="repetir" type="password" minlength="8" autocomplete="new-password" placeholder="Repite tu contraseña">
        <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
      </div>

      <label for="regAvatar">Foto de perfil (opcional)</label>
      <input id="regAvatar" name="avatar" type="file" accept="image/png,image/jpeg,image/webp">

      <label for="regPortada">Foto de portada (opcional)</label>
      <input id="regPortada" name="portada" type="file" accept="image/png,image/jpeg,image/webp">
      <small class="hint">Puedes omitirlas y agregarlas luego desde tu perfil.</small>

      <% if (!error.isEmpty()) { %>
        <p class="form-msg err" id="regMsg" role="alert"><%= error %></p>
      <% } else { %>
        <p class="form-msg" id="regMsg" role="status"></p>
      <% } %>

      <button class="btn" type="submit">Crear cuenta</button>
    </form>

    <p class="m-switch">¿Ya tienes una cuenta? <a href="<%= contexto %>/auth/login">Iniciar sesión</a></p>
    <p class="m-legal">Al registrarte aceptas los términos de uso y la política de privacidad.</p>
  </div>
</div>

<script>
(function () {
  // Tema guardado (el mismo del resto del sitio)
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}

  var form = document.getElementById('regForm');
  var nombre = document.getElementById('regNombre');
  var mail = document.getElementById('regEmail');
  var pass = document.getElementById('regPass');
  var pass2 = document.getElementById('regPass2');
  var avatar = document.getElementById('regAvatar');
  var portada = document.getElementById('regPortada');
  var msg = document.getElementById('regMsg');

  function say(text, kind) { msg.className = 'form-msg' + (kind ? ' ' + kind : ''); msg.textContent = text; }
  function isEmail(v) { return /^[^ @]+@[^ @]+[.][^ @]+$/.test(v); }
  function tooBig(input, maxMb) { return input.files && input.files[0] && input.files[0].size > maxMb * 1024 * 1024; }

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

  // Valida y, si todo está bien, envía a /auth/registro
  form.addEventListener('submit', function (e) {
    function stop(text) { e.preventDefault(); say(text, 'err'); }
    if (!nombre.value.trim()) return stop('Escribe tu nombre público.');
    if (nombre.value.trim().length > 60) return stop('El nombre público admite hasta 60 caracteres.');
    if (!isEmail(mail.value.trim())) return stop('Escribe un correo electrónico válido.');
    if (pass.value.length < 8) return stop('La contraseña debe tener al menos 8 caracteres.');
    if (pass.value !== pass2.value) return stop('Las contraseñas no coinciden.');
    if (tooBig(avatar, 2)) return stop('La foto de perfil no puede superar 2 MB.');
    if (tooBig(portada, 5)) return stop('La foto de portada no puede superar 5 MB.');
    say('Creando tu cuenta…', 'ok');
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
