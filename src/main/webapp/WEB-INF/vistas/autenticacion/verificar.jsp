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
    String info = esc((String) request.getAttribute("info"));
    String destino = esc((String) request.getAttribute("destinoOculto"));
    boolean porTelefono = "telefono".equals(request.getAttribute("canal"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Verificar cuenta · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/css/autenticacion.css">
</head>
<body>

<%@ include file="/WEB-INF/vistas/comunes/simbolos-logo.jspf" %>

<div class="backdrop" aria-hidden="true">
  <div class="bg-plane"><svg viewBox="0 0 380 280"><use href="#plane-color"/></svg></div>
  <div class="bg-moon"></div>
</div>

<div class="overlay">
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="verTitle">
    <a class="close" href="<%= contexto %>/auth/registro" aria-label="Volver al registro">×</a>

    <div class="m-brand" aria-hidden="true">
      <svg class="lt" viewBox="0 0 380 280"><use href="#plane-color"/></svg>
      <svg class="dk" viewBox="0 0 380 280"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </div>

    <h2 id="verTitle">Verifica tu cuenta</h2>
    <p class="m-sub">
      Enviamos un código de 6 dígitos por <%= porTelefono ? "SMS" : "correo" %> a
      <b><%= destino %></b>.
    </p>

    <form id="verForm" action="<%= contexto %>/auth/verificar" method="post" novalidate>
      <input type="hidden" name="accion" value="confirmar">

      <label for="verCodigo">Código de verificación</label>
      <input id="verCodigo" name="codigo" class="codigo" type="text" inputmode="numeric"
             pattern="[0-9]{6}" maxlength="6" autocomplete="one-time-code" placeholder="••••••">

      <% if (!error.isEmpty()) { %>
        <p class="form-msg err" id="verMsg" role="alert"><%= error %></p>
      <% } else if (!info.isEmpty()) { %>
        <p class="form-msg ok-info" id="verMsg" role="status"><%= info %></p>
      <% } else { %>
        <p class="form-msg" id="verMsg" role="status"></p>
      <% } %>

      <button class="btn" type="submit">Verificar y crear cuenta</button>
    </form>

    <form action="<%= contexto %>/auth/verificar" method="post">
      <input type="hidden" name="accion" value="reenviar">
      <button class="btn ghost" type="submit">Reenviar código</button>
    </form>

    <p class="m-switch">¿Te equivocaste de dato? <a href="<%= contexto %>/auth/registro">Volver al registro</a></p>
    <p class="m-legal">Al ingresar el código confirmas que el <%= porTelefono ? "número" : "correo" %> es tuyo y autorizas el uso de tus datos personales según nuestra política de privacidad.</p>
  </div>
</div>

<script>
(function () {
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}
  var form = document.getElementById('verForm');
  var codigo = document.getElementById('verCodigo');
  var msg = document.getElementById('verMsg');
  codigo.addEventListener('input', function () { codigo.value = codigo.value.replace(/\D/g, '').slice(0, 6); });
  form.addEventListener('submit', function (e) {
    if (!/^\d{6}$/.test(codigo.value)) {
      e.preventDefault();
      msg.className = 'form-msg err';
      msg.textContent = 'Escribe el código de 6 dígitos.';
    }
  });
  codigo.focus();
})();
</script>
</body>
</html>
