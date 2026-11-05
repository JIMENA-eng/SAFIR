<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%!
    /** Escapa texto para colocarlo dentro de HTML. */
    private static String esc(String t) {
        return t == null ? "" : t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    String contexto = request.getContextPath();

    jakarta.servlet.http.HttpSession sesion = request.getSession(false);
    String nombreUsuario = "lector";
    if (sesion != null && sesion.getAttribute("nombreUsuario") != null) {
        nombreUsuario = String.valueOf(sesion.getAttribute("nombreUsuario"));
    }
    // Roles guardados en sesión por LoginServlet (texto "lector, autor", colección o arreglo).
    boolean esAutor = false;
    if (sesion != null && sesion.getAttribute("roles") != null) {
        Object rolesSesion = sesion.getAttribute("roles");
        java.util.List<String> listaRoles = new java.util.ArrayList<String>();
        if (rolesSesion instanceof java.util.Collection<?>) {
            for (Object r : (java.util.Collection<?>) rolesSesion) listaRoles.add(String.valueOf(r));
        } else if (rolesSesion instanceof String[]) {
            for (String r : (String[]) rolesSesion) listaRoles.add(r);
        } else {
            for (String r : String.valueOf(rolesSesion).split("[,;]")) listaRoles.add(r);
        }
        for (String r : listaRoles) {
            String rol = r == null ? "" : r.trim();
            if (rol.equalsIgnoreCase("autor") || rol.equalsIgnoreCase("administrador")) { esAutor = true; }
        }
    }
    // Contadores para los puntos rojos (los calcula InicioServlet; 0 si no llegan).
    long notifNoLeidas = request.getAttribute("notificacionesNoLeidas") instanceof Number
            ? ((Number) request.getAttribute("notificacionesNoLeidas")).longValue() : 0L;
    long mensajesNoLeidos = request.getAttribute("mensajesNoLeidos") instanceof Number
            ? ((Number) request.getAttribute("mensajesNoLeidos")).longValue() : 0L;
    String inicial = nombreUsuario.isBlank() ? "S"
            : nombreUsuario.trim().substring(0, 1).toUpperCase();

    nombreUsuario = nombreUsuario
            .replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace("\"", "&quot;").replace("'", "&#39;");
    inicial = inicial
            .replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace("\"", "&quot;").replace("'", "&#39;");
    // Foto y portada: lo que cargó InicioServlet; si no llegó, la sesión.
    String avatarRuta = request.getAttribute("menuAvatar") != null
            ? String.valueOf(request.getAttribute("menuAvatar"))
            : ((sesion != null && sesion.getAttribute("avatarRuta") != null)
                ? String.valueOf(sesion.getAttribute("avatarRuta")) : null);
    String portadaRuta = request.getAttribute("menuPortada") != null
            ? String.valueOf(request.getAttribute("menuPortada")) : null;
    String sobrenombreMenu = request.getAttribute("menuSobrenombre") != null
            ? String.valueOf(request.getAttribute("menuSobrenombre"))
            : ((sesion != null && sesion.getAttribute("nombreUsuario") != null)
                ? String.valueOf(sesion.getAttribute("nombreUsuario")) : "lector");
    String usuarioMenu = request.getAttribute("menuUsuario") != null
            ? String.valueOf(request.getAttribute("menuUsuario")) : "";
    String avatarHtml = (avatarRuta == null) ? inicial
            : "<img src=\"" + contexto + "/media/"
              + avatarRuta.replace("&", "&amp;").replace("<", "&lt;").replace("\"", "&quot;")
              + "\" alt=\"\" style=\"width:100%;height:100%;border-radius:50%;object-fit:cover\">";
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Inicio · SAFIR</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500;9..40,600&family=Literata:opsz,wght@7..72,400;7..72,500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= contexto %>/assets/inicio/encabezadoinicio.css">
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
      <a href="<%= contexto %>/catalogo">Catálogo</a>
      <a href="<%= contexto %>/biblioteca">Mi biblioteca</a>
      <% if (esAutor) { %>
      <a href="<%= contexto %>/autor/panel">Panel de autor</a>
      <% } %>
    </nav>
    <button class="theme-toggle" id="themeBtn" type="button" aria-pressed="false">Modo noche</button>
    <div class="header-actions">
      <div class="lang-wrap">
        <button class="icon-btn" id="langBtn" type="button" aria-haspopup="true" aria-expanded="false" aria-controls="langMenu" aria-label="Idioma" title="Idioma"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3c2.8 3 2.8 15 0 18M12 3c-2.8 3-2.8 15 0 18"/></svg></button>
        <div class="menu" id="langMenu" role="menu" aria-label="Idioma" hidden>
          <button type="button" role="menuitemradio" aria-checked="true" data-lang="es">Español</button>
          <button type="button" role="menuitemradio" aria-checked="false" data-lang="en">English</button>
        </div>
      </div>
      <a class="icon-btn" href="<%= contexto %>/mensajes" data-pendiente aria-label="Mensajes<%= mensajesNoLeidos > 0 ? " (hay mensajes nuevos)" : "" %>" title="Mensajes"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="m3.5 7 8.5 6.5L20.5 7"/></svg><span class="dot" <%= mensajesNoLeidos > 0 ? "" : "hidden" %>></span></a>
      <a class="icon-btn" href="<%= contexto %>/notificaciones" aria-label="Notificaciones<%= notifNoLeidas > 0 ? " (hay notificaciones nuevas)" : "" %>" title="Notificaciones"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 9a6 6 0 0 1 12 0c0 6 2.5 7.5 2.5 7.5h-17S6 15 6 9"/><path d="M10 20a2 2 0 0 0 4 0"/></svg><span class="dot" <%= notifNoLeidas > 0 ? "" : "hidden" %>></span></a>
      <div class="menu-wrap">
        <button class="btn small user" id="userMenuBtn" type="button" aria-haspopup="true" aria-expanded="false" aria-controls="userMenu">
          <span class="avatar" aria-hidden="true"><%= avatarHtml %></span><b><%= nombreUsuario %></b>
          <svg class="caret" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m2 4 4 4 4-4"/></svg>
        </button>
        <div class="menu" id="userMenu" role="menu" aria-label="Menú de usuario" hidden>
          <a class="profile-card" role="menuitem" href="<%= contexto %>/perfil" aria-label="Editar perfil de <%= esc(sobrenombreMenu) %>">
            <span class="pc-cover">
              <% if (portadaRuta != null) { %><img src="<%= contexto %>/media/<%= esc(portadaRuta) %>" alt=""><% } %>
            </span>
            <span class="pc-avatar" aria-hidden="true"><%= avatarHtml %></span>
            <span class="pc-body">
              <span class="pc-names">
                <b><%= esc(sobrenombreMenu) %></b>
                <% if (!usuarioMenu.isEmpty()) { %><small>@<%= esc(usuarioMenu) %></small><% } %>
              </span>
              <span class="pc-edit" aria-hidden="true">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>
              </span>
            </span>
          </a>
          <a role="menuitem" href="<%= contexto %>/auth/cuenta">Mi cuenta</a>
          <a role="menuitem" href="<%= contexto %>/biblioteca">Mi biblioteca</a>
          <a role="menuitem" href="<%= contexto %>/notificaciones">Notificaciones</a>
          <a role="menuitem" href="#" data-pendiente>Mensajes</a>
          <% if (esAutor) { %>
          <div class="sep" role="separator"></div>
          <a role="menuitem" href="<%= contexto %>/autor/panel">Panel de autor</a>
          <a role="menuitem" href="<%= contexto %>/autor/obra/nueva">Nueva obra</a>
          <% } %>
          <div class="sep" role="separator"></div>
          <a role="menuitem" href="#" data-pendiente>Configuraciones</a>
          <div class="sep" role="separator"></div>
          <a role="menuitem" class="logout" href="<%= contexto %>/auth/logout">Cerrar sesión</a>
        </div>
      </div>
    </div>
  </div>
</header>

<main id="inicio">
  <!-- BIENVENIDA + BUSCADOR -->
  <section class="welcome">
    <div class="wrap">
      <div class="welcome-plane" aria-hidden="true">
        <svg viewBox="0 0 380 280" class="plane-float"><use href="#plane-color"/></svg>
      </div>
      <h1>Hola, <%= nombreUsuario %>.</h1>
      <p class="lead">Qué bueno verte de nuevo. Busca una obra o sigue leyendo donde te quedaste.</p>
      <%-- La búsqueda se envía al catálogo (CatalogoServlet, parámetro "q"). --%>
      <form class="search" id="searchForm" role="search" method="get" action="<%= contexto %>/catalogo">
        <input type="search" id="searchInput" name="q" placeholder="Buscar obras por título o género…" aria-label="Buscar obras" autocomplete="off">
        <button class="btn" type="submit">Buscar</button>
      </form>
    </div>
  </section>

  <!-- ACCESOS RÁPIDOS: una puerta a cada vista de la aplicación -->
  <section class="quick" id="accesos">
    <div class="wrap">
      <h2>Accesos rápidos</h2>
      <div class="quick-grid">
        <a class="qcard" href="<%= contexto %>/catalogo">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.5"/></svg></span>
          <b>Catálogo</b>
          <small>Explora las obras publicadas y filtra por título o género.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/biblioteca">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v16H6.5A2.5 2.5 0 0 0 4 21.5z"/><path d="M4 5.5v16"/></svg></span>
          <b>Mi biblioteca</b>
          <small>Tus obras guardadas, su estado de lectura y tus favoritas.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/notificaciones">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 9a6 6 0 0 1 12 0c0 6 2.5 7.5 2.5 7.5h-17S6 15 6 9"/><path d="M10 20a2 2 0 0 0 4 0"/></svg></span>
          <b>Notificaciones</b>
          <small>Capítulos nuevos y avisos de las obras que sigues.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/perfil">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg></span>
          <b>Mi perfil</b>
          <small>Tu nombre público, tus roles y tus accesos.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/auth/cuenta">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3.5" y="5" width="17" height="14" rx="2.5"/><circle cx="9" cy="12" r="2.2"/><path d="M13.5 10.5h4M13.5 13.5h4"/></svg></span>
          <b>Mi cuenta</b>
          <small>Datos de tu cuenta y de acceso.</small>
        </a>
<% if (esAutor) { %>
        <a class="qcard" href="<%= contexto %>/autor/panel">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 20l1-4L16.5 4.5a2.1 2.1 0 0 1 3 3L8 19z"/><path d="M14.5 6.5l3 3"/></svg></span>
          <b>Panel de autor</b>
          <small>Tus obras, avance, lecturas y valoraciones.</small>
        </a>
        <a class="qcard" href="<%= contexto %>/autor/obra/nueva">
          <span class="qi"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 8v8M8 12h8"/></svg></span>
          <b>Nueva obra</b>
          <small>Crea una historia y empieza a publicar capítulos.</small>
        </a>
<% } %>
      </div>
    </div>
  </section>

  <!-- CONTINUAR LEYENDO: la lectura (/lectura) se abre desde una obra o desde la biblioteca -->
  <section class="block" id="continuar">
    <div class="wrap">
      <h2>Continuar leyendo</h2>
      <p class="sec-lead">Vuelve justo donde lo dejaste.</p>
      <div class="empty">
        <p>Abre una obra de tu biblioteca y el lector retomará tu última posición guardada.</p>
        <a class="btn small" href="<%= contexto %>/biblioteca">Ir a mi biblioteca</a>
      </div>
    </div>
  </section>

  <!-- RECOMENDADOS -->
  <section class="block" id="recomendados">
    <div class="wrap">
      <h2>Recomendados para ti</h2>
      <p class="sec-lead">Historias que podrían gustarte esta noche.</p>
      <div class="empty">
        <p>Encuentra tu próxima lectura entre todas las obras publicadas.</p>
        <a class="btn small" href="<%= contexto %>/catalogo">Explorar el catálogo</a>
      </div>
    </div>
  </section>

  <!-- MIS LISTADOS -->
  <section class="block" id="listados">
    <div class="wrap">
      <h2>Mis listados</h2>
      <p class="sec-lead">Tus obras guardadas, organizadas a tu manera.</p>
      <div class="empty">
        <p>En tu biblioteca puedes marcar cada obra como por leer, leyendo, terminada o abandonada, y guardar tus favoritas.</p>
        <a class="btn small" href="<%= contexto %>/biblioteca">Abrir mi biblioteca</a>
      </div>
    </div>
  </section>

<% if (esAutor) { %>
  <!-- MIS OBRAS (solo autores y administradores) -->
  <section class="block" id="mis-obras">
    <div class="wrap">
      <h2>Mis obras</h2>
      <p class="sec-lead">Las historias que escribes y publicas en SAFIR.</p>
      <div class="actions-row">
        <a class="btn" href="<%= contexto %>/autor/panel">Ir al panel de autor</a>
        <a class="btn outline" href="<%= contexto %>/autor/obra/nueva">Nueva obra</a>
      </div>
    </div>
  </section>
<% } %>

  <!-- NOTIFICACIONES -->
  <section class="block" id="avisos">
    <div class="wrap">
      <h2>Notificaciones</h2>
      <p class="sec-lead">Entérate de los capítulos nuevos de las obras que sigues.</p>
      <div class="actions-row">
        <a class="btn outline" href="<%= contexto %>/notificaciones">Ver mis notificaciones</a>
        <a class="btn outline" href="<%= contexto %>/perfil">Mi perfil</a>
      </div>
    </div>
  </section>
</main>

<footer>
  <div class="wrap">
    <a class="brand" href="<%= contexto %>/auth/inicio" aria-label="SAFIR, inicio">
      <svg viewBox="0 0 380 280" aria-hidden="true"><use href="#plane-white"/></svg>
      <span>SAFIR</span>
    </a>
    <div class="links">
      <a href="<%= contexto %>/catalogo">Catálogo</a>
      <a href="<%= contexto %>/biblioteca">Mi biblioteca</a>
      <a href="<%= contexto %>/notificaciones">Notificaciones</a>
      <a href="<%= contexto %>/perfil">Mi perfil</a>
    </div>
    <span>Tus historias, en un solo lugar.</span>
  </div>
</footer>

<script src="<%= contexto %>/assets/js/inicio.js"></script>
</body>
</html>
