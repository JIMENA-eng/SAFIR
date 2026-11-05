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
    String paso = (String) request.getAttribute("paso");          // codigo | clave | listo
    if (paso == null) paso = "codigo";
    String correoOculto = esc((String) request.getAttribute("correoOculto"));
    Object diasObj = request.getAttribute("dias");
    int dias = (diasObj instanceof Integer) ? (Integer) diasObj : 30;
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
  .aviso.warn { background: rgba(179,38,30,.10); border-color: rgba(179,38,30,.35); }
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

    <% if ("listo".equals(paso)) { %>
      <h2 id="resTitle">Contraseña actualizada</h2>
      <p class="m-sub">Ya puedes iniciar sesión con tu nueva contraseña.</p>
      <p class="aviso warn" role="alert">
        <b>Importante:</b> por seguridad, no podrás volver a recuperar tu
        contraseña hasta dentro de <b><%= dias %> días</b>. Guárdala en un lugar seguro.
      </p>
      <a class="btn" href="<%= contexto %>/auth/login" style="text-decoration:none">Ir a iniciar sesión</a>

    <% } else if ("clave".equals(paso)) { %>
      <h2 id="resTitle">Nueva contraseña</h2>
      <p class="m-sub">Código verificado. Elige tu nueva contraseña.</p>

      <form id="resForm" action="<%= contexto %>/auth/restablecer" method="post" novalidate>
        <input type="hidden" name="accion" value="guardar">

        <label for="resPass">Nueva contraseña</label>
        <div class="pw">
          <input id="resPass" name="clave" type="password" maxlength="72" autocomplete="new-password" placeholder="Mínimo 8 caracteres y una mayúscula">
          <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
        </div>

        <label for="resPass2">Confirmar contraseña</label>
        <div class="pw">
          <input id="resPass2" name="repetir" type="password" maxlength="72" autocomplete="new-password" placeholder="Repite tu contraseña">
          <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
        </div>

        <p class="aviso warn">Después de guardarla, no podrás recuperar la contraseña otra vez durante <b>30 días</b>.</p>

        <% if (!error.isEmpty()) { %>
          <p class="form-msg err" id="resMsg" role="alert"><%= error %></p>
        <% } else { %>
          <p class="form-msg" id="resMsg" role="status"></p>
        <% } %>

        <button class="btn" type="submit">Guardar contraseña</button>
      </form>

    <% } else { %>
      <h2 id="resTitle">Revisa tu correo</h2>
      <p class="m-sub">Enviamos un código de 6 dígitos a <b><%= correoOculto %></b>. Vale <%= com.safir.dao.RecuperacionDAO.MINUTOS_VALIDEZ %> minutos.</p>

      <form id="codForm" action="<%= contexto %>/auth/restablecer" method="post" novalidate>
        <input type="hidden" name="accion" value="confirmar">

        <label for="resCodigo">Código de verificación</label>
        <input id="resCodigo" name="codigo" class="codigo" type="text" inputmode="numeric"
               pattern="[0-9]{6}" maxlength="6" autocomplete="one-time-code" placeholder="••••••">

        <% if (!error.isEmpty()) { %>
          <p class="form-msg err" id="resMsg" role="alert"><%= error %></p>
        <% } else if (!info.isEmpty()) { %>
          <p class="form-msg ok-info" id="resMsg" role="status"><%= info %></p>
        <% } else { %>
          <p class="form-msg" id="resMsg" role="status"></p>
        <% } %>

        <button class="btn" type="submit">Verificar código</button>
      </form>

      <form action="<%= contexto %>/auth/restablecer" method="post">
        <input type="hidden" name="accion" value="reenviar">
        <button class="btn ghost" type="submit">Reenviar código</button>
      </form>

      <p class="m-switch">¿Te equivocaste de correo? <a href="<%= contexto %>/auth/recuperar">Volver</a></p>
    <% } %>
  </div>
</div>

<script>
(function () {
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}

  var msg = document.getElementById('resMsg');
  function stop(e, t) { e.preventDefault(); msg.className = 'form-msg err'; msg.textContent = t; }

  // Paso 1: código
  var codForm = document.getElementById('codForm');
  if (codForm) {
    var codigo = document.getElementById('resCodigo');
    codigo.addEventListener('input', function () { codigo.value = codigo.value.replace(/\D/g, '').slice(0, 6); });
    codForm.addEventListener('submit', function (e) {
      if (!/^\d{6}$/.test(codigo.value)) stop(e, 'Escribe el código de 6 dígitos.');
    });
    codigo.focus();
  }

  // Paso 2: contraseña nueva
  var resForm = document.getElementById('resForm');
  if (resForm) {
    var pass = document.getElementById('resPass');
    var pass2 = document.getElementById('resPass2');

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

    function seguidos(c) {
      var a = 1, d = 1, r = 1;
      for (var i = 1; i < c.length; i++) {
        var x = c.charAt(i - 1), y = c.charAt(i);
        if (/\d/.test(x) && /\d/.test(y)) {
          a = (+y === +x + 1) ? a + 1 : 1;
          d = (+y === +x - 1) ? d + 1 : 1;
          r = (y === x) ? r + 1 : 1;
        } else { a = d = r = 1; }
        if (a >= 4 || d >= 4 || r >= 4) return true;
      }
      return false;
    }

    resForm.addEventListener('submit', function (e) {
      var p = pass.value;
      if (p.length < 8) return stop(e, 'La contraseña debe tener al menos 8 caracteres.');
      if (!/[A-ZÁÉÍÓÚÑ]/.test(p)) return stop(e, 'La contraseña debe incluir al menos una letra mayúscula.');
      if (seguidos(p)) return stop(e, 'No uses números seguidos (12345678) ni repetidos (1111).');
      if (p !== pass2.value) return stop(e, 'Las contraseñas no coinciden.');
      msg.className = 'form-msg ok';
      msg.textContent = 'Guardando…';
    });
    pass.focus();
  }
})();
</script>
</body>
</html>
