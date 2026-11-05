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

    jakarta.servlet.http.HttpSession sesion = request.getSession(false);

    String nombreRaw = "lector";
    String rolesRaw = "lector";
    String idUsuario = "";
    int monedas = 0; // bono de bienvenida por el primer registro

    if (sesion != null) {
        if (sesion.getAttribute("nombreUsuario") != null) {
            nombreRaw = String.valueOf(sesion.getAttribute("nombreUsuario"));
        }
        Object r = sesion.getAttribute("roles");
        if (r instanceof java.util.Collection) {
            rolesRaw = ((java.util.Collection<?>) r).stream()
                    .map(String::valueOf)
                    .collect(java.util.stream.Collectors.joining(", "));
        } else if (r != null) {
            rolesRaw = String.valueOf(r);
        }
        if (sesion.getAttribute("usuarioId") != null) {
            idUsuario = String.valueOf(sesion.getAttribute("usuarioId"));
        }
        Object m = request.getAttribute("monedas");
        if (m instanceof Number) {
            monedas = ((Number) m).intValue();
        }
    }

    String nombreUsuario = esc(nombreRaw);
    String inicial = esc(nombreRaw.isBlank() ? "S" : nombreRaw.trim().substring(0, 1).toUpperCase());
    String roles = esc(rolesRaw);
    String idMostrar = esc(idUsuario);
    String monedasTxt = String.format(java.util.Locale.US, "%,d", monedas);
    String avatarRuta = (sesion != null && sesion.getAttribute("avatarRuta") != null)
            ? String.valueOf(sesion.getAttribute("avatarRuta")) : null;
    String avatarHtml = (avatarRuta == null) ? inicial
            : "<img src=\"" + contexto + "/media/" + esc(avatarRuta)
              + "\" alt=\"\" style=\"width:100%;height:100%;border-radius:50%;object-fit:cover\">";
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
<link rel="stylesheet" href="<%= contexto %>/assets/css/cuenta/base.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/cuenta/landing.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/cuenta/animaciones.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/cuenta/ventanas.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/cuenta/responsive.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/cuenta/inicio.css">
<link rel="stylesheet" href="<%= contexto %>/assets/css/cuenta/cuenta.css">
</head>
<body>

<!-- Símbolo del logo (aproximación vectorial; reemplazar por el archivo oficial) -->
<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">
  <defs>
    <path id="star" d="M0,-1 Q.12,-.12 1,0 Q.12,.12 0,1 Q-.12,.12 -1,0 Q-.12,-.12 0,-1Z"/>
    <linearGradient id="orb" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#CBC9F4"/><stop offset="1" stop-color="#A9A5EE"/>
    </linearGradient>
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

<header class="bar">
  <div class="wrap">
    <a class="brand" href="<%= contexto %>/auth/inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" role="img" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <nav aria-label="Principal">
      <a href="<%= contexto %>/auth/inicio#continuar">Continuar leyendo</a>
      <a href="<%= contexto %>/auth/inicio#recomendados">Recomendados</a>
      <a href="<%= contexto %>/auth/inicio#listados">Mis listados</a>
      <a href="<%= contexto %>/auth/inicio#mis-obras">Mis obras</a>
    </nav>
    <button class="theme-toggle" id="themeBtn" type="button" aria-pressed="false">Modo noche</button>
    <div class="menu-wrap">
      <button class="btn small user" id="userMenuBtn" type="button" aria-haspopup="true" aria-expanded="false" aria-controls="userMenu">
        <span class="avatar" aria-hidden="true"><%= avatarHtml %></span><b><%= nombreUsuario %></b>
        <svg class="caret" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m2 4 4 4 4-4"/></svg>
      </button>
      <div class="menu" id="userMenu" role="menu" aria-label="Menú de usuario" hidden>
        <div class="menu-head"><b><%= nombreUsuario %></b><small>Sesión iniciada</small></div>
        <a role="menuitem" href="<%= contexto %>/auth/cuenta">Mi cuenta</a>
        <a role="menuitem" href="#" data-pendiente>Configuraciones</a>
        <a role="menuitem" href="<%= contexto %>/auth/inicio#listados">Mi biblioteca</a>
        <a role="menuitem" href="#" data-pendiente>Notificaciones</a>
        <a role="menuitem" href="#" data-pendiente>Mensajes</a>
        <a role="menuitem" href="<%= contexto %>/auth/inicio#mis-obras">Mis obras</a>
        
      </div>
    </div>
    <a class="btn small on-bar" href="<%= contexto %>/auth/logout">Cerrar sesión</a>
  </div>
</header>

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
              <h2><%= nombreUsuario %></h2>
              <p class="muted">Cuenta de SAFIR</p>
            </div>
          </div>
          <dl class="dl">
            <div><dt>Nombre público</dt><dd><%= nombreUsuario %></dd></div>
            <div><dt>Tipo de cuenta</dt><dd><%= roles %></dd></div>
            <% if (!idMostrar.isEmpty()) { %>
            <div><dt>ID de usuario</dt><dd>#<%= idMostrar %></dd></div>
            <% } %>
          </dl>
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

<script>
(function () {
  // Modo noche
  var root = document.documentElement;
  var themeBtn = document.getElementById('themeBtn');
  function setTheme(t) {
    if (t === 'dark') root.setAttribute('data-theme', 'dark'); else root.removeAttribute('data-theme');
    themeBtn.setAttribute('aria-pressed', t === 'dark' ? 'true' : 'false');
    themeBtn.textContent = t === 'dark' ? 'Modo claro' : 'Modo noche';
    try { localStorage.setItem('safir-theme', t); } catch (e) {}
  }
  var saved = null;
  try { saved = localStorage.getItem('safir-theme'); } catch (e) {}
  setTheme(saved === 'dark' ? 'dark' : 'light');
  themeBtn.addEventListener('click', function () {
    setTheme(root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
  });

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

  // Menú de usuario
  var menuBtn = document.getElementById('userMenuBtn');
  var menu = document.getElementById('userMenu');
  function setMenu(open) {
    menu.hidden = !open;
    menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  menuBtn.addEventListener('click', function (e) { e.stopPropagation(); setMenu(menu.hidden); });
  document.addEventListener('click', function (e) {
    if (!menu.hidden && !menu.contains(e.target)) setMenu(false);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && !menu.hidden) { setMenu(false); menuBtn.focus(); }
  });
  Array.prototype.forEach.call(menu.querySelectorAll('a'), function (a) {
    a.addEventListener('click', function (e) {
      if (a.hasAttribute('data-pendiente')) e.preventDefault();
      setMenu(false);
    });
  });
})();
</script>
</body>
</html>
