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

    // Si ya hay sesión iniciada, va directo al inicio
    jakarta.servlet.http.HttpSession sesion = request.getSession(false);
    if (sesion != null && sesion.getAttribute("usuarioId") != null) {
        response.sendRedirect(contexto + "/auth/inicio");
        return;
    }

    String error = esc((String) request.getAttribute("error"));
    boolean registrado = "1".equals(request.getParameter("registrado"));
    boolean eliminada = "1".equals(request.getParameter("eliminada"));
    
    boolean restablecido = "1".equals(request.getParameter("restablecido"));

   
    String correoPrevio = esc(request.getParameter("identificador"));

    // TAREA 1 (LOGIN-BLOQUEO): segundos que faltan para poder reintentar (0 = sin bloqueo)
    Object attrBloqueo = request.getAttribute("bloqueoSegundos");
    int bloqueoSegundos = (attrBloqueo instanceof Integer) ? (Integer) attrBloqueo : 0;
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Iniciar sesión · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&display=swap" rel="stylesheet">
<style>
  :root {
    --indigo: #252866; --lav: #7775D6; --lav-soft: #E9E7FF; --warm: #FFFCF7; --carbon: #292936;
    --bg: var(--warm); --soft: var(--lav-soft); --text: var(--carbon); --title: var(--indigo);
    --muted: #5b5b72; --line: #E3E0F7; --btn: var(--indigo); --btn-text: #fff; --link: var(--indigo); --outline: var(--lav);
    --sans: "DM Sans", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  }
  :root[data-theme="dark"] {
    --bg: #12142E; --soft: #181B3A; --text: #D9D9E8; --title: #F1F0FF; --muted: #A5A6C4;
    --line: #2C3060; --btn: #7775D6; --btn-text: #12142E; --link: #B9B7F5;
  }
  *, *::before, *::after { box-sizing: border-box; }
  html, body { height: 100%; }
  body { margin: 0; background: var(--bg); color: var(--text); font-family: var(--sans); font-size: 1.0625rem; line-height: 1.6; -webkit-font-smoothing: antialiased; overflow: hidden; }
  h2 { font-weight: 300; color: var(--title); margin: 0; line-height: 1.1; letter-spacing: -0.01em; }
  p { margin: 0; }
  :focus-visible { outline: 3px solid var(--lav); outline-offset: 3px; border-radius: 6px; }

  /* Fondo decorativo que queda detrás de la ventana */
  .backdrop { position: fixed; inset: 0; overflow: hidden; }
  .backdrop::before {
    content: ""; position: absolute; width: 820px; height: 820px; border-radius: 50%; top: 50%; right: -230px; transform: translateY(-50%);
    background: radial-gradient(circle, var(--soft) 0%, var(--soft) 34%, transparent 68%);
  }
  .backdrop::after {
    content: ""; position: absolute; width: 540px; height: 540px; border-radius: 50%; left: -210px; bottom: -280px;
    background: repeating-radial-gradient(circle, transparent 0 34px, var(--line) 34px 35.5px);
    -webkit-mask-image: radial-gradient(circle, #000 22%, transparent 70%); mask-image: radial-gradient(circle, #000 22%, transparent 70%);
  }
  .bg-plane { position: absolute; left: 8%; top: 14%; width: min(360px, 42vw); }
  .bg-plane svg { width: 100%; height: auto; overflow: visible; animation: drift 7s ease-in-out infinite; }
  .bg-moon { position: absolute; right: 9%; bottom: 12%; width: min(190px, 26vw); aspect-ratio: 1; border-radius: 50%;
    background: radial-gradient(circle at 36% 32%, #F6F5FF, #DAD8F8 60%, #B9B6EE); box-shadow: 0 0 70px 14px rgba(203,201,244,.5); }
  :root[data-theme="dark"] .bg-moon { opacity: .75; }
  @keyframes drift { 0%,100% { transform: translateY(0) rotate(0); } 50% { transform: translateY(-12px) rotate(-1.5deg); } }

  /* Ventana flotante */
  .overlay {
    position: fixed; inset: 0; z-index: 10; display: grid; place-items: center;
    padding: max(1rem, env(safe-area-inset-top, 0px)) 1rem max(1rem, env(safe-area-inset-bottom, 0px));
    background: rgba(18,20,46,.5); -webkit-backdrop-filter: blur(6px); backdrop-filter: blur(6px);
    animation: fadeIn .25s ease;
  }
  .modal {
    position: relative; width: min(430px, 100%); max-height: 100%; overflow-y: auto;
    padding: 2.2rem 1.9rem 1.8rem; border-radius: 26px; color: var(--text);
    background: rgba(255,252,247,.82); -webkit-backdrop-filter: blur(18px) saturate(1.2); backdrop-filter: blur(18px) saturate(1.2);
    border: 1px solid rgba(255,255,255,.65); box-shadow: 0 30px 80px -20px rgba(18,20,46,.6);
    animation: rise .3s cubic-bezier(.2,.8,.2,1);
  }
  :root[data-theme="dark"] .modal { background: rgba(29,32,66,.82); border-color: rgba(119,117,214,.4); }
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
  @keyframes rise { from { opacity: 0; transform: translateY(16px) scale(.97); } to { opacity: 1; transform: none; } }
  .close {
    position: absolute; top: .9rem; right: .9rem; width: 38px; height: 38px; border-radius: 50%; display: grid; place-items: center;
    background: rgba(119,117,214,.15); color: var(--title); font: 400 1.5rem/1 var(--sans); text-decoration: none;
  }
  .close:hover { background: rgba(119,117,214,.3); }
  .m-brand { display: flex; align-items: center; justify-content: center; gap: .6rem; margin-bottom: 1.1rem; }
  .m-brand svg { width: 48px; height: 36px; }
  .m-brand .dk { display: none; }
  :root[data-theme="dark"] .m-brand .lt { display: none; }
  :root[data-theme="dark"] .m-brand .dk { display: block; }
  .m-brand span { font: 500 1.3rem/1 var(--sans); letter-spacing: .28em; color: var(--title); }
  .modal h2 { font-size: 1.9rem; text-align: center; }
  .m-sub { text-align: center; color: var(--muted); margin-top: .4rem; font-size: .98rem; }
  form { margin-top: 1.2rem; }
  label { display: block; margin: 1rem 0 .35rem; font-size: .92rem; font-weight: 500; color: var(--title); }
  input {
    width: 100%; font: inherit; font-size: 1rem; padding: .85rem 1rem; border-radius: 12px;
    border: 1.5px solid var(--line); background: rgba(255,255,255,.75); color: var(--text);
  }
  :root[data-theme="dark"] input { background: rgba(18,20,46,.6); }
  input::placeholder { color: #8b8ba3; }
  input:focus { outline: none; border-color: var(--lav); box-shadow: 0 0 0 3px rgba(119,117,214,.28); }
  .pw { position: relative; }
  .pw input { padding-right: 5.2rem; }
  .pw-toggle { position: absolute; right: .5rem; top: 50%; transform: translateY(-50%); border: 0; background: transparent; color: var(--link); font: 500 .88rem var(--sans); cursor: pointer; padding: .4rem .6rem; border-radius: 8px; }
  .form-msg { min-height: 1.4em; margin-top: .8rem; font-size: .92rem; color: var(--muted); }
  .form-msg.err { color: #B3261E; }
  :root[data-theme="dark"] .form-msg.err { color: #FF9C94; }
  .form-msg.ok { color: var(--title); font-weight: 500; }
  .btn {
    display: inline-flex; align-items: center; justify-content: center; width: 100%; margin-top: .6rem; padding: 1rem;
    font: 500 1rem/1 var(--sans); border-radius: 999px; border: 1.5px solid transparent;
    background: var(--btn); color: var(--btn-text); cursor: pointer; transition: transform .15s;
  }
  .btn:hover { transform: translateY(-1px); }
  .btn:disabled { opacity: .55; cursor: not-allowed; transform: none; }
  input:disabled { opacity: .6; cursor: not-allowed; }
  /* Aviso de bloqueo por intentos fallidos */
  .bloqueo { display: flex; align-items: center; gap: .9rem; margin-top: 1rem; padding: .9rem 1rem; border-radius: 16px;
    background: rgba(179,38,30,.10); border: 1px solid rgba(179,38,30,.45); color: var(--title); font-size: .95rem; line-height: 1.45; }
  .bloqueo .reloj { width: 52px; height: 52px; border-radius: 50%; flex: none; display: grid; place-items: center;
    font: 600 1.15rem var(--sans); color: #B3261E; background: rgba(179,38,30,.12); font-variant-numeric: tabular-nums; }
  :root[data-theme="dark"] .bloqueo .reloj { color: #FF9C94; }
  .m-switch { margin-top: 1.3rem; text-align: center; font-size: .95rem; color: var(--muted); }
  .m-switch a { font-weight: 600; color: var(--link); text-underline-offset: 3px; }

  .bonus { display: flex; align-items: center; gap: .9rem; margin-top: 1.2rem; padding: .9rem 1rem; border-radius: 16px;
    background: rgba(242,184,75,.18); border: 1px solid rgba(242,184,75,.55); color: var(--title); font-size: .95rem; line-height: 1.45; }
  .bonus .coin { width: 44px; height: 44px; border-radius: 50%; background: #F2B84B; color: #B8832A; display: grid; place-items: center;
    font: 500 1.2rem var(--sans); box-shadow: inset 0 0 0 4px rgba(184,131,42,.25); flex: none; }
  .bonus b { font-weight: 600; }
  .bonus + form { margin-top: .4rem; }
  .olvido { display: block; margin-top: .55rem; text-align: right; font-size: .9rem; font-weight: 500; color: var(--link); text-underline-offset: 3px; }
  .aviso-ok { margin-top: 1.2rem; padding: .9rem 1rem; border-radius: 16px; font-size: .95rem; line-height: 1.5;
              background: rgba(30,122,70,.12); border: 1px solid rgba(30,122,70,.4); color: var(--title); }
  /* Inicio de sesión con redes sociales */
  .social { margin-top: 1.2rem; display: grid; gap: .6rem; }
  .social-sep { display: flex; align-items: center; gap: .8rem; font-size: .85rem; color: var(--muted); }
  .social-sep::before, .social-sep::after { content: ""; flex: 1; height: 1px; background: var(--line); }
  .btn-social { display: flex; align-items: center; justify-content: center; padding: .85rem 1rem; border-radius: 999px;
    border: 1.5px solid var(--line); background: rgba(255,255,255,.75); color: var(--title); font: 500 .98rem var(--sans); text-decoration: none; }
  :root[data-theme="dark"] .btn-social { background: rgba(18,20,46,.6); }
  .btn-social:hover { border-color: var(--lav); }
  .social-legal { font-size: .8rem; color: var(--muted); text-align: center; }
  @media (prefers-reduced-motion: reduce) { .overlay, .modal, .bg-plane svg { animation: none; } }
</style>
</head>
<body>

<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">
  <defs>
    <path id="star" d="M0,-1 Q.12,-.12 1,0 Q.12,.12 0,1 Q-.12,.12 -1,0 Q-.12,-.12 0,-1Z"/>
    <linearGradient id="orb" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#CBC9F4"/><stop offset="1" stop-color="#A9A5EE"/></linearGradient>
    <symbol id="plane-color" viewBox="300 230 380 280">
      <use href="#star" transform="translate(368 275) scale(35)" fill="#5051AE"/>
      <use href="#star" transform="translate(322 327) scale(17)" fill="#5051AE"/>
      <path d="M388 405C330 440 310 480 360 493C420 502 480 482 528 459C470 475 400 478 372 462C350 448 360 425 388 405Z" fill="url(#orb)"/>
      <polygon points="368,350 642,258 440,382" fill="#CBC9F4"/>
      <polygon points="440,382 642,258 458,461" fill="#5051AE"/>
      <polygon points="458,461 440,382 500,420" fill="#28296D"/>
      <polygon points="642,258 545,453 484,404" fill="#BDB9F2"/>
      <path d="M620 345C662 345 676 366 656 396C640 419 610 431 582 439C620 421 646 400 646 380C646 365 636 352 620 345Z" fill="url(#orb)"/>
    </symbol>
    <symbol id="plane-white" viewBox="300 230 380 280">
      <use href="#star" transform="translate(368 275) scale(35)" fill="#F4F3FF"/>
      <use href="#star" transform="translate(322 327) scale(17)" fill="#F4F3FF"/>
      <path d="M388 405C330 440 310 480 360 493C420 502 480 482 528 459C470 475 400 478 372 462C350 448 360 425 388 405Z" fill="#B7B6D6"/>
      <polygon points="368,350 642,258 440,382" fill="#C9C8DC"/>
      <polygon points="440,382 642,258 458,461" fill="#A9A8C6"/>
      <polygon points="458,461 440,382 500,420" fill="#8E8DB0"/>
      <polygon points="642,258 545,453 484,404" fill="#E9E8F5"/>
      <path d="M620 345C662 345 676 366 656 396C640 419 610 431 582 439C620 421 646 400 646 380C646 365 636 352 620 345Z" fill="#B7B6D6"/>
    </symbol>
  </defs>
</svg>

<!-- Fondo (queda desenfocado detrás de la ventana) -->
<div class="backdrop" aria-hidden="true">
  <div class="bg-plane"><svg viewBox="0 0 380 280"><use href="#plane-color"/></svg></div>
  <div class="bg-moon"></div>
</div>

<!-- Ventana flotante: POST /auth/login -->
<div class="overlay">
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="loginTitle">
    <a class="close" href="<%= contexto %>/index.jsp" aria-label="Cerrar y volver al inicio">×</a>

    <div class="m-brand" aria-hidden="true">
      <svg class="lt" viewBox="0 0 380 280"><use href="#plane-color"/></svg>
      <svg class="dk" viewBox="0 0 380 280"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </div>

    <h2 id="loginTitle">Iniciar sesión</h2>
    <p class="m-sub">Entra para continuar tu lectura.</p>
    <% if (eliminada) { %>
    <div class="bonus" role="status">
      <p><b>Tu cuenta fue eliminada.</b> Si te correspondía un reembolso, lo recibirás en el destino que indicaste.</p>
    </div>

    <% } %>
    <% if (registrado) { %>
    <div class="bonus" role="status">
      <span class="coin" aria-hidden="true">S</span>
      <p><b>¡Registro exitoso!</b> Por ser tu primera vez en SAFIR recibiste un <b>regalo de bienvenida en monedas</b>. Inicia sesión para verlo en tu cuenta.</p>
    </div>
    <% } %>

    <% if (restablecido) { %>
    <p class="aviso-ok" role="status"><b>Contraseña actualizada.</b> Ya puedes iniciar sesión con la nueva.</p>
    <% } %>

    <% if (bloqueoSegundos > 0) { %>
    <div class="bloqueo" id="loginBloqueo" role="alert">
      <span class="reloj" id="bloqueoReloj" aria-hidden="true"><%= bloqueoSegundos %></span>
      <p><b>Inicio de sesión bloqueado.</b> Fallaste la contraseña 3 veces. Podrás intentarlo de nuevo en
        <b><span id="bloqueoTexto"><%= bloqueoSegundos %></span> s</b>.</p>
    </div>
    <% } %>

    <form id="loginForm" action="<%= contexto %>/auth/login" method="post" novalidate
          data-bloqueo="<%= bloqueoSegundos %>">
      <label for="loginUser">Correo o número de teléfono</label>
      <input id="loginUser" name="identificador" type="text" maxlength="254" autocomplete="username"
             placeholder="tucorreo@ejemplo.com o 999 888 777" value="<%= correoPrevio %>">

      <label for="loginPass">Contraseña</label>
      <div class="pw">
        <input id="loginPass" name="clave" type="password" autocomplete="current-password" placeholder="Tu contraseña">
        <button class="pw-toggle" type="button" aria-pressed="false" aria-label="Mostrar contraseña">Mostrar</button>
      </div>
      <a class="olvido" href="<%= contexto %>/auth/recuperar">¿Olvidaste tu contraseña?</a>

      <% if (!error.isEmpty() && bloqueoSegundos == 0) { %>
        <p class="form-msg err" id="loginMsg" role="alert"><%= error %></p>
      <% } else { %>
        <p class="form-msg" id="loginMsg" role="status"></p>
      <% } %>

      <button class="btn" id="loginBtn" type="submit">Iniciar sesión</button>
    </form>

    <%
      String[][] redes = {{"google", "Google"}, {"facebook", "Facebook"}, {"x", "X"}};
      boolean hayRedes = false;
      for (String[] rd : redes) { if (com.safir.seguridad.SocialAuth.configurado(rd[0])) hayRedes = true; }
    %>
    <% if (hayRedes) { %>
    <div class="social">
      <p class="social-sep"><span>o continúa con</span></p>
      <% for (String[] rd : redes) { if (com.safir.seguridad.SocialAuth.configurado(rd[0])) { %>
      <a class="btn-social" href="<%= contexto %>/auth/social/<%= rd[0] %>">Continuar con <%= rd[1] %></a>
      <% } } %>
      <p class="social-legal">Al continuar autorizas el uso de tus datos personales según nuestra política de privacidad.</p>
    </div>
    <% } %>

    <p class="m-switch">¿No tienes una cuenta? <a href="<%= contexto %>/auth/registro">Registrarse</a></p>
  </div>
</div>

<script>
(function () {
  // Tema guardado (el mismo del resto del sitio)
  try { if (localStorage.getItem('safir-theme') === 'dark') document.documentElement.setAttribute('data-theme', 'dark'); } catch (e) {}

  var form = document.getElementById('loginForm');
  var user = document.getElementById('loginUser');
  var pass = document.getElementById('loginPass');
  var msg = document.getElementById('loginMsg');

  function say(text, kind) { msg.className = 'form-msg' + (kind ? ' ' + kind : ''); msg.textContent = text; }
  function isEmail(v) { return /^[^ @]+@[^ @]+[.][^ @]+$/.test(v); }
  function phoneOk(v) {
    var s = v.replace(/[\s\-().]/g, '');
    if (s.indexOf('00') === 0) s = '+' + s.slice(2);
    if (s.charAt(0) !== '+') { if (!/^9\d{8}$/.test(s)) return false; s = '+51' + s; }
    return /^\+[1-9]\d{7,14}$/.test(s);
  }

  // Mostrar / ocultar contraseña
  var t = document.querySelector('.pw-toggle');
  t.addEventListener('click', function () {
    var show = pass.type === 'password';
    pass.type = show ? 'text' : 'password';
    t.textContent = show ? 'Ocultar' : 'Mostrar';
    t.setAttribute('aria-pressed', show ? 'true' : 'false');
    t.setAttribute('aria-label', show ? 'Ocultar contraseña' : 'Mostrar contraseña');
  });

  // TAREA 1 (LOGIN-BLOQUEO): cuenta regresiva mientras dura el bloqueo.
  // El servidor es quien realmente bloquea; esto solo evita reenvíos y
  // le muestra al usuario cuánto falta.
  var btn = document.getElementById('loginBtn');
  var restante = parseInt(form.getAttribute('data-bloqueo'), 10) || 0;
  var bloqueado = restante > 0;

  function setBloqueo(activo) {
    bloqueado = activo;
    btn.disabled = activo;
    pass.disabled = activo;
    btn.textContent = activo ? 'Espera ' + restante + ' s' : 'Iniciar sesión';
  }

  if (bloqueado) {
    var caja = document.getElementById('loginBloqueo');
    var reloj = document.getElementById('bloqueoReloj');
    var texto = document.getElementById('bloqueoTexto');
    setBloqueo(true);
    var fin = Date.now() + restante * 1000;   // se basa en la hora real, no en contar ticks
    var timer = setInterval(function () {
      restante = Math.max(0, Math.ceil((fin - Date.now()) / 1000));
      if (reloj) reloj.textContent = restante;
      if (texto) texto.textContent = restante;
      if (restante <= 0) {
        clearInterval(timer);
        if (caja) caja.remove();
        setBloqueo(false);
        say('Ya puedes volver a intentarlo.', 'ok');
        pass.value = '';
        pass.focus();
      } else {
        btn.textContent = 'Espera ' + restante + ' s';
      }
    }, 250);
  }

  // Valida y, si todo está bien, envía a /auth/login
  form.addEventListener('submit', function (e) {
    if (bloqueado) { e.preventDefault(); return; }
    var v = user.value.trim();
    if (v.indexOf('@') >= 0 ? !isEmail(v) : !phoneOk(v)) { e.preventDefault(); return say('Escribe un correo o un número de teléfono válido.', 'err'); }
    if (!pass.value) { e.preventDefault(); return say('Escribe tu contraseña.', 'err'); }
    say('Ingresando…', 'ok');
  });

  // Escape cierra la ventana y vuelve al index
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') window.location.href = document.querySelector('.close').href;
  });

  if (!bloqueado) (user.value ? pass : user).focus();
})();
</script>
</body>
</html>
