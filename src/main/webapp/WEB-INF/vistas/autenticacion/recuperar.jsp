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
    boolean enviado = "1".equals(request.getParameter("enviado"));
    String correoPrevio = esc(request.getParameter("correo"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Recuperar contraseña · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/css/autenticacion.css">
<style>
  .aviso { margin-top: 1.2rem; padding: .9rem 1rem; border-radius: 16px; font-size: .95rem; line-height: 1.5;
           background: rgba(119,117,214,.14); border: 1px solid rgba(119,117,214,.35); color: var(--title); }
</style>
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/simbolos-logo.jspf" %>

<div class="backdrop" aria-hidden="true">
  <div class="bg-plane"><svg viewBox="0 0 380 280"><use href="#plane-color"/></svg></div>
  <div class="bg-moon"></div>
</div>

<!-- Ventana flotante: POST /auth/recuperar -->
<div class="overlay">
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="recTitle">
    <a class="close" href="<%= contexto %>/auth/login" aria-label="Volver a iniciar sesión">×</a>

    <div class="m-brand" aria-hidden="true">
      <svg class="lt" viewBox="0 0 380 280"><use href="#plane-color"/></svg>
      <svg class="dk" viewBox="0 0 380 280"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </div>

    <h2 id="recTitle">Recuperar contraseña</h2>
    <p class="m-sub">Te enviaremos un enlace para crear una nueva.</p>

    <% if (enviado) { %>
      <p class="aviso" role="status">
        Si el correo está registrado, te enviamos un enlace para restablecer
        tu contraseña. Revisa tu bandeja de entrada (y la carpeta de spam).
        El enlace vale <b>30 minutos</b>.
      </p>
      <p class="m-switch"><a href="<%= contexto %>/auth/login">Volver a iniciar sesión</a></p>
    <% } else { %>
      <form id="recForm" action="<%= contexto %>/auth/recuperar" method="post" novalidate>
        <label for="recCorreo">Correo electrónico</label>
        <input id="recCorreo" name="correo" type="email" maxlength="254" autocomplete="email"
               placeholder="tucorreo@ejemplo.com" value="<%= correoPrevio %>">

        <% if (!error.isEmpty()) { %>
          <p class="form-msg err" id="recMsg" role="alert"><%= error %></p>
        <% } else { %>
          <p class="form-msg" id="recMsg" role="status"></p>
        <% } %>

        <button class="btn" type="submit">Enviar enlace</button>
      </form>
      <p class="m-switch">¿Ya la recordaste? <a href="<%= contexto %>/auth/login">Iniciar sesión</a></p>
    <% } %>
  </div>
</div>

<script>
(function () {
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}

  var form = document.getElementById('recForm');
  if (!form) return;
  var correo = document.getElementById('recCorreo');
  var msg = document.getElementById('recMsg');

  form.addEventListener('submit', function (e) {
    if (!/^[^ @]+@[^ @]+[.][^ @]+$/.test(correo.value.trim())) {
      e.preventDefault();
      msg.className = 'form-msg err';
      msg.textContent = 'Escribe un correo electrónico válido.';
      return;
    }
    msg.className = 'form-msg ok';
    msg.textContent = 'Enviando…';
  });

  correo.focus();
})();
</script>
</body>
</html>