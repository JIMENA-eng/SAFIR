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
    String token = esc((String) request.getAttribute("token"));
    boolean tokenInvalido = request.getAttribute("tokenInvalido") != null;
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Nueva contraseña · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/css/autenticacion.css">
<style>
  .aviso { margin-top: 1.2rem; padding: .9rem 1rem; border-radius: 16px; font-size: .95rem; line-height: 1.5;
           background: rgba(179,38,30,.10); border: 1px solid rgba(179,38,30,.35); color: var(--title); }
</style>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/simbolos-logo.jspf" %>

<div class="backdrop" aria-hidden="true">
  <div class="bg-plane"><svg viewBox="0 0 380 280"><use href="#plane-color"/></svg></div>
  <div class="bg-moon"></div>
</div>

<!-- Ventana flotante: POST /auth/restablecer -->
<div class="overlay">
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="resTitle">
    <a class="close" href="<%= contexto %>/auth/login" aria-label="Volver a iniciar sesión">×</a>

    <div class="m-brand" aria-hidden="true">
      <svg class="lt" viewBox="0 0 380 280"><use href="#plane-color"/></svg>
      <svg class="dk" viewBox="0 0 380 280"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </div>

    <% if (tokenInvalido) { %>
      <h2 id="resTitle">Enlace no válido</h2>
      <p class="aviso" role="alert">
        Este enlace no es válido, ya se usó o caducó. Pide uno nuevo para
        continuar.
      </p>
      <a class="btn" href="<%= contexto %>/auth/recuperar" style="text-decoration:none">Pedir un enlace nuevo</a>
      <p class="m-switch"><a href="<%= contexto %>/auth/login">Volver a iniciar sesión</a></p>
    <% } else { %>
      <h2 id="resTitle">Nueva contraseña</h2>
      <p class="m-sub">Elige una contraseña de al menos 8 caracteres.</p>

      <form id="resForm" action="<%= contexto %>/auth/restablecer" method="post" novalidate>
        <input type="hidden" name="token" value="<%= token %>">

        <label for="resPass">Nueva contraseña</label>
        <div class="pw">
          <input id="resPass" name="clave" type="password" minlength="8" autocomplete="new-password" placeholder="Crea una contraseña">
          <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
        </div>

        <label for="resPass2">Repetir contraseña</label>
        <div class="pw">
          <input id="resPass2" name="repetir" type="password" minlength="8" autocomplete="new-password" placeholder="Repite tu contraseña">
          <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
        </div>

        <% if (!error.isEmpty()) { %>
          <p class="form-msg err" id="resMsg" role="alert"><%= error %></p>
        <% } else { %>
          <p class="form-msg" id="resMsg" role="status"></p>
        <% } %>

        <button class="btn" type="submit">Guardar contraseña</button>
      </form>
    <% } %>
  </div>
</div>

<script>
(function () {
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}

  var form = document.getElementById('resForm');
  if (!form) return;
  var pass = document.getElementById('resPass');
  var pass2 = document.getElementById('resPass2');
  var msg = document.getElementById('resMsg');

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

  form.addEventListener('submit', function (e) {
    function stop(t) { e.preventDefault(); msg.className = 'form-msg err'; msg.textContent = t; }
    if (pass.value.length < 8) return stop('La contraseña debe tener al menos 8 caracteres.');
    if (pass.value !== pass2.value) return stop('Las contraseñas no coinciden.');
    msg.className = 'form-msg ok';
    msg.textContent = 'Guardando…';
  });

  pass.focus();
})();
</script>
</body>
</html>