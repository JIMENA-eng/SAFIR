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
    long[] est = request.getAttribute("estadisticas") instanceof long[]
            ? (long[]) request.getAttribute("estadisticas") : new long[5];
    String nSeguidores = String.format(java.util.Locale.US, "%,d", est[0]);
    String nValoraciones = String.format(java.util.Locale.US, "%,d", est[1]);
    String nListas = String.format(java.util.Locale.US, "%,d", est[2]);
    String nObras = String.format(java.util.Locale.US, "%,d", est[3]);
    String nSeguidos = String.format(java.util.Locale.US, "%,d", est[4]);
    java.util.List<String[]> siguiendoLista = request.getAttribute("siguiendo") instanceof java.util.List
            ? (java.util.List<String[]>) request.getAttribute("siguiendo") : new java.util.ArrayList<String[]>();
    java.util.List<String[]> seguidoresLista = request.getAttribute("seguidores") instanceof java.util.List
            ? (java.util.List<String[]>) request.getAttribute("seguidores") : new java.util.ArrayList<String[]>();
    String nombrePublico = esc(sobrenombreMenu);
    String usuarioArroba = usuarioMenu.isEmpty() ? "" : "@" + esc(usuarioMenu);
    String bioCuenta = request.getAttribute("menuBiografia") == null ? ""
            : esc(String.valueOf(request.getAttribute("menuBiografia")));
    java.util.List<String[]> enlacesCuenta = request.getAttribute("enlaces") instanceof java.util.List
            ? (java.util.List<String[]>) request.getAttribute("enlaces") : new java.util.ArrayList<String[]>();
%>
<%!
    /** Etiqueta visible de cada red. */
    private static String nombreRed(String red) {
        switch (red == null ? "" : red) {
            case "instagram": return "Instagram";
            case "facebook":  return "Facebook";
            case "x":         return "X";
            case "tiktok":    return "TikTok";
            case "youtube":   return "YouTube";
            case "web":       return "Sitio web";
            default:          return "Enlace";
        }
    }
    /** Ícono SVG (trazo) de cada red. */
    private static String iconoRed(String red) {
        String d;
        switch (red == null ? "" : red) {
            case "instagram":
                d = "<rect width=\"20\" height=\"20\" x=\"2\" y=\"2\" rx=\"5\" ry=\"5\"/><path d=\"M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z\"/><line x1=\"17.5\" x2=\"17.51\" y1=\"6.5\" y2=\"6.5\"/>"; break;
            case "facebook":
                d = "<path d=\"M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z\"/>"; break;
            case "x":
                d = "<path d=\"M4 4h4l12 16h-4z\"/><path d=\"M4 20l7-7M13 11l7-7\"/>"; break;
            case "tiktok":
                d = "<path d=\"M9 18V5l12-2v13\"/><circle cx=\"6\" cy=\"18\" r=\"3\"/><circle cx=\"18\" cy=\"16\" r=\"3\"/>"; break;
            case "youtube":
                d = "<path d=\"M2.5 17a24.12 24.12 0 0 1 0-10 2 2 0 0 1 1.4-1.4 49.56 49.56 0 0 1 16.2 0A2 2 0 0 1 21.5 7a24.12 24.12 0 0 1 0 10 2 2 0 0 1-1.4 1.4 49.55 49.55 0 0 1-16.2 0A2 2 0 0 1 2.5 17\"/><path d=\"m10 15 5-3-5-3z\"/>"; break;
            case "web":
                d = "<circle cx=\"12\" cy=\"12\" r=\"10\"/><path d=\"M2 12h20\"/><path d=\"M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z\"/>"; break;
            default:
                d = "<path d=\"M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71\"/><path d=\"M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71\"/>";
        }
        return "<svg viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" aria-hidden=\"true\">" + d + "</svg>";
    }
%>
<%!
    /** Una fila de persona (avatar o inicial, sobrenombre y @usuario). pr = {sobrenombre, usuario, avatar}. */
    private static String filaPersona(String[] pr, String contexto) {
        String nombre = pr[0] == null ? "" : pr[0];
        String ini = nombre.isEmpty() ? "?"
                : new String(Character.toChars(Character.toUpperCase(nombre.codePointAt(0))));
        StringBuilder sb = new StringBuilder("<li><span class=\"cuenta-mini\" aria-hidden=\"true\">");
        if (pr[2] != null && !pr[2].isEmpty()) {
            sb.append("<img src=\"").append(contexto).append("/media/").append(esc(pr[2])).append("\" alt=\"\">");
        } else {
            sb.append(esc(ini));
        }
        sb.append("</span><span class=\"cuenta-persona\"><b>").append(esc(nombre)).append("</b>");
        if (pr[1] != null && !pr[1].isEmpty()) sb.append("<small>@").append(esc(pr[1])).append("</small>");
        return sb.append("</span></li>").toString();
    }
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
  <!-- PERFIL: portada a todo el ancho, perfil a la izquierda y "Encuéntrame en" a la derecha -->
  <section class="cuenta-hero" aria-label="Mi perfil">
    <div class="cuenta-cover">
      <% if (portadaRuta != null) { %>
      <img src="<%= contexto %>/media/<%= esc(portadaRuta) %>" alt="">
      <% } %>
    </div>

    <div class="cuenta-hero-body">
      <div class="cuenta-lado cuenta-lado-perfil">
        <div class="cuenta-avatar" aria-hidden="true"><%= avatarHtml %></div>
        <div class="cuenta-nombres">
          <h1 class="cuenta-nombre"><%= nombrePublico %></h1>
          <% if (!usuarioArroba.isEmpty()) { %>
          <p class="cuenta-usuario"><%= usuarioArroba %></p>
          <% } %>
          <ul class="cuenta-stats" aria-label="Estadísticas del perfil">
            <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg><b><%= nSeguidores %></b><span>Seguidores</span></li>
            <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" x2="19" y1="8" y2="14"/><line x1="22" x2="16" y1="11" y2="11"/></svg><b><%= nSeguidos %></b><span>Siguiendo</span></li>
            <li><svg viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/></svg><b><%= nValoraciones %></b><span>Valoraciones</span></li>
            <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/></svg><b><%= nListas %></b><span>Listas</span></li>
            <li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg><b><%= nObras %></b><span>Obras publicadas</span></li>
          </ul>
        </div>
      </div>

      <div class="cuenta-lado cuenta-lado-redes">
        <h2 class="cuenta-redes-titulo">Encuéntrame en:</h2>
        <% if (enlacesCuenta.isEmpty()) { %>
        <p class="muted">Aún no has añadido tus redes. Usa el lápiz para agregarlas.</p>
        <% } else { %>
        <ul class="cuenta-redes">
          <% for (String[] en : enlacesCuenta) { %>
          <li><a class="cuenta-red" href="<%= esc(en[1]) %>" target="_blank" rel="noopener noreferrer nofollow"
                 title="<%= nombreRed(en[0]) %>"><%= iconoRed(en[0]) %><span><%= nombreRed(en[0]) %></span></a></li>
          <% } %>
        </ul>
        <% } %>
      </div>
    </div>

    <a class="cuenta-edit" href="<%= contexto %>/perfil#editar-perfil" aria-label="Editar perfil" title="Editar perfil">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>
    </a>
  </section>

  <!-- CONTENIDO: izquierda = más sobre mí, siguiendo y seguidores; derecha = el resto -->
  <section class="block">
    <div class="wrap">
      <div class="cuenta-cols">

        <aside class="cuenta-col-izq">
          <article class="cuenta-panel" id="mas-sobre-mi">
            <h3>Más sobre mí</h3>
            <% if (bioCuenta.isEmpty()) { %>
            <p class="muted">Aún no has escrito nada sobre ti. Usa el lápiz de arriba para añadir tu descripción.</p>
            <% } else { %>
            <p class="cuenta-bio"><%= bioCuenta %></p>
            <% } %>
          </article>

          <article class="cuenta-panel" id="siguiendo">
            <h3>Siguiendo <span class="cuenta-count"><%= nSeguidos %></span></h3>
            <% if (siguiendoLista.isEmpty()) { %>
            <p class="muted">Aún no sigues a ningún autor.</p>
            <% } else { %>
            <ul class="cuenta-personas">
              <% for (String[] pr : siguiendoLista) { %><%= filaPersona(pr, contexto) %><% } %>
            </ul>
            <% if (est[4] > siguiendoLista.size()) { %>
            <p class="cuenta-mas">y <%= est[4] - siguiendoLista.size() %> más</p>
            <% } %>
            <% } %>
          </article>

          <article class="cuenta-panel" id="seguidores">
            <h3>Seguidores <span class="cuenta-count"><%= nSeguidores %></span></h3>
            <% if (seguidoresLista.isEmpty()) { %>
            <p class="muted">Todavía nadie te sigue.</p>
            <% } else { %>
            <ul class="cuenta-personas">
              <% for (String[] pr : seguidoresLista) { %><%= filaPersona(pr, contexto) %><% } %>
            </ul>
            <% if (est[0] > seguidoresLista.size()) { %>
            <p class="cuenta-mas">y <%= est[0] - seguidoresLista.size() %> más</p>
            <% } %>
            <% } %>
          </article>
        </aside>

        <div class="cuenta-col-der">
          <!-- MONEDAS -->
          <article class="coins" id="coinsCard">
            <h3>Mis monedas</h3>
            <p>Tus recompensas de lectura, logros y compras viven en un solo saldo.</p>
            <div class="coin-row">
              <div class="coin" aria-hidden="true">S</div>
              <div class="coin-num" id="coinNum" aria-label="<%= monedasTxt %> monedas"><%= monedasTxt %></div>
            </div>
            <a class="btn small gold" href="#movimientos">Ver movimientos</a>
          </article>

          <!-- ACCESOS -->
          <div class="cuenta-bloque" id="accesos">
            <h2>Accesos</h2>
            <div class="cuenta-accesos">
              <% if (esAutor) { %>
              <a class="cuenta-acceso destacado" href="<%= contexto %>/autor/panel"><b>Panel de autor</b><small>Gestiona tus obras</small></a>
              <% } %>
              <a class="cuenta-acceso" href="<%= contexto %>/biblioteca"><b>Mi biblioteca</b><small>Tus lecturas guardadas</small></a>
              <a class="cuenta-acceso" href="<%= contexto %>/billetera"><b>Mi billetera</b><small>Monedas y compras</small></a>
              <a class="cuenta-acceso" href="<%= contexto %>/notificaciones"><b>Mis notificaciones</b><small>Novedades de tus obras</small></a>
              <a class="cuenta-acceso" href="<%= contexto %>/catalogo"><b>Explorar el catálogo</b><small>Descubre nuevas historias</small></a>
            </div>
          </div>

          <!-- MOVIMIENTOS -->
          <div class="cuenta-bloque" id="movimientos">
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

          <!-- SESIÓN -->
          <div class="cuenta-bloque">
            <h2>Sesión</h2>
            <p class="sec-lead">Cuando termines, cierra tu sesión para proteger tu cuenta.</p>
            <p style="margin-top:1.4rem"><a class="btn" href="<%= contexto %>/auth/logout">Cerrar sesión</a></p>
            <p style="margin-top:1rem"><a href="<%= contexto %>/auth/cuenta/eliminar">Eliminar mi cuenta</a></p>
          </div>
        </div>

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
