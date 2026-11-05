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
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Personaliza tu perfil · SAFIR</title>
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
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="fotTitle">
    <div class="bonus" role="status">
      <span class="coin" aria-hidden="true">S</span>
      <p><b>¡Registro exitoso!</b> Recibiste un <b>regalo de bienvenida en monedas</b>.</p>
    </div>

    <h2 id="fotTitle" style="margin-top:1.2rem">Personaliza tu perfil</h2>
    <p class="m-sub">Sube tu foto de perfil y tu portada. Es opcional y puedes hacerlo luego.</p>

    <form id="fotForm" action="<%= contexto %>/auth/fotos" method="post" enctype="multipart/form-data" novalidate>

      <!-- Vista previa -->
      <div class="prev" aria-label="Vista previa del perfil">
        <div class="prev-portada" id="prevPortada"><span id="prevPortadaTxt">Portada</span></div>
        <div class="prev-avatar" id="prevAvatar"><span id="prevAvatarTxt">Foto</span></div>
      </div>

      <label for="fotAvatar">Foto de perfil (hasta 2 MB)</label>
      <input id="fotAvatar" name="avatar" type="file" accept="image/png,image/jpeg,image/webp">

      <label for="fotPortada">Foto de portada (hasta 5 MB)</label>
      <input id="fotPortada" name="portada" type="file" accept="image/png,image/jpeg,image/webp">

      <% if (!error.isEmpty()) { %>
        <p class="form-msg err" id="fotMsg" role="alert"><%= error %></p>
      <% } else { %>
        <p class="form-msg" id="fotMsg" role="status"></p>
      <% } %>

      <button class="btn" type="submit">Guardar y continuar</button>
    </form>

    <a class="btn ghost" href="<%= contexto %>/auth/inicio" style="text-decoration:none">Omitir por ahora</a>
  </div>
</div>

<script>
(function () {
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}

  var form = document.getElementById('fotForm');
  var inAvatar = document.getElementById('fotAvatar');
  var inPortada = document.getElementById('fotPortada');
  var msg = document.getElementById('fotMsg');
  var tipos = ['image/png', 'image/jpeg', 'image/webp'];

  function say(t, k) { msg.className = 'form-msg' + (k ? ' ' + k : ''); msg.textContent = t; }

  // Muestra la imagen elegida en el recuadro de vista previa
  function previa(input, caja, txt, maxMb, nombre) {
    input.addEventListener('change', function () {
      var f = input.files && input.files[0];
      caja.style.backgroundImage = '';
      txt.style.display = '';
      if (!f) { say(''); return; }
      if (tipos.indexOf(f.type) < 0) { input.value = ''; return say('Usa una imagen PNG, JPG o WEBP.', 'err'); }
      if (f.size > maxMb * 1024 * 1024) { input.value = ''; return say('La ' + nombre + ' no puede superar ' + maxMb + ' MB.', 'err'); }
      say('');
      var url = URL.createObjectURL(f);
      caja.style.backgroundImage = 'url("' + url + '")';
      txt.style.display = 'none';
    });
  }
  previa(inAvatar, document.getElementById('prevAvatar'), document.getElementById('prevAvatarTxt'), 2, 'foto de perfil');
  previa(inPortada, document.getElementById('prevPortada'), document.getElementById('prevPortadaTxt'), 5, 'portada');

  form.addEventListener('submit', function (e) {
    if (!(inAvatar.files && inAvatar.files[0]) && !(inPortada.files && inPortada.files[0])) {
      e.preventDefault();
      return say('Elige una imagen o pulsa "Omitir por ahora".', 'err');
    }
    say('Subiendo…', 'ok');
  });
})();
</script>
</body>
</html>
