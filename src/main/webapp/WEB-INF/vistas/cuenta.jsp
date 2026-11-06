<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ include file="/WEB-INF/vistas/comunes/encabezado-datos.jspf" %>
<%
    // Datos propios de "Mi cuenta" (nombreUsuario, avatarHtml, contexto, sesion vienen del encabezado compartido)
    String rolesRaw = "lector";
    String idUsuario = "";
    int monedas = 0;
    if (sesion != null) {
        Object rolesCuenta = sesion.getAttribute("roles");
        if (rolesCuenta instanceof java.util.Collection) {
            rolesRaw = ((java.util.Collection<?>) rolesCuenta).stream()
                    .map(String::valueOf)
                    .collect(java.util.stream.Collectors.joining(", "));
        } else if (rolesCuenta != null) {
            rolesRaw = String.valueOf(rolesCuenta);
        }
        if (sesion.getAttribute("usuarioId") != null) {
            idUsuario = String.valueOf(sesion.getAttribute("usuarioId"));
        }
    }
    Object monedasAttr = request.getAttribute("monedas");
    if (monedasAttr instanceof Number) {
        monedas = ((Number) monedasAttr).intValue();
    }
    String roles = esc(rolesRaw);
    String idMostrar = esc(idUsuario);
    String monedasTxt = String.format(java.util.Locale.US, "%,d", monedas);
    String nombrePublico = esc(sobrenombreMenu);
    String usuarioArroba = usuarioMenu.isEmpty() ? "" : "@" + esc(usuarioMenu);
    String bioCuenta = request.getAttribute("menuBiografia") == null ? ""
            : esc(String.valueOf(request.getAttribute("menuBiografia")));
    java.util.List<String[]> enlacesCuenta = request.getAttribute("enlaces") instanceof java.util.List
            ? (java.util.List<String[]>) request.getAttribute("enlaces") : new java.util.ArrayList<String[]>();
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Mi cuenta · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/base.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/landing.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/animaciones.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/ventanas.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/responsive.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/inicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/cuenta/cuenta.css">
</head>
<body>

<!-- Portadas ilustradas (SVG propio, paleta SAFIR) -->
<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">
  <defs>
    <symbol id="cv1" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#252866"/>
      <use href="#star" transform="translate(30 35) scale(9)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(112 28) scale(6)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(82 66) scale(5)" fill="#E9E7FF"/>
      <path d="M0 165 Q75 122 150 165 V200 H0Z" fill="#1D2042"/>
      <g stroke="#7775D6" stroke-width="2.5"><line x1="38" y1="182" x2="38" y2="152"/><line x1="75" y1="186" x2="75" y2="140"/><line x1="112" y1="182" x2="112" y2="155"/></g>
      <use href="#star" transform="translate(38 150) scale(9)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(75 138) scale(11)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(112 153) scale(8)" fill="#E9E7FF"/>
    </symbol>
    <symbol id="cv2" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#CBC9F4"/>
      <circle cx="108" cy="56" r="22" fill="#FFFCF7"/>
      <polygon points="0,150 46,82 92,150" fill="#7775D6"/>
      <polygon points="52,150 106,96 150,150" fill="#5051AE"/>
      <rect y="150" width="150" height="50" fill="#252866"/>
      <rect x="38" y="165" width="74" height="3" rx="1.5" fill="#7775D6"/>
      <rect x="56" y="178" width="40" height="3" rx="1.5" fill="#7775D6"/>
    </symbol>
    <symbol id="cv3" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#12142E"/>
      <circle cx="78" cy="82" r="44" fill="#E9E7FF"/>
      <circle cx="58" cy="72" r="8" fill="#CBC9F4"/>
      <circle cx="94" cy="98" r="10" fill="#CBC9F4"/>
      <circle cx="92" cy="64" r="5" fill="#CBC9F4"/>
      <use href="#plane-white" x="22" y="128" width="78" height="58"/>
      <use href="#star" transform="translate(24 30) scale(6)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(128 150) scale(5)" fill="#CBC9F4"/>
    </symbol>
    <symbol id="cv4" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#5051AE"/>
      <rect x="30" y="128" width="90" height="18" rx="3" fill="#252866"/>
      <rect x="40" y="108" width="76" height="18" rx="3" fill="#CBC9F4"/>
      <rect x="36" y="88" width="66" height="18" rx="3" fill="#E9E7FF" transform="rotate(-7 69 97)"/>
      <use href="#star" transform="translate(32 46) scale(8)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(116 60) scale(6)" fill="#CBC9F4"/>
      <use href="#star" transform="translate(86 28) scale(4)" fill="#E9E7FF"/>
    </symbol>
    <symbol id="cv5" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#E9E7FF"/>
      <path d="M75 24 Q94 50 75 70 Q56 50 75 24Z" fill="#252866"/>
      <g fill="none" stroke-width="7" stroke-linecap="round">
        <path d="M-5 118 Q35 96 75 118 T155 118" stroke="#5051AE"/>
        <path d="M-5 144 Q35 122 75 144 T155 144" stroke="#7775D6"/>
        <path d="M-5 170 Q35 148 75 170 T155 170" stroke="#252866"/>
      </g>
    </symbol>
    <symbol id="cv6" viewBox="0 0 150 200">
      <rect width="150" height="200" fill="#252866"/>
      <circle cx="75" cy="122" r="54" fill="#7775D6" opacity=".45"/>
      <rect y="148" width="150" height="52" fill="#12142E"/>
      <rect x="40" y="128" width="70" height="20" rx="5" fill="#CBC9F4"/>
      <g fill="#252866"><rect x="48" y="134" width="10" height="8" rx="2"/><rect x="64" y="134" width="10" height="8" rx="2"/><rect x="80" y="134" width="10" height="8" rx="2"/><rect x="96" y="134" width="8" height="8" rx="2"/></g>
      <g stroke="#5051AE" stroke-width="2"><line x1="0" y1="166" x2="150" y2="166"/><line x1="0" y1="182" x2="150" y2="182"/></g>
      <use href="#star" transform="translate(30 36) scale(6)" fill="#E9E7FF"/>
      <use href="#star" transform="translate(118 52) scale(8)" fill="#CBC9F4"/>
    </symbol>
  </defs>
</svg>

<%@ include file="/WEB-INF/vistas/comunes/encabezado.jspf" %>

<main id="cuenta">
  <!-- ENCABEZADO DE LA PÁGINA -->
  <section class="welcome">
    <div class="wrap">
      <div class="welcome-plane" aria-hidden="true">
        <svg viewBox="0 0 380 280" class="plane-float"><use href="#plane-color"/></svg>
      </div>
      <h1>Mi cuenta</h1>
      <p class="lead">Aquí ves los datos de tu cuenta y las monedas que has ganado en SAFIR.</p>
    </div>
  </section>

  <!-- PERFIL + MONEDAS -->
  <section class="block">
    <div class="wrap">
      <div class="account-grid">
        <article class="card profile">
          <div class="profile-top">
            <div class="big-avatar" aria-hidden="true"><%= avatarHtml %></div>
            <div>
              <h2><%= nombrePublico %></h2>
              <p class="muted">Cuenta de SAFIR</p>
            </div>
          </div>
          <dl class="dl">
            <div><dt>Nombre público</dt><dd><%= nombrePublico %></dd></div>
            <% if (!usuarioArroba.isEmpty()) { %>
            <div><dt>Nombre de usuario</dt><dd><%= usuarioArroba %></dd></div>
            <% } %>
            <% if (!bioCuenta.isEmpty()) { %>
            <div><dt>Descripción</dt><dd class="dd-bio"><%= bioCuenta %></dd></div>
            <% } %>
            <% if (!enlacesCuenta.isEmpty()) { %>
            <div><dt>Enlaces</dt><dd class="dd-enlaces">
              <% for (String[] en : enlacesCuenta) { %>
              <a href="<%= esc(en[1]) %>" target="_blank" rel="noopener noreferrer nofollow"><%= esc(en[0]) %></a>
              <% } %>
            </dd></div>
            <% } %>
            <div><dt>Tipo de cuenta</dt><dd><%= roles %></dd></div>
            <% if (!idMostrar.isEmpty()) { %>
            <div><dt>ID de usuario</dt><dd>#<%= idMostrar %></dd></div>
            <% } %>
          </dl>
          <p style="margin-top:1.2rem"><a class="btn small" href="<%= contexto %>/perfil#editar-perfil">Editar perfil</a></p>
        </article>

        <article class="coins" id="coinsCard">
          <h3>Mis monedas</h3>
          <p>Tus recompensas de lectura, logros y compras viven en un solo saldo.</p>
          <div class="coin-row">
            <div class="coin" aria-hidden="true">S</div>
            <div class="coin-num" id="coinNum" aria-label="<%= monedasTxt %> monedas"><%= monedasTxt %></div>
          </div>
          <a class="btn small gold" href="#movimientos">Ver movimientos</a>
        </article>
      </div>
    </div>
  </section>

  <!-- MOVIMIENTOS -->
  <section class="block" id="movimientos">
    <div class="wrap">
      <h2>Monedas ganadas</h2>
      <p class="sec-lead">El detalle de cómo ha crecido tu saldo.</p>
      <ul class="moves">
        <li class="move">
          <span class="coin sm" aria-hidden="true">S</span>
          <div class="move-text"><b>Bono de bienvenida</b><small>Por ser tu primera vez en SAFIR al registrarte</small></div>
          <span class="plus">+1,000</span>
        </li>
      </ul>
      <div class="total-row"><span>Saldo actual</span><b><%= monedasTxt %> monedas</b></div>
    </div>
  </section>

  <!-- SESIÓN -->
  <section class="block">
    <div class="wrap">
      <h2>Sesión</h2>
      <p class="sec-lead">Cuando termines, cierra tu sesión para proteger tu cuenta.</p>
      <p style="margin-top:1.4rem"><a class="btn" href="<%= contexto %>/auth/logout">Cerrar sesión</a></p>
      <p style="margin-top:1rem"><a href="<%= contexto %>/auth/cuenta/eliminar">Eliminar mi cuenta</a></p>
    </div>
  </section>
</main>

<footer>
  <div class="wrap">
    <a class="brand" href="<%= contexto %>/auth/inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <span>Tus historias, en un solo lugar.</span>
  </div>
</footer>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
<script>
(function () {
  // Animación del saldo de monedas
  var card = document.getElementById('coinsCard');
  var numEl = document.getElementById('coinNum');
  var total = <%= monedas %>;
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  card.classList.add('in');
  if (!reduce) {
    var t0 = null;
    (function paso(t) {
      if (!t0) t0 = t;
      var k = Math.min(1, (t - t0) / 1400);
      numEl.textContent = Math.round(total * (1 - Math.pow(1 - k, 3))).toLocaleString('en-US');
      if (k < 1) requestAnimationFrame(paso);
    })(performance.now());
  }
})();
</script>
</body>
</html>
